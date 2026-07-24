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

# Install menu
echo "Downloading menu script..."
wget -4 -q -O /usr/local/bin/menu "$MENU_URL"
if [ ! -s /usr/local/bin/menu ]; then
    echo "ERROR: Failed to download menu script or file is empty."
    exit 1
fi
chmod +x /usr/local/bin/menu

echo "Applying xxxJIHAD SSH configuration..."

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F-%H%M%S)"

# Backup current SSH config
cp "$SSHD_CONFIG" "$BACKUP"

# Download xxxJIHAD SSH config
wget -4 -q -O "$SSHD_CONFIG" "$SSHD_URL"
chmod 600 "$SSHD_CONFIG"

# Validate SSH config (silent)
if ! sshd -t 2>/dev/null; then
    echo "ERROR: SSH configuration is invalid!"
    echo "Restoring previous configuration..."
    cp "$BACKUP" "$SSHD_CONFIG"
    exit 1
fi

echo "SSH configuration validated."

# Restart SSH quietly and safely
restart_ssh() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart sshd 2>/dev/null \
        || systemctl restart ssh 2>/dev/null \
        || return 1
    elif command -v service >/dev/null 2>&1; then
        service sshd restart 2>/dev/null \
        || service ssh restart 2>/dev/null \
        || return 1
    elif command -v rc-service >/dev/null 2>&1; then
        rc-service sshd restart 2>/dev/null \
        || rc-service ssh restart 2>/dev/null \
        || return 1
    elif [ -x /etc/init.d/sshd ]; then
        /etc/init.d/sshd restart >/dev/null 2>&1
    elif [ -x /etc/init.d/ssh ]; then
        /etc/init.d/ssh restart >/dev/null 2>&1
    else
        return 1
    fi
}

if restart_ssh; then
    echo "SSH service restarted."
else
    echo "WARNING: SSH restart not supported on this system."
    echo "SSH config applied but service was not restarted automatically."
fi

# Run xxxJIHAD setup
echo "Running initial setup..."
/usr/local/bin/menu --install-setup || echo "Note: Initial setup finished with some notices."

echo "Installation complete!"
echo "Type 'menu' to start."
