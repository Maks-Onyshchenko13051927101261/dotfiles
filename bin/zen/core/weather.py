import subprocess

def get_weather():
    try:
        cmd = "curl -s 'wttr.in/Kyiv?format=%t+%C'"
        out = subprocess.check_output(cmd, shell=True, text=True, timeout=5).strip()
        if not out or "Unknown" in out:
            return "--°C ☁️"

        desc = out.lower()
        icon = "☀️"
        if "cloud" in desc or "overcast" in desc: icon = "☁️"
        elif "rain" in desc: icon = "🌧️"
        elif "snow" in desc: icon = "❄️"
        elif "clear" in desc: icon = "☀️"
        
        return f"{out} {icon}"
    except:
        return "--°C 📡 Offline"