#!/bin/bash
# ccswitch.sh - Claude Code のモデルを切り替えるスクリプト
#
# ⚠️ 使用前に API キーを設定してください
#   Coding Plan 用:
#     export ALIBABACODINGPLAN_API_KEY="sk-..."
#   GLM (Z.ai) 用:
#     export ZAI_API_KEY="..."
#   NVIDIA NIM 用:
#     export NVIDIA_API_KEY="nvapi-..."
# 使い方:
#   ccswitch proxy      → プロキシモード (/model で自由に切り替え)
#   ccswitch start      → プロキシ起動
#   ccswitch stop       → プロキシ停止
#   ccswitch claude     → Anthropic Claude (Sonnet) 直結
#   ccswitch qwen       → Qwenモデル選択 (3.7/3.6/3.5/think)
#   ccswitch qwen37     → Qwen3.7-Plus (Coding Plan) 直結
#   ccswitch qwen36     → Qwen3.6-Plus (Coding Plan) 直結
#   ccswitch qwen35     → Qwen3.5-Plus (Coding Plan) 直結
#   ccswitch qwen-think → Qwen3.6-Plus (Coding Plan・思考モード) 直結
#   ccswitch glm        → GLM-5.3 (Z.ai) 直結 (/model で 5.3/5.2 切替)
#   ccswitch glm53      → GLM-5.3 (Z.ai) 直結
#   ccswitch glm52      → GLM-5.2 (Z.ai) 直結
#   ccswitch nvidia      → NVIDIA NIM プロキシ (/model で DeepSeek/Nemotron/Llama切替)
#   ccswitch nvidia-stop → NVIDIA NIM プロキシ停止
#   ccswitch nvidia-start→ NVIDIA NIM プロキシ起動
#   ccswitch deepseek    → DeepSeek-V4-Pro (NVIDIA NIM・無料) 直結
#   ccswitch kimi        → Kimi-K2.5 (ALIBABA Coding Plan) 直結
#   ccswitch minimax     → MiniMax-M2.5 (ALIBABA Coding Plan) 直結
#   ccswitch status     → 現在の設定を確認

SETTINGS="$HOME/.claude/settings.json"
PROXY_SCRIPT="$HOME/script/ccproxy.js"
PROXY_PORT=18273
PROXY_LOG="/tmp/ccproxy.log"

GEMMA_SERVER_SCRIPT="$HOME/script/gemma4-server.sh"
GEMMA_PROXY_SCRIPT="$HOME/script/gemma-anthropic-proxy.js"
GEMMA_SERVER_PORT=8081
GEMMA_PROXY_PORT=18275
GEMMA_LOG="/tmp/gemma4.log"

NVIDIA_PROXY_PORT=18276
NVIDIA_PROXY_SCRIPT="$HOME/script/nvidia_proxy.js"
NVIDIA_PROXY_LOG="/tmp/nvidia_proxy.log"

ensure_settings_dir() {
  mkdir -p "$(dirname "$SETTINGS")"
}

# ── Claude (Anthropic) 設定 ──────────────────────────────────────────────────
use_claude() {
  ensure_settings_dir
  stop_proxy
  cat > "$SETTINGS" << 'EOF'
{
  "model": "claude-sonnet-4-6",
  "availableModels": ["sonnet", "opus", "haiku"],
  "env": {
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7"
  }
}
EOF
  echo "✅ Claude (Anthropic Sonnet 4.6) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.7-Plus (Coding Plan) 設定 ────────────────────────────────────────────
use_qwen37() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.7-plus"
  },
  "model": "qwen3.7-plus"
}
EOF
  echo "✅ Qwen3.7-Plus (DashScope Coding Plan) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.6-Plus (Coding Plan) 設定 ────────────────────────────────────────────
use_qwen36() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.6-plus"
  },
  "model": "qwen3.6-plus"
}
EOF
  echo "✅ Qwen3.6-Plus (DashScope Coding Plan) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen モデル選択メニュー ─────────────────────────────────────────────────
