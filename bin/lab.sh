#!/bin/bash

# Налаштування
BROWSER="chromium-browser"
ARGS="--no-first-run --no-default-browser-check"
SILENT="> /dev/null 2>&1"

# Логіка вибору
case "$1" in
    gpt)
        eval "$BROWSER $ARGS --app=https://chatgpt.com $SILENT &"
        ;;
    gem)
        eval "$BROWSER $ARGS --app=https://gemini.google.com/app $SILENT &"
        ;;
    post)
        eval "$BROWSER $ARGS --app=https://web.postman.co $SILENT &"
        ;;
    hub)
        eval "$BROWSER $ARGS --app=https://github.com $SILENT &"
        ;;
    all)
        # Запускаємо все по черзі
        $0 hub
        sleep 0.5
        $0 gpt
        sleep 0.5
        $0 post
        ;;
    *)
        echo "🚀 Lab Control: [gpt | gem | post | hub | all]"
        ;;
esac
