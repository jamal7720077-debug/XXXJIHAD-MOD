#!/bin/bash
set -e

# Must be root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

echo "Installing xxxJIHAD Manager with Jihad Shield Protection..."
mkdir -p /etc/xxxJIHAD

# URLs (Using master branch and correct repo name)
REPO_URL="https://raw.githubusercontent.com/jamal7720077-debug/XXXJIHAD-MOD/master"
MENU_URL="${REPO_URL}/menu.sh"
SSHD_URL="${REPO_URL}/ssh"

# Remove old menu if exists
rm -f /usr/local/bin/menu

# Install menu
echo "Downloading menu script from: $MENU_URL"
wget --no-check-certificate -4 -q -O /usr/local/bin/menu "$MENU_URL"

if [ ! -s /usr/local/bin/menu ]; then
    echo "ERROR: Failed to download menu script or file is empty."
    # Try alternative download method
    curl -L -s -o /usr/local/bin/menu "$MENU_URL"
fi

if [ ! -s /usr/local/bin/menu ]; then
    echo "CRITICAL ERROR: Could not download menu script."
    exit 1
fi

echo "Setting permissions for /usr/local/bin/menu..."
chmod 755 /usr/local/bin/menu
chown root:root /usr/local/bin/menu

echo "Applying xxxJIHAD SSH configuration..."
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F-%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP"
wget --no-check-certificate -4 -q -O "$SSHD_CONFIG" "$SSHD_URL" || curl -L -s -o "$SSHD_CONFIG" "$SSHD_URL"
chmod 600 "$SSHD_CONFIG"

# Validate SSH config
if ! sshd -t 2>/dev/null; then
    echo "ERROR: SSH configuration is invalid! Restoring backup..."
    cp "$BACKUP" "$SSHD_CONFIG"
else
    echo "SSH configuration validated."
fi

# Run xxxJIHAD setup
echo "Running initial setup..."
# Use absolute path and ensure it's executable
/usr/local/bin/menu --install-setup || bash /usr/local/bin/menu --install-setup || echo "Note: Initial setup finished with notices."

echo "Installation complete!"
echo "---------------------------------------"
echo "You can now start the manager by typing: menu"
echo "If 'menu' fails, try: bash /usr/local/bin/menu"
echo "---------------------------------------"
