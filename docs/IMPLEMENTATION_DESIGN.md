# Bookers2 Next Generation - 実装設計書

**バージョン**: 1.0
**作成日**: 2026年2月11日
**対象**: 要件定義書 v2.0

---

## 目次

1. [システムアーキテクチャ](#1-システムアーキテクチャ)
2. [ディレクトリ構成](#2-ディレクトリ構成)
3. [環境構築手順](#3-環境構築手順)
4. [データベース詳細設計](#4-データベース詳細設計)
5. [モデル設計](#5-モデル設計)
6. [コントローラー設計](#6-コントローラー設計)
7. [ビュー設計](#7-ビュー設計)
8. [フロントエンド設計](#8-フロントエンド設計)
9. [認証・認可設計](#9-認証認可設計)
10. [リアルタイム機能設計](#10-リアルタイム機能設計)
11. [検索機能設計](#11-検索機能設計)
12. [テスト設計](#12-テスト設計)
13. [デプロイ設計](#13-デプロイ設計)

---

## 1. システムアーキテクチャ

### 1.1 全体構成図

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Client Layer                                  │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │
│  │   Browser   │  │   Mobile    │  │   PWA       │                     │
│  │  (Desktop)  │  │  (Safari)   │  │             │                     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                     │
│         │                │                │                             │
│         └────────────────┼────────────────┘                             │
│                          │                                              │
│                    HTTPS/WSS                                            │
└──────────────────────────┼──────────────────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────────────┐
│                     Application Layer                                    │
├──────────────────────────┼──────────────────────────────────────────────┤
│                          ▼                                              │
│  ┌───────────────────────────────────────────────────────────────┐     │
│  │                     Nginx (Reverse Proxy)                      │     │
│  │              - SSL Termination                                 │     │
│  │              - Static File Serving                             │     │
│  │              - Load Balancing                                  │     │
│  └───────────────────────────────────────────────────────────────┘     │
│                          │                                              │
│         ┌────────────────┼────────────────┐                            │
│         ▼                ▼                ▼                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │
│  │  Puma #1    │  │  Puma #2    │  │  Puma #3    │                     │
│  │  Rails 7.1  │  │  Rails 7.1  │  │  Rails 7.1  │                     │
│  │  ┌───────┐  │  │  ┌───────┐  │  │  ┌───────┐  │                     │
│  │  │Hotwire│  │  │  │Hotwire│  │  │  │Hotwire│  │                     │
│  │  │Turbo  │  │  │  │Turbo  │  │  │  │Turbo  │  │                     │
│  │  │Stimulus│ │  │  │Stimulus│ │  │  │Stimulus│ │                     │
│  │  └───────┘  │  │  └───────┘  │  │  └───────┘  │                     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                     │
│         │                │                │                             │
│         └────────────────┼────────────────┘                             │
│                          │                                              │
└──────────────────────────┼──────────────────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────────────────┐
│                       Data Layer                                         │
├──────────────────────────┼──────────────────────────────────────────────┤
│         ┌────────────────┼────────────────┐                             │
│         ▼                ▼                ▼                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │
│  │ PostgreSQL  │  │    Redis    │  │   AWS S3    │                     │
│  │   Primary   │  │   Cache +   │  │   Images    │                     │
│  │             │  │ Action Cable│  │             │                     │
│  └─────────────┘  └─────────────┘  └─────────────┘                     │
│         │                                                               │
│         ▼                                                               │
│  ┌─────────────┐                                                        │
│  │ PostgreSQL  │                                                        │
│  │   Replica   │                                                        │
│  └─────────────┘                                                        │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 技術スタック詳細

| レイヤー | 技術 | バージョン | 用途 |
|---------|------|-----------|------|
| **Language** | Ruby | 3.3.0 | サーバーサイド |
| **Framework** | Rails | 7.1.3 | Webフレームワーク |
| **Frontend** | Hotwire | 2.0 | Turbo + Stimulus |
| **CSS** | Tailwind CSS | 3.4 | スタイリング |
| **Database** | PostgreSQL | 16 | メインDB |
| **Cache** | Redis | 7.2 | キャッシュ/WebSocket |
| **Web Server** | Puma | 6.4 | アプリケーションサーバー |
| **Reverse Proxy** | Nginx | 1.25 | リバースプロキシ |
| **Storage** | AWS S3 | - | 画像ストレージ |
| **Search** | pg_search | 2.3 | 全文検索 |

### 1.3 Gem依存関係

```ruby
# Gemfile

source "https://rubygems.org"

ruby "3.3.0"

# === Core ===
gem "rails", "~> 7.1.3"
gem "pg", "~> 1.5"
gem "puma", ">= 6.4"
gem "bootsnap", require: false

# === Frontend ===
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# === Authentication ===
gem "devise", "~> 4.9"
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"

# === Authorization ===
gem "pundit", "~> 2.3"

# === Image Processing ===
gem "image_processing", "~> 1.12"
gem "aws-sdk-s3", require: false

# === Search ===
gem "pg_search", "~> 2.3"

# === Pagination ===
gem "kaminari", "~> 1.2"

# === Background Jobs ===
gem "solid_queue", "~> 0.2"

# === Caching ===
gem "redis", ">= 5.0"
gem "hiredis-client"

# === Performance ===
gem "rack-mini-profiler"
gem "bullet", group: :development

# === API ===
gem "faraday"          # Google Books API用
gem "faraday-retry"

group :development, :test do
  gem "debug"
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "web-console"
  gem "annotate"
  gem "erb_lint", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end
```

---

## 2. ディレクトリ構成

```
bookers2.ver2/
├── app/
│   ├── assets/
│   │   ├── images/
│   │   │   ├── logo.svg
│   │   │   ├── logo-dark.svg
│   │   │   ├── default-avatar.png
│   │   │   ├── default-book.png
│   │   │   └── icons/
│   │   └── stylesheets/
│   │       └── application.tailwind.css
│   │
│   ├── channels/
│   │   ├── application_cable/
│   │   │   ├── channel.rb
│   │   │   └── connection.rb
│   │   └── notification_channel.rb
│   │
│   ├── components/                    # ViewComponent
│   │   ├── application_component.rb
│   │   ├── book_card_component.rb
│   │   ├── book_card_component.html.erb
│   │   ├── user_card_component.rb
│   │   ├── user_card_component.html.erb
│   │   ├── notification_component.rb
│   │   ├── notification_component.html.erb
│   │   ├── rating_stars_component.rb
│   │   ├── rating_stars_component.html.erb
│   │   ├── flash_component.rb
│   │   └── flash_component.html.erb
│   │
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb
│   │   ├── books_controller.rb
│   │   ├── users_controller.rb
│   │   ├── relationships_controller.rb
│   │   ├── favorites_controller.rb
│   │   ├── book_comments_controller.rb
│   │   ├── ratings_controller.rb
│   │   ├── bookmarks_controller.rb
│   │   ├── notifications_controller.rb
│   │   ├── search_controller.rb
│   │   └── users/
│   │       └── omniauth_callbacks_controller.rb
│   │
│   ├── helpers/
│   │   ├── application_helper.rb
│   │   ├── books_helper.rb
│   │   └── users_helper.rb
│   │
│   ├── javascript/
│   │   ├── application.js
│   │   └── controllers/
│   │       ├── application.js
│   │       ├── index.js
│   │       ├── dark_mode_controller.js
│   │       ├── dropdown_controller.js
│   │       ├── modal_controller.js
│   │       ├── toast_controller.js
│   │       ├── infinite_scroll_controller.js
│   │       ├── search_controller.js
│   │       ├── rating_controller.js
│   │       ├── favorite_controller.js
│   │       ├── image_preview_controller.js
│   │       ├── character_count_controller.js
│   │       ├── tabs_controller.js
│   │       └── notification_controller.js
│   │
│   ├── jobs/
│   │   ├── application_job.rb
│   │   └── notification_broadcast_job.rb
│   │
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   └── notification_mailer.rb
│   │
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── user.rb
│   │   ├── book.rb
│   │   ├── book_comment.rb
│   │   ├── favorite.rb
│   │   ├── rating.rb
│   │   ├── relationship.rb
│   │   ├── bookmark.rb
│   │   ├── notification.rb
│   │   ├── tag.rb
│   │   └── book_tag.rb
│   │
│   ├── policies/                      # Pundit
│   │   ├── application_policy.rb
│   │   ├── book_policy.rb
│   │   ├── user_policy.rb
│   │   └── book_comment_policy.rb
│   │
│   ├── services/                      # Service Objects
│   │   ├── books/
│   │   │   ├── create_service.rb
│   │   │   └── search_service.rb
│   │   ├── notifications/
│   │   │   ├── create_service.rb
│   │   │   └── broadcast_service.rb
│   │   └── external/
│   │       └── google_books_service.rb
│   │
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb
│       │   ├── _navbar.html.erb
│       │   ├── _sidebar.html.erb
│       │   ├── _footer.html.erb
│       │   └── _flash.html.erb
│       ├── home/
│       │   ├── top.html.erb
│       │   └── about.html.erb
│       ├── books/
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   ├── new.html.erb
│       │   ├── edit.html.erb
│       │   ├── _book.html.erb
│       │   ├── _form.html.erb
│       │   ├── _book_card.html.erb
│       │   ├── create.turbo_stream.erb
│       │   ├── update.turbo_stream.erb
│       │   └── destroy.turbo_stream.erb
│       ├── users/
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   ├── edit.html.erb
│       │   ├── _user_card.html.erb
│       │   ├── _stats.html.erb
│       │   ├── followers.html.erb
│       │   └── following.html.erb
│       ├── favorites/
│       │   ├── create.turbo_stream.erb
│       │   └── destroy.turbo_stream.erb
│       ├── book_comments/
│       │   ├── _comment.html.erb
│       │   ├── _form.html.erb
│       │   ├── create.turbo_stream.erb
│       │   └── destroy.turbo_stream.erb
│       ├── ratings/
│       │   └── create.turbo_stream.erb
│       ├── relationships/
│       │   ├── create.turbo_stream.erb
│       │   └── destroy.turbo_stream.erb
│       ├── bookmarks/
│       │   ├── index.html.erb
│       │   ├── create.turbo_stream.erb
│       │   └── destroy.turbo_stream.erb
│       ├── notifications/
│       │   ├── index.html.erb
│       │   ├── _notification.html.erb
│       │   └── _notification.turbo_stream.erb
│       ├── search/
│       │   └── index.html.erb
│       ├── devise/
│       │   ├── registrations/
│       │   │   ├── new.html.erb
│       │   │   └── edit.html.erb
│       │   ├── sessions/
│       │   │   └── new.html.erb
│       │   └── shared/
│       │       └── _links.html.erb
│       └── shared/
│           ├── _pagination.html.erb
│           ├── _loading.html.erb
│           └── _empty_state.html.erb
│
├── config/
│   ├── application.rb
│   ├── routes.rb
│   ├── database.yml
│   ├── cable.yml
│   ├── storage.yml
│   ├── tailwind.config.js
│   ├── importmap.rb
│   └── initializers/
│       ├── devise.rb
│       ├── omniauth.rb
│       ├── pundit.rb
│       ├── kaminari.rb
│       └── inflections.rb
│
├── db/
│   ├── migrate/
│   ├── schema.rb
│   └── seeds.rb
│
├── spec/
│   ├── rails_helper.rb
│   ├── spec_helper.rb
│   ├── factories/
│   ├── models/
│   ├── requests/
│   ├── system/
│   └── support/
│
├── docs/
│   ├── REQUIREMENTS_SPECIFICATION.md
│   └── IMPLEMENTATION_DESIGN.md
│
└── public/
    └── ...
```

---

## 3. 環境構築手順

### 3.1 必要要件

```bash
# 必須ソフトウェア
Ruby      >= 3.3.0
Node.js   >= 20.0.0
PostgreSQL >= 16
Redis     >= 7.0
```

### 3.2 初期セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/username/bookers2.ver2.git
cd bookers2.ver2

# 2. Rubyバージョン確認・設定
rbenv install 3.3.0
rbenv local 3.3.0

# 3. Gem インストール
bundle install

# 4. JavaScript依存関係（importmap使用のため最小限）
# Tailwind CSSのみ別途ビルドが必要

# 5. データベース作成
rails db:create
rails db:migrate
rails db:seed

# 6. 環境変数設定
cp .env.example .env
# .envファイルを編集

# 7. 開発サーバー起動
bin/dev
```

### 3.3 環境変数設定

```bash
# .env.example

# Database
DATABASE_URL=postgresql://localhost/bookers2_development

# Redis
REDIS_URL=redis://localhost:6379/1

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_base

# OAuth - Google
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# OAuth - GitHub
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# AWS S3 (本番環境用)
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-1
AWS_BUCKET=bookers2-production

# Google Books API (オプション)
GOOGLE_BOOKS_API_KEY=your_google_books_api_key
```

### 3.4 bin/dev スクリプト

```bash
#!/usr/bin/env bash

# Procfile.devを使用して並列起動
if ! command -v foreman &> /dev/null; then
  echo "Installing foreman..."
  gem install foreman
fi

exec foreman start -f Procfile.dev "$@"
```

```yaml
# Procfile.dev
web: bin/rails server -p 3000
css: bin/rails tailwindcss:watch
```

---

## 4. データベース詳細設計

### 4.1 ER図

```
                                    ┌─────────────────┐
                                    │      tags       │
                                    ├─────────────────┤
                              ┌────>│ id              │
                              │     │ name            │
                              │     │ books_count     │
                              │     │ created_at      │
                              │     │ updated_at      │
                              │     └─────────────────┘
                              │
┌─────────────────┐     ┌─────┴───────────┐     ┌─────────────────┐
│     users       │     │   book_tags     │     │     books       │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id          PK  │     │ book_id     FK  │<────│ id          PK  │
│ email           │     │ tag_id      FK  │     │ title           │
│ encrypted_pass  │     └─────────────────┘     │ body            │
│ name            │                             │ user_id     FK  │────┐
│ username        │     ┌─────────────────┐     │ favorites_count │    │
│ introduction    │     │    ratings      │     │ comments_count  │    │
│ provider        │     ├─────────────────┤     │ ratings_count   │    │
│ uid             │     │ id          PK  │     │ avg_rating      │    │
│ followers_count │     │ score           │     │ created_at      │    │
│ following_count │     │ user_id     FK  │────>│ updated_at      │    │
│ books_count     │     │ book_id     FK  │<────└─────────────────┘    │
│ created_at      │     │ created_at      │                            │
│ updated_at      │     └─────────────────┘                            │
└────────┬────────┘                                                    │
         │              ┌─────────────────┐                            │
         │              │   favorites     │                            │
         │              ├─────────────────┤                            │
         ├─────────────>│ id          PK  │                            │
         │              │ user_id     FK  │────────────────────────────┤
         │              │ book_id     FK  │<───────────────────────────┤
         │              │ created_at      │                            │
         │              └─────────────────┘                            │
         │                                                             │
         │              ┌─────────────────┐                            │
         │              │ book_comments   │                            │
         │              ├─────────────────┤                            │
         ├─────────────>│ id          PK  │                            │
         │              │ comment         │                            │
         │              │ user_id     FK  │────────────────────────────┤
         │              │ book_id     FK  │<───────────────────────────┤
         │              │ created_at      │                            │
         │              │ updated_at      │                            │
         │              └─────────────────┘                            │
         │                                                             │
         │              ┌─────────────────┐                            │
         │              │   bookmarks     │                            │
         │              ├─────────────────┤                            │
         ├─────────────>│ id          PK  │                            │
         │              │ user_id     FK  │────────────────────────────┤
         │              │ book_id     FK  │<───────────────────────────┘
         │              │ created_at      │
         │              └─────────────────┘
         │
         │              ┌─────────────────┐
         │              │  relationships  │
         │              ├─────────────────┤
         ├─────────────>│ id          PK  │
         │              │ follower_id FK  │───┐
         │              │ followed_id FK  │───┤
         │              │ created_at      │   │
         │              └─────────────────┘   │
         │                                    │
         └────────────────────────────────────┘
         │
         │              ┌─────────────────┐
         │              │  notifications  │
         │              ├─────────────────┤
         └─────────────>│ id          PK  │
                        │ recipient_id FK │
                        │ actor_id     FK │
                        │ notifiable_type │
                        │ notifiable_id   │
                        │ action          │
                        │ read_at         │
                        │ created_at      │
                        │ updated_at      │
                        └─────────────────┘
```

### 4.2 マイグレーションファイル

#### 4.2.1 Users テーブル拡張

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_social_auth_to_users.rb
class AddSocialAuthToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :username
      t.string :provider
      t.string :uid
      t.integer :followers_count, default: 0, null: false
      t.integer :following_count, default: 0, null: false
      t.integer :books_count, default: 0, null: false
    end

    add_index :users, :username, unique: true
    add_index :users, [:provider, :uid], unique: true
  end
end
```

#### 4.2.2 Books テーブル拡張

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_counters_to_books.rb
class AddCountersToBooks < ActiveRecord::Migration[7.1]
  def change
    change_table :books, bulk: true do |t|
      t.integer :favorites_count, default: 0, null: false
      t.integer :book_comments_count, default: 0, null: false
      t.integer :ratings_count, default: 0, null: false
      t.decimal :average_rating, precision: 2, scale: 1, default: 0.0
    end

    add_index :books, :average_rating
    add_index :books, :created_at
  end
end
```

#### 4.2.3 Ratings テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_ratings.rb
class CreateRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :score, null: false

      t.timestamps
    end

    add_index :ratings, [:user_id, :book_id], unique: true
    add_check_constraint :ratings, "score >= 1 AND score <= 5", name: "ratings_score_range"
  end
end
```

#### 4.2.4 Relationships テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_relationships.rb
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
```

#### 4.2.5 Bookmarks テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_bookmarks.rb
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
```

#### 4.2.6 Notifications テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_notifications.rb
class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :action, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:recipient_id, :read_at]
    add_index :notifications, [:recipient_id, :created_at]
  end
end
```

#### 4.2.7 Tags テーブル

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_tags.rb
class CreateTags < ActiveRecord::Migration[7.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.integer :books_count, default: 0, null: false

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
```

#### 4.2.8 全文検索用インデックス

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_search_indexes.rb
class AddSearchIndexes < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE INDEX books_search_idx ON books
      USING gin(to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(body, '')));
    SQL

    execute <<-SQL
      CREATE INDEX users_search_idx ON users
      USING gin(to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(username, '')));
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS books_search_idx;"
    execute "DROP INDEX IF EXISTS users_search_idx;"
  end
end
```

---

## 5. モデル設計

### 5.1 User モデル

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :github]

  # === Associations ===
  has_one_attached :avatar

  has_many :books, dependent: :destroy
  has_many :book_comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_books, through: :favorites, source: :book
  has_many :ratings, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_books, through: :bookmarks, source: :book

  # フォロー関係
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower

  # 通知
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification",
                                foreign_key: :actor_id,
                                dependent: :destroy

  # === Validations ===
  validates :name, presence: true, length: { minimum: 2, maximum: 20 }
  validates :username, uniqueness: true, allow_nil: true,
                       format: { with: /\A[a-zA-Z0-9_]+\z/ },
                       length: { minimum: 3, maximum: 20 }
  validates :introduction, length: { maximum: 160 }

  # === Scopes ===
  scope :recent, -> { order(created_at: :desc) }

  # === Callbacks ===
  before_validation :set_default_username, on: :create

  # === Search ===
  include PgSearch::Model
  pg_search_scope :search_by_name,
                  against: [:name, :username],
                  using: { tsearch: { prefix: true, dictionary: "simple" } }

  # === Instance Methods ===

  # アバター画像取得（リサイズ対応）
  def avatar_url(size: :medium)
    sizes = { small: [40, 40], medium: [100, 100], large: [200, 200] }
    width, height = sizes[size]

    if avatar.attached?
      avatar.variant(resize_to_fill: [width, height])
    else
      "default-avatar.png"
    end
  end

  # フォロー操作
  def follow(other_user)
    return if self == other_user || following?(other_user)

    following << other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  # タイムライン取得
  def feed
    following_ids_subquery = active_relationships.select(:followed_id)
    Book.where(user_id: following_ids_subquery)
        .or(Book.where(user_id: id))
        .includes(:user, :tags)
        .with_attached_image
        .order(created_at: :desc)
  end

  # 未読通知数
  def unread_notifications_count
    notifications.unread.count
  end

  # OmniAuth用
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.username = generate_username(auth.info.nickname || auth.info.name)
    end
  end

  private

  def set_default_username
    return if username.present?

    base = name&.parameterize(separator: "_") || "user"
    self.username = self.class.generate_username(base)
  end

  def self.generate_username(base)
    username = base.downcase.gsub(/[^a-z0-9_]/, "_")[0, 15]
    return username unless exists?(username: username)

    loop do
      candidate = "#{username}_#{SecureRandom.hex(3)}"
      return candidate unless exists?(username: candidate)
    end
  end
end
```

### 5.2 Book モデル

```ruby
# app/models/book.rb
class Book < ApplicationRecord
  # === Associations ===
  belongs_to :user, counter_cache: true
  has_one_attached :image

  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user
  has_many :book_comments, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags

  # === Validations ===
  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 2000 }

  # === Scopes ===
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(favorites_count: :desc, created_at: :desc) }
  scope :highly_rated, -> { where("ratings_count >= ?", 3).order(average_rating: :desc) }
  scope :with_associations, -> {
    includes(:user, :tags)
      .with_attached_image
  }

  # === Search ===
  include PgSearch::Model
  pg_search_scope :search_content,
                  against: { title: "A", body: "B" },
                  associated_against: {
                    user: [:name],
                    tags: [:name]
                  },
                  using: {
                    tsearch: { prefix: true, dictionary: "simple" }
                  }

  # === Callbacks ===
  after_save :update_average_rating, if: -> { saved_change_to_ratings_count? }

  # === Instance Methods ===

  # 画像取得
  def image_url(size: :medium)
    sizes = { small: [100, 150], medium: [200, 300], large: [400, 600] }
    width, height = sizes[size]

    if image.attached?
      image.variant(resize_to_fill: [width, height])
    else
      "default-book.png"
    end
  end

  # いいね判定
  def favorited_by?(user)
    return false unless user

    favorites.exists?(user_id: user.id)
  end

  # ブックマーク判定
  def bookmarked_by?(user)
    return false unless user

    bookmarks.exists?(user_id: user.id)
  end

  # ユーザーの評価取得
  def rating_by(user)
    return nil unless user

    ratings.find_by(user_id: user.id)
  end

  # タグ設定
  def tag_list=(names)
    self.tags = names.split(",").map(&:strip).uniq.map do |name|
      Tag.find_or_create_by(name: name.downcase)
    end
  end

  def tag_list
    tags.pluck(:name).join(", ")
  end

  private

  def update_average_rating
    avg = ratings.average(:score)&.round(1) || 0.0
    update_column(:average_rating, avg)
  end
end
```

### 5.3 その他のモデル

```ruby
# app/models/favorite.rb
class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :user_id, uniqueness: { scope: :book_id }

  after_create :create_notification
  after_destroy :destroy_notification

  private

  def create_notification
    return if user == book.user

    Notification.create!(
      recipient: book.user,
      actor: user,
      notifiable: self,
      action: "favorite"
    )
  end

  def destroy_notification
    Notification.where(notifiable: self).destroy_all
  end
end
```

```ruby
# app/models/book_comment.rb
class BookComment < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :comment, presence: true, length: { maximum: 500 }

  after_create :create_notification

  private

  def create_notification
    return if user == book.user

    Notification.create!(
      recipient: book.user,
      actor: user,
      notifiable: self,
      action: "comment"
    )
  end
end
```

```ruby
# app/models/rating.rb
class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :score, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :book_id }

  after_save :update_book_average
  after_destroy :update_book_average

  private

  def update_book_average
    avg = book.ratings.average(:score)&.round(1) || 0.0
    book.update_column(:average_rating, avg)
  end
end
```

```ruby
# app/models/relationship.rb
class Relationship < ApplicationRecord
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :not_self_follow

  after_create :create_notification

  private

  def not_self_follow
    errors.add(:followed_id, "自分自身はフォローできません") if follower_id == followed_id
  end

  def create_notification
    Notification.create!(
      recipient: followed,
      actor: follower,
      notifiable: self,
      action: "follow"
    )
  end
end
```

```ruby
# app/models/bookmark.rb
class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :user_id, uniqueness: { scope: :book_id }
end
```

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  ACTIONS = %w[favorite comment follow].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_to_recipient

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def message
    case action
    when "favorite"
      "#{actor.name}さんがあなたの投稿にいいねしました"
    when "comment"
      "#{actor.name}さんがあなたの投稿にコメントしました"
    when "follow"
      "#{actor.name}さんがあなたをフォローしました"
    end
  end

  private

  def broadcast_to_recipient
    NotificationBroadcastJob.perform_later(self)
  end
end
```

```ruby
# app/models/tag.rb
class Tag < ApplicationRecord
  has_many :book_tags, dependent: :destroy
  has_many :books, through: :book_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 30 }

  scope :popular, -> { order(books_count: :desc).limit(20) }
end
```

```ruby
# app/models/book_tag.rb
class BookTag < ApplicationRecord
  belongs_to :book
  belongs_to :tag, counter_cache: :books_count

  validates :book_id, uniqueness: { scope: :tag_id }
end
```

---

## 6. コントローラー設計

### 6.1 ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, except: [:top, :about]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Devise リダイレクト設定
  def after_sign_in_path_for(resource)
    books_path
  end

  def after_sign_out_path_for(resource)
    root_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username, :introduction, :avatar])
  end

  private

  def user_not_authorized
    flash[:alert] = "この操作を行う権限がありません"
    redirect_back(fallback_location: root_path)
  end
end
```

### 6.2 BooksController

```ruby
# app/controllers/books_controller.rb
class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  before_action :authorize_book, only: [:edit, :update, :destroy]

  def index
    @books = Book.with_associations
                 .recent
                 .page(params[:page])
                 .per(12)
    @book = Book.new
  end

  def show
    @book_comment = BookComment.new
    @book_comments = @book.book_comments
                          .includes(:user)
                          .order(created_at: :desc)
    @user_rating = @book.rating_by(current_user)
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)

    respond_to do |format|
      if @book.save
        format.turbo_stream { flash.now[:notice] = "投稿しました" }
        format.html { redirect_to @book, notice: "投稿しました" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "book_form",
            partial: "books/form",
            locals: { book: @book }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    respond_to do |format|
      if @book.update(book_params)
        format.turbo_stream { flash.now[:notice] = "更新しました" }
        format.html { redirect_to @book, notice: "更新しました" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "book_form",
            partial: "books/form",
            locals: { book: @book }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @book.destroy

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "削除しました" }
      format.html { redirect_to books_path, notice: "削除しました" }
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def authorize_book
    authorize @book
  end

  def book_params
    params.require(:book).permit(:title, :body, :image, :tag_list)
  end
end
```

### 6.3 FavoritesController

```ruby
# app/controllers/favorites_controller.rb
class FavoritesController < ApplicationController
  before_action :set_book

  def create
    @favorite = current_user.favorites.build(book: @book)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream
        format.html { redirect_back(fallback_location: @book) }
      else
        format.html { redirect_back(fallback_location: @book, alert: "いいねできませんでした") }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(book: @book)
    @favorite&.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @book) }
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end
end
```

### 6.4 RelationshipsController

```ruby
# app/controllers/relationships_controller.rb
class RelationshipsController < ApplicationController
  before_action :set_user

  def create
    current_user.follow(@user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @user) }
    end
  end

  def destroy
    current_user.unfollow(@user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: @user) }
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
```

### 6.5 NotificationsController

```ruby
# app/controllers/notifications_controller.rb
class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .page(params[:page])
                                 .per(20)
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: notifications_path) }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notifications_list",
          partial: "notifications/list",
          locals: { notifications: current_user.notifications.recent.limit(20) }
        )
      end
      format.html { redirect_to notifications_path, notice: "すべて既読にしました" }
    end
  end
end
```

### 6.6 SearchController

```ruby
# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    @query = params[:q]
    return if @query.blank?

    case params[:type]
    when "users"
      @users = User.search_by_name(@query).page(params[:page]).per(20)
    else
      @books = Book.search_content(@query)
                   .with_associations
                   .page(params[:page])
                   .per(12)
    end
  end
end
```

### 6.7 OmniAuth Callbacks

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb
module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_auth("Google")
    end

    def github
      handle_auth("GitHub")
    end

    def failure
      redirect_to root_path, alert: "認証に失敗しました"
    end

    private

    def handle_auth(provider)
      @user = User.from_omniauth(request.env["omniauth.auth"])

      if @user.persisted?
        flash[:notice] = "#{provider}アカウントでログインしました"
        sign_in_and_redirect @user, event: :authentication
      else
        session["devise.#{provider.downcase}_data"] = request.env["omniauth.auth"].except(:extra)
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
    end
  end
end
```

---

## 7. ビュー設計

### 7.1 レイアウト

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="ja" class="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= content_for(:title) || "Bookers" %></title>
  <meta name="description" content="<%= content_for(:description) || "読書感想共有プラットフォーム" %>">

  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>

  <%= stylesheet_link_tag "tailwind", "inter-font", "data-turbo-track": "reload" %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>

<body class="bg-primary text-primary min-h-screen flex flex-col"
      data-controller="dark-mode">

  <%= render "layouts/navbar" %>

  <main class="flex-1 container mx-auto px-4 py-6">
    <%= render "layouts/flash" %>
    <%= yield %>
  </main>

  <%= render "layouts/footer" %>

  <%# Toast通知コンテナ %>
  <div id="toast-container"
       class="fixed bottom-4 right-4 z-50 space-y-2"
       data-controller="toast">
  </div>
</body>
</html>
```

### 7.2 ナビゲーションバー

```erb
<%# app/views/layouts/_navbar.html.erb %>
<nav class="bg-secondary border-b border-border sticky top-0 z-40">
  <div class="container mx-auto px-4">
    <div class="flex items-center justify-between h-16">

      <%# ロゴ %>
      <%= link_to root_path, class: "flex items-center space-x-2" do %>
        <%= image_tag "logo.svg", alt: "Bookers", class: "h-8 w-8" %>
        <span class="text-xl font-bold text-accent-primary">Bookers</span>
      <% end %>

      <%# 検索バー %>
      <div class="hidden md:flex flex-1 max-w-md mx-8">
        <%= form_with url: search_path, method: :get, class: "relative", data: { controller: "search" } do |f| %>
          <input type="text"
                 name="q"
                 placeholder="本やユーザーを検索..."
                 value="<%= params[:q] %>"
                 class="w-full bg-tertiary border border-border rounded-lg pl-10 pr-4 py-2
                        text-sm text-primary placeholder-muted
                        focus:outline-none focus:ring-2 focus:ring-accent-primary focus:border-transparent">
          <svg class="absolute left-3 top-2.5 h-5 w-5 text-muted" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        <% end %>
      </div>

      <%# ナビゲーションリンク %>
      <div class="flex items-center space-x-4">
        <% if user_signed_in? %>
          <%= link_to books_path, class: "nav-link" do %>
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          <% end %>

          <%= link_to users_path, class: "nav-link" do %>
            <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          <% end %>

          <%# 通知 %>
          <div class="relative" data-controller="dropdown">
            <button data-action="click->dropdown#toggle" class="nav-link relative">
              <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
              <% if current_user.unread_notifications_count > 0 %>
                <span class="absolute -top-1 -right-1 bg-accent-danger text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  <%= current_user.unread_notifications_count > 9 ? "9+" : current_user.unread_notifications_count %>
                </span>
              <% end %>
            </button>

            <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-80 bg-secondary rounded-lg shadow-lg border border-border">
              <%= turbo_frame_tag "notifications_dropdown" do %>
                <%= render "notifications/dropdown", notifications: current_user.notifications.recent.limit(5) %>
              <% end %>
            </div>
          </div>

          <%# ユーザーメニュー %>
          <div class="relative" data-controller="dropdown">
            <button data-action="click->dropdown#toggle" class="flex items-center space-x-2">
              <%= image_tag current_user.avatar_url(size: :small), class: "h-8 w-8 rounded-full object-cover" %>
            </button>

            <div data-dropdown-target="menu" class="hidden absolute right-0 mt-2 w-48 bg-secondary rounded-lg shadow-lg border border-border py-1">
              <%= link_to "マイページ", user_path(current_user), class: "dropdown-item" %>
              <%= link_to "ブックマーク", bookmarks_path, class: "dropdown-item" %>
              <%= link_to "設定", edit_user_registration_path, class: "dropdown-item" %>
              <hr class="border-border my-1">
              <%= button_to "ログアウト", destroy_user_session_path, method: :delete, class: "dropdown-item w-full text-left" %>
            </div>
          </div>

        <% else %>
          <%= link_to "ログイン", new_user_session_path, class: "btn-secondary" %>
          <%= link_to "新規登録", new_user_registration_path, class: "btn-primary" %>
        <% end %>

        <%# ダークモード切替 %>
        <button data-action="click->dark-mode#toggle" class="nav-link">
          <svg data-dark-mode-target="darkIcon" class="h-6 w-6 hidden" fill="currentColor" viewBox="0 0 20 20">
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
          </svg>
          <svg data-dark-mode-target="lightIcon" class="h-6 w-6" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    </div>
  </div>
</nav>
```

### 7.3 Turbo Stream テンプレート

```erb
<%# app/views/favorites/create.turbo_stream.erb %>
<%= turbo_stream.replace "favorite_button_#{@book.id}" do %>
  <%= render "books/favorite_button", book: @book %>
<% end %>

<%= turbo_stream.replace "favorites_count_#{@book.id}" do %>
  <span id="favorites_count_<%= @book.id %>" class="text-sm text-secondary">
    <%= @book.favorites_count %>
  </span>
<% end %>
```

```erb
<%# app/views/book_comments/create.turbo_stream.erb %>
<%= turbo_stream.prepend "comments_list" do %>
  <%= render "book_comments/comment", comment: @book_comment %>
<% end %>

<%= turbo_stream.replace "comment_form" do %>
  <%= render "book_comments/form", book: @book, book_comment: BookComment.new %>
<% end %>

<%= turbo_stream.replace "comments_count_#{@book.id}" do %>
  <span id="comments_count_<%= @book.id %>" class="text-sm text-secondary">
    <%= @book.book_comments_count %>
  </span>
<% end %>
```

---

## 8. フロントエンド設計

### 8.1 Tailwind CSS設定

```javascript
// config/tailwind.config.js
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*.{erb,rb}'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'Noto Sans JP', ...defaultTheme.fontFamily.sans],
        mono: ['JetBrains Mono', 'Fira Code', ...defaultTheme.fontFamily.mono],
      },
      colors: {
        // Background
        'primary': 'var(--color-bg-primary)',
        'secondary': 'var(--color-bg-secondary)',
        'tertiary': 'var(--color-bg-tertiary)',
        // Border
        'border': 'var(--color-border)',
        // Accent
        'accent': {
          'primary': 'var(--color-accent-primary)',
          'success': 'var(--color-accent-success)',
          'warning': 'var(--color-accent-warning)',
          'danger': 'var(--color-accent-danger)',
          'purple': 'var(--color-accent-purple)',
        }
      },
      textColor: {
        'primary': 'var(--color-text-primary)',
        'secondary': 'var(--color-text-secondary)',
        'muted': 'var(--color-text-muted)',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio'),
  ],
}
```

### 8.2 CSS変数定義

```css
/* app/assets/stylesheets/application.tailwind.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Light mode (デフォルト) */
    --color-bg-primary: #ffffff;
    --color-bg-secondary: #f6f8fa;
    --color-bg-tertiary: #eaeef2;
    --color-text-primary: #1f2328;
    --color-text-secondary: #656d76;
    --color-text-muted: #8c959f;
    --color-border: #d0d7de;
    --color-accent-primary: #0969da;
    --color-accent-success: #1a7f37;
    --color-accent-warning: #9a6700;
    --color-accent-danger: #cf222e;
    --color-accent-purple: #8250df;
  }

  .dark {
    /* Dark mode */
    --color-bg-primary: #0d1117;
    --color-bg-secondary: #161b22;
    --color-bg-tertiary: #21262d;
    --color-text-primary: #e6edf3;
    --color-text-secondary: #8b949e;
    --color-text-muted: #6e7681;
    --color-border: #30363d;
    --color-accent-primary: #58a6ff;
    --color-accent-success: #3fb950;
    --color-accent-warning: #d29922;
    --color-accent-danger: #f85149;
    --color-accent-purple: #a371f7;
  }
}

@layer components {
  /* ボタン */
  .btn-primary {
    @apply inline-flex items-center justify-center px-4 py-2
           bg-accent-primary text-white font-medium rounded-lg
           hover:opacity-90 focus:outline-none focus:ring-2
           focus:ring-accent-primary focus:ring-offset-2
           transition-all duration-200;
  }

  .btn-secondary {
    @apply inline-flex items-center justify-center px-4 py-2
           bg-tertiary text-primary font-medium rounded-lg
           border border-border
           hover:bg-secondary focus:outline-none focus:ring-2
           focus:ring-accent-primary focus:ring-offset-2
           transition-all duration-200;
  }

  .btn-danger {
    @apply inline-flex items-center justify-center px-4 py-2
           bg-accent-danger text-white font-medium rounded-lg
           hover:opacity-90 focus:outline-none focus:ring-2
           focus:ring-accent-danger focus:ring-offset-2
           transition-all duration-200;
  }

  /* カード */
  .card {
    @apply bg-secondary rounded-lg border border-border
           shadow-sm hover:shadow-md transition-shadow duration-200;
  }

  /* ナビゲーションリンク */
  .nav-link {
    @apply text-secondary hover:text-primary
           transition-colors duration-200 p-2 rounded-lg
           hover:bg-tertiary;
  }

  /* ドロップダウンアイテム */
  .dropdown-item {
    @apply block px-4 py-2 text-sm text-secondary
           hover:bg-tertiary hover:text-primary
           transition-colors duration-200;
  }

  /* フォーム入力 */
  .form-input {
    @apply w-full bg-tertiary border border-border rounded-lg
           px-4 py-2 text-primary placeholder-muted
           focus:outline-none focus:ring-2 focus:ring-accent-primary
           focus:border-transparent transition-all duration-200;
  }

  .form-textarea {
    @apply form-input resize-none;
  }

  .form-label {
    @apply block text-sm font-medium text-primary mb-1;
  }

  .form-error {
    @apply text-sm text-accent-danger mt-1;
  }
}
```

### 8.3 Stimulus Controllers

#### Dark Mode Controller

```javascript
// app/javascript/controllers/dark_mode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["darkIcon", "lightIcon"]

  connect() {
    this.applyTheme(this.currentTheme)
  }

  toggle() {
    const newTheme = this.currentTheme === "dark" ? "light" : "dark"
    localStorage.setItem("theme", newTheme)
    this.applyTheme(newTheme)
  }

  get currentTheme() {
    return localStorage.getItem("theme") ||
      (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  }

  applyTheme(theme) {
    document.documentElement.classList.toggle("dark", theme === "dark")

    if (this.hasDarkIconTarget && this.hasLightIconTarget) {
      this.darkIconTarget.classList.toggle("hidden", theme !== "dark")
      this.lightIconTarget.classList.toggle("hidden", theme === "dark")
    }
  }
}
```

#### Rating Controller

```javascript
// app/javascript/controllers/rating_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]
  static values = {
    current: Number,
    url: String
  }

  connect() {
    this.highlightStars(this.currentValue)
  }

  hover(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.highlightStars(rating)
  }

  leave() {
    this.highlightStars(this.currentValue)
  }

  select(event) {
    const rating = parseInt(event.currentTarget.dataset.rating)
    this.currentValue = rating
    this.inputTarget.value = rating
    this.highlightStars(rating)

    // Turbo経由でサーバーに送信
    this.element.requestSubmit()
  }

  highlightStars(rating) {
    this.starTargets.forEach((star, index) => {
      const starRating = index + 1
      star.classList.toggle("text-yellow-400", starRating <= rating)
      star.classList.toggle("text-gray-400", starRating > rating)
    })
  }
}
```

#### Infinite Scroll Controller

```javascript
// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { loading: Boolean }

  connect() {
    this.createObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createObserver() {
    if (!this.hasPaginationTarget) return

    this.observer = new IntersectionObserver(
      entries => this.handleIntersection(entries),
      { rootMargin: "100px" }
    )

    this.observer.observe(this.paginationTarget)
  }

  async handleIntersection(entries) {
    const entry = entries[0]

    if (!entry.isIntersecting || this.loadingValue) return

    const nextUrl = this.paginationTarget.querySelector("a[rel='next']")?.href
    if (!nextUrl) return

    this.loadingValue = true

    try {
      const response = await fetch(nextUrl, {
        headers: { Accept: "text/vnd.turbo-stream.html" }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } finally {
      this.loadingValue = false
    }
  }
}
```

#### Toast Controller

```javascript
// app/javascript/controllers/toast_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.show()
  }

  show() {
    this.element.classList.add("animate-slide-in")

    setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  dismiss() {
    this.element.classList.add("animate-slide-out")

    this.element.addEventListener("animationend", () => {
      this.element.remove()
    }, { once: true })
  }
}
```

---

## 9. 認証・認可設計

### 9.1 Devise設定

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.mailer_sender = 'noreply@bookers.example.com'

  require 'devise/orm/active_record'

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # OmniAuth設定
  config.omniauth :google_oauth2,
                  ENV['GOOGLE_CLIENT_ID'],
                  ENV['GOOGLE_CLIENT_SECRET'],
                  scope: 'email,profile'

  config.omniauth :github,
                  ENV['GITHUB_CLIENT_ID'],
                  ENV['GITHUB_CLIENT_SECRET'],
                  scope: 'user:email'
end
```

### 9.2 Punditポリシー

```ruby
# app/policies/book_policy.rb
class BookPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    user.present? && record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
```

```ruby
# app/policies/book_comment_policy.rb
class BookCommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    user.present? && record.user_id == user.id
  end
end
```

---

## 10. リアルタイム機能設計

### 10.1 Action Cable設定

```ruby
# config/cable.yml
development:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") %>
  channel_prefix: bookers_production
```

### 10.2 Notification Channel

```ruby
# app/channels/notification_channel.rb
class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end
end
```

### 10.3 Broadcast Job

```ruby
# app/jobs/notification_broadcast_job.rb
class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    NotificationChannel.broadcast_to(
      notification.recipient,
      turbo_stream.prepend(
        "notifications_list",
        partial: "notifications/notification",
        locals: { notification: notification }
      )
    )
  end

  private

  def turbo_stream
    Turbo::Streams::TagBuilder.new(view_context)
  end

  def view_context
    ApplicationController.new.view_context
  end
end
```

---

## 11. 検索機能設計

### 11.1 pg_search設定

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
  end
end
```

### 11.2 Search Service

```ruby
# app/services/books/search_service.rb
module Books
  class SearchService
    def initialize(query:, page: 1, per_page: 12)
      @query = query
      @page = page
      @per_page = per_page
    end

    def call
      return Book.none if @query.blank?

      Book.search_content(@query)
          .with_associations
          .page(@page)
          .per(@per_page)
    end
  end
end
```

---

## 12. テスト設計

### 12.1 RSpec設定

```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

### 12.2 Factory定義

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    introduction { "自己紹介文です" }

    trait :with_avatar do
      after(:build) do |user|
        user.avatar.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/avatar.png')),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end
    end
  end
end

# spec/factories/books.rb
FactoryBot.define do
  factory :book do
    association :user
    sequence(:title) { |n| "Book Title #{n}" }
    body { "これは本の感想です。とても面白かったです。" }

    trait :with_image do
      after(:build) do |book|
        book.image.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/book.png')),
          filename: 'book.png',
          content_type: 'image/png'
        )
      end
    end

    trait :with_ratings do
      after(:create) do |book|
        create_list(:rating, 3, book: book)
      end
    end
  end
end
```

---

## 13. デプロイ設計

### 13.1 本番環境構成

```yaml
# config/deploy.yml (Kamal用)
service: bookers2
image: username/bookers2

servers:
  web:
    hosts:
      - 192.168.1.1
    labels:
      traefik.http.routers.bookers2.rule: Host(`bookers.example.com`)

registry:
  username: username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - REDIS_URL

accessories:
  db:
    image: postgres:16
    host: 192.168.1.1
    port: 5432
    env:
      clear:
        POSTGRES_USER: bookers2
        POSTGRES_DB: bookers2_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7
    host: 192.168.1.1
    port: 6379
    directories:
      - data:/data
```

### 13.2 GitHub Actions CI/CD

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7
        ports:
          - 6379:6379

    env:
      RAILS_ENV: test
      DATABASE_URL: postgresql://postgres:postgres@localhost:5432/bookers2_test
      REDIS_URL: redis://localhost:6379/0

    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup Database
        run: |
          bin/rails db:create
          bin/rails db:schema:load

      - name: Build Assets
        run: bin/rails assets:precompile

      - name: Run Tests
        run: bundle exec rspec

      - name: Run Linter
        run: bundle exec rubocop

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true

      - name: Deploy with Kamal
        run: |
          gem install kamal
          kamal deploy
        env:
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.KAMAL_REGISTRY_PASSWORD }}
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
```

---

## 付録

### A. ルーティング一覧

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Devise
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  # Root
  root 'home#top'
  get 'about', to: 'home#about'

  # Books
  resources :books do
    resource :favorite, only: [:create, :destroy]
    resource :bookmark, only: [:create, :destroy]
    resources :book_comments, only: [:create, :destroy]
    resource :rating, only: [:create, :update]
  end

  # Users
  resources :users, only: [:index, :show, :edit, :update] do
    member do
      get :followers
      get :following
    end
    resource :relationship, only: [:create, :destroy]
  end

  # Bookmarks
  resources :bookmarks, only: [:index]

  # Notifications
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # Search
  get 'search', to: 'search#index'

  # Health check
  get 'up', to: 'rails/health#show', as: :rails_health_check
end
```

### B. 参考資料

- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [pg_search GitHub](https://github.com/Casecommons/pg_search)
- [Devise OmniAuth](https://github.com/heartcombo/devise/wiki/OmniAuth:-Overview)
- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html)

---

**文書管理**

| バージョン | 日付 | 変更内容 | 作成者 |
|-----------|------|----------|--------|
| 1.0 | 2026-02-11 | 初版作成 | Claude Code |
