#!/usr/bin/python3

#http://easygui.sourceforge.net/tutorial.html
import easygui
import os
import subprocess
import sys
import argparse

user = os.environ['USER']
videos_path_default = "/home/" + str(user) + "/Videos/"
videos_path_remote = "/home/" + str(user) + "/pi_server/SharedMovies"
louncher_creator_path = "/home/" + str(user) + "/rpitools/tools/omxplayer_gui/create_louncher.bash"

# argparser for manual start
parser = argparse.ArgumentParser()
parser.add_argument("-g", "--gui",  action='store_true', help="run omcplayer with easygui")
parser.add_argument("-c", "--console",  action='store_true', help="run omxplayer with console")
parser.add_argument("-cl", "--create_louncher",  action='store_true', help="create graphic louncher to the desktop")
parser.add_argument("-ko", "--kill_omxplayer",  action='store_true', help="kill omxplayer playing")
args = parser.parse_args()
force_gui = args.gui
force_console = args.console
create_louncher = args.create_louncher
iskill_omxplayer = args.kill_omxplayer
is_manual_settings = False
if (force_gui or force_console) and not (force_gui is True and force_console is True) or create_louncher or iskill_omxplayer:
    is_manual_settings = True

# easygui function
def run_gui(choices):
    msg ="Which movie do you want to play?\nTo exit press cancel."
    title = "OMXPLAYER EASYGUI INTERFACE"
    try:
        choice = easygui.choicebox(msg, title, choices)
    except KeyboardInterrupt:
        print("Goodbye")
        choice = None
        sys.exit(0)
    return choice

# console function
def run_console(choices):
    msg ="Which movie do you want to play?\nTo exit press cancel."
    title = "OMXPLAYER CONSOLE INTERFACE"

    for index, movie_name in enumerate(choices):
        print("[ {} ] - {}".format(index, movie_name))
    print(title)
    print(msg)
    try:
        selected_index = int(input("Choose one index from the list! "))
    except KeyboardInterrupt:
        selected_index = None
        print("Goodbye!")
        sys.exit(0)
    except ValueError:
        return run_console(choices)                             # recursive cal!!!
    except Exception as e:
        selected_index = None
        print("Exception: " + str(e))
        sys.exit(1)
    choice = choices[selected_index]
    return choice

# list movies from the given folder - videos_path
def list_movies():
    videos_path_dict = {}
    global videos_path
    for root, dirs, files in os.walk(videos_path_default):
        for actual_file in files:
            if (".mkv" in actual_file or ".avi" in actual_file) and "simple" not in actual_file:
                path = os.path.join(root, actual_file)
                videos_path_dict[actual_file] = path
                print("Movie found: " + str(path))
    for root, dirs, files in os.walk(videos_path_remote):
        for actual_file in files:
            if (".mkv" in actual_file or ".avi" in actual_file) and "simple" not in actual_file:
                path = os.path.join(root, actual_file)
                videos_path_dict[actual_file] = path
                print("Movie found: " + str(path))
    return videos_path_dict

# play selected movie with omxplayer
def play_selected_movie(movies_dict, selected, is_easygui=True):
    if selected is None:
        print("Goodbye!")
        sys.exit(0)
    # get selected movie path
    selected_movie = movies_dict[selected]
    #use with esaygui
    if is_easygui:
        try:
            if easygui.ccbox("Play " + str(selected_movie) + " ?", "Movie to play"):
                cmd = "/usr/bin/omxplayer -o hdmi " + str(selected_movie)
                print(cmd)
                output = subprocess.check_output(cmd, shell = True)
                print(output)
            else:
                main_w_gui()
        except KeyboardInterrupt:
            print("Goodbye")
            sys.exit(0)
    else:
        # use with console
        if str(input("Play " + str(selected_movie) + " ?\nMovie to play[Y/N] ")).lower() == "y":
            cmd = "/usr/bin/omxplayer -o hdmi " + str(selected_movie)
            print(cmd)
            output = subprocess.check_output(cmd, shell = True)
            print(output)
        else:
            main_w_console()

# main with easygui
def main_w_gui():
    print("Start OMXPLAYER GUI")
    # search movies in the given folder
    movies_dict = list_movies()
    # create choice list
    choices = list(movies_dict.keys())
    # call choicebox
    output = run_gui(choices)
    # run movie
    play_selected_movie(movies_dict, output)

# main with console
def main_w_console():
    # search movies in the given folder
    movies_dict = list_movies()
    # create choice list
    choices = list(movies_dict.keys())
    # call choicebox
    output = run_console(choices)
    # run movie
    play_selected_movie(movies_dict, output, is_easygui=False)

def kill_omxplayer():
    cmd = "ps aux | grep -v grep | grep 'omxplayer.bin -o hdmi' | awk '{print $2}'"
    output = subprocess.check_output(cmd, shell = True)
    output_string = output.decode("utf-8")
    pids = output_string.split("\n")
    #print(pids)
    for pid in pids:
        if pid != "":
            cmd = "kill " + str(pid)
            print("STOPPING OMXPLAYER: " + str(cmd))
            output = subprocess.check_output(cmd, shell = True)
            print(output)

# main block
if __name__ == "__main__":
    if is_manual_settings:
        print("Run with manual mode")
        if force_gui:
            main_w_gui()
        if force_console:
            main_w_console()
        if create_louncher:
            output = subprocess.check_output(louncher_creator_path, shell = True)
            print(output.decode("utf-8"))
        if iskill_omxplayer:
            kill_omxplayer()
    else:
        print("Run autodetect mode")
        # X is running, DISPLAY ENV is set
        if "DISPLAY" in os.environ:
            main_w_gui()
        else:
            # run with console gui - X and DISPLAY enc is not exists
            main_w_console()
