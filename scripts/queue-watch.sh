#!/bin/bash
# ── ✦ 任务队列看守 ✦ ──
# 轮询 ~/localmodel/inbox/，自动调用本地 API 处理任务

INBOX="$HOME/localmodel/inbox"
OUTBOX="$HOME/localmodel/outbox"
ARCHIVE="$HOME/localmodel/archive"
LOG="$HOME/localmodel/queue.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
status_file="$HOME/localmodel/.queue-status"

echo "running" > "$status_file"
log "任务队列启动，监控: $INBOX"

process_task() {
    local task="$1" task_name="$2" requester="$3"
    local result_file="$OUTBOX/${task_name%.*}.result.md"
    local model answer

    model=$(cat "$HOME/localmodel/current-model" 2>/dev/null || echo "gemma")

    # 用 python 处理：读任务文件 → 调 API → 输出回复
    answer=$(python3 - "$task" "$model" << 'PYEOF'
import json, subprocess, sys, os

task_file = sys.argv[1]
model = sys.argv[2]

with open(task_file) as f:
    content = f.read().strip()

payload = {
    'model': model,
    'max_tokens': 1024,
    'temperature': 0.7,
    'thinking': {'type': 'disabled'},
    'messages': [{'role': 'user', 'content': content}]
}

try:
    r = subprocess.run(['curl', '-s', 'http://localhost:8082/v1/messages',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps(payload)],
         capture_output=True, text=True, timeout=120)
    d = json.loads(r.stdout)
    text_parts = []
    if 'content' in d and isinstance(d['content'], list):
        for block in d['content']:
            if block.get('type') == 'text':
                text_parts.append(block['text'])
            elif block.get('type') == 'thinking' and block.get('thinking'):
                # 如果只有 thinking 没有 text，把 thinking 摘要当回复
                t = block['thinking']
                if len(t) > 200:
                    t = t[:200] + '...'
                text_parts.append(f'[思考] {t}')
    if text_parts:
        print('\n'.join(text_parts))
        sys.exit(0)
    if 'error' in d:
        print(f"(API Error) {json.dumps(d['error'], ensure_ascii=False)[:200]}")
    else:
        print(f"(API 返回异常) {r.stdout[:300]}")
except Exception as e:
    print(f"(API 调用失败: {e})")
PYEOF
)

    cat > "$result_file" << EOF
# 任务结果: $task_name

**提交者:** $requester
**时间:**   $(date '+%Y-%m-%d %H:%M:%S')
**模型:**   $model

## 任务

$(cat "$task")

## 小G 回复

$answer

---
*由小G 自动处理*
EOF
}

# ── 主循环 ──
while [ -f "$status_file" ]; do
    task=$(find "$INBOX" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | head -1)

    if [ -n "$task" ]; then
        task_name=$(basename "$task")
        requester=$(stat -c '%U' "$task" 2>/dev/null || echo "unknown")
        log "📥 收到: $task_name ← $requester"

        process_task "$task" "$task_name" "$requester"

        # 归档
        mv "$task" "$ARCHIVE/${task_name}.done.$(date '+%Y%m%d%H%M%S')"
        log "✅ 完成: $task_name"
    fi

    sleep 3
done

log "任务队列已停止"
rm -f "$status_file"
