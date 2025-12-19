# キーマップ機能の拡張設計

**実装ステータス**: ✅ **Phase 1完了**（Day 18）、Phase 2-3は将来実装

**最終更新**: 2025-12-20

このドキュメントには、キーマップ機能の拡張設計（複数管理、公開・共有機能）を記載しています。

---

## 現状の課題

- ✅ ~~ユーザーごとに1つのキーマップのみ~~（Phase 1で解決）
- ⏳ 複数のキーマップを管理できない（用途別に使い分けられない）
- ⏳ キーマップの公開・共有機能がない
- ⏳ 他ユーザーのキーマップをフォーク（コピー）できない

---

## 将来の目標

- ✅ **KeymapSet基盤実装**（Day 18完了）
- ⏳ **複数キーマップ管理**（無課金2つ、課金5つまで）
- ⏳ **キーマップに名前と説明を設定可能**（Phase 1で実装済み、Phase 2で複数管理）
- ⏳ **キーマップの公開・共有機能**
- ⏳ **他ユーザーのキーマップをフォーク（コピー）**

---

## データベース設計

### 現状の階層構造（Day 18以前）

```
User (1ユーザー)
  └─ Keymap (約240レコード) ← 実質1つのキーマップセット
       ├─ Layer 0 の各キー配置
       ├─ Layer 1 の各キー配置
       └─ ... Layer 5まで
```

### 拡張後の階層構造（Day 18以降）

```
User (1ユーザー)
  ├─ KeymapSet (例: "プログラミング用")
  │    └─ Keymap (約240レコード) ← 6レイヤー分
  ├─ KeymapSet (例: "ゲーム用")
  │    └─ Keymap (約240レコード)
  └─ KeymapSet (例: "日常用")
       └─ Keymap (約240レコード)
```

### KeymapSet モデル（✅ Day 18で実装）

```ruby
class KeymapSet < ApplicationRecord
  belongs_to :user
  has_many :keymaps, dependent: :destroy  # 既存のKeymapモデルを再利用

  # カラム
  - user_id: references users, not null
  - name: string (max: 50, not null) ← キーマップ名
  - slug: string (max: 50, not null) ← URL用スラッグ
  - description: text (max: 500, nullable) ← キーマップの説明
  - is_public: boolean (default: false, not null) ← 公開設定
  - forked_from_id: integer (nullable) ← フォーク元のKeymap Set ID
  - keyboard_type: string (default: "split_ortho_4x6", not null) ← キーボードタイプ
  - created_at, updated_at

  # バリデーション
  - validates :name, presence: true, length: { maximum: 50 }
  - validates :slug, presence: true, uniqueness: { scope: :user_id }
  - validates :description, length: { maximum: 500 }, allow_blank: true
  - validate :check_user_keymap_limit ← Phase 2で実装予定

  # スコープ
  - scope :published, -> { where(is_public: true) }
end
```

### Keymap モデル（✅ Day 18で拡張）

```ruby
class Keymap < ApplicationRecord
  belongs_to :user
  belongs_to :keymap_set  # 必須（データ整合性重視）

  # 既存のカラム
  - user_id: references users, not null
  - layer: integer (0-5, not null)
  - key_position: string (例: "L0-R0", not null)
  - character: string (max: 20, not null)
  - created_at, updated_at

  # 追加カラム（Day 18）
  - keymap_set_id: references keymap_sets, not null ← NEW!

  # 既存のインデックス
  - [user_id, layer, key_position], unique: true

  # 追加インデックス（Day 18）
  - [keymap_set_id, layer, key_position], unique: true ← NEW!

  # 既存のバリデーション・メソッドはそのまま
end
```

---

## URL設計

### 個人のキーマップ管理（認証必須、`/my`配下）

```ruby
GET    /my/keymaps                    # キーマップ一覧 ← Phase 2で実装予定
GET    /my/keymaps/new                # 新規作成フォーム ← Phase 2で実装予定
POST   /my/keymaps                    # 新規作成（fork_from_idパラメータでフォーク対応）
GET    /my/keymaps/:slug              # 詳細表示（読み取り専用） ← Phase 2で実装予定
GET    /my/keymaps/:slug/edit         # 編集フォーム（名前・説明 + 6レイヤーのキー配置） ← ✅ 実装済み
PATCH  /my/keymaps/:slug              # 更新 ← ✅ 実装済み
DELETE /my/keymaps/:slug              # 削除 ← Phase 2で実装予定
```

