#!/usr/bin/env bash

####
# Options global vars (to be used by other scripts)
####
ADM_OPT_QUIET=


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

    while getopts qh opt; do
        local longopt=
        case $opt in
            -)
                val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                longopt="$"
                ;;

            q) ADM_OPT_QUIET=t ;;
            h)
                HELP
                ;;
            \?) #unrecognized option - show help
                error "Option -${BOLD}$OPTARG${OFF} not allowed."
                HELP
                ;;
        esac
    done
}


# source lib.sh
# adm_parse_opts "$@"
# adm_help

OPTSPEC=":hv-:"
while getopts "$OPTSPEC" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                loglevel)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    ;;
                loglevel=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2
                    ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${OPTSPEC:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                    fi
                    ;;
            esac;;
        h)
            echo "usage: $0 [-v] [--loglevel[=]<value>]" >&2
            exit 2
            ;;
        v)
            echo "Parsing option: '-${optchar}'" >&2
            ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
            fi
            ;;
    esac
done
