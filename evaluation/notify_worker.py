import os
import json
import socket
import sys
import argparse
import requests


# import ../pash/compiler/config
# NOTE: this file is meant to be a light-weight way to 
# 1) load worker:datanode mappings
# 2) send a message to one of the datanodes

# Many functions are copied from worker_manager.py
# This is used in evaluation to send a datanode a message to bring itself back up after being killed
HOST = socket.gethostbyname(socket.gethostname())
PORT = 55555        # Port to listen on (non-privileged ports are > 1023)
DATANODE_META_SERVER_PORT = 12345
NODEMANAGER_META_SERVER_PORT = 12340
PASH_TOP = os.environ['PASH_TOP']

sys.path.append(f"{PASH_TOP}/compiler/dspash")  # Add the directory to sys.path
from socket_utils import SocketManager, encode_request, decode_request, send_msg, recv_msg
KILL_WITNESS_PATH = os.path.join(os.path.dirname(os.path.realpath(__file__)), '../pash/compiler/dspash/kill_witness.log')


class WorkerConnection:
    def __init__(self, name, host, ports):
        self.name = name
        self._host = socket.gethostbyaddr(host)[2][0] # get ip address in case host needs resolving
        self._ports = ports
        self._running_processes = 0
        self._online = True
        # assume client service is running, can add a way to activate later
        try:
            self._sockets = []
            for _port in self._ports:
                _socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                _socket.connect((self._host, _port))
                self._sockets.append(_socket)
        except Exception as e:
            self._online = False
        
    def is_online(self):
        # TODO: create a ping to confirm is online
        return self._online


    def send_payload(self, payload) -> bool:
        for _socket in self._sockets:
            request = encode_request(payload)
            send_msg(_socket, request)
            response_data = recv_msg(_socket)
            if not response_data or decode_request(response_data)['status'] != "OK":
                raise Exception(f"didn't recieved ack on request {response_data}")
            else:
                # response = decode_request(response_data)
                return True

    def close(self):
        for _socket in self._sockets:
            _socket.send("Done")
            _socket.close()

    def __str__(self):
        return f"Worker {self._host}:{self._ports}"

    def host(self):
        return self._host

class Messenger():
    def __init__(self, workers: WorkerConnection = []):
        self.workers = workers
        self.host = socket.gethostbyname(socket.gethostname())
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.s.bind((HOST, PORT))
        self.s.listen()

    def __del__(self):
        # Cleanup resources here, such as closing the socket
        self.s.close()
        
    def add_worker(self, name, host, ports):
            self.workers.append(WorkerConnection(name, host, ports))

    def add_workers_from_cluster_config(self, config_path):
        with open(config_path, 'r') as f:
            cluster_config = json.load(f)

        workers = cluster_config["workers"]
        for name, worker in workers.items():
            host = worker['host']
            self.add_worker(name, host, [DATANODE_META_SERVER_PORT, NODEMANAGER_META_SERVER_PORT])

        addrs = {conn.host() for conn in self.workers}

    def send_payload_to_worker(self, payload, receiver):
        receiver_host = socket.gethostbyaddr(receiver)[2][0]
        socket.gethostbyaddr(receiver)[2][0]
        for worker in self.workers:
            if worker.host() == receiver_host:
                worker.send_payload(payload)
                return


def send_payload(host, port, endpoint, payload):
    try:
        url = f"http://{host}:{port}/{endpoint}"
        print(url)
        # Send the POST request with the payload as JSON
        response = requests.post(url, json=payload)
        # Check if the request was successful
        if response.status_code == 200:
            print("Received response:", response.text)
        else:
            print(f"Failed to send payload, status code: {response.status_code}")
            print("Response:", response.text)
    except requests.RequestException as e:
        print(f"Request error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Send a message to a datanode.')
    parser.add_argument('type', choices=['kill', 'resurrect'], help='Type of action to perform')
    parser.add_argument('target', help='Hostname of the target datanode')

    args = parser.parse_args()

    try:
        receiver_host = socket.gethostbyaddr(args.target)[2][0]
    except socket.error as e:
        print(f"Hostname resolution error: {e}")
        sys.exit(1)

    # receiver = "datanode1" # pass as arg
    # receiver_host = socket.gethostbyaddr(receiver)[2][0]
    payload = {
        "type": args.type,
    }
    for receiver_port in [DATANODE_META_SERVER_PORT, NODEMANAGER_META_SERVER_PORT]:
        # Send the payload to the target
        send_payload(receiver_host, receiver_port, args.type, payload)


