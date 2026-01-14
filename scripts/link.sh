#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Link: starting"
cd "$ROOT_DIR"

HOME_BACKUP_DIR="$ROOT_DIR/.stow-backups-home/$(date +%F-%H%M%S)"
IGNORE_RE='^(root(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

backup_target_if_needed() {
  local tgt="$1"  # absolute target path
  local rel="$2"  # relative path under $HOME for backup layout

  # backup only if it's not a symlink and exists
  if [[ ( -e "$tgt" || -L "$tgt" ) && ! -L "$tgt" ]]; then
    local dest="$HOME_BACKUP_DIR/$rel"
    log_info "Backup (home): $tgt -> $dest"
    mkdir -p "$(dirname "$dest")"
    cp -a "$tgt" "$dest"
  fi
}

remove_target_if_not_symlink() {
  local tgt="$1"

  # ONLY touch targets inside $HOME
  case "$tgt" in
    "$HOME"/*) ;;
    *)
      log_warn "Refusing to remove non-HOME target: $tgt"
      return 1
      ;;
  esac

  # only remove if it's not a symlink
  if [[ -L "$tgt" ]]; then
    log_info "Skip remove (is symlink): $tgt"
    return 0
  fi

  if [[ -e "$tgt" || -L "$tgt" ]]; then
    log_info "Remove conflict target: $tgt"
    rm -rf "$tgt"
  fi
}

extract_conflict_target() {
  # Reads stow stderr/stdout text and prints a single conflicting target (relative to $HOME)
  # Supports the exact format you pasted.
  local out="$1"
  # Example:
  # cannot stow dotfiles/.config/.../settings.json over existing target .config/.../settings.json since ...
  sed -nE 's/^.*over existing target ([^ ]+) since.*$/\1/p' <<<"$out" | head -n1
}

log_info "Stow dotfiles into \$HOME (auto-fix conflicts)"
max_rounds=25
round=0

while true; do
  round=$((round + 1))
  if (( round > max_rounds )); then
    log_error "Too many stow retries ($max_rounds). Aborting."
    exit 1
  fi

  set +e
  stow_out="$(stow -v -R . --ignore="$IGNORE_RE" 2>&1)"
  rc=$?
  set -e

  # Print stow output (so you still see LINK/UNLINK etc)
  if [[ -n "$stow_out" ]]; then
    echo "$stow_out"
  fi

  if [[ $rc -eq 0 ]]; then
    break
  fi

  conflict_rel="$(extract_conflict_target "$stow_out" || true)"
  if [[ -z "${conflict_rel:-}" ]]; then
    log_error "stow failed, and I couldn't parse the conflicting target."
    exit "$rc"
  fi

  conflict_tgt="$HOME/$conflict_rel"
  log_warn "stow conflict: $conflict_tgt"

  # backup + remove ONLY the target
  backup_target_if_needed "$conflict_tgt" "$conflict_rel"
  remove_target_if_not_symlink "$conflict_tgt"

  log_info "Retrying stow..."
done

if [[ -d "$HOME_BACKUP_DIR" ]]; then
  log_ok "Home backups kept in: $HOME_BACKUP_DIR"
fi

# ---- 2) Root stow package: NO backup, NO removal, just stow to / ----
PKG_DIR="$ROOT_DIR/root"
if [[ -d "$PKG_DIR" ]]; then
  sudo -v
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
