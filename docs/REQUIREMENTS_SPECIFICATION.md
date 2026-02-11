# Bookers2 Next Generation - 要件定義書

**バージョン**: 2.0
**作成日**: 2026年2月11日
**プロジェクト名**: Bookers2 Next Generation
**概要**: 読書感想共有プラットフォームの全面リニューアル

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [現状分析](#2-現状分析)
3. [技術要件](#3-技術要件)
4. [UI/UX要件](#4-uiux要件)
5. [機能要件](#5-機能要件)
6. [非機能要件](#6-非機能要件)
7. [データベース設計](#7-データベース設計)
8. [API設計](#8-api設計)
9. [セキュリティ要件](#9-セキュリティ要件)
10. [テスト要件](#10-テスト要件)
11. [移行計画](#11-移行計画)
12. [README強化計画](#12-readme強化計画)

---

## 1. プロジェクト概要

### 1.1 背景

Bookers2は、ユーザーが読了した本の感想を投稿・共有し、他のユーザーとコミュニケーションを取れるソーシャルプラットフォームです。本プロジェクトでは、最新のWeb開発トレンドとユーザー体験の向上を目的とした全面リニューアルを行います。

### 1.2 ビジョン

> **"本を通じて、人と人をつなぐ"**

単なる読書記録アプリではなく、読書を通じた**コミュニティプラットフォーム**へと進化させます。

### 1.3 プロジェクト目標

| 目標 | 詳細 |
|------|------|
| **UI/UX刷新** | ダークモードを基調とした現代的なデザインへの全面移行 |
| **技術刷新** | Rails 7 + Hotwire (Turbo/Stimulus) への移行 |
| **機能拡張** | ソーシャル機能・検索機能・レコメンデーション機能の追加 |
| **パフォーマンス** | ページロード時間50%削減、SPAライクな体験の実現 |

---

## 2. 現状分析

### 2.1 現行システム構成

```
┌─────────────────────────────────────────────────┐
│                 Current Stack                    │
├─────────────────────────────────────────────────┤
│  Framework    │ Rails 6.1.7                     │
│  Ruby         │ 3.1.2                           │
│  Frontend     │ Bootstrap 4 + jQuery + Turbolinks│
│  Database     │ SQLite3                         │
│  Auth         │ Devise                          │
│  Bundler      │ Webpacker                       │
└─────────────────────────────────────────────────┘
```

### 2.2 現行機能一覧

| 機能カテゴリ | 機能 | 状態 |
|-------------|------|------|
| **認証** | ユーザー登録/ログイン/ログアウト | ✅ 実装済 |
| **書籍** | CRUD操作（作成/読取/更新/削除） | ✅ 実装済 |
| **ソーシャル** | コメント機能 | ✅ 実装済 |
| **ソーシャル** | いいね機能 | ✅ 実装済 |
| **ユーザー** | プロフィール表示/編集 | ✅ 実装済 |
| **画像** | プロフィール画像アップロード | ✅ 実装済 |

### 2.3 現行システムの課題

```
課題1: UI/UXの老朽化
├── ライトモードのみ対応
├── レスポンシブ対応が不十分
└── 視覚的フィードバックの不足

課題2: 技術的負債
├── Webpacker（非推奨）の使用
├── jQuery依存のレガシーコード
└── N+1クエリ問題

課題3: 機能不足
├── 検索機能なし
├── フォロー機能なし
├── 通知機能なし
└── 本の評価（★）機能なし
```

---

## 3. 技術要件

### 3.1 新技術スタック

```
┌─────────────────────────────────────────────────────────────┐
│                    New Stack (2026)                          │
├─────────────────────────────────────────────────────────────┤
│  Framework      │ Rails 7.1+                                │
│  Ruby           │ 3.3.x                                     │
│  Frontend       │ Hotwire (Turbo + Stimulus)                │
│  CSS            │ Tailwind CSS 3.x + カスタムダークテーマ    │
│  Database       │ PostgreSQL 15+ (本番) / SQLite (開発)     │
│  Auth           │ Devise + OmniAuth (SNS認証)               │
│  Bundler        │ esbuild / importmap-rails                 │
│  Cache          │ Redis                                     │
│  Background Job │ Solid Queue / Sidekiq                     │
│  Search         │ Meilisearch / PostgreSQL Full Text Search │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Hotwire導入によるメリット

```ruby
# Before: 従来のフルページリロード
def create
  @book = Book.new(book_params)
  if @book.save
    redirect_to @book, notice: '投稿しました'  # ページ全体リロード
  end
end

# After: Turbo Streamによる部分更新
def create
  @book = Book.new(book_params)
  if @book.save
    respond_to do |format|
      format.turbo_stream  # 投稿リストのみ更新（SPAライク）
      format.html { redirect_to @book }
    end
  end
end
```

**Hotwire採用理由**:
- JavaScript最小限でSPAライクな体験を実現
- Railsとの親和性が高い（Rails 7のデフォルト）
- 学習コストが低い
- SEO対策が容易（SSR）

### 3.3 フロントエンドアーキテクチャ

```
app/
├── javascript/
│   ├── controllers/           # Stimulus Controllers
│   │   ├── application.js
│   │   ├── dark_mode_controller.js
│   │   ├── dropdown_controller.js
│   │   ├── modal_controller.js
│   │   ├── infinite_scroll_controller.js
│   │   ├── search_controller.js
│   │   └── toast_controller.js
│   └── application.js
├── views/
│   ├── books/
│   │   ├── _book.html.erb
│   │   ├── _form.html.erb
│   │   ├── create.turbo_stream.erb   # Turbo Stream
│   │   └── destroy.turbo_stream.erb
│   └── ...
└── assets/
    └── stylesheets/
        ├── application.tailwind.css
        └── components/
            ├── _buttons.css
            ├── _cards.css
            └── _dark_theme.css
```

---

## 4. UI/UX要件

### 4.1 デザインシステム

#### 4.1.1 カラーパレット（ダークモード基調）

```css
/* Primary Colors */
--color-bg-primary: #0d1117;      /* メイン背景 */
--color-bg-secondary: #161b22;    /* カード背景 */
--color-bg-tertiary: #21262d;     /* ホバー状態 */

/* Text Colors */
--color-text-primary: #e6edf3;    /* メインテキスト */
--color-text-secondary: #8b949e;  /* サブテキスト */
--color-text-muted: #6e7681;      /* 控えめテキスト */

/* Accent Colors */
--color-accent-primary: #58a6ff;  /* プライマリアクセント（リンク） */
--color-accent-success: #3fb950;  /* 成功 */
--color-accent-warning: #d29922;  /* 警告 */
--color-accent-danger: #f85149;   /* エラー */
--color-accent-purple: #a371f7;   /* 特別なハイライト */

/* Border */
--color-border: #30363d;          /* ボーダー */
```

#### 4.1.2 タイポグラフィ

```css
/* Font Family */
--font-sans: 'Inter', 'Noto Sans JP', system-ui, sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;

/* Font Sizes */
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
```

#### 4.1.3 スペーシング・レイアウト

```css
/* Spacing Scale */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */

/* Border Radius */
--radius-sm: 0.375rem;   /* 6px */
--radius-md: 0.5rem;     /* 8px */
--radius-lg: 0.75rem;    /* 12px */
--radius-full: 9999px;   /* 円形 */
```

### 4.2 コンポーネント設計

#### 4.2.1 ナビゲーションバー

```
┌────────────────────────────────────────────────────────────────┐
│  📚 Bookers    [検索...]    Home  Books  Users  🔔  👤        │
└────────────────────────────────────────────────────────────────┘
```

**仕様**:
- 固定ヘッダー（スクロール時も表示）
- グローバル検索バー
- 通知ベルアイコン（未読数バッジ）
- ユーザーアバタードロップダウン

#### 4.2.2 書籍カード

```
┌─────────────────────────────────────────┐
│  ┌─────┐                                │
│  │ 📖  │  書籍タイトル                   │
│  │     │  ★★★★☆ (4.2)                  │
│  └─────┘                                │
│                                          │
│  感想文の最初の100文字がここに表示       │
│  されます...                             │
│                                          │
│  ┌────┐ ユーザー名 • 2時間前            │
│  │ 👤 │                                  │
│  └────┘                                  │
│                                          │
│  ❤️ 42    💬 12    🔖                    │
└─────────────────────────────────────────┘
```

**仕様**:
- ホバーエフェクト（微妙な浮き上がり）
- 画像遅延読み込み
- アニメーション付きいいねボタン
- 感想文のトランケーション

#### 4.2.3 ユーザープロフィールカード

```
┌─────────────────────────────────────────┐
│         ┌──────────┐                    │
│         │   👤     │                    │
│         └──────────┘                    │
│           ユーザー名                     │
│         @username                        │
│                                          │
│  自己紹介文がここに表示されます。        │
│  読書が大好きです。                      │
│                                          │
│  📚 42冊    👥 128フォロワー             │
│                                          │
│  [フォローする]  [メッセージ]            │
└─────────────────────────────────────────┘
```

### 4.3 ページレイアウト

#### 4.3.1 トップページ（ランディング）

```
┌────────────────────────────────────────────────────────────────┐
│  📚 Bookers                              [ログイン] [新規登録] │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│          本を読む。感想を書く。世界とつながる。                 │
│                                                                 │
│              [無料で始める]                                     │
│                                                                 │
├────────────────────────────────────────────────────────────────┤
│  🔥 トレンドの投稿                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                        │
│  │  Card1  │  │  Card2  │  │  Card3  │                        │
│  └─────────┘  └─────────┘  └─────────┘                        │
├────────────────────────────────────────────────────────────────┤
│  📊 統計                                                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                        │
│  │ 1,234   │  │  567    │  │  89     │                        │
│  │ 投稿数  │  │ユーザー │  │今日の投稿│                        │
│  └─────────┘  └─────────┘  └─────────┘                        │
└────────────────────────────────────────────────────────────────┘
```

#### 4.3.2 ダッシュボード（ログイン後）

```
┌────────────────────────────────────────────────────────────────┐
│  Navbar                                                         │
├──────────────┬─────────────────────────────────────────────────┤
│              │                                                  │
│  サイドバー   │  メインコンテンツ                                │
│              │                                                  │
│  📖 タイムライン│  ┌────────────────────────────────────────┐   │
│  📚 マイ本棚  │  │  新規投稿フォーム                        │   │
│  👥 フォロー中│  └────────────────────────────────────────┘   │
│  🔖 ブックマーク│                                              │
│  ⚙️ 設定     │  ┌─────────┐  ┌─────────┐                     │
│              │  │  Feed1  │  │  Feed2  │                     │
│              │  └─────────┘  └─────────┘                     │
│              │  ┌─────────┐  ┌─────────┐                     │
│              │  │  Feed3  │  │  Feed4  │                     │
│              │  └─────────┘  └─────────┘                     │
└──────────────┴─────────────────────────────────────────────────┘
```

### 4.4 マイクロインタラクション

| インタラクション | 詳細 |
|-----------------|------|
| **いいねアニメーション** | ハートが拡大→縮小するアニメーション（300ms） |
| **トースト通知** | 右下から滑り込む成功/エラー通知 |
| **スケルトンローディング** | コンテンツ読み込み中のプレースホルダー |
| **無限スクロール** | スクロール時に自動読み込み（Turbo Frames） |
| **リアルタイムバリデーション** | フォーム入力時の即座フィードバック |
| **ドラッグ&ドロップ** | 画像アップロード時のドラッグ対応 |

### 4.5 レスポンシブ対応

```
Breakpoints:
- Mobile:  < 640px   (sm)
- Tablet:  640-1024px (md)
- Desktop: > 1024px  (lg)

モバイル最適化:
- ボトムナビゲーション
- スワイプジェスチャー対応
- タッチフレンドリーなボタンサイズ（最小44x44px）
```

### 4.6 アクセシビリティ要件

| 要件 | 実装方法 |
|------|----------|
| **キーボードナビゲーション** | Tab/Enter/Escキー対応 |
| **スクリーンリーダー** | ARIA属性の適切な使用 |
| **コントラスト比** | WCAG 2.1 AA準拠（4.5:1以上） |
| **フォーカス表示** | 視認性の高いフォーカスリング |
| **動作の軽減** | `prefers-reduced-motion` 対応 |

---

## 5. 機能要件

### 5.1 機能一覧（優先度別）

#### 5.1.1 必須機能（P0）

| ID | 機能 | 説明 |
|----|------|------|
| F001 | ダークモードUI | システム設定連動 + 手動切替 |
| F002 | ユーザー認証強化 | SNS認証（Google/GitHub） |
| F003 | 書籍CRUD | Turbo Stream対応 |
| F004 | コメント機能 | リアルタイム更新 |
| F005 | いいね機能 | Optimistic UI対応 |
| F006 | ユーザープロフィール | 編集・表示の強化 |

#### 5.1.2 重要機能（P1）

| ID | 機能 | 説明 |
|----|------|------|
| F101 | ★評価システム | 5段階評価 + 平均スコア表示 |
| F102 | フォロー/フォロワー | ユーザー間のフォロー機能 |
| F103 | タイムライン | フォローユーザーの投稿表示 |
| F104 | 検索機能 | 書籍/ユーザー全文検索 |
| F105 | 通知機能 | いいね/コメント/フォロー通知 |
| F106 | ブックマーク | 後で読む機能 |

#### 5.1.3 追加機能（P2）

| ID | 機能 | 説明 |
|----|------|------|
| F201 | タグ/カテゴリ | 書籍のジャンル分類 |
| F202 | 読書統計 | 月間/年間の読書グラフ |
| F203 | バッジシステム | 活動に応じた実績バッジ |
| F204 | 書籍API連携 | Google Books APIによる書籍情報自動取得 |
| F205 | シェア機能 | Twitter/LINE等へのシェア |
| F206 | ダイレクトメッセージ | ユーザー間チャット（Action Cable） |

### 5.2 機能詳細

#### F001: ダークモードUI

```javascript
// dark_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.applyTheme(this.currentTheme)
  }

  toggle() {
    const newTheme = this.currentTheme === 'dark' ? 'light' : 'dark'
    localStorage.setItem('theme', newTheme)
    this.applyTheme(newTheme)
  }

  get currentTheme() {
    return localStorage.getItem('theme') ||
           (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  }

  applyTheme(theme) {
    document.documentElement.classList.toggle('dark', theme === 'dark')
  }
}
```

#### F101: ★評価システム

```ruby
# app/models/rating.rb
class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :score, presence: true,
            inclusion: { in: 1..5, message: "は1〜5の範囲で入力してください" }
  validates :user_id, uniqueness: { scope: :book_id }
end

# app/models/book.rb
class Book < ApplicationRecord
  has_many :ratings, dependent: :destroy

  def average_rating
    ratings.average(:score)&.round(1) || 0
  end

  def rating_count
    ratings.count
  end
end
```

#### F102: フォロー/フォロワー

```ruby
# app/models/relationship.rb
class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }
end

# app/models/user.rb (追加)
class User < ApplicationRecord
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  def follow(other_user)
    following << other_user unless self == other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end
end
```

#### F103: タイムライン

```ruby
# app/models/user.rb (追加)
def feed
  following_ids = "SELECT followed_id FROM relationships
                   WHERE follower_id = :user_id"
  Book.where("user_id IN (#{following_ids}) OR user_id = :user_id",
             user_id: id)
      .includes(:user, :ratings)
      .order(created_at: :desc)
end
```

#### F104: 検索機能

```ruby
# app/models/book.rb (検索スコープ追加)
class Book < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_all,
    against: [:title, :body],
    associated_against: {
      user: [:name]
    },
    using: {
      tsearch: { prefix: true, dictionary: "simple" }
    }

  scope :search, ->(query) {
    return all if query.blank?
    search_all(query)
  }
end
```

#### F105: 通知機能

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(20) }

  TYPES = %w[like comment follow].freeze
  validates :notification_type, inclusion: { in: TYPES }

  def mark_as_read!
    update!(read_at: Time.current)
  end
end
```

---

## 6. 非機能要件

### 6.1 パフォーマンス要件

| 指標 | 目標値 |
|------|--------|
| **初期ページロード** | < 2秒（LCP） |
| **インタラクション応答** | < 100ms（FID） |
| **レイアウトシフト** | < 0.1（CLS） |
| **API応答時間** | < 200ms（P95） |
| **同時接続数** | 1,000ユーザー以上 |

### 6.2 最適化戦略

```ruby
# config/initializers/bullet.rb (N+1検出)
if Rails.env.development?
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
end

# Eager Loading
@books = Book.includes(:user, :ratings, :favorites, :book_comments)
             .order(created_at: :desc)
             .page(params[:page])
             .per(20)

# Counter Cache
class Book < ApplicationRecord
  belongs_to :user, counter_cache: true
  has_many :favorites, counter_cache: true
  has_many :book_comments, counter_cache: true
end

# Fragment Caching
<% cache book do %>
  <%= render partial: "books/card", locals: { book: book } %>
<% end %>
```

### 6.3 可用性要件

| 項目 | 目標 |
|------|------|
| **稼働率** | 99.5%以上 |
| **計画停止** | 月1回・最大2時間 |
| **データバックアップ** | 日次自動バックアップ |
| **障害復旧時間** | 4時間以内（RTO） |

### 6.4 スケーラビリティ

```
インフラ構成（本番環境想定）:

┌─────────────────────────────────────────────────┐
│                  Load Balancer                   │
└──────────────────────┬──────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐
    │  App 1  │   │  App 2  │   │  App 3  │
    │ (Puma)  │   │ (Puma)  │   │ (Puma)  │
    └────┬────┘   └────┬────┘   └────┬────┘
         │             │             │
         └─────────────┼─────────────┘
                       │
              ┌────────┴────────┐
              ▼                 ▼
       ┌───────────┐     ┌───────────┐
       │PostgreSQL │     │   Redis   │
       │ (Primary) │     │  (Cache)  │
       └─────┬─────┘     └───────────┘
             │
       ┌─────┴─────┐
       │PostgreSQL │
       │ (Replica) │
       └───────────┘
```

---

## 7. データベース設計

### 7.1 新規ER図

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    users    │────<│    books    │>────│   ratings   │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ id          │     │ id          │     │ id          │
│ email       │     │ title       │     │ score       │
│ name        │     │ body        │     │ user_id     │
│ username    │     │ user_id     │     │ book_id     │
│ introduction│     │ status      │     │ created_at  │
│ avatar_url  │     │ created_at  │     └─────────────┘
│ provider    │     └─────────────┘
│ uid         │            │
│ created_at  │            │
└─────────────┘            │
      │                    │
      │         ┌──────────┴──────────┐
      │         │                     │
      ▼         ▼                     ▼
┌─────────────────┐         ┌─────────────────┐
│  relationships  │         │    favorites    │
├─────────────────┤         ├─────────────────┤
│ id              │         │ id              │
│ follower_id     │         │ user_id         │
│ followed_id     │         │ book_id         │
│ created_at      │         │ created_at      │
└─────────────────┘         └─────────────────┘

      │                           │
      │                           │
      ▼                           ▼
┌─────────────────┐         ┌─────────────────┐
│  notifications  │         │  book_comments  │
├─────────────────┤         ├─────────────────┤
│ id              │         │ id              │
│ recipient_id    │         │ comment         │
│ actor_id        │         │ user_id         │
│ notifiable_type │         │ book_id         │
│ notifiable_id   │         │ created_at      │
│ notification_type│        └─────────────────┘
│ read_at         │
│ created_at      │
└─────────────────┘

┌─────────────────┐         ┌─────────────────┐
│    bookmarks    │         │      tags       │
├─────────────────┤         ├─────────────────┤
│ id              │         │ id              │
│ user_id         │         │ name            │
│ book_id         │         │ books_count     │
│ created_at      │         │ created_at      │
└─────────────────┘         └─────────────────┘
                                   │
                                   ▼
                           ┌─────────────────┐
                           │   book_tags     │
                           ├─────────────────┤
                           │ book_id         │
                           │ tag_id          │
                           └─────────────────┘
```

### 7.2 マイグレーション計画

```ruby
# 1. ratings テーブル追加
class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :score, null: false

      t.timestamps
    end

    add_index :ratings, [:user_id, :book_id], unique: true
  end
end

# 2. relationships テーブル追加
class CreateRelationships < ActiveRecord::Migration[7.1]
  def change
    create_table :relationships do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :relationships, [:follower_id, :followed_id], unique: true
  end
end

# 3. notifications テーブル追加
class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :notification_type, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:recipient_id, :read_at]
  end
end

# 4. bookmarks テーブル追加
class CreateBookmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true

      t.timestamps
    end

    add_index :bookmarks, [:user_id, :book_id], unique: true
  end
end

# 5. tags / book_tags テーブル追加
class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :books_count, default: 0

      t.timestamps
    end

    add_index :tags, :name, unique: true

    create_table :book_tags do |t|
      t.references :book, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
    end

    add_index :book_tags, [:book_id, :tag_id], unique: true
  end
end

# 6. users テーブルにSNS認証用カラム追加
class AddOmniauthToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :username, :string

    add_index :users, :username, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end

# 7. Counter Cache カラム追加
class AddCounterCaches < ActiveRecord::Migration[7.1]
  def change
    add_column :books, :favorites_count, :integer, default: 0
    add_column :books, :book_comments_count, :integer, default: 0
    add_column :books, :ratings_count, :integer, default: 0
    add_column :users, :books_count, :integer, default: 0
    add_column :users, :followers_count, :integer, default: 0
    add_column :users, :following_count, :integer, default: 0
  end
end
```

---

## 8. API設計

### 8.1 RESTful API エンドポイント

```
Authentication:
  POST   /api/v1/auth/sign_in
  DELETE /api/v1/auth/sign_out
  POST   /api/v1/auth/oauth/:provider

Books:
  GET    /api/v1/books                 # 一覧取得（ページネーション）
  POST   /api/v1/books                 # 新規作成
  GET    /api/v1/books/:id             # 詳細取得
  PATCH  /api/v1/books/:id             # 更新
  DELETE /api/v1/books/:id             # 削除
  GET    /api/v1/books/search          # 検索

Users:
  GET    /api/v1/users                 # 一覧取得
  GET    /api/v1/users/:id             # 詳細取得
  PATCH  /api/v1/users/:id             # 更新
  GET    /api/v1/users/:id/books       # ユーザーの書籍一覧
  GET    /api/v1/users/:id/followers   # フォロワー一覧
  GET    /api/v1/users/:id/following   # フォロー中一覧

Social:
  POST   /api/v1/books/:book_id/favorites    # いいね
  DELETE /api/v1/books/:book_id/favorites    # いいね解除
  POST   /api/v1/books/:book_id/comments     # コメント投稿
  DELETE /api/v1/books/:book_id/comments/:id # コメント削除
  POST   /api/v1/books/:book_id/ratings      # 評価
  PATCH  /api/v1/books/:book_id/ratings      # 評価更新
  POST   /api/v1/books/:book_id/bookmarks    # ブックマーク
  DELETE /api/v1/books/:book_id/bookmarks    # ブックマーク解除
  POST   /api/v1/users/:id/follow            # フォロー
  DELETE /api/v1/users/:id/follow            # フォロー解除

Notifications:
  GET    /api/v1/notifications              # 通知一覧
  PATCH  /api/v1/notifications/:id/read     # 既読にする
  POST   /api/v1/notifications/read_all     # 全て既読

Feed:
  GET    /api/v1/feed                       # タイムライン
  GET    /api/v1/trending                   # トレンド
```

### 8.2 レスポンス形式

```json
// 成功レスポンス
{
  "status": "success",
  "data": {
    "book": {
      "id": 1,
      "title": "吾輩は猫である",
      "body": "面白い小説でした...",
      "average_rating": 4.2,
      "favorites_count": 42,
      "comments_count": 12,
      "user": {
        "id": 1,
        "name": "夏目漱石",
        "username": "natsume",
        "avatar_url": "/uploads/user/1/avatar.jpg"
      },
      "tags": ["小説", "日本文学", "古典"],
      "created_at": "2026-02-11T10:00:00Z"
    }
  },
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 100
  }
}

// エラーレスポンス
{
  "status": "error",
  "error": {
    "code": "validation_failed",
    "message": "入力内容に問題があります",
    "details": [
      { "field": "title", "message": "を入力してください" },
      { "field": "body", "message": "は200文字以内で入力してください" }
    ]
  }
}
```

---

## 9. セキュリティ要件

### 9.1 認証・認可

| 項目 | 実装 |
|------|------|
| **パスワードハッシュ** | bcrypt（Devise標準） |
| **セッション管理** | Secure Cookie + HTTPOnly |
| **CSRF対策** | Rails標準トークン |
| **認可** | Punditポリシー |

```ruby
# app/policies/book_policy.rb
class BookPolicy < ApplicationPolicy
  def update?
    user == record.user
  end

  def destroy?
    user == record.user
  end
end
```

### 9.2 入力バリデーション

```ruby
# Strong Parameters
def book_params
  params.require(:book).permit(:title, :body, :image, tag_ids: [])
end

# モデルバリデーション
class Book < ApplicationRecord
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 2000 }
  validates :title, :body,
            format: { without: /<script/i, message: "に不正な文字が含まれています" }
end
```

### 9.3 レート制限

```ruby
# config/initializers/rack_attack.rb
class Rack::Attack
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end
end
```

---

## 10. テスト要件

### 10.1 テストカバレッジ目標

| レイヤー | カバレッジ目標 |
|---------|---------------|
| モデル | 90%以上 |
| コントローラー | 80%以上 |
| システム（E2E） | 70%以上 |
| 全体 | 80%以上 |

### 10.2 テスト構成

```ruby
# spec/models/book_spec.rb
RSpec.describe Book, type: :model do
  describe 'バリデーション' do
    it 'タイトルが必須であること'
    it '感想文が2000文字以内であること'
    it '評価の平均が正しく計算されること'
  end

  describe 'アソシエーション' do
    it 'ユーザーに属すること'
    it 'コメントを複数持つこと'
    it 'いいねを複数持つこと'
  end
end

# spec/system/books_spec.rb
RSpec.describe '書籍投稿', type: :system do
  before { driven_by(:selenium_chrome_headless) }

  it 'ユーザーが書籍を投稿できること' do
    sign_in user
    visit books_path

    fill_in 'タイトル', with: 'テスト書籍'
    fill_in '感想', with: '素晴らしい本でした'
    click_button '投稿する'

    expect(page).to have_content 'テスト書籍'
    expect(page).to have_content '投稿しました'
  end
end
```

### 10.3 CI/CD パイプライン

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Setup database
        run: bin/rails db:setup
        env:
          RAILS_ENV: test

      - name: Run tests
        run: bundle exec rspec

      - name: Run linter
        run: bundle exec rubocop
```

---

## 11. 移行計画

### 11.1 フェーズ分け

```
Phase 1: 基盤構築（2週間）
├── Rails 7.1へのアップグレード
├── Hotwire (Turbo/Stimulus) 導入
├── Tailwind CSS導入
└── ダークモードテーマ実装

Phase 2: UI/UX刷新（3週間）
├── 新デザインシステム実装
├── 全ページのリデザイン
├── レスポンシブ対応
└── マイクロインタラクション実装

Phase 3: 機能拡張（4週間）
├── 評価システム実装
├── フォロー機能実装
├── 通知機能実装
├── 検索機能実装
└── ブックマーク機能実装

Phase 4: テスト・最適化（2週間）
├── 統合テスト
├── パフォーマンス最適化
├── セキュリティ監査
└── ドキュメント整備

Phase 5: 本番移行（1週間）
├── 本番環境構築
├── データ移行
├── 監視設定
└── リリース
```

### 11.2 データ移行戦略

```ruby
# db/seeds/migrate_data.rb
# 既存データの移行スクリプト

# 1. カウンターキャッシュの再計算
Book.find_each do |book|
  Book.reset_counters(book.id, :favorites, :book_comments)
end

User.find_each do |user|
  User.reset_counters(user.id, :books)
end

# 2. デフォルト評価の設定（必要に応じて）
# Book.where(ratings_count: 0).find_each do |book|
#   book.ratings.create(user: book.user, score: 3)
# end
```

---

## 12. README強化計画

### 12.1 新README構成

```markdown
# 📚 Bookers - 読書感想共有プラットフォーム

> 本を読む。感想を書く。世界とつながる。

[![Ruby](https://img.shields.io/badge/Ruby-3.3-red.svg)]()
[![Rails](https://img.shields.io/badge/Rails-7.1-red.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

## ✨ 特徴

- 📖 読書感想の投稿・共有
- ⭐ 5段階評価システム
- 💬 コメント・いいね機能
- 👥 フォロー機能
- 🔔 リアルタイム通知
- 🌙 ダークモード対応
- 📱 レスポンシブデザイン

## 🖼️ スクリーンショット

[ダッシュボード画像]
[書籍詳細画像]
[プロフィール画像]

## 🚀 デモ

- **URL**: https://bookers-demo.herokuapp.com
- **テストアカウント**: demo@example.com / password

## 🛠️ 技術スタック

| カテゴリ | 技術 |
|---------|------|
| Backend | Ruby 3.3, Rails 7.1 |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS |
| Database | PostgreSQL 15 |
| Auth | Devise, OmniAuth |
| Testing | RSpec, Capybara |
| CI/CD | GitHub Actions |

## 📦 セットアップ

### 必要条件

- Ruby 3.3.x
- PostgreSQL 15+
- Node.js 20+

### インストール

（詳細手順）

## 🏗️ アーキテクチャ

（ER図、システム構成図）

## 🧪 テスト

（テスト実行方法）

## 📄 API ドキュメント

（主要エンドポイント）

## 🤝 コントリビューション

（貢献方法）

## 📝 ライセンス

MIT License

## 👨‍💻 作者

（作者情報）
```

---

## 付録

### A. 参考資料

- [Rails 7 + Hotwire 公式ドキュメント](https://turbo.hotwired.dev/)
- [Tailwind CSS ドキュメント](https://tailwindcss.com/docs)
- [2026 Dark Mode Best Practices](https://www.designstudiouiux.com/blog/dark-mode-ui-design-best-practices/)
- [UI/UX Trends 2026](https://medium.com/design-bootcamp/top-ui-ux-trends-to-watch-in-2026-379a955ce591)

### B. 用語集

| 用語 | 説明 |
|------|------|
| **Hotwire** | HTML Over The Wire。JavaScriptを最小限に抑えつつSPAライクな体験を実現する技術 |
| **Turbo** | ページ遷移・フォーム送信の高速化を担当 |
| **Stimulus** | 軽量なJavaScriptフレームワーク |
| **Turbo Stream** | 部分的なDOM更新を実現 |
| **Turbo Frame** | ページの一部分だけを更新 |

---

**文書管理**

| バージョン | 日付 | 変更内容 | 作成者 |
|-----------|------|----------|--------|
| 1.0 | 2026-02-11 | 初版作成 | Claude Code |
