# Tend API

A small Cloudflare Worker that sits between the app and plant-identification providers, so API keys never ship inside the app.

## Endpoint

`POST /v1/identify?lang=en`, as `multipart/form-data`:

| Field | Required | Notes |
|---|---|---|
| `images` | yes | 1–5 JPEG or PNG photos of the same plant, up to 6 MB each |
| `organs` | no | One per image: `auto`, `leaf`, `flower`, `fruit`, `bark`, `habit` or `other`. Defaults to `auto` |

Response `200`:

```json
{
  "provider": "plantnet",
  "bestMatch": "Spathiphyllum wallisii",
  "candidates": [
    {
      "scientificName": "Spathiphyllum wallisii",
      "scientificNameWithAuthor": "Spathiphyllum wallisii Regel",
      "commonNames": ["Peace lily"],
      "genus": "Spathiphyllum",
      "family": "Araceae",
      "score": 0.9133,
      "gbifId": "2868323",
      "powoId": "87195-1",
      "referenceImages": [{ "url": "https://…", "organ": "leaf", "author": "…", "license": "cc-by-sa" }]
    }
  ],
  "remainingRequests": 487
}
```

An empty `candidates` array means no plant was recognised. Errors return `{ "error": { "code", "message" } }`:

| Status | Code | Meaning |
|---|---|---|
| 400 | `bad_request` | Missing or invalid upload |
| 401 | `unauthorized` | Wrong or missing `X-Tend-Client` (only when `APP_TOKEN` is set) |
| 413 / 415 / 422 | `too_large` / `unsupported_type` / `unreadable_image` | The photo can't be used |
| 429 | `quota_exceeded` | Pl@ntNet quota used up |
| 502 / 503 | `upstream_error` / `service_misconfigured` | Provider down, or the key is missing or invalid |

`GET /health` returns `{ "ok": true }`.

## Set up

1. Create a free account at [my.plantnet.org](https://my.plantnet.org) and copy your API key. The free plan is for non-commercial use with a daily quota; check their pricing before launch.
2. Install and log in to Cloudflare:
   ```sh
   cd backend
   npm install
   npx wrangler login
   ```
3. Add the secrets:
   ```sh
   npx wrangler secret put PLANTNET_API_KEY
   npx wrangler secret put APP_TOKEN        # optional: any long random string
   ```
4. Deploy, and note the URL it prints (for example `https://tend-api.<you>.workers.dev`):
   ```sh
   npm run deploy
   ```
5. In Xcode, open `ios/Config/Tend-Info.plist` and set `TendAPIBaseURL` to that URL, and `TendAPIAppToken` to the same `APP_TOKEN` if you set one.

While `TendAPIBaseURL` is empty, the app runs in demo mode: the scanner shows the design's sample results and labels them **DEMO**.

## Develop

```sh
npm test         # unit tests with a stubbed Pl@ntNet
npm run dev      # local server; put secrets in .dev.vars (PLANTNET_API_KEY=…)
```

## Notes

- **Attribution:** the app credits Pl@ntNet under each result. Keep this; check Pl@ntNet's terms for their exact attribution and usage rules.
- **Abuse protection:** `APP_TOKEN` stops casual misuse, but anything shipped in the app can be extracted. Before launch, add [App Attest](https://developer.apple.com/documentation/devicecheck) verification and per-device rate limits.
- **Photos:** the Worker forwards photos to Pl@ntNet and doesn't store them. Make sure the privacy policy says photos are sent to a third-party identification service.
