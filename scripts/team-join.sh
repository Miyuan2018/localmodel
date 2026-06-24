#!/bin/bash
# ── ✦ 显示团队加入信息 ✦ ──
# 以"我"（主 session）为中心的团队协作

PORT=42000
TOKEN="my-team-2026"
IP=$(hostname -I | awk '{print $1}')

echo "══════════════════════════════════════════"
echo "  团队协作 — 加入方式"
echo "══════════════════════════════════════════"
echo ""
echo "  Host:  我 (DeepSeek V4 Pro)"
echo "  AI 队友:  小G (gemma/qwable)"
echo ""
echo "  安装:  npm install -g coclaude"
echo "  加入:  coclaude join \"ws://${IP}:${PORT}/s/${TOKEN}\""
echo ""
echo "  加入后需 host 审批，按 a 通过"
echo "══════════════════════════════════════════"
