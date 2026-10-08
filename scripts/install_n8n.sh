#!/bin/bash
set -euo pipefail

# Credentials + timezone injected by Terraform via OCI instance metadata
# (see terraform/main.tf). No secrets are baked into this script.
META="http://169.254.169.254/opc/v2/instance/metadata"
N8N_BASIC_AUTH_USER="$(curl -s "$META/n8n_user" || true)"
N8N_BASIC_AUTH_PASSWORD="$(curl -s "$META/n8n_password" || true)"
N8N_TIMEZONE="$(curl -s "$META/n8n_timezone" || true)"
if [ -z "$N8N_BASIC_AUTH_USER" ]; then N8N_BASIC_AUTH_USER="admin"; fi
if [ -z "$N8N_TIMEZONE" ]; then N8N_TIMEZONE="America/New_York"; fi

# Ensure all files are created in the user's home directory
cd "$HOME"

# Install Docker and Docker Compose
sudo apt update && sudo apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
if [ -n "${USER-}" ]; then
    sudo usermod -aG docker "$USER"
fi
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Compose file — secrets live in n8n.env (written with printf, no shell-quoting pitfalls)
cat <<'EOF' | sudo tee docker-compose.yml > /dev/null
services:
  n8n:
    image: n8nio/n8n
    restart: unless-stopped
    container_name: n8n
    ports:
      - "5678:5678"
    env_file:
      - ./n8n.env
    volumes:
      - ./n8n_data:/home/node/.n8n
EOF

{
  printf 'GENERIC_TIMEZONE=%s\n' "$N8N_TIMEZONE"
  printf 'N8N_BASIC_AUTH_ACTIVE=true\n'
  printf 'N8N_BASIC_AUTH_USER=%s\n' "$N8N_BASIC_AUTH_USER"
  printf 'N8N_BASIC_AUTH_PASSWORD=%s\n' "$N8N_BASIC_AUTH_PASSWORD"
  printf 'N8N_SECURE_COOKIE=false\n'
} | sudo tee n8n.env > /dev/null
sudo chmod 600 n8n.env

# Prepare volume and start container
mkdir -p n8n_data
sudo chown -R 1000:1000 n8n_data
sudo docker-compose -p n8n up -d
