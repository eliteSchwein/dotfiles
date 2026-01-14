#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# blue ASCII art (ANSI)
printf '\033[35m%s\033[0m\n' \
'  ░██████     ░██████  ░██     ░██ ░██       ░██  ░██████    ░██   ░███    ░██ ' \
' ░██   ░██   ░██   ░██ ░██     ░██ ░██       ░██ ░██   ░██ ░████   ░████   ░██ ' \
'░██         ░██        ░██     ░██ ░██  ░██  ░██       ░██   ░██   ░██░██  ░██ ' \
' ░████████  ░██        ░██████████ ░██ ░████ ░██   ░█████    ░██   ░██ ░██ ░██ ' \
'        ░██ ░██        ░██     ░██ ░██░██ ░██░██       ░██   ░██   ░██  ░██░██ ' \
' ░██   ░██   ░██   ░██ ░██     ░██ ░████   ░████ ░██   ░██   ░██   ░██   ░████ ' \
'  ░██████     ░██████  ░██     ░██ ░███     ░███  ░██████  ░██████ ░██    ░███ '
printf '\033[32m%s\033[0m\n' \
'Dotfiles 0.0.1 (Arch only!)'



ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# ---- Options (override via env) ----
: "${CLEAR_AFTER_STEP:=1}" # 1 clears console after each *successful* step
: "${KEEP_LOGS:=1}"        # 1 keeps logs even on success
: "${LOG_LEVEL:=INFO}"     # DEBUG, INFO, WARN, ERROR
: "${LOG_COLOR:=auto}"     # auto, always, never
: "${LOG_TIME:=1}"         # 1 show timestamps
: "${SUDO_KEEPALIVE:=1}"   # 1 do sudo -v + keepalive, 0 disable

# ---- Logs ----
LOGDIR="$(mktemp -d -t installer.XXXXXX)"
MASTER_LOG="$LOGDIR/full.log"
mkdir -p "$LOGDIR"
: > "$MASTER_LOG"              # <-- always create (truncate if exists)
chmod 600 "$MASTER_LOG" || true

export LOG_FILE="$MASTER_LOG"
export LOG_LEVEL LOG_COLOR LOG_TIME

# Source your colored logger
source "$SCRIPTS_DIR/logger.sh"

INSTALL_OK=0
SUDO_KEEPALIVE_PID=""

cleanup() {
  if [[ -n "${SUDO_KEEPALIVE_PID}" ]]; then
    kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true
  fi

  if [[ "$INSTALL_OK" == "1" && "$KEEP_LOGS" != "1" ]]; then
    rm -rf "$LOGDIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

clear_console() {
  if command -v tput >/dev/null 2>&1; then
    tput clear || true
  else
    clear || true
  fi
}

# ---- Steps ----
STEP_NAMES=()
STEP_SCRIPTS=()
STATUSES=() # PENDING, OK, FAIL, SKIP

add_step() {
  STEP_NAMES+=("$1")
  STEP_SCRIPTS+=("$2")
}

add_step "root link" "$SCRIPTS_DIR/root_link.sh"
add_step "paru install" "$SCRIPTS_DIR/install_paru.sh"
add_step "old packages uninstall" "$SCRIPTS_DIR/remove_old_packages.sh"
add_step "greetd install" "$SCRIPTS_DIR/install_greetd.sh"
add_step "package install" "$SCRIPTS_DIR/install_packages.sh"
add_step "hyprland config" "$SCRIPTS_DIR/make_hyprland_config.sh"
add_step "dms install" "$SCRIPTS_DIR/install_dms.sh"
add_step "gtk theme install" "$SCRIPTS_DIR/install_gtk_theme.sh"
add_step "zsh install" "$SCRIPTS_DIR/install_zsh.sh"
add_step "power profiles install" "$SCRIPTS_DIR/install_powerprofiles.sh"
add_step "link" "$SCRIPTS_DIR/link.sh"

for i in "${!STEP_NAMES[@]}"; do
  STATUSES[$i]="PENDING"
done

render_statuses() {
  for i in "${!STEP_NAMES[@]}"; do
    case "${STATUSES[$i]}" in
      OK)   echo "✅ [Step $i] ${STEP_NAMES[$i]}" ;;
      FAIL) echo "❌ [Step $i] ${STEP_NAMES[$i]}" ;;
      SKIP) echo "⏭️ [Step $i] ${STEP_NAMES[$i]}" ;;
      *)    echo "⌛️ [Step $i] ${STEP_NAMES[$i]}" ;;
    esac
  done
  echo
}

# ---- Sudo keepalive (runner only) ----
start_sudo_keepalive() {
  log_info "Requesting sudo once (so step scripts can use sudo normally)..."
  sudo -v

  (
    while true; do
      sudo -n true 2>/dev/null || exit 0
      sleep 60
    done
  ) &
  SUDO_KEEPALIVE_PID="$!"
  log_ok "Sudo keepalive started."
}

if [[ "$SUDO_KEEPALIVE" == "1" ]]; then
  start_sudo_keepalive
fi

run_step() {
  local idx="$1"
  local name="${STEP_NAMES[$idx]}"
  local script="${STEP_SCRIPTS[$idx]}"
  local step_log="$LOGDIR/step_$((idx+1)).log"

  if [[ ! -f "$script" ]]; then
    echo "ERROR: Missing script: $script" | tee -a "$step_log" >>"$MASTER_LOG"
    return 127
  fi

  {
    echo "=================================================="
    echo "STEP $((idx+1)): $name"
    echo "SCRIPT: $script"
    echo "TIME: $(date -Is)"
    echo "=================================================="
  } >>"$MASTER_LOG"

  # LIVE OUTPUT: terminal + step log + master log (line-buffered)
  set +e
  stdbuf -oL -eL bash "$script" 2>&1 \
    | stdbuf -oL -eL tee "$step_log" \
    | stdbuf -oL -eL tee -a "$MASTER_LOG"
  local rc="${PIPESTATUS[0]}"
  set -e

  echo >>"$MASTER_LOG"
  return "$rc"
}

# ---- Execute ----
clear_console
render_statuses
log_info "Master log: $MASTER_LOG"
echo

for i in "${!STEP_NAMES[@]}"; do
  echo "⏳ START: ${STEP_NAMES[$i]}"
  echo

  if run_step "$i"; then
    STATUSES[$i]="OK"

    if [[ "$CLEAR_AFTER_STEP" == "1" ]]; then
      clear_console
    fi

    render_statuses
  else
    STATUSES[$i]="FAIL"
    for j in $(seq $((i+1)) $((${#STEP_NAMES[@]}-1))); do
      STATUSES[$j]="SKIP"
    done

    echo
    echo "❌ FAIL: ${STEP_NAMES[$i]}"
    echo
    render_statuses
    echo "Logs kept in: $LOGDIR"
    echo "Master log: $MASTER_LOG"
    exit 1
  fi
done

INSTALL_OK=1

echo "✅ All steps completed successfully."
if [[ "${KEEP_LOGS:-0}" -eq 1 ]]; then
  echo "Logs kept in: $LOGDIR"
  echo "Master log: $MASTER_LOG"
fi