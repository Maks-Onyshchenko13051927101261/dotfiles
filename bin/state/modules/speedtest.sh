#!/bin/bash

# Файл для збереження результату
SPEED_CACHE="/tmp/zenstat_speed"

run_speedtest() {
    # Запускаємо тест у фоні, щоб не гальмувати головний скрипт
    (
        echo "Testing..." > "$SPEED_CACHE"
        # Отримуємо тільки Download та Upload цифри
        RESULT=$(speedtest-cli --simple 2>/dev/null)
        if [ $? -eq 0 ]; then
            DL=$(echo "$RESULT" | awk '/Download/ {print $2" "$3}')
            UL=$(echo "$RESULT" | awk '/Upload/ {print $2" "$3}')
            echo "⬇ $DL | ⬆ $UL" > "$SPEED_CACHE"
        else
            echo "Offline" > "$SPEED_CACHE"
        fi
    ) &
}

get_speed_data() {
    # Якщо файлу немає або він старий (більше 60 хв), запускаємо тест
    if [[ ! -f "$SPEED_CACHE" || $(find "$SPEED_CACHE" -mmin +60 2>/dev/null) ]]; then
        run_speedtest
    fi
    
    # Читаємо результат
    cat "$SPEED_CACHE" 2>/dev/null || echo "Waiting..."
}
# Функція для примусового скидання кешу
reset_speed_cache() {
    rm -f "$SPEED_CACHE"
}
