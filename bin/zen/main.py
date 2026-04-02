import time
import threading
from rich.live import Live
from core.system import get_system_data
from core.processes import get_top_processes
from core.network import NetworkMonitor
from core.weather import get_weather
from ui.render import render_dashboard
from core.temp_reader import cleanup_logs

def main():
    cleanup_logs()
    net_monitor = NetworkMonitor()

    thread = threading.Thread(target=net_monitor.run_test, daemon=True)
    thread.start()
    
    weather_data = get_weather()
    weather_tick = 0

    with Live(auto_refresh=False, screen=False) as live:
        try:
            while True:
                system = get_system_data()
                top_win, top_linux = get_top_processes(3)
                
                if weather_tick > 600:
                    weather_data = get_weather()
                    weather_tick = 0
                weather_tick += 1

                content = render_dashboard(
                    system, 
                    top_win, 
                    top_linux, 
                    net_monitor.get_data(), 
                    weather_data
                )
                
                live.update(content, refresh=True)
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n[!] Спокій збережено. До зустрічі!")

if __name__ == "__main__":
    main()