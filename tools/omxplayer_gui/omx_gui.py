#!/usr/bin/python3

#http://easygui.sourceforge.net/tutorial.html
import easygui
import os
import subprocess
import sys

videos_path = "/home/pi/Videos/"

def run_gui(choices):
    msg ="Which movie do you want to play?\nTo exit press cancel."
    title = "OMXPLAYER EASYGUI INTERFACE"
    choice = easygui.choicebox(msg, title, choices)
    return choice

def list_movies():
    videos_path_dict = {}
    global videos_path
    for root, dirs, files in os.walk(videos_path):
        #print(root)
        #print(dirs)
        #print(files)
        for actual_file in files:
            if ".mkv" in actual_file or ".avi" in actual_file:
                path = os.path.join(root, actual_file)
                videos_path_dict[actual_file] = path
                print("Movie found: " + str(path))
    return videos_path_dict

def play_selected_movie(movies_dict, selected):
    if selected is None:
        print("Goodbye!")
        sys.exit(0)
    selected_movie = movies_dict[selected]
    if easygui.ccbox("Play " + str(selected_movie) + " ?", "Movie to play"):
        cmd = "/usr/bin/omxplayer -o hdmi " + str(selected_movie)
        print(cmd)
        output = subprocess.check_output(cmd, shell = True)
        print(output)
    else:
        main()

def main():
    print("Start OMXPLAYER GUI")
    # search movies in the given folder
    movies_dict = list_movies()
    # create choice list
    choices = list(movies_dict.keys())
    # call choicebox
    output = run_gui(choices)
    # run movie
    play_selected_movie(movies_dict, output)

if __name__ == "__main__":
    main()