use_qwen() {
  echo "Qwenモデルを選んでください:"
  echo ""
  options=(
    "qwen3.7-plus  - Qwen3.7-Plus (Coding Plan)"
    "qwen3.6-plus  - Qwen3.6-Plus (Coding Plan)"
    "qwen3.5-plus  - Qwen3.5-Plus (Coding Plan)"
    "qwen-think    - Qwen3.6-Plus (Coding Plan・思考モード)"
    "キャンセル"
  )
  select opt in "${options[@]}"; do
    case "$REPLY" in
      1) use_qwen37; break ;;
      2) use_qwen36; break ;;
      3) use_qwen35; break ;;
      4) use_qwen_think; break ;;
      5) echo "キャンセルしました"; break ;;
      *) echo "1〜5 で選んでください" ;;
    esac
  done
}

# ── Qwen3.5-Plus (Coding Plan) 設定 ────────────────────────────────────────────
use_qwen35() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.5-plus"
  },
  "model": "qwen3.5-plus"
}
EOF
  echo "✅ Qwen3.5-Plus (DashScope Coding Plan) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Qwen3.6-Plus (思考モード) 設定 ───────────────────────────────────────────
use_qwen_think() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "qwen3.6-plus"
  },
  "model": "qwen3.6-plus",
  "alwaysThinkingEnabled": true
}
EOF
  echo "✅ Qwen3.6-Plus (DashScope Coding Plan・思考モード) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── GLM (Z.ai) 設定 ─────────────────────────────────────────
# use_glm [version]  version: 5.3 (デフォルト) / 5.2
use_glm() {
  local glm_ver="${1:-5.3}"
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
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-${glm_ver}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-${glm_ver}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME": "GLM-${glm_ver}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION": "Z.ai GLM-${glm_ver}（sonnetエイリアス・thinking/effort対応）",
    "ANTHROPIC_DEFAULT_SONNET_MODEL_SUPPORTED_CAPABILITIES": "thinking,effort,interleaved_thinking",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_NAME": "GLM-${glm_ver}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION": "Z.ai GLM-${glm_ver}（opusエイリアス・thinking/effort対応）",
    "ANTHROPIC_DEFAULT_OPUS_MODEL_SUPPORTED_CAPABILITIES": "thinking,effort,interleaved_thinking",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME": "GLM-4.5-Air",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION": "Z.ai GLM-4.5-Air（haikuエイリアス・軽量バックグラウンド用）",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_SUPPORTED_CAPABILITIES": "thinking"
  },
  "availableModels": ["glm-5.3", "glm-5.2"],
  "model": "glm-${glm_ver}"
}
EOF
  echo "✅ GLM-${glm_ver}（Z.ai） に切り替えました"
  echo "   /model で glm-5.3 / glm-5.2 が選べます"
  echo "   設定ファイル: $SETTINGS"
}

# ── NVIDIA NIM プロキシモード ───────────────────────────────────────────────
# /model で DeepSeek / Nemotron / Llama を切り替え可能
use_nvidia() {
  ensure_settings_dir
  stop_proxy
  # Load NVIDIA API key from file if env var is not set
  if [ -z "$NVIDIA_API_KEY" ] && [ -f "$HOME/.claude/nvidia_api_key.sh" ]; then
    source "$HOME/.claude/nvidia_api_key.sh"
  fi
  if [ -z "$NVIDIA_API_KEY" ]; then
    echo "❌ NVIDIA_API_KEY が設定されていません"
    echo "   export NVIDIA_API_KEY=\"nvapi-...\" を実行してください"
    echo "   API Key: https://build.nvidia.com/ から取得"
    return 1
  fi
  stop_nvidia_proxy
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:${NVIDIA_PROXY_PORT}",
    "ANTHROPIC_AUTH_TOKEN": "nvidia-proxy"
  },
  "availableModels": ["deepseek", "opus", "nemotron-3-super", "qwen-coder", "devstral", "haiku", "deepseek-flash", "deepseek-v4-pro"],
  "model": "deepseek"
}
EOF
  echo "✅ NVIDIA NIM プロキシモードに切り替えました"
  echo "   /model で切り替え: deepseek / qwen-coder / devstral / nemotron-3-super"
  echo "   設定ファイル: $SETTINGS"
  start_nvidia_proxy
}

