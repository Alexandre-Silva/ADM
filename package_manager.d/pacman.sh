#!/usr/bin/bash

pm_pacman() {
    local args=("$@")
    local command=${args[1]}

    local packages=()
    packages+=( "${args[@]:1}" )

    echo "${packages[@]}"

    i=1
    while [[ $i -le ${#packages} ]]; do
        packages[i]="${packages[i]#pm:}"

        (( i++ ))
    done

    case $command in
        install) sudo pacman -S "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac

    return 0
}


main() {
    if [ -x "/usr/bin/pacman" ]; then
        echo "Found pacman"
        register "pm" "adm_pacman"
    fi

    return 0
}

main
