#!/bin/bash

# get arg list pcs
args_pcs=$#
# get arg list
arg_list=($@)

# script path n name
MY_PATH="`dirname \"$0\"`"
MY_NAME="`basename \"$0\"`"

# ------------------- SET ARG PARSER ----------------#
function init() {
    #__________________________!!!!!!!!!___________________________#
    ########################## SET THESE ###########################
    known_args=("man" "debug" "pics" "vid")                             # valid arg list - add new args - call with -- expl: --man
    known_args_subs_pcs=(0 0 1 2)                                       # values for args - expl: --man -> 0, --example -> 1 etc.
    man_for_args=("--man\t\t::\tmanual"\                                # add help text here
                  "--pics\t\t::\ttake picture and save to the given path<1>,  ${known_args_subs_pcs[2]} par"\
                  "--vid\t\t::\ttake video given lenght<1> and save to the given path<2>, ${known_args_subs_pcs[3]} par")
    #______________________________________________________________#
    ################################################################
    known_args_status=()
    known_args_value=()
    error_happened=0

    for init_value in "${known_args[@]}"
    do
        # set value to one
        known_args_status+=("0")
        known_args_value+=("")
    done
}

#--- VALIDATE LISTS SYNCRON & ERRORS & ARG VALUES ---#
function validate() {

    if [[ "${known_args_value[*]}" == *"--"* ]] || [ "$error_happened" -eq 1 ]
    then
        echo -e "[!!!] args error, use --man for more info."
        exit 400
    fi

    if [ "${#known_args[@]}" -ne "${#known_args_subs_pcs[@]}" ]
    then
        echo -e "[!!!] config error, known_args len and known_args_subs_pcs len is not equel!"
        exit 401
    fi

    validcommandwasfind=0
    for iscalled in "${known_args_status[@]}"
    do
        validcommandwasfind=$((validcommandwasfind+iscalled))
    done
    if [ "$validcommandwasfind" -eq 0 ] && [ "$args_pcs" -gt 0 ]
    then
        echo -e "[!!!] valid arg not find, use --man for more info."
        exit 402
    fi
}

# ----------------- ARG PARSER CORE ----------------#
function arg_parse() {
    error_happened=0
    for((i=0;i<"${#arg_list[@]}";i++))
    do
        for((k=0;k<"${#known_args[@]}";k++))
        do
            buffer=""
            case "${arg_list[$i]}" in
                "--${known_args[$k]}")
                    # set value to one
                    known_args_status[$k]="1"
                    args_max=$((i + ${known_args_subs_pcs[$k]} + 1))
                    #echo -e "arg max: $args_max"
                    if [ ${#arg_list[@]} -eq $args_max ] || [ ${#arg_list[@]} -gt $args_max ]
                    then
                        for((args_val="$((i+1))"; args_val<="$i"+"${known_args_subs_pcs[$k]}"; args_val++))
                        do
                            buffer+="${arg_list["$args_val"]} "
                        done
                        known_args_value[$k]="$buffer"
                    else
                       echo -e "${arg_list[$i]} arg required ${known_args_subs_pcs[$k]} parameter, $((${known_args_subs_pcs[$k]}+args_pcs-args_max)) were given"
                        error_happened=1
                        known_args_status[$k]="0"
                    fi
                    # debug message
                    #Message="ARGS METCHED: ${arg_list[$i]} <=> ${known_args[$k]}"
                    ;;
            esac
        done
    done
}
# ------------------- GET STATUS FOR ARG -------------#
function get_arg_status() {
    key="$1"
    for((index=0;index<"${#known_args[@]}";index++))
    do
        if [ "$key" == "${known_args["$index"]}" ]
        then
            echo "${known_args_status["$index"]}"
        fi
    done
}
# ---------------- GET VALUE(S) FOR ARG ---------------#
function get_arg_value() {
    local key="$1"
    local bare_output=""
    for((index=0;index<"${#known_args[@]}";index++))
    do
        if [ "$key" == "${known_args["$index"]}" ]
        then
            bare_output=$(echo "${known_args_value["$index"]}" | sed 's/^ *//g' | sed 's/ *$//g')       # HANDLE TRAILING WHITESPACES
            echo "${bare_output}"
        fi
    done
}
# ---------------------- MAN PAGE --------------------#
function man() {
    if [ "$(get_arg_status "man")" -eq 1 ]
    then
        for manpage in "${man_for_args[@]}"
        do
            echo -e "$manpage"
        done
    fi
}
function debug_print() {
    echo -e "KNOWN ARGS: ${known_args[*]}\t\t\t:::   known arguments"
    echo -e "KNOWN ARGS SUB ELEMENTS PIECES: ${known_args_subs_pcs[*]}\t\t\t:::   known args reguired parameters pieces"
    echo -e "KNOWN ARGS STATUS: ${known_args_status[*]}\t\t\t\t:::   args status, is colled?"
    echo -e "ARGS ARGS VALUE(S): ${known_args_value[*]}\t\t\t\t:::   args reguired read parameters"
}
# ------------------- MAIN FUNCTION -------------------#
function argParseRun() {
    init
    arg_parse
    validate
    if [ "$(get_arg_status "debug")" -eq 1 ]
    then
        debug_print
    fi
    man
}
#:::::::::::::::::::: MAIN USAGE ::::::::::::::::::::::
function main() {
    # run argparser
    argParseRun
    # check arg was called
    if [ "$(get_arg_status "pics")" -eq 1 ]
    then
        # get required arg values
        echo -e "pics was called with parameters: ->|$(get_arg_value "pics")|<-"
        takePICS $(get_arg_value "pics")[0]
    fi
    # check arg was called
    if [ "$(get_arg_status "vid")" -eq 1 ]
    then
        # get required arg values
        echo -e "vid was called with parameters: ->|$(get_arg_value "vid")|<-"
        takeVID $(get_arg_value "vid")[0] $(get_arg_value "vid")[1]
    fi
}

function takePICS() {
    local path="$1"
    if [ -z "$path" ] || [ ! -d "$path" ]
    then
        path="."
    fi
    local pics_path="${path}/img_$(date +"%Y-%m-%d_%H-%M-%S").jpg"
    echo -e "CMD: raspistill -o ${pics_path}"
    raspistill -o "${pics_path}"
    if [ "$?" == 0 ] && [ -e "${pics_path}" ]
    then
        echo -e "\tSUCCESS : ${pics_path}"
    else
        echo -e "\tFAIL"
    fi
}

function takeVID() {
    local path="$1"
    if [ -z "$path" ] || [ ! -d "$path" ]
    then
        path="."
    fi
    local lenght_sec="$2"
    if [ -z "$lenght_sec" ] || [ "$lenght_sec" == "" ]
    then
        lenght_sec=1
    fi
    local pics_path="vid_$(date +"%Y-%m-%d_%H-%M-%S").h264"
    #echo -e "CMD: raspivid -o vid_$(date +"%Y-%m-%d_%H-%M-%S").h264 -t "$((lenght_sec*1000))
    raspivid -o "vid_$(date +"%Y-%m-%d_%H-%M-%S").h264" -t $((lenght_sec*1000))
    if [ "$?" == 0 ] && [ -e "${pics_path}" ]
    then
        echo -e "\tSUCCESS : ${pics_path}"
    else
        echo -e "\tFAIL"
    fi
}

main


