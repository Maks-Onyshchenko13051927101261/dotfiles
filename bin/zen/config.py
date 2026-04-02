DRIVES = ["/mnt/c"]

CORE_TEMP_PATH = "/mnt/c/ProgramData/chocolatey/lib/coretemp/tools"

GET_WIN_RAM_CMD = 'powershell.exe -Command "Get-CimInstance Win32_OperatingSystem | Select-Object @{n=\'Used\';e={($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*1024}}, @{n=\'Total\';e={$_.TotalVisibleMemorySize*1024}}"'