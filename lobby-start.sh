#!/bin/bash
# ── ✦ 团队大厅 · 动态多栏布局 ✦ ──
#
#  ┌──────────┬──────────┬──────────┬──────────┐
#  │          │          │          │          │
#  │  白板    │   小G    │   Bob    │  Alice   │
#  │          │  Claude  │  Claude  │  Claude  │
#  ├──────────┤          │          │          │
#  │  任务    │          │          │          │
#  └──────────┴──────────┴──────────┴──────────┘
#
#  左栏固定（白板+任务），右栏动态（团队成员 Claude）

SESSION="lobby"
DIR="$HOME/localmodel"

add_member_pane() {
    local name="$1"
    # 找到最右边的 pane，在其右边 split
    local last_pane
    last_pane=$(tmux list-panes -t "$SESSION:大厅" -F '#{pane_index}' | tail -1)
    tmux split-window -h -t "$SESSION:大厅.$last_pane" -c "$DIR"
    local new_pane
    new_pane=$(tmux list-panes -t "$SESSION:大厅" -F '#{pane_index}' | tail -1)
    tmux send-keys -t "$SESSION:大厅.$new_pane" "echo '👤 $name'; echo ''; cd $DIR && claude" Enter
    # 重新均匀分配所有右栏宽度
    tmux select-layout -t "$SESSION:大厅" tiled 2>/dev/null || true
    echo "✅ $name 已加入 (pane $new_pane)"
}

case "${1:-start}" in
  start)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "大厅已在运行  tmux attach -t $SESSION"
      exit 0
    fi

    cd "$DIR" || exit 1

    # ── 创建基础 session ──
    tmux new-session -d -s "$SESSION" -c "$DIR" -n "大厅"

    # ── 左栏上: 白板 ──
    tmux send-keys -t "$SESSION:大厅" \
      "watch -n 3 'clear; echo \"📝 团队白板  \$(date +%H:%M:%S)\"; echo \"\"; cat $DIR/whiteboard.md 2>/dev/null; echo \"\"; echo \"─── vim whiteboard.md ───\"'" Enter

    # ── 左栏下: 任务面板 ──
    tmux split-window -v -t "$SESSION:大厅.0" -c "$DIR"
    tmux send-keys -t "$SESSION:大厅.1" \
      "watch -n 5 'clear; echo \"📋 任务面板  \$(date +%H:%M:%S)\"; echo \"\"; echo \"📥 等待:\"; ls $DIR/outbox/*.waiting 2>/dev/null | sed \"s|.*/||;s/.waiting//\" || echo \"  无\"; echo \"\"; echo \"📤 完成:\"; ls -t $DIR/outbox/*.md 2>/dev/null | head -5 | sed \"s|.*/||;s/.md//\" || echo \"  无\"'" Enter

    # 调整左栏宽度（占总宽 30%）
    tmux resize-pane -t "$SESSION:大厅.0" -x 40 2>/dev/null || true

    # ── 右栏: 小G ──
    tmux select-pane -t "$SESSION:大厅.0"
    tmux split-window -h -t "$SESSION:大厅.0" -c "$DIR"
    tmux send-keys -t "$SESSION:大厅.2" "echo '👤 小G (gemma)'; echo ''; cd $DIR && claude" Enter

    # ── 后台通知器 ──
    ps aux | grep "[t]ask-notify.sh" | awk '{print $2}' | xargs -r kill 2>/dev/null || true
    nohup bash "$DIR/task-notify.sh" &>/dev/null &
    sleep 1

    echo "══════════════════════════════════════════"
    echo "  团队大厅"
    echo "  tmux attach -t $SESSION"
    echo ""
    echo "  ┌──────┬──────┬──────┬──────┐"
    echo "  │ 白板 │ 小G  │ Bob  │ ...  │"
    echo "  ├──────┤      │      │      │"
    echo "  │ 任务 │      │      │      │"
    echo "  └──────┴──────┴──────┴──────┘"
    echo ""
    echo "  加人: bash $DIR/member-add.sh <名字>"
    echo "══════════════════════════════════════════"
    ;;

  add)
    shift
    add_member_pane "${1:-新人}"
    ;;

  attach)
    exec tmux attach -t "$SESSION" 2>/dev/null || echo "加入: tmux attach -t $SESSION"
    ;;

  stop)  tmux kill-session -t "$SESSION" 2>/dev/null; echo "大厅已关闭" ;;
  status)
    tmux has-session -t "$SESSION" 2>/dev/null && echo "在线 ✅" || echo "离线 ❌"
    ;;
  *) echo "用法: $0 {start|add <name>|attach|stop|status}" ;;
esac
