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

    # 窗口 0 = 小G Claude（实时可见）
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "小G"
    tmux send-keys -t "$SESSION:小G" "cd $WORKDIR && claude" Enter

    # 窗口 1 = 任务提交 + 状态
    tmux new-window -t "$SESSION" -c "$WORKDIR" -n "任务"
    tmux send-keys -t "$SESSION:任务" "clear; echo '📋 给小G 派活 — 直接在这里打字，然后切回窗口0看他干活'; echo ''; echo '─────────────────────────────────'; echo '提交方式1: 在这里打任务描述，然后按 Enter'; echo '提交方式2: bash ~/localmodel/task-submit.sh \"任务描述\"'; echo ''" Enter

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
