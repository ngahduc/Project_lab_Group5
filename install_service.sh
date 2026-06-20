#!/bin/bash
# ============================================================
# install_service.sh
# Cai dat monitor.sh chay nhu mot systemd service, tu dong
# khoi dong cung may, lap lai kiem tra moi 60 giay.
# Chi can chay 1 LAN DUY NHAT.
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

USERNAME=$(whoami)
SERVICE_NAME="ai-monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CHECK_INTERVAL=60   # so giay giua moi lan monitor.sh kiem tra

echo -e "${CYAN}================================================"
echo "  Cai dat AI Monitor chay nen, tu khoi dong cung may"
echo -e "================================================${NC}"
echo ""

# -------------------------------------------------------
# BUOC 1: Luu GROQ_API_KEY ra file rieng
# (systemd KHONG doc duoc ~/.bashrc cua user)
# -------------------------------------------------------
echo -e "${YELLOW}[BUOC 1] Luu GROQ_API_KEY cho systemd su dung...${NC}"

if [ -z "$GROQ_API_KEY" ]; then
    echo -e "${RED}LOI: Khong tim thay GROQ_API_KEY trong shell hien tai.${NC}"
    echo "Chay: source ~/.bashrc   roi chay lai script nay."
    exit 1
fi

echo "GROQ_API_KEY=$GROQ_API_KEY" > "$HOME/ai_monitor/groq.env"
chmod 600 "$HOME/ai_monitor/groq.env"
echo -e "  ${GREEN}Da luu vao ~/ai_monitor/groq.env${NC}"

# -------------------------------------------------------
# BUOC 2: Tao file service tu template
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}[BUOC 2] Tao systemd service file...${NC}"

sed "s/__USERNAME__/$USERNAME/g; s/__INTERVAL__/$CHECK_INTERVAL/g" \
    "$HOME/ai_monitor/ai-monitor.service" | sudo tee "$SERVICE_FILE" > /dev/null

echo -e "  ${GREEN}Da tao: $SERVICE_FILE${NC}"
echo -e "  Chu ky kiem tra: moi ${CHECK_INTERVAL} giay"

# -------------------------------------------------------
# BUOC 3: Cho phep user chay sudo khong can mat khau
# cho dung cac lenh ma auto_fix.sh can dung khi tu sua loi
# (BAT BUOC vi service chay nen, khong co ai go mat khau)
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}[BUOC 3] Cau hinh sudo khong mat khau cho cac lenh fix...${NC}"

SUDOERS_FILE="/etc/sudoers.d/ai-monitor"
sudo tee "$SUDOERS_FILE" > /dev/null << EOF
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl restart httpd
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl start httpd
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl start firewalld
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl enable firewalld
$USERNAME ALL=(ALL) NOPASSWD: /bin/sync
$USERNAME ALL=(ALL) NOPASSWD: /sbin/sysctl -w vm.drop_caches=3
$USERNAME ALL=(ALL) NOPASSWD: /bin/journalctl --vacuum-time=7d
$USERNAME ALL=(ALL) NOPASSWD: /bin/dnf clean all
EOF

sudo chmod 440 "$SUDOERS_FILE"
echo -e "  ${GREEN}Da cau hinh: $SUDOERS_FILE${NC}"

# -------------------------------------------------------
# BUOC 4: Reload systemd, enable va start service
# -------------------------------------------------------
echo ""
echo -e "${YELLOW}[BUOC 4] Kich hoat service...${NC}"

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

sleep 2

echo ""
echo -e "${CYAN}================================================"
echo "  Trang thai service:"
echo -e "================================================${NC}"
sudo systemctl status "$SERVICE_NAME" --no-pager -l | head -15

echo ""
echo -e "${GREEN}Hoan tat! monitor.sh se tu dong chay khi khoi dong may.${NC}"
echo ""
echo "Cac lenh quan ly:"
echo "  sudo systemctl status ai-monitor     # xem trang thai"
echo "  sudo systemctl stop ai-monitor       # dung"
echo "  sudo systemctl restart ai-monitor    # khoi dong lai"
echo "  sudo systemctl disable ai-monitor    # tat tu khoi dong cung may"
echo "  journalctl -u ai-monitor -f          # xem log realtime (Ctrl+C de thoat)"
