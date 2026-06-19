#!/bin/bash
# ============================================================
# setup_cron.sh
# Topic 06: Leveraging AI Chatbots for Scheduling Processes
#
# Nguoi dung tu nhap: gio, phut, tan suat
# --> Groq AI sinh cron expression chinh xac
# --> Tu dong them vao crontab
# ============================================================

source "$HOME/ai_monitor/ask_ai.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] [TOPIC06] $1" | tee -a "$LOG_FILE"; }

clear
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║  TOPIC 06: AI Chatbot Scheduling                    ║"
echo "║  Groq AI (llama-3.3-70b-versatile)                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# BUOC 1: CHON SCRIPT CAN LEN LICH
# ============================================================
echo -e "${CYAN}[BUOC 1] Chon script can len lich:${NC}"
echo ""
echo "  1) backup.sh   - Sao luu du lieu"
echo "  2) monitor.sh  - Giam sat he thong"
echo "  3) auto_fix.sh - Tu dong sua loi"
echo ""
read -p "  Chon (1-3): " SCRIPT_CHOICE

case $SCRIPT_CHOICE in
    1) SCRIPT_NAME="backup.sh";   SCRIPT_PATH="$HOME/ai_monitor/backup.sh" ;;
    2) SCRIPT_NAME="monitor.sh";  SCRIPT_PATH="$HOME/ai_monitor/monitor.sh" ;;
    3) SCRIPT_NAME="auto_fix.sh"; SCRIPT_PATH="$HOME/ai_monitor/auto_fix.sh" ;;
    *)
        echo -e "${RED}  Lua chon khong hop le.${NC}"
        exit 1
        ;;
esac

echo -e "  Da chon: ${GREEN}${SCRIPT_NAME}${NC}"

# ============================================================
# BUOC 2: NGUOI DUNG NHAP TAN SUAT
# ============================================================
echo ""
echo -e "${CYAN}[BUOC 2] Chon tan suat chay:${NC}"
echo ""
echo "  1) Moi ngay      (nhap gio va phut)"
echo "  2) Moi tuan      (nhap thu, gio, phut)"
echo "  3) Moi thang     (nhap ngay, gio, phut)"
echo "  4) Moi X phut    (nhap so phut)"
echo "  5) Moi gio       (nhap phut trong gio)"
echo ""
read -p "  Chon (1-5): " FREQ_CHOICE

case $FREQ_CHOICE in

1)
    echo ""
    echo -e "${CYAN}  Nhap thoi gian chay moi ngay:${NC}"
    while true; do
        read -p "  Gio  (0-23): " INPUT_HOUR
        [[ "$INPUT_HOUR" =~ ^[0-9]+$ ]] && [ "$INPUT_HOUR" -ge 0 ] && [ "$INPUT_HOUR" -le 23 ] && break
        echo -e "  ${RED}Gio khong hop le, nhap lai (0-23)${NC}"
    done
    while true; do
        read -p "  Phut (0-59): " INPUT_MIN
        [[ "$INPUT_MIN" =~ ^[0-9]+$ ]] && [ "$INPUT_MIN" -ge 0 ] && [ "$INPUT_MIN" -le 59 ] && break
        echo -e "  ${RED}Phut khong hop le, nhap lai (0-59)${NC}"
    done
    USER_DESC="Run ${SCRIPT_NAME} every day at ${INPUT_HOUR}:$(printf '%02d' $INPUT_MIN)"
    ;;

