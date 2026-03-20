#!/bin/bash

# Форматування швидкості
format_speed() {
    local diff=$1
    if [ "$diff" -eq 0 ]; then echo -ne "0 B/s"
    elif [ "$diff" -lt 1024 ]; then echo -ne "${diff} B/s"
    elif [ "$diff" -lt 1048576 ]; then echo -ne "$((diff / 1024)) KB/s"
    else echo -ne "$((diff / 1024 / 1024)) MB/s"; fi
}

get_net_data() {
    # Читаємо RX (отримано) та TX (відправлено)
    awk '/eth0/ {print $2"|"$10}' /proc/net/dev
}