start_nvidia_proxy() {
  if lsof -i :${NVIDIA_PROXY_PORT} >/dev/null 2>&1; then
    echo "ℹ️  nvidia_proxy は既に起動しています (port ${NVIDIA_PROXY_PORT})"
  else
    nohup node "$NVIDIA_PROXY_SCRIPT" > "$NVIDIA_PROXY_LOG" 2>&1 &
    sleep 1
    if lsof -i :${NVIDIA_PROXY_PORT} >/dev/null 2>&1; then
      echo "✅ nvidia_proxy 起動しました (port ${NVIDIA_PROXY_PORT})"
      echo "   ログ: $NVIDIA_PROXY_LOG"
    else
      echo "❌ nvidia_proxy の起動に失敗しました"
      echo "   ログ: $NVIDIA_PROXY_LOG"
      cat "$NVIDIA_PROXY_LOG"
    fi
  fi
}

stop_nvidia_proxy() {
  local pid=$(lsof -ti :${NVIDIA_PROXY_PORT} 2>/dev/null)
  if [ -n "$pid" ]; then
    kill $pid 2>/dev/null
    echo "✅ nvidia_proxy を停止しました (PID: $pid)"
  else
    echo "ℹ️  nvidia_proxy は起動していません"
  fi
}

# ── DeepSeek-V4-Pro (NVIDIA NIM・無料) 設定 ────────────────────────────────────
use_deepseek() {
  ensure_settings_dir
  stop_proxy
  # Load NVIDIA API key from file if env var is not set
  if [ -z "$NVIDIA_API_KEY" ] && [ -f "$HOME/.claude/nvidia_api_key.sh" ]; then
    source "$HOME/.claude/nvidia_api_key.sh"
  fi
  if [ -z "$NVIDIA_API_KEY" ]; then
    echo "❌ NVIDIA_API_KEY が設定されていません"
    echo "   export NVIDIA_API_KEY=\"nvapi-...\" を実行してください"
    echo "   API Key: https://build.nvidia.com/ から取得"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${NVIDIA_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://integrate.api.nvidia.com/v1",
    "ANTHROPIC_MODEL": "deepseek-ai/deepseek-v4-pro"
  },
  "model": "deepseek-ai/deepseek-v4-pro"
}
EOF
  echo "✅ DeepSeek-V4-Pro (NVIDIA NIM・無料) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Kimi-K2.5 (ALIBABA Coding Plan) 設定 ─────────────────────────────────────
use_kimi() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "kimi-k2.5"
  },
  "model": "kimi-k2.5"
}
EOF
  echo "✅ Kimi-K2.5 (ALIBABA Coding Plan) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── MiniMax-M2.5 (ALIBABA Coding Plan) 設定 ──────────────────────────────────
use_minimax() {
  ensure_settings_dir
  stop_proxy
  if [ -z "$ALIBABACODINGPLAN_API_KEY" ]; then
    echo "❌ ALIBABACODINGPLAN_API_KEY が設定されていません"
    echo "   export ALIBABACODINGPLAN_API_KEY=\"sk-...\" を実行してください"
    return 1
  fi
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${ALIBABACODINGPLAN_API_KEY}",
    "ANTHROPIC_BASE_URL": "https://coding-intl.dashscope.aliyuncs.com/apps/anthropic",
    "ANTHROPIC_MODEL": "MiniMax-M2.5"
  },
  "model": "MiniMax-M2.5"
}
EOF
  echo "✅ MiniMax-M2.5 (ALIBABA Coding Plan) に切り替えました"
  echo "   設定ファイル: $SETTINGS"
}

# ── Gemma 4 (MLX ローカル) 設定 ───────────────────────────────────────────
use_gemma() {
  ensure_settings_dir
  stop_proxy
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:${GEMMA_PROXY_PORT}"
  },
  "model": "gemma-4-31b"
}
EOF
  echo "✅ Gemma 4 31B (MLX ローカル) に切り替えました"
  echo "   設定ファイル：$SETTINGS"
  echo "   サーバー：$(lsof -ti :${GEMMA_SERVER_PORT} >/dev/null 2>&1 && echo '起動中 ✅' || echo '停止中 ❌')"
  echo "   プロキシ：$(lsof -ti :${GEMMA_PROXY_PORT} >/dev/null 2>&1 && echo '起動中 ✅' || echo '停止中 ❌')"
}

