import requests, ipaddress, sys, logging, speedtest, pythonping, certifi, re

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(name)-12s %(lineno)d %(levelname)-8s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

logger_name = "{} :: {}".format(__file__, __name__)
logger = logging.getLogger(logger_name) 


# PerTester class for running tests such as speedtest from clients

class PerfTester:
    def __init__(self):
        self.ping_target = 'www.google.com'
        self.ping_count = 10
        self.ping_interval = 0.5
        self.egress_ip = ''
        self.geolocalization_info = {}
        self.current_pop = ''
        self.download_speed = 0
        self.upload_speed = 0
        self.fss_ip_dict = {
            'Burnaby' : '66.35.18.0/24',
            'Burnaby' : '66.35.19.0/24',
            'Burnaby' : '66.35.21.0/24',
            'Burnaby' : '65.35.29.0/24',
            'Ottawa' : '206.47.184.0/24',
            'Tokyo' : '66.35.23.0/24',
            'Sophia' : '149.5.234.0/24',
            'Frankfurt' : '154.52.2.0/24',
            'London' : '154.52.3.0/24'
        }
        self.egress_ip_api_url = 'https://api.ipify.org?format=json'
        self.geolocaization_api_url = 'http://ip-api.com/json/'

# Get public ip stored in self.egress_ip from API call to url specified in self.egress_ip_api_url

    def get_egress_ip(self):
        try:
            j = requests.get(self.egress_ip_api_url, verify=False)
            self.egress_ip = j.json()['ip']

        except Exception as e:
            raise e

# Get geolocalization json store in self.geolocalization_infos from API call specified in self.geolocaization_api_url

    def get_geolocalization_info(self):
        try:
            r = requests.get(self.geolocaization_api_url + self.egress_ip, verify=False)
            self.geolocalization_info = r.json()

        except Exception as e:
            raise e

# Get current FSS dc by comparing self.egress_ip as IPv4Address to fss_ip_dict items as IPv4Network. Set self.current_dc

    def fss_pop(self):
        try:
            is_fss_ip = False
            ip = ipaddress.IPv4Address(self.egress_ip)
            for pop, net in self.fss_ip_dict.items():
                if ip in ipaddress.IPv4Network(net):
                    is_fss_ip = True
                    current_pop = pop
            
            if is_fss_ip:
                self.current_pop = current_pop
            else:
                self.current_pop = False

        except Exception as e:
            raise e

    def do_ping_test(self):
        return pythonping.ping(self.ping_target, count=self.ping_count, interval=self.ping_interval)

    
if __name__ == "__main__":
    try: 
        logging.info('''

###############################

        Starting tests

###############################
    ''')

        perftester = PerfTester()
        perftester.get_egress_ip()

        logging.info(f'Current Egress IP :  \'{perftester.egress_ip}\'')
        
        perftester.get_geolocalization_info()

        if perftester.geolocalization_info['status'] == 'success':
            logging.info(f'''
Geolocalization info :

    -  Country : {perftester.geolocalization_info['country']}
    -  CountryCode : {perftester.geolocalization_info['countryCode']}
    -  Timezone : {perftester.geolocalization_info['timezone']}
    -  Isp : {perftester.geolocalization_info['isp']}
    -  AS : {perftester.geolocalization_info['as']}
            ''')
        else:
            logging.error('Unable to retrieve geolocalization info')

        perftester.fss_pop()
        if perftester.current_pop:
            logging.info(f'Connected to FortiSase pop : {perftester.current_pop}\n')
        else:
            logging.error('Unable to determine the current FortiSase pop')
        logging.info('#### Starting speedtest ####')

        s = speedtest.Speedtest()
        server = s.get_best_server()
        ds = s.download(threads=None)
        us = s.upload(threads=None, pre_allocate=True)
        logging.info(f'Using server : {server["name"]}, {server["country"]}')
        logging.info(f'Download speed {int(ds/1024/1024)} mbps')
        logging.info(f'Upload speed {int(us/1024/1024)} mbps')
        logging.info('#### End speedtest ####\n')
        
        logging.info('#### Starting Ping test ####')

        latency_sum = 0
        for response in perftester.do_ping_test():
            responseStr = str(response)
            pattern = "bytes in (.*)ms"
            latency = re.search(pattern, responseStr).group(1) or 2000
            ip_pattern = "Reply from(.*),"
            ip = re.search(ip_pattern, responseStr).group(1) or ''
            latency_sum += int(float(latency))
        logging.info(f'Ping done on server {perftester.ping_target} with ip {ip}')   
        logging.info(f'Ping latency : {latency_sum / perftester.ping_count} ms')
        
        logging.info('#### End Ping test ####\n')

    except Exception as e:
        logging.error(e)
        sys.exit(-1)