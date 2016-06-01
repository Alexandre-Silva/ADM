#!/usr/bin/bash


PACMAN_FLAGS=(
    "--noconfirm"
    "--needed" # does not reistall up-to-date packages
)

pm_pacman() {
    local args=("$@")
    local command=${args[0]}

    local packages=()
    packages+=( ${args[@]:1} )

    local i=0
    local packages_len=${#packages[@]}
    while [[ $i -lt $packages_len ]]; do
        packages[i]="${packages[i]#pm:}"

        i=$(( i + 1 ))
    done

    case $command in
        install) sudo pacman -S "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo pacman -Rns "${PACMAN_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac

    return 0
}


main() {
    if [ -x "/usr/bin/pacman" ]; then
        echo "Found pacman"
        pm_register "pm" "pm_pacman"
    fi

    return 0
}

main
