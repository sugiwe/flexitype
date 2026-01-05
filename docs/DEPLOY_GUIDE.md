# デプロイガイド

**作成日:** 2025-01-04
**目的:** 安全で確実なデプロイ手順を標準化する

---

## デプロイ方法

### 推奨方法: デプロイスクリプト使用（自動テスト付き）

```bash
./bin/deploy
```

このスクリプトは以下を自動実行します:

1. **RSpec**: 全テストを実行
2. **RuboCop**: コード品質チェック
3. **Brakeman**: セキュリティ脆弱性チェック
4. **Kamal deploy**: 本番環境へのデプロイ

**メリット:**
- デプロイ前に自動で品質チェック
- テスト失敗時は自動的にデプロイ中止
- 人的ミスを防止
- ブランチ確認（mainブランチ以外は警告）

---

## 緊急時のデプロイ（テストスキップ）

テストに時間がかかる場合や緊急の修正が必要な場合のみ:

```bash
kamal deploy
```

**注意:** テストをスキップするため、本番環境に不具合が混入するリスクがあります。

---

## デプロイ後の確認

### 1. サイトにアクセスして動作確認

```bash
open https://typnix.com
```

**確認項目:**
- ✅ トップページが表示される
- ✅ ログインが正常に動作する
- ✅ タイピング練習が正常に動作する
- ✅ 管理者ダッシュボードにアクセスできる（管理者のみ）

### 2. ログを確認

```bash
# アプリケーションログをリアルタイムで確認
kamal app logs --follow

# 最新100行のログを表示
kamal app logs --lines 100

# エラーログのみ表示
kamal app logs | grep ERROR
```

### 3. ヘルスチェック確認

```bash
curl https://typnix.com/up
# 期待される出力: OK
```

---

## マイグレーション実行

データベース変更がある場合:

```bash
# マイグレーション実行
kamal app exec bin/rails db:migrate

# マイグレーション状況確認
kamal app exec bin/rails db:migrate:status
```

---

## ロールバック手順（問題が発生した場合）

### 方法1: 前のバージョンにロールバック

```bash
# 直前のバージョンにロールバック
kamal rollback
```

### 方法2: 特定のコミットにロールバック

```bash
# ロールバックしたいコミットをチェックアウト
git checkout <commit-hash>

# デプロイ
kamal deploy

# 終わったらmainに戻る
git checkout main
```

---

## トラブルシューティング

### デプロイが失敗する場合

**原因1: テストが通らない**
```bash
# ローカルでテストを実行
bundle exec rspec

# 失敗したテストを修正してから再デプロイ
```

**原因2: VPSへの接続失敗**
```bash
# SSH接続を確認
ssh ubuntu@153.120.65.157

# Kamalの接続を確認
kamal app exec echo "Connection OK"
```

**原因3: ディスク容量不足**
```bash
# ディスク使用状況を確認
kamal app exec df -h

# 古いDockerイメージを削除
kamal app exec docker system prune -af
```

### アプリが起動しない場合

```bash
# コンテナの状態を確認
kamal app exec docker ps -a

# コンテナログを確認
kamal app logs --lines 500

# コンテナを再起動
kamal app restart
```

### データベース接続エラーが出る場合

```bash
# データベースの状態を確認
ssh ubuntu@153.120.65.157
sudo systemctl status postgresql

# PostgreSQLが起動していない場合は起動
sudo systemctl start postgresql
```

---

## デプロイのベストプラクティス

### 1. デプロイ前のチェックリスト

- [ ] ローカルで全テストが通る（`bundle exec rspec`）
- [ ] RuboCopでコード品質チェック（`bundle exec rubocop`）
- [ ] Brakemanでセキュリティチェック（`bundle exec brakeman`）
- [ ] mainブランチにマージ済み
- [ ] マイグレーションファイルがある場合は確認済み

### 2. デプロイタイミング

**推奨時間帯:**
- 平日の営業時間外（深夜または早朝）
- ユーザーアクセスが少ない時間帯

**避けるべき時間帯:**
- 週末のピーク時間
- イベント開催中

### 3. デプロイ後の監視

**最初の30分:**
- ログを監視（`kamal app logs --follow`）
- エラーが発生していないか確認
- ヘルスチェック確認（`curl https://typnix.com/up`）

**最初の24時間:**
- ユーザーからのフィードバックを確認
- Sentryでエラーを監視（導入後）
- パフォーマンス確認

---

## CI/CD（将来実装予定）

GitHub Actionsを導入すると、以下が自動化されます:

1. **PR作成時:**
   - 自動テスト実行
   - RuboCop実行
   - Brakeman実行

2. **mainブランチへのマージ時:**
   - 自動デプロイ（オプション）

詳細は `TODO.md` の「GitHub Actions CI/CD設定」を参照。

---

## まとめ

**デプロイの基本フロー:**
1. ローカルでテスト・品質チェック
2. `./bin/deploy` でデプロイ
3. サイトで動作確認
4. ログ監視

**問題が発生した場合:**
1. `kamal app logs` でログ確認
2. 必要に応じてロールバック（`kamal rollback`）
3. 問題を修正して再デプロイ

**最終更新:** 2025-01-04
