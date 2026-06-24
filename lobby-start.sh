#!/bin/bash
# ── ✦ tmux 团队大厅 ✦ ──
# 共享 tmux session，团队成员 attach 后可围观小G + 任务队列
# 用法: lobby-start.sh          启动大厅
#       lobby-start.sh attach   进入大厅

SESSION="lobby"
WORKDIR="$HOME/localmodel"

case "${1:-start}" in
  start)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅已在运行"
      echo "加入: tmux attach -t $SESSION"
      exit 0
    fi

    cd "$WORKDIR" || exit 1

    # 创建 session，第一个窗口 = 小G
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "小G"
    tmux send-keys -t "$SESSION:小G" "cd $WORKDIR && claude" Enter

    # 窗口2 = 任务队列
    tmux new-window -t "$SESSION" -c "$WORKDIR" -n "任务队列"
    tmux send-keys -t "$SESSION:任务队列" "echo '📋 任务队列监控'; echo '收件箱:'; ls -la $WORKDIR/inbox/ 2>/dev/null | tail -5; echo ''; echo '发件箱:'; ls -la $WORKDIR/outbox/ 2>/dev/null | tail -5; echo ''; echo '提交任务: bash ~/localmodel/task-submit.sh \"任务描述\"'; echo '───'; tail -f $WORKDIR/queue.log 2>/dev/null || echo '队列未启动 (bash ~/localmodel/queue-watch.sh &)'" Enter

    # 窗口3 = 自由 shell
    tmux new-window -t "$SESSION" -c "$HOME" -n "shell"
    tmux send-keys -t "$SESSION:shell" "echo '🟢 团队大厅 Shell | 小G 在窗口 1 | 任务队列在窗口 2'; echo ''" Enter

    # 切回小G 窗口
    tmux select-window -t "$SESSION:小G"

    echo "══════════════════════════════════════════"
    echo "  团队大厅已启动"
    echo "  加入:  tmux attach -t $SESSION"
    echo ""
    echo "  窗口:  Ctrl+B 0=小G  1=任务队列  2=Shell"
    echo "══════════════════════════════════════════"
    ;;

  attach)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      exec tmux attach -t "$SESSION"
    else
      echo "大厅未启动，先执行: $0 start"
    fi
    ;;

  stop)
    tmux kill-session -t "$SESSION" 2>/dev/null
    echo "大厅已关闭"
    ;;

  status)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅在线 ✅  (session: $SESSION)"
      echo "连接数: $(tmux list-clients -t $SESSION 2>/dev/null | wc -l)"
      tmux list-windows -t "$SESSION" 2>/dev/null
    else
      echo "大厅离线 ❌"
    fi
    ;;

  *)
    echo "用法: $0 {start|attach|stop|status}"
    ;;
esac
