import time
import Adafruit_SSD1306

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont

from time import *
import subprocess
import os
import sys
import importlib

# import pages source path
page_files_path = "pages"
sys.path.append(page_files_path)

import LogHandler
oledlog = LogHandler.LogHandler("oled")

import threading

thread_refresh = 1

class Oled_window_manager():

    def __init__(self, RST_pin=None, i2c_addr=0x3C):
        # instantiate display from adafruit
        self.disp = Adafruit_SSD1306.SSD1306_128_64(rst=RST_pin, i2c_address=i2c_addr)
        self.disp.begin()
        # Clear display.
        self.disp.clear()
        self.disp.display()
        # Create blank image for drawing.
        # Make sure to create image with mode '1' for 1-bit color.
        self.image = Image.new('1', (self.disp.width, self.disp.height))
        # Get drawing object to draw on image.
        self.draw = ImageDraw.Draw(self.image)
        # Load default font.
        self.font = ImageFont.load_default()

        # Draw a black filled box to clear the image.
        #draw.rectangle((0,0,width,height), outline=0, fill=0)
        self.page_list = []                                     # page list tuples: page name, page index, page instance
        self.actual_page_index = 0                              # actual page index
        self.stored_files_number = 0                            # stores file pieces in pages folder
        self.display_is_avaible = True
        self.threads = []

    # show contents on display if device is not busy
    def display_show(self):
        if self.display_is_avaible:
            self.display_is_avaible = False
            self.disp.image(self.image)
            self.disp.display()
            self.display_is_avaible = True

    # init and start threads
    def __init_threads(self):
        self.threads.append(threading.Thread(target=self.draw_header_bar_thread))
        self.threads.append(threading.Thread(target=self.draw_page_bar_thread))
        self.threads.append(threading.Thread(target=self.manage_pages_thread))
        # write more threads here...
        for thd in self.threads:
            thd.daemon = True                                   # with this set, can stop therad
            thd.start()

    # page bar thread
    def draw_page_bar_thread(self):
        while True:
            if len(self.page_list) == 0:
                self.draw_page_bar(1, self.actual_page_index)
            else:
                self.draw_page_bar(len(self.page_list), self.actual_page_index)
            # sleep in therad
            sleep(thread_refresh)

    # header bar thread
    def draw_header_bar_thread(self):
        while True:
            self.draw_header_bar()
            sleep(thread_refresh)

    # read pages and reload if necessarry
    def manage_pages_thread(self):
            is_reload = self.__read_pages()
            #if is_reload:
            self.__load_pages()
            sleep(thread_refresh)

    # page bar
    def draw_page_bar(self, all_page_int, actaul_page_int):
        one_bar_width = int(self.disp.width / all_page_int)
        one_bar_height = 4

        # Draw some shapes.
        # First define some constants to allow easy resizing of shapes.
        for x_pos in range(0, self.disp.width, one_bar_width):
            top_pos = self.disp.height-one_bar_height
            right_pos = x_pos + one_bar_width
            if right_pos >= self.disp.width:
                right_pos = self.disp.width - 1
            self.draw.rectangle((x_pos, top_pos, right_pos, self.disp.height-1), outline=255, fill=0)
            if x_pos / one_bar_width == actaul_page_int:
                self.draw.rectangle((x_pos, top_pos, right_pos, self.disp.height-1), outline=255, fill=1)
        # Display image.
        self.display_show()

    # header bar
    def draw_header_bar(self):
        time = strftime("%H:%M:%S", gmtime())
        self.__draw_time_text(time)
        # Display image.
        self.display_show()

    def __draw_time_text(self, text):
        text = str(text)
        # Write two lines of text.
        w, h = self.font.getsize(text)
        x_text_pos = int((self.disp.width - w)/2)
        # clean text space
        self.draw.rectangle((x_text_pos, 0, x_text_pos+w, 0+h), outline=0, fill=0)
        # draw text
        self.draw.text((x_text_pos, 0), text,  font=self.font, fill=255)

    def draw_text(self, text, x, y):
        text = str(text)
        # Write two lines of text.
        w, h = self.font.getsize(text)
        # clean text space
        self.draw.rectangle((x, y, x+w, y+h), outline=0, fill=0)
        # draw text
        self.draw.text((x, y), text,  font=self.font, fill=255)
        # Display image.
        self.display_show()
        return w, h

    # executor main loop
    def run(self):
        self.__init_threads()
        try:
            while True:
                self.__executor()
        except KeyboardInterrupt as e:
            oledlog.logger.info("Exiting " + str(e))

    # Main block for running gui from pages and some extra stuff
    def __executor(self):
            self.run_page()

    # read pages from file
    def __read_pages(self):
        reload_is_necesarry = False
        fileslist = os.listdir(page_files_path)
        if len(fileslist) != self.stored_files_number:
            self.stored_files_number = len(fileslist)
            for actual_file in fileslist:
                module_is_imported = False
                first_part, second_part = actual_file.split("_")
                second_part, third_part = second_part.split(".")
                if third_part == "py" and first_part == "page":
                    try:
                        page_index = int(second_part)
                        page_to_import = first_part + "_" + second_part
                        for page_ in self.page_list:
                            if page_[0] == page_to_import:
                                module_is_imported = True
                        if not module_is_imported:
                            self.page_list.append((page_to_import, page_index))
                    except Exception as e:
                        oledlog.logger.error("read pages error " + str(e))
            oledlog.logger.info("Raw page list" + str(self.page_list))
            reload_is_necesarry = True
        return reload_is_necesarry

    # dynamic import handling
    def dynamic_import(self, module):
        try:
            module = importlib.import_module(module)
        except Exception as e:
            oledlog.logger.error("Dynamic import error: " + str(e))
            module == None
        return module

    # Load pages with dynamic_import
    def __load_pages(self):
        for index, page in enumerate(self.page_list):
            module = self.dynamic_import(page[0])
            oledlog.logger.info("PAGE: " + str(page))
            oledlog.logger.info("MODULE: " + str(module))
            if len(page) == 2:
                self.page_list[index] = (page[0], page[1], module)
            else:
                oledlog.logger.info("already inited: " + str(page))
        oledlog.logger.info("Full loaded parsed pages: " + str(self.page_list))

    # Run selected page
    def run_page(self):
        for index, page in enumerate(self.page_list):
            if int(page[1]) == self.actual_page_index:
                oledlog.logger.info("Call page: " + str(page))
                try:
                    page[2].page(self)
                except Exception as e:
                    oledlog.logger.warn("run page exception" + str(e))
                # Display image.
                self.display_show()

if __name__ == "__main__":
    display = Oled_window_manager()
    display.run()