### 公開キーマップ（認証不要、`/@username`配下）

```ruby
GET    /@:username/keymaps            # ユーザーの公開キーマップ一覧 ← Phase 3で実装予定
GET    /@:username/keymaps/:slug      # 特定の公開キーマップ詳細（読み取り専用） ← Phase 3で実装予定
                                       # 「フォークする」ボタン → POST /my/keymaps?fork_from_id=:id
```

### フォーク機能の設計（Phase 3）

```ruby
# /@username/keymaps/:slug のページに「フォークする」ボタンを設置
# ボタンクリック → POST /my/keymaps (body: { fork_from_id: :id })
# My::KeymapsController#create で fork_from_id があればコピー処理を実行

def create
  if params[:fork_from_id].present?
    fork_keymap_set(params[:fork_from_id])  # 既存のキーマップをコピー
  else
    create_new_keymap_set                    # 通常の新規作成
  end
end
```

**設計のポイント:**
- YAGNI原則に従い、`share_token` は削除（slug で十分）
- 既存の Keymap モデルを再利用（新しい KeymapLayer モデルは作らない）
- フォーク機能は RESTful に `POST /my/keymaps` で実装（パラメータでフォーク元を指定）

---

## 段階的な実装アプローチ

### ✅ Phase 1: 基盤整備（Day 18で完了）

**実装内容:**
- KeymapSet モデルの作成
- Keymap モデルに `keymap_set_id` カラムを追加
- 既存データの移行（各ユーザーに「デフォルト」という名前の KeymapSet を作成）
- モデルのアソシエーションとバリデーションを実装
- slug 機能の実装（URL用）
- `/my/keymaps/:slug/edit` ルートの実装
- 編集画面の実装（名前・説明・6レイヤーのキー配置）
- 開発環境・本番環境で動作確認

**マイグレーション（Day 18完了）:**
```ruby
# 1つのマイグレーションで完結（データ整合性重視）
def up
  # 1. keymap_sets テーブルを作成
  create_table :keymap_sets do |t|
    t.references :user, null: false, foreign_key: true
    t.string :name, null: false, limit: 50
    t.string :slug, null: false, limit: 50
    t.text :description, limit: 500
    t.boolean :is_public, default: false, null: false
    t.integer :forked_from_id
    t.string :keyboard_type, default: "split_ortho_4x6", null: false
    t.timestamps
  end
  add_index :keymap_sets, [:user_id, :name]
  add_index :keymap_sets, [:user_id, :slug], unique: true

  # 2. keymaps テーブルに keymap_set_id を追加（まずは nullable）
  add_reference :keymaps, :keymap_set, foreign_key: true

  # 3. 既存データの移行
  User.find_each do |user|
    next unless user.keymaps.exists?

    keymap_set = user.keymap_sets.create!(
      name: "デフォルト",
      slug: "default",
      description: "初期キーマップ",
      is_public: false
    )
    user.keymaps.update_all(keymap_set_id: keymap_set.id)
  end

  # 4. keymap_set_id を NOT NULL に変更（データ移行完了後）
  change_column_null :keymaps, :keymap_set_id, false

  # 5. インデックスを追加
  add_index :keymaps, [:keymap_set_id, :layer, :key_position], unique: true
end
```

**設計のポイント:**
- 3つのマイグレーションを1つにまとめることで、一時的な不整合状態を回避
- データ移行完了後に `NOT NULL` 制約を追加することで、データ整合性を保証
- `optional: true` を使わず、すべてのKeymapは必ずKeymap Setに属する設計

---

### ⏳ Phase 2: 複数キーマップ対応（将来実装）

**実装内容:**
- `/my/keymaps` 一覧ページの実装
- `/my/keymaps/new` 新規作成フォームの実装
- `/my/keymaps/:slug/edit` 編集フォームの実装（既存のUIを流用）
- `/my/keymaps/:slug` 詳細表示（読み取り専用）の実装
- 削除機能の実装
- 無課金ユーザーは2つまで制限（`check_user_keymap_limit`バリデーション）
- 将来の課金ユーザーは5つまで

