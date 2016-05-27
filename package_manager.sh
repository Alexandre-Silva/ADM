#!/usr/bin/bash

####
# Imports
####
source "./lib.sh"

####
# CONFIGS and VARS
####
declare -A package_manager

####
# Funcs
####


pm_register() {
    # the prefix that associates a package to a particular package manager
    # E.g.: `pm` is the system's package manager which in ArchLinux is `pacman`
    local sufix="$1"
    # The func to call for packages of a certain manager
    local func="$2"

    running "Binding $sufix to $func"

    if [[ ! -z ${package_manager[$sufix]} ]]; then
        error "Sufix: $sufix already bound to ${package_manager[$sufix]}"
        return 1
    fi

    package_manager[$sufix]="$2"
    ok

    return 0
}

# This function receives a list packages to install (with suffix)
# and calls the apropriate package manager for each of them
pm_install() {
    local args=( "$@" )
    declare -A packages

    # aggregates packages by suffix in `packages`
    for pckg in "${args[@]}"; do
        local suffix="${pckg%%:*}" # removes the suffix (excluding the `:`)

        # Since bash does not support arrays of arrays we use a really long string
        # containning all packages separated by spaces
        [[ -z ${packages["$suffix"]} ]] && packages["$suffix"]=""
        packages["$suffix"]+=" ${pckg#*:}"  # adds `pckg` name to `packages` to install
    done

    for suffix in "${!packages[@]}"; do
        if [ -n "${package_manager[$suffix]}" ]; then

            # convert long string to actual array of packages
            local packages_array=( ${packages[$suffix]} )
            "${package_manager[$suffix]}" install "${packages_array[@]}"
        else
            error "There is no package manager for suffix: $suffix"
            return 1
        fi
    done

    return 0
}


pm_init() {
    for pm in $(find "package_manager.d" -type f -name "*.sh"); do
        source "$pm"
    done
}

pm_reset() {
    package_manager=()
}
