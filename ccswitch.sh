#!/bin/bash
# ccswitch.sh - Claude Code のモデルを切り替えるスクリプト
#
# ⚠️ 使用前に API キーを設定してください
#   Qwen (DashScope) 用:
#     export DASHSCOPE_API_KEY="sk-..."
#   GLM (Z.ai) 用:
#     export ZAI_API_KEY="..."
#
# 使い方:
#   ccswitch proxy      → プロキシモード (/model で自由に切り替え)
#   ccswitch start      → プロキシ起動
#   ccswitch stop       → プロキシ停止
#   ccswitch claude     → Anthropic Claude (Sonnet) 直結
#   ccswitch qwen       → Qwen3.6-Plus (DashScope) 直結
#   ccswitch qwen35     → Qwen3.5-Plus (DashScope) 直結
#   ccswitch qwen-think → Qwen3.6-Plus (DashScope・思考モード) 直結
#   ccswitch glm        → GLM-5.1 (Z.ai) 直結
#   ccswitch status     → 現在の設定を確認

SETTINGS="$HOME/.claude/settings.json"
PROXY_SCRIPT="$HOME/script/ccproxy.js"
PROXY_PORT=18273
PROXY_LOG="/tmp/ccproxy.log"

ensure_settings_dir() {
  mkdir -p "$(dirname "$SETTINGS")"
}

# ── Claude (Anthropic) 設定 ──────────────────────────────────────────────────
use_claude() {
  ensure_settings_dir
  stop_proxy
  cat > "$SETTINGS" << 'EOF'
{
  "model": "claude-sonnet-4-6"
}
EOF
  echo "✅ Claude (Anthropic Sonnet) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.6-Plus (DashScope) 設定 ────────────────────────────────────────────
use_qwen() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$DASHSCOPE_API_KEY" ]; then
    echo "❌ DASHSCOPE_API_KEY が設定されていません"
    echo "   export DASHSCOPE_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${DASHSCOPE_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://dashscope-intl.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.6-plus"
  },
  "model": "qwen3.6-plus"
}
EOF
  echo "✅ Qwen3.6-Plus (DashScope) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.5-Plus (DashScope) 設定 ────────────────────────────────────────────
use_qwen35() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$DASHSCOPE_API_KEY" ]; then
    echo "❌ DASHSCOPE_API_KEY が設定されていません"
    echo "   export DASHSCOPE_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${DASHSCOPE_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.5-plus"
  },
  "model": "qwen3.5-plus"
}
EOF
  echo "✅ Qwen3.5-Plus (DashScope) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.6-Plus (思考モード) 設定 ───────────────────────────────────────────
use_qwen_think() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$DASHSCOPE_API_KEY" ]; then
    echo "❌ DASHSCOPE_API_KEY が設定されていません"
    echo "   export DASHSCOPE_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${DASHSCOPE_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://dashscope-intl.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.6-plus"
  },
  "model": "qwen3.6-plus",
  "alwaysThinkingEnabled": true
}
EOF
  echo "✅ Qwen3.6-Plus (DashScope・思考モード) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── GLM-5.1 (Z.ai) 設定 ─────────────────────────────────────────
use_glm() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ZAI_API_KEY" ]; then
    echo "❌ ZAI_API_KEY が設定されていません"
    echo "   export ZAI_API_KEY=\"...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ZAI_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "API_TIMEOUT_MS": "3000000",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.1",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5.1"
  },
  "model": "glm-5.1"
}
EOF
  echo "✅ GLM-5.1（Z.ai） に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── プロキシモード ─────────────────────────────────────────────────────────
use_proxy() {
  ensure_settings_dir
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:${PROXY_PORT}"
  }
}
EOF
  echo "✅ プロキシモードに切り替えました"
  echo "   /model で自由に切り替えられます:"
  echo "     claude-sonnet-4-6 / qwen3.6-plus / glm-5.1"
  start_proxy
}

