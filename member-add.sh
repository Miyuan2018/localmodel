#!/bin/bash
# ── ✦ 添加团队成员 ✦ ──
# 用法: member-add.sh <名字>
#       member-add.sh Bob
#       member-add.sh Alice

SESSION="lobby"
DIR="$HOME/localmodel"
name="${1:-新人}"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "❌ 大厅未启动，先执行: bash ~/localmodel/lobby-start.sh start"
    exit 1
fi

# 找到最右边的 pane（x 坐标最大的那个）
rightmost=$(tmux list-panes -t "$SESSION:大厅" -F '#{pane_index} #{pane_left}' | sort -k2 -n | tail -1 | awk '{print $1}')

# 在它右边 split 新栏
tmux split-window -h -t "$SESSION:大厅.$rightmost" -c "$DIR"
new=$(tmux list-panes -t "$SESSION:大厅" -F '#{pane_index}' | tail -1)

# 可选模型参数
model="${2:-}"
if [ -n "$model" ]; then
    tmux send-keys -t "$SESSION:大厅.$new" \
      "echo '👤 $name ($model)'; echo ''; cd $DIR && ANTHROPIC_MODEL=$model claude" Enter
else
    tmux send-keys -t "$SESSION:大厅.$new" \
      "echo '👤 $name'; echo ''; cd $DIR && claude" Enter
fi

echo "✅ $name 已加入大厅 (pane $new)"
echo "   tmux attach -t lobby"
