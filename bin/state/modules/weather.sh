#!/bin/bash

# Функція для отримання погоди
get_weather() {
    # Перевіряємо, чи треба оновити кеш (змінні беруться з config.conf)
    if [[ ! -f "$WEATHER_CACHE" || "$(cat "$WEATHER_CACHE" 2>/dev/null)" == "Wait..." || $(find "$WEATHER_CACHE" -mmin +60 2>/dev/null) ]]; then
        (curl -s --max-time 5 "wttr.in/${CITY}?format=%c%t&m&lang=en" > "$WEATHER_CACHE" || echo "Offline" > "$WEATHER_CACHE") &
    fi
    
    # Записуємо результат у змінну WEATHER
    WEATHER=$(cat "$WEATHER_CACHE" 2>/dev/null | head -n 1)
    [ -z "$WEATHER" ] && WEATHER="Searching..."
    
    # Повертаємо чистий рядок з погодою
    echo -n "$WEATHER"
}
