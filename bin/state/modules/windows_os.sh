#!/bin/bash

#!/bin/bash

# --- ЛОГІКА ЗБОРУ ТА РОЗПАКОВКИ ---
update_windows_data() {
    # Збираємо тільки динаміку (CPU, RAM used, SSD free, SSD %)
    local RAW=$(powershell.exe -Command "
        \$cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue;
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$ram = [Math]::Round((\$os.TotalVisibleMemorySize - \$os.FreePhysicalMemory) / 1024 / 1024, 1);
        \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
        \$ssdF = [Math]::Round(\$drive.FreeSpace / 1GB, 1);
        \$ssdP = [Math]::Round(((\$drive.Size - \$drive.FreeSpace) / \$drive.Size) * 100);
        
        Write-Host \"([Math]::Round(\$cpu))|\$ram|\$ssdF|\$ssdP\"
    " 2>/dev/null | tr -d '\r')

    # Розпаковка в глобальні змінні
    IFS='|' read -r W_CPU W_RAM_U W_SSD_F W_SSD_P <<< "$RAW"

    # Чистимо W_CPU від дужок, якщо вони прилетіли з PS
    W_CPU=$(echo "$W_CPU" | tr -d '()')
}

# --- СТАТИКА (Запускаємо ОДИН раз у zen.sh) ---
get_windows_static() {
    powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
        \$totalRam = [int](\$os.TotalVisibleMemorySize / 1024 / 1024);
        \$totalSSD = [int](\$drive.Size / 1GB);
        Write-Host \"\$totalRam|\$totalSSD\"
    " 2>/dev/null | tr -d '\r'
}
