import os
import asyncio
import sys
import json
import argparse
from datetime import datetime
from dotenv import load_dotenv

# Load configuration from .env
load_dotenv()

try:
    import websockets
except ImportError:
    print("Error: 'websockets' package not installed.", flush=True)
    sys.exit(1)

# Professional ANSI Styles (Subtle)
DIM = "\033[2m"
BOLD = "\033[1m"
RESET = "\033[0m"
BLUE = "\033[34m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"

class SocketLogServer:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.message_count = 0

    def get_timestamp(self):
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

    async def handler(self, websocket):
        client_addr = websocket.remote_address
        print(f"{DIM}[{self.get_timestamp()}]{RESET} {GREEN}Connection established{RESET} from {client_addr[0]}:{client_addr[1]}", flush=True)
        
        try:
            async for message in websocket:
                self.message_count += 1
                try:
                    data = json.loads(message)
                    content = json.dumps(data, indent=2)
                    is_struct = True
                except:
                    content = message
                    is_struct = False

                print(f"\n{BOLD}{CYAN}ENTRY #{self.message_count:04}{RESET} {DIM}────────────────────────────────────────────────{RESET}")
                print(f"{DIM}Source:{RESET} {client_addr[0]}:{client_addr[1]}")
                print(f"{DIM}Time:  {RESET} {self.get_timestamp()}")
                print(f"{DIM}Format:{RESET} {'Structured (JSON)' if is_struct else 'Plain Text'}")
                print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}")
                
                for line in content.splitlines():
                    print(f"  {line}")
                
                print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}", flush=True)
        except websockets.exceptions.ConnectionClosed:
            print(f"{DIM}[{self.get_timestamp()}]{RESET} {YELLOW}Connection closed{RESET} {client_addr[0]}:{client_addr[1]}", flush=True)

    async def run(self):
        print(f"{BOLD}logd SocketSink {DIM}|{RESET} Wireless Logging Protocol Server")
        print(f"{DIM}Status:  {RESET} Listening")
        print(f"{DIM}Endpoint:{RESET} ws://{self.host}:{self.port}")
        print(f"{DIM}─────────────────────────────────────────────────────────────{RESET}\n", flush=True)

        async with websockets.serve(self.handler, self.host, self.port):
            await asyncio.Future()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Professional logd SocketSink Server")
    parser.add_argument("--host", default=os.getenv('HOST', '127.0.0.1'), help="Host to bind to")
    parser.add_argument("--port", type=int, default=int(os.getenv('PORT', 12345)), help="Port to bind to")
    args = parser.parse_args()

    server = SocketLogServer(args.host, args.port)
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        print(f"\n{DIM}[System]{RESET} Shutdown requested.")
    except Exception as e:
        print(f"\n{BOLD}Error:{RESET} {e}")
        sys.exit(1)
