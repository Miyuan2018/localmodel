#!/bin/bash
# ── ✦ 等待小G 回复并保存到 outbox ✦ ──
# 用法: task-wait.sh <task-id>
#       task-wait.sh          等待最近一次回复

TASK_ID="${1:-latest}"
SESSION="lobby"
WINDOW="小G"
OUTBOX="$HOME/localmodel/outbox"
mkdir -p "$OUTBOX"

# 找到最新的等待文件
[ "$TASK_ID" = "latest" ] && TASK_ID=$(ls -t "$OUTBOX"/*.waiting 2>/dev/null | head -1 | xargs basename | sed 's/.waiting//')

# 记录当前窗口行数作为起点
prev_lines=$(tmux capture-pane -t "$SESSION:$WINDOW" -p 2>/dev/null | wc -l)

echo "⏳ 等待小G 回复..."

while true; do
    sleep 5
    content=$(tmux capture-pane -t "$SESSION:$WINDOW" -p -S -80 2>/dev/null)
    cur_lines=$(echo "$content" | wc -l)

    # 检测：有新内容 且 小G 不再 thinking
    thinking=$(echo "$content" | grep -c "Thinking\|Galloping\|Churned\|Crunched\|Bootstrapping" 2>/dev/null || true)
    has_new_content=$((cur_lines - prev_lines))

    if [ "$thinking" -eq 0 ] && [ "$has_new_content" -gt 3 ]; then
        result="$OUTBOX/${TASK_ID:-reply}.md"

        # 提取回复
        echo "$content" | awk '
            /^❯/ && !done { next }
            /^●/ { found=1 }
            found { print }
            /^✻/ && found { done=1 }
        ' > "$result"

        # 清理等待标记
        rm -f "$OUTBOX"/*.waiting 2>/dev/null

        echo "✅ 小G 回复了！"
        echo "   $result"
        echo ""
        cat "$result"
        exit 0
    fi
done