start_gemma() {
  # Start MLX server
  if lsof -ti :${GEMMA_SERVER_PORT} >/dev/null 2>&1; then
    echo "ℹ️  Gemma MLX サーバーは既に起動しています (port ${GEMMA_SERVER_PORT})"
  else
    echo "🚀 Gemma MLX サーバー起動中..."
    nohup bash "$GEMMA_SERVER_SCRIPT" > "$GEMMA_LOG" 2>&1 &
    sleep 3
    if lsof -ti :${GEMMA_SERVER_PORT} >/dev/null 2>&1; then
      echo "✅ Gemma MLX サーバー起動しました"
    else
      echo "❌ Gemma MLX サーバーの起動に失敗しました"
      echo "   ログ：$GEMMA_LOG"
      tail -20 "$GEMMA_LOG"
    fi
  fi

  # Start Anthropic proxy
  if lsof -ti :${GEMMA_PROXY_PORT} >/dev/null 2>&1; then
    echo "ℹ️  gemma-anthropic-proxy は既に起動しています (port ${GEMMA_PROXY_PORT})"
  else
    echo "🚀 gemma-anthropic-proxy 起動中..."
    GEMMA_SERVER_URL="http://127.0.0.1:${GEMMA_SERVER_PORT}" nohup node "$GEMMA_PROXY_SCRIPT" > "$GEMMA_LOG" 2>&1 &
    sleep 1
    if lsof -ti :${GEMMA_PROXY_PORT} >/dev/null 2>&1; then
      echo "✅ gemma-anthropic-proxy 起動しました"
    else
      echo "❌ gemma-anthropic-proxy の起動に失敗しました"
      echo "   ログ：$GEMMA_LOG"
      tail -20 "$GEMMA_LOG"
    fi
  fi
}

stop_gemma() {
  # Stop proxy first
  local pid=$(lsof -ti :${GEMMA_PROXY_PORT} 2>/dev/null)
  if [ -n "$pid" ]; then
    kill $pid 2>/dev/null
    echo "✅ gemma-anthropic-proxy を停止しました (PID: $pid)"
  else
    echo "ℹ️  gemma-anthropic-proxy は起動していません"
  fi

  # Stop MLX server
  local pid2=$(lsof -ti :${GEMMA_SERVER_PORT} 2>/dev/null)
  if [ -n "$pid2" ]; then
    kill $pid2 2>/dev/null
    echo "✅ Gemma MLX サーバーを停止しました (PID: $pid2)"
  else
    echo "ℹ️  Gemma MLX サーバーは起動していません"
  fi
}

# ── プロキシモード ─────────────────────────────────────────────────────────
use_proxy() {
  ensure_settings_dir
  cat > "$SETTINGS" << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:${PROXY_PORT}",
    "ANTHROPIC_AUTH_TOKEN": "proxy-mode-local"
  },
  "availableModels": ["sonnet", "opus", "haiku", "qwen", "qwen-think", "glm", "glm-5.3", "glm-5.2", "kimi", "minimax"]
}
EOF
  echo "✅ プロキシモードに切り替えました"
  echo "   /model で切り替えられます: claude / qwen / glm / kimi / minimax"
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
  stop_nvidia_proxy
}

