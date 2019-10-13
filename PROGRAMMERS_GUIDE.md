![rpitools_system](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/)

1. [RPITOOLS DEVELOPER GUIDE](#general)
2. [DYNAMIC ENVIRONMENT](#dynamicenv)
3. [POST CONFIGURE API](#postconf)
4. [CONFIGHANDLER](#confhandler)
5. [SHARED MEMORY DICT](#sharedmemdict)
6. [AUTOSYNC](#autosync)
7. [SETUP.BASH](#setup)
8. [OLED API](#oled)

# RPITOOLS DEVELOPER GUIDE <a name="general"></a>

Rpitools is a "hobby" middleware what was designed to setup, controll and maintain your system based on a central configuration `$RPITOOLS_CONFIG`, what you can access with `configeditor`.

The rpitools provides many possiblilites to collaborate, and integrate new application components into the system. Most of the central elements supports easy to use interfaces:

- command line
	- every element has command line access to interract with
- file/config based


This **programmers guide** document want to describe the main solution how to customize the system like a programmer or just a person who is interested in.

---

## DYNAMIC ENVIRONMENT <a name="dynamicenv"></a>

Basically rpitools is a script collection, there are some main scripts and some source wich provides sub-functionality implementtaions.

- user manager
- backup manager
- system monitor
- etc.

> NOTE: Execute `rpihelp` alias for the details. 

System implementation use `bash` and `python` programming languages, opensource and flaxible ...

Rpitools **main goals**

- all scripts managed in git repository
	- embedded version controll, easy to maintain and develop
	- easy to upgrade `rpitools_update`
		- graceful service shutdown
		- git pull --rebase (with stash before if necessary)
		- service launch
		- etc.

There is a need, to access the scripts from everywhere from the system, to aviod (exposed) script path hardcodeing (hardcode path is NOT a good idea as we know, it results a fragile system), so we need a solution for that clain. That was named as **DYNAMIC ENVIRONMENT**.

Somehow we want to highlight a custom script for expose (make it accessible environment wide). To make it accessable as an `alias` and/or `environmant variable` create an indicator file `<name>.rpienv`.

### Lets show an example for you.

```bash
|-- helloworld.rpienv
`-- myscript.bash
```

Here we have a script what we want to use from everywhere `myscript.bash`, but we don't want to know where it is exactly in a file system. SO we want to expose that.

> NOTE: The indicator file `helloworld.rpienv` should be next to the script what we want to expose.

#### helloworld.rpienv

```bash
SCRIPT=myscript.bash
PROP=("env" "alias")
```

The content of the indicator file `<name>.rpienv` has 2 lines.

```bash
SCRIPT=
```

- Write your main script name after `SCRIPT=`

```bash
PROP=()
```

- Bash list type object, write `alias` and/or `env` here.
	- `alias` creates an alias 'shell command'
	- `env` creates an environment variable with original script path for script usage


#### myscript.bash

```
#!/ban/bash

echo -e "Hello world!"
```

or some python script, or what are you want, it must have execute `+x` rights

> NOTE: The rpienv search zone is under `REPOROOT` folder

#### The interpreter script

PATH: `$REPOROOT/rpienv.bash`

You can execute it manually, like:

```
source $REPOROOT/rpienv.bash
```

Parameters `--help`:

```bash
### RPITOOLS ENVIRONMENT GENERATOR ###
-v | --verbose	- print log messages to console
-s | --skipvalidation	- skip env validation
-f | --force	- force recreate env
-d | --dump	- dump *.rpienv files
-p | --process	- process indicator

USAGE[CASE 1]:
1. Create config file next to the script to expose
<ENV/alias name>.rpienv       - replace <>
2. Content of the rpienv config:
SCRIPT=<foo.bash>             - replace <> exposed script name
PROP=("env" "alias")     - mode: env and/or alias

USAGE[CASE 2]:
1. Create config file next to the script where you want to use ENV VARS
link.rpienv
[i] if you don't want to expose any script but, ENV link needed

THE CASE 1 and CASE 2 *.rpienv pathes automatically get .rpienv sourceable
scipt what gets the proper environment back.
```

#### Environment caching

The RPIENV `$REPOROOT/rpienv.bash` (source environment) stores environment in cache for the better loading performance.

Cache path:

```bash
pi@node01:~/echo $ENV_CACHE_PATH
/home/pi/rpitools/cache/rpienv
pi@node01:~/ $ echo $ALIAS_CACHE_PATH 
/home/pi/rpitools/cache/rpialiases
```

> NOTE: Generate env manually: `-f` force resource or system autodecet in case of rpitools repo movement in a system

```bash
source $REPOROOT/rpienv.bash -f -v -p
``` 

#### Use from scripts - access rpitools environment

Create `link.rpienv` empty file next to the script where you want to use 

Generate `rpienv link` next to the script:

```bash
source $REPOROOT/rpienv.bash -f -p
``` 

Source link `.rpienv -> $REPOROOT/rpienv.bash` file from script folder.

```bash
MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $MYDIR/.rpienv
```

## POST CONFIGURE API <a name="postconf"></a>

Search zone: `$REPOROOT/autodeployment/lib/`

Example `tree __template_package_structure/`:

```bash
__template_package_structure/
|-- config
|   |-- orig
|   |   `-- template.config
|   |-- template.config.bak
|   |-- template.config.data
|   |-- template.config.factory
|   |-- template.config.final
|   |-- template.config.finaltemplate
|   `-- template.config.patch
|-- foo_app_configure.run
|-- link.rpienv
`-- main.bash`:
```

Copy folder and replace element with yours.

The key is `<UID_name>.run`:

```bash
TITLE="template main execution"
SCRIPT="main.bash"
RUN_DEPENDENCY=("socketmem_setup")
```

- Fill the `TITLE=` with your app/service/autoconfig name.
- Fill main scipt name `SCRIPT=` it must next to be `<UID_name>.run` file.
- Dependency list for other `<UID_name>` names.

## CONFIGHANDLER <a name="confhandler"></a>

Access for central configuration file storage.

Use from command line, with alias: 

```bash
confighandler <parameters>
```

Use from script, with env var:

```
output="$($CONFIGHANDLER <parameters>)"
```

Parameters `--help`:

```
pi@node01:~/rpitools/example $ confighandler -h
usage: ConfigHandlerInterface.py [-h] [-s SECTION] [-o OPTION] [-l] [-lf] [-u]
                                 [-v]

optional arguments:
  -h, --help            show this help message and exit
  -s SECTION, --section SECTION
                        select section
  -o OPTION, --option OPTION
                        select option
  -l, --list            list config dict
  -lf, --list_formatted
                        list config dict - formatted version
  -u, --user_script     set user script from config [bash]
  -v, --validate        validate configuration
```


## SHARED MEMORY DICT <a name="sharedmemdict"></a>

For multiprocess communication with socket interface - dictionary key - value storage.

Use from command line `alias`

```bash
pi@node01:~/ $ clientMemDict -h
(1) RUN COMMAND: clientMemDict -md -n xx -k yy -v zz
	OR: clientMemDict --memdict --namespace xx --key yy --value zz
(2) RUN COMMAND: clientMemDict -md -n xx -f mm -k yy -v zz
	OR: clientMemDict --memdict --namespace xx --field mm --key yy --value zz
(3) RUN INTERACTIVE MODE: clientMemDict
TOOLS: RESET AND RESTART MEMDICT SERVICE: clientMemDict -r | --reset
TOOLS: RUN TEST MODULE: clientMemDict -tm | --testmodule
```

### Use from script

`output=$($CLIENTMEMDICT <parameters>)` 

#### CONTENT AND STRUCTURE

```bash
pi@node01:~/rpitools $ clientMemDict --show
SHOW DICTIONARY CONTENT:
system								# -n or --namespace
	processes : ALARM			# -k or --key for set value add -v or --value <value>
	linux_services : OK
	temp : OK
	disks : OK
	rpitools_services : OK
	memory : OK
	cpu : OK
	metadata:						# -f or --field for access sub fileds
		info : ===
		description : SYSTEM HEALTH DATA collection for rpitools managed system.
		last_update : 2019-10-01 20:48:02.110540
oled
	joystick : None
	sysbuttons : None
	metadata:
		description : OLED BUTTONS MULTIPROCESS COMMUNICATION, central store.
		last_update : 2019-08-21 22:17:38.782519
rgb
	BLUE : 55
	LED : OFF
	SERVICE : OFF
	GREEN : 55
	RED : 65
	metadata:
		description : RGB VALUES MULTIPROCESS COMMUNICATION, central store.
		last_update : 2019-08-21 22:17:37.710213
general
	born : around2018
	service : rpitools
	metadata:
		dummykey : dummyvalue
		description : GENERAL DEFAULT MEMDICT FRAGMENT for rpitools test purposes.
		last_update : 2019-08-21 22:17:38.747266
```

## AUTOSYNC <a name="autosync"></a>

Sync, copy, move your filder and files locally or remote.

Search zone: `$REPOROOT/config/sync_configs/`

Create  file `<name>.sync`

```bash
#===================== config =====================#
FROM_PATH=/home/pi/foo
TO_PATH=/home/pi/foo_synced

# MODE: copy | move | mirror
# copy: copy content to path
# move: move content to path
# mirror: sync with path, delete what
# FROM_PATH not contains
MODE=copy

# optional parameters:
# if REMOTE_SERVER_USER: None
# section diactivated, local sync enabled
REMOTE_SERVER_USER=None
REMOTE_SERVER_PASSWD=remotepassword
REMOTE_SERVER_HOST=hostname_or_ip

# After ssh-key authentication was successfully set
# delete REMOTE_SERVER_PASSWD content for
# security reasons
TMP_PASSWORD_DELETE=True
#==================================================#
```

Fill with your content.

## SETUP.BASH heart of rpitools <a name="setup"></a>

The central logic of rpitools middleware subsystem. Configure, repair, update, etc.

Autoexecute steps like:

```
 _____  _____  _____  _   _ ______
/  ___||  ___||_   _|| | | || ___ |
\ \'--.| |__    | |  | | | || |_/ /
 `--. \|  __|   | |  | | | ||  __/ 
/\__/ /| |___   | |  | |_| || |    
\____/ \____/   \_/   \___/ \_|    rpitools
```

1. Restore backup
2. [ rpitools ] GET RPITOOLS ENVIRONMENT
3. [ rpitools ] wpa_supplient - config.txt - cmdline.txt SETUP
4. [ rpitools ] /home/pi/rpitools/config/ config linking
5. VALIDATE CUSTOM (USER) CONFIG FILE
6. [ CUSTOM HOSTNAME SETUP ]
7. [ SET USER ] - CUSTOM PASSWORD
8. [ rpitools ] other basic system files: vimrc, .ssh, etc.
9. [ rpitools ] Install requested programs from list /home/pi/rpitools/template/programs.dat
10. [ SECURITY [SSH|UFW|GROUPS] SETUP ]
11. [ rpitools ] PREPARE CONNECTED DISKS WHICH CONTAINS DISKCONF.JSON
12. [STORAGE] CREATE STORAGE STUCTURE FOR RPITOOLS
13. [ rpitools ] Run autodeployment scripts. [ CONFIG POST ACTIONS ]
14. [ SYSTEM CMD CREATE ] - Manual args: /home/pi/rpitools/prepare/system/set_system_wide_commands.bash create | list
15. [ rpitools ] Instantiation UUID: 46139787-6f63-47b3-a562-32242da11344
16. [ rpitools ] LINK STORAGE FOLDERS UNDER /home/pi -> /home/pi/storage/
17. [ rpitools ] Router config - manual
18. [ rpitools ] Set system backup scheduling
19. Create cache backup

#### Execute:

```bash
source $REPOROOT/setup.bash
```

## OLED API <a name="oled"></a>

Oled pages search zone: `${REPOROOT}/rpitools/gpio/oled_128x64/lib/pages`

Default content:

```bash
|-- images
|   |-- happycat_oled_64.ppm
|   |-- katica_draw.png
|   |-- linux.png
|   |-- rpi.png
|   `-- weather_images
|       |-- cloudy.png
|       |-- empty.png
|       |-- mist.png
|       |-- partly_cloudy.png
|       |-- rain.png
|       |-- snow-rain.png
|       |-- snow.png
|       |-- storm.png
|       `-- sunny.png
|-- link.rpienv
|-- page_0.py
|-- page_1.py
|-- page_2.py
|-- page_3.py
|-- page_4.py
|-- page_5.py
|-- page_6.py
|-- page_7.py
|-- page_8.py
|-- page_empty.py
|-- page_joystick_elemets_test.py
|-- page_shapes.py
`-- page_simple_rgb_demo.py
``` 

Page template:

```python
import subprocess
import time

#################################################################################
#                                PAGE 5 - empty page demo                       #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(10)

def page(display, joystick, joystick_elements):
    return False

def page_destructor(displayi, joystick_elements):
    pass
```

#### Create new page

Copy template with new name `page_<next digit>.py`.

```bash
cp ${REPOROOT}/gpio/oled_128x64/lib/pages/page_empty.py ${REPOROOT}/gpio/oled_128x64/lib/pages/page_9.py
```

Restart oled service

```bash
oledinterface --restart
```

oledinterface `-h`

```bash
  -h, --help            show this help message and exit
  -o OLED, --oled OLED  Oled service ON or OFF
  -s, --show            show service status
  -r, --restart         restart oled service
  -b BUTTON, --button BUTTON
                        LEFT / STANDBY / RIGHT / standbyFalse / standbyTrue
  -j JOYSTICK, --joystick JOYSTICK
                        LEFT / RIGHT / UP / DOWN /CENTER
```

#### API Documentation

|                      Phases                   |          Description         |
| :-------------------------------------------: | :--------------------------: |
|  page_setup(display, joystick_elements)       |  Initiate screen - run once
|  page(display, joystick, joystick_elements)   |  Page main loop
|  page_destructor(displayi, joystick_elements) |  Exit page - event function


|                   Function                   |            Description       |
|  ------------------------------------------  | :--------------------------: |
| display.head_page_bar_switch(True, True)     |
| display.display_refresh_time_setter(3)       |
| w, h = display.draw_text("Hello World", x, y)|
| display.draw.rectangle((x, y, x+size, y+size), outline=255, fill=0) |
| display.draw.ellipse((x, y, x+size, y+size), outline=255, fill=0) | 
| display.draw.polygon([(x, y), (x, y+size), (x-size, y)], outline=255, fill=0)| | display.draw.line((x, y, x+size, y+size), fill=255) |
| display.clever_screen_clean(force_clean=True) |
| display.draw_image('path/pics.png')           |
| display.display_show()                        |
| display.disp.clear()                          |

|        joystick keys         |        Description      |
| :--------------------------: | :---------------------: |
|    joystick == "UP"          |   
|    joystick == "LEFT"        |
|    joystick == "RIGHT"       |
|    joystick == "DOWN"        |
|    joystick == "CENTER"      |
|    joystick == "CENTER"      |
 

