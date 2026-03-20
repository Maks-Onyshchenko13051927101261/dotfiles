#!/bin/bash

# 1. ПІДКЛЮЧАЄМО КОНФІГ ТА МОДУЛІ (Наш "Import" блок)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.conf"
source "$DIR/modules/weather.sh"
source "$DIR/modules/windows_os.sh"
source "$DIR/modules/network.sh"
source "$DIR/modules/speedtest.sh"
source "$DIR/modules/ui_draw.sh"

# Скидаємо старий спідтест при кожному новому запуску скрипта
reset_speed_cache

# 2. ПІДГОТОВКА СЕРЕДОВИЩА
tput civis
trap "tput cnorm; clear; exit" INT TERM
clear
echo "Initializing ZEN engine..."

# Початкові дані для мережі
NET_START=$(get_net_data)
A_RX=$(echo "$NET_START" | cut -d'|' -f1); A_TX=$(echo "$NET_START" | cut -d'|' -f2)
MAX_RX=0; MAX_TX=0

while true; do
    # Оновлюємо погоду (функція з модуля weather.sh)
    get_weather > /dev/null 

    # Опитування Windows (раз на 10 сек)
    if (( SECONDS % 10 == 0 || SECONDS < 2 )); then
        W_DATA=$(get_windows_stats)
        W_USED_KB=$(echo "$W_DATA" | cut -d'|' -f1)
        W_TOTAL_GB_RAM=$(echo "$W_DATA" | cut -d'|' -f2)
        W_TOP_PROC=$(echo "$W_DATA" | cut -d'|' -f3)
        W_SSD_FREE=$(echo "$W_DATA" | cut -d'|' -f4)
        W_SSD_PCT=$(echo "$W_DATA" | cut -d'|' -f5)
        W_TOTAL_CPU=$(echo "$W_DATA" | cut -d'|' -f6)
        
        [[ -n "$W_USED_KB" ]] && WIN_RAM_STR="$((W_USED_KB / 1024 / 1024))/${W_TOTAL_GB_RAM}GB" || WIN_RAM_STR="Sync..."
    fi

    # --- (Рендеринг) ---
    tput cup 0 0
    draw_header

    # Блок Температури
    LATEST_LOG=$(ls -t "$CORE_TEMP_PATH"/CT-Log*.csv 2>/dev/null | head -n 1)
    TEMP="??"
    [ -n "$LATEST_LOG" ] && VAL=$(tail -n 1 "$LATEST_LOG" | awk -F',' '{print $4}' | tr -d ' ') && TEMP=$((VAL/1000))
    
    T_COLOR=$COLOR_GREEN
    (( TEMP > 65 )) && T_COLOR=$COLOR_YELLOW
    (( TEMP > 80 )) && T_COLOR=$COLOR_RED
    echo -e "🌡️  Hardware: ${T_COLOR}${TEMP}°C${COLOR_RESET}\033[K"
    draw_line

    # Блок Ресурсів
    LNX_LOAD=$(uptime | awk -F'average:' '{print $2}' | tr -d ' ' | cut -d',' -f1)
    echo -e "🧠 CPU Total: ${COLOR_PURPLE}${W_TOTAL_CPU:-0}%${COLOR_RESET} (Lnx: $LNX_LOAD)\033[K"
    echo -e "💾 WSL RAM:   $(free -m | awk '/Mem:/ {printf "%d/%dMB", $3, $2}')\033[K"
    echo -e "🪟 Win RAM:   ${COLOR_CYAN}$WIN_RAM_STR${COLOR_RESET}\033[K"
    draw_line

    # Блок SSD
    SSD_COLOR=$COLOR_GREEN; (( W_SSD_PCT > 85 )) && SSD_COLOR=$COLOR_RED
    echo -e "💽 SSD (C:):  ${SSD_COLOR}${W_SSD_FREE} GB Free${COLOR_RESET} (${W_SSD_PCT}% Used)\033[K"
    draw_line

    # Блок Процесів
    echo -e "🔥 TOP PROCESSES:\033[K"
    echo -e "   🪟 Win: ${COLOR_YELLOW}${W_TOP_PROC:-Sync...}${COLOR_RESET}\033[K"
    echo -ne "   🐧 Lnx: " && ps -eo comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{printf "%-12s %s%%\n", $1, $2}'
    draw_line

    # --- БЛОК МЕРЕЖІ ---
    NET_NOW=$(get_net_data)
    B_RX=$(echo "$NET_NOW" | cut -d'|' -f1); B_TX=$(echo "$NET_NOW" | cut -d'|' -f2)
    D_RX=$((B_RX - A_RX)); D_TX=$((B_TX - A_TX)); A_RX=$B_RX; A_TX=$B_TX
    [ "$D_RX" -gt "$MAX_RX" ] && MAX_RX=$D_RX; [ "$D_TX" -gt "$MAX_TX" ] && MAX_TX=$D_TX

    # 🏅 MAX
    echo -ne "🏅 MAX   ⬇ " && format_speed $MAX_RX
    echo -ne "  |  ⬆ " && format_speed $MAX_TX
    echo -e "          \033[K"
    
    echo -e "${COLOR_RESET}==============================\033[K"
    
    # 🚀 LIVE
    echo -ne "🚀 LIVE  ⬇ " && format_speed $D_RX
    echo -ne "  |  ⬆ " && format_speed $D_TX
    echo -e "          \033[K"
    
    draw_line

    # 🏁 FACT
    echo -ne "🏁 FACT  " && get_speed_data
    echo -e "\033[K"

    sleep 1
done
