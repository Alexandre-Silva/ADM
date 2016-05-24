#!/bin/bash
DOTFILES_ROOT=${DOTFILES_ROOT:-$(pwd)}


function find_setups () {
    local root_dir="$1"

    printf -- "%s\n" $(find "$root_dir" -type f -name "*.setup")
}

function extract () {
    local file="$1"


}

function main () {
    find_setups

    for setup in $(find_setups "$DOTFILES_ROOT"); do
        extract $setup
    done
}
