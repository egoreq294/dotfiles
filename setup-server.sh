#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Configuration
# ============================================================

DOTFILES_DIR="$HOME/dotfiles"

SSH_CONFIG="/etc/ssh/sshd_config"
FAIL2BAN_CONFIG="/etc/fail2ban/jail.d/sshd.local"

NVIM_DIR="/opt/nvim-linux-x86_64"
NVIM_BIN="/usr/local/bin/nvim"

# Random SSH port range.
SSH_PORT_MIN=10000
SSH_PORT_MAX=60000

# ============================================================
# Helpers
# ============================================================

log() {
  echo
  echo "==> $1"
}

error() {
  echo
  echo "ERROR: $1" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_sudo() {
  if ! sudo -v; then
    error "sudo is required."
  fi
}

# ============================================================
# Initial checks
# ============================================================

if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root."
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
  error "Dotfiles directory not found: $DOTFILES_DIR"
fi

if [[ ! -f "$DOTFILES_DIR/config/fish/config.fish" ]]; then
  error "Fish config not found: $DOTFILES_DIR/config/fish/config.fish"
fi

if [[ ! -f "$DOTFILES_DIR/config/nvim/init.lua" ]]; then
  error "Neovim config not found: $DOTFILES_DIR/config/nvim/init.lua"
fi

require_sudo

# ============================================================
# Check Ubuntu
# ============================================================

log "Checking operating system"

if [[ ! -f /etc/os-release ]]; then
  error "Cannot detect operating system."
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
  error "This script supports Ubuntu only. Detected: ${ID:-unknown}"
fi

echo "Ubuntu ${VERSION_ID}"

# ============================================================
# Update system
# ============================================================

log "Updating system"

sudo apt update
sudo apt upgrade -y

# ============================================================
# Install packages
# ============================================================

log "Installing packages"

sudo apt install -y \
  git \
  curl \
  wget \
  fzf \
  make \
  cmake \
  fish \
  ripgrep \
  fd-find \
  unzip \
  gcc \
  g++ \
  qemu-guest-agent \
  fail2ban \
  openssh-server \
  fastfetch

# ============================================================
# Install latest Neovim
# ============================================================

log "Installing latest Neovim"

TMP_DIR="$(mktemp -d)"
NVIM_ARCHIVE="$TMP_DIR/nvim-linux-x86_64.tar.gz"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

curl -fL \
  "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
  -o "$NVIM_ARCHIVE"

sudo rm -rf "$NVIM_DIR"

sudo tar \
  -xzf "$NVIM_ARCHIVE" \
  -C /opt

sudo ln -sfn \
  "$NVIM_DIR/bin/nvim" \
  "$NVIM_BIN"

echo
echo "Neovim:"
nvim --version | head -n 1

# ============================================================
# QEMU Guest Agent
# ============================================================

log "Enabling QEMU Guest Agent"

sudo systemctl enable --now qemu-guest-agent

# ============================================================
# Dotfiles
# ============================================================

log "Installing dotfiles"

mkdir -p "$HOME/.config"

# ------------------------------------------------------------
# Fish
# ------------------------------------------------------------

rm -rf "$HOME/.config/fish"

ln -s \
  "$DOTFILES_DIR/config/fish" \
  "$HOME/.config/fish"

# ------------------------------------------------------------
# Neovim
# ------------------------------------------------------------

rm -rf "$HOME/.config/nvim"

ln -s \
  "$DOTFILES_DIR/config/nvim" \
  "$HOME/.config/nvim"

# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

if [[ -f "$DOTFILES_DIR/home/.gitconfig" ]]; then
  rm -f "$HOME/.gitconfig"

  ln -s \
    "$DOTFILES_DIR/home/.gitconfig" \
    "$HOME/.gitconfig"
fi

# ============================================================
# Fish as default shell
# ============================================================

log "Setting Fish as default shell"

FISH_PATH="$(command -v fish)"

if [[ "$SHELL" != "$FISH_PATH" ]]; then
  sudo chsh -s "$FISH_PATH" "$USER"
  echo "Default shell changed to $FISH_PATH"
else
  echo "Fish is already the default shell."
fi

# ============================================================
# SSH
# ============================================================

log "Checking SSH configuration"

if ! command_exists sshd; then
  error "sshd was not found."
fi

# ------------------------------------------------------------
# Get effective SSH port
# ------------------------------------------------------------

CURRENT_SSH_PORT="$(
    sudo sshd -T |
        awk '$1 == "port" { print $2; found=1 } END { if (!found) exit 1 }'
)"

if [[ -z "$CURRENT_SSH_PORT" ]]; then
  error "Could not determine current SSH port."
fi

echo "Current SSH port: $CURRENT_SSH_PORT"

# ============================================================
# SSH first-time hardening
# ============================================================

