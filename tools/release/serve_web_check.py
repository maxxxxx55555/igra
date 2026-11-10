# -*- coding: utf-8 -*-
"""Serve a Godot Web export for a real-browser startup check.

Usage: python tools/release/serve_web_check.py <web_dir> <port>

A Godot 4 Web build needs application/wasm for .wasm and, for the threaded
variant, a cross-origin-isolated context (COOP/COEP). The pinned 4.7.2
toolchain ships web_nothreads_* templates, so threads are not required, but
COOP/COEP are harmless and make the same server work for both variants.
"""
import functools
import http.server
import mimetypes
import socketserver
import sys
from pathlib import Path


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        if path.endswith(".data"):
            return "application/octet-stream"
        if path.endswith(".js"):
            return "application/javascript"
        return mimetypes.guess_type(path)[0] or "application/octet-stream"

    def log_message(self, fmt, *args):
        sys.stderr.write("[web-check] " + (fmt % args) + "\n")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    root = Path(sys.argv[1]).resolve()
    port = int(sys.argv[2])
    if not (root / "index.html").is_file():
        raise SystemExit(f"no index.html in {root}")
    handler = functools.partial(Handler, directory=str(root))
    with Server(("127.0.0.1", port), handler) as srv:
        print(f"serving {root} on http://127.0.0.1:{port}", flush=True)
        srv.serve_forever()
