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


####
# Functions
####

# Adds an option which can be parsed by adm_parse_opts.
#
# @Param $1:name The name used to identify the option and pass to adm.sh.
#                e.g. verbose is --verbose. The name must not have spaces.
# @Param $2:short_name The short version of the option. Pass '' to ignore this.
# @Param $3:default The initial value for the option in ADM_OPT[${name}]. Pass '' to ignore this.
# @Param $4:parser The function to use when the option is passed to adm.sh. See the section about parsers.
# @Returns: 0 on success -1 if an error is encountered
adm_add_option() {
    local name="$1"
    local short_name="$2"
    local default="$3"
    local parser="$4"

    ADM_OPT["${name}"]="${default}"
    if [[ -n "${short_name}" ]]; then
        ADM_OPTSPEC+="${short_name}"
        ADM_OPT_SHORT["${short_name}"]="${name}"
    fi
    ADM_OPT_PARSE["${name}"]="${parser}"
}


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
            *) # short option convert to
                longopt=ADM_OPT_SHORT[$opt]
                ;;
        esac

        ADM_OPT_PARSE[${longopt}]
    done
}

### Verbose opt init
adm_add_option verbose v t verbose adm_parse_verbose
# help

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
