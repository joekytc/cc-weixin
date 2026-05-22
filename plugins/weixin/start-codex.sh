#!/usr/bin/env bash
# Start Weixin bridge for Codex.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="${WEIXIN_CODEX_PID_FILE:-/private/tmp/weixin-codex-bridge.pid}"
APP_PID_FILE="${WEIXIN_CODEX_APP_PID_FILE:-/private/tmp/weixin-codex-appserver.pid}"
BUN="${BUN:-/opt/homebrew/bin/bun}"
MODE="${WEIXIN_CODEX_MODE:-desktop}"
WS_URL="${CODEX_WS_URL:-ws://127.0.0.1:4500}"
if [ -n "${CODEX_BIN:-}" ]; then
  CODEX_EXEC="$CODEX_BIN"
elif command -v codex >/dev/null 2>&1; then
  CODEX_EXEC="$(command -v codex)"
elif [ -x "/Applications/Codex.app/Contents/Resources/codex" ]; then
  CODEX_EXEC="/Applications/Codex.app/Contents/Resources/codex"
else
  echo "[weixin] Codex executable not found." >&2
  echo "[weixin] Set CODEX_BIN=/path/to/codex and retry." >&2
  exit 1
fi

if [ -f "$PID_FILE" ]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
    echo "[weixin] Bridge already running (PID $old_pid)."
    echo "[weixin] Stop it with: ~/.codex/plugins/weixin/stop-codex.sh"
    exit 0
  fi
fi

if [ ! -x "$BUN" ]; then
  echo "[weixin] Bun not found at $BUN" >&2
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/node_modules" ]; then
  echo "[weixin] Installing dependencies..."
  "$BUN" install --no-summary --cwd "$SCRIPT_DIR"
else
  echo "[weixin] Dependencies ready."
fi

echo "[weixin] Starting Weixin bridge..."
echo "[weixin] Codex binary: $CODEX_EXEC"
echo "[weixin] Stop with: ~/.codex/plugins/weixin/stop-codex.sh"

if [ "$MODE" = "stdio" ]; then
  echo "[weixin] Mode: stdio (headless)"
  echo "$$" > "$PID_FILE"
  exec env WEIXIN_CODEX_STANDALONE="1" CODEX_WS_URL="stdio://" CODEX_BIN="$CODEX_EXEC" "$BUN" "$SCRIPT_DIR/server-codex.ts"
fi

echo "[weixin] Mode: desktop (WebSocket)"
echo "[weixin] Starting Codex App Server at $WS_URL..."
"$CODEX_EXEC" app-server --listen "$WS_URL" &
APP_SERVER_PID=$!
echo "$APP_SERVER_PID" > "$APP_PID_FILE"

cleanup() {
  if [ -n "${BRIDGE_PID:-}" ]; then
    kill "$BRIDGE_PID" 2>/dev/null || true
  fi
  kill "$APP_SERVER_PID" 2>/dev/null || true
  rm -f "$APP_PID_FILE" "$PID_FILE"
}
trap cleanup EXIT INT TERM

for i in $(seq 1 20); do
  sleep 0.5
  HTTP_URL="${WS_URL/ws:\/\//http://}"
  HTTP_URL="${HTTP_URL/wss:\/\//https://}"
  if curl -sf "${HTTP_URL}/healthz" > /dev/null 2>&1; then
    echo "[weixin] App Server ready."
    break
  fi
  if [ "$i" -eq 20 ]; then
    echo "[weixin] App Server did not start in time." >&2
    exit 1
  fi
done

env WEIXIN_CODEX_STANDALONE="1" CODEX_WS_URL="$WS_URL" CODEX_BIN="$CODEX_EXEC" "$BUN" "$SCRIPT_DIR/server-codex.ts" &
BRIDGE_PID=$!
echo "$BRIDGE_PID" > "$PID_FILE"
wait "$BRIDGE_PID"
