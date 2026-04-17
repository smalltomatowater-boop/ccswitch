# ccswitch.sh

## 目的

- Claude Code トークン消費激しく上限到達早い
- 安価なモデルで切り替え必要
- セッション再起動でコンテキスト引継ぎコスト高い
- proxy でセッション内切替可能に

## 切替方法

```bash
/model {モデル名}
```

proxy モード起動中のみ有効。

## 概要

Claude Code のモデルバックエンドを切り替えるスクリプト。

## 事前準備

API キーを環境変数に設定。

```bash
export DASHSCOPE_API_KEY="sk-..."           # Qwen3.6 用
export ALIBABACODINGPLAN_API_KEY="sk-..."   # Qwen3.5 用 (proxy で使用)
export ZAI_API_KEY="..."                     # GLM 用
```

または `~/.claude/zai_api_key.sh` に GLM キーを記述。

## 使い方

```bash
./ccswitch.sh [command]
```

### コマンド一覧

| コマンド | 説明 |
|----------|------|
| `proxy` | プロキシモード。`/model` で動的切り替え |
| `start` | プロキシ手動起動 |
| `stop` | プロキシ停止 |
| `claude` | Anthropic Claude Sonnet 直結 |
| `qwen` | Qwen3.6-Plus (DashScope) 直結 |
| `qwen35` | Qwen3.5-Plus (DashScope) 直結 |
| `qwen-think` | Qwen3.6-Plus 思考モード有効 |
| `glm` | GLM-5.1 (Z.ai) 直結 |
| `status` | 現在の設定表示 |
| `plist` | `/model` で使えるモデル一覧表示 |

### プロキシモード時の /model

| モデル名 | 説明 |
|----------|------|
| `sonnet` | Claude Sonnet 4.6 |
| `opus-4-5` | Claude Opus 4.5 |
| `haiku` | Claude Haiku 4.5 |
| `qwen` | Qwen3.5-Plus |
| `qwen-think` | Qwen3.5-Plus Thinking |
| `glm` | GLM-5.1 |

※ `opus` (4.7) は Max plan 限定。Pro plan では `opus-4-5` を使用。

## 設定ファイル

`~/.claude/settings.json` に書き出す。

## プロキシ設定

- **ccproxy.js**: `~/script/ccproxy.js`
- **ポート**: 18273
- **ログ**: `/tmp/ccproxy.log`

### ccproxy の動作

1. `/model` で指定されたモデル名をエイリアス解決 (sonnet → claude-sonnet-4-6 等)
2. qwen/glm → 対応バックエンドへルーティング
3. claude 系 → Anthropic API へパススルー

### モデル切替時の自動処理

`/model` でモデル切替すると ccproxy が JSON リクエストを自動変換:

- **Claude 系に切替時**: メッセージ履歴内の `thinking` ブロック自動削除
  - Qwen の thinking ブロックは Anthropic API で signature エラーになるため
- **qwen-think 指定時**: `thinking: { type: 'enabled', budget_tokens: 10000 }` 自動付与

これにより Qwen → Claude、Claude → Qwen のセッション中切替がシームレスに動作。

## Gemma 4 (ローカル)

- **サーバー**: `~/script/gemma4-server.sh` (port 8081)
- **プロキシ**: `~/script/gemma-anthropic-proxy.js` (port 18275)
- **モデル**: `gemma-4-31b`

## 起動中チェック

```bash
lsof -ti :18273  # ccproxy
lsof -ti :8081   # Gemma サーバー
lsof -ti :18275  # Gemma プロキシ
```

## 注意事項

- API キーはハードコードしない。環境変数で管理
- proxy 再起動後は `/model` で再度モデル選択
