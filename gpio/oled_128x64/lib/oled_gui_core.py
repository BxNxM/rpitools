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
import oled_gui_widgets

# import pages source path
page_files_path = "pages"
sys.path.append(page_files_path)

import LogHandler
oledlog = LogHandler.LogHandler("oled")

import threading

import ButtonHandler
import prctl

from datetime import datetime

#############################################################################
#                             THREAD TIMING                                 #
#############################################################################
performance_setup_dict = {"ULTRALOW": 1.4, "LOW": 0.8, "MEDIUM": 0.4, "HIGH": 0.2}
performance = performance_setup_dict["MEDIUM"]                    # ---> set performance here

# timing base
thread_refresh_header_bar = 0.9 * performance                # header bar refresh time (sec)
thread_refresh_page_bar = 0.7 * performance                  # page bar refresh time (sec)
thread_refresh_dynamic_pages = 4 * performance                # rescan page folder time (sec)
thread_refresh_display_show_thread = 0.5 * performance        # display show thread refresh time (sec)
main_page_refresh_min_delay = 0.03 * performance              # default page refresh time (sec)
oled_sys_message_wait_sec = 3                                 # system message min show on display (sec)
oled_standby_period = 1

#############################################################################
#                               OLED CLASS                                  #
#############################################################################
class Oled_window_manager():

    # class constructor
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
        self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)

        self.page_list = []                                     # page list tuples: page name, page index, page instance
        self.image_strored = self.image                         # image buffer for restore screen after image draw on any page

        # indicator variables for managing elements
        self.actual_page_index = 0                              # actual page index
        self.last_page_index = self.actual_page_index           # last page index -> check is page changed
        self.actual_page_setup_executed = False                 # actual page setup is run indicator
        self.stored_files_number = 0                            # stores file pieces in pages folder
        self.display_is_avaible = True                          # display busy indicator
        self.threads = []                                       # threads list
        self.sys_message_cleanup = False                        # system msg indicator
        self.head_page_bar_is_enable = [True, True]             # head, page bar status
        self.head_page_bar_is_enable_backup = self.head_page_bar_is_enable
        self.redraw = True                                      # redraw page request status for display_show_thread
        self.display_refresh_time_sec = 1                       # actual page default refresh time - set with -> display_refresh_time_setter
        self.ok_button_event = False                            # ok button event status holder
        self.read_default_page_index()
        self.standby = False                                    # standby mode indicator

        # header bar shcedule widhets counters
        self.heder_page_widget_call_counter_max = 3
        self.header_bar_widget_counter = 0

    # read default index from file
    def read_default_page_index(self):
        default_index_config = ".defaultindex.dat"
        if os.path.exists(default_index_config):
            with open(default_index_config, "r") as f:
                index = f.read()
            try:
                self.actual_page_index = int(index)
            except Exception as e:
                oledlog.logger.warn("default index read: " + str(e))
                self.actual_page_index = 0

    #############################################################################
    #                                   THREADS                                 #
    #############################################################################
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
            sleep(0.1)
        # sleep a little while manage_pages_thread read contents
        sleep(0.5)

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
            if not self.standby:
                if len(self.page_list) == 0:
                    self.draw_page_bar(1, self.actual_page_index)
                else:
                    self.draw_page_bar(len(self.page_list), self.actual_page_index)
                # sleep in therad
                sleep(thread_refresh_page_bar)
            else:
                sleep(oled_standby_period)

    # header bar thread
    def draw_header_bar_thread(self):
        prctl.set_name("thread_headerbar")
        while True:
            if not self.standby:
                self.draw_header_bar()
                sleep(thread_refresh_header_bar)
            else:
                sleep(oled_standby_period)

    # read pages and reload if necessarry
    def manage_pages_thread(self):
        prctl.set_name("thread_pagemanag")
        while True:
            is_reload = self.__read_pages()
            if is_reload:
                self.__load_pages()
            sleep(thread_refresh_dynamic_pages)

    # button handler thread
    def button_handler_thread(self):
        prctl.set_name("thread_button")
        while True:
            status = ButtonHandler.oled_buttons.oled_read_all_function_buttons()
            self.virtual_button(status)

    #############################################################################
    #                             GETTER - SETTER                               #
    #############################################################################
    def ok_button_event_getter(self):
        try:
            if self.ok_button_event:
                self.ok_button_event = False
                return_value = True
            else:
                return_value = False
        except:
            self.ok_button_event = False
            return_value = False
        return return_value

    def display_refresh_time_setter(self, time):
        if isinstance(time, int):
            self.display_refresh_time_sec = time

    def head_page_bar_switch(self, head_bar, page_bar):
        if isinstance(head_bar, bool) and isinstance(page_bar, bool):
            self.head_page_bar_is_enable = [ head_bar, page_bar ]

    #############################################################################
    #                   VIRTUAL BUTTONS - RIGHT - LEFT - OK*                    #
    #############################################################################
    def virtual_button(self, cmd):
        pages_pcs = len(self.page_list)
        #print("all page: " + str(pages_pcs))
        if cmd == "right" or cmd == "RIGHT":
            self.standby = False                                        # wake up if button was pressed
            oledlog.logger.info("=> Button: right pressed")
            self.actual_page_index +=1
            if self.actual_page_index >= pages_pcs:
                self.actual_page_index = 0
        elif cmd == "left" or cmd == "LEFT":
            self.standby = False                                        # wake up if button was pressed
            oledlog.logger.info("=> Button: left pressed")
            self.actual_page_index -=1
            if self.actual_page_index < 0:
                self.actual_page_index = pages_pcs-1
        elif cmd == "ok" or cmd == "OK":
            if self.standby:
                self.ok_button_event = False
                self.standby_switch(False)                              # wake up for standby
            else:
                self.ok_button_event = True
        elif cmd == "standbyTrue" or cmd == "standbyFalse":
            if cmd == "standbyTrue":
                self.standby_switch(mode=True)
            else:
                self.standby_switch(mode=False)
        else:
            oledlog.logger.error("virtual_button cmd not found: " + str(cmd))

    #############################################################################
    #                           PAGE and HEADER BAR                             #
    #############################################################################
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
            self.redraw = True

    # header bar
    def draw_header_bar(self):
        if self.head_page_bar_is_enable[0]:
            if self.header_bar_widget_counter > self.heder_page_widget_call_counter_max:
                self.header_bar_widget_counter = 0

            # time / date
            date = datetime.now().strftime('%Y-%m-%d')
            time = datetime.now().strftime('%H:%M:%S')
            self.__draw_time_text(time)

            page_is_changed = self.page_is_changed(reset_status=False)
            # wifi
            if self.header_bar_widget_counter == 1 or page_is_changed:
                self.wifi_quality()

            # performance
            if self.header_bar_widget_counter == 0 or self.header_bar_widget_counter == 2 or page_is_changed:
                self.performance_widget()

            # Display image.
            self.redraw = True

            self.header_bar_widget_counter += 1

    #############################################################################
    #                      OFFICIAL WIDGETS - HEADER BAR                        #
    #############################################################################
    # wifi indicator
    def wifi_quality(self):
        try:
            strenght = oled_gui_widgets.wifi_quality()
        except Exception as e:
            oledlog.logger.error("wifi_quality: " + str(e))
            strenght = None
        size = 8
        for i in range(3):
            start_x = 0+size*i
            start_y = 0
            end_x = 0+size*(i+1)
            end_y = 0+size
            self.draw.rectangle((start_x, start_y, end_x, end_y), outline=1, fill=0)
            # if wifi is not avaible
            if strenght is None or strenght ==  -1:
                self.draw.rectangle((3, 3, 21, 5), outline=1, fill=1)
                self.redraw = True
                sleep(0.2)
                self.draw.rectangle((3, 3, 21, 5), outline=0, fill=0)
                self.redraw = True
                sleep(0.2)
            # if wifi is avaible
            elif strenght >= i+1:
                self.draw.rectangle((start_x+2, start_y+2, end_x-2, end_y-2), outline=1, fill=1)

        # cleanup area if state is false after draw - needed because multithreading sync problem
        if not self.head_page_bar_is_enable[0]:
            self.draw.rectangle((0, 0, 24, 8), outline=0, fill=0)

    # performance indicator bar
    def performance_widget(self):
        try:
            CPU, MemUsage, temp, DiskUsage = oled_gui_widgets.performance_widget()
        except Exception as e:
            oledlog.logger.error("wifi_quality: " + str(e))

        self.draw.rectangle((100, 0, 105, 8), outline=1, fill=0)
        self.draw.rectangle((107, 0, 112, 8), outline=1, fill=0)
        self.draw.rectangle((114, 0, 119, 8), outline=1, fill=0)
        self.draw.rectangle((121, 0, 126, 8), outline=1, fill=0)

        max_val = 100
        step = 7 / float(max_val)

        # CPU BAR
        input_val = int(CPU)
        lvl = int(input_val*step)
        self.draw.rectangle((101, 8-lvl, 104, 8), outline=1, fill=1)

        # Mem BAR
        input_val = int(MemUsage)
        lvl = int(input_val*step)
        self.draw.rectangle((108, 8-lvl, 111, 8), outline=1, fill=1)

        # temp BAR
        input_val = int(temp)
        lvl = int(input_val*step)
        self.draw.rectangle((115, 8-lvl, 118, 8), outline=1, fill=1)

        # disk BAR
        input_val = int(DiskUsage)
        lvl = int(input_val*step)
        self.draw.rectangle((122, 8-lvl, 125, 8), outline=1, fill=1)

        # cleanup area if state is false after draw - needed because multithreading sync problem
        if not self.head_page_bar_is_enable[0]:
            self.draw.rectangle((100, 0, 126, 9), outline=0, fill=0)

    #############################################################################
    #                              OFFICIAL WIDGET(S)                             #
    #############################################################################
    # system message box
    def oled_sys_message(self, text=None, time=None):
        # main frame
        if time is None:
            global oled_sys_message_wait_sec
            time_wait = oled_sys_message_wait_sec
        if time is not None:
            time_wait = time

        # store standy state and set it True to ignore head - page bar and main loop
        standby_stored_state =  self.standby
        self.standby = True

        # make system msg screen - and store original page
        original_image_obj = self.image
        self.image = Image.new('1', (self.disp.width, self.disp.height))
        self.draw = ImageDraw.Draw(self.image)

        while time_wait > 0:
            self.draw.rectangle((10, 12, self.disp.width-10, self.disp.height-7), outline=255, fill=0)
            header_text = "SYS MESS - {} s".format(time_wait)
            w, h = self.font.getsize(header_text)
            self.draw_text(header_text, (self.disp.width - w)/2, 13)
            if text is not None:
                if len(text) >= 18:
                    text1 = text[0:17]
                    if len(text) > 17*2:
                        text2 = text[17:34]
                        text3 = text[34:len(text)]
                    else:
                        text2 = text[17:len(text)]
                        text3 = ""
                    self.draw_text(text1, 14, 16+h)
                    self.draw_text(text2, 14, 16+h+h)
                    self.draw_text(text3, 14, 16+h+h+h)
                else:
                    self.draw_text(text, 14, 16+h)
                self.sys_message_cleanup = True
                self.redraw = True
                sleep(1)
                time_wait-=1
        else:
            self.draw.rectangle((10, 8, self.disp.width-10, self.disp.height-7), outline=0, fill=0)

        # restore original page
        self.image = original_image_obj
        self.draw = ImageDraw.Draw(self.image)

        # restore self.standby state to original
        self.standby = standby_stored_state

    #############################################################################
    #                            IMPORT AND LOAD PAGES                          #
    #############################################################################
    # read pages from file
    def __read_pages(self):
        reload_is_necesarry = False
        fileslist = os.listdir(page_files_path)
        if len(fileslist) != self.stored_files_number:
            self.stored_files_number = len(fileslist)
            for actual_file in fileslist:
                module_is_imported = False
                try:
                    first_part, second_part = actual_file.split("_")
                    second_part, third_part = second_part.split(".")
                except:
                    first_part = None
                    third_part = None
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

    #############################################################################
    #                            MAIN FUNCTIONALITIES                           #
    #############################################################################
    def standby_switch(self, mode=None):
        if mode is not None:
            if mode is True and self.standby is False:
                self.oled_sys_message("go to standby", time=1)
                self.standby = True
                # buffer page setup for wake up
                self.head_page_bar_is_enable_backup = self.head_page_bar_is_enable
                self.head_page_bar_switch(False, False)
                # clean display
                sleep(2)
                self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
                self.disp.clear()
                self.display_show()
                sleep(1.5)
            if mode is False and self.standby is True:
                # TODO restore page settings!
                self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
                self.disp.clear()
                # wake up message
                # self.oled_sys_message("oled is ready", time=2)
                sleep(1)
                # load actual page settings
                self.head_page_bar_switch(self.head_page_bar_is_enable_backup[0], self.head_page_bar_is_enable_backup[1])
                self.standby = False

    # show contents on display if device is not busy
    def display_show(self):
        if self.display_is_avaible:
            self.display_is_avaible = False
            self.disp_buffer = self.disp._buffer
            oledlog.logger.info("\n\nself.image draw over i2c: " + str(self.image) + "\n\n")
            print("\n\nself.image draw over i2c: " + str(self.image) + "\n\n")
            self.disp.image(self.image)
            self.disp.display()
            self.display_is_avaible = True

    # draw ppm image
    def draw_image(self, image_path=None, img_mode="store"):
        if img_mode == "store" and image_path is not None: # and self.image_strored is None:
            # conevrt image
            image = Image.open(image_path)
            image_r = image.resize((128,64), Image.BICUBIC)
            image_bw = image_r.convert("1")
            # store previous image
            #self.image_strored = self.image
            # activate new loaded image
            self.image = image_bw
            self.draw = ImageDraw.Draw(self.image)
        elif img_mode == "restore" and image_path is None:
            if self.image_strored is not None:
                # retore normal image
                self.image = self.image_strored
                self.draw = ImageDraw.Draw(self.image)
                #self.image_strored = None

    # header bar - time show
    def __draw_time_text(self, text):
        text = str(text)
        # Write two lines of text.
        w, h = self.font.getsize(text)
        x_text_pos = int((self.disp.width - w)/2)
        # clean text space
        self.draw.rectangle((x_text_pos, 0, x_text_pos+w, 0+h), outline=0, fill=0)
        # draw text
        self.draw.text((x_text_pos, 0), text,  font=self.font, fill=255)

    # text method - cleam area automaticly before draw text
    def draw_text(self, text, x, y):
        text = str(text)
        # Write two lines of text.
        w, h = self.font.getsize(text)
        # clean text space
        self.draw.rectangle((x, y, x+w, y+h), outline=0, fill=0)
        # draw text
        self.draw.text((x, y), text,  font=self.font, fill=255)
        # Display image.
        return w, h

    # main loop - run actual page
    def run(self):
        self.__init_threads()
        try:
            while True:
                if not self.standby:
                    self.run_actual_page()
                    sleep(main_page_refresh_min_delay)
                else:
                    sleep(oled_standby_period)
        except KeyboardInterrupt as e:
            oledlog.logger.info("Exiting " + str(e))

    # run page setup - when actual page is activated
    def actual_page_setup(self, page, force=False):
        if self.page_is_changed(reset_status=False):
            self.actual_page_setup_executed = False
        if not self.actual_page_setup_executed or force:
            page.page_setup(self)
            self.actual_page_setup_executed = True

    # Run selected page
    def run_actual_page(self):
        for index, page in enumerate(self.page_list):
            if int(page[1]) == self.actual_page_index:
                oledlog.logger.info("Call page: " + str(page))
                try:
                    # clean system message if it was printed
                    if self.sys_message_cleanup:
                        self.sys_message_cleanup = False
                        self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
                    # run page setup function
                    #page[2].page_setup(self)
                    self.actual_page_setup(page[2])
                    # if page changed clean page
                    self.clever_screen_clean()
                    # run page
                    ok_button = self.ok_button_event_getter()
                    is_show = page[2].page(self, ok_button)
                except Exception as e:
                    oledlog.logger.warn(str(page[0]) + " - run page exception" + str(e))                  # warning msg to log file
                    self.oled_sys_message("run page exception" + str(e))                # warning msg to screen
                    is_show = False
                if is_show:
                    # Display image.
                    self.redraw = True
                # clever wait, if button press happen, break sleep
                self.run_page_wait(int(page[1]))

    # page smart delay/sleep
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
                self.head_page_bar_switch(False, False)                                 # dummy
                break

    # detect page is changed
    def page_is_changed(self, reset_status=True):
        state = False
        if self.last_page_index != self.actual_page_index:
            if reset_status:
                self.ok_button_event = False                                    # clean page ok button event for the next page
                self.run_page_x_destructor(self.last_page_index)
                self.last_page_index = self.actual_page_index
            state = True
        return state

    # if page gets inactive - run page destructor
    def run_page_x_destructor(self, last_page_index_to_clean):
        for index, page in enumerate(self.page_list):
            if int(page[1]) == last_page_index_to_clean:
                self.draw_image(img_mode="restore")
                # page destructor
                try:
                    page[2].page_destructor(self)
                except Exception as err:
                    oledlog.logger.warn("run page destructor" + str(err))

    # clean page area depends on page and head bar status
    def clever_screen_clean(self, clean_full=False, force_clean=False):
        head_bar_height = 9
        page_bar_height = 5
        if self.page_is_changed() or force_clean:
            if self.head_page_bar_is_enable[0] and self.head_page_bar_is_enable[1]:
                # page and header bar are ON
                self.draw.rectangle((0,head_bar_height,self.disp.width, self.disp.height-page_bar_height), outline=0, fill=0)
                oledlog.logger.info("Clean screen without head - page bar")
            elif not self.head_page_bar_is_enable[0] and not self.head_page_bar_is_enable[1]:
                # page and header bar are OFF
                clean_full = True
            elif not self.head_page_bar_is_enable[0] and self.head_page_bar_is_enable[1]:
                # head bar OFF, page bar ON
                self.draw.rectangle((0,0,self.disp.width, self.disp.height-page_bar_height), outline=0, fill=0)
                oledlog.logger.info("Clean screen without page bar")
            elif self.head_page_bar_is_enable[0] and not self.head_page_bar_is_enable[1]:
                # head bar ON, page bar OFF
                self.draw.rectangle((0,head_bar_height,self.disp.width, self.disp.height), outline=0, fill=0)
                oledlog.logger.info("Clean screen without head bar")
            else:
                oledlog.logger.info("clever_screen_clean impassibrueeeee")

        if clean_full:
            self.draw.rectangle((0,0,self.disp.width, self.disp.height), outline=0, fill=0)
            oledlog.logger.info("Clean full page")

    # class destructor
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
