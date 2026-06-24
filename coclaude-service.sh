#!/bin/bash
# ── ✦ coclaude 团队服务看守进程 ✦ ──
# systemd Type=simple 需要进程持续运行，此脚本等待 tmux session 结束

SESSION="coclaude-team"
WORKDIR="$HOME/localmodel"
PORT=42000
TOKEN="xiaog-team-2026"

cleanup() {
    tmux kill-session -t "$SESSION" 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT

# 如果已存在旧会话，先清理
tmux kill-session -t "$SESSION" 2>/dev/null
sleep 0.5

cd "$WORKDIR" || exit 1

# 在 detached tmux 中启动 coclaude
tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "小G"
tmux send-keys -t "$SESSION" "cd $WORKDIR && coclaude host --name \"小G\" --bind 0.0.0.0 --port $PORT --token \"$TOKEN\"" Enter

echo "coclaude 团队服务已启动 | port=$PORT | token=$TOKEN"

# 阻塞等待 tmux session 结束
while tmux has-session -t "$SESSION" 2>/dev/null; do
    sleep 5
done
echo "coclaude 团队服务已停止"
