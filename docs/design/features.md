# 機能仕様

Typnixで実装済みの機能の詳細仕様書です。

---

## 1. ユーザー認証

### 認証方式
- Google Identity Services を使用
- メール許可リスト制によるアクセス制御（ベータ版）
- セッション管理でログイン状態を保持

### User モデル

```ruby
# カラム
- google_uid (string, unique, not null)
- email (string, unique, not null)
- name (string, not null)
- icon_url (string)
- username (string, unique)
- last_sign_in_at, current_sign_in_at (datetime)
- sign_in_count (integer)
- username_changed_at (datetime) # 24時間変更制限用

# 主要メソッド
- from_google(payload): Google認証からユーザーを作成/取得
- admin?: 管理者判定
```

---

## 2. キーマップ管理

### KeymapSet モデル

複数のキーマップセットを管理します。

```ruby
# カラム
- user_id (references users)
- name (string, max: 50)
- slug (string, unique per user)
- description (text)
- is_public (boolean)
- keyboard_type (string) # split_4x6, ortho_4x12 など

# 主要メソッド
- generate_next_slug(user): slug連番生成（keymap-1, keymap-2...）
- deletable?: 削除可能判定（最古のキーマップは削除不可）
```

### Keymap モデル

各キーのマッピング情報を保持します。

```ruby
# カラム
- user_id, keymap_set_id (references)
- layer (integer, 0-5)
- key_position (string, 例: "L0-R0")
- character (string, max: 20)

# クラスメソッド
- for_user_layer(user_id, layer): 特定レイヤーのキーマップ取得
- bulk_upsert(user_id, layer, keymap_hash): 一括更新
```

### 機能
- 6レイヤー対応（Layer 0-5）
- 2段表示（通常時|Shift時）
- デフォルトキーマップ自動コピー
- キーボードタイプ対応（分割4×6、一体4×12）

---

## 3. タイピング練習

### レッスンシステム

- Category モデルでカテゴリー管理（基礎、英語、日本語、プログラミング）
- Lesson モデルでレッスン管理（items: JSONB配列）
- タブ化UI（Turbo Frames）

### 練習フロー

1. レッスン選択
2. キーボード表示（指ガイド、色分け）
3. リアルタイム正誤判定
4. BackSpaceで修正可能
5. 完了後に統計表示（正答率、WPM、グレード）

### 指ガイド機能

- 指ごとの色分け（小指:赤、薬指:黄、中指:青、人差し指:緑、親指:グレー）
- 次に打つキーのハイライト
- レイヤー自動判定・切り替え

---

## 4. 練習履歴

### LessonRecord モデル

```ruby
# カラム
- user_id (references users)
- lesson_id (bigint, nullable) # レッスン削除に対応
- word_count, correct_count, mistake_count (integer)
- accuracy (decimal, 5, 2)
- duration_seconds (integer)
- typed_chars (integer)
- wpm, grade (string) # 自動計算
- completed_at (datetime)

# 主要メソッド
- calculate_wpm: CPM → WPM変換
- calculate_grade: 5段階カワウソグレード判定
- grade_emoji: グレード絵文字取得
```

### 機能

- 無制限保存
- 期間フィルター（全期間・直近1ヶ月・直近1週間）
- Turbo Framesによるタブ切り替え
- ページネーション（Kaminari gem）

---

## 5. 成績評価・シェア機能

### 5段階カワウソグレード

正答率 × WPM で判定：

| グレード | 条件 |
|---------|------|
| 伝説のカワウソ | 正答率98%以上 & WPM 80以上 |
| 達人カワウソ | 正答率95%以上 & WPM 60以上 |
| 熟練カワウソ | 正答率90%以上 & WPM 40以上 |
| 修行中カワウソ | 正答率80%以上 & WPM 20以上 |
| 見習いカワウソ | 上記以外 |

### Share モデル

```ruby
# カラム
- lesson_record_id (references lesson_records)
- token (string, unique, indexed)

# delegate
- wpm, accuracy, grade (→ lesson_record)
- lesson_name, category_name (→ lesson → category)

# 機能
- has_secure_token :token # トークン自動生成
- OGP対応ランディングページ（/shares/:token）
- X（Twitter）シェア機能
```

---

## 6. 管理者機能

### アクセス制御

- 環境変数 `ADMIN_EMAILS` で管理
- `Admin::ApplicationController` で権限チェック

### ダッシュボード

- 統計サマリー（ユーザー数、練習回数、キーマップ数、レッスン数）
- アクティブユーザー統計（7日間、30日間）
- 最新ユーザー一覧（10名）
- 最新練習履歴（10件）
- 人気レッスンランキング（TOP 10）

### 許可メール管理

- AllowedEmail モデルでDB管理
- フィーチャーフラグ（`RESTRICT_LOGIN`環境変数）
- CRUD操作（`/admin/allowed_emails`）
- 通知フラグ機能（Turbo Streams）

---

## 7. レスポンシブ対応

### ブレークポイント

- モバイル: 768px未満
- PC: 768px以上

### レイアウト

**PC:**
- 左固定サイドバー（300px）
- 右メインコンテンツ（可変幅）

**モバイル:**
- ハンバーガーメニュー方式
- 100dvh対応（モバイルブラウザのアドレスバー考慮）

---

## 8. ダークモード

- Tailwind CSS v4 のクラスベース
- Light / Dark / System の3つのテーマ
- LocalStorageで永続化
- Stimulus コントローラー（theme_controller.js）

---

## 9. ユーザー名機能

### 機能

- `/@username` 形式のプロフィールページ
- Gmail互換バリデーション
- 24時間変更制限
- 予約語チェック（100+ の予約語、`config/initializers/reserved_usernames.rb`）

---

## 10. キーボードタイプ対応

### シンプル実装方式

- 設定ファイルベース（`KEYBOARD_TYPES`ハッシュ）
- デフォルトキーマップ: YAML（`config/default_keymaps/`）
- ビューパーシャル: 動的レンダリング
- JavaScript: 指マッピング定義

### 実装済みタイプ

- `split_4x6`: 4×6分割型（Cornix等）
- `ortho_4x12`: 4×12一体型（Planck等）

---

## 11. SEO/SNS対応

- OGP設定（og:title, og:description, og:image, og:url）
- Twitter Card対応
- ページごとのカスタマイズ可能

---

## 12. セキュリティ

- CSRF保護（Rails標準）
- Strong Parameters
- 環境変数管理（`credentials.yml.enc`, `.kamal/secrets`）
- IDトークン検証（`google-id-token` gem）
- Brakeman 0警告達成
- Content Security Policy（CSP）設定
- ユーザー名変更制限（24時間冷却期間、予約語チェック）

---

## 関連ドキュメント

- [キーボードタイプ設計](keyboard_types.md)
- [セキュリティ設計](security.md)
