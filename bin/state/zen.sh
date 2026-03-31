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

# ---------------------------------------------------------
# НОВА СТАТИКА (Беремо 1 раз, щоб не мучити PowerShell)
# ---------------------------------------------------------
STATIC_DATA=$(powershell.exe -Command "
    \$os = Get-CimInstance Win32_OperatingSystem;
    \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
    \$totalRam = [int](\$os.TotalVisibleMemorySize / 1024 / 1024);
    \$totalSSD = [int](\$drive.Size / 1GB);
    Write-Host \"\$totalRam|\$totalSSD\"
" 2>/dev/null | tr -d '\r')
IFS='|' read -r W_TOTAL_GB W_TOTAL_SSD_SIZE <<< "$STATIC_DATA"
# ---------------------------------------------------------

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

    # 🧠 Опитування Windows (Динаміка)
    # Ми прибрали розпаковку через cut і зробили один швидкий запит
    W_DATA=$(powershell.exe -Command "
        \$cpu = [int](Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue;
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$usedRam = [Math]::Round((\$os.TotalVisibleMemorySize - \$os.FreePhysicalMemory) / 1024 / 1024, 1);
        \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
        \$freeSSD = [Math]::Round(\$drive.FreeSpace / 1GB, 1);
        \$pctSSD = [int](((\$drive.Size - \$drive.FreeSpace) / \$drive.Size) * 100);
        \$health = (Get-PhysicalDisk | Select-Object -ExpandProperty HealthStatus -First 1);
        \$top = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1;
        
        Write-Host \"\$usedRam|\$top.Name \$top.CPU|\$cpu|\$freeSSD|\$pctSSD|\$health\"
    " 2>/dev/null | tr -d '\r')

    # Розпаковка даних
    IFS='|' read -r W_USED_GB W_TOP_PROC W_TOTAL_CPU W_SSD_FREE W_SSD_PCT W_HEALTH <<< "$W_DATA"

    # 🧠 CPU Колір
    CPU_COLOR=$COLOR_GREEN
    [[ -n "$W_TOTAL_CPU" ]] && (( W_TOTAL_CPU > 50 )) && CPU_COLOR=$COLOR_YELLOW
    [[ -n "$W_TOTAL_CPU" ]] && (( W_TOTAL_CPU > 85 )) && CPU_COLOR=$COLOR_RED
    W_CPU_STR="${CPU_COLOR}${W_TOTAL_CPU:-0}%${COLOR_RESET}"

    # 💾 RAM Колір
    if [[ -n "$W_USED_GB" && "$W_TOTAL_GB" != "0" ]]; then
        RAM_COLOR=$COLOR_CYAN
        RAM_USAGE=$(echo "scale=0; $W_USED_GB * 100 / $W_TOTAL_GB" | bc 2>/dev/null || echo 0)
        (( RAM_USAGE > 90 )) && RAM_COLOR=$COLOR_RED
        WIN_RAM_STR="${RAM_COLOR}${W_USED_GB}/${W_TOTAL_GB}GB${COLOR_RESET}"
    else
        WIN_RAM_STR="${COLOR_YELLOW}Sync...${COLOR_RESET}"
    fi

    # 🩺 Health & SSD Colors
    HEALTH_COLOR=$COLOR_GREEN
    [[ "$W_HEALTH" != "Healthy" ]] && HEALTH_COLOR=$COLOR_YELLOW
    SSD_COLOR=$COLOR_GREEN; (( W_SSD_PCT > 85 )) && SSD_COLOR=$COLOR_RED

    # --- (Рендеринг) ---
    tput cup 0 0
    draw_header

    # Блок Температури
    LATEST_LOG=$(ls -t "$CORE_TEMP_PATH"/CT-Log*.csv 2>/dev/null | head -n 1)
    TEMP="??"
    [ -n "$LATEST_LOG" ] && VAL=$(tail -n 1 "$LATEST_LOG" | awk -F',' '{print $4}' | tr -d ' ') && TEMP=$((VAL/1000))
    T_COLOR=$COLOR_GREEN; (( TEMP > 65 )) && T_COLOR=$COLOR_YELLOW; (( TEMP > 80 )) && T_COLOR=$COLOR_RED
    echo -e "🌡️  Hardware: ${T_COLOR}${TEMP}°C${COLOR_RESET}\033[K"
    draw_line

    # Блок Ресурсів
    LNX_LOAD=$(uptime | awk -F'average:' '{print $2}' | tr -d ' ' | cut -d',' -f1)
    CPU_VAL=$(printf "%3d" "${W_TOTAL_CPU:-0}")
    echo -e "🧠 CPU Total: ${COLOR_PURPLE}${CPU_VAL}%${COLOR_RESET} (Lnx: $LNX_LOAD)\033[K"
    echo -e "💾 WSL RAM:   $(free -m | awk '/Mem:/ {printf "%d/%dMB", $3, $2}')\033[K"
    echo -e "🪟 Win RAM:   ${COLOR_CYAN}$WIN_RAM_STR${COLOR_RESET}\033[K"
    draw_line

    # Блок SSD + Health
    echo -e "💽 SSD (C:):  ${SSD_COLOR}${W_SSD_FREE} GB Free${COLOR_RESET} (${W_SSD_PCT}% Used)\033[K"
    echo -e "🩺 Status:    ${HEALTH_COLOR}${W_HEALTH:-Sync...}${COLOR_RESET}\033[K"
    draw_line

    # Блок Процесів
    echo -e "🔥 TOP PROCESSES:\033[K"
    W_PROC_NAME=$(echo "$W_TOP_PROC" | awk '{print $1}')
    W_PROC_CPU=$(echo "$W_TOP_PROC" | awk '{print $2}' | cut -d'.' -f1)
    W_CPU_FMT=$(printf "%2d" "${W_PROC_CPU:-0}")
    echo -e "   🪟 Win: ${COLOR_YELLOW}${W_CPU_FMT}%${COLOR_RESET} ${W_PROC_NAME:-Sync...}\033[K"
    
    L_PROC_DATA=$(ps -eo comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1)
    L_PROC_NAME=$(echo "$L_PROC_DATA" | awk '{print $1}')
    L_PROC_CPU=$(echo "$L_PROC_DATA" | awk '{printf "%.0f", $2}')
    echo -e "   🐧 Lnx: ${COLOR_YELLOW}$(printf "%2d" "$L_PROC_CPU")%${COLOR_RESET} $L_PROC_NAME\033[K"
    draw_line

    # Блок Мережі (Твій оригінальний)
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
