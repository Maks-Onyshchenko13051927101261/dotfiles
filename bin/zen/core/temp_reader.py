import os
import glob
from config import CORE_TEMP_PATH

_last_valid_temp = 45 

def get_core_temp():
    global _last_valid_temp
    try:
        log_files = glob.glob(os.path.join(CORE_TEMP_PATH, "CT-Log*.csv"))
        if not log_files: 
            return str(_last_valid_temp)

        latest_log = max(log_files, key=os.path.getmtime)
        
        with open(latest_log, 'r', encoding='utf-8', errors='ignore') as f:
            lines = [l.strip() for l in f.readlines() if l.strip()]
            if len(lines) < 2: 
                return str(_last_valid_temp)

            last_line = lines[-1]
            parts = [p.strip() for p in last_line.split(',') if p.strip()]
            
            if len(parts) < 10:
                parts = [p.strip() for p in lines[-2].split(',') if p.strip()]
            
            temps = []
            for p in parts:
                try:
                    val = int(p)
                    curr = int(val / 1000) if val > 1000 else val
                    if 35 < curr < 95:
                        temps.append(curr)
                except:
                    continue
            
            if temps:
                current = int(sum(temps) / len(temps))

                diff = current - _last_valid_temp
                if abs(diff) > 3:
                    current = _last_valid_temp + (3 if diff > 0 else -3)

                new_temp = (_last_valid_temp * 0.7) + (current * 0.3)
                _last_valid_temp = int(new_temp)

        return str(_last_valid_temp)
    except:
        return str(_last_valid_temp)

def cleanup_logs():
    try:
        log_files = sorted(glob.glob(os.path.join(CORE_TEMP_PATH, "CT-Log*.csv")), key=os.path.getmtime)
        if len(log_files) > 5:
            for old_file in log_files[:-5]:
                os.remove(old_file)
    except:
        pass