import os
import json
import socket
import sys


# import ../pash/compiler/config
# NOTE: this file is meant to be a light-weight way to 
# 1) load worker:datanode mappings
# 2) send a message to one of the datanodes

# Many functions are copied from worker_manager.py
# This is used in evaluation to send a datanode a message to bring itself back up after being killed
HOST = socket.gethostbyname(socket.gethostname())
PORT = 55555        # Port to listen on (non-privileged ports are > 1023)
PASH_TOP = os.environ['PASH_TOP']

sys.path.append(f"{PASH_TOP}/compiler/dspash")  # Add the directory to sys.path
from socket_utils import SocketManager, encode_request, decode_request, send_msg, recv_msg

class WorkerConnection:
    def __init__(self, name, host, port):
        self.name = name
        self._host = socket.gethostbyaddr(host)[2][0] # get ip address in case host needs resolving
        self._port = port
        self._running_processes = 0
        self._online = True
        # assume client service is running, can add a way to activate later
        try:
            self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self._socket.connect((self._host, self._port))
        except Exception as e:
            self._online = False
        
    def is_online(self):
        # TODO: create a ping to confirm is online
        return self._online

    def send_resurrect_request(self) -> bool:
        request_dict = { 'type': 'resurrect' }
        request = encode_request(request_dict)
        send_msg(self._socket, request)
        response_data = recv_msg(self._socket)
        if not response_data or decode_request(response_data)['status'] != "OK":
            raise Exception(f"didn't recieved ack on request {response_data}")
        else:
            # response = decode_request(response_data)
            return True

    def close(self):
        self._socket.send("Done")
        self._socket.close()

    def __str__(self):
        return f"Worker {self._host}:{self._port}"

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
        
    def add_worker(self, name, host, port):
            self.workers.append(WorkerConnection(name, host, port))

    def add_workers_from_cluster_config(self, config_path):
        with open(config_path, 'r') as f:
            cluster_config = json.load(f)

        workers = cluster_config["workers"]
        for name, worker in workers.items():
            host = worker['host']
            port = worker['port']
            self.add_worker(name, host, port)

        addrs = {conn.host() for conn in self.workers}

    def send_resurrect_request(self, resurrect_target):
        resurrect_target_host = socket.gethostbyaddr(resurrect_target)[2][0]
        socket.gethostbyaddr(resurrect_target)[2][0]
        for worker in self.workers:
            if worker.host() == resurrect_target_host:
                worker.send_resurrect_request()
                return

if __name__ == "__main__":
    # Arity check
    if len(sys.argv) < 2:
        print("Usage: python3 type [optional args]")
        sys.exit(1)

    messenger = Messenger()
    # Load workers
    messenger.add_workers_from_cluster_config(os.path.join(PASH_TOP, 'cluster.json'))

    # Handle request
    type = sys.argv[1]
    if type == "resurrect":
        resurrect_target = sys.argv[2]
        messenger.send_resurrect_request(resurrect_target)
    else:
        print("Unsupported type of request")
        sys.exit(1)