#!/bin/bash
# ============================================================
# config.sh - Cau hinh chung
# GROQ_API_KEY: uu tien doc tu bien moi truong (.bashrc, khi
# chay tay tren terminal). Neu khong co (vi du khi chay qua
# systemd service - khong doc duoc .bashrc) thi doc tu file
# ~/ai_monitor/groq.env
# ============================================================

if [ -z "$GROQ_API_KEY" ] && [ -f "$HOME/ai_monitor/groq.env" ]; then
    export $(grep GROQ_API_KEY "$HOME/ai_monitor/groq.env" | xargs)
fi

if [ -z "$GROQ_API_KEY" ]; then
    echo "LOI: Chua tim thay GROQ_API_KEY trong moi truong."
    echo "     Cach 1 (chay tay): them vao ~/.bashrc dong:"
    echo "       export GROQ_API_KEY=\"gsk_...\""
    echo "       roi chay: source ~/.bashrc"
    echo "     Cach 2 (chay qua systemd): chay ~/ai_monitor/install_service.sh"
    exit 1
fi

export AI_MODEL="llama-3.3-70b-versatile"
export AI_ENDPOINT="https://api.groq.com/openai/v1/chat/completions"
export PROJECT_DIR="$HOME/ai_monitor"
export LOG_FILE="/var/log/ai_monitor.log"
export BACKUP_DIR="$HOME/ai_monitor/backups"
export DATA_DIR="$HOME/ai_monitor/data"
