#!/bin/bash
# ── ✦ 显示 coclaude 团队加入信息 ✦ ──

PORT=42000
TOKEN="xiaog-team-2026"
IP=$(hostname -I | awk '{print $1}')
URL="ws://${IP}:${PORT}/s/${TOKEN}"

echo "══════════════════════════════════════════"
echo "  小G 团队协作 — 加入方式"
echo "══════════════════════════════════════════"
echo ""
echo "  安装:  npm install -g coclaude"
echo ""
echo "  加入:  coclaude join \"${URL}\""
echo ""
echo "  IP:    ${IP}"
echo "  端口:  ${PORT}"
echo "══════════════════════════════════════════"
