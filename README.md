# ccswitch

Claude Code のモデルバックエンドをセッション内で切り替えるツール。

Switch Claude Code model backends within a session.

---

## 日本語

### 目的

Claude Code はトークン消費が激しく、すぐに上限に達する。
安価なモデル（Qwen・GLM・Kimi・MiniMax）に切り替えることでコストを抑えられる。
セッションを再起動するとコンテキスト引継ぎコストが高いため、
**proxy モードでセッション中に `/model` で切り替え**できるようにした。

### インストール

#### ccswitch（モデル切替）

```bash
git clone https://github.com/smalltomatowater-boop/ccswitch.git
cd ccswitch
sudo ln -sf $(pwd)/ccswitch.sh /usr/local/bin/ccswitch
```

#### /switch スキル（UI モードル切替）

```bash
mkdir -p ~/.claude/skills/switch
cp .claude/skills/switch/SKILL.md ~/.claude/skills/switch/SKILL.md
```

これで `/switch` コマンドでモデルバックエンドを選択できる。

### 構成ファイル

| ファイル | 説明 |
|----------|------|
| `ccswitch.sh` | モデル切替スクリプト |
| `ccproxy.js` | モデル切替プロキシサーバー |
| `.claude/skills/switch/SKILL.md` | `/switch` スキル定義 |

### 事前準備

API キーを環境変数に設定する。

```bash
export DASHSCOPE_API_KEY="sk-..."           # Qwen3.6 直結用
export ALIBABACODINGPLAN_API_KEY="sk-..."   # Qwen3.5 / Kimi / MiniMax 用 (proxy モードで使用・Coding Plan API)
export ZAI_API_KEY="..."                     # GLM 用
export NVIDIA_API_KEY="nvapi-..."            # NVIDIA NIM 用
```

> **proxy モードの `qwen` は DashScope Coding Plan API を使用。通常の DashScope より大幅に安価。**

GLM キーは `~/.claude/zai_api_key.sh` に記述しても読み込まれる。
NVIDIA キーは `~/.claude/nvidia_api_key.sh` に記述しても読み込まれる。

### 使い方

#### 1. proxy モードで起動（推奨）

```bash
ccswitch proxy
```

以降は Claude Code のセッション内で `/model` コマンドで切り替えられる。

| コマンド | モデル |
|----------|--------|
| `/model sonnet` | Claude Sonnet 4.6 |
| `/model opus` | Claude Opus 4.7 |
| `/model haiku` | Claude Haiku 4.5 |
| `/model qwen` | Qwen3.5-Plus (DashScope **Coding Plan** ※安価) |
| `/model qwen-think` | Qwen3.5-Plus 思考モード (DashScope **Coding Plan** ※安価) |
| `/model glm` | GLM-5.1 (Z.ai) |
| `/model kimi` | Kimi-K2.5 (DashScope **Coding Plan**) |
| `/model minimax` | MiniMax-M2.5 (DashScope **Coding Plan**) |

#### 2. 直結モードで起動

```bash
ccswitch claude      # Anthropic Claude Sonnet 直結
ccswitch qwen        # Qwen3.6-Plus 直結
ccswitch qwen35      # Qwen3.5-Plus 直結
ccswitch qwen-think  # Qwen3.6-Plus 思考モード直結
ccswitch glm         # GLM-5.1 直結
ccswitch kimi        # Kimi-K2.5 (ALIBABA Coding Plan) 直結
ccswitch minimax     # MiniMax-M2.5 (ALIBABA Coding Plan) 直結
ccswitch deepseek    # DeepSeek-V4-Pro (NVIDIA NIM・無料) 直結
ccswitch nvidia      # NVIDIA NIM プロキシモード (/model 切替)
```

#### その他

```bash
ccswitch status  # 現在の設定確認
ccswitch stop    # proxy 停止
ccswitch plist   # /model で使えるモデル一覧
```

### ccproxy の動作

`/model` で切り替えると ccproxy がリクエストを自動変換する。

- **Claude 系に切替時**: メッセージ履歴内の `thinking` ブロックを自動削除
  - Qwen の thinking ブロックは Anthropic API で signature エラーになるため
- **qwen-think 指定時**: thinking パラメータを自動付与
- **qwen/glm/kimi/minimax**: 対応バックエンドへルーティング
- **claude 系**: Anthropic API へパススルー

