#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Root Link: starting"

PKG_DIR="$ROOT_DIR/root"                         # your stow package folder
BACKUP_DIR="$ROOT_DIR/.stow-backups/$(date +%F-%H%M%S)"

# Ensure sudo is available up-front (optional but nice UX)
sudo -v

backup_and_remove_if_target_not_symlink() {
  local src="$1"      # full path inside PKG_DIR
  local rel="$2"      # relative path inside PKG_DIR
  local tgt="/$rel"   # target on filesystem
  local dest="$BACKUP_DIR$tgt"

  # If target doesn't exist at all, nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # If target is a symlink, leave it alone
  if [[ -L "$tgt" ]]; then
    return 0
  fi

  # Backup existing non-symlink target
  log_info "Backup: $tgt -> $dest"
  sudo mkdir -p "$(dirname "$dest")"
  sudo cp -a "$tgt" "$dest"

  # Remove existing non-symlink target
  log_info "Remove: $tgt"
  if [[ -d "$tgt" ]]; then
    sudo rm -rf "$tgt"
  else
    sudo rm -f "$tgt"
  fi
}

# 1) Handle package FILES/LINKS: if target exists and is not symlink => backup+remove
while IFS= read -r -d '' src; do
  rel="${src#$PKG_DIR/}"
  backup_and_remove_if_target_not_symlink "$src" "$rel"
done < <(find "$PKG_DIR" -mindepth 1 \( -type f -o -type l \) -print0)

# 2) Handle package DIRECTORIES: if target exists and is a blocking FILE (not dir, not symlink) => backup+remove
while IFS= read -r -d '' srcdir; do
  rel="${srcdir#$PKG_DIR/}"
  tgt="/$rel"
  dest="$BACKUP_DIR$tgt"

  # If target is a symlink or a directory, fine
  if [[ -L "$tgt" || -d "$tgt" ]]; then
    continue
  fi

  # If a file exists where we need a directory, backup+remove
  if [[ -e "$tgt" ]]; then
    log_info "Backup blocking file for dir: $tgt -> $dest"
    sudo mkdir -p "$(dirname "$dest")"
    sudo cp -a "$tgt" "$dest"

    log_info "Remove blocking file: $tgt"
    sudo rm -f "$tgt"
  fi
done < <(find "$PKG_DIR" -mindepth 1 -type d -print0)

log_ok "Conflicts cleaned (non-symlink targets backed up to: $BACKUP_DIR)"

# Now stow to /
sudo stow -v -R -t / root

log_ok "Root Link: done"
