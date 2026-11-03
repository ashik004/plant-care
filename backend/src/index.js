// Tend API: a Cloudflare Worker that keeps provider keys off the phone.
//
// POST /v1/identify   multipart/form-data
//   images  1–5 JPEG/PNG files of the same plant
//   organs  optional, one per image: auto | leaf | flower | fruit | bark | habit | other
//   query   ?lang=en
// →  200 { provider, bestMatch, candidates: [...], remainingRequests }
//    An empty `candidates` array means no plant was recognised.
//
// Errors use { error: { code, message } }.
//
// Secrets (wrangler secret put): PLANTNET_API_KEY, and optionally APP_TOKEN. When APP_TOKEN
// is set, requests must send it in the X-Tend-Client header.

import {
  ALLOWED_ORGANS, ALLOWED_TYPES, MAX_IMAGES,
  buildIdentifyURL, mapUpstreamStatus, normalizeIdentification,
} from './plantnet.js';

const MAX_IMAGE_BYTES = 6 * 1024 * 1024;

const json = (status, body) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
});
const fail = (status, code, message) => json(status, { error: { code, message } });

export async function handleIdentify(request, env, fetchImpl = fetch) {
  if (!env.PLANTNET_API_KEY) return fail(503, 'service_misconfigured', 'Identification is unavailable right now.');

  const type = request.headers.get('content-type') || '';
  if (!type.startsWith('multipart/form-data')) return fail(400, 'bad_request', 'Send the photo as multipart/form-data.');

  let form;
  try { form = await request.formData(); } catch { return fail(400, 'bad_request', 'The upload could not be read.'); }

  const images = form.getAll('images').filter((v) => typeof v === 'object' && v !== null && 'arrayBuffer' in v);
  if (images.length === 0) return fail(400, 'bad_request', 'Add at least one photo.');
  if (images.length > MAX_IMAGES) return fail(400, 'bad_request', `Send at most ${MAX_IMAGES} photos.`);
  for (const img of images) {
    if (!ALLOWED_TYPES.includes(img.type)) return fail(415, 'unsupported_type', 'Photos must be JPEG or PNG.');
    if (img.size > MAX_IMAGE_BYTES) return fail(413, 'too_large', 'The photo is too large.');
  }

  let organs = form.getAll('organs').map(String);
  if (organs.length === 0) organs = images.map(() => 'auto');
  if (organs.length !== images.length) return fail(400, 'bad_request', 'Send one organ per photo.');
  if (!organs.every((o) => ALLOWED_ORGANS.includes(o))) return fail(400, 'bad_request', 'Unknown organ.');

  const lang = (new URL(request.url).searchParams.get('lang') || 'en').slice(0, 5);
  const upstream = new FormData();
  images.forEach((img, i) => upstream.append('images', img, img.name || `photo-${i + 1}.jpg`));
  organs.forEach((o) => upstream.append('organs', o));

  const url = buildIdentifyURL({ apiKey: env.PLANTNET_API_KEY, project: env.PLANTNET_PROJECT || 'all', lang });
  let res;
  try {
    res = await fetchImpl(url, { method: 'POST', body: upstream });
  } catch {
    return fail(502, 'upstream_unreachable', 'Identification is unavailable right now.');
  }

  if (!res.ok) {
    const mapped = mapUpstreamStatus(res.status);
    if (mapped === null) return json(200, normalizeIdentification({ results: [] }));
    return fail(mapped.status, mapped.code, mapped.message);
  }

  let body;
  try { body = await res.json(); } catch { return fail(502, 'upstream_error', 'Identification is unavailable right now.'); }
  return json(200, normalizeIdentification(body));
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/health') return json(200, { ok: true });

    if (env.APP_TOKEN && request.headers.get('x-tend-client') !== env.APP_TOKEN) {
      return fail(401, 'unauthorized', 'Unauthorized.');
    }
    if (pathname === '/v1/identify') {
      if (request.method !== 'POST') return fail(405, 'method_not_allowed', 'Use POST.');
      return handleIdentify(request, env);
    }
    return fail(404, 'not_found', 'Not found.');
  },
};
