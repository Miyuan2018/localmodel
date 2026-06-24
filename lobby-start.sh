#!/bin/bash
# ── ✦ tmux 团队大厅 ✦ ──
# 窗口 0=小G  1=任务面板  2=白板  3=Shell

SESSION="lobby"
WORKDIR="$HOME/localmodel"

case "${1:-start}" in
  start)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅已在运行  加入: tmux attach -t $SESSION"
      exit 0
    fi

    cd "$WORKDIR" || exit 1

    # 窗口 0 = 小G Claude
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "小G"
    tmux send-keys -t "$SESSION:小G" "cd $WORKDIR && claude" Enter

    # 后台启动回复通知器
    ps aux | grep "[t]ask-notify.sh" | awk '{print $2}' | xargs -r kill 2>/dev/null || true
    nohup bash "$WORKDIR/task-notify.sh" &>/dev/null &
    sleep 1

    # 窗口 1 = 任务面板
    tmux new-window -t "$SESSION" -c "$WORKDIR" -n "任务"
    tmux send-keys -t "$SESSION:任务" \
      "clear; echo '📋 任务面板'; echo ''; echo '提交: bash task-submit.sh \"任务\"'; echo '查结果: bash task-check.sh'; echo ''; echo '───'; watch -n 5 'echo \"📥 等待:\"; ls outbox/*.waiting 2>/dev/null | sed \"s|.*/||;s/.waiting//\" || echo \"  无\"; echo \"\"; echo \"📤 完成:\"; ls -t outbox/*.md 2>/dev/null | head -5 | sed \"s|.*/||;s/.md//\" || echo \"  无\"'" Enter

    # 窗口 2 = 白板（实时刷新）
    tmux new-window -t "$SESSION" -c "$WORKDIR" -n "白板"
    tmux send-keys -t "$SESSION:白板" \
      "watch -n 3 'clear; echo \"📝 团队白板 — 自动刷新 | 编辑: vim whiteboard.md\"; echo \"\"; cat whiteboard.md 2>/dev/null'" Enter

    # 窗口 3 = Shell
    tmux new-window -t "$SESSION" -c "$HOME" -n "Shell"

    tmux select-window -t "$SESSION:小G"

    echo "══════════════════════════════════════════"
    echo "  团队大厅已启动  加入: tmux attach -t $SESSION"
    echo "  窗口: Ctrl+B 0=小G  1=任务  2=白板  3=Shell"
    echo "══════════════════════════════════════════"
    ;;

  attach)
    exec tmux attach -t "$SESSION" 2>/dev/null || echo "加入: tmux attach -t $SESSION"
    ;;

  stop)  tmux kill-session -t "$SESSION" 2>/dev/null; echo "大厅已关闭" ;;
  status)
    tmux has-session -t "$SESSION" 2>/dev/null && echo "在线 ✅" || echo "离线 ❌"
    ;;
  *) echo "用法: $0 {start|attach|stop|status}" ;;
esac
