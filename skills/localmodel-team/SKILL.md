# localmodel-team

本地模型团队协作系统。

## 快速开始

```bash
# 首次安装
git clone https://github.com/Miyuan2018/localmodel.git ~/localmodel
bash ~/localmodel/scripts/setup.sh

# 启动系统
bash ~/localmodel/scripts/lobby-start.sh start
tmux attach -t lobby
```

## 命令

| 命令 | 说明 |
|------|------|
| `/model-local` | 启动/进入小G tmux 会话 |
| `/model-local lobby` | 启动团队大厅 (白板+任务+我+小G) |
| `/model-local gemma` | 切换到 Gemma 4 12B |
| `/model-local qwable` | 切换到 Qwable 9B (Fable 5 distill) |
| `/model-local restart` | 重启小G |
| `/model-local close` | 关闭小G |

## 大厅 (tmux attach -t lobby)

窗口 0: 白板 + 任务面板
窗口 1: 我 (Lead)
窗口 2+: 小G + 团队成员

## 工具脚本

```bash
bash ~/localmodel/scripts/task-submit.sh "任务"   # 派任务
bash ~/localmodel/scripts/task-check.sh <ID>     # 查结果
bash ~/localmodel/scripts/whiteboard-post.sh "消息"  # 白板留言
bash ~/localmodel/scripts/member-add.sh <名字>     # 加人
bash ~/localmodel/scripts/lobby-start.sh start    # 启动大厅
bash ~/localmodel/scripts/lobby-start.sh stop     # 停止大厅
```

## 架构

```
Lead (我) → 白板 + 任务队列 + 大厅 + Agent Teams
    │
    ├── 小G (AI 程序员, gemma/qwable)
    ├── 老王 (测试员)
    └── ...
```

> 沟通机制是 Lead 的指挥系统，小G 是普通团队成员。
