#!/bin/bash

####
# Imports
####
source "./lib.sh"
source "./package_manager.sh"
####
# CONFIGS and VARS
####
DOTFILES_ROOT=${DOTFILES_ROOT:-$(pwd)}

_packages=()


####
# Funcs
####
reset_setup() {
    _packages=()
    pm_reset
}


find_setups() {
    local root_dir="$1"

    printf -- "%s\n" $(find "$root_dir" -type f -name "*.setup.sh" | sort)
}

extract_packages() {
    local file="$1"

    source "$file"

    # is `packages` defined
    if [ -z ${packages+x} ]; then
        warn 'Var `packages` unset in '"$file"
        return
    fi

    for p in "${packages[@]}"; do
        echo $p
        case p in
            #FIXME should be `pm:*)` but it doesnt work
            *)
                _packages+=( "${p}" )
                ;;
            pm*)
                warn "In file: $file \n"
                warn "Invalid package: $p \n"
                ;;
        esac
    done

    return 0
}

_main() {
    for setup in $(find_setups "$DOTFILES_ROOT"); do
        extract $setup
    done
}
