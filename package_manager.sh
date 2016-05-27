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


pm_init() {
    for pm in $(find "package_manager.d" -type f -name "*.sh"); do
        source "$pm"
    done
}

pm_reset() {
    package_manager=()
}
