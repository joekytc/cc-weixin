#!/usr/bin/env bash
# Stop Weixin bridge for Codex.

set -euo pipefail

PID_FILE="${WEIXIN_CODEX_PID_FILE:-/private/tmp/weixin-codex-bridge.pid}"

if [ ! -f "$PID_FILE" ]; then
  fallback_pids="$(pgrep -f "[b]un .*server-codex.ts" 2>/dev/null || true)"
  if [ -z "$fallback_pids" ]; then
    echo "[weixin] Bridge not running."
    exit 0
  fi
  echo "[weixin] Stopping bridge..."
  kill $fallback_pids 2>/dev/null || true
  echo "[weixin] Bridge stopped."
  exit 0
fi

pid="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "$pid" ]; then
  rm -f "$PID_FILE"
  echo "[weixin] Bridge PID file was empty."
  exit 0
fi

if ! kill -0 "$pid" 2>/dev/null; then
  rm -f "$PID_FILE"
  fallback_pids="$(pgrep -f "[b]un .*server-codex.ts" 2>/dev/null || true)"
  if [ -n "$fallback_pids" ]; then
    echo "[weixin] Stopping bridge..."
    kill $fallback_pids 2>/dev/null || true
    echo "[weixin] Bridge stopped."
    exit 0
  fi
  echo "[weixin] Bridge not running."
  exit 0
fi

echo "[weixin] Stopping bridge (PID $pid)..."
kill "$pid" 2>/dev/null || true

for _ in $(seq 1 20); do
  if ! kill -0 "$pid" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "[weixin] Bridge stopped."
    exit 0
  fi
  sleep 0.2
done

echo "[weixin] Bridge still running; sending SIGKILL."
kill -9 "$pid" 2>/dev/null || true
rm -f "$PID_FILE"
echo "[weixin] Bridge stopped."