ユーザーは `/model` で切り替えるだけ。変換処理は意識不要。

### 注意事項

- `opus` (4.7) は Max plan 限定。Pro plan では使用できない場合があります
- API キーは環境変数で管理（ハードコード禁止）
- proxy 再起動後は `/model` で再度モデル選択

---

## English

### Purpose

Claude Code consumes tokens quickly and hits limits fast.
Switching to cheaper models (Qwen, GLM, Kimi, MiniMax) reduces costs.
Restarting a session has high context re-transfer costs, so
**proxy mode allows switching with `/model` within a session**.

### Installation

#### ccswitch (model switching)

```bash
git clone https://github.com/smalltomatowater-boop/ccswitch.git
cd ccswitch
sudo ln -sf $(pwd)/ccswitch.sh /usr/local/bin/ccswitch
```

#### /switch skill (UI model switching)

```bash
mkdir -p ~/.claude/skills/switch
cp .claude/skills/switch/SKILL.md ~/.claude/skills/switch/SKILL.md
```

This enables the `/switch` command to select model backends.

### Files

| File | Description |
|------|-------------|
| `ccswitch.sh` | Model switching script |
| `ccproxy.js` | Model switching proxy server |
| `.claude/skills/switch/SKILL.md` | `/switch` skill definition |

### Prerequisites

Set API keys as environment variables.

```bash
export DASHSCOPE_API_KEY="sk-..."           # For Qwen3.6
export ALIBABACODINGPLAN_API_KEY="sk-..."   # For Qwen3.5 / Kimi / MiniMax (used in proxy)
export ZAI_API_KEY="..."                     # For GLM
export NVIDIA_API_KEY="nvapi-..."            # For NVIDIA NIM
```

GLM key can also be stored in `~/.claude/zai_api_key.sh`.
NVIDIA key can also be stored in `~/.claude/nvidia_api_key.sh`.

### Usage

#### 1. Start in proxy mode (recommended)

```bash
ccswitch proxy
```

Then switch models inside Claude Code with `/model`:

| Command | Model |
|---------|-------|
| `/model sonnet` | Claude Sonnet 4.6 |
| `/model opus` | Claude Opus 4.7 |
| `/model haiku` | Claude Haiku 4.5 |
| `/model qwen` | Qwen3.5-Plus (DashScope **Coding Plan** ※cheaper) |
| `/model qwen-think` | Qwen3.5-Plus with thinking (DashScope **Coding Plan** ※cheaper) |
| `/model glm` | GLM-5.1 (Z.ai) |
| `/model kimi` | Kimi-K2.5 (DashScope **Coding Plan**) |
| `/model minimax` | MiniMax-M2.5 (DashScope **Coding Plan**) |

#### 2. Direct mode

```bash
ccswitch claude      # Anthropic Claude Sonnet direct
ccswitch qwen        # Qwen3.6-Plus direct
ccswitch qwen35      # Qwen3.5-Plus direct
ccswitch qwen-think  # Qwen3.6-Plus with thinking mode
ccswitch glm         # GLM-5.1 direct
ccswitch kimi        # Kimi-K2.5 (ALIBABA Coding Plan) direct
ccswitch minimax     # MiniMax-M2.5 (ALIBABA Coding Plan) direct
ccswitch deepseek    # DeepSeek-V4-Pro (NVIDIA NIM・free) direct
ccswitch nvidia      # NVIDIA NIM proxy mode (/model switching)
```

#### Other commands

```bash
ccswitch status  # Show current settings
ccswitch stop    # Stop proxy
ccswitch plist   # List available models for /model
```

### How ccproxy works

ccproxy automatically transforms requests when you switch models with `/model`.

- **Switching to Claude**: Removes `thinking` blocks from message history
  - Qwen's thinking blocks cause signature errors on the Anthropic API
- **qwen-think**: Automatically injects thinking parameters
- **qwen/glm/kimi/minimax**: Routes to the corresponding backend
- **claude**: Passthrough to Anthropic API

Users just type `/model` — no need to think about the transformation logic.

### Notes

- `opus` (4.7) requires Max plan. Pro plan users may not be able to use it
- API keys must be set via environment variables (never hardcode)
- After restarting the proxy, re-select your model with `/model`
