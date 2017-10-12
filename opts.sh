#!/usr/bin/env bash

#
# TODO Explaing how this works and why
#

####
# Options parsing constants/globals
####
ADM_OPTSPEC_DEFAULT=":h-:"

TO_BE_UNSET+=( ADM_OPTSPEC_DEFAULT )

####
# Functions
####

adm_opts_init() {
    # clean ADM_OPT*
    btr_unset ADM_OPT ADM_OPT_SHORT ADM_OPT_PARSE OPTIND OPTERR OPTARG


    ADM_OPTSPEC="${ADM_OPTSPEC_DEFAULT}"
    declare -gA ADM_OPT       # Map of option <name> -> <value>
    declare -gA ADM_OPT_SHORT # Map of short options 'name's -> long 'name's (the key in ADM_OPT)
    declare -gA ADM_OPT_L2S   # Map of longopt -> shortopt name
    declare -gA ADM_OPT_PARSE # Map of longopt 'name' -> parsing 'function' for said option
    declare -gA ADM_OPT_HELP  # Map of longopt 'name' -> help string
}

TO_BE_UNSET+=( ADM_OPTSPEC ADM_OPT ADM_OPT_SHORT ADM_OPT_L2S ADM_OPT_PARSE ADM_OPT_HELP)


# Adds an option which can be parsed by adm_parse_opts.
#
# @Returns: 0 on success -1 if an error is encountered
adm_opts_add() {
    local name="$1"       # The name used to identify the option and pass to adm.sh.
                          #   e.g. verbose is --verbose. The name must not have spaces.
    local short_name="$2" # The short version of the option. Pass '' to ignore this.
    local default="$3"    # Initial value for the option in. Pass '' to ignore this.
    local parser="$4"     # Function to use when the option is detected.
                          #   See the section about parsers for more details.
    local desc="$5"       # Help description of the option. Pass '' to ignore this

    ADM_OPT[${name}]="${default}"
    if [[ -n "${short_name}" ]]; then
        ADM_OPTSPEC+="${short_name}"
        ADM_OPT_SHORT[${short_name}]="${name}"
        ADM_OPT_L2S[${name}]="${short_name}"
    fi
    ADM_OPT_PARSE[${name}]="${parser}"

    [[ -n "${desc}" ]] && adm_opts_add_help "${name}" "${desc}"
}

# Adds and help description of an option
#
# @Returns: 0 on success -1 if an error is encountered
adm_opts_add_help() {
    local name="$1" # Name of the option
    local desc="$2" # Description of the option

    # see https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
    if [ ${ADM_OPT[${name}]+abc} ]; then
        ADM_OPT_HELP[${name}]="${desc}"
    else
        error "Failed to add description to non existent option:" "$name"
        return 1
    fi
}


## Let's do some admin work to find out the variables to be used here
BOLD='\e[1;31m'         # Bold Red
REV='\e[1;32m'       # Bold Green


# Prints all help descriptions of all configured options
adm_opts_help_all() {
    if [[ -n $BASH_VERSION ]]; then
        for optname in "${!ADM_OPT_HELP[@]}"; do
            adm_opts_help "${optname}"
            echo
        done

    elif [[ -n $ZSH_VERSION ]]; then
        emulate zsh
        for optname in "${(@k)ADM_OPT_HELP}"; do
            adm_opts_help "${optname}"
            echo
        done
        emulate bash
    fi
}

# Prints the help description of an option
#
# @param $1:optname The name of the option to print
adm_opts_help() {
    local optname="$1"
    local optshort=""

    if [[ -n "${ADM_OPT_L2S[${optname}]}" ]]; then
        optshort="${ADM_OPT_L2S[${optname}]}"
        printf "${COL_BLUE}  -%s, --%s\n${COL_RESET}" "${optshort}" "${optname}"
    else
        printf "${COL_BLUE}  --%s\n${COL_RESET}" "${optname}"
    fi


    if [[ -n "${ADM_OPT_HELP[${optname}]}" ]]; then
        echo "${ADM_OPT_HELP[${optname}]}" | fmt | sed 's/^/    /'
    fi
}

adm_opts_parse2() {
    # DOT NOT REMOVE THIS
    # zsh'S getopts fails to work as intended if the variables are unset rather than empty
    OPTIND=
    OPTARG=

    while getopts "${ADM_OPTSPEC}" opt "$@"; do
        local longopt=""
        case $opt in
            -)
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
            *)
                # convert short option to normal name
                longopt=${ADM_OPT_SHORT[$opt]}
                ;;
        esac

        ${ADM_OPT_PARSE[${longopt}]} "${longopt}" "${ADM_OPT[${longopt}]}"
    done
    return 0
}

adm_opts_parse() {
    local args=( "$@" )
    ret=() # Returns all arguments which are not options

    # In case you wanted to check what variables were passed
    # echo "flags = $*"

    local opts=()
    for arg in "${args[@]}"; do
        if [[ "${arg}" =~ ^-.*$ ]]; then
            opts+=( "${arg}" )
        else
            ret+=( "${arg}" )
        fi
    done
    adm_opts_parse2 "${opts[@]}"
}

adm_opts_build_parser() {
    ### Verbose opt init
    #e.g.:       <longname> <shortname> <default val> <parser fn name> <help description>

    adm_opts_add verbose   v "" adm_opts_set_true "explain what is being done"
    adm_opts_add recursive r "" adm_opts_set_true "recursively searches given directories"
}

## adm_parse_*

# the following functions are helps for common parser operations. Were the first
# argument $1 is always the name of the option and $2 the its value if
# ${ADM_OPT[$opt_name]}


adm_opts_set_true () { ADM_OPT[$1]=t; }
