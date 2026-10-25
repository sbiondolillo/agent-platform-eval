#!/usr/bin/env python3
"""A local OTLP relay for the spend-attribution probe.

Listens on all interfaces on port 4318. Forwards every POST to the Grafana Cloud OTLP
gateway with the Authorization header taken from OTEL_EXPORTER_OTLP_HEADERS
in the environment. Prints, per request: client address, time, path, content type, body
size, upstream status, and the first 300 bytes of the upstream body. It
never prints a header value.
urllib honours an https_proxy variable in the environment, so the relay needs no proxy code.
"""
import os
import sys
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

UPSTREAM = "https://otlp-gateway-prod-us-east-2.grafana.net/otlp"
raw = os.environ.get("OTEL_EXPORTER_OTLP_HEADERS", "")
if "=" not in raw:
    sys.exit("OTEL_EXPORTER_OTLP_HEADERS is not set in this shell")
name, value = raw.split("=", 1)
value = value.replace("%20", " ")


class Relay(BaseHTTPRequestHandler):
    def do_POST(self):
        size = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(size)
        ctype = self.headers.get("Content-Type", "")
        req = urllib.request.Request(UPSTREAM + self.path, data=body, method="POST")
        req.add_header("Content-Type", ctype)
        req.add_header(name.strip(), value.strip())
        try:
            with urllib.request.urlopen(req, timeout=20) as r:
                status, text = r.status, r.read(300)
        except urllib.error.HTTPError as e:
            status, text = e.code, e.read(300)
        except Exception as e:  # noqa: BLE001
            status, text = 0, repr(e).encode()
        print(f"{self.client_address[0]} {time.strftime('%H:%M:%S')} {self.path} {ctype} {size} B -> {status} {text!r}", flush=True)
        self.send_response(status if status else 502)
        self.end_headers()

    def log_message(self, *args):  # silence the default access log
        pass


print("relay on http://0.0.0.0:4318 -> " + UPSTREAM, flush=True)
HTTPServer(("0.0.0.0", 4318), Relay).serve_forever()
