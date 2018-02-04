import time

class JoystickElementsBase():

    def __init__(self, x, y, w, h):
        self.x = x
        self.y = y
        self.width = w
        self.height = h
        self.is_active = False

    def set_activate_state(self, state):
        if type(state) is bool:
            self.is_active = state
        return self.is_active

    def get_activate_state(self):
        return self.is_active

class JoystickElement_button(JoystickElementsBase):

    def __init__(self, display, x, y, w=26, h=13, init_state=False):
        try:
            super().__init__(x, y, w, h)
        except:
            JoystickElementsBase.__init__(self, x, y, w, h)
        self.display = display
        self.button_state = init_state
        self.draw_button()

    def draw_button(self):
        self.set_activate_indicator()
        self.display.draw.rectangle((self.x, self.y, self.x + self.width, self.y + self.height), outline=255, fill=0)

        text_x = self.x+2+2
        text_y = self.y+1
        if self.button_state:
            print("Button is ON")
            w, h = self.display.draw_text("ON ", text_x, text_y)
        else:
            print("Button is OFF")
            w, h = self.display.draw_text("OFF", text_x, text_y)

    def set_activate_indicator(self):
        if self.is_active:
            self.display.draw.rectangle((self.x-2, self.y-2, self.x + self.width + 2, self.y + self.height + 2), outline=255, fill=0)
        else:
            self.display.draw.rectangle((self.x-2, self.y-2, self.x + self.width + 2, self.y + self.height + 2), outline=0, fill=0)

    def set_state(self, state):
        if type(state) is bool:
            self.button_state = state
            self.draw_button()
            self.display.display_show()

    def get_state(self):
        return self.button_state

    def set_activate_state(self, state):
        try:
            super().set_activate_state(state)
        except:
            JoystickElementsBase.set_activate_state(self, state)
        self.draw_button()
        self.display.display_show()

class JoystickElement_value_bar(JoystickElement_button):

    def __init__(self, display, x, y, w=26, h=13, valmax=100, valmin=0, title=None, init_state=False):
        self.title = title
        self.actual_value = 0
        self.valmax = valmax
        self.valmin = valmin
        h = 64-y-10
        try:
            super().__init__(display, x, y, w, h, init_state)
        except:
            JoystickElement_button.__init__(self, display, x, y, w, h, init_state)

    def draw_button(self):
        self.set_activate_indicator()
        self.display.draw.rectangle((self.x, self.y, self.x + self.width, self.y + self.height), outline=255, fill=0)
        self.draw_title(self.title)
        self.draw_val()

    def draw_title(self, title):
        if title is not None:
            text_x = self.x
            text_y = self.y - 11
            w, h = self.display.draw_text(title, text_x, text_y)

    def draw_val(self):
        value = self.actual_value
        if value is not None:
            text_x = self.x + 2
            text_y = self.y + ((self.width / 2) - 4)
            w, h = self.display.draw_text(value, text_x, text_y)

    def set_value(self, delta=None, direct=None):
        if delta is not None and type(delta) is int:
            self.actual_value += delta
            if self.actual_value > self.valmax:
                self.actual_value = self.valmax
            if self.actual_value < self.valmin:
                self.actual_value = self.valmin
        elif direct is not None and type(direct) is int:
            self.actual_value = direct
        self.draw_button()

    def get_value(self):
        return self.actual_value

class JoystickElementManager():

    def __init__(self):
        self.element_list = []
        self.title_list = []
        self.active_element_index = 0
        self.is_first_run = True

    def add_element(self, element, title=None):
        if isinstance(element, JoystickElement_button):
            self.element_list.append(element)
            self.title_list.append(title)

    def draw_elements(self, checked=True):
        for index, element in enumerate(self.element_list):
            if index == self.active_element_index:
                if not element.get_activate_state() and checked:
                    element.set_activate_state(True)
                if not checked:
                    element.set_activate_state(True)
            else:
                if element.get_activate_state() and checked:
                    element.set_activate_state(False)
                if not checked:
                    element.set_activate_state(False)

    def run_elements(self, joystick):
        is_changed = False
        if joystick is not None:
            if joystick == "RIGHT":
                self.active_element_index += 1
                if self.active_element_index >= len(self.element_list):
                    self.active_element_index = 0
            elif joystick == "LEFT":
                self.active_element_index -= 1
                if self.active_element_index < 0:
                    self.active_element_index = len(self.element_list) - 1
            elif joystick == "CENTER":
                is_changed = True
                new_state = not self.element_list[self.active_element_index].get_state()
                self.element_list[self.active_element_index].set_state(new_state)

        # draw elements
        if self.is_first_run:
            self.is_first_run = False
            self.draw_elements(checked=False)
        else:
            self.draw_elements(checked=True)

        # return
        if is_changed:
            return self.title_list[self.active_element_index], self.element_list[self.active_element_index].get_state()
        else:
            return None, None

def test_JoystickElement_button(display):
    je_button = JoystickElement_button(display, x=20, y=20)
    # set button activate state (True-active/False-inactive)
    je_button.set_activate_state(True)
    # set button state (True-ON/False-OFF)
    je_button.set_state(True)
    # get button state:
    print(je_button.get_state())
    # get button is active
    print(je_button.get_activate_state())


manag = None
def test_JoystickElementManager(display, joystick, mode=None):
    global manag
    if mode == "init":
        je_button = JoystickElement_button(display, x=20, y=20)
        je_button2 = JoystickElement_button(display, x=50, y=20)
        je_button3 = JoystickElement_button(display, x=80, y=20)

        manag = JoystickElementManager()
        manag.add_element(je_button, "button1")
        manag.add_element(je_button2, "button2")
        manag.add_element(je_button3, "button3")
        time.sleep(1)

    if mode == "run":
        change = manag.run_elements(joystick)
        if change[1] is not None:
            print("#"*100)
            print("name: " + str(change[0]) + " value: " + str(change[1]))
            print("#"*100)

manag2 = None
def test_JoystickElementManager2(display, joystick, mode=None):
    global manag2
    if mode == "init":
        je_button = JoystickElement_value_bar(display, x=20, y=20, title="A")
        je_button.set_value(delta=42)
        je_button2 = JoystickElement_value_bar(display, x=50, y=20, title="B")
        je_button3 = JoystickElement_value_bar(display, x=80, y=20, title="C")

        manag2 = JoystickElementManager()
        manag2.add_element(je_button, "valuebar1")
        manag2.add_element(je_button2, "valuebar2")
        manag2.add_element(je_button3, "valuebar3")
        time.sleep(1)

    if mode == "run":
        change = manag2.run_elements(joystick)
        if change[1] is not None:
            print("#"*100)
            print("name: " + str(change[0]) + " value: " + str(change[1]))
            print("#"*100)
