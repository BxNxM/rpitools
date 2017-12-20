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

import ButtonHandler
import prctl

from datetime import datetime

# timing
thread_refresh_header_bar = 1
thread_refresh_page_bar = 1
thread_refresh_dynamic_pages = 3
thread_refresh_display_show_thread = 0.2
main_page_refresh_min_delay = 0.02
oled_sys_message_wait_sec = 5

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
        #self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)

        self.page_list = []                                     # page list tuples: page name, page index, page instance
        self.actual_page_index = 0                              # actual page index
        self.last_page_index = self.actual_page_index           # last page index -> check is page changed
        self.stored_files_number = 0                            # stores file pieces in pages folder
        self.display_is_avaible = True
        self.threads = []
        self.sys_message_cleanup = False
        self.head_page_bar_is_enable = [True, True]
        self.redraw = True
        self.display_refresh_time_sec = 1

    def display_refresh_time_setter(self, time):
        if isinstance(time, int):
            self.display_refresh_time_sec = time

    def head_page_bar_switch(self, head_bar, page_bar):
        if isinstance(head_bar, bool) and isinstance(page_bar, bool):
            self.head_page_bar_is_enable = [ head_bar, page_bar ]

    def virtual_button(self, cmd):
        pages_pcs = len(self.page_list)
        #print("all page: " + str(pages_pcs))
        if cmd == "right" or cmd == "RIGHT":
            oledlog.logger.info("=> Button: right pressed")
            self.actual_page_index +=1
            if self.actual_page_index >= pages_pcs:
                self.actual_page_index = 0
        elif cmd == "left" or cmd == "LEFT":
            oledlog.logger.info("=> Button: left pressed")
            self.actual_page_index -=1
            if self.actual_page_index < 0:
                self.actual_page_index = pages_pcs-1
        else:
            oledlog.logger.error("virtual_button cmd not found: " + str(cmd))

    # show contents on display if device is not busy
    def display_show(self):
        if self.display_is_avaible:
            self.display_is_avaible = False
            self.disp_buffer = self.disp._buffer
            oledlog.logger.info("self.image draw over i2c: " + str(self.image))
            self.disp.image(self.image)
            self.disp.display()
            self.display_is_avaible = True

    # init and start threads
    def __init_threads(self):
        self.threads.append(threading.Thread(target=self.draw_header_bar_thread))
        self.threads.append(threading.Thread(target=self.draw_page_bar_thread))
        self.threads.append(threading.Thread(target=self.manage_pages_thread))
        self.threads.append(threading.Thread(target=self.button_handler_thread))
        self.threads.append(threading.Thread(target=self.display_show_thread))
        # write more threads here...
        for thd in self.threads:
            thd.daemon = True                                   # with this set, can stop therad
            thd.start()
        # sleep a little while manage_pages_thread read contents
        sleep(1)

    # showes display content if self.redraw is true
    def display_show_thread(self):
        prctl.set_name("thread_dipshow")
        try:
            while True:
                if self.redraw:
                    self.display_show()
                    self.redraw = False
                sleep(thread_refresh_display_show_thread)
        except Exception as e:
            oledlog.logger.error("display_show: " + str(e))
            raise Exception(e)

    # page bar thread
    def draw_page_bar_thread(self):
        prctl.set_name("thread_pagebar")
        while True:
            if len(self.page_list) == 0:
                self.draw_page_bar(1, self.actual_page_index)
            else:
                self.draw_page_bar(len(self.page_list), self.actual_page_index)
            # sleep in therad
            sleep(thread_refresh_page_bar)

    # header bar thread
    def draw_header_bar_thread(self):
        prctl.set_name("thread_headerbar")
        while True:
            self.draw_header_bar()
            sleep(thread_refresh_header_bar)

    # read pages and reload if necessarry
    def manage_pages_thread(self):
        prctl.set_name("thread_pagemanag")
        while True:
            is_reload = self.__read_pages()
            if is_reload:
                self.__load_pages()
            sleep(thread_refresh_dynamic_pages)

    def button_handler_thread(self):
        prctl.set_name("thread_button")
        while True:
            status = ButtonHandler.oled_buttons.oled_read_all_function_buttons()
            self.virtual_button(status)

    # page bar
    def draw_page_bar(self, all_page_int, actaul_page_int):
        if self.head_page_bar_is_enable[1]:
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
            # self.display_show()
            self.redraw = True

    # header bar
    def draw_header_bar(self):
        if self.head_page_bar_is_enable[0]:
            #time = strftime("%H:%M:%S", gmtime())
            date = datetime.now().strftime('%Y-%m-%d')
            time = datetime.now().strftime('%H:%M:%S')
            self.__draw_time_text(time)
            # Display image.
            #self.display_show()
            self.redraw = True

    # system message box
    def oled_sys_message(self, text=None):
        # main frame
        global oled_sys_message_wait_sec
        time_wait = oled_sys_message_wait_sec
        while time_wait > 0:
            self.draw.rectangle((10, 8, self.disp.width-10, self.disp.height-7), outline=255, fill=0)
            header_text = "SYS MESS - {} s".format(time_wait)
            w, h = self.font.getsize(header_text)
            self.draw_text(header_text, (self.disp.width - w)/2, 9)
            if text is not None:
                if len(text) >= 18:
                    text1 = text[0:17]
                    if len(text) > 17*2:
                        text2 = text[17:34]
                        text3 = text[34:len(text)]
                    else:
                        text2 = text[17:len(text)]
                        text3 = ""
                    self.draw_text(text1, 14, 12+h)
                    self.draw_text(text2, 14, 12+h+h)
                    self.draw_text(text3, 14, 12+h+h+h)
                else:
                    self.draw_text(text, 14, 12+h)
                self.sys_message_cleanup = True
                self.display_show()
                sleep(1)
                time_wait-=1
        else:
            self.draw.rectangle((10, 8, self.disp.width-10, self.disp.height-7), outline=0, fill=0)

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
        #self.display_show()
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
            # write here you want to run in main loop permanently
            self.run_page()
            sleep(main_page_refresh_min_delay)

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
                    # clean system message if it was printed
                    if self.sys_message_cleanup:
                        self.sys_message_cleanup = False
                        self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
                    # run page setup function
                    page[2].page_setup(self)
                    # if page changed clean page
                    self.clever_screen_clean()
                    # run page
                    is_show = page[2].page(self)
                except Exception as e:
                    oledlog.logger.warn("run page exception" + str(e))
                    self.oled_sys_message("run page exception" + str(e))
                if is_show:
                    # Display image.
                    #self.display_show()
                    self.redraw = True
                # clever wait, if button press happen, break sleep
                self.run_page_wait(int(page[1]))

    def run_page_wait(self, page_weight_index_buff):
        # clever wait between refresh page - if change page evenet happen break wait
        wait = 0
        while wait < self.display_refresh_time_sec:
            wait += 0.1
            sleep(0.1)
            print("=> SLEEP AFTER PAGE REFRESH: " + str(wait) + "/" + str(self.display_refresh_time_sec))
            print("{} actual <-> {} buffer".format(self.actual_page_index, page_weight_index_buff))
            if page_weight_index_buff != self.actual_page_index:
                print("\n\n=> SLEEP AFTER PAGE REFRESH !!! BREAK !!!\n\n")
                break

    def clever_screen_clean(self, clean_full=False):
        head_bar_height = 9
        page_bar_height = 5
        if self.last_page_index != self.actual_page_index:
            self.last_page_index = self.actual_page_index
            if self.head_page_bar_is_enable[0] and self.head_page_bar_is_enable[1]:
                self.draw.rectangle((0,head_bar_height,self.disp.width, self.disp.height-page_bar_height), outline=0, fill=0)
                oledlog.logger.info("Clean screen without head - page bar")
            elif not self.head_page_bar_is_enable[0] and not self.head_page_bar_is_enable[1]:
                clean_full = True
            else:
                oledlog.logger.info("TODO: Make smart clean smarter...")

        if clean_full:
            self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
            oledlog.logger.info("Clean full page")

    def __del__(self):
        self.clever_screen_clean(clean_full=True)
        self.disp.clear()
        self.disp.display()

def run():
    display = Oled_window_manager()
    display.run()
    display.__del__()

if __name__ == "__main__":
    run()
