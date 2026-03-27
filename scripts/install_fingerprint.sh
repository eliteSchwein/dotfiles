#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Fingerprint Reader Install: starting"

PACMAN_FLAGS=(--noconfirm --needed)

log_info "Check for Fingerprint Hardware"

pattern='finger|fingerprint|biometric|validity|synaptics|goodix|elan|authentec|upek'

if ! { lsusb 2>/dev/null; lspci 2>/dev/null; } | grep -Eiq "$pattern"; then
    log_warn "No fingerprint reader hardware detected, skipping install"
    exit 0
fi

log_ok "Fingerprint reader hardware detected"

log_ok "Install Packages"
paru -S "${PACMAN_FLAGS[@]}" fprintd imagemagick

log_ok "Adjust Pam Configurations"

ensure_pam_fprintd() {
    local file="$1"
    local line='auth      sufficient    pam_fprintd.so'

    if [[ ! -f "$file" ]]; then
        log_warn "Missing PAM file: $file, skipping"
        return 0
    fi

    if grep -Eq '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_fprintd\.so([[:space:]]|$)' "$file"; then
        log_info "pam_fprintd already present in $file"
        return 0
    fi

    sudo cp "$file" "${file}.bak"

    local tmp
    tmp="$(mktemp)"

    awk -v line="$line" '
        BEGIN { inserted = 0 }

        /^[[:space:]]*auth[[:space:]]+/ && !inserted {
            print line
            inserted = 1
        }

        { print }

        END {
            if (!inserted) {
                print line
            }
        }
    ' "$file" > "$tmp"

    sudo install -m 0644 "$tmp" "$file"
    rm -f "$tmp"

    log_ok "Added pam_fprintd.so to $file"
}

ensure_pam_fprintd /etc/pam.d/system-local-login
ensure_pam_fprintd /etc/pam.d/login

log_ok "Enroll fingerprints (both index fingers, in case one finger gets injured)"

# Remove old enrolled fingerprints if any.
fprintd-delete "$USER" 2>/dev/null || true

for finger in \
    left-index-finger \
    right-index-finger
do
    log_info "Enrolling $finger"
    fprintd-enroll -f "$finger" "$USER"
done

log_ok "Fingerprint Reader Install: done"