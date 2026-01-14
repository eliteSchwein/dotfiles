#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Source logger
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "Link: starting"
cd "$ROOT_DIR"

# ---- 1) Stow dotfiles into $HOME + backup conflicts + auto-remove ONLY THE TARGET that causes stow failure ----

HOME_BACKUP_DIR="$ROOT_DIR/.stow-backups-home/$(date +%F-%H%M%S)"
IGNORE_RE='^(root(/|$)|scripts(/|$)|install_utils\.sh$|install\.sh$|link\.sh$)'

ROOT_REAL="$(realpath -m "$ROOT_DIR")"

is_inside_repo() {
  # returns 0 if path is inside the repo (protect it)
  local p
  p="$(realpath -m "$1")"
  [[ "$p" == "$ROOT_REAL" || "$p" == "$ROOT_REAL/"* ]]
}

backup_home_target_if_exists_and_not_symlink() {
  local tgt="$1"   # absolute target path in $HOME
  local rel="$2"   # relative path under $HOME for backup layout
  local dest="$HOME_BACKUP_DIR/$rel"

  # nothing to do
  if [[ ! -e "$tgt" && ! -L "$tgt" ]]; then
    return 0
  fi

  # Only backup if NOT a symlink
  if [[ -L "$tgt" ]]; then
    return 0
  fi

  log_debug "Backup (home): $tgt -> $dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$tgt" "$dest"
}

remove_home_target_if_not_symlink() {
  local tgt="$1"  # absolute path

  # NEVER delete inside the repo (prevents the $HOME/dotfiles disaster)
  if is_inside_repo "$tgt"; then
    log_warn "Refusing to remove (inside repo): $tgt"
    return 1
  fi

  # Only remove if it's NOT a symlink
  if [[ -L "$tgt" ]]; then
    log_debug "Not removing symlink target: $tgt"
    return 0
  fi

  if [[ -e "$tgt" || -L "$tgt" ]]; then
    log_info "Remove conflict target: $tgt"
    rm -rf "$tgt"
  fi
}

# Build list of stow packages (top-level dirs), excluding root/scripts
packages=()
while IFS= read -r -d '' d; do
  pkg="$(basename "$d")"
  [[ "$pkg" == "root" || "$pkg" == "scripts" ]] && continue
  packages+=("$pkg")
done < <(find . -mindepth 1 -maxdepth 1 -type d -print0)

extract_conflict_targets_from_stow_output() {
  # Prints one conflict path per line (as stow reports it; usually relative to target dir)
  # We handle a few common stow error formats.
  local out="$1"

  # Common formats include:
  #   "existing target is neither a link nor a directory: foo/bar"
  #   "existing target is neither a directory nor a link: foo/bar"
  #   "cannot stow ... over existing target foo/bar"
  #   "CONFLICT: ... existing target is ...: foo/bar"
  #
  # We extract:
  #  - everything after the last ": " in the "existing target ..." lines
  #  - the last token after "existing target " in the "cannot stow ... over existing target ..." line
  #
  # Then de-dup.
  {
    grep -E 'existing target is neither|over existing target' <<<"$out" || true
  } | while IFS= read -r line; do
    if [[ "$line" == *"existing target is neither"*":"* ]]; then
      # take text after last ": "
      printf '%s\n' "${line##*: }"
    elif [[ "$line" == *"over existing target "* ]]; then
      # take text after "over existing target "
      printf '%s\n' "${line##*over existing target }"
    fi
  done | sed 's/[[:space:]]*$//' | awk 'NF' | awk '!seen[$0]++'
}

stow_home_with_autofix() {
  local max_rounds=50
  local round=0

  if ((${#packages[@]} == 0)); then
    log_info "No stow packages found for \$HOME (skipping home stow)"
    return 0
  fi

  while true; do
    round=$((round + 1))
    if (( round > max_rounds )); then
      log_error "Too many stow conflict-fix rounds ($max_rounds). Aborting."
      return 1
    fi

    log_info "Stow dotfiles into \$HOME (round $round)"
    set +e
    stow_out="$(stow -v -R "${packages[@]}" --ignore="$IGNORE_RE" 2>&1)"
    rc=$?
    set -e

    # Always show stow output in logs (but don't spam INFO unless you want)
    if [[ -n "$stow_out" ]]; then
      # If you want it quieter, change to log_debug
      echo "$stow_out"
    fi

    if [[ $rc -eq 0 ]]; then
      return 0
    fi

    # Extract conflicts from stow error output
    mapfile -t conflicts < <(extract_conflict_targets_from_stow_output "$stow_out")

    if ((${#conflicts[@]} == 0)); then
      log_error "stow failed, but I couldn't parse a conflicting target from output."
      return "$rc"
    fi

    log_warn "stow reported ${#conflicts[@]} conflict(s); backing up + removing ONLY target(s) and retrying."

    for c in "${conflicts[@]}"; do
      # stow usually reports paths relative to target dir ($HOME), but handle absolute too
      if [[ "$c" == /* ]]; then
        tgt="$c"
        # Backup path relative under $HOME if possible, else sanitize into backups
        if [[ "$tgt" == "$HOME/"* ]]; then
          rel="${tgt#"$HOME/"}"
        else
          rel="_abs${tgt}"
          rel="${rel#/}" # avoid leading /
          rel="${rel//\//_}" # flatten if outside home
        fi
      else
        tgt="$HOME/$c"
        rel="$c"
      fi

      # Backup (only if not symlink)
      backup_home_target_if_exists_and_not_symlink "$tgt" "$rel"
      # Remove ONLY the TARGET (only if not symlink)
      remove_home_target_if_not_symlink "$tgt" || true
    done

    log_ok "Conflicts handled. Retrying stow..."
  done
}

log_info "Stow (home) with conflict auto-fix"
stow_home_with_autofix

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
