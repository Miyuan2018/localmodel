#!/bin/bash
# ── ✦ 团队大厅 ✦ ──
# 每人独立窗口，一目了然

SESSION="lobby"
DIR="$HOME/localmodel"

case "${1:-start}" in
  start)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅已在运行  tmux attach -t $SESSION"
      exit 0
    fi

    cd "$DIR" || exit 1

    # 显示窗口列表的状态栏
    tmux new-session -d -s "$SESSION" -c "$DIR" -n "📝白板+任务"
    tmux set-option -t "$SESSION" -g status on 2>/dev/null
    tmux set-option -t "$SESSION" -g status-position top 2>/dev/null

    # ── 窗口0: 白板(上) + 任务(下) ──
    tmux send-keys "watch -n 3 'clear; echo \"\"; echo \"  📝 团队白板  \$(date +%H:%M)\"; echo \"  ─────────────────────\"; cat $DIR/whiteboard.md 2>/dev/null'" Enter
    tmux split-window -v -c "$DIR"
    tmux send-keys "watch -n 5 'clear; echo \"\"; echo \"  📋 任务面板  \$(date +%H:%M)\"; echo \"  ─────────────────────\"; echo \"\"; echo \"  📥 等待:\"; ls $DIR/outbox/*.waiting 2>/dev/null | sed \"s|.*/||;s/.waiting//\" || echo \"    无\"; echo \"\"; echo \"  📤 完成:\"; ls -t $DIR/outbox/*.md 2>/dev/null | head -3 | sed \"s|.*/||;s/.md//\" || echo \"    无\"'" Enter

    # ── 窗口1: 我 ──
    tmux new-window -t "$SESSION" -c "$HOME" -n "👤我"
    tmux send-keys "clear; echo ''; echo '  👤 我'; echo ''; cd $HOME && claude" Enter

    # ── 窗口2: 小G ──
    tmux new-window -t "$SESSION" -c "$DIR" -n "🤖小G"
    tmux send-keys "clear; echo ''; echo '  🤖 小G · gemma'; echo ''; cd $DIR && claude" Enter

    tmux select-window -t "$SESSION:📝白板+任务"

    # 通知器
    ps aux | grep "[t]ask-notify.sh" | awk '{print $2}' | xargs -r kill 2>/dev/null || true
    nohup bash "$DIR/task-notify.sh" &>/dev/null &
    sleep 1

    echo "══════════════════════════════════════════"
    echo "  团队大厅  tmux attach -t lobby"
    echo "  切换:     Ctrl+B 0=白板 1=我 2=小G ..."
    echo "  状态栏:   顶部显示所有窗口"
    echo "  加人:     bash $DIR/member-add.sh <名字>"
    echo "══════════════════════════════════════════"
    ;;

  attach) exec tmux attach -t "$SESSION" 2>/dev/null || echo "tmux attach -t $SESSION" ;;
  stop)   tmux kill-session -t "$SESSION" 2>/dev/null; echo "已关闭" ;;
  status) tmux has-session -t "$SESSION" 2>/dev/null && echo "在线 ✅" || echo "离线 ❌" ;;
  *) echo "用法: $0 {start|attach|stop|status}" ;;
esac
