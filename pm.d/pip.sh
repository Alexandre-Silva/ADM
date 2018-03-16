#!/usr/bin/env bash

TO_BE_UNSET+=( "PIP_FLAGS" )

PIP_FLAGS=(
    --upgrade # updates packages if installed but not up-to-date
)

adm_pm__pip() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo pip install "${PIP_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

if hash pip &>/dev/null; then
    adm_pm_register "pip" "adm_pm__pip"
fi
