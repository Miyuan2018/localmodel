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
| `/xiaog` | 启动/进入小G |
| `/xiaog gemma` | 切换到 Gemma 4 12B |
| `/xiaog qwable` | 切换到 Qwable 9B |
| `/xiaog restart` | 重启小G |
| `/xiaog close` | 关闭小G |
| `/team start` | 启动团队空间 |
| `/team stop` | 停止团队空间 |
| `/team status` | 查看状态 |
| `/team task <描述>` | 派任务给小G |
| `/team board <消息>` | 白板留言 |

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