2)
    echo ""
    echo -e "${CYAN}  Nhap lich chay moi tuan:${NC}"
    echo "  Thu: 1=Thu Hai, 2=Thu Ba, 3=Thu Tu, 4=Thu Nam,"
    echo "       5=Thu Sau, 6=Thu Bay, 0=Chu Nhat"
    while true; do
        read -p "  Thu  (0-6): " INPUT_DOW
        [[ "$INPUT_DOW" =~ ^[0-6]$ ]] && break
        echo -e "  ${RED}Thu khong hop le, nhap lai (0-6)${NC}"
    done
    while true; do
        read -p "  Gio  (0-23): " INPUT_HOUR
        [[ "$INPUT_HOUR" =~ ^[0-9]+$ ]] && [ "$INPUT_HOUR" -ge 0 ] && [ "$INPUT_HOUR" -le 23 ] && break
        echo -e "  ${RED}Gio khong hop le, nhap lai (0-23)${NC}"
    done
    while true; do
        read -p "  Phut (0-59): " INPUT_MIN
        [[ "$INPUT_MIN" =~ ^[0-9]+$ ]] && [ "$INPUT_MIN" -ge 0 ] && [ "$INPUT_MIN" -le 59 ] && break
        echo -e "  ${RED}Phut khong hop le, nhap lai (0-59)${NC}"
    done
    DOW_NAMES=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday")
    USER_DESC="Run ${SCRIPT_NAME} every ${DOW_NAMES[$INPUT_DOW]} at ${INPUT_HOUR}:$(printf '%02d' $INPUT_MIN)"
    ;;

3)
    echo ""
    echo -e "${CYAN}  Nhap lich chay moi thang:${NC}"
    while true; do
        read -p "  Ngay trong thang (1-28): " INPUT_DOM
        [[ "$INPUT_DOM" =~ ^[0-9]+$ ]] && [ "$INPUT_DOM" -ge 1 ] && [ "$INPUT_DOM" -le 28 ] && break
        echo -e "  ${RED}Ngay khong hop le, nhap lai (1-28)${NC}"
    done
    while true; do
        read -p "  Gio  (0-23): " INPUT_HOUR
        [[ "$INPUT_HOUR" =~ ^[0-9]+$ ]] && [ "$INPUT_HOUR" -ge 0 ] && [ "$INPUT_HOUR" -le 23 ] && break
        echo -e "  ${RED}Gio khong hop le, nhap lai (0-23)${NC}"
    done
    while true; do
        read -p "  Phut (0-59): " INPUT_MIN
        [[ "$INPUT_MIN" =~ ^[0-9]+$ ]] && [ "$INPUT_MIN" -ge 0 ] && [ "$INPUT_MIN" -le 59 ] && break
        echo -e "  ${RED}Phut khong hop le, nhap lai (0-59)${NC}"
    done
    USER_DESC="Run ${SCRIPT_NAME} on day ${INPUT_DOM} of every month at ${INPUT_HOUR}:$(printf '%02d' $INPUT_MIN)"
    ;;

4)
    echo ""
    echo -e "${CYAN}  Nhap so phut giua moi lan chay:${NC}"
    while true; do
        read -p "  Moi bao nhieu phut (1-59): " INPUT_INTERVAL
        [[ "$INPUT_INTERVAL" =~ ^[0-9]+$ ]] && [ "$INPUT_INTERVAL" -ge 1 ] && [ "$INPUT_INTERVAL" -le 59 ] && break
        echo -e "  ${RED}Gia tri khong hop le, nhap lai (1-59)${NC}"
    done
    USER_DESC="Run ${SCRIPT_NAME} every ${INPUT_INTERVAL} minutes"
    ;;

5)
    echo ""
    echo -e "${CYAN}  Moi gio, chay vao phut thu may?${NC}"
    while true; do
        read -p "  Phut trong gio (0-59): " INPUT_MIN
        [[ "$INPUT_MIN" =~ ^[0-9]+$ ]] && [ "$INPUT_MIN" -ge 0 ] && [ "$INPUT_MIN" -le 59 ] && break
        echo -e "  ${RED}Phut khong hop le, nhap lai (0-59)${NC}"
    done
    USER_DESC="Run ${SCRIPT_NAME} every hour at minute ${INPUT_MIN}"
    ;;

*)
    echo -e "${RED}  Lua chon khong hop le.${NC}"
    exit 1
    ;;
esac

