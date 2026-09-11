#!/usr/bin/env bash

set -Eeuo pipefail

# This script doubles as a tiny Tilt test double when invoked with `up` or
# `down`. That keeps the wrapper's exit and signal paths testable without
# starting a long-lived Tilt or Docker process.
case "${1:-}" in
  up)
    case "${TILT_TEST_MODE:-success}" in
      success)
        exit 0
        ;;
      failure)
        exit "${TILT_TEST_UP_STATUS:-42}"
        ;;
      signal)
        trap 'exit 130' INT
        trap 'exit 143' TERM
        while true; do
          sleep 0.05
        done
        ;;
      *)
        printf 'unknown test mode: %s\n' "${TILT_TEST_MODE}" >&2
        exit 2
        ;;
    esac
    ;;
  down)
    exit "${TILT_TEST_DOWN_STATUS:-0}"
    ;;
esac

root_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
wrapper="$root_dir/scripts/tilt.sh"

bash -n "$wrapper" "$0"

expect_status() {
  local mode="$1"
  local expected="$2"
  local down_status="$3"
  local actual

  set +e
  TILT_BIN="$0" \
    TILT_TEST_MODE="$mode" \
    TILT_TEST_DOWN_STATUS="$down_status" \
    "$wrapper" >/dev/null 2>&1
  actual=$?
  set -e

  if [[ "$actual" != "$expected" ]]; then
    printf 'expected %s mode to exit %s, got %s\n' "$mode" "$expected" "$actual" >&2
    exit 1
  fi
}

expect_signal_status() {
  local signal="$1"
  local expected="$2"
  local wrapper_pid
  local actual

  setsid env TILT_BIN="$0" TILT_TEST_MODE=signal \
    bash -c 'trap - INT; exec "$1"' _ "$wrapper" >/dev/null 2>&1 &
  wrapper_pid=$!
  sleep 0.2
  kill "-$signal" "$wrapper_pid"

  for _ in {1..50}; do
    if ! kill -0 "$wrapper_pid" 2>/dev/null; then
      break
    fi
    sleep 0.1
  done

  if kill -0 "$wrapper_pid" 2>/dev/null; then
    kill -KILL "$wrapper_pid" 2>/dev/null || true
    wait "$wrapper_pid" 2>/dev/null || true
    printf 'Tilt wrapper did not exit after SIG%s\n' "$signal" >&2
    exit 1
  fi

  set +e
  wait "$wrapper_pid"
  actual=$?
  set -e

  if [[ "$actual" != "$expected" ]]; then
    printf 'expected SIG%s to produce exit %s, got %s\n' "$signal" "$expected" "$actual" >&2
    exit 1
  fi
}

# Normal shutdown returns the bounded cleanup result; an update failure always
# wins over cleanup failure so the original Tilt error reaches the caller.
expect_status success 0 0
expect_status success 9 9
expect_status failure 42 9
expect_signal_status TERM 143

printf 'Tilt wrapper syntax, exit, cleanup, and signal paths passed.\n'
