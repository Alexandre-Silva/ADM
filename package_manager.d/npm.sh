#!/usr/bin/bash

NPM_FLAGS=( --global )
TO_BE_UNSET+=( "NPM_FLAGS")

pm_npm() {
    local args=("$@")
    local command=${args[0]}

    local packages=()
    packages+=( ${args[@]:1} )

    local i=0
    local packages_len=${#packages[@]}
    while [[ $i -lt $packages_len ]]; do
        packages[i]="${packages[i]#aur:}"

        (( i++ ))
    done

    case $command in
        install) sudo npm install "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo npm uninstall "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac

    return 0
}
TO_BE_UNSET_f+=( "pm_npm" )


main() {
    if which "npm" >/dev/null 2>&1; then
        echo "Found npm"
        pm_register "npm" "pm_npm"
    fi

    return 0
}

main
btr_unset_f main
