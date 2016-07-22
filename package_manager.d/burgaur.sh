#!/usr/bin/bash

COWER_FLAGS=(
    --brief
)

BURGAUR_FLAGS=(
    "--noconfirm"
)
TO_BE_UNSET+=( {COWER,BURGAUR}"_FLAGS" )

pm_burgaur() {
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
        install) burgaur "${BURGAUR_FLAGS[@]}" \
                         --make-install "${packages[@]}" \
                         --cower-raw-options "${COWER_FLAGS[@]}"
                 ;;

        remove)  sudo pacman -Rns "${BURGAUR_FLAGS[@]}" "${packages[@]}" ;;

        *)       err "Invalid command: $command"; return 1 ;;
    esac

    return 0
}
TO_BE_UNSET_f+=( "pm_burgaur" )


main() {
    if which "burgaur" >/dev/null 2>&1; then
        echo "Found burgaur"
        pm_register "aur" "pm_burgaur"
    fi

    return 0
}

main
btr_unset_f main
