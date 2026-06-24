#!/bin/bash
# ── ✦ 添加团队成员 ✦ ──
SESSION="lobby"
DIR="$HOME/localmodel"
name="${1:-新人}"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ 大厅未启动: bash $DIR/lobby-start.sh start"
    exit 1
fi

# 新建窗口
tmux new-window -t "$SESSION" -c "$DIR" -n "👤$name"
tmux send-keys "clear; echo ''; echo '  👤 $name'; echo ''; cd $DIR && claude" Enter

echo "✅ $name 已加入 (Ctrl+B 选择窗口)"
echo "   tmux attach -t lobby"
