#!/usr/bin/env python
# Test script for the native messaging host

import os
import sys
import subprocess
import time

print("Testing native messaging host...")

# Get the directory where the script is located
current_dir = os.path.dirname(os.path.abspath(__file__))

# Path to the host script
host_script = os.path.join(current_dir, "socioio_host.py")

# Check if the host script exists
if not os.path.exists(host_script):
    print(f"ERROR: Host script not found at {host_script}")
    sys.exit(1)

print(f"Host script found at {host_script}")

# Check if Python is available
try:
    python_version = subprocess.check_output(["python", "--version"], stderr=subprocess.STDOUT).decode().strip()
    print(f"Python is available: {python_version}")
except Exception as e:
    print(f"ERROR: Python not found: {str(e)}")
    sys.exit(1)

# Try to start the host script
print("Attempting to start the host script...")
try:
    # Start the process
    process = subprocess.Popen(
        ["python", host_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait a bit
    time.sleep(2)
    
    # Check if the process is still running
    if process.poll() is None:
        print("Host script started successfully and is still running")
        
        # Get the output so far
        stdout, stderr = process.communicate(timeout=1)
        if stdout:
            print(f"Host script stdout: {stdout.decode()}")
        if stderr:
            print(f"Host script stderr: {stderr.decode()}")
        
        # Terminate the process
        process.terminate()
        print("Host script terminated")
    else:
        # Process has already terminated
        stdout, stderr = process.communicate()
        print(f"Host script exited with code {process.returncode}")
        if stdout:
            print(f"Host script stdout: {stdout.decode()}")
        if stderr:
            print(f"Host script stderr: {stderr.decode()}")
        
except Exception as e:
    print(f"ERROR: Failed to start host script: {str(e)}")
    sys.exit(1)

# Check if the log file exists
log_file = os.path.join(current_dir, "socioio_host.log")
if os.path.exists(log_file):
    print(f"Log file found at {log_file}")
    
    # Show the last few lines of the log
    try:
        with open(log_file, "r") as f:
            lines = f.readlines()
            print("Last 10 lines of the log file:")
            for line in lines[-10:]:
                print(f"  {line.strip()}")
    except Exception as e:
        print(f"ERROR: Failed to read log file: {str(e)}")
else:
    print(f"WARNING: Log file not found at {log_file}")

print("Test completed")