#!/bin/bash
# ============================================================
# ask_ai.sh - Ham goi Groq API dung chung cho ca project
# Groq tuong thich OpenAI format, chi doi endpoint va model
# ============================================================

source "$HOME/ai_monitor/config.sh"

ask_ai() {
    local PROMPT="$1"

    # Kiem tra API key
    if [ -z "$GROQ_API_KEY" ] || [[ "$GROQ_API_KEY" == *"xxxxx"* ]]; then
        echo "LOI: Chua dat GROQ_API_KEY trong config.sh"
        echo "     Lay key tai: https://console.groq.com/keys"
        return 1
    fi

    # Escape ky tu dac biet trong prompt
    local ESCAPED=$(python3 -c "
import sys, json
text = sys.stdin.read()
print(json.dumps(text)[1:-1])
" <<< "$PROMPT")

    # Goi Groq API (tuong thich OpenAI format)
    local RAW=$(curl -s "$AI_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -d "{
            \"model\": \"$AI_MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$ESCAPED\"}],
            \"temperature\": 0.3,
            \"max_tokens\": 800
        }")

    # Kiem tra loi
    local ERR=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('error', {}).get('message', ''))
except:
    print('')
" <<< "$RAW")

    if [ -n "$ERR" ]; then
        echo "LOI GROQ API: $ERR"
        return 1
    fi

    # Lay noi dung tra loi
    python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d['choices'][0]['message']['content'].strip())
except Exception as e:
    print('Loi parse response: ' + str(e))
" <<< "$RAW"
}
