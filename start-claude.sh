#!/bin/bash
# ── ✦ 小G Claude 启动脚本 ✦ ──
# 根据 ~/localmodel/current-model 设置环境变量并启动 Claude

MODEL=$(cat "$HOME/localmodel/current-model" 2>/dev/null || echo "gemma")

export ANTHROPIC_BASE_URL="http://localhost:8082"
export ANTHROPIC_AUTH_TOKEN="local"

case "$MODEL" in
    gemma)
        export ANTHROPIC_MODEL="gemma-4-12b-it"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="gemma-4-12b-it"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="gemma-4-12b-it"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="llama.app"
        export CLAUDE_CODE_SUBAGENT_MODEL="llama.app"
        ;;
    qwable)
        export ANTHROPIC_MODEL="qwable-9b"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="qwable-9b"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="qwable-9b"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="llama.app"
        export CLAUDE_CODE_SUBAGENT_MODEL="llama.app"
        ;;
    *)
        export ANTHROPIC_MODEL="$MODEL"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="llama.app"
        export CLAUDE_CODE_SUBAGENT_MODEL="llama.app"
        ;;
esac

exec claude "$@"
