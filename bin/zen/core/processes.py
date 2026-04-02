import psutil
import subprocess

def get_top_processes(n=3):
    top_win = []
    try:
        all_procs = []
        for p in psutil.process_iter(['name', 'cpu_percent']):
            try:
                if p.info['cpu_percent'] is not None:
                    all_procs.append(p.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue

        sorted_procs = sorted(all_procs, key=lambda x: x['cpu_percent'], reverse=True)[:n]
        top_win = [{"name": p['name'], "cpu": int(p['cpu_percent'])} for p in sorted_procs]
    except Exception:
        top_win = [{"name": "Unknown", "cpu": 0}]

    try:
        out = subprocess.check_output(
            "ps -eo comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1", 
            shell=True, 
            text=True, 
            stderr=subprocess.DEVNULL
        )
        parts = out.strip().split()
        if len(parts) >= 2:
            name, cpu = parts[0], parts[1]
            top_linux = {"name": name, "cpu": int(float(cpu))}
        else:
            top_linux = {"name": "Idle", "cpu": 0}
    except Exception:
        top_linux = {"name": "WSL_None", "cpu": 0}

    return top_win, top_linux