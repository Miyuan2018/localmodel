# 小G · 本地模型 + 团队协作

程序员小G 是一个基于本地 llama-server 的 AI 编码助手，支持模型热切换和多人团队协作。

## 架构

```
┌──────────────────────────────────────────────────────────────┐
│                       团队协作层                              │
│                                                              │
│   我 (host · DeepSeek V4 Pro) ← 团队中心                      │
│   ├─ 审批新成员                                               │
│   ├─ 主持讨论、分配任务                                       │
│   └─ @ 文件、/ 命令                                          │
│        │                                                     │
│   ┌────┴──────────┬──────────┐                               │
│   ▼               ▼          ▼                               │
│  小G (guest)    Bob        Alice                             │
│  gemma/qwable   human      human                             │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                       模型服务层                              │
│                                                              │
│   llama-server :8082                                         │
│   ├─ gemma-4-12b-it (Q6_K, ~9.6GB)                          │
│   └─ qwable-9b (Q8_0, ~9.5GB, Fable 5 distill)             │
│                                                              │
│   /model-local gemma  ←→  /model-local qwable                │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                       会话管理层                              │
│                                                              │
│   xiaog tmux session     coclaude-team tmux session           │
│   (单人独享)              (多人协作)                           │
│   xterm 弹窗              systemd 开机自启                    │
└──────────────────────────────────────────────────────────────┘
```

## 模型

| 短名 | 模型 | 量化 | 大小 | 说明 |
|------|------|------|------|------|
| `gemma` | Gemma 4 12B | Q6_K | ~9.6GB | 通用编码 |
| `qwable` | Qwable 9B | Q8_0 | ~9.5GB | Fable 5 蒸馏, agentic tool-use |

## 快速开始

### 1. 环境

| 依赖 | 用途 |
|------|------|
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | 模型推理 (`llama-server`) |
| tmux | 会话管理 |
| systemd (user) | 开机自启 |
| [huggingface_hub](https://pypi.org/project/huggingface-hub/) | 模型下载 (`hf`) |
| [coclaude](https://www.npmjs.com/package/coclaude) | 团队协作 |

### 2. 克隆

```bash
git clone git@github.com:Miyuan2018/localmodel.git ~/localmodel
cd ~/localmodel
```

### 3. 下载模型

```bash
# Gemma 4 12B
hf download unsloth/gemma-4-12b-it-GGUF gemma-4-12b-it-Q6_K.gguf --local-dir .

# Qwable 9B (Fable 5 distill)
hf download empero-ai/Qwable-9B-Claude-Fable-5-GGUF Qwable-9B-Claude-Fable-5-Q8_0.gguf --local-dir ./models/
```

### 4. 安装命令

```bash
ln -sf ~/localmodel/commands/model-local.md ~/.claude/commands/model-local.md
```

### 5. 启动模型服务

```bash
bash ~/localmodel/start-server.sh
# → http://localhost:8082
```

### 6. 启动小G（单人模式）

```
/model-local gemma    # Gemma 4 12B
/model-local qwable   # Qwable 9B (Fable 5 distill)
```

### 7. 启动团队协作

```bash
# 安装 coclaude
npm install -g coclaude

# 启用开机自启
cp ~/localmodel/systemd/coclaude-xiaog.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now coclaude-xiaog.service

# 查看加入信息
bash ~/localmodel/team-join.sh
```

### 8. 队友加入

```bash
npm install -g coclaude
coclaude join "ws://<机器IP>:42000/s/my-team-2026"
```

加入后 host 会收到审批请求，按 `a` 批准，`d` 拒绝。

## 命令参考

### /model-local

```
/model-local              启动/进入小G（弹出终端窗口）
/model-local gemma        切换到 Gemma 4 12B
/model-local qwable       切换到 Qwable 9B
/model-local restart      重启小G
/model-local close        关闭小G
```

### 团队服务管理

```bash
systemctl --user status  coclaude-xiaog   # 查看状态
systemctl --user restart coclaude-xiaog   # 重启服务
systemctl --user stop    coclaude-xiaog   # 停止服务

tmux attach -t coclaude-team              # 查看团队协作界面
bash ~/localmodel/team-join.sh            # 显示加入信息
```

## 文件结构

```
~/localmodel/
├── xiaog-session.sh          # 小G tmux 会话管理器
├── start-server.sh           # llama-server 启动（根据 current-model）
├── start-claude.sh           # Claude 启动 wrapper
├── coclaude-service.sh       # 团队服务看守进程
├── team-join.sh              # 显示团队加入信息
├── models.conf               # 模型注册表
├── current-model             # 当前激活模型
├── models/                   # GGUF 模型文件
├── commands/
│   └── model-local.md        # Claude Code 命令定义
├── systemd/
│   └── coclaude-xiaog.service # 用户级 systemd 服务
├── .claude/
│   ├── settings.json         # 项目级 API 配置
│   └── settings.local.json   # 本地覆盖（优先级最高）
├── .gitignore
└── README.md
```

## 团队角色

| 角色 | 身份 | 模型 | 权限 |
|------|------|------|------|
| **我** | host | DeepSeek V4 Pro | 审批、主持、完全控制 |
| **小G** | guest (AI) | gemma/qwable | 发言、/@文件、/命令 |
| **队友** | guest (human) | - | 发言、/@文件 |

## 许可证

MIT
