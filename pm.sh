#!/usr/bin/bash

# This files handles the loading and use of various package maneger wrappers in pm.d directory.
#
# The initialization works by sourcing every .sh in pm.d. Each file there should
# regitar one or more prefixed to a function defined in the file. That function
# is the wrapper to the package manager in question.
#
# Once all package mangers are loaded adm_pm_install (and family) can be called
# to perform operations on packages using the wrappers.


##### CONFIGS and VARS

# Association list for prefixes --> package manager functions
declare -A package_manager=()
TO_BE_UNSET+=( package_manager )

##### Funcs

adm_pm_init() {
    for pm in $(find "$ADM/pm.d" -type f -name "*.sh"); do
        source "$pm"
    done
}

adm_pm_register() {
    # the prefix that associates a package to a particular package manager
    # E.g.: `pm` is the system's package manager which in ArchLinux is `pacman`
    local sufix="$1"
    # The func to call for _packages of a certain manager
    local func="$2"

    [[ "${ADM_OPT[verbose]}" == t ]] && running "Binding $sufix to $func"

    if [[ ! -z ${package_manager[$sufix]} ]]; then
        error "Sufix: $sufix already bound to ${package_manager[$sufix]}"
        return 1
    fi

    package_manager[$sufix]="$2"

    return 0
}

# Installs the packages passed as arguments by calling the appropride package manager.
# @param @:_packages Each package must contain the prefix which maps to a pm.
adm_pm_install() {
    local _packages=( "$@" )

    adm_pm__call_func "install" "${_packages[@]}"
    return $?
}

# Like `pm_install` but removes instead of installing the _packages
adm_pm_remove() {
    local _packages=( "$@" )

    adm_pm__call_func "remove" "${_packages}"
    return $?

}

adm_pm_reset() {
    package_manager=()
}

##### private Funcs

# performs `action` to each packge in `raw_packges` using the package install in its suffix
adm_pm__call_func() {
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
