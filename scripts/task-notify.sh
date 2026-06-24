#!/bin/bash
# ── ✦ 回复通知器 ✦ ──
# 后台运行。检测到小G 回完 → 自动存 outbox

SES="lobby"
WIN="小G"
OUTBOX="$HOME/localmodel/outbox"
mkdir -p "$OUTBOX"

echo "🔔 通知器启动"

prev_hash=""

while true; do
    sleep 5

    content=$(tmux capture-pane -t "$SES:$WIN" -p -S -80 2>/dev/null)
    [ -z "$content" ] && continue

    # 检测是否还在忙（Crunched/Churned 是完成标记，不算忙）
    busy=$(echo "$content" | grep -cE "Thinking|Galloping|Zesting|Bootstrapping" 2>/dev/null || true)

    # 检测是否有回复（● 开头的行）
    has_reply=$(echo "$content" | grep -cE "^●" 2>/dev/null || true)

    cur_hash=$(echo "$content" | md5sum)

    # 条件：不在忙 + 有回复 + 内容变了
    if [ "$busy" -eq 0 ] && [ "$has_reply" -gt 0 ] && [ "$cur_hash" != "$prev_hash" ]; then
        prev_hash="$cur_hash"

        pending=$(ls -t "$OUTBOX"/*.waiting 2>/dev/null | head -1)
        if [ -n "$pending" ]; then
            tid=$(basename "$pending" .waiting)
            result="$OUTBOX/${tid}.md"

            # 提取整个回复块（从第一个 ● 到最后）
            echo "$content" | awk '
                /^●/ { found=1 }
                found { print }
                /^─/ && found { done=1 }
            ' > "$result"

            # 确保有内容才删除 waiting
            if [ -s "$result" ]; then
                rm -f "$pending"
                echo "[$(date '+%H:%M:%S')] ✅ $tid → outbox/"

                # 同步贴到白板
                WB="$HOME/localmodel/whiteboard.md"
                brief=$(head -3 "$result" | tail -1)
                sed -i "/^## 小G 最新回复/i\\\n✅ **$tid** ($(date '+%H:%M:%S'))\n\n详见: outbox/$tid.md\n" "$WB" 2>/dev/null || true
            fi
        fi
    fi
done