# ============================================================
# BUOC 3: GOI GROQ AI SINH CRON EXPRESSION
# ============================================================
echo ""
echo -e "${CYAN}[BUOC 3] Dang gui yeu cau den Groq AI...${NC}"
echo -e "  Yeu cau: ${YELLOW}\"${USER_DESC}\"${NC}"
echo ""

PROMPT="You are a Linux cron job expert.
Script to schedule: ${SCRIPT_NAME}
User request: \"${USER_DESC}\"

Reply in EXACTLY this format (2 lines only, nothing else):
CRON: <5-field cron expression>
EXPLAIN: <Vietnamese explanation of the schedule>"

echo -ne "  Dang cho Groq AI..."
AI_RESPONSE=$(ask_ai "$PROMPT")
RC=$?
echo -e " ${GREEN}Nhan duoc!${NC}"

if [ $RC -ne 0 ]; then
    echo -e "${RED}  Loi API: $AI_RESPONSE${NC}"
    echo -e "${YELLOW}  Kiem tra GROQ_API_KEY: source ~/.bashrc${NC}"
    exit 1
fi

CRON_EXPR=$(echo "$AI_RESPONSE" | grep "^CRON:"    | sed 's/CRON: //'    | tr -d '\r')
EXPLAIN=$(echo   "$AI_RESPONSE" | grep "^EXPLAIN:" | sed 's/EXPLAIN: //' | tr -d '\r')

[ -z "$CRON_EXPR" ] && \
    CRON_EXPR=$(echo "$AI_RESPONSE" | grep -oE '[*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+ [*0-9/,-]+' | head -1)

# ============================================================
# BUOC 4: HIEN THI KET QUA
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗"
echo -e "║  Groq AI tra loi:                                    ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Script    : ${CYAN}${SCRIPT_NAME}${NC}"
echo -e "  Yeu cau   : ${YELLOW}\"${USER_DESC}\"${NC}"
echo -e "  Cron      : ${GREEN}${CRON_EXPR}${NC}"
echo -e "  Y nghia   : ${EXPLAIN}"
echo ""

FIELDS=($CRON_EXPR)
echo    "  Phan tich cron expression:"
echo    "  +---------+--------+-------+-------+-----------+"
echo    "  | Minute  | Hour   | Day   | Month | Weekday   |"
echo    "  +---------+--------+-------+-------+-----------+"
printf  "  | %-7s | %-6s | %-5s | %-5s | %-9s |\n" \
    "${FIELDS[0]:-?}" "${FIELDS[1]:-?}" "${FIELDS[2]:-?}" \
    "${FIELDS[3]:-?}" "${FIELDS[4]:-?}"
echo    "  +---------+--------+-------+-------+-----------+"
echo ""
echo -e "  Lenh day du:"
echo -e "  ${YELLOW}${CRON_EXPR} ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1${NC}"

# ============================================================
# BUOC 5: XAC NHAN THEM VAO CRONTAB
# ============================================================
echo ""
echo -e "${CYAN}[BUOC 4] Xac nhan:${NC}"
read -p "  Them vao crontab? (y/n): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_NAME"
     echo "$CRON_EXPR $SCRIPT_PATH >> $LOG_FILE 2>&1") | crontab -

    echo ""
    echo -e "${GREEN}  Da them vao Cron Scheduler!${NC}"
    echo ""
    echo -e "${CYAN}  Crontab hien tai:${NC}"
    crontab -l | while IFS= read -r line; do
        echo -e "  ${GREEN}${line}${NC}"
    done

    if systemctl is-active --quiet crond 2>/dev/null; then
        echo ""
        echo -e "  crond: ${GREEN}dang chay -- job se duoc thuc thi dung lich${NC}"
    else
        echo ""
        echo -e "  ${RED}crond chua chay! Khoi dong bang:${NC}"
        echo -e "  sudo systemctl start crond"
    fi

    log "Cron job da tao: ${CRON_EXPR} ${SCRIPT_PATH}"
else
    echo -e "  Huy. Khong thay doi crontab."
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
