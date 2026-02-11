#!/bin/bash

# Bookers - 起動スクリプト
# =====================================

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# バナー表示
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     📚 Bookers - 起動スクリプト      ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# スクリプトのディレクトリに移動
cd "$(dirname "$0")"

# rbenvの確認と初期化
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init -)"
    log_success "rbenv detected"
else
    log_warn "rbenv not found. Using system Ruby."
fi

# Rubyバージョン確認
RUBY_VERSION=$(ruby -v 2>/dev/null || echo "not found")
log_info "Ruby version: $RUBY_VERSION"

# Bundlerの確認
if ! command -v bundle &> /dev/null; then
    log_warn "Bundler not found. Installing..."
    gem install bundler
fi

# 依存関係のインストール
log_info "Checking dependencies..."
if [ ! -f "Gemfile.lock" ] || [ "Gemfile" -nt "Gemfile.lock" ]; then
    log_info "Running bundle install..."
    bundle install
else
    bundle check || bundle install
fi
log_success "Dependencies OK"

# データベースの確認とセットアップ
log_info "Checking database..."
if [ ! -f "db/development.sqlite3" ]; then
    log_info "Creating database..."
    rails db:create
fi

# マイグレーションの実行
log_info "Running migrations..."
rails db:migrate 2>/dev/null || {
    log_warn "Migration failed. Running db:reset..."
    rails db:reset
}
log_success "Database OK"

# Tailwind CSSのビルド
log_info "Building Tailwind CSS..."
rails tailwindcss:build
log_success "Tailwind CSS built"

# 古いサーバープロセスのクリーンアップ
if [ -f "tmp/pids/server.pid" ]; then
    log_info "Cleaning up old server process..."
    rm -f tmp/pids/server.pid
    pkill -f "puma.*3000" 2>/dev/null || true
fi

# サーバー起動
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║        🚀 サーバーを起動中...        ║"
echo "  ║                                      ║"
echo "  ║    URL: http://localhost:3000        ║"
echo "  ║    停止: Ctrl + C                    ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

rails server -p 3000
