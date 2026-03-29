#!/bin/bash

# 1. ПІДКЛЮЧАЄМО КОНФІГ ТА МОДУЛІ
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/config.conf"
source "$DIR/modules/weather.sh"
source "$DIR/modules/windows_os.sh"
source "$DIR/modules/network.sh"
source "$DIR/modules/speedtest.sh"
source "$DIR/modules/ui_draw.sh"

reset_speed_cache

# 2. ПІДГОТОВКА СЕРЕДОВИЩА
tput civis
trap "tput cnorm; clear; exit" INT TERM
clear
echo "Initializing ZEN engine..."

NET_START=$(get_net_data)
A_RX=$(echo "$NET_START" | cut -d'|' -f1); A_TX=$(echo "$NET_START" | cut -d'|' -f2)
MAX_RX=0; MAX_TX=0

while true; do
    get_weather > /dev/null 2>&1

    # Опитування Windows (раз на 10 сек)
    if (( SECONDS % 10 == 0 || SECONDS < 2 )); then
        W_DATA=$(get_windows_stats)

        # Розпаковка даних з модуля
        W_USED_GB=$(echo "$W_DATA" | cut -d'|' -f1)
        W_TOTAL_GB=$(echo "$W_DATA" | cut -d'|' -f2)
        W_TOP_PROC=$(echo "$W_DATA" | cut -d'|' -f3)
        W_TOTAL_CPU=$(echo "$W_DATA" | cut -d'|' -f4)
        W_SSD_FREE=$(echo "$W_DATA" | cut -d'|' -f5)
        W_SSD_PCT=$(echo "$W_DATA" | cut -d'|' -f6)
        W_HEALTH=$(echo "$W_DATA" | cut -d'|' -f7)

        # 🧠 CPU Колір
        CPU_COLOR=$COLOR_GREEN
        [[ -n "$W_TOTAL_CPU" ]] && (( W_TOTAL_CPU > 50 )) && CPU_COLOR=$COLOR_YELLOW
        [[ -n "$W_TOTAL_CPU" ]] && (( W_TOTAL_CPU > 85 )) && CPU_COLOR=$COLOR_RED
        W_CPU_STR="${CPU_COLOR}${W_TOTAL_CPU:-0}%${COLOR_RESET}"

        # 💾 RAM Колір (якщо більше 90% зайнято - червоний)
        if [[ -n "$W_USED_GB" && "$W_TOTAL_GB" != "0" ]]; then
            RAM_COLOR=$COLOR_CYAN
            RAM_USAGE=$(( W_USED_GB * 100 / W_TOTAL_GB ))
            (( RAM_USAGE > 90 )) && RAM_COLOR=$COLOR_RED
            WIN_RAM_STR="${RAM_COLOR}${W_USED_GB}/${W_TOTAL_GB}GB${COLOR_RESET}"
        else
            WIN_RAM_STR="${COLOR_YELLOW}Sync...${COLOR_RESET}"
        fi

        # 💽 SSD Колір
        SSD_COLOR=$COLOR_WHITE
        [[ -n "$W_SSD_PCT" ]] && (( W_SSD_PCT > 80 )) && SSD_COLOR=$COLOR_YELLOW
        [[ -n "$W_SSD_PCT" ]] && (( W_SSD_PCT > 95 )) && SSD_COLOR=$COLOR_RED
        W_SSD_STR="${SSD_COLOR}${W_SSD_FREE:-0} GB Free (${W_SSD_PCT:-0}% Used)${COLOR_RESET}"

        # 🩺 Status Колір
        HEALTH_COLOR=$COLOR_GREEN
        [[ "$W_HEALTH" != "Healthy" ]] && HEALTH_COLOR=$COLOR_YELLOW
        [[ "$W_HEALTH" == "Unhealthy" || "$W_HEALTH" == "Warning" ]] && HEALTH_COLOR=$COLOR_RED
        W_HEALTH_STR="${HEALTH_COLOR}${W_HEALTH:-Sync...}${COLOR_RESET}"

        # 🔥 Top Process Колір
        W_TOP_STR="${COLOR_CYAN}${W_TOP_PROC:-None}${COLOR_RESET}"
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
    CPU_VAL=$(printf "%3d" "${W_TOTAL_CPU:-0}")

    echo -e "🧠 CPU Total: ${COLOR_PURPLE}${CPU_VAL}%${COLOR_RESET} (Lnx: $LNX_LOAD)\033[K"
    echo -e "💾 WSL RAM:   $(free -m | awk '/Mem:/ {printf "%d/%dMB", $3, $2}')\033[K"
    echo -e "🪟 Win RAM:   ${COLOR_CYAN}$WIN_RAM_STR${COLOR_RESET}\033[K"
    draw_line

    # Блок SSD + Health 🩺
    SSD_COLOR=$COLOR_GREEN; (( W_SSD_PCT > 85 )) && SSD_COLOR=$COLOR_RED
    echo -e "💽 SSD (C:):  ${SSD_COLOR}${W_SSD_FREE} GB Free${COLOR_RESET} (${W_SSD_PCT}% Used)\033[K"
    echo -e "🩺 Status:    ${HEALTH_COLOR}${W_HEALTH:-Sync...}${COLOR_RESET}\033[K"
    draw_line

    # Блок Процесів
    echo -e "🔥 TOP PROCESSES:\033[K"
    W_PROC_NAME=$(echo "$W_TOP_PROC" | awk '{print $1}')
    W_PROC_CPU=$(echo "$W_TOP_PROC" | awk '{print $2}' | tr -d '%')
    W_CPU_FMT=$(printf "%2d" "${W_PROC_CPU:-0}")
    echo -e "   🪟 Win: ${COLOR_YELLOW}${W_CPU_FMT}%${COLOR_RESET} ${W_PROC_NAME:-Sync...}\033[K"

    L_PROC_DATA=$(ps -eo comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1)
    L_PROC_NAME=$(echo "$L_PROC_DATA" | awk '{print $1}')
    L_PROC_CPU=$(echo "$L_PROC_DATA" | awk '{printf "%.0f", $2}')
    L_CPU_FMT=$(printf "%2d" "$L_PROC_CPU")
    echo -e "   🐧 Lnx: ${COLOR_YELLOW}${L_CPU_FMT}%${COLOR_RESET} $L_PROC_NAME\033[K"
    draw_line

    # Блок Мережі
    NET_NOW=$(get_net_data)
    B_RX=$(echo "$NET_NOW" | cut -d'|' -f1); B_TX=$(echo "$NET_NOW" | cut -d'|' -f2)
    D_RX=$((B_RX - A_RX)); D_TX=$((B_TX - A_TX)); A_RX=$B_RX; A_TX=$B_TX
    [ "$D_RX" -gt "$MAX_RX" ] && MAX_RX=$D_RX; [ "$D_TX" -gt "$MAX_TX" ] && MAX_TX=$D_TX

    echo -ne "🏅 MAX   ⬇ " && format_speed $MAX_RX
    echo -ne "  |  ⬆ " && format_speed $MAX_TX
    echo -e "\033[K"

    echo -e "${COLOR_RESET}==============================\033[K"

    echo -ne "🚀 LIVE  ⬇ " && format_speed $D_RX
    echo -ne "  |  ⬆ " && format_speed $D_TX
    echo -e "\033[K"

    draw_line

    echo -ne "🏁 FACT  " && get_speed_data
    echo -e "\033[K"

    sleep 1
done
