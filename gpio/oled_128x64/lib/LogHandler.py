import logging
import os
mypath = os.path.dirname(os.path.abspath(__file__))

class LogHandler():

    def __init__(self, name, folder="logs"):
        self.name = name
        self.folder = folder
        self.create_folder_for_logs(os.path.join(mypath, self.folder))
        self.logger = None
        self.ch = None
        self.create_logger()
        self.console_handler()
        self.formatter_set()
        self.clean_log_file()

    def clean_log_file(self):
        log_file_path = os.path.join(mypath, self.folder, self.name)
        if os.path.exists(log_file_path):
            os.remove(log_file_path)
            print("Clean log file before start.")

    def create_folder_for_logs(self, folder):
        if not os.path.isdir(folder):
            os.makedirs(folder)

    def create_logger(self):
        # create logger
        self.logger = logging.getLogger(self.name)
        self.logger.setLevel(logging.DEBUG)
        logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', \
                            filename=os.path.join(mypath, self.folder, self.name) + ".log", level=logging.DEBUG)

    def console_handler(self):
        # create console handler and set level to debug
        self.ch = logging.StreamHandler()
        self.ch.setLevel(logging.DEBUG)

    def formatter_set(self):
        # create formatter
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        # add formatter to ch
        self.ch.setFormatter(formatter)
        # add ch to logger
        self.logger.addHandler(self.ch)

    def test(self):
        # 'application' code
        self.logger.debug('debug message')
        self.logger.info('info message')
        self.logger.warn('warn message')
        self.logger.error('error message')
        self.logger.critical('critical message')

if __name__ == "__main__":
    ledh = LogHandler("test")
    ledh.test()
