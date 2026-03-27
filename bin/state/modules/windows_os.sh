#!/bin/bash

get_windows_stats() {
    # Запитуємо дані (RAM, TopProc, SSD Free, SSD Pct, CPU, Health)
    WIN_DATA=$(powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
        \$proc = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1 Name;
        \$totalCpu = [Math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Name '_Total').PercentProcessorTime);
        \$freeGB = [Math]::Round(\$drive.FreeSpace / 1GB, 1);
        \$usedPct = [Math]::Round(((\$drive.Size - \$drive.FreeSpace) / \$drive.Size) * 100);
        \$health = (Get-PhysicalDisk | Select-Object -First 1 HealthStatus).HealthStatus;
        
        Write-Host \"\$(\$os.TotalVisibleMemorySize - \$os.FreePhysicalMemory)|\$([Math]::Round(\$os.TotalVisibleMemorySize / 1MB))|\$(( \$proc.Name ))|\$(( \$freeGB ))|\$(( \$usedPct ))|\$(( \$totalCpu ))|\$(( \$health ))\"
    " 2>/dev/null | tr -d '\r')

    echo "$WIN_DATA"
}
