# 小G 团队通信系统 · 设计演进

> 记录 2026-06-23 ~ 2026-06-24 从需求到实现的完整过程。

## 起点：单人模式

`/model-local` 命令管理小G 的 tmux 会话，xterm/gnome-terminal 弹窗，一人独享。支持 `gemma` ↔ `qwable` 模型切换。

```
用户 → /model-local gemma → tmux xiaog → Claude + llama-server
```

**局限：** 只有一个人能用，团队无法参与。

---

## 第一阶段：探索多人协作工具

### 尝试 1: coclaude

**思路：** 用 coclaude 实现多人 WebSocket 连接，共享 Claude 会话。

**过程：**
1. 安装 `coclaude`，在 tmux 中启动 host/guest
2. 成功建立连接——host（小G）审批 guest（Bob）加入
3. Bob 发消息，小G 收到并回复

**发现的问题：**
- coclaude 的 guest 只能**遥控 host 的 Claude**，不是独立 AI agent
- 架构变成以"小G 为中心"，而非以"我（主 session）为中心"
- 调整后以"我"为 host，小G 为 guest——但小G 的消息只是 host（DeepSeek）的输入，小G 没有自己的 Claude 实例
- 本质设计：**多人共享一个 AI**，非**多 AI 协作**

**结论：** ❌ 不适合"我 + 小G 作为两个独立 AI agent"的场景。

### 尝试 2: Clay

**思路：** 自托管浏览器工作台，支持 Multi-Mate 辩论，每个 Mate 有独立 Claude 会话。

**过程：**
1. 安装 `clay-server`，`--headless --multi-user` 模式启动
2. 通过 API 完成 admin 设置（Setup Code → 创建账号）
3. 为小G 创建 Mate 账号
4. 发现 Clay 的 Mate 需要**浏览器 UI** 配置，curl API 不完整

**发现的问题：**
- Clay 是**浏览器原生**工具，核心操作（创建 Mate、配置模型、发起辩论）都在 Web UI 完成
- 纯 CLI + 本地模型场景不匹配
- Mate 的模型配置需要浏览器操作，无法自动化

**结论：** ❌ 不适合纯 CLI 环境。

---

## 第二阶段：回归本质需求

### 核心需求澄清

| 需求 | 说明 |
|------|------|
| 纯 CLI | 不依赖浏览器 |
| 本地模型 | llama-server，gemma/qwable |
| 多角色 | 我（主 session）+ 小G（AI）+ 队友（人类） |
| 异步通信 | 不需要实时等待 |
| 可见性 | 所有人都能看到小G 的工作过程 |

### 放弃"多 AI agent 实时对话"

coclaude 和 Clay 都试图实现"多 agent 实时对话"，但这需要：
- 每个 agent 有独立 Claude 实例（coclaude 做不到）
- 或者 agent 之间通过消息总线通信（Clay 可以做但需要浏览器）

对纯 CLI + 本地模型来说，这层需求当前没有成熟工具。

---

## 第三阶段：三层协作系统

**设计思路：** 不求"多 AI 对话"，而是让所有人和小G **通过不同方式协作**。

### 架构

```
┌─────────────────────────────────────────────┐
│  🏛️ tmux 大厅       沟通层                   │
│  tmux attach -t lobby                       │
│  Ctrl+B 0=小G  1=任务面板  2=Shell            │
│  → 所有人实时围观小G 干活                      │
├─────────────────────────────────────────────┤
│  📋 任务队列         调度层                   │
│  task-submit.sh → inbox/.waiting              │
│  task-notify.sh → 检测回复 → outbox/<id>.md   │
│  task-check.sh → 随时查结果                    │
│  → 异步派活，零等待                            │
├─────────────────────────────────────────────┤
│  ⚡ Agent Teams      执行层                   │
│  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1      │
│  → 主 session 并行 dispatch 子 agent          │
└─────────────────────────────────────────────┘
```

### 关键设计决策

#### 1. 为什么用 tmux send-keys 而不是 API 调用？

**尝试过直接调 API（`curl llama-server /v1/messages`）：**
- ✅ 异步，不阻塞
- ❌ 缺少 Claude Code 的工具链（文件读写、命令执行）
- ❌ 回复质量差，没有 agent 能力

**最终方案——tmux send-keys 打字到 Claude 输入框：**
- ✅ 小G 拥有完整 Claude Code 能力（读文件、执行命令、搜索代码）
- ✅ 所有人通过 tmux attach 实时看到过程
- ✅ 保留小G 的人设和 CLAUDE.md 配置
- ❌ 需要 tmux session 存在（大厅必须在线）

#### 2. 通知器如何检测"小G 回复完了"？

```
小G 窗口轮询（每 5 秒）
  → 检测 ❌ 不在 busy 状态（排除 Thinking/Galloping/Zesting/Bootstrapping）
  → 检测 ✅ 有 ● 开头的回复行
  → 检测 ✅ 内容 hash 变了（不是旧回复）
  → 提取回复块 → 存 outbox/<id>.md → 删除 .waiting
```

**关键 bug：** `Crunched`/`Churned` 是**完成标记**，不是忙碌状态，排除在 busy 检测外。

#### 3. 为什么需要 .waiting 标记？

解决**同步问题**——老王提交任务后不知道小G 什么时候回完。

```
提交时:
  outbox/<id>.waiting  ← 创建（表示等待中）

回复完成时:
  outbox/<id>.md       ← 生成（通知器自动）
  outbox/<id>.waiting  ← 删除
```

老王随时 `task-check.sh <id>`：
- `.waiting` 存在 → ⏳ 还在等
- `.md` 存在 → ✅ 已回复，显示内容

### 技术踩坑

| 坑 | 现象 | 解决 |
|-----|------|------|
| `tmux setenv` 不生效 | Claude 读不到环境变量 | 改 `.claude/settings.local.json` |
| `settings.local.json` 优先级最高 | 覆盖了所有其他设置 | 切片模型时同步更新 |
| gnome-terminal `[exited]` 残留 | 窗口关不掉 | 改用 `--wait` + PID 追踪 |
| `pkill -f` 误杀自己 | exit 144 | 用 `grep [p]attern` 排除当前进程 |
| 对话内容被当 session 名 | task-submit 参数解析错误 | `grep ":"` 检测 session:window 格式 |
| 通知器 `busy` 检测包含完成标记 | `Crunched` 被误判为忙碌 | 排除完成态关键词 |
| 通知器重复保存旧回复 | hash 检测逻辑错误 | 用 md5sum 比较内容变化 |

### 通知器 vs API 调用的取舍

| | tmux send-keys | API 调用 |
|------|:---:|:---:|
| Agent 能力（文件、命令） | ✅ | ❌ |
| 实时可见（tmux attach） | ✅ | ❌ |
| 不依赖 tmux | ❌ | ✅ |
| 速度 | 慢（完整 Claude 流程） | 快 |
| 适合任务 | 复杂开发、代码审查 | 简单问答 |

**结论：** 对团队协作场景，选择 tmux send-keys——宁愿慢，也要让所有人看到小G 的完整工作过程。

## 最终使用方式

```bash
# 管理员：启动大厅（开机自启）
bash ~/localmodel/lobby-start.sh start

# 任何人：提交任务
bash ~/localmodel/task-submit.sh "帮我审查 auth.py 的安全性"

# 任何人：查回复
bash ~/localmodel/task-check.sh <任务ID>

# 任何人：实时围观
tmux attach -t lobby
```

**一条命令提交，一条命令查结果。中间不需要等。**
