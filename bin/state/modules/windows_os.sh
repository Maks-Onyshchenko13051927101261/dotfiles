#!/bin/bash

get_windows_stats() {
    # Використовуємо Get-Counter для реальних даних CPU
    powershell.exe -Command "
        \$os = Get-CimInstance Win32_OperatingSystem;
        \$drive = Get-CimInstance Win32_LogicalDisk -Filter \"DeviceID='C:'\";
        
        # Беремо топ-процес за часом процесора
        \$procObj = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1;
        \$procName = \$procObj.Name;

        # Магія для CPU (Counter дає реальний відсоток, а не 0)
        \$cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue;
        \$cpu = [Math]::Round(\$cpuCounter.CounterSamples[0].CookedValue);

        \$usedRam = [Math]::Round((\$os.TotalVisibleMemorySize - \$os.FreePhysicalMemory) / 1024 / 1024);
        \$totalRam = [Math]::Round(\$os.TotalVisibleMemorySize / 1024 / 1024);
        \$freeSSD = [Math]::Round(\$drive.FreeSpace / 1GB, 1);
        \$usedSSDPct = [Math]::Round(((\$drive.Size - \$drive.FreeSpace) / \$drive.Size) * 100);
        \$health = (Get-PhysicalDisk | Select-Object -ExpandProperty HealthStatus -First 1);

        Write-Host \"\$usedRam|\$totalRam|\$procName|\$cpu|\$freeSSD|\$usedSSDPct|\$health\"
    " 2>/dev/null | tr -d '\r'
}
