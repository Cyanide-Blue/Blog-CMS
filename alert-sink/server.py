import json
import os
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG_FILE = "/logs/alerts.log"
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

class AlertHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        content_len = int(self.headers.get("Content-Length", 0))
        post_body = self.rfile.read(content_len).decode("utf-8")
        now_iso = datetime.now(timezone.utc).isoformat()

        try:
            data = json.loads(post_body)
        except Exception:
            data = {"raw": post_body}

        alert_title = data.get("title", data.get("groupKey", "Grafana Alert"))
        status = data.get("status", "unknown")
        alerts_list = data.get("alerts", [])

        print(f"[ALERT-SINK] timestamp={now_iso} status={status.upper()} title='{alert_title}' count={len(alerts_list)}", flush=True)
        for idx, a in enumerate(alerts_list):
            labels = a.get("labels", {})
            annos = a.get("annotations", {})
            alertname = labels.get("alertname", "UnknownAlert")
            severity = labels.get("severity", "info")
            desc = annos.get("description", annos.get("summary", ""))
            print(f"  -> [{idx+1}] {alertname} ({severity.upper()}): {desc}", flush=True)

        # Write to log file
        try:
            with open(LOG_FILE, "a", encoding="utf-8") as f:
                f.write(json.dumps({"received_at": now_iso, "payload": data}, ensure_ascii=False) + "\n")
        except Exception as e:
            print(f"[ALERT-SINK] Error writing to {LOG_FILE}: {e}", file=sys.stderr, flush=True)

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status":"received"}')

    def log_message(self, format, *args):
        # Keep stdout clean and structured
        pass

if __name__ == "__main__":
    port = 9099
    print(f"[ALERT-SINK] Starting Alert Sink Webhook Server on port {port}...", flush=True)
    server = HTTPServer(("0.0.0.0", port), AlertHandler)
    server.serve_forever()
