#!/usr/bin/env bash

####
# CONFIGS and VARS
####
DOTFILES=${DOTFILES:-$(pwd)}
ADM_INSTALL_DIR=${ADM_INSTALL_DIR:-"/tmp/ADM"}

ret=()

####
# Funcs
####

adm_init() {
    adm_pm_init
}

adm_reset_setup() {
    ret=()
    adm_pm_reset
}

# Finds all setup.sh in a given directory and its sub-directorys.
#
# @Param $1:root_dir Directory to start searching
# @Returns: Trough stdout the files separated with \n alphabetically sorted.
# @Usage: Use inside setups="$(adm_find_setups ...)"; IFS=$'\n' setups=( $setups ); btr_unset IFS
adm_find_setups() {
    local root_dir="$1"

    find "$(realpath "$root_dir")" -type f -name "*.setup.sh" -or -type f -name "setup.sh" | sort
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


    # Find and install all setups packages
    local all_packages=()
    for setup in "${setups[@]}"; do
        adm__extract_var "$setup" "packages" || return 1
        all_packages+=( "${ret[@]}" )
    done

    adm_pm_install "${all_packages[@]}" || return 1

    # prepare temporary dirs
    local curr_dir=$(pwd)
    mkdir --parents --verbose "$ADM_INSTALL_DIR"
    local template="$(date +"%S:%M:%H_%d-%m-%y")"

    # execute all setups st_install
    for setup in "${setups[@]}"; do
        # create temporary dir for the setup file
        local setup_name="$(basename $setup)"
        setup_name="${setup_name%.setup.sh}"
        local tmp_dir="$(mktemp --tmpdir=$ADM_INSTALL_DIR --directory $setup_name-$template-XXXXX)"
        builtin cd "$tmp_dir"

        adm__run_function "st_install" "$setup"
        local ret_code=$?

        [[ $ret_code -eq 0 ]] || break
    done
    set +x

    # linkings
    adm_link_setup "${setups[@]}"

    # Clean up
    builtin cd "$curr_dir"
    return $ret_code
}


# finds all *.setup.sh files and removes the all `packages`
adm_remove_setups() {
    ret=()

    local setups="$(adm_find_setups "$DOTFILES")"; IFS=$'\n'; setups=( $setups ); btr_unset IFS
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
                ln --no-target-directory --force --verbose --symbolic "$target" "$name"
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
        ln --no-target-directory --force --verbose --symbolic "$target" "$name"
        echo -ne "$COL_RESET"
    fi
    return 0
}

# Creates the soft links specified in the `links` var of the `setups` files
adm_link_setup() {
    local setups=( "$@" )
    ret=()

    for setup in "${setups[@]}"; do
        adm__extract_var "$setup" "links" || return 1
        local links=( "${ret[@]}" )

        builtin cd "$(dirname $setup)"

        local i=0
        local j=1
        while (( $i < ${#links[@]} )); do
            adm_link "${links[$i]}" "${links[$j]}"

            (( i += 2 ))
            (( j = i + 1 ))
        done

        builtin cd "$OLDPWD"
    done

    return 0
}


# Calls btr_unset and btr_unset_f on the values marked to be unset (TO_BE_UNSET and TO_BE_UNSET_f)
adm__unset_marked() {
    btr_unset "${TO_BE_UNSET[@]}"
    btr_unset_f "${TO_BE_UNSET_f[@]}"

    btr_unset "TO_BE_UNSET" "TO_BE_UNSET_f"
}

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"

    local setups="$(adm_find_setups "$DOTFILES")"; IFS=$'\n'; setups=( $setups ); btr_unset IFS
    adm_init

    case $command in
        install)
            if [ -n "${args[1]}" ]; then
                adm_install_setup "$(realpath "${args[1]}")"
            else
                echo "No setup provided. Installing ALL of them."
                adm_install_setup "${setups[@]}"
            fi
            ;;

        remove) adm_remove_setups ;;
        profile) adm__run_function "st_profile" "$(realpath "${args[1]}")" ;;
        profiles) adm__run_function "st_profile" "${setups[@]}" ;;
        rc) adm__run_function "st_rc" "$(realpath "${args[1]}")" ;;
        rcs) adm__run_function "st_rc" "${setups[@]}" ;;
        link) adm_link_setup "$(realpath "${args[1]}")" ;;
        links) adm_link_setup "${setups[@]}" ;;
        noop) return 0 ;; # testing purposes
        *) error "Invalid commands: $command" ; return 1 ;;
    esac

    adm__clean_setup_env
    adm__unset_marked

    return 0
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
        warn 'Var '"$name"' unset in '"$setup"
        return 0
    fi

    # copies `name` into `ret`
    ret+=( $(eval 'echo ${'"$name"'[@]}') )

    return 0
}


# Sources a certain while maintaining certain protections
adm__source_safe() {
    local setup="$1"

    adm__clean_setup_env

    [[ -n "${ZSH_VERSION:-}" ]] && emulate zsh
    source "$setup"
    [[ -n "${ZSH_VERSION:-}" ]] && emulate bash
}

adm__clean_setup_env() {
    local vars=( "packages" )
    btr_unset "${bars[@]}"

    local functions=( "st_install" "st_profile" "st_rc")
    btr_unset_f "${functions[@]}"
}
