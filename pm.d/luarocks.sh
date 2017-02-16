#!/usr/bin/bash

TO_BE_UNSET+=( "LUAROCKS_FLAGS" )

LUAROCKS_FLAGS=( --local ) # install in "$HOME/.luarocks" rather than "/usr"

adm_pm__luarocks() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) luarocks install "${LUAROCKS_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

hash luarocks &>/dev/null && adm_pm_register "rock" "adm_pm__luarocks"
