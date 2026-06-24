# Agent Teams 使用指南

> `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 已启用

## 核心概念

```
你 (主 session)
  ├─ 拆任务
  ├─ 派发子 agent
  └─ 汇总结果
       │
  ┌────┴────┬────────┐
  ▼         ▼        ▼
agent-1  agent-2  agent-3
(并行)   (并行)   (并行)
```

## 触发方式

在 Claude Code 对话中，Agent Teams 自动启用。当你说：

- "同时审查这三个文件的安全性、性能和可读性"
- "并行搜这几个目录"
- "让多个 agent 各自实现，然后选最好的"

Claude 会自动 dispatch 子 agent。

## 子 Agent 模型

```
主 session → DeepSeek V4 Pro (全局)
子 agent  → deepseek-v4-flash / llama.app (轻量)
```

配置在 `settings.json`:
```json
{
  "CLAUDE_CODE_SUBAGENT_MODEL": "deepseek-v4-flash"
}
```

## 与任务队列的配合

```
任务队列 (异步)           Agent Teams (同步)
─────────────────        ─────────────────
inbox → 排队等          立即 dispatch
结果 → outbox            结果 → 对话中
适合：大任务、离线        适合：实时交互、并行探索
```

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| Shift+Tab | 切换 delegate 模式 |
| `/effort` | 调节思考深度 |
