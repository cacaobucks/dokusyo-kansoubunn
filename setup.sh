#!/bin/bash

# Bookers - セットアップスクリプト
# =====================================
# macOS用の初期セットアップを行います

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
    exit 1
}

# バナー表示
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   📚 Bookers - セットアップ          ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# スクリプトのディレクトリに移動
cd "$(dirname "$0")"

# macOS確認
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_warn "This script is optimized for macOS"
fi

# ==========================================
# 1. Homebrew
# ==========================================
log_info "Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon Mac対応
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log_success "Homebrew is installed"
fi

# ==========================================
# 2. rbenv
# ==========================================
log_info "Checking rbenv..."
if ! command -v rbenv &> /dev/null; then
    log_info "Installing rbenv..."
    brew install rbenv ruby-build

    # シェル設定を追加
    if [[ -f ~/.zshrc ]]; then
        if ! grep -q 'rbenv init' ~/.zshrc; then
            echo '' >> ~/.zshrc
            echo '# rbenv' >> ~/.zshrc
            echo 'eval "$(rbenv init -)"' >> ~/.zshrc
        fi
    fi

    eval "$(rbenv init -)"
    log_success "rbenv installed"
else
    eval "$(rbenv init -)"
    log_success "rbenv is installed"
fi

# ==========================================
# 3. Ruby 3.2.2
# ==========================================
REQUIRED_RUBY="3.2.2"
log_info "Checking Ruby version..."

if ! rbenv versions | grep -q "$REQUIRED_RUBY"; then
    log_info "Installing Ruby $REQUIRED_RUBY (this may take a while)..."
    rbenv install "$REQUIRED_RUBY"
fi

rbenv local "$REQUIRED_RUBY"
rbenv global "$REQUIRED_RUBY"
eval "$(rbenv init -)"

CURRENT_RUBY=$(ruby -v | awk '{print $2}')
log_success "Ruby $CURRENT_RUBY is active"

# ==========================================
# 4. Bundler
# ==========================================
log_info "Checking Bundler..."
if ! gem list bundler -i > /dev/null 2>&1; then
    log_info "Installing Bundler..."
    gem install bundler
fi
log_success "Bundler is installed"

# ==========================================
# 5. Gems
# ==========================================
log_info "Installing gems..."
bundle install
log_success "Gems installed"

# ==========================================
# 6. Database
# ==========================================
log_info "Setting up database..."
rails db:create 2>/dev/null || true
rails db:migrate
log_success "Database ready"

# ==========================================
# 7. Tailwind CSS
# ==========================================
log_info "Building Tailwind CSS..."
rails tailwindcss:build
log_success "Tailwind CSS built"

# ==========================================
# 完了
# ==========================================
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     ✅ セットアップ完了！            ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║                                      ║"
echo "  ║  サーバーを起動するには:             ║"
echo "  ║    ./start.sh                        ║"
echo "  ║                                      ║"
echo "  ║  または:                             ║"
echo "  ║    rails server                      ║"
echo "  ║                                      ║"
echo "  ║  URL: http://localhost:3000          ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# 新しいターミナルが必要な場合の警告
if [[ $(which ruby) == "/usr/bin/ruby" ]]; then
    log_warn "Please open a new terminal window for rbenv to take effect"
fi
