#!/bin/bash
# ── ✦ 提交任务到小G 队列 ✦ ──
# 用法: task-submit.sh "修一下 auth 的 bug"
#       task-submit.sh           (交互式)

INBOX="$HOME/localmodel/inbox"

task="$*"
if [ -z "$task" ]; then
    echo -n "任务描述: "
    read -r task
fi
if [ -z "$task" ]; then
    echo "取消"
    exit 0
fi

id=$(date '+%Y%m%d%H%M%S')-$(whoami)
file="$INBOX/$id.task"
echo "$task" > "$file"
echo "✅ 已提交: $id"
echo "   查看: cat $file"
echo "   结果: ~/localmodel/outbox/${id}.result.md"
