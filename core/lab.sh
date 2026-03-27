#!/bin/bash

# browser settings
BROWSER="chromium-browser"
ARGS="--no-first-run --no-default-browser-check"
SILENT="> /dev/null 2>&1"

case "$1" in
    # --- [Apps] ---
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
        $0 hub && sleep 0.5 && $0 gpt && sleep 0.5 && $0 post
        ;;

    # --- [System Clean] ---
    clean)
        echo "--- 🐧 Linux Cleanup ---"
        sudo apt update && sudo apt upgrade -y
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        rm -f ~/.zsh_history && history -c
        echo "--- ✨ Linux is Fresh! ---"
        ;;

    win-clean)
        echo "--- 🪟 Windows Deep Clean ---"
        powershell.exe -Command "Stop-Service wuauserv -Force; Remove-Item -Path \$env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -ErrorAction SilentlyContinue; Start-Service wuauserv; Clear-RecycleBin -Confirm:\$false -ErrorAction SilentlyContinue; ipconfig /flushdns"
        echo "--- ✨ Windows is Shiny! ---"
        ;;

    # --- [System Health & Fix] ---
    fix)
        echo "--- 🩹 Running System Repair (SFC & DISM) ---"
        echo "This may take 15-30 minutes..."
        powershell.exe -Command "sfc /scannow; DISM /Online /Cleanup-Image /RestoreHealth"
        ;;

    dev-reset)
        echo "--- 🔄 Dev Environment Reset ---"
        # kill port processes
        powershell.exe -Command "Stop-Process -Name 'node','python','npm' -Force -ErrorAction SilentlyContinue"
        wsl.exe --shutdown
        echo "--- ✅ Ports cleared, WSL restarted. ---"
        ;;

    *)
        echo "🧪 LAB CORE v1.0"
        echo "Usage: lab [gpt|gem|post|hub|all] | [clean|win-clean|fix|dev-reset]"
        ;;
esac
