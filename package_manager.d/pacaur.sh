#!/usr/bin/bash

PACAUR_FLAGS=( --silent --noedit --noconfirm --noprogressbar --needed )
TO_BE_UNSET+=( "PACAUR_FLAGS")

pm_pacaur() {
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
        install) pacaur "${PACAUR_FLAGS[@]}" --sync "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac

    return 0
}
TO_BE_UNSET_f+=( "pm_pacaur" )


main() {
    if which "pacaur" >/dev/null 2>&1; then
        echo "Found pacaur"
        pm_register "aur" "pm_pacaur"
    fi

    return 0
}

main
btr_unset_f main