**制限の実装:**
```ruby
# app/models/keymap_set.rb
def check_user_keymap_limit
  return if user.blank?

  # 無課金ユーザーは2つまで
  max_keymaps = user.premium? ? 5 : 2

  if user.keymap_sets.count >= max_keymaps && new_record?
    errors.add(:base, "キーマップは#{max_keymaps}個まで作成できます")
  end
end
```

---

### ⏳ Phase 3: 公開・共有機能（将来実装）

キーマップ公開機能は、既存の基盤（KeymapSet、slug、複数管理）をそのまま活用できるため、比較的シンプルに実装可能（2-3時間程度の作業量）。

#### 3-1. 公開設定UI（簡単）

**編集画面（`/my/keymaps/:slug/edit`）に公開/非公開トグルを追加:**
- `is_public` カラムは既に存在（Day 18で実装済み）
- トグルボタンのUI実装（Tailwind CSS）
- 保存時に `is_public` を更新

**一覧ページ（`/my/keymaps`）に公開状態バッジを表示:**
- 公開中: 緑色バッジ
- 非公開: グレー色バッジ

#### 3-2. 公開キーマップ表示ページ（中程度）

**新規コントローラ `Public::KeymapsController` を作成:**

```ruby
# app/controllers/public/keymaps_controller.rb
class Public::KeymapsController < ApplicationController
  def index
    # /@username/keymaps - そのユーザーの公開キーマップ一覧
    @user = User.find_by!(username: params[:username])
    @keymap_sets = @user.keymap_sets.published.order(created_at: :desc)
  end

  def show
    # /@username/keymaps/:slug - 公開キーマップ詳細（読み取り専用）
    @user = User.find_by!(username: params[:username])
    @keymap_set = @user.keymap_sets.published.find_by!(slug: params[:slug])

    # キー配置を6レイヤー分読み込んで表示（edit画面と同じロジック）
    @keymaps = {}
    (0..5).each do |layer|
      default_keymap = Keymap.default_keymap[layer] || {}
      user_keymap = Keymap.where(keymap_set: @keymap_set, layer: layer)
                          .pluck(:key_position, :character)
                          .to_h
      @keymaps[layer] = default_keymap.merge(user_keymap)
    end
  end
end
```

**ルーティング追加:**
```ruby
# config/routes.rb
# User profiles (public) セクションに追加
get "/@:username/keymaps", to: "public/keymaps#index", as: :user_keymaps
get "/@:username/keymaps/:slug", to: "public/keymaps#show", as: :user_keymap
```

**ビュー実装:**
- `app/views/public/keymaps/index.html.slim`: 公開キーマップ一覧（`/my/keymaps/index.html.slim` を参考）
- `app/views/public/keymaps/show.html.slim`: 公開キーマップ詳細（`/my/keymaps/edit.html.slim` を読み取り専用で再利用）

#### 3-3. フォーク機能（中程度）

**`My::KeymapsController#create` にフォーク処理を追加:**

```ruby
# app/controllers/my/keymaps_controller.rb
def create
  # フォーク処理
  if params[:fork_from_id].present?
    fork_keymap_set(params[:fork_from_id])
    return
  end

  # 通常の新規作成
  @keymap_set = current_user.keymap_sets.build(keymap_set_params)
  if @keymap_set.save
    redirect_to edit_my_keymap_path(@keymap_set), notice: "キーマップ「#{@keymap_set.name}」を作成しました。"
  else
    render :new, status: :unprocessable_entity
  end
end

private

def fork_keymap_set(original_id)
  original = KeymapSet.published.find(original_id)

  # KeymapSetをコピー
  @keymap_set = original.dup
  @keymap_set.user = current_user
  @keymap_set.forked_from_id = original.id
  @keymap_set.is_public = false  # フォーク時は非公開
  @keymap_set.slug = KeymapSet.generate_next_slug(current_user)  # 新しいslugを生成
  @keymap_set.save!

  # 関連するKeymapもコピー
  original.keymaps.each do |keymap|
    @keymap_set.keymaps.create!(
      user: current_user,
      layer: keymap.layer,
      key_position: keymap.key_position,
      character: keymap.character
    )
  end

  redirect_to edit_my_keymap_path(@keymap_set), notice: "キーマップ「#{original.name}」をフォークしました。"
end
```

