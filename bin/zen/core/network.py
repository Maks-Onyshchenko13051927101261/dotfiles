import speedtest

class NetworkMonitor:
    def __init__(self):
        self.results = {"down": 0, "up": 0, "ping": 0}
        self.tested = False

    def run_test(self):
        try:
            st = speedtest.Speedtest()
            st.get_best_server()
            down = st.download() / 1_000_000 # В Мбіт/с
            up = st.upload() / 1_000_000
            self.results = {
                "down": round(down, 1),
                "up": round(up, 1),
                "ping": int(st.results.ping)
            }
            self.tested = True
        except:
            self.results = {"down": "Err", "up": "Err", "ping": 0}
            self.tested = True
        return self.results

    def get_data(self):
        return self.results