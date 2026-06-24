# model-local Command

启动/管理 程序员小G 的持久 tmux 会话。小G 工作在 ~/localmodel。

## 用法

`/model-local [restart|close|<modelname>]`

## 不带参数：启动或进入小G

1. 检查 tmux session `xiaog` 是否已存在
2. 如不存在：创建 detached session → 自动发送 `claude` 启动命令 → 弹出 gnome-terminal 窗口
3. 如已存在：弹出 gnome-terminal 窗口 attach 到现有会话
4. 如果无 DISPLAY（纯 SSH）：告知用户在终端执行 `tmux attach -t xiaog`

会话启动时自动设置环境变量（根据当前模型）：
```
ANTHROPIC_BASE_URL=http://localhost:8082
ANTHROPIC_AUTH_TOKEN=local
ANTHROPIC_MODEL=<当前模型别名>
ANTHROPIC_DEFAULT_OPUS_MODEL=<当前模型别名>
ANTHROPIC_DEFAULT_SONNET_MODEL=<当前模型别名>
ANTHROPIC_DEFAULT_HAIKU_MODEL=llama.app
CLAUDE_CODE_SUBAGENT_MODEL=llama.app
```

## /model-local restart：重启小G

1. 向 xiaog session 发送 Ctrl-C
2. 等待 0.5 秒
3. kill xiaog session
4. 重新创建 detached session（会用当前 active model）
5. 弹出 gnome-terminal 窗口

## /model-local close：关闭小G

1. 向 xiaog session 发送 Ctrl-C（优雅退出）
2. 等待 0.5 秒
3. kill xiaog session
4. 确认会话已关闭
5. 不弹窗，只报告结果

## /model-local <modelname>：切换模型并自动重启

1. 验证模型名在 ~/localmodel/models.conf 中存在
2. 更新 ~/localmodel/current-model
3. 更新 xiaog tmux 会话的环境变量
4. **自动执行 restart**：kill 旧会话 → 重建 → 弹窗 → llama-server 加载新 GGUF

### 支持的模型
- `gemma` — Gemma 4 12B (Q6_K, ~9.6GB)
- `qwable` — Qwable 9B (Fable 5 distill, Q8_0, ~9.5GB)

## 注意事项

- 小G 的会话是**持久**的——除非显式 `/model-local restart`，否则一直复用同一个 session
- 模型注册表: `~/localmodel/models.conf`，可自行添加新模型
- 切换模型（如 `/model-local qwable`）会自动重启会话加载新模型
- 弹窗使用 xterm（命令结束自动关闭，不残留）
