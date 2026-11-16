#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

# KWallet as the only Secret Service provider (classic blowfish, no password).
# gnome-keyring and ksecretd both want org.freedesktop.secrets; when gnome-keyring wins,
# kwalletd6 can't see its own wallets and re-runs the first-use wizard every boot.

log_info "KWallet Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Install KWallet Packages"
paru -S kwallet kwalletmanager "${PACMAN_FLAGS[@]}"

log_info "Disable gnome-keyring"
if systemctl --user list-unit-files gnome-keyring-daemon.socket >/dev/null 2>&1; then
  systemctl --user mask --now gnome-keyring-daemon.socket gnome-keyring-daemon.service || true
fi
mkdir -p ~/.config/autostart
for n in gnome-keyring-secrets gnome-keyring-pkcs11; do
  printf '[Desktop Entry]\nHidden=true\n' > ~/.config/autostart/$n.desktop
done
pkill -x gnome-keyring-d 2>/dev/null || true

log_info "Let ksecretd provide org.freedesktop.secrets"
mkdir -p ~/.local/share/dbus-1/services
cat > ~/.local/share/dbus-1/services/org.freedesktop.secrets.service <<'EOF'
[D-BUS Service]
Name=org.freedesktop.secrets
Exec=/usr/bin/ksecretd
EOF
# Remove an old mask of kwallet's Secret Service compat unit, if present
rm -f "$HOME/.config/systemd/user/dbus-\x2a-org.kde.secretservicecompat@\x2a.service"
systemctl --user daemon-reload

log_info "Write KWallet Configuration"
cat > ~/.config/kwalletrc <<'EOF'
[Wallet]
Close When Idle=false
Default Wallet=kdewallet
Enabled=true
First Use=false
Leave Open=true
Local Wallet=kdewallet
Prompt on Open=false
Use One Wallet=true

[org.freedesktop.secrets]
apiEnabled=true
EOF

if [[ -f ~/.local/share/kwalletd/kdewallet.kwl ]]; then
  log_ok "Wallet 'kdewallet' already exists"
else
  log_warn "No wallet yet: on the first KWallet prompt choose 'Classic, blowfish' and leave the password empty"
fi

log_ok "KWallet Install: done"
