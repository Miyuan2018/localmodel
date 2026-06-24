#!/bin/bash
# ── ✦ 团队协作服务看守进程 ✦ ──
# 以"我"（主 session, DeepSeek）为中心启动 coclaude host
# 小G 和队友作为 guest 加入

SESSION="coclaude-team"
MAIN_DIR="$HOME/claude-workspace"
XIAOG_DIR="$HOME/localmodel"
PORT=42000
TOKEN="my-team-2026"

cleanup() {
    tmux kill-session -t "$SESSION" 2>/dev/null
    exit 0
}
trap cleanup SIGTERM SIGINT

# 清理旧会话
tmux kill-session -t "$SESSION" 2>/dev/null
sleep 0.5

# ── Step 1: 启动 host（我, DeepSeek） ──
tmux new-session -d -s "$SESSION" -c "$MAIN_DIR" -n "我-host"
tmux send-keys -t "$SESSION" "coclaude host --name \"我\" --bind 0.0.0.0 --port $PORT --token \"$TOKEN\"" Enter
echo "团队 host 已启动 (我 · DeepSeek) | port=$PORT"
sleep 3

# ── Step 2: 小G 自动加入 ──
JOIN_URL="ws://127.0.0.1:$PORT/s/$TOKEN"
tmux new-window -t "$SESSION" -c "$XIAOG_DIR" -n "小G-guest"
tmux send-keys -t "$SESSION:小G-guest" "coclaude join --name \"小G\" \"$JOIN_URL\"" Enter
echo "小G 已申请加入"
sleep 2
# 自动批准小G（第一个 join 请求）
tmux send-keys -t "$SESSION:我-host" "a" Enter
sleep 1

echo "══════════════════════════════════════════"
echo "  团队就绪"
echo "  Host:  我 (DeepSeek V4 Pro)"
echo "  成员:  小G (gemma/qwable)"
echo ""
echo "  队友加入:"
echo "  npm install -g coclaude"
echo "  coclaude join \"ws://$(hostname -I | awk '{print $1}'):$PORT/s/$TOKEN\""
echo "══════════════════════════════════════════"

# 阻塞等待
while tmux has-session -t "$SESSION" 2>/dev/null; do
    sleep 5
done
echo "团队服务已停止"
