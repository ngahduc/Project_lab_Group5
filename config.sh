#!/bin/bash
# ============================================================
# config.sh - Cau hinh chung
# GROQ_API_KEY duoc lay tu ~/.bashrc (khong can dien vao day)
# ============================================================

# Doc GROQ_API_KEY tu bien moi truong (da set trong ~/.bashrc)
# Neu chua co thi bao loi
if [ -z "$GROQ_API_KEY" ]; then
    echo "LOI: Chua tim thay GROQ_API_KEY trong moi truong."
    echo "     Kiem tra ~/.bashrc co dong nay chua:"
    echo "     export GROQ_API_KEY=\"gsk_...\""
    echo "     Sau do chay: source ~/.bashrc"
    exit 1
fi

export AI_MODEL="llama-3.3-70b-versatile"
export AI_ENDPOINT="https://api.groq.com/openai/v1/chat/completions"
export PROJECT_DIR="$HOME/ai_monitor"
export LOG_FILE="/var/log/ai_monitor.log"
export BACKUP_DIR="$HOME/ai_monitor/backups"
export DATA_DIR="$HOME/ai_monitor/data"
