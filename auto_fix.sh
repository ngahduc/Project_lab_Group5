#!/bin/bash
# ============================================================
# auto_fix.sh
# Topic 17 <Chapter 12>: Learn and set up AI to automatically
#           resolve issues as they are detected
#
# LUONG:
#   Nhan danh sach loi tu monitor.sh
#   --> Goi Groq API: AI quyet dinh cach fix
#   --> Tu dong thuc thi cac lenh fix
#   --> Verify trang thai sau khi fix
#   --> Goi Groq API lan 2: AI danh gia ket qua
# ============================================================

source "$HOME/ai_monitor/ask_ai.sh"

RED='\033[0;31m';    GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m';   NC='\033[0m'

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] [AUTO_FIX] $1" | tee -a "$LOG_FILE"; }

ISSUES="${AI_ISSUES}"
FIX_RESULTS=""

[ -t 1 ] && clear
echo -e "${YELLOW}"
echo "================================================"
echo "  Topic 17: AI Automatically Resolves Issues"
echo "  AI Provider : Groq (llama-3.3-70b-versatile)"
echo "  $(timestamp)"
echo "================================================"
echo -e "${NC}"

echo -e "${YELLOW}  Van de nhan tu monitor.sh:${NC}"
echo "$ISSUES" | while IFS= read -r line; do
    [ -n "$line" ] && echo -e "    ${RED}• $line${NC}"
done
echo ""
log "===== BAT DAU TU DONG SUA LOI ====="

# ============================================================
# BUOC 1: HOI GROQ AI -- NEN XU LY NHU THE NAO?
# ============================================================
echo -e "${CYAN}[BUOC 1] Hoi Groq AI cach xu ly tung van de...${NC}"
echo -e "  Model: $AI_MODEL"
echo ""

PROMPT="You are an expert Linux system administrator AI on CentOS Stream 9.

The following issues were automatically detected:
${ISSUES}

For each detected issue, provide the fix plan in this EXACT format:
ISSUE: <issue name>
ACTION: <exact shell command to fix>
REASON: <why this fixes it, in Vietnamese>
---

Rules:
- APACHE_DOWN     --> sudo systemctl restart httpd
- MEM_HIGH        --> sudo sync && sudo sysctl -w vm.drop_caches=3
- DISK_HIGH       --> sudo journalctl --vacuum-time=7d && sudo dnf clean all
- FIREWALL_OFF    --> sudo systemctl start firewalld && sudo systemctl enable firewalld
- CPU_HIGH        --> ps aux --sort=-%cpu | head -10 (investigate only, do not kill)
- FAILED_LOGIN    --> sudo lastb | head -20 (report only, do not block)
- UPDATES         --> echo 'Run: sudo dnf update -y' (recommend only)

Only address the issues listed above. Do not add extra issues."

echo -e "  ${YELLOW}Dang cho Groq AI quyet dinh...${NC}"
AI_PLAN=$(ask_ai "$PROMPT")
RC=$?

if [ $RC -eq 0 ] && [ -n "$AI_PLAN" ]; then
    echo -e "${GREEN}  Groq AI quyet dinh:${NC}"
    echo ""
    echo "$AI_PLAN" | while IFS= read -r line; do
        echo "    $line"
    done
    log "GROQ_PLAN: $(echo "$AI_PLAN" | head -3 | tr '\n' ' ')"
else
    echo -e "  ${RED}Khong nhan duoc ke hoach tu AI, thuc thi mac dinh...${NC}"
fi
echo ""

# ============================================================
# BUOC 2: TU DONG THUC THI TUNG FIX
# ============================================================
echo -e "${CYAN}[BUOC 2] Tu dong thuc thi cac fix...${NC}"
echo ""

