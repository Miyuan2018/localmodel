#!/bin/bash
# ── ✦ 本地模型推理服务 ✦ ──
# 根据 ~/localmodel/current-model 选择模型
# 模型注册表: ~/localmodel/models.conf

MODEL_NAME=$(cat "$HOME/localmodel/current-model" 2>/dev/null || echo "gemma")

# 解析 models.conf 找到对应行 (跳过注释)
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    read -r name path alias desc <<< "$line"
    if [ "$name" = "$MODEL_NAME" ]; then
        # expand $HOME
        MODEL=$(eval echo "$path")
        ALIAS="$alias"
        break
    fi
done < "$HOME/localmodel/models.conf"

if [ -z "$MODEL" ] || [ ! -f "$MODEL" ]; then
    echo "Model not found: ${MODEL:-unknown}"
    echo "Active model: $MODEL_NAME"
    echo "Available models:"
    grep -v '^#' "$HOME/localmodel/models.conf" | grep -v '^$' | while read -r n p a d; do
        echo "  $n  →  $a  ($d)"
    done
    exit 1
fi

echo "Starting: $MODEL_NAME ($ALIAS)"
echo "GGUF: $MODEL"

exec ~/llama.cpp/build/bin/llama-server \
    --model "$MODEL" \
    --alias "$ALIAS" \
    --n-gpu-layers 99 \
    --ctx-size 88000 \
    --cache-type-k q4_0 \
    --cache-type-v q4_0 \
    --host 127.0.0.1 \
    --port 8082 \
    --jinja
