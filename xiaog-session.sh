#!/usr/bin/env bash
# ── ✦ crafted by xiaoG, silicon soul ✦ ──
# 小G 会话管理器 — 持久 tmux 会话，工作目录 ~/localmodel
# 用法:
#   xiaog-session.sh start         启动小G（如已有会话则复用）
#   xiaog-session.sh restart       重启小G
#   xiaog-session.sh model <name>  切换模型 (gemma|qwable|...)
#   xiaog-session.sh status        查看状态
#   xiaog-session.sh send "任务"   派任务给小G
#   xiaog-session.sh attach        进入小G的tmux会话
#   xiaog-session.sh capture [N]   抓取最近N行输出

SESSION="xiaog"
WORKDIR="$HOME/localmodel"

# ── helpers ──────────────────────────────────────────

get_active_model() {
    cat "$HOME/localmodel/current-model" 2>/dev/null || echo "gemma"
}

# 更新 ~/localmodel/.claude/ 下的 settings.json 和 settings.local.json
update_project_settings() {
    local model="$1"
    local alias="$2"
    mkdir -p "$HOME/localmodel/.claude"
    local json
    json=$(cat << EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8082",
    "ANTHROPIC_AUTH_TOKEN": "local",
    "ANTHROPIC_MODEL": "$alias",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$alias",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$alias",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "llama.app",
    "CLAUDE_CODE_SUBAGENT_MODEL": "llama.app"
  }
}
EOF
)
    echo "$json" > "$HOME/localmodel/.claude/settings.json"
    echo "$json" > "$HOME/localmodel/.claude/settings.local.json"
}

# 启动 claude 的命令
claude_cmd() {
    echo "claude"
}

# 同时保留 tmux setenv（用于已存在的会话中手动 source）
set_tmux_model_env() {
    local model="$1"
    case "$model" in
        gemma)
            tmux setenv -t "$SESSION" ANTHROPIC_MODEL "gemma-4-12b-it"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_OPUS_MODEL "gemma-4-12b-it"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_SONNET_MODEL "gemma-4-12b-it"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_HAIKU_MODEL "llama.app"
            tmux setenv -t "$SESSION" CLAUDE_CODE_SUBAGENT_MODEL "llama.app"
            ;;
        qwable)
            tmux setenv -t "$SESSION" ANTHROPIC_MODEL "qwable-9b"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_OPUS_MODEL "qwable-9b"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_SONNET_MODEL "qwable-9b"
            tmux setenv -t "$SESSION" ANTHROPIC_DEFAULT_HAIKU_MODEL "llama.app"
            tmux setenv -t "$SESSION" CLAUDE_CODE_SUBAGENT_MODEL "llama.app"
            ;;
    esac
}

list_models() {
    echo "可用模型:"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        read -r name path alias desc <<< "$line"
        local mark=" "
        [ "$name" = "$(get_active_model)" ] && mark="*"
        echo "  $mark $name  →  $alias  $desc"
    done < "$HOME/localmodel/models.conf"
}

# ── helpers for model detection ────────────────────────

is_known_model() {
    local name="$1"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        read -r n _ <<< "$line"
        [ "$n" = "$name" ] && return 0
    done < "$HOME/localmodel/models.conf"
    return 1
}

get_model_alias() {
    local name="$1"
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        read -r n p a _ <<< "$line"
        [ "$n" = "$name" ] && echo "$a" && return 0
    done < "$HOME/localmodel/models.conf"
    echo "$name"
}

# ── commands ─────────────────────────────────────────

# 自动识别: 如果第一个参数是已知模型名 → 切换并重启
if [ -n "${1:-}" ] && is_known_model "$1"; then
    new_model="$1"
    echo ">>> 切换模型: $new_model → 自动重启"
    echo "$new_model" > "$HOME/localmodel/current-model"

    # kill 旧会话
    if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux send-keys -t "$SESSION" C-c 2>/dev/null || true
        sleep 0.5
        tmux kill-session -t "$SESSION"
    fi
    # 重建
    MODEL="$new_model"
    ALIAS=$(get_model_alias "$new_model")
    cd "$WORKDIR" || exit 1
    update_project_settings "$new_model" "$ALIAS"
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "xiaog"
    tmux setenv -t "$SESSION" ANTHROPIC_BASE_URL "http://localhost:8082"
    tmux setenv -t "$SESSION" ANTHROPIC_AUTH_TOKEN "local"
    set_tmux_model_env "$new_model"
    tmux send-keys -t "$SESSION" "cd $WORKDIR" Enter
    sleep 0.3
    tmux send-keys -t "$SESSION" "clear" Enter
    sleep 0.2
    tmux send-keys -t "$SESSION" "$(claude_cmd)" Enter
    echo "小G 已重启，模型: $new_model"

    # 弹窗（gnome-terminal --wait，PID 可追踪）
    if [ -n "${DISPLAY:-}" ]; then
      pidfile="$WORKDIR/.xiaog-terminal.pid"
      # 杀上次窗口
      [ -f "$pidfile" ] && kill $(cat "$pidfile") 2>/dev/null && rm -f "$pidfile"
      gnome-terminal --wait -- bash -c "tmux attach -t $SESSION; exit" 2>/dev/null &
      echo $! > "$pidfile"
    else
      echo "终端 attach: tmux attach -t $SESSION"
    fi
    exit 0