if [[ "$CURRENT_SSH_PORT" == "22" ]]; then

  log "SSH is using default port 22"
  log "Applying SSH hardening"

  # --------------------------------------------------------
  # Find free random port
  # --------------------------------------------------------

  find_free_ssh_port() {
    while true; do
      PORT="$(
        shuf \
          -i "${SSH_PORT_MIN}-${SSH_PORT_MAX}" \
          -n 1
      )"

      if ! ss -ltn | awk '{print $4}' | grep -qE "[:.]${PORT}$"; then
        echo "$PORT"
        return
      fi
    done
  }

  SSH_PORT="$(find_free_ssh_port)"

  echo "Selected new SSH port: $SSH_PORT"

  # --------------------------------------------------------
  # Create dedicated SSH configuration
  #
  # Instead of modifying sshd_config directly, we create
  # a dedicated config file in sshd_config.d.
  # --------------------------------------------------------

  SSH_HARDENING_CONFIG="/etc/ssh/sshd_config.d/99-server-hardening.conf"

  sudo mkdir -p /etc/ssh/sshd_config.d

  sudo tee "$SSH_HARDENING_CONFIG" >/dev/null <<EOF
# Managed by dotfiles setup-server.sh

Port $SSH_PORT
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

  # --------------------------------------------------------
  # Validate SSH configuration
  # --------------------------------------------------------

  log "Validating SSH configuration"

  if ! sudo sshd -t; then
    error "sshd configuration is invalid. SSH service was NOT restarted."
  fi

  # --------------------------------------------------------
  # Configure UFW if it exists and is active
  # --------------------------------------------------------

  if command_exists ufw; then
    if sudo ufw status | grep -q "Status: active"; then

      log "Opening SSH port in UFW"

      sudo ufw allow "${SSH_PORT}/tcp"
      sudo ufw delete allow 22/tcp 2>/dev/null || true

      echo "UFW rule added for SSH port $SSH_PORT"
    else
      echo "UFW is installed but inactive. No firewall rule added."
    fi
  else
    echo "UFW is not installed. Skipping firewall configuration."
  fi

  # --------------------------------------------------------
  # Restart SSH
  # --------------------------------------------------------

  log "Restarting SSH"

  if systemctl list-unit-files | grep -q '^ssh.service'; then
    sudo systemctl restart ssh
  else
    sudo systemctl restart sshd
  fi

  CURRENT_SSH_PORT="$SSH_PORT"

  echo
  echo "SSH hardening completed."

else

  log "SSH is already using port $CURRENT_SSH_PORT"

  echo "SSH configuration will NOT be changed."
  echo "This server appears to be already configured."

fi

# ============================================================
# Fail2Ban
# ============================================================

log "Configuring Fail2Ban"

sudo mkdir -p "$(dirname "$FAIL2BAN_CONFIG")"

sudo tee "$FAIL2BAN_CONFIG" >/dev/null <<EOF
[sshd]
enabled = true
port = $CURRENT_SSH_PORT
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
EOF

sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban

# ============================================================
# Final checks
# ============================================================

log "Running final checks"

echo
echo "------------------------------------------------------------"
echo "Fish"
echo "------------------------------------------------------------"

fish --version

echo
echo "------------------------------------------------------------"
echo "Neovim"
echo "------------------------------------------------------------"

nvim --version | head -n 1

echo
echo "------------------------------------------------------------"
echo "SSH"
echo "------------------------------------------------------------"

echo "Port $CURRENT_SSH_PORT"
echo "PasswordAuthentication no"
echo "PermitRootLogin no"
echo "PubkeyAuthentication yes"

echo
echo "------------------------------------------------------------"
echo "Services"
echo "------------------------------------------------------------"

echo
echo "SSH:"
sudo systemctl is-active ssh 2>/dev/null ||
  sudo systemctl is-active sshd 2>/dev/null || true

echo
echo "Fail2Ban:"
sudo systemctl is-active fail2ban || true

echo
echo "QEMU Guest Agent:"
sudo systemctl is-active qemu-guest-agent || true

echo
echo "------------------------------------------------------------"
echo "Fail2Ban SSH jail"
echo "------------------------------------------------------------"

sudo fail2ban-client status sshd 2>/dev/null || true

echo
echo "============================================================"
echo "SERVER SETUP COMPLETE"
echo "============================================================"
echo
echo "SSH:"
echo "Port $CURRENT_SSH_PORT"
echo "PasswordAuthentication no"
echo "PermitRootLogin no"
echo "PubkeyAuthentication yes"
echo
echo "IMPORTANT:"
echo "Save the SSH port somewhere!"
echo
echo "Reconnect using:"
echo
echo "ssh -p $CURRENT_SSH_PORT $USER@SERVER"
echo
echo "============================================================"
