#!/usr/bin/bash

adm_pacman() {
    local args=("$@")
    local command=${args[1]}
    local packages=(${args[@]:1})

    echo "${packages[@]}"

    i=1
    while [[ $i -le ${#packages} ]]; do
        packages[i]="${packages[i]#pm:}"

        (( i++ ))
    done
    echo "${packages[@]}"

    case $command in
        install) sudo pacman -S "${packages[@]}" ;;
        *) err "Invalid command: $command"
    esac
}

install_packages() {
    for pcg in "${_packages[@]}"; do
        adm_pacman "install" "$pcg"
    done
}

main() {
    if [ -x "/usr/bin/pacman" ]; then
        echo "Found pacman"
        register "pm" "adm_pacman"
    fi

    return 0
}

main
