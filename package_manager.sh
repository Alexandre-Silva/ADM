#!/usr/bin/bash

####
# Imports
####
source "$ADM/lib.sh"

##### CONFIGS and VARS
declare -A package_manager=()

TO_BE_UNSET+=( package_manager )


##### Funcs

pm_register() {
    # the prefix that associates a package to a particular package manager
    # E.g.: `pm` is the system's package manager which in ArchLinux is `pacman`
    local sufix="$1"
    # The func to call for _packages of a certain manager
    local func="$2"

    running "Binding $sufix to $func"

    if [[ ! -z ${package_manager[$sufix]} ]]; then
        error "Sufix: $sufix already bound to ${package_manager[$sufix]}"
        return 1
    fi

    package_manager[$sufix]="$2"

    return 0
}
TO_BE_UNSET_f+=( "pm_register" )


# This function receives a list _packages to install (with suffix)
# and calls the apropriate package manager for each of them
pm_install() {
    local _packages=( "$@" )

    __pm_call_func "install" "${_packages[@]}"
    return $?
}
TO_BE_UNSET_f+=( "pm_install" )

# Like `pm_install` but removes instead of installing the _packages
pm_remove() {
    local _packages=( "$@" )

    __pm_call_func "remove" "${_packages}"
    return $?

}
TO_BE_UNSET_f+=( "pm_remove" )

pm_init() {
    for pm in $(find "$ADM/package_manager.d" -type f -name "*.sh"); do
        source "$pm"
    done
}
TO_BE_UNSET_f+=( "pm_init" )

pm_reset() {
    package_manager=()
}
TO_BE_UNSET_f+=( "pm_reset" )

##### private Funcs

# performs `action` to each packge in `raw_packges` using the package install in its suffix
__pm_call_func() {
    local args=( "$@" )
    local action="${args[0]}"
    local raw_packages=( "${args[@]:1}" )

    local -A _packages
    local packages_suffixes=()

    # aggregates packages by suffix in `_packages`
    for pckg in "${raw_packages[@]}" ; do
        [ -z "$pckg" ] && continue

        local suffix="${pckg%%:*}" # removes the suffix (excluding the `:`)

        # Since bash does not support arrays of arrays we use a really long string
        # containning all _packages separated by spaces
        if [[ -z "${_packages[$suffix]}" ]]; then
            _packages[$suffix]="${pckg#*:}"
            packages_suffixes+=( "${suffix}" )
        else
            # adds `pckg` name to `_packages` to install
            _packages[$suffix]+=" ${pckg#*:}"
        fi
    done

    # note that we could have used "${!packages[@]}" to acess the list of keys
    #  of associative array.
    # However, this feature is not portable between bash and zsh. (at least)
    # Hence the use of the `packges_suffixes`.
    for suffix in "${packages_suffixes[@]}"; do
        if [ -n "${package_manager[$suffix]}" ]; then

            # convert long string to actual array of _packages
            # note the lack of "..." around _packages[$suffix]
            local packages_array=( ${_packages[$suffix]} )
            "${package_manager[$suffix]}" "$action" "${packages_array[@]}"

            local ret_code=$?
            [[ $ret_code -ne 0 ]] && return $ret_code
        else
            error "There is no package manager for suffix: $suffix"
            return 1
        fi
    done

    return 0
}
TO_BE_UNSET_f+=( "__pm_call_func" )
