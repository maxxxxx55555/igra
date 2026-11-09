// Every public object belongs to the verified release manifest, never a user-supplied R2 key.
export default {
  async fetch(request, env) {
    if (!['GET', 'HEAD'].includes(request.method)) {
      return new Response('Method not allowed', { status: 405, headers: { Allow: 'GET, HEAD' } });
    }
    let files;
    try {
      if (!/^releases\/[a-f0-9]{40}\/[a-f0-9]{64}$/.test(env.RELEASE_PREFIX)) throw new Error('prefix');
      files = JSON.parse(env.FILES_JSON);
      if (!Object.hasOwn(files, 'index.html') || !env.GAME) throw new Error('manifest');
    } catch {
      return new Response('Release unavailable', { status: 503 });
    }
    const path = new URL(request.url).pathname;
    const base = '/v/' + env.RELEASE_PREFIX + '/';
    if (path === '/' || path === '/index.html') {
      return new Response(null, { status: 302, headers: { Location: base + 'index.html', 'Cache-Control': 'no-store' } });
    }
    if (!path.startsWith(base)) return new Response('Not found', { status: 404 });
    const name = path.slice(base.length);
    if (!/^[a-zA-Z0-9_.-]+$/.test(name) || !Object.hasOwn(files, name)) {
      return new Response('Not found', { status: 404 });
    }
    const file = files[name];
    if (!file || !Number.isSafeInteger(file.bytes) || file.bytes <= 0 || !/^[a-f0-9]{64}$/.test(file.sha256)) {
      return new Response('Release unavailable', { status: 503 });
    }
    const headers = new Headers({
      'Content-Type': file.mime, 'Content-Length': String(file.bytes),
      'Cache-Control': 'public, max-age=31536000, immutable', 'Accept-Ranges': 'bytes',
      'ETag': '"sha256-' + file.sha256 + '"', 'X-Content-Type-Options': 'nosniff',
      'Cross-Origin-Resource-Policy': 'same-origin',
    });
    if (env.THREADED === 'true') {
      headers.set('Cross-Origin-Opener-Policy', 'same-origin');
      headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
    }
    let range;
    const ifRange = request.headers.get('If-Range');
    if (request.method === 'GET' && request.headers.has('Range') && (!ifRange || ifRange === headers.get('ETag'))) {
      const parsed = /^bytes=(\d*)-(\d*)$/.exec(request.headers.get('Range'));
      let start = NaN, end = NaN;
      if (parsed && (parsed[1] || parsed[2])) {
        start = parsed[1] ? Number(parsed[1]) : Math.max(0, file.bytes - Number(parsed[2]));
        end = parsed[1] && parsed[2] ? Math.min(Number(parsed[2]), file.bytes - 1) : file.bytes - 1;
        if (!parsed[1] && Number(parsed[2]) === 0) start = NaN;
      }
      if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || start >= file.bytes || end < start) {
        return new Response(null, { status: 416, headers: { 'Content-Range': 'bytes */' + file.bytes } });
      }
      range = { offset: start, length: end - start + 1 };
      headers.set('Content-Range', `bytes ${start}-${end}/${file.bytes}`);
      headers.set('Content-Length', String(range.length));
    }
    const key = env.RELEASE_PREFIX + '/' + name;
    const object = request.method === 'HEAD' ? await env.GAME.head(key) : await env.GAME.get(key, range ? { range } : undefined);
    if (!object) return new Response('Not found', { status: 404 });
    if (object.size !== file.bytes) return new Response('Release unavailable', { status: 503 });
    return new Response(request.method === 'HEAD' ? null : object.body, { status: range ? 206 : 200, headers });
  },
};
