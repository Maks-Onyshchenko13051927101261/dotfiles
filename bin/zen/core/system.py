import psutil
import os
import subprocess
from config import DRIVES, GET_WIN_RAM_CMD
from core.temp_reader import get_core_temp # Наш новий "градусник"

GB = 1024 ** 3

def get_drives_info():
    drives_info = {}
    for mount_path in DRIVES:
        try:
            usage = psutil.disk_usage(mount_path)
            name = "C:" if "c" in mount_path.lower() else mount_path
            drives_info[name] = {
                "free": round(usage.free / GB, 1),
                "percent": int(usage.percent),
                "health": "Healthy"
            }
        except:
            continue
    return drives_info

def get_win_ram():
    try:
        cmd = 'powershell.exe -Command "(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize; (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory"'
        output = subprocess.check_output(cmd, shell=True, text=True, timeout=5).splitlines()
        data = [line.strip() for line in output if line.strip().isdigit()]
        
        if len(data) >= 2:
            total_kb = int(data[0])
            free_kb = int(data[1])
            used_gb = round((total_kb - free_kb) / (1024**2), 1)
            total_gb = round(total_kb / (1024**2), 1)
            return f"{used_gb}/{total_gb}GB"
    except:
        pass
    return "Sync..."

def get_system_data():
    cpu = psutil.cpu_percent(interval=None)
    load_1, _, _ = os.getloadavg() if hasattr(os, "getloadavg") else (0,0,0)
    ram = psutil.virtual_memory()
    
    return {
        "cpu": int(cpu),
        "cpu_lnx_load": round(load_1, 2),
        "ram_used": int(ram.used / (1024**2)), # Переводимо в МБ
        "ram_total": int(ram.total / (1024**2)),
        "win_ram": get_win_ram(),
        "cpu_temp": get_core_temp(), # Отримуємо 41 замість 41000
        "drives": get_drives_info()
    }