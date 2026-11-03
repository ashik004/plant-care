import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker, { handleIdentify } from '../src/index.js';
import { buildIdentifyURL, normalizeIdentification, mapUpstreamStatus } from '../src/plantnet.js';

// Shaped like the Pl@ntNet IdentificationResult schema (OpenAPI 2.2.2).
const SAMPLE = {
  query: { project: 'all', images: ['abc'], organs: ['auto'], includeRelatedImages: true },
  language: 'en',
  preferedReferential: 'k-world-flora',
  bestMatch: 'Spathiphyllum wallisii Regel',
  results: [
    { score: 0.0412, species: { scientificNameWithoutAuthor: 'Aglaonema commutatum', scientificName: 'Aglaonema commutatum Schott', genus: { scientificNameWithoutAuthor: 'Aglaonema' }, family: { scientificNameWithoutAuthor: 'Araceae' }, commonNames: ['Chinese evergreen'] }, gbif: { id: '2869311' } },
    { score: 0.9133, species: { scientificNameWithoutAuthor: 'Spathiphyllum wallisii', scientificName: 'Spathiphyllum wallisii Regel', genus: { scientificNameWithoutAuthor: 'Spathiphyllum' }, family: { scientificNameWithoutAuthor: 'Araceae' }, commonNames: ['Peace lily', 'White sails'] }, gbif: { id: '2868323' }, powo: { id: '87195-1' }, images: [{ organ: 'leaf', author: 'A. Botanist', license: 'cc-by-sa', url: { o: 'https://o/1.jpg', m: 'https://m/1.jpg', s: 'https://s/1.jpg' } }] },
    { score: 0.004, species: { scientificNameWithoutAuthor: 'Noise plant', commonNames: [] } },
  ],
  version: '2025-01-17 (7.3)',
  remainingIdentificationRequests: 487,
};

const ENV = { PLANTNET_API_KEY: 'test-key' };

function upload({ images = 1, type = 'image/jpeg', organs, contentType } = {}) {
  const form = new FormData();
  for (let i = 0; i < images; i++) form.append('images', new File([new Uint8Array([0xff, 0xd8, 0xff, i])], `p${i}.jpg`, { type }));
  (organs || []).forEach((o) => form.append('organs', o));
  const req = new Request('https://api.tend.test/v1/identify?lang=en', { method: 'POST', body: form });
  if (contentType) return new Request(req.url, { method: 'POST', body: 'x', headers: { 'content-type': contentType } });
  return req;
}

function stubFetch(status, body) {
  const calls = [];
  const fn = async (url, init) => {
    calls.push({ url: String(url), init });
    return new Response(typeof body === 'string' ? body : JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
  };
  fn.calls = calls;
  return fn;
}

test('builds the upstream URL with the key as a query parameter', () => {
  const u = buildIdentifyURL({ apiKey: 'k', project: 'all', lang: 'fr' });
  assert.equal(u.origin + u.pathname, 'https://my-api.plantnet.org/v2/identify/all');
  assert.equal(u.searchParams.get('api-key'), 'k');
  assert.equal(u.searchParams.get('lang'), 'fr');
  assert.equal(u.searchParams.get('include-related-images'), 'true');
});

test('normalises, sorts by score and drops noise', () => {
  const out = normalizeIdentification(SAMPLE);
  assert.equal(out.candidates.length, 2);
  assert.equal(out.bestMatch, 'Spathiphyllum wallisii');
  const top = out.candidates[0];
  assert.equal(top.scientificName, 'Spathiphyllum wallisii');
  assert.deepEqual(top.commonNames, ['Peace lily', 'White sails']);
  assert.equal(top.genus, 'Spathiphyllum');
  assert.equal(top.family, 'Araceae');
  assert.equal(top.score, 0.9133);
  assert.equal(top.gbifId, '2868323');
  assert.equal(top.referenceImages[0].url, 'https://m/1.jpg');
  assert.equal(out.candidates[1].referenceImages.length, 0);
  assert.equal(out.remainingRequests, 487);
});

test('handles empty or malformed bodies', () => {
  assert.deepEqual(normalizeIdentification(null).candidates, []);
  assert.equal(normalizeIdentification({}).bestMatch, null);
});

test('forwards images and default organs upstream', async () => {
  const f = stubFetch(200, SAMPLE);
  const res = await handleIdentify(upload({ images: 2 }), ENV, f);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.candidates[0].scientificName, 'Spathiphyllum wallisii');
  assert.equal(f.calls.length, 1);
  const sent = f.calls[0].init.body;
  assert.equal(sent.getAll('images').length, 2);
  assert.deepEqual(sent.getAll('organs'), ['auto', 'auto']);
  assert.ok(f.calls[0].url.includes('api-key=test-key'));
});

test('upstream 404 means no match, not an error', async () => {
  const res = await handleIdentify(upload(), ENV, stubFetch(404, { message: 'Species not found' }));
  assert.equal(res.status, 200);
  assert.deepEqual((await res.json()).candidates, []);
});

test('maps upstream errors without leaking details', async () => {
  for (const [up, want, code] of [[401, 503, 'service_misconfigured'], [429, 429, 'quota_exceeded'], [400, 422, 'unreadable_image'], [500, 502, 'upstream_error']]) {
    const res = await handleIdentify(upload(), ENV, stubFetch(up, { message: 'x' }));
    assert.equal(res.status, want, `upstream ${up}`);
    assert.equal((await res.json()).error.code, code);
  }
  assert.equal(mapUpstreamStatus(404), null);
});

test('rejects bad uploads before calling Pl@ntNet', async () => {
  const f = stubFetch(200, SAMPLE);
  assert.equal((await handleIdentify(upload({ images: 0 }), ENV, f)).status, 400);
  assert.equal((await handleIdentify(upload({ images: 6 }), ENV, f)).status, 400);
  assert.equal((await handleIdentify(upload({ type: 'image/gif' }), ENV, f)).status, 415);
  assert.equal((await handleIdentify(upload({ images: 2, organs: ['leaf'] }), ENV, f)).status, 400);
  assert.equal((await handleIdentify(upload({ organs: ['root'] }), ENV, f)).status, 400);
  assert.equal((await handleIdentify(upload({ contentType: 'application/json' }), ENV, f)).status, 400);
  assert.equal(f.calls.length, 0);
});

test('missing API key is reported as unavailable', async () => {
  const res = await handleIdentify(upload(), {}, stubFetch(200, SAMPLE));
  assert.equal(res.status, 503);
});

test('router: app token, health and unknown routes', async () => {
  const env = { ...ENV, APP_TOKEN: 'secret' };
  assert.equal((await worker.fetch(new Request('https://x/health'), env)).status, 200);
  assert.equal((await worker.fetch(upload(), env)).status, 401);
  assert.equal((await worker.fetch(new Request('https://x/v1/identify', { headers: { 'x-tend-client': 'secret' } }), env)).status, 405);
  assert.equal((await worker.fetch(new Request('https://x/nope', { headers: { 'x-tend-client': 'secret' } }), env)).status, 404);
});
