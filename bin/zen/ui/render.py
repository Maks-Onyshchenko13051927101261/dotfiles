from rich.console import Group
from rich.panel import Panel
from rich.text import Text
from datetime import datetime, timedelta

def render_dashboard(system, top_win, top_linux, net_data, weather):
    curr_time = (datetime.now() + timedelta(hours=3)).strftime("%H:%M:%S")
    lines = []
    
    # Header
    lines.append(Text(f"--- ⛩️  ZEN MONITOR | ⌚ {curr_time} ---", style="bold cyan"))
    lines.append(Text(f"🌍 {weather}", style="bright_white"))
    lines.append(Text("=" * 45, style="bright_black"))

    try:
        temp_val = int(system.get('cpu_temp', 0))
    except:
        temp_val = 0

    if temp_val > 80:
        t_style = "bold red"
    elif temp_val > 65:
        t_style = "bold yellow"
    else:
        t_style = "bold green"

    temp_text = Text("🌡️  Hardware: ", style="white")
    temp_text.append(f"{temp_val}°C", style=t_style)
    lines.append(temp_text)
    lines.append(Text("-" * 45, style="bright_black"))
 
    lines.append(Text(f"🧠 CPU Total:   {system['cpu']}% (Lnx: {system['cpu_lnx_load']})"))
    lines.append(Text(f"💾 WSL RAM:     {system['ram_used']}/{system['ram_total']}MB"))
    lines.append(Text(f"🪟 Win RAM:     {system['win_ram']}", style="bright_blue"))
    lines.append(Text("-" * 45, style="bright_black"))

    for drive, info in system['drives'].items():
        drive_line = Text(f"💽 SSD ({drive}):  {info['free']} GB Free ({info['percent']}% Used)")
        lines.append(drive_line)
        lines.append(Text(f" 🩺 Status:      Healthy", style="green"))
    
    lines.append(Text("-" * 45, style="bright_black"))

    lines.append(Text("🔥 TOP PROCESSES (Mixed):", style="bold yellow"))
    
    all_procs = []
    for p in (top_win or []):
        if isinstance(p, dict): 
            all_procs.append({"icon": "🪟", "name": p['name'], "cpu": p['cpu']})

    if isinstance(top_linux, list):
        for p in top_linux:
            if isinstance(p, dict): 
                all_procs.append({"icon": "🐧", "name": p['name'], "cpu": p['cpu']})
    elif isinstance(top_linux, dict):
        all_procs.append({"icon": "🐧", "name": top_linux['name'], "cpu": top_linux['cpu']})

    all_procs = sorted(all_procs, key=lambda x: x['cpu'], reverse=True)
    for p in all_procs[:3]:
        proc_line = Text(f"   {p['icon']} ")
        proc_line.append(f"{p['cpu']:>3}%", style="bold magenta")
        proc_line.append(f" {p['name'][:20]}")
        lines.append(proc_line)
    
    lines.append(Text("=" * 45, style="bright_black"))

    if isinstance(net_data, dict) and net_data.get('down') != "Err":
        net_val = f"⬇ {net_data['down']} Mbit/s | ⬆ {net_data['up']} Mbit/s"
        lines.append(Text(f"🏁 FACT  {net_val}", style="bold green"))
    else:
        lines.append(Text("🏁 FACT  Waiting for Speedtest... ⏳", style="italic yellow"))

    return Panel(Group(*lines), border_style="bright_black", expand=False)