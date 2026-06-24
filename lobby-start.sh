#!/bin/bash
# ── ✦ tmux 团队大厅 ✦ ──
# 窗口 0 = 小G 的 Claude（实时可见）
# 窗口 1 = 任务提交 + 状态
# 窗口 2 = 自由 Shell

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

    # 窗口 0 = 小G Claude
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "小G"
    tmux send-keys -t "$SESSION:小G" "cd $WORKDIR && claude" Enter

    # 后台启动回复通知器
    pkill -f "task-notify.sh" 2>/dev/null || true
    nohup bash "$WORKDIR/task-notify.sh" &>/dev/null &
    sleep 1

    # 窗口 1 = 任务状态
    tmux new-window -t "$SESSION" -c "$WORKDIR" -n "任务"
    tmux send-keys -t "$SESSION:任务" "clear; echo '📋 任务面板'; echo ''; echo '提交:  bash ~/localmodel/task-submit.sh \"任务\"'; echo '查结果: bash ~/localmodel/task-check.sh'; echo '围观:   tmux attach -t lobby'; echo ''; echo '─────────────────────────────'; watch -n 5 'echo \"📥 等待中:\"; ls ~/localmodel/outbox/*.waiting 2>/dev/null | sed \"s|.*/||;s/.waiting//\" || echo \"  无\"; echo \"\"; echo \"📤 已完成:\"; ls -t ~/localmodel/outbox/*.md 2>/dev/null | head -5 | sed \"s|.*/||;s/.md//\" || echo \"  无\"'" Enter

    # 窗口 2 = 自由 Shell
    tmux new-window -t "$SESSION" -c "$HOME" -n "Shell"

    # 默认显示小G
    tmux select-window -t "$SESSION:小G"

    echo "══════════════════════════════════════════"
    echo "  团队大厅已启动"
    echo "  加入:  tmux attach -t $SESSION"
    echo "  窗口:  Ctrl+B 0=小G  1=任务  2=Shell"
    echo "══════════════════════════════════════════"
    ;;

  attach)
    [ -n "${DISPLAY:-}" ] && xterm -e "tmux attach -t $SESSION" 2>/dev/null &
    exec tmux attach -t "$SESSION" 2>/dev/null || echo "加入: tmux attach -t $SESSION"
    ;;

  stop)  tmux kill-session -t "$SESSION" 2>/dev/null; echo "大厅已关闭" ;;
  status)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅在线 ✅  加入: tmux attach -t $SESSION"
    else
      echo "大厅离线 ❌"
    fi ;;
  *) echo "用法: $0 {start|attach|stop|status}" ;;
esac
