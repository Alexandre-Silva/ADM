#!/usr/bin/bash

####
# Imports
####
. "./adm.sh"
. "./lib.sh"

####
# CONFIGS and VARS
####
OK="true"

####
# Funcs
####
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

test_find_setups() {
    expected="./test.setup.sh\n./test/test.setup.sh"
    result=$(find_setups .)

    assert_eq "$expected" "$result"
}

test_extract_packages() {
    extract_packages "./test/test.setup.sh"

    assert_eq "1" "${#_packages[@]}"
    assert_eq "pm:fortune" "${_packages[0]}"
}


adm_test() {
    _target="test_"$1

    OK="true"

    running "$_target"
    "$_target"

    reset_setup

    if [ "$OK" = "true" ]; then ok; else error; fi
}

main() {
    local argv=("$@")
    local target=$1

    local targets=()
    if [[ "$target" = "all" ]] ; then
        targets=("find_setups" "extract_packages")
    else
        targets=( "${argv[@]}" )
    fi

    for t in "${targets[@]}"; do
        adm_test "$t"
    done
}

main "$@"
