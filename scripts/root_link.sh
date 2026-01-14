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

# ---- Dotfiles path guard (do NOT delete targets already symlinked into this repo) ----
DOTFILES_REAL="$(realpath -m "$ROOT_DIR")"
DOTFILES_HOME_REAL="$(realpath -m "$HOME/dotfiles")"

resolve_symlink_target() {
  local link="$1"
  local raw
  raw="$(readlink "$link")" || return 1

  # If relative symlink, resolve relative to link's directory
  if [[ "$raw" != /* ]]; then
    raw="$(cd "$(dirname "$link")" && realpath -m "$raw")"
  else
    raw="$(realpath -m "$raw")"
  fi

  printf '%s\n' "$raw"
}

is_symlink_into_dotfiles() {
  local link="$1"
  [[ -L "$link" ]] || return 1

  local resolved
  resolved="$(resolve_symlink_target "$link" 2>/dev/null || true)"
  [[ -n "$resolved" ]] || return 1

  [[ "$resolved" == "$DOTFILES_REAL"* || "$resolved" == "$DOTFILES_HOME_REAL"* ]]
}

# Ensure sudo is available up-front (optional but nice UX)
sudo -v

backup_and_remove_if_target_not_managed_link() {
  local src="$1"      # full path inside PKG_DIR (unused but kept for signature)
  local rel="$2"      # relative path inside PKG_DIR
  local tgt="/$rel"   # target on filesystem
  local dest="$BACKUP_DIR$tgt"

  # If target doesn't exist at all, nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # If target is a symlink into dotfiles, DO NOT delete it
  if [[ -L "$tgt" ]] && is_symlink_into_dotfiles "$tgt"; then
    return 0
  fi

  # Backup existing target (file/dir/or symlink not into dotfiles)
  log_info "Backup: $tgt -> $dest"
  sudo mkdir -p "$(dirname "$dest")"
  sudo cp -a "$tgt" "$dest"

  # Remove existing target
  log_info "Remove: $tgt"
  if [[ -d "$tgt" && ! -L "$tgt" ]]; then
    sudo rm -rf "$tgt"
  else
    sudo rm -f "$tgt"
  fi
}

# 1) Handle package FILES/LINKS: if target exists and is not a dotfiles-managed symlink => backup+remove
while IFS= read -r -d '' src; do
  rel="${src#$PKG_DIR/}"
  backup_and_remove_if_target_not_managed_link "$src" "$rel"
done < <(find "$PKG_DIR" -mindepth 1 \( -type f -o -type l \) -print0)

# 2) Handle package DIRECTORIES: if target exists and is a blocking FILE/symlink (not a dir),
#    then backup+remove — BUT do not remove if it's a dotfiles-managed symlink.
while IFS= read -r -d '' srcdir; do
  rel="${srcdir#$PKG_DIR/}"
  tgt="/$rel"
  dest="$BACKUP_DIR$tgt"

  # If target is a real directory, fine
  if [[ -d "$tgt" && ! -L "$tgt" ]]; then
    continue
  fi

  # If target is a symlink into dotfiles, keep it
  if [[ -L "$tgt" ]] && is_symlink_into_dotfiles "$tgt"; then
    continue
  fi

  # If something exists where we need a directory (file or symlink not into dotfiles), backup+remove
  if [[ -e "$tgt" || -L "$tgt" ]]; then
    log_info "Backup blocking path for dir: $tgt -> $dest"
    sudo mkdir -p "$(dirname "$dest")"
    sudo cp -a "$tgt" "$dest"

    log_info "Remove blocking path: $tgt"
    sudo rm -f "$tgt"
  fi
done < <(find "$PKG_DIR" -mindepth 1 -type d -print0)

log_ok "Conflicts cleaned (non-managed targets backed up to: $BACKUP_DIR)"

# Now stow to /
sudo stow -v -R -t / root

log_ok "Root Link: done"