start_proxy() {
  if lsof -i :${PROXY_PORT} >/dev/null 2>&1; then
    echo "ℹ️  ccproxy は既に起動しています (port ${PROXY_PORT})"
  else
    nohup node "$PROXY_SCRIPT" > "$PROXY_LOG" 2>&1 &
    sleep 1
    if lsof -i :${PROXY_PORT} >/dev/null 2>&1; then
      echo "✅ ccproxy 起動しました (port ${PROXY_PORT})"
      echo "   ログ: $PROXY_LOG"
    else
      echo "❌ ccproxy の起動に失敗しました"
      echo "   ログ: $PROXY_LOG"
      cat "$PROXY_LOG"
    fi
  fi
}

stop_proxy() {
  local pid=$(lsof -ti :${PROXY_PORT} 2>/dev/null)
  if [ -n "$pid" ]; then
    kill $pid 2>/dev/null
    echo "✅ ccproxy を停止しました (PID: $pid)"
  else
    echo "ℹ️  ccproxy は起動していません"
  fi
}

# ── 現在の設定を表示 ─────────────────────────────────────────────────────────
show_status() {
  echo "📄 現在の設定 ($SETTINGS):"
  echo "──────────────────────────────"
  cat "$SETTINGS"
  echo ""
  echo "──────────────────────────────"

  # 使用中のモデルを判定
  if grep -q "localhost:${PROXY_PORT}" "$SETTINGS" 2>/dev/null; then
    echo "🔀 現在: プロキシモード (/model で切り替え)"
    echo "   プロキシ: $(lsof -i :${PROXY_PORT} >/dev/null 2>&1 && echo '起動中 ✅' || echo '停止中 ❌')"
  elif grep -q "alwaysThinkingEnabled" "$SETTINGS" 2>/dev/null; then
    echo "🟠 現在: Qwen (DashScope・思考モード)"
  elif grep -q "qwen" "$SETTINGS" 2>/dev/null; then
    echo "🟡 現在: Qwen (DashScope) モード"
  elif grep -q "claude" "$SETTINGS" 2>/dev/null; then
    echo "🟣 現在: Claude (Anthropic) モード"
  elif grep -q "glm" "$SETTINGS" 2>/dev/null; then
    echo "🟣 現在: GLM (Z.ai) モード"
  else
    echo "⚪ 現在: デフォルト設定（Anthropicアカウントに依存）"
  fi
}

# ── メイン処理 ───────────────────────────────────────────────────────────────
case "$1" in
  proxy)
    use_proxy
    ;;
  start)
    start_proxy
    ;;
  stop)
    stop_proxy
    ;;
  claude)
    use_claude
    ;;
  qwen)
    use_qwen
    ;;
  qwen35|qwen3.5)
    use_qwen35
    ;;
  qwen-think|qwen36-think)
    use_qwen_think
    ;;
  glm|glm51|glm-5.1)
    use_glm
    ;;
  status)
    show_status
    ;;
  *)
    echo "モデルを選んでください:"
    echo ""
    options=(
      "claude      - Anthropic Claude Sonnet 直結"
      "qwen        - Qwen3.6-Plus (DashScope) 直結"
      "qwen35      - Qwen3.5-Plus (DashScope) 直結"
      "qwen-think  - Qwen3.6-Plus (DashScope・思考モード) 直結"
      "glm         - GLM-5.1 (Z.ai) 直結"
      "proxy       - プロキシモード (/model で切り替え)"
      "status      - 現在の設定を確認"
      "キャンセル"
    )
    select opt in "${options[@]}"; do
      case "$REPLY" in
        1) use_claude; break ;;
        2) use_qwen; break ;;
        3) use_qwen35; break ;;
        4) use_qwen_think; break ;;
        5) use_glm; break ;;
        6) use_proxy; break ;;
        7) show_status; break ;;
        8) echo "キャンセルしました"; break ;;
        *) echo "1〜8 で選んでください" ;;
      esac
    done
    ;;
esac
