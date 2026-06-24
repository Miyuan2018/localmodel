#!/bin/bash
# ── ✦ 查小G 是否回复了你的任务 ✦ ──
# 用法: task-check.sh <task-id>
#       task-check.sh            列出所有结果

OUTBOX="$HOME/localmodel/outbox"

if [ -n "$1" ]; then
    result="$OUTBOX/$1.md"
    if [ -f "$result" ]; then
        echo "✅ 已回复！"
        cat "$result"
    elif [ -f "$OUTBOX/$1.waiting" ]; then
        echo "⏳ 还在等..."
    else
        echo "❌ 找不到任务 $1"
    fi
else
    echo "═══════════════════════════════════════"
    echo "  已完成的任务"
    echo "═══════════════════════════════════════"
    ls -lt "$OUTPUT"/*.md 2>/dev/null | head -10 || echo "  暂无"
    echo ""
    echo "  等待中的任务"
    echo "═══════════════════════════════════════"
    ls -lt "$OUTBOX"/*.waiting 2>/dev/null | head -10 || echo "  暂无"
    echo ""
    echo "  查看结果: task-check.sh <任务ID>"
fi