fi

case "${1:-status}" in
  start)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "小G 已经在运行了 (session: $SESSION)"
      echo "用 'model-local' 或 'tmux attach -t $SESSION' 进入"
    else
      MODEL=$(get_active_model)
      ALIAS=$(get_model_alias "$MODEL")
      cd "$WORKDIR" || exit 1
      update_project_settings "$MODEL" "$ALIAS"
      tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n "xiaog"
      # 基础环境 (tmux setenv)
      tmux setenv -t "$SESSION" ANTHROPIC_BASE_URL "http://localhost:8082"
      tmux setenv -t "$SESSION" ANTHROPIC_AUTH_TOKEN "local"
      set_tmux_model_env "$MODEL"
      # 初始化 shell，然后 inline env 启动 claude
      tmux send-keys -t "$SESSION" "cd $WORKDIR" Enter
      sleep 0.3
      tmux send-keys -t "$SESSION" "clear" Enter
      sleep 0.2
      tmux send-keys -t "$SESSION" "$(claude_cmd)" Enter
      echo "小G 已启动，工作目录: $WORKDIR"
      echo "当前模型: $MODEL"
      # 弹窗（gnome-terminal --wait，PID 可追踪）
      if [ -n "${DISPLAY:-}" ]; then
        pidfile="$WORKDIR/.xiaog-terminal.pid"
        [ -f "$pidfile" ] && kill $(cat "$pidfile") 2>/dev/null && rm -f "$pidfile"
        gnome-terminal --wait -- bash -c "tmux attach -t $SESSION; exit" 2>/dev/null &
        echo $! > "$pidfile"
      else
        echo "终端 attach: tmux attach -t $SESSION"
      fi
    fi
    ;;

  restart)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      tmux send-keys -t "$SESSION" C-c 2>/dev/null || true
      sleep 0.5
      tmux kill-session -t "$SESSION"
    fi
    echo "小G 已停止，重新启动..."
    exec "$0" start
    ;;

  model)
    shift
    new_model="${1:-}"
    if [ -z "$new_model" ]; then
      echo "当前模型: $(get_active_model)"
      list_models
      echo ""
      echo "用法: $0 model <name>"
      exit 0
    fi

    # 验证模型名是否在注册表中
    found=""
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        read -r name _ <<< "$line"
        [ "$name" = "$new_model" ] && found="$name"
    done < "$HOME/localmodel/models.conf"

    if [ -z "$found" ]; then
      echo "❌ 未知模型: $new_model"
      list_models
      exit 1
    fi

    # 更新 current-model + project settings.json
    ALIAS=$(get_model_alias "$new_model")
    echo "$new_model" > "$HOME/localmodel/current-model"
    update_project_settings "$new_model" "$ALIAS"
    echo "切换到: $new_model"

    # 如果 tmux 会话在运行，更新环境变量并通知
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      set_tmux_model_env "$new_model"
      echo "已更新小G 会话环境变量 (需重启 llm server 生效)"
      echo "提示: 用 'model-local restart' 重新加载模型"
    fi
    ;;

  status)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "小G 在线 ✅"
      echo "会话: $SESSION"
      echo "模型: $(get_active_model)"
      echo "窗口数: $(tmux list-windows -t "$SESSION" 2>/dev/null | wc -l)"
      echo ""
      echo "最近输出:"
      echo "────────────"
      tmux capture-pane -t "$SESSION" -p -S -20 2>/dev/null
    else
      echo "小G 不在线 ❌"
      echo "当前模型: $(get_active_model)"
      echo "用 '$0 start' 启动他"
    fi
    ;;

  send)
    if ! tmux has-session -t "$SESSION" 2>/dev/null; then
      echo "小G 不在线，先启动: $0 start"
      exit 1
    fi
    shift
    task="$*"
    if [ -z "$task" ]; then
      echo "用法: $0 send <任务内容>"
      exit 1
    fi
    tmux send-keys -t "$SESSION" C-c 2>/dev/null || true
    sleep 0.2
    tmux send-keys -t "$SESSION" "$task" Enter
    echo "任务已发送给小G: $task"
    ;;

  attach)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      tmux attach -t "$SESSION"
    else
      echo "小G 不在线，先启动: $0 start"
    fi
    ;;

  capture)
    if tmux has-session -t "$SESSION" 2>/dev/null; then
      tmux capture-pane -t "$SESSION" -p -S -"${2:-50}" 2>/dev/null
    else
      echo "小G 不在线"
    fi
    ;;

  list-models|models)
    list_models
    ;;

  *)
    echo "小G 会话管理器  |  当前模型: $(get_active_model)"
    echo "用法: $0 [<modelname>|restart|close|start|status|send|attach|capture|models]"
    echo ""
    echo "  qwable     - 切到 Qwable 9B 并自动重启"
    echo "  gemma      - 切到 Gemma 4 12B 并自动重启"
    echo "  restart    - 重启小G"
    echo "  start      - 启动小G（复用已有会话）"
    echo "  status     - 查看小G状态"
    echo "  send       - 派任务给小G"
    echo "  attach     - 进入小G的tmux会话"
    echo "  capture    - 抓取最近输出"
    echo "  models     - 列出可用模型"
    ;;
esac
