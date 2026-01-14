#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Link: starting"
cd "$ROOT_DIR"

# ---- 1) Stow dotfiles into $HOME (NO adopt) + backup conflicts (NO REMOVAL) ----
HOME_BACKUP_DIR="$ROOT_DIR/.stow-backups-home/$(date +%F-%H%M%S)"
IGNORE_RE='^(root(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

backup_home_target_if_exists_and_not_symlink() {
  local pkg_path="$1"        # e.g. ./zsh/.zshrc
  local rel="${pkg_path#./}" # strip leading ./
  local tgt="$HOME/$rel"
  local dest="$HOME_BACKUP_DIR/$rel"

  # nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # Only backup if NOT a symlink
  if [[ -L "$tgt" ]]; then
    return 0
  fi

  log_info "Backup (home): $tgt -> $dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$tgt" "$dest"
}

# Backup home targets that would conflict with stow links
# (ignore root + installer scripts)
while IFS= read -r -d '' pkg; do
  rel="${pkg#./}"
  if [[ "$rel" =~ $IGNORE_RE ]]; then
    continue
  fi
  backup_home_target_if_exists_and_not_symlink "$pkg"
done < <(find . -mindepth 1 \( -type f -o -type l \) -print0)

if [[ -d "$HOME_BACKUP_DIR" ]]; then
  log_ok "Home conflicts backed up to: $HOME_BACKUP_DIR"
fi

log_info "Stow dotfiles into \$HOME"
# This may still fail if conflicts exist (since we no longer remove them)
stow -v -R . --ignore="$IGNORE_RE"

# ---- 2) Root stow package: NO backup, NO removal, just stow to / ----
PKG_DIR="$ROOT_DIR/root"
if [[ -d "$PKG_DIR" ]]; then
  sudo -v
  log_info "Stow root package into /"
  # This may fail if conflicts exist
  sudo stow -v -R -t / root
else
  log_info "No root package directory found at: $PKG_DIR (skipping sudo stow)"
fi

# ---- 3) Tauon theme copy (only if source exists) ----
SRC_THEME="$HOME/.local/share/TauonMusicBox/theme/Schw31n.ttheme"
DST_THEME="$HOME/.local/share/TauonMusicBox/theme/Schw31nFIX.ttheme"

if [[ -f "$SRC_THEME" ]]; then
  log_info "Copy Tauon theme: $SRC_THEME -> $DST_THEME"
  cp -f "$SRC_THEME" "$DST_THEME"
else
  log_info "Tauon theme source not found, skipping: $SRC_THEME"
fi

# ---- 4) Refresh font cache ----
log_info "Refreshing font cache (fc-cache)"
fc-cache -f

log_ok "Link: done"
