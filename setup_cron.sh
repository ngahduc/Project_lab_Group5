#!/bin/bash
# ============================================================
# setup_cron.sh
# Topic 06 <Chapter 4>: Leveraging AI chatbots for
#           scheduling processes in Linux
#
# USE CASE: Nguoi dung noi bang tieng tu nhien:
#   "Run backup.sh every day at 2 AM"
#   --> Groq AI hieu va tao cron job chinh xac
# ============================================================

source "$HOME/ai_monitor/ask_ai.sh"

BLUE='\033[0;34m'; CYAN='\033[0;36m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'

SCRIPT="$HOME/ai_monitor/backup.sh"
NAME="backup.sh"

clear
echo -e "${BLUE}"
echo "========================================================"
echo "  Topic 06: Leveraging AI Chatbots for"
echo "            Scheduling Processes in Linux"
echo "  Groq AI (llama-3.3-70b-versatile)"
echo "========================================================"
echo -e "${NC}"

# ============================================================
# BUOC 1: NGUOI DUNG NHAP YEU CAU BANG TIENG TU NHIEN
# ============================================================
echo -e "${CYAN}[BUOC 1] Nhap yeu cau len lich bang tieng Anh:${NC}"
echo ""
echo -e "  Goi y: ${YELLOW}Run backup.sh every day at 2 AM${NC}"
echo ""
read -p "  > " USER_REQUEST

# Kiem tra rong
if [ -z "$USER_REQUEST" ]; then
    echo -e "${RED}Chua nhap yeu cau.${NC}"; exit 1
fi

# ============================================================
# BUOC 2: GOI GROQ API -- AI PHAN TICH YEU CAU
# ============================================================
echo ""
echo -e "${CYAN}[BUOC 2] Dang gui yeu cau den Groq API...${NC}"
echo -e "  Endpoint : https://api.groq.com/openai/v1/chat/completions"
echo -e "  Model    : $AI_MODEL"
echo ""

PROMPT='You are a Linux cron job expert.

The user wants to schedule the script: backup.sh
User request: "'"$USER_REQUEST"'"

Reply in EXACTLY this format (2 lines, nothing else):
CRON: <5-field cron expression>
EXPLAIN: <Vietnamese explanation of the schedule>

Example output:
CRON: 0 2 * * *
EXPLAIN: Chay moi ngay luc 2 gio sang'

echo -ne "  Dang cho Groq AI tra loi"
AI_RESPONSE=$(ask_ai "$PROMPT")
RC=$?
echo -e "  --> Nhan duoc!"
echo ""

# Kiem tra loi API
if [ $RC -ne 0 ]; then
    echo -e "${RED}  Loi: $AI_RESPONSE${NC}"
    echo -e "${YELLOW}  Kiem tra GROQ_API_KEY trong config.sh${NC}"
    exit 1
fi

# ============================================================
# BUOC 3: HIEN THI KET QUA TU GROQ AI
# ============================================================
CRON_EXPR=$(echo "$AI_RESPONSE" | grep "^CRON:"    | sed 's/CRON: //'    | tr -d '\r')
EXPLAIN=$(echo   "$AI_RESPONSE" | grep "^EXPLAIN:" | sed 's/EXPLAIN: //' | tr -d '\r')

# Fallback neu AI khong theo dung format
if [ -z "$CRON_EXPR" ]; then
    CRON_EXPR=$(echo "$AI_RESPONSE" | grep -oE '[*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+' | head -1)
fi

echo -e "${GREEN}========================================================"
echo -e "  Groq AI tra loi:"
echo -e "========================================================${NC}"
echo ""
echo -e "  Yeu cau    : ${YELLOW}\"$USER_REQUEST\"${NC}"
echo -e "  Script     : ${CYAN}$NAME${NC}"
echo -e "  Groq AI    : ${GREEN}$CRON_EXPR${NC}  -->  $EXPLAIN"
echo ""

# Hien thi bang phan tich cron
FIELDS=($CRON_EXPR)
echo    "  Phan tich cron expression:"
echo    "  +---------+------+-----+-------+---------+"
echo    "  | Minute  | Hour | Day | Month | Weekday |"
echo    "  +---------+------+-----+-------+---------+"
printf  "  | %-7s | %-4s | %-3s | %-5s | %-7s |\n" \
    "${FIELDS[0]:-?}" "${FIELDS[1]:-?}" "${FIELDS[2]:-?}" \
    "${FIELDS[3]:-?}" "${FIELDS[4]:-?}"
echo    "  +---------+------+-----+-------+---------+"
echo ""
echo -e "  Lenh se them vao crontab:"
echo -e "  ${YELLOW}$CRON_EXPR $SCRIPT >> $LOG_FILE 2>&1${NC}"
echo ""

# ============================================================
# BUOC 4: XAC NHAN VA THEM VAO CRONTAB
# ============================================================
echo -e "${CYAN}[BUOC 3] Xac nhan them vao Cron Scheduler:${NC}"
read -p "  Them vao crontab? (y/n): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    # Xoa job cu cua backup.sh neu co, roi them moi
    (crontab -l 2>/dev/null | grep -v "backup.sh"
     echo "$CRON_EXPR $SCRIPT >> $LOG_FILE 2>&1") | crontab -

    echo ""
    echo -e "${GREEN}  Da them vao Cron Scheduler thanh cong!${NC}"
    echo ""
    echo -e "${CYAN}  [ Crontab hien tai ]${NC}"
    echo "  $(crontab -l)"

    # Xac nhan crond dang chay
    echo ""
    if systemctl is-active --quiet crond; then
        echo -e "  crond: ${GREEN}dang chay -- cron job se duoc thuc thi dung lich${NC}"
    else
        echo -e "  crond: ${RED}chua chay -- khoi dong bang: sudo systemctl start crond${NC}"
    fi
else
    echo -e "  Huy. Khong thay doi crontab."
fi

echo ""
echo -e "${BLUE}========================================================${NC}"