#!/bin/bash
set -e

# environment variables
echo "Exporting environment variables for SSH sessions..."
printenv | grep -E '^HF_|^CUDA_|^NCCL_|^JUPYTER_|^SSH_|^PUBLIC_|^USER_|^UNSLOTH_|^PATH=' | \
    sed 's/^\([^=]*\)=\(.*\)$/export \1="\2"/' > /tmp/unsloth_environment

# Source it in user's bashrc (no sudo needed)
echo 'source /tmp/unsloth_environment' >> /home/unsloth/.bashrc

# Use USER_PASSWORD from env, or default to 'unsloth'.
FINAL_PASSWORD="${USER_PASSWORD:-unsloth}"

# Set the password for the unsloth user
echo "unsloth:${FINAL_PASSWORD}" | sudo chpasswd
echo "User 'unsloth' password set."

# Default values
export JUPYTER_PORT=${JUPYTER_PORT:-8888}
export JUPYTER_PASSWORD="${JUPYTER_PASSWORD:-${FINAL_PASSWORD}}"


# Configure ssh
if [ ! -z "$SSH_KEY" ]; then
    PUBLIC_SSH_KEY="$SSH_KEY"
elif [ ! -z "$PUBLIC_KEY" ]; then
    PUBLIC_SSH_KEY="$PUBLIC_KEY"
else
    PUBLIC_SSH_KEY=""
fi

if [ ! -z "$PUBLIC_SSH_KEY" ]; then
    echo "Setting up SSH key..."

    mkdir -p /home/unsloth/.ssh
    chmod 700 /home/unsloth/.ssh
    echo "$PUBLIC_SSH_KEY" > /home/unsloth/.ssh/authorized_keys
    chmod 600 /home/unsloth/.ssh/authorized_keys
    chown -R unsloth:runtimeusers /home/unsloth/.ssh
fi

echo "Checking SSH host keys..."
# Check if all required host keys exist and are not empty
HOST_KEYS_OK=true
for key_type in rsa ecdsa ed25519; do
    key_file="/etc/ssh/ssh_host_${key_type}_key"
    if [ ! -f "$key_file" ] || [ ! -s "$key_file" ]; then
        echo "Missing or empty SSH host key: $key_file"
        HOST_KEYS_OK=false
        break
    fi
done

if [ "$HOST_KEYS_OK" = false ]; then
    echo "Generating SSH host keys..."
    # Remove any existing (possibly corrupted) keys
    sudo rm -f /etc/ssh/ssh_host_*
    # Generate fresh keys
    sudo ssh-keygen -A
    # Verify they were created
    sudo ls -la /etc/ssh/ssh_host_* 2>/dev/null || echo "Warning: SSH host keys may not have been generated properly"
else
    echo "SSH host keys already exist and appear valid"
fi

# Configure Jupyter
if [ ! -f /home/unsloth/.jupyter/jupyter_lab_config.py ]; then
    if [ ! -f /home/unsloth/.jupyter/jupyter_lab_config.py ]; then
        echo "Generating Jupyter configuration..."
        jupyter lab --generate-config
    fi

    python3 -c "
from jupyter_server.auth import passwd
import os

password_hash = passwd('${JUPYTER_PASSWORD}')
config_file = '/home/unsloth/.jupyter/jupyter_lab_config.py'

config_content = ''
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        lines = f.readlines()
    lines = [line for line in lines if not line.strip().startswith('c.ServerApp.password')]
    config_content = ''.join(lines)

config_content += f'''
c.ServerApp.password = '{password_hash}'
c.ServerApp.allow_root = False
c.ServerApp.allow_remote_access = True
c.ServerApp.open_browser = False
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.notebook_dir = '/workspace'
c.ServerApp.terminado_settings = {{\'shell_command\': [\'/bin/bash\', \'-l\']}}
'''

with open(config_file, 'w') as f:
    f.write(config_content)
"
fi

echo "Handing over control to supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
