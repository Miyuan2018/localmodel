#!/bin/bash
# ── ✦ /team 命令处理器 ✦ ──
DIR="$HOME/localmodel"

case "${1:-status}" in
  start)
    bash "$DIR/lobby-start.sh" start
    echo "加入: tmux attach -t lobby"
    ;;
  stop)
    tmux kill-session -t lobby 2>/dev/null
    ps aux | grep "[t]ask-notify" | awk '{print $2}' | xargs -r kill 2>/dev/null
    echo "团队空间已停止"
    ;;
  status)
    echo "🤖 小G:  $(tmux has-session -t xiaog 2>/dev/null && echo '✅' || echo '❌')  模型: $(cat $DIR/current-model 2>/dev/null)"
    echo "🏛️ 大厅: $(tmux has-session -t lobby 2>/dev/null && echo '✅' || echo '❌')"
    echo "📋 队列: $(ls $DIR/outbox/*.waiting 2>/dev/null | wc -l) 等待 / $(ls $DIR/outbox/*.md 2>/dev/null | wc -l) 完成"
    ;;
  task)
    shift
    bash "$DIR/task-submit.sh" "$*"
    ;;
  board)
    shift
    bash "$DIR/whiteboard-post.sh" "$*"
    ;;
  *)
    echo "用法: team {start|stop|status|task|board}"
    ;;
esac