# --- FIX: APACHE DOWN --> RESTART SERVICE ---
if echo "$ISSUES" | grep -q "APACHE_DOWN"; then
    echo -e "${BLUE}  ┌─ [ACTION] Restart Service: httpd${NC}"
    log "ACTION: Restarting httpd..."

    sudo systemctl restart httpd
    sleep 3

    echo -e "${CYAN}  │  [ Verify Service State ]${NC}"
    if systemctl is-active --quiet httpd; then
        echo -e "  │  Apache: ${GREEN}active (running) ✓${NC}"
        log "SUCCESS: httpd --> active (running)"
        FIX_RESULTS="${FIX_RESULTS}\nAPACHE_FIX: SUCCESS - httpd active (running)"
    else
        echo -e "  │  Apache: ${RED}van con loi, thu start...${NC}"
        sudo systemctl start httpd; sleep 2
        if systemctl is-active --quiet httpd; then
            echo -e "  │  Apache: ${GREEN}active (running) ✓ (sau start)${NC}"
            log "SUCCESS: httpd started OK"
            FIX_RESULTS="${FIX_RESULTS}\nAPACHE_FIX: SUCCESS (start)"
        else
            echo -e "  │  Apache: ${RED}FAILED - can kiem tra thu cong ✗${NC}"
            log "FAILED: httpd khong khoi dong duoc"
            FIX_RESULTS="${FIX_RESULTS}\nAPACHE_FIX: FAILED - can kiem tra thu cong"
        fi
    fi
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# --- FIX: MEMORY CAO --> CLEAN RESOURCES ---
if echo "$ISSUES" | grep -q "MEM_HIGH"; then
    echo -e "${BLUE}  ┌─ [ACTION] Clean Resources: RAM Cache${NC}"
    MEM_BEFORE=$(free | awk '/Mem/{printf "%.0f", $3/$2*100}')
    log "ACTION: Clearing RAM cache (truoc: ${MEM_BEFORE}%)"

    sudo sync
    sudo sysctl -w vm.drop_caches=3 > /dev/null 2>&1
    sleep 1

    MEM_AFTER=$(free | awk '/Mem/{printf "%.0f", $3/$2*100}')
    echo -e "  │  RAM: ${MEM_BEFORE}% --> ${GREEN}${MEM_AFTER}% ✓${NC}"
    log "SUCCESS: RAM cleaned (${MEM_BEFORE}% --> ${MEM_AFTER}%)"
    FIX_RESULTS="${FIX_RESULTS}\nMEM_FIX: SUCCESS (${MEM_BEFORE}% --> ${MEM_AFTER}%)"
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# --- FIX: DISK CAO --> CLEAN RESOURCES ---
if echo "$ISSUES" | grep -q "DISK_HIGH"; then
    echo -e "${BLUE}  ┌─ [ACTION] Clean Resources: Disk${NC}"
    DISK_BEFORE=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    log "ACTION: Cleaning disk (truoc: ${DISK_BEFORE}%)"

    sudo find /var/log -name "*.gz" -mtime +7 -delete 2>/dev/null
    sudo find /tmp -type f -mtime +3 -delete 2>/dev/null
    sudo journalctl --vacuum-time=7d > /dev/null 2>&1
    sudo dnf clean all > /dev/null 2>&1

    DISK_AFTER=$(df / | awk 'NR==2{print $5}' | tr -d '%')
    echo -e "  │  Disk: ${DISK_BEFORE}% --> ${GREEN}${DISK_AFTER}% ✓${NC}"
    log "SUCCESS: Disk cleaned (${DISK_BEFORE}% --> ${DISK_AFTER}%)"
    FIX_RESULTS="${FIX_RESULTS}\nDISK_FIX: SUCCESS (${DISK_BEFORE}% --> ${DISK_AFTER}%)"
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# --- FIX: FIREWALL TAT --> BAT FIREWALLD ---
if echo "$ISSUES" | grep -q "FIREWALL_OFF"; then
    echo -e "${BLUE}  ┌─ [ACTION] Start Firewalld${NC}"
    sudo systemctl start firewalld && sudo systemctl enable firewalld
    sleep 2
    if systemctl is-active --quiet firewalld; then
        echo -e "  │  Firewalld: ${GREEN}active (running) ✓${NC}"
        log "SUCCESS: firewalld started"
        FIX_RESULTS="${FIX_RESULTS}\nFIREWALL_FIX: SUCCESS"
    fi
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# --- FIX: CPU CAO --> INVESTIGATE ---
if echo "$ISSUES" | grep -q "CPU_HIGH"; then
    echo -e "${BLUE}  ┌─ [ACTION] Investigate CPU cao${NC}"
    echo -e "  │  Top 5 processes dung CPU nhieu nhat:"
    ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {
        printf "  │    %-22s CPU:%-5s MEM:%-5s PID:%s\n",$11,$3"%",$4"%",$2
    }' | tee -a "$LOG_FILE"
    FIX_RESULTS="${FIX_RESULTS}\nCPU_FIX: INVESTIGATED - can kiem tra thu cong"
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# --- FIX: UPDATES ---
if echo "$ISSUES" | grep -q "UPDATES"; then
    UPDATE_COUNT=$(echo "$ISSUES" | grep "UPDATES" | cut -d':' -f2)
    echo -e "${BLUE}  ┌─ [ACTION] System Updates: ${UPDATE_COUNT} goi${NC}"
    echo -e "  │  ${YELLOW}De tranh loi, khong tu dong update.${NC}"
    echo -e "  │  Chay thu cong: ${CYAN}sudo dnf update -y${NC}"
    log "INFO: Can update $UPDATE_COUNT goi - chay thu cong"
    FIX_RESULTS="${FIX_RESULTS}\nUPDATE_FIX: PENDING - chay thu cong: sudo dnf update -y"
    echo -e "${BLUE}  └─ Xong${NC}"
    echo ""
