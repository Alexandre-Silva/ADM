#!/bin/bash

####
# Imports
####
. "./lib.sh"

####
# CONFIGS and VARS
####
DOTFILES_ROOT=${DOTFILES_ROOT:-$(pwd)}

_packages=()


####
# Funcs
####
find_setups() {
    local root_dir="$1"

    printf -- "%s\n" $(find "$root_dir" -type f -name "*.setup.sh")
}

extract_packages() {
    local file="$1"

    . "$file"

    # is `packages` defined
    if [ -z ${packages+x} ]; then
        warn 'Var `packages` unset in '"$file"
        return
    fi

    for p in "${packages[@]}"; do
        case p in
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




OK="true"

assert_eq() {
    expected="$1"
    result="$2"

    if diff <(printf -- "$expected") <(printf -- "$result") >/dev/null 2>&1; then
        OK="true"
    else
        OK="false"
        echo "Expected | Result "
        diff <(printf -- "$expected") <(printf -- "$result") -y
        printf -- "\n"
    fi

}

_main() {
    for setup in $(find_setups "$DOTFILES_ROOT"); do
        extract $setup
    done
}
