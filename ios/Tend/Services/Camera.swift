import AVFoundation
import SwiftUI
import Observation

/// Live camera feed for the scanner and light meter. Also estimates scene brightness
/// in lux from the exposure the camera picks (ISO, shutter, aperture).
@MainActor
@Observable
final class CameraController {
    enum Status { case idle, unavailable, denied, running }

    var status: Status = .idle
    /// Estimated lux, refreshed a few times a second while running.
    var lux: Double?

    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private var device: AVCaptureDevice?
    @ObservationIgnored private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var meterTask: Task<Void, Never>?
    @ObservationIgnored private let queue = DispatchQueue(label: "tend.camera")

    func start() async {
        #if targetEnvironment(simulator)
        status = .unavailable
        return
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else { status = .denied; return }
        case .denied, .restricted:
            status = .denied; return
        default: break
        }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { status = .unavailable; return }
        self.device = device
        let session = self.session
        let output = self.photoOutput
        let needsConfig = !configured
        configured = true
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            queue.async {
                if needsConfig {
                    session.beginConfiguration()
                    session.sessionPreset = .photo
                    if session.canAddInput(input) { session.addInput(input) }
                    if session.canAddOutput(output) { session.addOutput(output) }
                    session.commitConfiguration()
                }
                if !session.isRunning { session.startRunning() }
                c.resume()
            }
        }
        status = .running
        startMetering()
        #endif
    }

    func stop() {
        meterTask?.cancel()
        let session = self.session
        queue.async { if session.isRunning { session.stopRunning() } }
        if status == .running { status = .idle }
    }

    private func startMetering() {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.sampleLux()
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    /// EV100 = log2(N² / t) − log2(ISO / 100); illuminance ≈ 2.5 × 2^EV100.
    /// A rough reflected-light estimate: calibrate against a lux meter before shipping.
    private func sampleLux() {
        guard let d = device else { return }
        let n = Double(d.lensAperture)
        let t = CMTimeGetSeconds(d.exposureDuration)
        let iso = Double(d.iso)
        guard n > 0, t > 0, iso > 0 else { return }
        let ev100 = log2(n * n / t) - log2(iso / 100)
        let value = 2.5 * pow(2, ev100)
        lux = lux.map { $0 * 0.7 + value * 0.3 } ?? value
    }
}

/// Shows the camera feed, or nothing when the camera isn't running (the caller draws
/// the placeholder underneath).
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.previewLayer.session = session
        v.previewLayer.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}
