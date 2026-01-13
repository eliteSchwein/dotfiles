#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Link: starting"

cd "$ROOT_DIR"

# ---- 1) Stow dotfiles into $HOME (NO adopt) + backup conflicts ----
HOME_BACKUP_DIR="$ROOT_DIR/.stow-backups-home/$(date +%F-%H%M%S)"
IGNORE_RE='^(root(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

backup_home_target_if_not_symlink() {
  local pkg_path="$1"        # e.g. ./zsh/.zshrc (or ./<something>/...)
  local rel="${pkg_path#./}" # strip leading ./
  local tgt="$HOME/$rel"
  local dest="$HOME_BACKUP_DIR/$rel"

  # nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # leave symlinks alone
  if [[ -L "$tgt" ]]; then
    return 0
  fi

  log_info "Backup (home): $tgt -> $dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$tgt" "$dest"

  log_info "Remove (home): $tgt"
  if [[ -d "$tgt" ]]; then
    rm -rf "$tgt"
  else
    rm -f "$tgt"
  fi
}

# Backup/remove home targets that would conflict with stow links
# (ignore root + installer scripts)
while IFS= read -r -d '' pkg; do
  rel="${pkg#./}"
  if [[ "$rel" =~ $IGNORE_RE ]]; then
    continue
  fi
  backup_home_target_if_not_symlink "$pkg"
done < <(find . -mindepth 1 \( -type f -o -type l \) -print0)

if [[ -d "$HOME_BACKUP_DIR" ]]; then
  log_ok "Home conflicts backed up to: $HOME_BACKUP_DIR"
fi

log_info "Stow dotfiles into \$HOME"
stow -v -R . --ignore="$IGNORE_RE"

# ---- 2) Root stow package: backup conflicts, then stow to / ----
PKG_DIR="$ROOT_DIR/root"
BACKUP_DIR="$ROOT_DIR/.stow-backups/$(date +%F-%H%M%S)"

if [[ -d "$PKG_DIR" ]]; then
  sudo -v

  backup_and_remove_if_target_not_symlink() {
    local rel="$1"      # relative path inside PKG_DIR
    local tgt="/$rel"   # target on filesystem
    local dest="$BACKUP_DIR/$rel"

    if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
      return 0
    fi
    if [[ -L "$tgt" ]]; then
      return 0
    fi

    log_info "Backup: $tgt -> $dest"
    sudo mkdir -p "$(dirname "$dest")"
    sudo cp -a "$tgt" "$dest"

    log_info "Remove: $tgt"
    if [[ -d "$tgt" ]]; then
      sudo rm -rf "$tgt"
    else
      sudo rm -f "$tgt"
    fi
  }

  # FILES/LINKS
  while IFS= read -r -d '' src; do
    rel="${src#$PKG_DIR/}"
    backup_and_remove_if_target_not_symlink "$rel"
  done < <(find "$PKG_DIR" -mindepth 1 \( -type f -o -type l \) -print0)

  # DIRECTORIES (blocking files)
  while IFS= read -r -d '' srcdir; do
    rel="${srcdir#$PKG_DIR/}"
    tgt="/$rel"
    dest="$BACKUP_DIR/$rel"

    if [[ -L "$tgt" || -d "$tgt" ]]; then
      continue
    fi

    if [[ -e "$tgt" ]]; then
      log_info "Backup blocking file for dir: $tgt -> $dest"
      sudo mkdir -p "$(dirname "$dest")"
      sudo cp -a "$tgt" "$dest"

      log_info "Remove blocking file: $tgt"
      sudo rm -f "$tgt"
    fi
  done < <(find "$PKG_DIR" -mindepth 1 -type d -print0)

  log_ok "Root conflicts cleaned (backups in: $BACKUP_DIR)"

  log_info "Stow root package into /"
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
