#!/bin/bash

# Малюємо тонку лінію (використовуємо колір з config.conf)
draw_line() {
    echo -e "${COLOR_CYAN}---------------------------------------${COLOR_RESET}\033[K"
}

# Малюємо жирну лінію
draw_sep() {
    echo -e "${COLOR_YELLOW}=======================================${COLOR_RESET}\033[K"
}

# Малюємо шапку
draw_header() {
    local time=$(date -d "+2 hours" +"%H:%M:%S")
    echo -e "${COLOR_CYAN}--- ⛩️  ZENSTAT V11.0 | ⌚ $time ---${COLOR_RESET}\033[K"
    echo -e "🕒 Up: $(uptime -p | sed 's/up //') | 🌍 ${WEATHER}\033[K"
    draw_sep
}