# ── 現在の設定を表示 ─────────────────────────────────────────────────────────
show_status() {
  echo "📄 現在の設定 ($SETTINGS):"
  echo "──────────────────────────────"
  cat "$SETTINGS"
  echo ""
  echo "──────────────────────────────"

  if grep -q "qwen3\.7" "$SETTINGS" 2>/dev/null; then
    echo "🟡 現在: Qwen3.7-Plus (Coding Plan) モード"
  elif grep -q "qwen-think" "$SETTINGS" 2>/dev/null; then
    echo "🟠 現在: Qwen (Coding Plan・思考モード)"
  elif grep -q "qwen" "$SETTINGS" 2>/dev/null; then
    echo "🟡 現在: Qwen (Coding Plan) モード"
  elif grep -q "claude" "$SETTINGS" 2>/dev/null; then
    echo "🟣 現在: Claude (Anthropic) モード"
  elif grep -q "glm" "$SETTINGS" 2>/dev/null; then
    echo "🟣 現在: GLM (Z.ai) モード"
  elif grep -q "kimi" "$SETTINGS" 2>/dev/null; then
    echo "🔵 現在: Kimi-K2.5 (DashScope Coding Plan) モード"
  elif grep -q "minimax" "$SETTINGS" 2>/dev/null; then
    echo "🟤 現在: MiniMax-M2.5 (DashScope Coding Plan) モード"
  elif grep -q "nvidia_proxy\|nvidia-proxy\|nvidia_proxy_port\|18276" "$SETTINGS" 2>/dev/null; then
    echo "🟢 現在: NVIDIA NIM プロキシモード"
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
  qwen37|qwen3.7)
    use_qwen37
    ;;
  qwen36|qwen3.6)
    use_qwen36
    ;;
  qwen35|qwen3.5)
    use_qwen35
    ;;
  qwen-think|qwen36-think)
    use_qwen_think
    ;;
  glm|glm53|glm-5.3)
    use_glm 5.3
    ;;
  glm52|glm-5.2)
    use_glm 5.2
    ;;
  nvidia|nemotron)
    use_nvidia
    ;;
  nvidia-stop)
    stop_nvidia_proxy
    ;;
  nvidia-start)
    start_nvidia_proxy
    ;;
  deepseek)
    use_deepseek
    ;;
  kimi|kimi-k2.5)
    use_kimi
    ;;
  minimax|minimax-m2.5)
    use_minimax
    ;;
  status)
    show_status
    ;;
  plist)
    echo "/model で使えるモデル一覧 (proxyモード):"
    echo ""
    echo "  sonnet      Claude Sonnet 4.6 (Anthropic)"
    echo "  opus        Claude Opus 4.7 (Anthropic)"
    echo "  haiku       Claude Haiku 4.5 (Anthropic)"
    echo "  qwen        Qwen3.6-Plus (Coding Plan)"
    echo "  qwen-think  Qwen3.6-Plus (Coding Plan・思考モード)"
    echo "  glm         GLM-5.3 (Z.ai Coding Plan)"
  echo "  glm-5.3     GLM-5.3 (Z.ai Coding Plan)"
  echo "  glm-5.2     GLM-5.2 (Z.ai Coding Plan)"
    echo "  kimi        Kimi-K2.5 (DashScope Coding Plan)"
    echo "  minimax     MiniMax-M2.5 (DashScope Coding Plan)"
    echo ""
    echo "使い方: /model sonnet"
    ;;
  *)
    echo "モデルを選んでください:"
    echo ""
    options=(
      "claude      - Anthropic Claude Sonnet 直結"
      "qwen37      - Qwen3.7-Plus (Coding Plan) 直結"
      "qwen36      - Qwen3.6-Plus (Coding Plan) 直結"
      "qwen35      - Qwen3.5-Plus (Coding Plan) 直結"
      "qwen-think  - Qwen3.6-Plus (Coding Plan・思考モード) 直結"
      "glm         - GLM-5.3 (Z.ai) 直結 (/model で 5.3/5.2 切替)"
      "nvidia      - NVIDIA NIM プロキシ (/model で切替)"
      "deepseek    - DeepSeek-V4-Pro (NVIDIA NIM・無料) 直結"
      "kimi        - Kimi-K2.5 (DashScope Coding Plan) 直結"
      "minimax     - MiniMax-M2.5 (DashScope Coding Plan) 直結"
      "proxy       - プロキシモード (/model で切り替え)"
      "status      - 現在の設定を確認"
      "キャンセル"
    )
    select opt in "${options[@]}"; do
      case "$REPLY" in
        1) use_claude; break ;;
        2) use_qwen37; break ;;
        3) use_qwen36; break ;;
        4) use_qwen35; break ;;
        5) use_qwen_think; break ;;
        6) use_glm; break ;;
        7) use_nvidia; break ;;
        8) use_deepseek; break ;;
        9) use_kimi; break ;;
        10) use_minimax; break ;;
        11) use_proxy; break ;;
        12) show_status; break ;;
        13) echo "キャンセルしました"; break ;;
        *) echo "1〜13 で選んでください" ;;
      esac
    done
    ;;
esac