**公開キーマップ詳細ページに「フォークする」ボタンを追加:**
```slim
/ app/views/public/keymaps/show.html.slim
- if logged_in?
  = button_to "このキーマップをフォークする", my_keymaps_path(fork_from_id: @keymap_set.id),
    method: :post,
    class: "px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700"
- else
  p.text-gray-500 ログインするとこのキーマップをフォークできます
```

#### 3-4. フォーク元の表示

**編集画面でフォーク元を表示:**
```slim
/ app/views/my/keymaps/edit.html.slim の基本情報セクションに追加
- if @keymap_set.forked_from_id.present?
  .mb-4.p-3.bg-blue-50.dark:bg-blue-900.rounded-lg
    p.text-sm.text-blue-800.dark:text-blue-200
      | このキーマップは
      = link_to @keymap_set.forked_from.user.username, profile_path(@keymap_set.forked_from.user.username), class: "underline"
      | さんの「
      = @keymap_set.forked_from.name
      | 」からフォークしました
```

**既存の基盤が活きるポイント:**
- ✅ KeymapSet モデル: `is_public`, `forked_from_id`, `slug` カラムが既にある
- ✅ slug ベースのURL: 既に実装済み
- ✅ 複数キーマップ管理: Phase 2で実装予定
- ✅ レイヤー表示UI: edit画面のUIをそのまま読み取り専用で再利用可能

---

## 機能要件

### キーマップ一覧（`/my/keymaps`）
- キーマップの一覧をカード形式で表示
- 各カード: 名前、説明、作成日時、公開状態
- 新規作成ボタン（制限に達している場合は非表示）
- 編集・削除ボタン

### キーマップ詳細・編集（`/my/keymaps/:slug/edit`）
- 名前・説明の編集
- 6レイヤーのキー配置編集（現在の実装と同じUI）
- 公開設定トグル（Phase 3）
- 保存・キャンセルボタン

### 公開キーマップ一覧（`/@username/keymaps`）
- ユーザーの公開キーマップのみ表示
- 各カード: 名前、説明、作成日時
- フォークボタン（要ログイン）

### 公開キーマップ詳細（`/@username/keymaps/:slug`）
- キーマップの詳細表示（読み取り専用）
- 6レイヤーのキー配置を視覚的に表示
- フォークボタン（自分のキーマップとしてコピー）
- フォーク元の表示（フォークされたキーマップの場合）

---

## 設計の利点

### RESTful設計
- KeymapSetとKeymapの分離により、Railsの標準的なリソース設計に従う
- ルーティングがシンプルで拡張しやすい
- コントローラのアクションも標準的なCRUD操作

### 拡張性
- 課金機能追加時に、キーマップ数制限を柔軟に変更可能
- 将来的にキーマップのテンプレート機能なども追加しやすい
- フォーク機能により、コミュニティ的な要素を強化

### ユーザビリティ
- 用途別にキーマップを使い分けられる（プログラミング、ゲーム、日常など）
- 他のユーザーの設定を参考にできる
- `/@username/keymaps`により、プロフィールと統一感のあるURL設計

---

## まとめ

**実装完了（Phase 1、Day 18）:**
- ✅ KeymapSet モデルの基盤実装
- ✅ Keymap モデルへの `keymap_set_id` カラム追加
- ✅ 既存データの移行
- ✅ slug 機能の実装
- ✅ 編集画面の実装（`/my/keymaps/:slug/edit`）

**将来実装（Phase 2）:**
- ⏳ 複数キーマップ管理（一覧、新規作成、削除）
- ⏳ キーマップ数制限（無課金2つ、課金5つ）

**将来実装（Phase 3）:**
- ⏳ 公開・共有機能
- ⏳ フォーク機能
- ⏳ 公開キーマップ一覧・詳細ページ
