# PostgreSQL定期メンテナンス設定ガイド

## 📅 発生日時

2026年2月5日（水）朝

## 🚨 発生した現象

### 症状
- サイトが極端に重くなった（通常の10倍以上のレスポンス時間）
- さくらVPSのリソース情報:
  - CPU(msec): 通常 <50 → **400** に増加（8倍）
  - DISK I/O(Bytes/s): 通常 ~0 → **200.0m** に増加

### ログから確認された問題
```
[bc1adf7f] Completed 200 OK in 161105ms (Views: 110409.6ms | ActiveRecord: 32296.3ms (2 queries) | GC: 10.3ms)
[11fb43b6] Completed 200 OK in 500597ms (Views: 405525.6ms | ActiveRecord: 91939.1ms (44 queries) | GC: 33.4ms)
```

- **通常**: ActiveRecord: 100-200ms
- **異常時**: ActiveRecord: 32秒〜91秒（300倍以上！）
- トップページの表示に2クエリで6.5秒〜7.4秒かかっていた

## 🔍 原因分析

### PostgreSQLの状態確認

#### 1. Sequential Scan（フルテーブルスキャン）の異常発生
```
lesson_records テーブル:
- Sequential Scans: 12,940回
- Sequential Tuple Read: 4,809,258行（480万行以上！）
- Index Scans: 15,654回
```

#### 2. データベース統計
```
tup_returned: 140,758,078  # クエリで返された行数：1億4千万行以上！
```

#### 3. テーブルブロート（dead tuples）
```
keymaps:      n_live_tup: 6,264 / n_dead_tup: 502
keymap_sets:  n_live_tup: 42    / n_dead_tup: 40
users:        n_live_tup: 33    / n_dead_tup: 36
categories:   n_live_tup: 12    / n_dead_tup: 23
```

### 根本原因

1. **PostgreSQLの自動VACUUMが追いついていない**
   - テーブルに「dead tuples（ゴミデータ）」が蓄積
   - 統計情報が古くなり、クエリプランナーが最適なインデックスを選択できない
   - Sequential Scan（遅い）が多用され、Index Scan（速い）が使われなくなった

2. **ディスクI/Oの遅延**
   - 大量のSequential Scanによりディスク読み込みが急増
   - 特に`lesson_records`テーブル（週1000レッスン = 高頻度更新）で顕著

## ✅ 即時対応（実施済み）

以下のコマンドでVACUUM ANALYZEを手動実行し、パフォーマンスが回復しました：

```bash
kamal app exec 'bundle exec rails runner "ActiveRecord::Base.connection.execute(\"VACUUM ANALYZE lesson_records\"); puts \"lesson_records: VACUUM ANALYZE completed\""'
kamal app exec 'bundle exec rails runner "ActiveRecord::Base.connection.execute(\"VACUUM ANALYZE lessons\"); puts \"lessons: VACUUM ANALYZE completed\""'
kamal app exec 'bundle exec rails runner "ActiveRecord::Base.connection.execute(\"VACUUM ANALYZE categories\"); puts \"categories: VACUUM ANALYZE completed\""'
```

### 結果
- `ActiveRecord: 7.8ms (9 queries)` - 正常
- `ActiveRecord: 14.9ms (19 queries)` - 正常
- トップページのレスポンス: 0.5秒 - 良好

## 🔧 恒久対策（未実施、要対応）

### Option 1: cronで定期VACUUM実行（推奨）

#### 手順

1. **VPSにSSHでログイン**
```bash
ssh root@153.120.65.157
# または sakura VPS コンパネから「コンソール」でログイン
```

2. **cronの編集**
```bash
crontab -e
```

3. **以下の行を追加**（毎日深夜3時に実行）
```cron
0 3 * * * docker exec $(docker ps -q -f label=service=flexitype -f label=role=web | head -1) bundle exec rails runner "ActiveRecord::Base.connection.execute('VACUUM ANALYZE'); puts \"VACUUM ANALYZE completed at #{Time.current}\"" >> /var/log/vacuum_analyze.log 2>&1
```

4. **保存して終了**
   - viエディタの場合: `Esc` → `:wq` → `Enter`

5. **cron設定の確認**
```bash
crontab -l
```

6. **ログディレクトリ作成（初回のみ）**
```bash
touch /var/log/vacuum_analyze.log
chmod 644 /var/log/vacuum_analyze.log
```

7. **動作確認（翌日朝に実施）**
```bash
tail -20 /var/log/vacuum_analyze.log
```

### Option 2: PostgreSQLの自動VACUUM設定調整

#### 手順

1. **PostgreSQLの設定ファイルを確認**
```bash
# PostgreSQLのバージョンによって場所が異なる
find / -name postgresql.conf 2>/dev/null
# 通常: /etc/postgresql/*/main/postgresql.conf
```

2. **設定ファイルを編集**
```bash
vi /etc/postgresql/14/main/postgresql.conf  # バージョンに応じて調整
```

3. **以下の設定を変更**
```conf
autovacuum = on  # 既にonのはず
autovacuum_naptime = 1min  # デフォルト: 1min（そのまま）
autovacuum_vacuum_scale_factor = 0.1  # デフォルト: 0.2（より頻繁にVACUUM）
autovacuum_analyze_scale_factor = 0.05  # デフォルト: 0.1（より頻繁にANALYZE）
```

