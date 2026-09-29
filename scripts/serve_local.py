import http.server
import socketserver
import os
import sys

PORT = 8080
BUILD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'build', 'web'))

class SPAServerHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    def do_GET(self):
        # Translate the requested path relative to the root directory
        local_path = self.translate_path(self.path)
        # If file doesn't exist on disk, fallback to index.html for Single Page Application routing
        if not os.path.exists(local_path) and not self.path.startswith('/api/'):
            self.path = '/index.html'
        return super().do_GET()

    def end_headers(self):
        # Allow cross-origin and disable caching for local live testing
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def run():
    socketserver.TCPServer.allow_reuse_address = True
    port = PORT
    for p in [8080, 8081, 3000, 5000]:
        try:
            with socketserver.TCPServer(("", p), SPAServerHandler) as httpd:
                print(f"=== OCHANYA GILI MAISON STOREFRONT SERVING AT ===")
                print(f"http://localhost:{p}")
                print(f"Serving directory: {BUILD_DIR}")
                sys.stdout.flush()
                httpd.serve_forever()
                break
        except OSError:
            continue

if __name__ == '__main__':
    run()
