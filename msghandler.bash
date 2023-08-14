#!/bin/bash
#################################################################################################################
#                                                                                                               #
# A simple log/message manager for bash, inspired by the "logging" built in in python                           #
#                                                                                                               #
# Author: Thiarles P. M                                                                                         #
# System Administrator                                                                                          #
#                                                                                                               #
#################################################################################################################
#                                                                                                               #
# How to set this up in your script:                                                                            #
#   1 - source this code                                                                                        #
#   2 - Setup the log configuration using this syntax: logconfig --loglevel=<level> --logfile="<path>"          #
#   3 - You're good to go, log messages using this syntax: logger "<level>" "<message>"                         #
#                                                                                                               #
#   OBS: loglevel and logfile are optional, default values are "debug" and print only if logfile is not set     #
#                                                                                                               #
#################################################################################################################

bashloggerhelpme(){
    echo ''
}

# General log configuration
logconfig(){
    #MyLogLevel="info" # Default loglevel
    DontPrintMessages=false
    # use getopt for easier feature update in the future
    local ARGS=$(getopt -o l::f:: --long loglevel::,logfile::,no_stdout:: -n "$0" -- "$@")
    eval set -- "$ARGS"

    # Process the parsed arguments
    while true; do
        case "$1" in
            -l|--loglevel)
                MyLogLevel="$2"
                shift 2
                ;;
            --logfile)
                MyLogFile="$2"
                # "set logfile to ${MyLogFile}"
                shift 2
                ;;
            --no_stdout)
                DontPrintMessages=true
                # "Will not output messages to standard output"
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Invalid option: $1"
                exit 1
                ;;
        esac
    done

    ### Loglevel validations ###
    case "$MyLogLevel" in
        debug|info|warn|error|dry)
            #echo -e "Setting log level to: $MyLogLevel"
            #MyLogLevel=${MyLogLevel}
            ;;
        *)
            echo -e "Invalid log level: $MyLogLevel\nValid log levels: debug, info, warn, error, dry"
            exit 1
            ;;
    esac

    ### Logfile validations ###
    if [[ -n ${MyLogFile} ]] #prevent execution if logfile is not set
        then
            # If mylogfile is set, create it if necessary
            if  [[ ! -e ${MyLogFile} ]]
                then
                    touch "${MyLogFile}"
                    # "Setting log file to: ${MyLogFile}"
                #else
                    # "Setting log file to: ${MyLogFile}"
            fi 
    fi
}

BuildMessages(){
    ### Execution ###
    MsgTimeNow=$(date +'%d/%m/%Y %H:%M:%S:%3N')
    case ${type} in
        debug) #1
            echo -e "[${MsgTimeNow}] - [DEBUG] - ${message}"
        ;;
        info) #2
            echo -e "[${MsgTimeNow}] - [${GREEN}INFO${RESET}] - ${GREEN}${message}${RESET}"
        ;;
        warn) #3
            echo -e "[${MsgTimeNow}] - [${YELLOW}WARNING${RESET}] - ${YELLOW}${message}${RESET}"
        ;;
        error) #4
            echo -e "[${MsgTimeNow}] - ${YELLOW}[${RED}ERROR${YELLOW}] - ${RED}${message}${RESET}"
        ;;
        dry) #?
            echo -e "[${MsgTimeNow}] - ${GREEN}[${RESET}WOULD RUN THIS${YELLOW}] - ${message}${RESET}"
        ;;
    esac
}

logger(){
    ### Variables ###
    type=${1} # can be debug, info, warn, error or dry
    message=${2}
    #echo -e "loglevel set to: ${loglevel}"
    
    ### Colors ###
    local RESET="\e[0m"
    local RED="\e[31m"
    local YELLOW="\e[33m"
    local GREEN="\e[32m"

    declare -A levelmap=( # map level to number for comparasion
        [debug]='1'
        [info]='2'
        [warn]='3'
        [error]='4'
        [dry]='0'
    )
    # Convert levels to numbers
    ntype=${levelmap[$type]}
    nloglevel=${levelmap[$MyLogLevel]}

    if [[ ${nloglevel} -gt ${ntype} ]] # Do not allow execution if loglevel is higher than the message
        then
            return
    fi

    ### Standard output validation ###
    if ${DontPrintMessages}
        then
            if [[ -n ${MyLogFile} ]]
                then
                    # "Will not print messages on screen, only log them to ${MyLogFile}"
                    BuildMessages >> "${MyLogFile}"
                else
                    echo -e "[${YELLOW}WARNING${RESET}] - Logger execution suppressed: 'no_stdout' is set, and 'logfile' has no value"
                    return
            fi
        else
            if [[ -n ${MyLogFile} ]]
                then
                    # "Will print and log messages"
                    BuildMessages | tee -a "${MyLogFile}"
                else
                    # "Will print only"
                    BuildMessages
            fi
    fi
}

#Example execution:
#loglevel::,logfile::,no_stdout
logconfig --loglevel=debug #--no_stdout #--logfile='./mylog.txt'
logger "debug" "This is a debug message"
logger "info" "This is an info message"
logger "warn" "This is a warning message"
logger "error" "This is an error message"
