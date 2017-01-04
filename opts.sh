#!/usr/bin/env bash

#
# TODO Explaing how this works and why
#

####
# Options parsing constants/globals
####
ADM_OPTSPEC=":hv-:"
declare -A ADM_OPT # Map of option <name> -> <value>
declare -A ADM_OPT_SHORT # Map of short options 'name's -> long 'name's (the key in ADM_OPT)
declare -A ADM_OPT_PARSE # Map of longopt 'name' -> parsing 'function' for said option

### Verbose opt init
ADM_OPTSPEC+=v
ADM_OPT[verbose]=t
ADM_OPT_SHORT[v]=verbose
ADM_OPT_PARSE[verbose]=adm_parse_verbose
adm_parse_verbose() { ADM_OPT[verbose]=f }
# help

####
# Functions
####


## Let's do some admin work to find out the variables to be used here
BOLD='\e[1;31m'         # Bold Red
REV='\e[1;32m'       # Bold Green

#Help function
function adm_help {
    info "Basic usage:${OFF} ${BOLD}adm -d helloworld"
    info "The following switches are recognized. $OFF "
    info "-p ${OFF}  --Sets the environment to use for installing python ${OFF}. Default is ${BOLD} /usr/bin"
    info "-d ${OFF}  --Sets the directory whose virtualenv is to be setup. Default is ${BOLD} local folder (.)"
    info "-v ${OFF}  --Sets the python version that you want to install. Default is ${BOLD} 2.7"
    info "-h${OFF}  --Displays this help message. No further functions are performed."
    info "Example: ${BOLD}adm -d helloworld -p /opt/py27env/bin -v 2.7 ${OFF}"
    exit 1
}

adm_parse_opts() {
    # In case you wanted to check what variables were passed
    # echo "flags = $*"

    while getopts "${OPTSPEC}" opt; do
        local longopt=
        case $opt in
            -)
                val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                longopt="${OPTARG}"
                ;;
            h)
                adm_help
                break
                ;;
            \?)
                #unrecognized option - show help
                error "Option -${BOLD}$OPTARG${OFF} not allowed."
                adm_help
                break;
                ;;
            *) # small option name
                longopt=ADM_OPT_SHORT[$opt]
                ;;
        esac

        ADM_OPT_PARSE[${longopt}]
    done
}


# source lib.sh
# adm_parse_opts "$@"
# adm_help

# while getopts "$OPTSPEC" optchar; do
#     case "${optchar}" in
#         -)
#             case "${OPTARG}" in
#                 loglevel)
#                     val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
#                     echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
#                     ;;
#                 loglevel=*)
#                     val=${OPTARG#*=}
#                     opt=${OPTARG%=$val}
#                     echo "Parsing option: '--${opt}', value: '${val}'" >&2
#                     ;;
#                 *)
#                     if [ "$OPTERR" = 1 ] && [ "${OPTSPEC:0:1}" != ":" ]; then
#                         echo "Unknown option --${OPTARG}" >&2
#                     fi
#                     ;;
#             esac;;
#         h)
#             echo "usage: $0 [-v] [--loglevel[=]<value>]" >&2
#             exit 2
#             ;;
#         v)
#             echo "Parsing option: '-${optchar}'" >&2
#             ;;
#         *)
#             if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
#                 echo "Non-option argument: '-${OPTARG}'" >&2
#             fi
#             ;;
#     esac
# done
