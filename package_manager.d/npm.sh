#!/usr/bin/bash

NPM_FLAGS=( --global )
TO_BE_UNSET+=( "NPM_FLAGS" )

pm_npm() {
    local args=( "$@" )
    local command=${args[0]}
    local packages=( ${args[@]:1} )

    case $command in
        install) sudo npm install "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        remove)  sudo npm uninstall "${NPM_FLAGS[@]}" "${packages[@]}" ;;
        *)       err "Invalid command: $command"; return 1 ;;
    esac
}
TO_BE_UNSET_f+=( "pm_npm" )

[[ -x "/usr/bin/npm" ]] && pm_register "npm" "pm_npm"
