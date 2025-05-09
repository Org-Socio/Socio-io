#!/bin/bash
# Socio.io Native Host Installer for Linux

echo "Installing Socio.io Native Messaging Host..."

# Get the directory where the script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make the Python script executable
chmod +x "$DIR/socioio_host.py"
chmod +x "$DIR/socioio_host.sh"

# Create the Chrome native messaging host manifest directory if it doesn't exist
CHROME_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
mkdir -p "$CHROME_DIR"

# Create the Chrome Beta native messaging host manifest directory if it doesn't exist
CHROME_BETA_DIR="$HOME/.config/google-chrome-beta/NativeMessagingHosts"
mkdir -p "$CHROME_BETA_DIR"

# Create the Chromium native messaging host manifest directory if it doesn't exist
CHROMIUM_DIR="$HOME/.config/chromium/NativeMessagingHosts"
mkdir -p "$CHROMIUM_DIR"

# Create the Edge native messaging host manifest directory if it doesn't exist
EDGE_DIR="$HOME/.config/microsoft-edge/NativeMessagingHosts"
mkdir -p "$EDGE_DIR"

# Copy the manifest to the Chrome directory
cp "$DIR/socioio_host_unix.json" "$CHROME_DIR/com.socioio.contentfilter.json"
if [ $? -ne 0 ]; then
    echo "Failed to copy manifest to Chrome directory."
    exit 1
fi

# Copy the manifest to the Chrome Beta directory
cp "$DIR/socioio_host_unix.json" "$CHROME_BETA_DIR/com.socioio.contentfilter.json"
if [ $? -ne 0 ]; then
    echo "Failed to copy manifest to Chrome Beta directory."
    exit 1
fi

# Copy the manifest to the Chromium directory
cp "$DIR/socioio_host_unix.json" "$CHROMIUM_DIR/com.socioio.contentfilter.json"
if [ $? -ne 0 ]; then
    echo "Failed to copy manifest to Chromium directory."
    exit 1
fi

# Copy the manifest to the Edge directory
cp "$DIR/socioio_host_unix.json" "$EDGE_DIR/com.socioio.contentfilter.json"
if [ $? -ne 0 ]; then
    echo "Failed to copy manifest to Edge directory."
    exit 1
fi

echo "Native messaging host installed successfully."
echo "You can now use the Socio.io extension with automatic backend startup."