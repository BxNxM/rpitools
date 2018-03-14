from Colors import Colors
import time

def header_bar(title, char_width=80, separator="#", color_name=Colors.LIGHT_GRAY):
    text = color_name + " " + separator * int((char_width - len(title))/2) + title + separator * int((char_width - len(title))/2) + Colors.NC + "\n"
    return text

def indicator_bar(value, dim="", pre_text="", char_width=80, min_val=0, max_val=100, active_char="#", passive_char="-", col_scale=[0.45, 0.65]):
    rare_value = value
    char_width -= 4 + len(str(value))
    if dim != "":
        char_width -= 2 + len(dim)
    if pre_text != "":
        char_width -= 1 + len(pre_text)

    if value < min_val:
        value = min_val
    elif value > max_val:
        value = max_val
    delta_val = max_val - min_val
    delta_char = float(char_width) / delta_val
    val_in_char = int(delta_char * value)

    bar_string = active_char * val_in_char
    if len(bar_string) < char_width * col_scale[0]:
        bar_string = Colors.GREEN + bar_string + Colors.NC
    elif len(bar_string) < char_width * col_scale[1]:
        bar_string = Colors.YELLOW + bar_string + Colors.NC
    else:
        bar_string = Colors.RED + bar_string + Colors.NC
    bar_string += passive_char * (char_width - val_in_char)

    if dim == "" and pre_text == "":
        final_printout = " [{}] {}\n".format(bar_string, rare_value)
    elif dim != "" and pre_text == "":
        final_printout = " [{}] {}[{}]\n".format(bar_string, rare_value, dim)
    elif dim != "" and pre_text != "":
        final_printout = " {} [{}] {}[{}]\n".format(pre_text, bar_string, rare_value, dim)
    elif dim == "" and pre_text != "":
        final_printout = " {} [{}] {}\n".format(pre_text, bar_string, rare_value)

    return final_printout

def test_indicator_bar():
    for i in range(-10, 150):
        print(indicator_bar(i, "'C", "CPU"))
        time.sleep(0.2)
