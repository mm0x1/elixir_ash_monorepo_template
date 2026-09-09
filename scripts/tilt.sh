#!/usr/bin/env bash

set -u -o pipefail

tilt_pid=""
up_status=0
cleanup_status=0
cleanup_started=false

forward_signal() {
  local signal="$1"

  if [[ -n "$tilt_pid" ]]; then
    kill "-$signal" "$tilt_pid" 2>/dev/null || true
  fi
}

handle_signal() {
  forward_signal "$1"
}

cleanup() {
  if [[ "$cleanup_started" == true ]]; then
    return
  fi

  cleanup_started=true
  trap - EXIT INT TERM HUP

  if [[ -n "$tilt_pid" ]]; then
    forward_signal INT
    wait "$tilt_pid" 2>/dev/null || true
    tilt_pid=""
  fi

  if tilt down; then
    cleanup_status=0
  else
    cleanup_status=$?
  fi

  if ((up_status != 0)); then
    exit "$up_status"
  fi

  exit "$cleanup_status"
}

trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM
trap 'handle_signal HUP' HUP
trap cleanup EXIT

tilt up --stream &
tilt_pid=$!

if wait "$tilt_pid"; then
  up_status=0
else
  up_status=$?
fi

tilt_pid=""
exit "$up_status"
