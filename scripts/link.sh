#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Link: starting"
cd "$ROOT_DIR"

# ---- 1) Stow dotfiles into $HOME + backup conflicts + remove conflicts (HOME ONLY) ----
HOME_BACKUP_DIR="$ROOT_DIR/.stow-backups-home/$(date +%F-%H%M%S)"
IGNORE_RE='^(root(/|$)|scripts(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

backup_and_remove_home_conflict() {
  local rel="$1"          # e.g. zsh/.zshrc
  local tgt="$HOME/$rel"
  local dest="$HOME_BACKUP_DIR/$rel"

  # Never touch your repo itself (e.g. $HOME/dotfiles/*)
  # Compare realpaths to be safe with symlinks.
  local tgt_real root_real
  tgt_real="$(realpath -m "$tgt")"
  root_real="$(realpath -m "$ROOT_DIR")"
  if [[ "$tgt_real" == "$root_real" || "$tgt_real" == "$root_real/"* ]]; then
    log_info "Skip (inside repo): $tgt"
    return 0
  fi

  # nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # If already a symlink, don't delete (stow will manage/replace it)
  if [[ -L "$tgt" ]]; then
    return 0
  fi

  log_info "Backup (home): $tgt -> $dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$tgt" "$dest"

  log_info "Remove conflict (home): $tgt"
  rm -rf "$tgt"
}

# Build list of stow "packages" (top-level dirs) excluding root/scripts
packages=()
while IFS= read -r -d '' d; do
  pkg="$(basename "$d")"
  [[ "$pkg" == "root" || "$pkg" == "scripts" ]] && continue
  packages+=("$pkg")
done < <(find . -mindepth 1 -maxdepth 1 -type d -print0)

if ((${#packages[@]} == 0)); then
  log_info "No stow packages found for \$HOME (skipping home stow)"
else
  # For each package, remove only the exact conflicting targets it would link
  for pkg in "${packages[@]}"; do
    while IFS= read -r -d '' src; do
      rel_inside_pkg="${src#./$pkg/}"
      [[ -z "$rel_inside_pkg" ]] && continue
      backup_and_remove_home_conflict "$pkg/$rel_inside_pkg"
    done < <(find "./$pkg" \( -type f -o -type l \) -print0)
  done

  if [[ -d "$HOME_BACKUP_DIR" ]]; then
    log_ok "Home conflicts backed up to: $HOME_BACKUP_DIR"
  fi

  log_info "Stow dotfiles into \$HOME"
  stow -v -R "${packages[@]}" --ignore="$IGNORE_RE"
fi

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
