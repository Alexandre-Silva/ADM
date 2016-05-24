#!/bin/env bash


. "./adm.sh"
. "./lib.sh"


assert_eq() {
    expected="$1"
    result="$2"

    if diff <(printf -- "$expected") <(printf -- "$result") &>/dev/null; then
        ok
    else
        error
        printf "Expected | Result \n"
        diff <(printf -- "$expected") <(printf -- "$result") -y
        printf -- "\n"
    fi

}

test_find_setups() {
    result=$(find_setups .)
    expected="./test.setup\n./test/test.setup"


    assert_eq "$expected" "$result"

}

main() {
    test="test_"$1

    running "$test"

    "$test"
}

main "$@"
