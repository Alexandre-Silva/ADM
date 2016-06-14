#!/usr/bin/bash

####
# Imports
####

# sdm.sh requires commands and will complain about it
# However we are just testing
source "./adm.sh" >/dev/null 2>&1
source "./lib.sh"

####
# CONFIGS and VARS
####
OK="true"

all_targets=()

####
# Funcs
####
assert_eq() {
    local expected="$1"
    local result="$2"
    local msg="$3"

    if diff <(printf -- "$expected") <(printf -- "$result") >/dev/null 2>&1; then
        OK="true"
    else
        OK="false"
        echo "Expected | Result -- $msg"
        diff <(printf -- "$expected") <(printf -- "$result") -y
        printf -- "\n"
    fi

}

all_targets+=( "find_setups" )
test_find_setups() {
    adm_find_setups .

    assert_eq "2" ${#ret[@]}
    assert_eq "./test/test1.setup.sh" "${ret[0]}"
    assert_eq "./test/test2.setup.sh" "${ret[1]}"
}

all_targets+=( "extract_var" )
test_extract_var() {
    __extract_var "./test/test1.setup.sh" "packages"

    assert_eq "1" "${#ret[@]}"
    assert_eq "pm:fortune-mod" "${ret[0]}"
}

all_targets+=( "pm_register_ok" )
test_pm_register_ok() {
    local _called=0
    pm_test() { _called=1; }

    pm_register "test" "pm_test" 1>/dev/null 2>&1

    assert_eq "0" "$?"
    assert_eq "pm_test" "${package_manager[test]}"
    "${package_manager[test]}"
    assert_eq "1" "$_called"

}

all_targets+=( "pm_register_fail" )
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


all_targets+=( "pm_install_nil" )
test_pm_install_nil() {
    pm_install

    assert_eq "0" "$?"
}

all_targets+=( "pm_install_1suffix" )
test_pm_install_1suffix() {
    local p_called=0
    pm_suffixA() {
        local args=( "$@" )
        local packages=()
        packages+=( "${args[@]:1}" )

        p_called=1

        assert_eq "install" "${args[0]}"
        assert_eq "foo"     "${packages[0]}"
        assert_eq "bar"     "${packages[1]}"

        return 77 # random number different than 0, 1, and 127
    }

    pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1

    local packages=( "suffixA:foo" "suffixA:bar" )
    pm_install "${packages[@]}"

    assert_eq "77" "$?"
    assert_eq "1" "$p_called" "pm_suffixA call"
}

all_targets+=( "pm_install_2suffix" )
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

all_targets+=( btr_unset )
test_btr_unset() {
    local a=1
    btr_unset "a"
    assert_eq "" "$a" '`a` was not unset'

   local b=1
   local c=1
   btr_unset "b" "c"
   assert_eq "" "$b" '`b` was not unset'
   assert_eq "" "$c" '`c` was not unset'
}

all_targets+=( "btr_unset_f" )
test_btr_unset_f() {
    f() { return 0; }
    btr_unset_f "-f" "f"
    f >/dev/null 2>&1 # call f
    assert_eq "127" "$?" '`f` was not unset'

}

__setup_link_test() {
    export TEST_DIR="/tmp/ADM-TEST-DIR"
    [[ -e "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    mkdir "$TEST_DIR"

    ln -s "/this/path/does/not/exist" "$TEST_DIR/broken-link"

    echo -e "A_FILE=1\n" > "$TEST_DIR/a_file"
    btr_unset "A_FILE"

    ln -s "$TEST_DIR/"{a_file,a_link}
}

all_targets+=( "link_file_normal" )
test_link_file_normal() {
    __setup_link_test

    adm_link "$TEST_DIR/"{a_file,some-link} >/dev/null 2>&1

    [[ -L "$TEST_DIR/"some-link ]]
    assert_eq "$?" 0 "some-link not created"

}

all_targets+=( "link_target_not_exist" )
test_link_target_not_exist() {
   __setup_link_test

   adm_link "/this/file/does/not/exist" "$TEST_DIR/some-link" >/dev/null 2>&1

   assert_eq "$?" 1 "adm_link did not return 1"

   [[ ! -e "$TEST_DIR/some-link" ]]
   assert_eq "$?" 0 "some-link created"
}

all_targets+=( "link_name_already_exists_link" )
test_link_name_already_exists_link() {
    __setup_link_test

    adm_link "$HOME" "$TEST_DIR/a_link" >/dev/null 2>&1

    assert_eq "$?" 1 "adm_link did not return 1"

    [[ $(readlink "$TEST_DIR/a_link") == "$TEST_DIR/a_file" ]]
    assert_eq "$?" 0 "overwrote existing valid link"
}

all_targets+=( "link_name_already_exists_file" )
test_link_name_already_exists_file() {
    __setup_link_test

    adm_link "$HOME" "$TEST_DIR/a_file" >/dev/null 2>&1

    assert_eq "$?" 1 "adm_link did not return 1"

    [[ $(readlink "$TEST_DIR/a_link") == "$TEST_DIR/a_file" ]]
    assert_eq "$?" 0 "overwrote existing file"
}

all_targets+=( "link_overwrite_expected" )
test_link_overwrite_expected() {
    __setup_link_test

    adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1
    adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1

    assert_eq "$?" 0 "adm_link did not return 0"

    [[ $(readlink "$TEST_DIR/a_link") == "$TEST_DIR/a_file" ]]
    assert_eq "$?" 0 "overwrote existing pretended link to an invalid one"
}


all_targets+=( "link_overwrite_expected" )
test_link_overwrite_expected() {
    __setup_link_test

    adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1
    adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1

    assert_eq "$?" 0 "adm_link did not return 0"

    [[ $(readlink "$TEST_DIR/a_link") == "$TEST_DIR/a_file" ]]
    assert_eq "$?" 0 "overwrote existing pretended link to an invalid one"
}


adm_test() {
    _target="test_"$1

    OK="true"

    running "$_target"
    "$_target"

    adm_reset_setup

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
