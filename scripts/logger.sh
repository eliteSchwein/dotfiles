#!/usr/bin/env bash
# logger.sh - source this file:  source "./logger.sh"
set -u

# -------- Config (override via env before sourcing) --------
: "${LOG_LEVEL:=INFO}"          # DEBUG, INFO, WARN, ERROR
: "${LOG_TIME:=0}"              # 1 = show timestamps
: "${LOG_COLOR:=auto}"          # auto, always, never
: "${LOG_FILE:=}"               # if set, append logs to this file

# -------- Internals --------
_logger__is_tty() { [[ -t 1 ]]; }

_logger__use_color() {
  case "$LOG_COLOR" in
    always) return 0 ;;
    never)  return 1 ;;
    auto)   _logger__is_tty ;;
    *)      _logger__is_tty ;;
  esac
}

_logger__ts() {
  if [[ "${LOG_TIME}" == "1" ]]; then
    date "+%Y-%m-%d %H:%M:%S "
  else
    printf ""
  fi
}

# Map level name -> numeric severity (lower = more verbose)
_logger__sev() {
  case "$1" in
    DEBUG) echo 10 ;;
    INFO)  echo 20 ;;
    WARN)  echo 30 ;;
    ERROR) echo 40 ;;
    *)     echo 20 ;;
  esac
}

_logger__allowed() {
  local msg_level="$1"
  local cfg="${LOG_LEVEL^^}"
  local msev csev
  msev="$(_logger__sev "${msg_level^^}")"
  csev="$(_logger__sev "$cfg")"
  [[ "$msev" -ge "$csev" ]]
}

_logger__write() {
  # $1=LEVEL $2=message (already formatted)
  local line="$2"
  # stdout
  printf "%s\n" "$line"
  # optional file
  if [[ -n "$LOG_FILE" ]]; then
    # Strip ANSI when writing to file to keep it clean
    printf "%s\n" "$line" | sed -r 's/\x1B\[[0-9;]*[mK]//g' >> "$LOG_FILE"
  fi
}

_logger__fmt() {
  local level="$1"; shift
  local msg="$*"
  local ts="$(_logger__ts)"

  local reset="" bold="" dim="" red="" green="" yellow="" blue="" magenta="" cyan=""
  if _logger__use_color; then
    reset=$'\033[0m'
    bold=$'\033[1m'
    dim=$'\033[2m'
    red=$'\033[31m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    blue=$'\033[34m'
    magenta=$'\033[35m'
    cyan=$'\033[36m'
  fi

  case "${level^^}" in
    DEBUG) printf "%s%s[%sDEBUG%s]%s %s" "${dim}${ts}" "${cyan}" "${bold}" "${reset}${dim}" "${reset}" "$msg" ;;
    INFO)  printf "%s%s[%sINFO%s]%s  %s" "${ts}" "${blue}" "${bold}" "${reset}${blue}" "${reset}" "$msg" ;;
    OK)    printf "%s%s[%sOK%s]%s    %s" "${ts}" "${green}" "${bold}" "${reset}${green}" "${reset}" "$msg" ;;
    WARN)  printf "%s%s[%sWARN%s]%s  %s" "${ts}" "${yellow}" "${bold}" "${reset}${yellow}" "${reset}" "$msg" ;;
    ERROR) printf "%s%s[%sERROR%s]%s %s" "${ts}" "${red}" "${bold}" "${reset}${red}" "${reset}" "$msg" ;;
    *)     printf "%s[%s] %s" "${ts}" "${level^^}" "$msg" ;;
  esac
}

# -------- Public API --------
log_debug() { _logger__allowed "DEBUG" || return 0; _logger__write "DEBUG" "$(_logger__fmt DEBUG "$*")"; }
log_info()  { _logger__allowed "INFO"  || return 0; _logger__write "INFO"  "$(_logger__fmt INFO  "$*")"; }
log_ok()    { _logger__allowed "INFO"  || return 0; _logger__write "OK"    "$(_logger__fmt OK    "$*")"; }
log_warn()  { _logger__allowed "WARN"  || return 0; _logger__write "WARN"  "$(_logger__fmt WARN  "$*")" >&2; }
log_error() { _logger__allowed "ERROR" || return 0; _logger__write "ERROR" "$(_logger__fmt ERROR "$*")" >&2; }

die() {
  log_error "$*"
  return 1
}
