import Foundation
import UIKit

// Real plant identification. The app sends the photo to the Tend API (see `backend/`),
// which calls Pl@ntNet with a key that never ships in the app. Care details come from the
// bundled `species-care.json` catalogue.

// MARK: - Care catalogue

struct CareProfile: Decodable {
    let key: String
    let rank: String
    let common: String
    let waterEvery: Int
    let light: String
    let lux: [Double]
    let humidity: [Double]
    let temp: [Double]
    let amount: String
    let toxicToPets: Bool?
    let care: String

    var source: CareSource {
        switch rank {
        case "species": .species
        case "genus": .genus
        case "family": .family
        default: .general
        }
    }
}

/// Looks up care by species, then genus, then family, then a general default.
final class SpeciesCatalog: @unchecked Sendable {
    static let shared = SpeciesCatalog()

    private let byKey: [String: CareProfile]
    private let fallback: CareProfile

    private struct File: Decodable { let entries: [CareProfile] }

    init(bundle: Bundle = .main) {
        var map: [String: CareProfile] = [:]
        if let url = bundle.url(forResource: "species-care", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(File.self, from: data) {
            for e in file.entries { map[e.key.lowercased()] = e }
        }
        byKey = map
        fallback = map["default"] ?? CareProfile(
            key: "default", rank: "default", common: "Plant", waterEvery: 7, light: "Medium",
            lux: [1000, 10000], humidity: [40, 60], temp: [16, 26], amount: "250 ml", toxicToPets: nil,
            care: "Check the soil before watering and adjust the schedule after a week or two.")
    }

    func profile(scientificName: String, genus: String?, family: String?) -> CareProfile {
        let species = scientificName.split(separator: " ").prefix(2).joined(separator: " ").lowercased()
        let genusKey = (genus ?? scientificName.split(separator: " ").first.map(String.init) ?? "").lowercased()
        // Pl@ntNet reports snake plants under Dracaena; Calathea moved to Goeppertia.
        for key in [species, genusKey, (family ?? "").lowercased()] where !key.isEmpty {
            if let p = byKey[key] { return p }
        }
        return fallback
    }
}

// MARK: - API response

struct IdentifyResponse: Decodable {
    struct Candidate: Decodable {
        struct RefImage: Decodable { let url: String; let organ: String?; let author: String?; let license: String? }
        let scientificName: String
        let scientificNameWithAuthor: String?
        let commonNames: [String]
        let genus: String?
        let family: String?
        let score: Double
        let gbifId: String?
        let powoId: String?
        let referenceImages: [RefImage]
    }
    let provider: String?
    let bestMatch: String?
    let candidates: [Candidate]
    let remainingRequests: Int?
}

private struct APIErrorBody: Decodable {
    struct Inner: Decodable { let code: String; let message: String }
    let error: Inner
}

enum IdentifyError: LocalizedError, Equatable {
    case noMatch
    case unreadablePhoto
    case quotaExceeded
    case offline
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .noMatch: "Tend couldn't recognise this plant."
        case .unreadablePhoto: "The photo couldn't be read. Try another one."
        case .quotaExceeded: "Too many identifications right now. Try again in a little while."
        case .offline: "You're offline. Scans need a connection."
        case .unavailable(let m): m
        }
    }
}

// MARK: - Identifiers

protocol PlantIdentifier: Sendable {
    /// Identifies a plant from 1–5 JPEG photos of the same plant. Throws `IdentifyError`.
    func identify(photos: [Data]) async throws -> [ScanCandidate]
    var isDemo: Bool { get }
}

enum PlantIdentifiers {
    /// The Tend API when `TendAPIBaseURL` is set in Info.plist, otherwise the demo results.
    static var current: PlantIdentifier {
        let info = Bundle.main.infoDictionary ?? [:]
        if let raw = info["TendAPIBaseURL"] as? String, let url = URL(string: raw), !raw.isEmpty {
            return RemotePlantIdentifier(baseURL: url, appToken: info["TendAPIAppToken"] as? String)
        }
        return DemoPlantIdentifier()
    }
}

/// Calls `POST {base}/v1/identify` on the Tend API.
struct RemotePlantIdentifier: PlantIdentifier {
    let baseURL: URL
    let appToken: String?
    var catalog: SpeciesCatalog = .shared
    var session: URLSession = .shared
    var isDemo: Bool { false }

