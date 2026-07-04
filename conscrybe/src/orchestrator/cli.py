#!/usr/bin/env python3
import socket
import sys
import os

SOCKET_PATH = "/tmp/conscrybe.sock"

def main():
    if len(sys.argv) < 2:
        print("Usage: conscrybe-cli [toggle|cancel]")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd not in ["toggle", "cancel"]:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCKET_PATH)
            s.sendall(f"{cmd}\n".encode('utf-8'))
    except socket.error as e:
        print(f"Could not connect to ConScrybe orchestrator: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
