#!/bin/bash
# ── ✦ 团队通信机制 · 一键部署 ✦ ──
# 在新项目中执行: bash ~/localmodel/setup.sh <项目路径>

set -e

SRC="$HOME/localmodel"                      # 机制源码
PROJ="${1:-$PWD}"                            # 目标项目
PROJ_NAME=$(basename "$PROJ")

echo "═══════════════════════════════════════"
echo "  部署团队通信机制到: $PROJ_NAME"
echo "═══════════════════════════════════════"
echo ""

# ═══ 1. 检查依赖 ═══
echo "① 检查依赖..."
for dep in tmux curl python3; do
    which $dep >/dev/null 2>&1 || { echo "  ❌ 缺少: $dep"; exit 1; }
done
echo "  ✅ tmux curl python3"

# ═══ 2. 安装命令 ═══
echo ""
echo "② 安装 /model-local 命令..."
mkdir -p "$HOME/.claude/commands"
cp "$SRC/commands/model-local.md" "$HOME/.claude/commands/model-local.md" 2>/dev/null || true
echo "  ✅ /model-local 可用"

# ═══ 3. 为 Lead 创建项目 CLAUDE.md ═══
echo ""
echo "③ 创建 Lead 指挥手册..."
LEAD_MD="$PROJ/CLAUDE.md"
if [ -f "$LEAD_MD" ]; then
    echo "  ⚠ 已存在，追加机制说明..."
    echo "" >> "$LEAD_MD"
else
    touch "$LEAD_MD"
fi

cat >> "$LEAD_MD" << 'EOF'

## 团队协作机制

本项目使用统一通信机制，由 Lead 管理。

### 启动大厅
```bash
bash ~/localmodel/lobby-start.sh start
tmux attach -t lobby
```

### 白板
```bash
bash ~/localmodel/whiteboard-post.sh "消息"   # 快速留言
vim ~/localmodel/whiteboard.md                # 详细编辑
```

### 任务队列
```bash
bash ~/localmodel/task-submit.sh "任务描述"    # 派任务
bash ~/localmodel/task-check.sh <任务ID>       # 查结果
```

### 团队成员
```bash
bash ~/localmodel/member-add.sh <名字>         # 加人
```

### 设计文档 → 任务联动
/brainstorming 产出设计文档后：
1. `whiteboard-post.sh "📄 新设计: <文档名>"`
2. 拆成具体任务用 task-submit.sh 派发
3. 追踪进度，更新白板

### 模型切换
/model-local gemma    # Gemma 4 12B
/model-local qwable   # Qwable 9B (Fable 5 distill)
EOF

echo "  ✅ $LEAD_MD"

# ═══ 4. 创建项目目录 ═══
echo ""
echo "④ 创建项目目录..."
mkdir -p "$PROJ/docs/specs"
echo "  ✅ $PROJ/docs/specs/ (设计文档)"

# ═══ 5. 启动 llama-server（如果模型已下载）═══
echo ""
echo "⑤ 模型服务..."
if [ -f "$SRC/gemma-4-12b-it-Q6_K.gguf" ] || [ -f "$SRC/models/Qwable-9B-Claude-Fable-5-Q8_0.gguf" ]; then
    echo "  ✅ 检测到模型文件"
    echo "  启动: bash ~/localmodel/start-server.sh"
else
    echo "  ⚠ 未检测到模型，下载:"
    echo "    hf download unsloth/gemma-4-12b-it-GGUF gemma-4-12b-it-Q6_K.gguf --local-dir ~/localmodel"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  部署完成！"
echo ""
echo "  下一步:"
echo "    1. bash ~/localmodel/start-server.sh"
echo "    2. bash ~/localmodel/lobby-start.sh start"
echo "    3. tmux attach -t lobby"
echo "    4. /brainstorming 开始规划项目"
echo ""
echo "  你的指挥手册: $PROJ/CLAUDE.md"
echo "  系统文档:     ~/localmodel/README.md"
echo "═══════════════════════════════════════"
