#!/usr/bin/env bash

# This files handles the loading and use of various package manager wrappers in
# pm.d directory.
#
# The initialization works by sourcing every .sh in pm.d. Each file there should
# register one or more prefixed to a function defined in the file. That function
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
    # The func to call for packages of a certain manager
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
    local packages=( "$@" )

    adm_pm__call_func "install" "${packages[@]}"
    return $?
}

# Like `pm_install` but removes instead of installing the packages
adm_pm_remove() {
    local packages=( "$@" )

    adm_pm__call_func "remove" "${packages}"
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

    local -A packages
    local packages_suffixes=()

    # aggregates packages by suffix in `packages`
    for pckg in "${raw_packages[@]}" ; do
        [ -z "$pckg" ] && continue

        local suffix="${pckg%%:*}" # removes the suffix (excluding the `:`)

        # Since bash does not support arrays of arrays we use a really long string
        # containning all packages separated by spaces
        if [[ -z "${packages[$suffix]}" ]]; then
            packages[$suffix]="${pckg#*:}"
            packages_suffixes+=( "${suffix}" )
        else
            # adds `pckg` name to `packages` to install
            packages[$suffix]+=" ${pckg#*:}"
        fi
    done

    # note that we could have used "${!packages[@]}" to acess the list of keys
    #  of associative array.
    # However, this feature is not portable between bash and zsh. (at least)
    # Hence the use of the `packges_suffixes`.
    for suffix in "${packages_suffixes[@]}"; do
        if [ -n "${package_manager[$suffix]}" ]; then

            # convert long string to actual array of packages
            # note the lack of "..." around packages[$suffix]
            local packages_array=( ${packages[$suffix]} )
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
