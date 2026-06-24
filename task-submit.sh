#!/bin/bash
# ── ✦ 提交任务给小G ✦ ──
# 直接打字进小G 的 tmux 窗口，所有旁观者都能看到

TARGET="${1:-lobby:小G}"
shift 2>/dev/null || true
task="$*"

if [ -z "$task" ]; then
    echo "用法: task-submit.sh [tmux-window] 任务描述"
    echo "默认发到 lobby:小G"
    echo ""
    echo "示例:"
    echo "  task-submit.sh \"审查 auth.py\""
    echo "  task-submit.sh xiaog \"切模型\"         # 发到 xiaog session"
    exit 0
fi

if ! tmux has-session -t "${TARGET%%:*}" 2>/dev/null; then
    echo "❌ tmux session 不在线: ${TARGET%%:*}"
    echo "   先启动: bash ~/localmodel/lobby-start.sh start"
    exit 1
fi

# 发消息到小G
tmux send-keys -t "$TARGET" -l "$task"
sleep 0.2
tmux send-keys -t "$TARGET" Enter

echo "✅ 已发送给小G: $task"
echo "   等回复:  bash ~/localmodel/task-read.sh"
echo "   实时看:  bash ~/localmodel/task-read.sh -f"
echo "   旁观:    tmux attach -t ${TARGET%%:*}"
