// Pl@ntNet v2 identify client and response normaliser.
// API reference: https://my.plantnet.org/doc/api/identify (OpenAPI 2.2.2).

export const PLANTNET_BASE = 'https://my-api.plantnet.org';
export const MAX_IMAGES = 5;
export const ALLOWED_ORGANS = ['auto', 'leaf', 'flower', 'fruit', 'bark', 'habit', 'other'];
export const ALLOWED_TYPES = ['image/jpeg', 'image/png'];
/** Results below this score are noise and are dropped. */
export const MIN_SCORE = 0.01;
export const MAX_CANDIDATES = 5;

/** Builds the upstream URL. The API key travels as a query parameter, per the Pl@ntNet docs. */
export function buildIdentifyURL({ apiKey, project = 'all', lang = 'en', nbResults = MAX_CANDIDATES }) {
  const url = new URL(`/v2/identify/${encodeURIComponent(project)}`, PLANTNET_BASE);
  url.searchParams.set('api-key', apiKey);
  url.searchParams.set('lang', lang);
  url.searchParams.set('nb-results', String(nbResults));
  url.searchParams.set('include-related-images', 'true');
  return url;
}

/** Picks a usable reference-image URL; Pl@ntNet returns `url` as `{ o, m, s }`. */
function imageURL(url) {
  if (!url) return null;
  if (typeof url === 'string') return url;
  return url.m || url.s || url.o || null;
}

/** Turns a Pl@ntNet IdentificationResult into Tend's stable response shape. */
export function normalizeIdentification(body) {
  const results = Array.isArray(body?.results) ? body.results : [];
  const candidates = results
    .filter((r) => typeof r?.score === 'number' && r.score >= MIN_SCORE && r.species)
    .sort((a, b) => b.score - a.score)
    .slice(0, MAX_CANDIDATES)
    .map((r) => {
      const s = r.species;
      return {
        scientificName: s.scientificNameWithoutAuthor || s.scientificName || '',
        scientificNameWithAuthor: s.scientificName || s.scientificNameWithoutAuthor || '',
        commonNames: Array.isArray(s.commonNames) ? s.commonNames.filter(Boolean) : [],
        genus: s.genus?.scientificNameWithoutAuthor || null,
        family: s.family?.scientificNameWithoutAuthor || null,
        score: Math.round(r.score * 10000) / 10000,
        gbifId: r.gbif?.id ? String(r.gbif.id) : null,
        powoId: r.powo?.id ? String(r.powo.id) : null,
        referenceImages: (Array.isArray(r.images) ? r.images : [])
          .map((img) => ({
            url: imageURL(img.url),
            organ: img.organ || null,
            author: img.author || null,
            license: img.license || null,
          }))
          .filter((img) => img.url)
          .slice(0, 3),
      };
    });

  return {
    provider: 'plantnet',
    bestMatch: candidates[0]?.scientificName || null,
    candidates,
    remainingRequests: typeof body?.remainingIdentificationRequests === 'number'
      ? body.remainingIdentificationRequests : null,
  };
}

/** Maps an upstream status to Tend's error codes. `null` means "no match" (not an error). */
export function mapUpstreamStatus(status) {
  if (status === 404) return null;                       // "Species not found"
  if (status === 400) return { status: 422, code: 'unreadable_image', message: "The photo couldn't be read. Try another one." };
  if (status === 401 || status === 403) return { status: 503, code: 'service_misconfigured', message: 'Identification is unavailable right now.' };
  if (status === 413 || status === 414) return { status: 413, code: 'too_large', message: 'The photo is too large.' };
  if (status === 429) return { status: 429, code: 'quota_exceeded', message: 'Too many identifications right now. Try again later.' };
  return { status: 502, code: 'upstream_error', message: 'Identification is unavailable right now.' };
}
