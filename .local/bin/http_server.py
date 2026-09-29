import http.server
import json


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def do_GET(self):
        self.send_response(http.server.HTTPStatus.OK)
        self.send_header("Content-type", "json")
        self.end_headers()
        self.wfile.write(bytes(json.dumps({"hello": "world"}).encode("UTF-8")))

    def do_POST(self):
        self.send_response(http.server.HTTPStatus.OK)
        self.send_header("Content-type", "json")
        self.end_headers()
        data = self.rfile.read(int(self.headers.get("content-length")))
        print(data)
        self.wfile.write(data)


def run(
    server_class=http.server.HTTPServer,
    handler_class=http.server.BaseHTTPRequestHandler,
):
    server_address = ("", 8000)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()


if __name__ == "__main__":
    print("start")
    run(handler_class=Handler)
