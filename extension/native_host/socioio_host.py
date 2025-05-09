#!/usr/bin/env python
# Native messaging host for Socio.io extension
# This script will be called by the browser when the extension is loaded

import os
import sys
import json
import struct
import subprocess
import threading
import time
import logging
import signal
import atexit

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    filename=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'socioio_host.log'),
    filemode='a'
)

# Global variables
backend_process = None
backend_running = False

def send_message(message):
    """Send a message to the browser extension."""
    encoded_message = json.dumps(message).encode('utf-8')
    sys.stdout.buffer.write(struct.pack('I', len(encoded_message)))
    sys.stdout.buffer.write(encoded_message)
    sys.stdout.buffer.flush()

def read_message():
    """Read a message from the browser extension."""
    raw_length = sys.stdin.buffer.read(4)
    if not raw_length:
        return None
    message_length = struct.unpack('I', raw_length)[0]
    message = sys.stdin.buffer.read(message_length).decode('utf-8')
    return json.loads(message)

def start_backend():
    """Start the Python backend server."""
    global backend_process, backend_running
    
    if backend_running:
        logging.info("Backend is already running")
        return {"status": "already_running"}
    
    try:
        # Get the path to the app.py file
        current_dir = os.path.dirname(os.path.abspath(__file__))
        root_dir = os.path.dirname(os.path.dirname(current_dir))  # Go up two levels
        app_path = os.path.join(root_dir, 'app.py')
        
        logging.info(f"Starting backend from {app_path}")
        
        # Start the backend process
        backend_process = subprocess.Popen(
            [sys.executable, app_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=root_dir
        )
        
        # Set the backend as running
        backend_running = True
        
        # Start a thread to monitor the backend process
        threading.Thread(target=monitor_backend, daemon=True).start()
        
        logging.info("Backend started successfully")
        return {"status": "started"}
    
    except Exception as e:
        logging.error(f"Error starting backend: {str(e)}")
        return {"status": "error", "message": str(e)}

def stop_backend():
    """Stop the Python backend server."""
    global backend_process, backend_running
    
    if not backend_running:
        logging.info("Backend is not running")
        return {"status": "not_running"}
    
    try:
        # Terminate the backend process
        if backend_process:
            backend_process.terminate()
            backend_process.wait(timeout=5)
            backend_running = False
            logging.info("Backend stopped successfully")
            return {"status": "stopped"}
    
    except Exception as e:
        logging.error(f"Error stopping backend: {str(e)}")
        return {"status": "error", "message": str(e)}

def monitor_backend():
    """Monitor the backend process and restart it if it crashes."""
    global backend_process, backend_running
    
    while backend_running:
        # Check if the process is still running
        if backend_process.poll() is not None:
            logging.warning("Backend process has terminated unexpectedly")
            
            # Get the output from the process
            stdout, stderr = backend_process.communicate()
            logging.error(f"Backend stderr: {stderr.decode('utf-8')}")
            
            # Restart the backend
            start_backend()
        
        # Sleep for a bit before checking again
        time.sleep(5)

def cleanup():
    """Clean up resources when the host is terminated."""
    stop_backend()

def main():
    """Main function to handle messages from the extension."""
    # Register cleanup function
    atexit.register(cleanup)
    
    # Start the backend automatically when the host is started
    start_result = start_backend()
    send_message({"action": "backend_status", "result": start_result})
    
    # Main message loop
    try:
        while True:
            message = read_message()
            if not message:
                break
            
            logging.info(f"Received message: {message}")
            
            # Handle different message types
            if message.get("action") == "start_backend":
                result = start_backend()
                send_message({"action": "backend_status", "result": result})
            
            elif message.get("action") == "stop_backend":
                result = stop_backend()
                send_message({"action": "backend_status", "result": result})
            
            elif message.get("action") == "check_backend":
                result = {"status": "running" if backend_running else "stopped"}
                send_message({"action": "backend_status", "result": result})
            
            else:
                send_message({"action": "unknown", "message": "Unknown action"})
    
    except Exception as e:
        logging.error(f"Error in main loop: {str(e)}")
    
    finally:
        # Clean up when the host is terminated
        cleanup()

if __name__ == "__main__":
    main()