#!/usr/bin/env bash
# 建立並驗證 dev container 是否可正確使用。
# 在「跑 docker 的主機」（本機 Mac 或 VPS）上執行：bash verify-container.sh
set -uo pipefail
cd "$(dirname "$0")"

fail() { echo "[失敗] $*" >&2; exit 1; }

echo "==> 1/6 檢查 config/authorized_keys 是否至少有一把公鑰"
if ! grep -qvE '^\s*#|^\s*$' config/authorized_keys 2>/dev/null; then
  echo "   目前沒有任何公鑰，重建後會無法登入。"
  echo "   請先執行： cat ~/.ssh/id_ed25519.pub >> config/authorized_keys"
  fail "authorized_keys 為空"
fi
echo "   OK（$(grep -cvE '^\s*#|^\s*$' config/authorized_keys) 把公鑰）"

echo "==> 2/6 讀取 .env 的 SSH_PORT / SSH_USER"
[ -f .env ] || fail "找不到 .env（可從 .env.example 複製並填寫）"
PORT=$(grep -E '^SSH_PORT=' .env | cut -d= -f2- | tr -d ' "'); PORT=${PORT:-2222}
USER_=$(grep -E '^SSH_USER=' .env | cut -d= -f2- | tr -d ' "'); USER_=${USER_:-developer}
echo "   SSH_USER=$USER_  SSH_PORT=$PORT"

echo "==> 3/6 驗證 compose 設定語法"
docker compose config >/dev/null || fail "docker compose config 失敗"
echo "   OK"

echo "==> 4/6 build 並啟動容器"
docker compose build || fail "build 失敗"
docker compose up -d || fail "up 失敗"

echo "==> 5/6 等待 healthcheck 變 healthy（最多約 90 秒）"
CID=$(docker compose ps -q python-dev)
[ -n "$CID" ] || fail "找不到容器"
STATUS=unknown
for i in $(seq 1 30); do
  STATUS=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}nohealth{{end}}' "$CID" 2>/dev/null || echo unknown)
  echo "   [$i] health=$STATUS"
  [ "$STATUS" = "healthy" ] && break
  sleep 3
done
[ "$STATUS" = "healthy" ] || echo "   [注意] 尚未 healthy，仍嘗試 SSH 測試（可能只是還在起）"

echo "==> 6/6 用金鑰實測 SSH 登入並檢查工具"
# 清掉舊的 host key，避免重建後 host key 變動導致比對失敗
ssh-keygen -R "[localhost]:$PORT" >/dev/null 2>&1 || true
ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes -p "$PORT" "$USER_@localhost" '
  echo "  登入成功： $(whoami)@$(hostname)"
  echo "  tmux : $(tmux -V 2>/dev/null || echo 未安裝)"
  echo "  mosh : $(mosh --version 2>/dev/null | head -1 || echo 未安裝)"
  echo "  工具 : $(command -v claude codex agy 2>/dev/null | tr "\n" " ")"
' && echo "驗證完成，可正常使用" || fail "SSH 金鑰登入失敗（檢查 authorized_keys 是否含此機公鑰、防火牆/port）"
