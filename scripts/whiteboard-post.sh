#!/bin/bash
# ── ✦ 白板留言 ✦ ──
# 用法: whiteboard-post.sh "你的留言"
#       whiteboard-post.sh          交互式

WB="$HOME/localmodel/whiteboard.md"
who="${USER:-匿名}"
msg="$*"

if [ -z "$msg" ]; then
    echo -n "留言: "
    read -r msg
fi
[ -z "$msg" ] && exit 0

echo "$who ($(date '+%H:%M')): $msg" >> "$WB"
echo "✅ 已贴到白板"
