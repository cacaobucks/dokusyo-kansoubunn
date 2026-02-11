# 読書感想文 (dokusyo-kansoubunn)

読書体験を共有するソーシャルプラットフォーム

<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.2.2-red?style=for-the-badge&logo=ruby" alt="Ruby">
  <img src="https://img.shields.io/badge/Rails-7.1-red?style=for-the-badge&logo=rubyonrails" alt="Rails">
  <img src="https://img.shields.io/badge/Tailwind_CSS-3.x-38B2AC?style=for-the-badge&logo=tailwindcss" alt="Tailwind CSS">
  <img src="https://img.shields.io/badge/Hotwire-Turbo_&_Stimulus-yellow?style=for-the-badge" alt="Hotwire">
</p>

---

## 概要

読んだ本の感想を投稿し、他のユーザーと交流できるWebアプリケーションです。

## 機能

- 投稿機能（本の感想を投稿・編集・削除）
- 評価機能（5段階の星評価）
- いいね機能
- コメント機能
- ブックマーク機能
- タグ機能
- フォロー/フォロワー機能
- 通知機能
- 検索機能
- ダークモード対応
- レスポンシブデザイン

## 技術スタック

| 技術 | バージョン |
|------|-----------|
| Ruby | 3.2.2 |
| Rails | 7.1 |
| Tailwind CSS | 3.x |
| Hotwire | Turbo + Stimulus |
| SQLite3 | - |
| Devise | 4.9 |

## セットアップ

### クイックスタート（macOS）

```bash
# リポジトリをクローン
git clone https://github.com/cacaobucks/dokusyo-kansoubunn.git
cd dokusyo-kansoubunn

# セットアップ（Ruby, gems, DBを自動設定）
./setup.sh

# サーバーを起動
./start.sh
```

ブラウザで http://localhost:3000 にアクセス

### サーバーの停止

```bash
./stop.sh
```

### 必要要件

- macOS（Apple Silicon / Intel対応）
- Homebrew

### 手動セットアップ

```bash
# rbenvとRubyをインストール
brew install rbenv ruby-build
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
source ~/.zshrc
rbenv install 3.2.2
rbenv global 3.2.2

# アプリケーションのセットアップ
bundle install
rails db:create db:migrate
rails tailwindcss:build

# サーバー起動
bin/dev
```

## ディレクトリ構成

```
dokusyo-kansoubunn/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── views/
│   └── javascript/controllers/
├── config/
├── db/
└── docs/
```

## ライセンス

MIT License

## 作者

- [cacaobucks](https://github.com/cacaobucks)
