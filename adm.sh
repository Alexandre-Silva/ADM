#!/bin/bash

####
# Imports
####
if [[ -z ${ADM+x} ]]; then
    echo "ERROR: ADM var must be defined with the path to the ADM directory"
    return 1
fi

source "$ADM/lib.sh"
source "$ADM/package_manager.sh"

TO_BE_UNSET+=( "DIR" )
TO_BE_UNSET_f+=( "__import" )

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
    pm_init
}

adm_reset_setup() {
    ret=()
    pm_reset
}

adm_find_setups() {
    local root_dir="$1"
    local setup
    ret=()

    for setup in $(find "$(realpath "$root_dir")" -type f -name "*.setup.sh" | sort); do
        ret+=( "$setup" )
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_find_setups" )


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
        __extract_var "$setup" "packages" || return 1
        all_packages+=( "${ret[@]}" )
    done

    pm_install "${all_packages[@]}" || return 1

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
        cd "$tmp_dir"

        __run_function "st_install" "$setup"
        local ret_code=$?

        [[ $ret_code -eq 0 ]] || break
    done
    set +x

    # linkings
    adm_link_setup "${setups[@]}"

    # Clean up
    cd "$curr_dir"
    return $ret_code
}
TO_BE_UNSET_f+=( "adm_install_setup" )


# finds all *.setup.sh files and removes the all `packages`
adm_remove_setups() {
    ret=()

    adm_find_setups "$DOTFILES" && local setups=( ${ret[@]} )
    for setup in "${setups[@]}"; do
        __extract_var "$setup" "packages" || return 0
        pm_remove "${ret[@]}"
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_remove_setups" )


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
TO_BE_UNSET_f+=( "adm_link" )

# Creates the soft links specified in the `links` var of the `setups` files
adm_link_setup() {
    local setups=( "$@" )
    ret=()

    for setup in "${setups[@]}"; do
        __extract_var "$setup" "links" || return 1
        local links=( "${ret[@]}" )

        local i=0
        local j=1
        while (( $i < ${#links[@]} )); do
            adm_link "${links[$i]}" "${links[$j]}"

            (( i += 2 ))
            (( j = i + 1 ))
        done
    done

    return 0
}
TO_BE_UNSET_f+=( "adm_link_setup" )

adm_main() {
    local args=( "$@" )
    local command="${args[0]}"

    adm_find_setups "$DOTFILES" && local setups=( "${ret[@]}" )

    case $command in
        install)
            pm_init

            if [ -n "${args[1]}" ]; then
                adm_install_setup "$(realpath "${args[1]}")"
            else
                echo "No setup provided. Installing ALL of them."
                adm_install_setup "${setups[@]}"
            fi
            ;;

        remove) pm_init; adm_remove_setups ;;
        profile) __run_function "st_profile" "$(realpath "${args[1]}")" ;;
        profiles) __run_function "st_profile" "${setups[@]}" ;;
        rc) __run_function "st_rc" "$(realpath "${args[1]}")" ;;
        rcs) __run_function "st_rc" "${setups[@]}" ;;
        link) adm_link_setup "$(realpath "${args[1]}")" ;;
        links) adm_link_setup "${setups[@]}" ;;
        *) error "Invalid commands: $command" ; return 1 ;;
    esac

    __clean_setup_env
    btr_unset_marked

    return 0
}
TO_BE_UNSET_f+=( "adm_main" )

####
# Private Funcs
####

# runs a `func` from the given `setup` file
__run_function() {
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

        __source_safe "$setup"

        # __source_sage unsets the common functions defined in setup.sh's
        if is_function "$func"; then
            "$func" || return $?
        fi
    done

    return 0
}
TO_BE_UNSET_f+=( "__run_function" )

# Extracts a variable with a certain `name` of the `setup` file
__extract_var() {
    local setup="$1"
    local name="$2"
    ret=()

    [[ -n "${name+x}" ]] && unset "$name"

    __source_safe "$setup"

    # is `name` defined ?
    if $(eval '[[ -z ${'"$name"'+x} ]]'); then
        warn 'Var '"$name"' unset in '"$setup"
        return 0
    fi

    ret+=( $(eval 'echo ${'"$name"'[@]}') )

    return 0
}
TO_BE_UNSET_f+=( "__extract_var" )


# Sources a certain while maintaining certain protections
__source_safe() {
    local setup="$1"

    __clean_setup_env

    [[ -n "$ZSH_VERSION" ]] && emulate zsh
    source "$setup"
    [[ -n "$ZSH_VERSION" ]] && emulate bash
}

__clean_setup_env() {
    local vars=( "packages" )
    btr_unset "${bars[@]}"

    local functions=( "st_install" "st_profile" "st_rc")
    btr_unset_f "${functions[@]}"
}
TO_BE_UNSET_f+=( "__clean_setup_env" )


####
# Main
####

[ -n "$ZSH_VERSION" ] && emulate bash
adm_main "$@"
[ -n "$ZSH_VERSION" ] && emulate zsh
