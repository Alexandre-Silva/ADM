#!/usr/bin/bash

####
# Imports
####
source "./adm.sh" >/dev/null 2>&1 # main required commands but we are just testing
source "./lib.sh"

####
# CONFIGS and VARS
####
OK="true"

all_targets=(
    "find_setups"
    "extract_packages"
    "pm_register_ok"
    "pm_register_fail"
    "pm_install_nil"
    "pm_install_1suffix"
    "pm_install_2suffix"
)

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
    expected="./test/test1.setup.sh\n./test/test2.setup.sh"
    find_setups .

    assert_eq "$expected" "$ret"
}

test_extract_packages() {
    extract_packages "./test/test1.setup.sh"

    assert_eq "1" "${#ret[@]}"
    assert_eq "pm:fortune" "${ret[0]}"
}

test_pm_register_ok() {
    local _called=0
    pm_test() { _called=1; }

    pm_register "test" "pm_test" 1>/dev/null 2>&1

    assert_eq "0" "$?"
    assert_eq "pm_test" "${package_manager[test]}"
    "${package_manager[test]}"
    assert_eq "1" "$_called"

}

test_pm_register_fail() {
    local _called=0
    pm_test1() { _called=1; }
    pm_test2() { _called=2; }

    pm_register "test" "pm_test1" 1>/dev/null 2>&1
    assert_eq "0" "$?"

    pm_register "test" "pm_test2" 1>/dev/null 2>&1
    assert_eq "1" "$?"
    assert_eq "pm_test1" "${package_manager[test]}"
}


test_pm_install_nil() {
    pm_install

    assert_eq "0" "$?"
}

test_pm_install_1suffix() {
    local called=0
    pm_suffixA() {
        local args=( "$@" )
        local packages=()
        packages+=( "${args[@]:1}" )

        called=1

        assert_eq "install" "${args[0]}"
        assert_eq "foo"     "${packages[0]}"
        assert_eq "bar"     "${packages[1]}"

        return 77 # random number different than 0, 1, and 127
    }

    pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1

    local packages=( "suffixA:foo" "suffixA:bar" )
    pm_install "${packages[@]}"

    assert_eq "77" "$?"
    assert_eq "1" "$called"
}

test_pm_install_2suffix() {
    local calledA=0
    pm_suffixA() {
        local args=( "$@" )
        local packages=()
        packages+=( "${args[@]:1}" )

        calledA=1

        assert_eq "install" "${args[0]}"
        assert_eq "foo"     "${packages[0]}"

        return 0
    }

    local calledB=0
    pm_suffixB() {
        local args=( "$@" )
        local packages=()
        packages+=( "${args[@]:1}" )

        calledB=1

        assert_eq "install" "${args[0]}"
        assert_eq "bar"     "${packages[0]}"

        return 0
    }

    pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1
    pm_register "suffixB" "pm_suffixB" 1>/dev/null 2>&1

    local packages=( "suffixA:foo" "suffixB:bar" )
    pm_install "${packages[@]}"

    assert_eq "0" "$?"
    assert_eq "1" "$calledA"
    assert_eq "1" "$calledB"
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
    if [[ "$target" = "all" || "$target" = "" ]] ; then
        targets=("${all_targets[@]}")
    else
        targets=( "${argv[@]}" )
    fi

    for t in "${targets[@]}"; do
        adm_test "$t"
    done
}

main "$@"
