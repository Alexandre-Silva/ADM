#!/usr/bin/env bash

####
# CONFIGS and VARS
####
DOTFILES=${DOTFILES:-$(pwd)}                 # default directory were dotfiles are located
ADM_TMP_DIR=${ADM_TMP_DIR:-"/tmp/ADM"${UID}} # were temporary adm files are stored (created in adm_init)

ret=()

####
# Funcs
####

CD() { builtin cd "$@"; }
LN() { /bin/ln "$@"; }

adm_init() {
    mkdir --parent "${ADM_TMP_DIR}"
    adm_pm_init
}

adm_reset_setup() {
    ret=()
    adm_pm_reset
}

# Finds all setup.sh in a given directory and its sub-directorys.
#
# @Param $1:root_dir Directory to start searching
# @Returns: Stores in ret a alphabetically sorted list of found setups.
adm_find_setups() {
    local root_dir="$1"
    ret=()

    # TODO think of a way to abstract/simplify this option stuff
    # Sets the followin opts, but stores their previous value
    if [[ -n $BASH_VERSION ]]; then
        local opts=(nullglob globstar)
        local -a optset
        for opt in "${opts[@]}"; do
            shopt -q $opt; local optset[$opt]=$?
            ((optset[$opt])) && shopt -s $opt
        done
    fi

    ret=( "${root_dir}"/**/*.setup.sh "${root_dir}"/**/setup.sh )

    # pops the options' previous value
    if [[ -n $BASH_VERSION ]]; then
        for opt in "${opts[@]}"; do
            ((optset[$opt])) && shopt -u $opt
        done
    fi

    btr_unset IFS
}


adm_resolve_depends_rec(){
    local args=("$@")
    local depf="${args[0]}"
    local setups=("${args[@]:1}")

    local i d
    for s in "${setups[@]}"; do
        echo -e "${s} ${s}" >>"${depf}"
        adm__extract_var "${s}" "depends"
        for d in "${ret[@]}"; do
            d="$(realpath "${d}")"
            echo -e "${d} ${s}" >>"${depf}"

            adm_resolve_depends_rec "${depf}" "${d}"
        done
    done
}

adm_resolve_depends() {
    local setups=("$@")

    local depf="${ADM_TMP_DIR}/depends.tsort"
    echo -e "" >"${depf}"

    adm_resolve_depends_rec "${depf}" "${setups[@]}"

    ret=( $(tsort "${depf}") )
}


# installs the provided `setups` files
adm_install_setup() {
    local setups=( "$@" )
    ret=()

    for setup in "${setups[@]}"; do
        if [ ! -f "$setup" ]; then
            error "Non existent setup file: $setup"
            return 1
        fi
    done

    adm_resolve_depends "${setups[@]}" && setups=( "${ret[@]}" ) || return 1

    adm_install_pkgs "${setups[@]}" || return 1

    # prepare temporary dirs
    local curr_dir=$(pwd)
    mkdir --parents --verbose "$ADM_TMP_DIR"
    local template="$(date +"%S:%M:%H_%d-%m-%y")"

    # execute all setups st_install
    for setup in "${setups[@]}"; do
        # create temporary dir for the setup file
        local setup_name="$(basename "${setup}")"
        setup_name="${setup_name%.setup.sh}"
        local tmp_dir="$(mktemp \
                            --tmpdir="${ADM_TMP_DIR}" \
                            --directory \
                            "${setup_name}-${template}"-XXXXX)"
        CD "$tmp_dir"

        adm__run_function "st_install" "$setup"
        local ret_code=$?

        [[ $ret_code -eq 0 ]] || break
    done

    # linkings
    [[ $ret_code -eq 0 ]] && adm_link_setup "${setups[@]}"

    # Clean up
    CD "$curr_dir"
    return $ret_code
}


# finds all *.setup.sh files and removes the all `packages`
adm_remove_setups() {
    ret=()

    adm_find_setups "$DOTFILES"; setups=( "${ret[@]}" )
    for setup in "${setups[@]}"; do
        adm__extract_var "$setup" "packages" || return 0
        adm_pm_remove "${ret[@]}"
    done

    return 0
}


