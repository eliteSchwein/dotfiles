#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -r "$SCRIPT_DIR/logger.sh" ]]; then
  # Use the installer's existing logger when this script is part of the repo.
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/logger.sh"
else
  log_info() { printf '[INFO] %s\n' "$*"; }
  log_ok()   { printf '[ OK ] %s\n' "$*"; }
  log_warn() { printf '[WARN] %s\n' "$*" >&2; }
fi

# Run as the user whose wallet is being configured, never with sudo.
if (( EUID == 0 )); then
  log_warn 'Run this installer as your regular user, not with sudo.'
  exit 1
fi

log_info 'KWallet Install: starting'

# This installation uses the existing Secret Service wallet named "Default Keyring".
# KWallet must create the wallet itself; never touch an empty .kwl file.
if command -v paru >/dev/null 2>&1; then
  paru -S --needed --noconfirm kwallet kwalletmanager
else
  sudo pacman -S --needed --noconfirm kwallet kwalletmanager
fi

if [[ ! -x /usr/bin/ksecretd ]]; then
  log_warn '/usr/bin/ksecretd is missing after installing kwallet.'
  exit 1
fi

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
config_file="$config_home/kwalletrc"
wallet_dir="$data_home/kwalletd"
wallet_name="Default Keyring"
wallet_file="$wallet_dir/$wallet_name.kwl"
service_dir="$data_home/dbus-1/services"
service_file="$service_dir/org.freedesktop.secrets.service"

mkdir -p -- "$config_home" "$wallet_dir" "$service_dir" "$config_home/autostart"

# Overwrite the entire configuration on each install, as requested.
# Existing encrypted wallet contents in $wallet_dir are untouched.
if [[ -s "$wallet_file" ]]; then
  first_use=false
else
  first_use=true
fi

log_info 'Overwrite KWallet configuration'
cat > "$config_file" <<EOF
[Wallet]
Close When Idle=false
Default Wallet=Default Keyring
Enabled=true
First Use=$first_use
Leave Open=true
Local Wallet=Default Keyring
Prompt on Open=false
Use One Wallet=true

[KSecretD]
Enabled=true

[org.freedesktop.secrets]
apiEnabled=true
EOF

if [[ -s "$wallet_file" ]]; then
  log_ok 'Existing Default Keyring.kwl found; wallet data preserved.'
elif [[ -e "$wallet_file" ]]; then
  log_warn 'Default Keyring.kwl exists but is empty; inspect it before creating a new wallet.'
else
  log_warn 'No wallet yet. Open KWalletManager and create Default Keyring (classic Blowfish).'
  log_warn 'For a passwordless wallet, leave the password empty (less secure).'
fi

# Only KWallet/ksecretd should own org.freedesktop.secrets.
# The per-user D-Bus service makes activation work in non-Plasma sessions too.
log_info 'Configure ksecretd as the Secret Service provider'
cat > "$service_file" <<'SERVICE'
[D-BUS Service]
Name=org.freedesktop.secrets
Exec=/usr/bin/ksecretd
SERVICE

# Disable just GNOME Keyring's competing secrets autostart, not its SSH/PKCS#11
# components. Do not kill any currently-running daemon mid-session.
printf '[Desktop Entry]\nType=Application\nHidden=true\n' \
  > "$config_home/autostart/gnome-keyring-secrets.desktop"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  for unit in gnome-keyring-daemon.socket gnome-keyring-daemon.service; do
    if systemctl --user cat "$unit" >/dev/null 2>&1; then
      if ! systemctl --user mask --now "$unit"; then
        log_warn "Could not mask $unit; check for a GNOME Keyring conflict."
      fi
    fi
  done
  systemctl --user daemon-reload
else
  log_warn 'No running systemd user manager; GNOME Keyring unit masking was skipped.'
fi

log_ok 'KWallet Install: done. Log out and back in to apply the provider change.'
log_info "Configuration: $config_file"
log_info "Wallet storage: $wallet_dir"
log_info 'After logging in, verify the provider with: busctl --user status org.freedesktop.secrets'
log_info 'Check default alias with: busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service ReadAlias s default'
