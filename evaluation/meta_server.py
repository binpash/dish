import socket
import logging
import subprocess
import time
import traceback
import json

# Configure logging
logging.basicConfig(filename='/meta_server.log', level=logging.INFO,
                    format='%(asctime)s %(levelname)s:%(message)s')

def start_server(host='0.0.0.0', port=12345):
    while True:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
                s.bind((host, port))
                s.listen()
                logging.info(f"Server listening on {host}:{port}")
                while True:
                    conn, addr = s.accept()
                    with conn:
                        logging.info(f"Connected by {addr}")
                        data = conn.recv(1024)
                        if not data:
                            break
                        data = json.loads(data.decode())
                        logging.info(f"Received message: {data}")
                        if data["type"] == "kill":
                            script_path = "/opt/dish/evaluation/kill_datanode.sh"
                            subprocess.run("/bin/sh " + script_path, shell=True)
                            logging.info("Killed the dummy process")
                            time.sleep(1)
                        elif data["type"] == "resurrect":
                            pass
                        conn.sendall(b"Message received")
        except Exception as e:
            logging.error(f"An error occurred: {e}")
            logging.error(traceback.format_exc())

if __name__ == "__main__":
    start_server()
