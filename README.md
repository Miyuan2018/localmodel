# 小G 本地模型会话管理系统

程序员小G 的持久 tmux 会话管理器，使用本地 llama-server 运行开源模型。

## 支持的模型

| 短名 | 模型 | 量化 | 大小 |
|------|------|------|------|
| `gemma` | Gemma 4 12B | Q6_K | ~9.6GB |
| `qwable` | Qwable 9B (Claude Fable 5 distill) | Q8_0 | ~9.5GB |

## 快速开始

### 1. 克隆

```bash
git clone git@github.com:Miyuan2018/localmodel.git ~/localmodel
cd ~/localmodel
```

### 2. 下载模型

```bash
# Gemma 4 12B
hf download unsloth/gemma-4-12b-it-GGUF gemma-4-12b-it-Q6_K.gguf --local-dir .

# Qwable 9B (Fable 5 distill)
hf download empero-ai/Qwable-9B-Claude-Fable-5-GGUF Qwable-9B-Claude-Fable-5-Q8_0.gguf --local-dir ./models/
```

### 3. 安装命令

```bash
ln -sf ~/localmodel/commands/model-local.md ~/.claude/commands/model-local.md
```

### 4. 启动 llama-server

```bash
bash ~/localmodel/start-server.sh
# 服务跑在 http://localhost:8082
```

### 5. 启动小G

在 Claude Code 中输入：

```
/model-local gemma    # 用 Gemma 4 12B
/model-local qwable   # 用 Qwable 9B (Fable 5 distill)
```

## 命令

```
/model-local              启动/进入小G
/model-local <modelname>  切换模型并自动重启
/model-local restart      重启小G
/model-local close        关闭小G
```

## 文件结构

```
~/localmodel/
├── xiaog-session.sh       # tmux 会话管理器
├── start-server.sh         # llama-server 启动脚本
├── start-claude.sh         # Claude Code 启动 wrapper (已弃用)
├── models.conf             # 模型注册表
├── current-model           # 当前激活的模型名
├── commands/
│   └── model-local.md      # Claude Code 命令定义
├── .claude/
│   ├── settings.json       # 项目级 Claude API 配置
│   └── settings.local.json # 本地覆盖 (优先级最高)
├── .gitignore
└── README.md
```

## 依赖

- [llama.cpp](https://github.com/ggml-org/llama.cpp) — llama-server
- tmux
- xterm
- [huggingface_hub](https://pypi.org/project/huggingface-hub/) (`hf` CLI)
