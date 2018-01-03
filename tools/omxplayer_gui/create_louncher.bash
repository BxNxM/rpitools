#/bin/bash

omxplayer_gui_path="/home/$USER/rpitools/tools/omxplayer_gui/omx_gui.py"
louncher_path="/home/$USER/Desktop/omx"

if [ -e "$louncher_path" ]
then
    echo -e "$louncher_path is already exists!"
else
    cmd="#!/bin/bash\n"
    cmd+="$omxplayer_gui_path"
    echo -e "$cmd" > "$louncher_path"
    chmod +x "$louncher_path"
    echo -e "$louncher_path omxplayer louncher created!"
fi
