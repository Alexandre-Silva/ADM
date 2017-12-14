#!/usr/bin/env bash

NPM_FLAGS=( --global )
TO_BE_UNSET+=( "NPM_FLAGS" )

adm_pm__npm() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo npm install "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo npm uninstall "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}

hash npm &>/dev/null && adm_pm_register "npm" "adm_pm__npm"
