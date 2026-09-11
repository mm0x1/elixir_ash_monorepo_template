#!/usr/bin/env bash

set -Eeuo pipefail

tilt_bin="${TILT_BIN:-tilt}"
tilt_pid=""
cleanup_started=false
received_signal=""

forward_signal() {
  local signal="$1"

  if [[ -n "$tilt_pid" ]] && kill -0 "$tilt_pid" 2>/dev/null; then
    kill "-$signal" "$tilt_pid" 2>/dev/null || true
  fi
}

handle_signal() {
  received_signal="$1"
  forward_signal "$received_signal"

  case "$received_signal" in
    INT) exit 130 ;;
    TERM) exit 143 ;;
    HUP) exit 129 ;;
  esac
}

cleanup() {
  local exit_status=$?
  local down_status=0

  if [[ "$cleanup_started" == true ]]; then
    return
  fi

  cleanup_started=true
  trap - EXIT INT TERM HUP

  if [[ -n "$tilt_pid" ]]; then
    forward_signal "${received_signal:-INT}"
    wait "$tilt_pid" 2>/dev/null || true
    tilt_pid=""
  fi

  if "$tilt_bin" down; then
    down_status=0
  else
    down_status=$?
  fi

  if ((exit_status != 0)); then
    exit "$exit_status"
  fi

  exit "$down_status"
}

trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM
trap 'handle_signal HUP' HUP
trap cleanup EXIT

"$tilt_bin" up --stream &
tilt_pid=$!

up_status=0
if wait "$tilt_pid"; then
  up_status=0
else
  up_status=$?
fi

tilt_pid=""
exit "$up_status"
