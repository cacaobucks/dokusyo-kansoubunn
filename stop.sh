#!/bin/bash

# Bookers - 停止スクリプト
# =====================================

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

# バナー表示
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     📚 Bookers - 停止スクリプト      ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# スクリプトのディレクトリに移動
cd "$(dirname "$0")"

# PIDファイルからプロセスを停止
if [ -f "tmp/pids/server.pid" ]; then
    PID=$(cat tmp/pids/server.pid)
    log_info "Stopping server (PID: $PID)..."

    if kill -0 "$PID" 2>/dev/null; then
        kill -TERM "$PID"
        sleep 2

        # まだ動いている場合は強制終了
        if kill -0 "$PID" 2>/dev/null; then
            log_warn "Process still running, sending SIGKILL..."
            kill -9 "$PID" 2>/dev/null
        fi
    fi

    rm -f tmp/pids/server.pid
    log_success "Server stopped"
else
    log_info "PID file not found, searching for processes..."
fi

# Pumaプロセスを検索して停止
PUMA_PIDS=$(pgrep -f "puma.*3000" 2>/dev/null || true)
if [ -n "$PUMA_PIDS" ]; then
    log_info "Found Puma processes: $PUMA_PIDS"
    echo "$PUMA_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    # 残っているプロセスを強制終了
    pgrep -f "puma.*3000" | xargs kill -9 2>/dev/null || true
    log_success "Puma processes stopped"
fi

# Foremanプロセスを検索して停止
FOREMAN_PIDS=$(pgrep -f "foreman" 2>/dev/null || true)
if [ -n "$FOREMAN_PIDS" ]; then
    log_info "Found Foreman processes: $FOREMAN_PIDS"
    echo "$FOREMAN_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    pgrep -f "foreman" | xargs kill -9 2>/dev/null || true
    log_success "Foreman processes stopped"
fi

# Tailwindプロセスを停止
TAILWIND_PIDS=$(pgrep -f "tailwindcss" 2>/dev/null || true)
if [ -n "$TAILWIND_PIDS" ]; then
    log_info "Found Tailwind processes: $TAILWIND_PIDS"
    echo "$TAILWIND_PIDS" | xargs kill -TERM 2>/dev/null || true
    log_success "Tailwind processes stopped"
fi

# 最終確認
sleep 1
REMAINING=$(pgrep -f "puma.*3000" 2>/dev/null || true)
if [ -z "$REMAINING" ]; then
    echo ""
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║     ✅ サーバーが停止しました        ║"
    echo "  ╚══════════════════════════════════════╝"
    echo ""
else
    log_warn "Some processes may still be running: $REMAINING"
    echo "Try: kill -9 $REMAINING"
fi
