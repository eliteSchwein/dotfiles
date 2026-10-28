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
  local out="$1"
  # GNU Stow reports conflicts in two different formats. Both use paths
  # relative to the target directory ($HOME).
  sed -nE \
    -e 's/^.*over existing target ([^ ]+) since.*$/\1/p' \
    -e 's/^[[:space:]]*\*[[:space:]]*existing target (is not owned by stow|is stowed to a different package):[[:space:]]*([^[:space:]]+).*$/\2/p' \
    <<<"$out" | head -n1
}

backup_and_move_stow_conflict() {
  local rel="$1"
  local tgt="$HOME/$rel"

  # Reject malformed paths and anything outside HOME.
  if [[ -z "$rel" || "$rel" == /* || "$rel" == "." ||
        "$rel" == ".." || "$rel" == ../* || "$rel" == */../* ||
        "$rel" == */.. || "$rel" == ./* ]]; then
    log_error "Unsafe stow conflict path: $rel"
    return 1
  fi

  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    log_error "Conflict target disappeared: $tgt"
    return 1
  fi

  # Backup and move both regular targets and symlinks. The original version
  # skipped symlinks, so a different-package conflict could never be fixed.
  local dest="$HOME_BACKUP_DIR/$rel"
  if [[ -e "$dest" || -L "$dest" ]]; then
    log_error "Backup already exists, refusing to overwrite: $dest"
    return 1
  fi
  log_info "Move conflicting target to backup: $tgt -> $dest"
  mkdir -p "$(dirname "$dest")"
  mv -- "$tgt" "$dest"
}

prepare_explicit_home_target() {
  local rel="$1"
  local tgt="$HOME/$rel"

  if [[ -e "$tgt" || -L "$tgt" ]]; then
    log_info "Preparing explicit target: $tgt"
    backup_target_if_needed "$tgt" "$rel"
    remove_target_if_not_symlink "$tgt"
  fi
}

copy_explicit_home_file() {
  local rel="$1"
  local src="$ROOT_DIR/$rel"
  local tgt="$HOME/$rel"

  if [[ ! -f "$src" ]]; then
    log_warn "Explicit source file not found, skipping: $src"
    return 0
  fi

  prepare_explicit_home_target "$rel"

  log_info "Copy explicit file: $src -> $tgt"
  cp -f "$src" "$tgt"
}

# ---- 0) Explicit uwsm env files: backup/remove/copy ----
mkdir -p "$HOME/.config/uwsm"
copy_explicit_home_file ".config/uwsm/env"
copy_explicit_home_file ".config/uwsm/env-hyprland"

# Explicit Hypr scripts directory: ensure it is linked as a directory
HYPR_SCRIPTS_SRC="$ROOT_DIR/.config/hypr/scripts"
HYPR_SCRIPTS_TGT="$HOME/.config/hypr/scripts"

if [[ -d "$HYPR_SCRIPTS_SRC" ]]; then
  mkdir -p "$HOME/.config/hypr"

  if [[ -e "$HYPR_SCRIPTS_TGT" || -L "$HYPR_SCRIPTS_TGT" ]]; then
    backup_target_if_needed "$HYPR_SCRIPTS_TGT" ".config/hypr/scripts"
    remove_target_if_not_symlink "$HYPR_SCRIPTS_TGT"

    # Recreate even an existing symlink so it always points at this repo.
    if [[ -L "$HYPR_SCRIPTS_TGT" ]]; then
      rm -f "$HYPR_SCRIPTS_TGT"
    fi
  fi

  log_info "Link Hypr scripts: $HYPR_SCRIPTS_TGT -> $HYPR_SCRIPTS_SRC"
  ln -s "$HYPR_SCRIPTS_SRC" "$HYPR_SCRIPTS_TGT"
else
  log_warn "Hypr scripts source not found, skipping: $HYPR_SCRIPTS_SRC"
fi

# ---- 1) Stow dotfiles into $HOME with auto-fix conflicts ----
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
  stow_out="$(stow --no-folding -v -R . 2>&1)"
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

  # Preserve the original target, including symlinks, before retrying.
  backup_and_move_stow_conflict "$conflict_rel"

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
  sudo stow --no-folding -v -R -t / root
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