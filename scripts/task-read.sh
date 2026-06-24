#!/bin/bash
# ── ✦ 读取小G 最新回复 ✦ ──
# 用法: task-read.sh          → 最近对话
#       task-read.sh 10        → 最近 10 行
#       task-read.sh -f        → 实时跟踪

LINES="${1:-20}"

if [ "$1" = "-f" ]; then
    echo "📺 实时跟踪小G 窗口 (Ctrl+C 退出)..."
    while true; do
        clear
        echo "═══════════════════════════════════════"
        echo "  小G 最新对话  $(date '+%H:%M:%S')"
        echo "═══════════════════════════════════════"
        tmux capture-pane -t lobby:小G -p -S -40 | tail -30
        sleep 3
    done
    exit 0
fi

echo "═══════════════════════════════════════"
echo "  小G 最近 ${LINES} 行"
echo "═══════════════════════════════════════"
tmux capture-pane -t lobby:小G -p -S -"$LINES"
