import socket
import logging
import subprocess
import time
import traceback
import json
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(filename='/meta_server.log', level=logging.INFO,
                    format='%(asctime)s %(levelname)s:%(message)s')

# Initialize Flask app
app = Flask(__name__)

# Global variable
isLive = True

def __kill():
    time.sleep(1)
    global isLive
    try:
        # Update state
        isLive = False

        # Tear down dish and hadoop-streaming internal processes
        script_path = "/opt/dish/runtime/scripts/killall.sh"
        subprocess.run("/bin/sh " + script_path, shell=True)
        logging.info("Service killed")
        return jsonify({"kill": "done"}), 200
    except Exception as e:
        logging.error(f"Kill error: {e}")
        return jsonify({"error": "failed to kill"}), 500

def __resurrect():
    time.sleep(1)
    global isLive
    try:
        # Update state
        isLive = True

        # Bring back dish and hadoop-streaming internal processes
        script_path = "$DISH_TOP/docker-hadoop/datanode/run.sh"
        subprocess.run("/bin/bash " + script_path + " --resurrect", shell=True)
        time.sleep(1)
        
        logging.info("Service resurrected")
        
        return jsonify({"resurrect": "done"}), 200
    except Exception as e:
        logging.error(f"Resurrect error: {e}")
        return jsonify({"error": "failed to resurrect"}), 500


@app.route('/health', methods=['GET'])
def health_check():
    try:
        # Customize health check logic as needed
        if isLive:
            return jsonify({"status": "healthy"}), 200
        else:
            return jsonify({"status": "unhealthy"}), 500
    except Exception as e:
        logging.error(f"Health check failed: {e}")
        return jsonify({"status": "unhealthy"}), 500

@app.route('/resurrect', methods=['POST'])
def resurrect():
    try:
        __resurrect()
        
        logging.info("Service resurrected")
        
        return jsonify({"resurrect": "done"}), 200
    except Exception as e:
        logging.error(f"Resurrect error: {e}")
        return jsonify({"error": "failed to resurrect"}), 500
    
@app.route('/kill', methods=['POST'])
def kill():
    global isLive
    try:
        __kill()

        logging.info("Service killed")
        return jsonify({"kill": "done"}), 200
    except Exception as e:
        logging.error(f"Kill error: {e}")
        return jsonify({"error": "failed to kill"}), 500


if __name__ == "__main__":
    # Run Flask app in a separate thread or process
    from threading import Thread
    flask_thread = Thread(target=lambda: app.run(host='0.0.0.0', port=12345))
    flask_thread.start()

    # Start the original socket server
    # start_server()
