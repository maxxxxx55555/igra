import test from 'node:test';
import assert from 'node:assert/strict';
import worker from './worker.mjs';

const prefix = 'releases/' + 'a'.repeat(40) + '/' + 'b'.repeat(64);
const bytes = new TextEncoder().encode('0123456789');
const calls = [];
function environment() {
  const metadata = { size: bytes.length };
  return { RELEASE_PREFIX: prefix, THREADED: 'false', FILES_JSON: JSON.stringify({
    'index.html': { bytes: 10, sha256: 'c'.repeat(64), mime: 'text/html; charset=utf-8' },
    'index.wasm': { bytes: 10, sha256: 'd'.repeat(64), mime: 'application/wasm' },
  }), GAME: {
    async head(key) { calls.push(['head', key]); return metadata; },
    async get(key, options) {
      calls.push(['get', key, options]);
      const range = options?.range;
      const part = range ? bytes.slice(range.offset, range.offset + range.length) : bytes;
      return { ...metadata, body: new ReadableStream({ start(c) { c.enqueue(part); c.close(); } }) };
    },
  } };
}
const request = (path, init) => new Request('https://game.example' + path, init);
const asset = '/v/' + prefix + '/index.wasm';

test('root redirects into immutable release path', async () => {
  const response = await worker.fetch(request('/'), environment());
  assert.equal(response.status, 302);
  assert.equal(response.headers.get('location'), '/v/' + prefix + '/index.html');
  assert.equal(response.headers.get('cache-control'), 'no-store');
});
test('GET streams correct MIME, size, release and immutable cache', async () => {
  calls.length = 0;
  const response = await worker.fetch(request(asset), environment());
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'application/wasm');
  assert.equal(response.headers.get('content-length'), '10');
  assert.match(response.headers.get('cache-control'), /immutable/);
  assert.equal(await response.text(), '0123456789');
  assert.equal(calls[0][1], prefix + '/index.wasm');
});
test('HEAD reads metadata only and has no body', async () => {
  calls.length = 0;
  const response = await worker.fetch(request(asset, { method: 'HEAD', headers: { Range: 'bytes=1-3' } }), environment());
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-length'), '10');
  assert.equal(await response.text(), '');
  assert.equal(calls[0][0], 'head');
});
test('bounded, open-ended and suffix byte ranges return 206', async () => {
  for (const [range, body, contentRange] of [['bytes=2-4', '234', 'bytes 2-4/10'], ['bytes=8-', '89', 'bytes 8-9/10'], ['bytes=-3', '789', 'bytes 7-9/10']]) {
    const response = await worker.fetch(request(asset, { headers: { Range: range } }), environment());
    assert.equal(response.status, 206);
    assert.equal(response.headers.get('content-range'), contentRange);
    assert.equal(response.headers.get('content-length'), String(body.length));
    assert.equal(await response.text(), body);
  }
});
test('invalid or multipart range returns 416 without fetching object', async () => {
  for (const value of ['bytes=10-', 'bytes=4-2', 'bytes=-0', 'bytes=0-1,4-5', 'invalid']) {
    calls.length = 0;
    const response = await worker.fetch(request(asset, { headers: { Range: value } }), environment());
    assert.equal(response.status, 416);
    assert.equal(response.headers.get('content-range'), 'bytes */10');
    assert.equal(calls.length, 0);
  }
});
test('missing files, old prefixes and encoded traversal never access bucket', async () => {
  for (const path of ['/secret', '/v/other/index.wasm', '/v/' + prefix + '/%2e%2e%2findex.wasm', '/v/' + prefix + '/index.wasm%00', '/v/' + prefix + '//index.wasm']) {
    calls.length = 0;
    assert.equal((await worker.fetch(request(path), environment())).status, 404);
    assert.equal(calls.length, 0);
  }
});
test('non-read methods fail and unavailable objects do not become HTML', async () => {
  assert.equal((await worker.fetch(request(asset, { method: 'POST' }), environment())).status, 405);
  const env = environment();
  env.GAME.get = async () => null;
  assert.equal((await worker.fetch(request(asset), env)).status, 404);
  env.GAME.get = async () => ({ size: 2, body: null });
  assert.equal((await worker.fetch(request(asset), env)).status, 503);
});
test('threaded release gets isolation headers; invalid configuration fails closed', async () => {
  const env = environment(); env.THREADED = 'true';
  const response = await worker.fetch(request(asset), env);
  assert.equal(response.headers.get('cross-origin-opener-policy'), 'same-origin');
  assert.equal(response.headers.get('cross-origin-embedder-policy'), 'require-corp');
  env.RELEASE_PREFIX = '../secret';
  assert.equal((await worker.fetch(request(asset), env)).status, 503);
});
test('If-Range mismatch returns the full resource', async () => {
  const response = await worker.fetch(request(asset, { headers: { Range: 'bytes=2-3', 'If-Range': '"older-etag"' } }), environment());
  assert.equal(response.status, 200);
  assert.equal(await response.text(), '0123456789');
});