adm_link() {
    local target="$1"
    local name="$2"

    if [[ ! -e "$target" ]]; then
        echo -e "$COL_RED $target: Target does not exist  $COL_RESET"
        return 1
    fi

    if [[ -e "$name" ]]; then
        if [[ -L "$name" ]]; then
            if [[ $(readlink "$name") == "$target" ]]; then
                echo -ne "$COL_CYAN"
                LN --no-target-directory --force --verbose --symbolic "$target" "$name"
                echo -ne "$COL_RESET"
            else
                echo -e "$COL_RED $name: File already exists $COL_RESET"
                return 1
            fi
        else
            echo -e "$COL_RED $name: File already exists $COL_RESET"
            return 1
        fi
    else # either `name` does not exist or is a broken link
        local name_dir=""
        name_dir="$(dirname "$name")"

        echo -ne "$COL_GREEN"
        [[ ! -d  "$name_dir" ]] && mkdir --parents --verbose "$name_dir"
        LN --no-target-directory --force --verbose --symbolic "$target" "$name"
        echo -ne "$COL_RESET"
    fi
    return 0
}

# Creates the soft links specified in the `links` var of the `setups` files
adm_link_setup() {
    local setups=( "$@" )
    ret=()

    adm_resolve_depends "${setups[@]}" && setups=( "${ret[@]}" ) || return 1

    for setup in "${setups[@]}"; do
        adm__extract_var "$setup" "links" || return 1;

        local links=( "${ret[@]}" )

        CD "$(dirname $setup)"

        local i=0
        local j=1
        while (( $i < ${#links[@]} )); do
            adm_link "${links[$i]}" "${links[$j]}"

            (( i += 2 ))
            (( j = i + 1 ))
        done

        CD "$OLDPWD"
    done

    return 0
}

# Installs all packages from the given setup files
adm_install_pkgs() {
    # Find and install all setups packages
    local all_packages=()
    for setup in "$@"; do
        adm__extract_var "$setup" "packages" || return 1
        all_packages+=( "${ret[@]}" )
    done

    adm_pm_install "${all_packages[@]}" || return 1

    return 0
}

# lists all setups
adm_list() {
    local args=( "$@" )
    [[ "${#args[@]}" == 0 ]] && args=("${DOTFILES}")

    for arg in "${args[@]}"; do
        while IFS= read -r -d '' file; do
            local fname="$(basename "$file")"

            if [[ "${fname}" == 'setup.sh' ]]; then
                fname="$(basename "${fname}")/${fname}"
            fi

            printf "${COL_BLUE}%25s${COL_RESET} %s\n" "${fname}" "${file}"
        done < <(find "${arg}" -regextype sed -regex '\(.*.setup.sh\)\|\(setup.sh\)' -type f -print0)
    done

}

# Displays the help page for ADM
adm_help() {
    echo -e "${COL_BLUE}NAME${COL_RESET}"
    echo -e "  adm - Alex Dotfile Manager"
    echo

    echo -e "${COL_BLUE}DESCRIPTION${COL_RESET}"
    echo -e "  TODO"
    echo

    echo -e "${COL_BLUE}OPTIONS${COL_RESET}"
    adm_opts_help_all
}

adm_extract_setup_paths() {
    local setups=()
    for setup in "$@"; do
        if [[ "${ADM_OPT[recursive]}" == t ]]; then
            adm_find_setups "${setup}"; setups=( "${ret[@]}" )

        else
            if [[ -d "${setup}" && -f "${setup}/setup.sh" ]]; then
                setup+="/setup.sh"
            fi
            setups+=( "$(realpath "${setup}")" )
        fi
    done

    ret=( "${setups[@]}" )
}

adm_main() {
    local args=( "$@" )

    adm_sh_on_exit 'adm_cleanup'

    # Handle options
    adm_opts_init
    adm_opts_build_parser
    adm_opts_parse "${args[@]}" && args=( "${ret[@]}" ) # adm_opts_parse places in `ret` the arguments

    if [[ -n "${ADM_OPT[help]}" ]]; then
        adm_help
        return 0
    fi

    adm_init

    local command="${args[0]}"
    args=( "${args[@]:1}" )
    adm_extract_setup_paths "${args[@]}" && args=( "${ret[@]}" )

    case $command in
        install)  adm_install_setup  "${args[@]}"                ;;
        link)     adm_link_setup     "${args[@]}"                ;;
        list)     adm_list           "${args[@]}"                ;;
        noop)                                                    ;; # testing  purposes
        pkgs)     adm_install_pkgs   "${args[@]}"                ;;
        profile)  adm__run_function  "st_profile"  "${args[@]}"  ;;
        rc)       adm__run_function  "st_rc"       "${args[@]}"  ;;
        remove)   adm_remove_setups                              ;;
        help)     adm_help                                       ;;
        *)        error              "Invalid commands: $command" ; return 1 ;;
    esac

    adm_sh_compat_mode_off
    return 0
}

