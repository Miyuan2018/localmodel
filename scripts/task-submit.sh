#!/bin/bash
# ── ✦ 提交任务给小G ✦ ──
# 用法: task-submit.sh "任务描述"
# 返回任务 ID，结果出现在 ~/localmodel/outbox/<id>.md

# 默认发到大厅的小G 窗口
TARGET="lobby:小G"
OUTBOX="$HOME/localmodel/outbox"

# 如果第一个参数是 session:window 格式，用它的
if echo "${1:-}" | grep -q ":" && tmux has-session -t "${1%%:*}" 2>/dev/null; then
    TARGET="$1"
    shift
fi

task="$*"
mkdir -p "$OUTBOX"
if [ -z "$task" ]; then
    echo "用法: task-submit.sh [tmux-session] 任务描述"
    echo "默认发到 lobby:小G"
    exit 0
fi

# 生成任务 ID
TASK_ID="$(date '+%Y%m%d-%H%M%S')-$(whoami)"

# 创建等待标记
touch "$OUTBOX/${TASK_ID}.waiting"

# 发消息到小G
tmux send-keys -t "$TARGET" -l "$task"
sleep 0.2
tmux send-keys -t "$TARGET" Enter

echo "✅ 已发送 (ID: $TASK_ID)"
echo ""
echo "   异步查:  bash ~/localmodel/task-check.sh $TASK_ID"
echo "   围观:    tmux attach -t ${TARGET%%:*}"
