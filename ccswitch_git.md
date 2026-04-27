# ccswitch コミットルール

## リポジトリ
https://github.com/smalltomatowater-boop/ccswitch

## ブランチ
- `main` をデフォルトブランチとして使用する

## コミットメッセージ
- 英語で書く
- 種類: feat / fix / docs / refactor / chore / test
- 日本語のコミットメッセージでも可（日本語がわかりやすい場合）

## コミット対象ファイル
- コアファイル: `ccswitch.sh`, `ccproxy.js`
- ドキュメント: `README.md`, `.claude/skills/switch/SKILL.md`
- バックアップファイル (`.bak`, `.bak2` etc.) はコミットしない
- `.DS_Store` はコミットしない

## APIキー
- ハードコード禁止。環境変数経由で管理
- 既存のコミットにAPIキーが含まれていないか確認すること

## プッシュ
- SSH プロトコルを使用
- リモート: `git@github.com:smalltomatowater-boop/ccswitch.git`
