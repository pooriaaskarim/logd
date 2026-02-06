import os
import json
import argparse
import sys
from datetime import datetime
from flask import Flask, request, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
batch_count = 0

# Professional ANSI Styles (Subtle)
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"
MAGENTA = "\033[35m"
BLUE = "\033[34m"

def get_timestamp():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

@app.route('/logs', methods=['POST'])
def receive_logs():
    global batch_count
    try:
        batch = request.get_json()
        batch_count += 1
        client_ip = request.remote_addr
        
        print(f"\n{BOLD}{MAGENTA}BATCH #{batch_count:04}{RESET} {DIM}────────────────────────────────────────────────{RESET}")
        print(f"{DIM}Source: {RESET} {client_ip}")
        print(f"{DIM}Volume: {RESET} {len(batch)} entries")
        print(f"{DIM}Received:{RESET} {get_timestamp()}")
        print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}")
        
        for i, entry in enumerate(batch):
            # Try to pretty print if entry is a dict
            if isinstance(entry, dict):
                content = json.dumps(entry, indent=2)
            else:
                content = str(entry)
                
            prefix = f"{BLUE}{i+1:02}{RESET} "
            lines = content.splitlines()
            print(f"{prefix}{lines[0]}")
            for line in lines[1:]:
                print(f"   {line}")
                
        print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}", flush=True)
        
        return jsonify({"status": "success", "processed": len(batch)}), 200
    except Exception as e:
        print(f"{BOLD}Error processing batch:{RESET} {e}", flush=True)
        return jsonify({"status": "error", "message": str(e)}), 400

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Professional logd HttpSink Server")
    parser.add_argument("--host", default=os.getenv('HOST', '127.0.0.1'), help="Host to bind to")
    parser.add_argument("--port", type=int, default=int(os.getenv('PORT', 8080)), help="Port to bind to")
    args = parser.parse_args()

    print(f"{BOLD}logd HttpSink {DIM}|{RESET} Batched Telemetry Server")
    print(f"{DIM}Status:  {RESET} Active")
    print(f"{DIM}Endpoint:{RESET} http://{args.host}:{args.port}/logs")
    print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}\n", flush=True)
    
    try:
        app.run(host=args.host, port=args.port, debug=False)
    except Exception as e:
        print(f"\n{BOLD}Error:{RESET} {e}")
        sys.exit(1)
