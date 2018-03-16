#!/usr/bin/env bash

TO_BE_UNSET+=( "LUAROCKS_FLAGS" )

LUAROCKS_FLAGS=( --local ) # install in "$HOME/.luarocks" rather than "/usr"

adm_pm__luarocks() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install)
            for pkg in "${packages[@]}"; do
                luarocks install "${LUAROCKS_FLAGS[@]}" "${pkg}"
            done
            ;;

        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

if hash luarocks &>/dev/null; then
    adm_pm_register "rock" "adm_pm__luarocks"
fi
