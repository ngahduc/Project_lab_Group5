#!/bin/bash
# backup.sh - Data Backup (duoc len lich boi Topic 06)
source "$HOME/ai_monitor/config.sh"
LOG_FILE="${LOG_FILE:-/var/log/ai_monitor.log}"
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] [BACKUP] $1" | tee -a "$LOG_FILE"; }

mkdir -p "$DATA_DIR" "$BACKUP_DIR"
[ -z "$(ls -A $DATA_DIR 2>/dev/null)" ] && echo "Sample $(date)" > "$DATA_DIR/sample.txt"

log "===== BAT DAU BACKUP ====="
FILE="$BACKUP_DIR/backup_$(date '+%Y%m%d_%H%M%S').tar.gz"
if tar -czf "$FILE" -C "$(dirname $DATA_DIR)" "$(basename $DATA_DIR)" 2>/dev/null; then
    SIZE=$(du -sh "$FILE" | cut -f1)
    log "SUCCESS: $FILE ($SIZE)"
else
    log "ERROR: Backup that bai!"; exit 1
fi
COUNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)
[ "$COUNT" -gt 7 ] && ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -$((COUNT-7)) | xargs rm -f
log "===== BACKUP HOAN TAT ====="
ls -lh "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null