4. **PostgreSQLを再起動**
```bash
systemctl restart postgresql
```

5. **動作確認**
```bash
systemctl status postgresql
```

### Option 3: Railsのrake taskを作成（補助的）

#### 手順

1. **rake taskファイルを作成**

ファイルパス: `lib/tasks/maintenance.rake`

```ruby
namespace :db do
  desc "Run VACUUM ANALYZE on all tables"
  task vacuum_analyze: :environment do
    tables = %w[lesson_records lessons categories users keymaps keymap_sets]

    tables.each do |table|
      puts "Running VACUUM ANALYZE on #{table}..."
      ActiveRecord::Base.connection.execute("VACUUM ANALYZE #{table}")
      puts "  ✓ #{table} completed"
    end

    puts "\n✅ All VACUUM ANALYZE operations completed at #{Time.current}"
  end

  desc "Show table bloat statistics"
  task table_stats: :environment do
    result = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT
        schemaname,
        relname,
        n_live_tup,
        n_dead_tup,
        CASE
          WHEN n_live_tup > 0 THEN ROUND((n_dead_tup::float / n_live_tup * 100)::numeric, 2)
          ELSE 0
        END as dead_ratio
      FROM pg_stat_user_tables
      ORDER BY n_dead_tup DESC
      LIMIT 10
    SQL

    puts "\n📊 Table Bloat Statistics (Top 10)"
    puts "-" * 80
    result.each do |row|
      puts sprintf("%-20s | Live: %6d | Dead: %6d | Dead Ratio: %6.2f%%",
                   row["relname"],
                   row["n_live_tup"],
                   row["n_dead_tup"],
                   row["dead_ratio"])
    end
  end
end
```

2. **手動実行方法**
```bash
# ローカルで実行
bundle exec rake db:vacuum_analyze

# 本番環境で実行（Kamal経由）
kamal app exec 'bundle exec rake db:vacuum_analyze'

# テーブル統計確認
kamal app exec 'bundle exec rake db:table_stats'
```

3. **cronで定期実行（Option 1と併用可能）**
```cron
0 3 * * * cd /path/to/flexitype && kamal app exec 'bundle exec rake db:vacuum_analyze' >> /var/log/vacuum_analyze.log 2>&1
```

## 📈 サーバスペックについて

### 現在の問題との関係

今回の問題は**PostgreSQLのメンテナンス不足**が主原因なので、**スペックアップだけでは根本解決にはならない**。

### スペックアップの効果

| 項目 | 効果 | 優先度 |
|------|------|--------|
| **メモリ増強** | PostgreSQLのキャッシュヒット率向上、ディスクI/O削減 | **高** |
| **SSD化** | ディスクI/O速度が劇的に向上 | **高** |
| CPU増強 | VACUUM処理が速くなる | 中 |

### 推奨スペック

**現在の規模（週1000レッスン、30ユーザー）**
- メモリ: **2GB以上**（最重要）
- CPU: 2コア以上
- ディスク: **SSD**（HDDだと今回のような問題が起きやすい）

**今後の成長に備えて**
- ユーザー数100人超え: メモリ2GB → 4GB
- 週3000レッスン超え: 4GBプラン + SSD + CPU 3-4コア

### コスパの良い対策（優先順位順）

1. **定期VACUUM設定（無料、最優先）** ← まずこれ
2. PostgreSQLの自動VACUUM設定調整（無料）
3. 接続プールサイズ最適化（無料）
4. メモリを2GBに増やす（有料、月額+数百円〜1000円）
5. SSDプランに変更（有料、効果大）

## 🎯 推奨する対応順序

1. **今すぐ**: Option 1（cronで定期VACUUM）を設定 ← これだけでも十分効果あり
2. **余裕があれば**: Option 3（rake task）を作成してモニタリング
3. **ユーザー数増加時**: サーバスペックアップを検討

## 📝 対応チェックリスト

- [ ] VPSにSSHログイン
- [ ] crontabに定期VACUUM設定を追加
- [ ] ログファイル作成（`/var/log/vacuum_analyze.log`）
- [ ] 翌日にログを確認して動作確認
- [ ] （オプション）rake taskファイル作成（`lib/tasks/maintenance.rake`）
- [ ] （オプション）PostgreSQL自動VACUUM設定調整
- [ ] 定期的にテーブル統計を確認（`rake db:table_stats`）

## 🔗 関連リンク

- PostgreSQL公式ドキュメント: https://www.postgresql.org/docs/current/routine-vacuuming.html
- さくらVPSコンソール: https://secure.sakura.ad.jp/vps/
- Kamalドキュメント: https://kamal-deploy.org/

## 📊 監視すべき指標

今後、同様の問題を早期発見するために以下を定期的に確認：

```bash
# テーブル統計確認
kamal app exec 'bundle exec rake db:table_stats'

# Sequential Scan回数確認
kamal app exec 'bundle exec rails runner "result = ActiveRecord::Base.connection.execute(\"SELECT relname, seq_scan, seq_tup_read FROM pg_stat_user_tables ORDER BY seq_tup_read DESC LIMIT 5\"); puts result.to_a.inspect"'
```

**警告の目安**:
- dead_ratio（Dead Ratio）が20%超え → VACUUM必要
- Sequential Scan回数が急増 → ANALYZE必要
- ActiveRecordの応答時間が500ms超え → 要調査
