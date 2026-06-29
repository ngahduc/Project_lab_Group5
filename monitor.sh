#!/bin/bash
source "$HOME/ai_monitor/ask_ai.sh"

HEAL="$HOME/ai_monitor/auto_fix.sh"
ISSUES_FILE="/tmp/ai_issues_$$.tmp"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ALERT_CPU=80
ALERT_MEM=85
ALERT_DISK=90

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] [MONITOR] $1" | tee -a "$LOG_FILE"; }

rm -f "$ISSUES_FILE"
[ -t 1 ] && clear

echo -e "${BLUE}"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "================================================"
echo "  Topic 14: AI-Powered Linux Monitoring"
echo "  System Performance | Security | Updates"
echo "  AI: Groq llama-3.3-70b-versatile"
echo "  $(timestamp)"
echo "================================================"
echo -e "${NC}"

echo -e "${CYAN}[1/3] Thu thap thong tin he thong...${NC}"
echo ""

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' | cut -d'.' -f1)
if [ -z "$CPU" ]; then
    CPU=$(vmstat 1 1 | tail -1 | awk '{print 100-$15}')
fi
CPU=${CPU:-0}

MEM_TOTAL=$(free -m | awk '/Mem/{print $2}')
MEM_USED=$(free -m  | awk '/Mem/{print $3}')
MEM_PCT=$(free      | awk '/Mem/{printf "%.0f", $3/$2*100}')
MEM_PCT=${MEM_PCT:-0}

DISK_PCT=$(df / | awk 'NR==2{print $5}' | tr -d '%')
DISK_AVAIL=$(df -h / | awk 'NR==2{print $4}')
DISK_PCT=${DISK_PCT:-0}

LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)

if systemctl is-active --quiet httpd 2>/dev/null; then
    APACHE_STATUS="active (running)"
    APACHE_FLAG="OK"
else
    APACHE_STATUS="inactive / stopped"
    APACHE_FLAG="DOWN"
    echo "APACHE_DOWN" >> "$ISSUES_FILE"
fi

echo -e "  ${BLUE}[ System Performance ]${NC}"

if [ "$CPU" -gt "$ALERT_CPU" ] 2>/dev/null; then
    echo -e "  CPU Usage    : ${RED}${CPU}%  CANH BAO (> ${ALERT_CPU}%)${NC}"
    log "ALERT: CPU cao: ${CPU}%"
    echo "CPU_HIGH:${CPU}" >> "$ISSUES_FILE"
else
    echo -e "  CPU Usage    : ${GREEN}${CPU}%  OK${NC}"
    log "OK: CPU=${CPU}%"
fi

if [ "$MEM_PCT" -gt "$ALERT_MEM" ] 2>/dev/null; then
    echo -e "  Memory Usage : ${RED}${MEM_PCT}% (${MEM_USED}MB/${MEM_TOTAL}MB)  CANH BAO${NC}"
    log "ALERT: Memory cao: ${MEM_PCT}%"
    echo "MEM_HIGH:${MEM_PCT}" >> "$ISSUES_FILE"
else
    echo -e "  Memory Usage : ${GREEN}${MEM_PCT}% (${MEM_USED}MB/${MEM_TOTAL}MB)  OK${NC}"
    log "OK: Memory=${MEM_PCT}%"
fi

if [ "$DISK_PCT" -gt "$ALERT_DISK" ] 2>/dev/null; then
    echo -e "  Disk (/)     : ${RED}${DISK_PCT}% (con ${DISK_AVAIL})  CANH BAO${NC}"
    log "ALERT: Disk cao: ${DISK_PCT}%"
    echo "DISK_HIGH:${DISK_PCT}" >> "$ISSUES_FILE"
else
    echo -e "  Disk (/)     : ${GREEN}${DISK_PCT}% (con ${DISK_AVAIL})  OK${NC}"
    log "OK: Disk=${DISK_PCT}%"
fi

echo -e "  Load Average : $LOAD"

if [ "$APACHE_FLAG" = "OK" ]; then
    echo -e "  Apache httpd : ${GREEN}${APACHE_STATUS}${NC}"
else
    echo -e "  Apache httpd : ${RED}${APACHE_STATUS}${NC}"
fi

