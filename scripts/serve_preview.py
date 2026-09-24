"""Serve local Flutter reviews without stale cache responses; retain one storage origin."""
import argparse
import io
import re
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

class PreviewHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        super().end_headers()

    def send_head(self):
        # Each review has distinct asset URLs, while IndexedDB stays on the same origin.
        match = re.match(r"^/review/([a-zA-Z0-9-]+)/", self.path)
        prefix = match.group(0) if match else "/"
        if match:
            self.path = "/" + self.path[match.end():]
        for header in ("If-Modified-Since", "If-None-Match"):
            if header in self.headers:
                del self.headers[header]
        path = urlsplit(self.path).path
        if path in ("/", "/index.html"):
            body = (Path(self.directory) / "index.html").read_bytes()
            body = body.replace(b'<base href="/">', ('<base href="' + prefix + '">').encode())
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            return io.BytesIO(body)
        return super().send_head()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    root = args.directory.resolve(strict=True)
    if not (root / "main.dart.js").is_file():
        raise SystemExit("Build the Flutter preview before serving it.")
    def handler(*a, **kw):
        return PreviewHandler(*a, directory=str(root), **kw)
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