fi

# ============================================================
# BUOC 3: GROQ AI DANH GIA KET QUA TONG THE
# ============================================================
echo -e "${CYAN}[BUOC 3] Gui ket qua cho Groq AI danh gia...${NC}"
echo ""

# Lay trang thai hien tai sau khi fix
CURRENT_APACHE=$(systemctl is-active httpd 2>/dev/null || echo "unknown")
CURRENT_MEM=$(free | awk '/Mem/{printf "%.0f%%", $3/$2*100}')
CURRENT_DISK=$(df / | awk 'NR==2{print $5}')
CURRENT_FW=$(systemctl is-active firewalld 2>/dev/null || echo "unknown")

FINAL_PROMPT="You are a Linux system administrator AI reviewing the self-healing results on CentOS Stream 9.

ORIGINAL ISSUES DETECTED:
${ISSUES}

FIX RESULTS SUMMARY:
$(echo -e "$FIX_RESULTS")

CURRENT SYSTEM STATE (after fixes):
- Apache httpd : ${CURRENT_APACHE}
- Memory usage : ${CURRENT_MEM}
- Disk usage   : ${CURRENT_DISK}
- Firewalld    : ${CURRENT_FW}
- Timestamp    : $(timestamp)

Please provide a brief final report in Vietnamese with:
1. TONG KET: Da giai quyet duoc bao nhieu % van de?
2. KET QUA TUNG LOI: Trang thai cua tung fix (thanh cong / that bai)
3. KHUYEN NGHI TIEP THEO: Admin can lam gi them khong?"

echo -e "  ${YELLOW}Dang cho Groq AI danh gia ket qua...${NC}"
AI_FINAL=$(ask_ai "$FINAL_PROMPT")

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Groq AI - Danh gia ket qua tu dong fix:${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
if [ -n "$AI_FINAL" ]; then
    echo "$AI_FINAL" | while IFS= read -r line; do
        echo "  $line"
    done
    log "GROQ_FINAL: $(echo "$AI_FINAL" | head -1)"
else
    echo -e "  ${RED}Khong nhan duoc danh gia tu AI${NC}"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Self-Healing hoan tat: $(timestamp)${NC}"
echo -e "${GREEN}================================================${NC}"
log "===== TU DONG SUA LOI HOAN TAT ====="