echo ""
echo -e "  ${BLUE}[ Security Issues ]${NC}"
FAILED_LOGIN=$(lastb 2>/dev/null | grep -c "." 2>/dev/null)
FAILED_LOGIN=${FAILED_LOGIN//[^0-9]/}
FAILED_LOGIN=${FAILED_LOGIN:-0}

if [ "$FAILED_LOGIN" -gt 10 ]; then
    echo -e "  Failed Login : ${RED}${FAILED_LOGIN} lan  CANH BAO${NC}"
    log "ALERT: Failed login: ${FAILED_LOGIN}"
    echo "FAILED_LOGIN:${FAILED_LOGIN}" >> "$ISSUES_FILE"
else
    echo -e "  Failed Login : ${GREEN}${FAILED_LOGIN} lan  OK${NC}"
fi

if systemctl is-active --quiet firewalld 2>/dev/null; then
    echo -e "  Firewalld    : ${GREEN}active  OK${NC}"
else
    echo -e "  Firewalld    : ${RED}inactive  CANH BAO${NC}"
    echo "FIREWALL_OFF" >> "$ISSUES_FILE"
fi

SELINUX=$(getenforce 2>/dev/null || echo "Unknown")
if [ "$SELINUX" = "Enforcing" ]; then
    echo -e "  SELinux      : ${GREEN}Enforcing  OK${NC}"
else
    echo -e "  SELinux      : ${YELLOW}${SELINUX}  CHU Y${NC}"
fi

echo ""
echo -e "  ${BLUE}[ Update Issues ]${NC}"
echo -e "  ${YELLOW}Dang kiem tra cap nhat...${NC}"
UPDATE_COUNT=$(dnf check-update --refresh 2>/dev/null | grep -v "kB/s" | grep -cP "^\S+\s+\S+\s+\S+")
UPDATE_COUNT=${UPDATE_COUNT//[^0-9]/}
UPDATE_COUNT=${UPDATE_COUNT:-0}

if [ "$UPDATE_COUNT" -gt 0 ]; then
    echo -e "  Packages     : ${YELLOW}Co ${UPDATE_COUNT} goi can cap nhat${NC}"
    log "INFO: $UPDATE_COUNT goi can update"
    echo "UPDATES:${UPDATE_COUNT}" >> "$ISSUES_FILE"
else
    echo -e "  Packages     : ${GREEN}He thong da cap nhat day du  OK${NC}"
fi

echo ""
echo -e "${CYAN}[2/3] Dang gui du lieu cho Groq AI phan tich...${NC}"
echo ""

ISSUES_DATA=$(cat "$ISSUES_FILE" 2>/dev/null || echo "none")

PROMPT="You are an expert Linux system administrator AI assistant.

Analyze the following real-time data from a CentOS Stream 9 server:

Timestamp: $(timestamp)
Hostname: $(hostname)
CPU Usage: ${CPU}% (alert: ${ALERT_CPU}%)
Memory: ${MEM_PCT}% used (${MEM_USED}MB/${MEM_TOTAL}MB) (alert: ${ALERT_MEM}%)
Disk: ${DISK_PCT}% used, ${DISK_AVAIL} free (alert: ${ALERT_DISK}%)
Load Average: ${LOAD}
Apache httpd: ${APACHE_STATUS}
Failed logins: ${FAILED_LOGIN}
Firewalld: $(systemctl is-active firewalld 2>/dev/null || echo unknown)
SELinux: ${SELINUX}
Packages to update: ${UPDATE_COUNT}
Detected issues: ${ISSUES_DATA}

Reply in Vietnamese with:
1. TRANG THAI TONG THE: (OK / CANH BAO / NGUY HIEM)
2. PHAN TICH HIEU NANG: nhan xet CPU, RAM, Disk, Apache
3. PHAN TICH BAO MAT: nhan xet firewall, login, SELinux
4. PHAN TICH CAP NHAT: nhan xet packages
5. KHUYEN NGHI: hanh dong cu the can thuc hien"

AI_ANALYSIS=$(ask_ai "$PROMPT")
RC=$?

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Groq AI - Ket qua phan tich:${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

if [ $RC -eq 0 ] && [ -n "$AI_ANALYSIS" ]; then
    echo "$AI_ANALYSIS" | while IFS= read -r line; do
        echo "  $line"
    done
    log "AI: $(echo "$AI_ANALYSIS" | head -1)"
else
    echo -e "  ${RED}Khong ket noi duoc Groq API.${NC}"
    echo -e "  ${YELLOW}Chay: source ~/.bashrc roi thu lai${NC}"
fi

echo ""
echo -e "${BLUE}================================================${NC}"

echo -e "${CYAN}[3/3] Danh gia...${NC}"

if [ -s "$ISSUES_FILE" ]; then
    echo ""
    echo -e "${RED}  Issue Detected? --> YES${NC}"
    echo -e "${YELLOW}  Dang goi auto_fix.sh...${NC}"
    log "TRIGGER: Phat hien van de, goi auto_fix.sh"
    export AI_ISSUES=$(cat "$ISSUES_FILE")
    bash "$HEAL"
else
    echo ""
    echo -e "${GREEN}  Issue Detected? --> NO${NC}"
    echo -e "${GREEN}  --> Continue Monitoring...${NC}"
    log "OK: He thong binh thuong"
fi

rm -f "$ISSUES_FILE"
log "===== KET THUC MONITORING ====="