# Last function to be executed which cleanups all the things
adm_cleanup() {
    [[ -d "${ADM_TMP_DIR}" ]] && rm -rf "${ADM_TMP_DIR}"

    adm__clean_setup_env
    adm__mark_functions

    adm_sh_compat_mode_off

    adm__unset_marked
}


####
# Private Funcs
####

# runs a `func` from the given `setup` file
adm__run_function() {
    local args=( "$@" )
    local func="$1"
    local setups=( "${args[@]:1}" )
    ret=()

    local setup
    for setup in "${setups[@]}"; do
        if [ ! -f "$setup" ]; then
            error "Cant run $func on non existent setup file: $setup"
            return 1
        fi

        is_function "$func" && unset "$func"

        adm__source_safe "$setup"

        # __source_sage unsets the common functions defined in setup.sh's
        if is_function "$func"; then
            "$func" || return $?
        fi
    done

    return 0
}

# Extracts a variable with a certain `name` of the `setup` file
adm__extract_var() {
    local setup="$1"
    local name="$2"
    ret=()

    [[ -n "${name+x}" ]] && unset "$name"

    adm__source_safe "$setup"

    # is `name` defined ?
    if $(eval '[[ -z ${'"$name"'+x} ]]'); then
        [[ "${ADM_OPT[verbose]}" == t ]] && info 'Var '"$name"' unset or empty in '"$setup"
        return 0
    fi

    # copies `name` into `ret`
    eval 'ret+=( ${'"$name"'[@]} )'

    return 0
}

# Sources a certain while maintaining certain protections
adm__source_safe() {
    local setup="$1"

    adm__clean_setup_env
    adm__helpers "${setup}"

    source "$setup"
}

adm__clean_setup_env() {
    local vars=( "packages" "links" )
    btr_unset "${vars[@]}"

    local functions=( "st_install" "st_profile" "st_rc")
    btr_unset_f "${functions[@]}"
}

# Setups a few helper vars and funcs to facilitate setup.sh files
#
# Vars:
# - ADM_FILE: The file path of the setup file
# - ADM_DIR: The directory path  of the dir contating the setup.sh file
#
# Funcs:
# - n/a
adm__helpers() {
    local setup="$1"

    ADM_FILE="$(realpath "${setup}")"
    ADM_DIR="$(dirname "${ADM_FILE}")"
}

# Mark helpers vars to be unset
TO_BE_UNSET+=( ADM_FILE ADM_DIR )

# Mark funcs defined inside ADM to be deleted. It works by searching for any
# function which matches `adm_*`
adm__mark_functions() {
    old_env_f=$(mktemp)

    # store func names
    typeset -f | awk '/ \(\) {?$/ && !/^main / {print $1}' >$old_env_f

    # dynamically adds functions of name 'adm_*' to TO_BE_UNSET_f
    while IFS='' read -r func_name || [[ -n "$var_name" ]]; do
        if [[ "$func_name" =~ ^adm_.* ]]; then
            TO_BE_UNSET_f+=( "$func_name" )
        fi
    done < <(cat "${old_env_f}")

    rm -f $old_env_f
}

# Calls btr_unset and btr_unset_f on the values marked to be unset (TO_BE_UNSET and TO_BE_UNSET_f)
adm__unset_marked() {
    btr_unset "${TO_BE_UNSET[@]}"
    btr_unset_f "${TO_BE_UNSET_f[@]}"

    btr_unset "TO_BE_UNSET" "TO_BE_UNSET_f"
}