    func identify(photos: [Data]) async throws -> [ScanCandidate] {
        var comps = URLComponents(url: baseURL.appendingPathComponent("v1/identify"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "lang", value: Self.language)]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "POST"
        req.timeoutInterval = 30
        if let appToken, !appToken.isEmpty { req.setValue(appToken, forHTTPHeaderField: "X-Tend-Client") }
        let boundary = "tend-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = Self.multipart(photos: photos, boundary: boundary)

        let data: Data, response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch let e as URLError where [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed].contains(e.code) {
            throw IdentifyError.offline
        } catch {
            throw IdentifyError.unavailable("Identification is unavailable right now.")
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let body = try? JSONDecoder().decode(APIErrorBody.self, from: data)
            switch body?.error.code {
            case "unreadable_image", "unsupported_type", "too_large": throw IdentifyError.unreadablePhoto
            case "quota_exceeded": throw IdentifyError.quotaExceeded
            default: throw IdentifyError.unavailable(body?.error.message ?? "Identification is unavailable right now.")
            }
        }
        guard let decoded = try? JSONDecoder().decode(IdentifyResponse.self, from: data) else {
            throw IdentifyError.unavailable("Identification is unavailable right now.")
        }
        let candidates = decoded.candidates.map { Self.candidate(from: $0, catalog: catalog) }
        guard let top = candidates.first, top.confidence >= 5 else { throw IdentifyError.noMatch }
        return candidates
    }

    static var language: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return ["en", "fr", "de", "es", "it", "pt", "nl"].contains(code) ? code : "en"
    }

    static func multipart(photos: [Data], boundary: String) -> Data {
        // Each part: "--boundary CRLF headers CRLF CRLF content CRLF", then "--boundary--" closes.
        var body = Data()
        func add(_ s: String) { body.append(Data(s.utf8)) }
        for (i, photo) in photos.prefix(5).enumerated() {
            add("--\(boundary)\r\n")
            add("Content-Disposition: form-data; name=\"images\"; filename=\"photo-\(i + 1).jpg\"\r\n")
            add("Content-Type: image/jpeg\r\n\r\n")
            body.append(photo)
            add("\r\n")
            add("--\(boundary)\r\n")
            add("Content-Disposition: form-data; name=\"organs\"\r\n\r\n")
            add("auto\r\n")
        }
        add("--\(boundary)--\r\n")
        return body
    }

    static func candidate(from c: IdentifyResponse.Candidate, catalog: SpeciesCatalog) -> ScanCandidate {
        let p = catalog.profile(scientificName: c.scientificName, genus: c.genus, family: c.family)
        let common = c.commonNames.first.map { $0.prefix(1).uppercased() + $0.dropFirst() }
            ?? (p.source == .species ? p.common : nil)
            ?? c.scientificName
        return ScanCandidate(
            species: common,
            latin: c.scientificName,
            confidence: Int((c.score * 100).rounded()),
            waterEvery: p.waterEvery,
            light: p.light,
            humidityText: "\(Int(p.humidity[0]))–\(Int(p.humidity[1]))%",
            humidity: p.humidity[0]...p.humidity[1],
            lightRange: p.lux[0]...p.lux[1],
            temperature: p.temp[0]...p.temp[1],
            amount: p.amount,
            care: p.care,
            referenceImageURL: c.referenceImages.first.flatMap { URL(string: $0.url) },
            toxicToPets: p.toxicToPets,
            careSource: p.source,
            genus: c.genus,
            family: c.family)
    }
}

/// Used until the Tend API is configured: returns the design's sample results.
struct DemoPlantIdentifier: PlantIdentifier {
    var isDemo: Bool { true }
    func identify(photos: [Data]) async throws -> [ScanCandidate] {
        try await Task.sleep(for: .milliseconds(1400))
        return SampleData.candidates
    }
}

// MARK: - Photo preparation

enum PhotoPrep {
    /// Downscales to at most `maxSide` px on the long edge (orientation baked in) and encodes JPEG.
    /// Pl@ntNet works at 1280 px on the short side, so bigger uploads only cost time.
    static func jpeg(_ image: UIImage, maxSide: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
