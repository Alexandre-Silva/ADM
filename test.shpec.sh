#!/bin/bash

if [[ -n $BASH_VERSION ]]; then
    # shopt -s extglob
    shopt -s globstar
    # IFS="$(printf '\n\t')"   # Remove space
fi

####
# Imports
####
if [[ -n "$BASH_SOURCE" ]]; then
    export ADM="$(realpath $(dirname $BASH_SOURCE))"
else
    export ADM="$(realpath $(dirname $0))"
fi

# sdm.sh requires commands and will complain about it
# However we are just testing
source "$ADM/adm.sh" noop


if [[ -n "$ZSH_VERSION" ]]; then
    set -o ksh_arrays
fi

__setup_base() {
    export TEST_DIR="/tmp/ADM-TEST-DIR"
    [[ -e "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    mkdir "$TEST_DIR"

    adm_pm_reset
}

__setup() {
    __setup_base

    ln -s "/this/path/does/not/exist" "$TEST_DIR/broken-link"

    echo -e "A_FILE=1\n" > "$TEST_DIR/a_file"
    btr_unset "A_FILE"

    ln -s "$TEST_DIR/a_file" "$TEST_DIR/a_link"

    cat <<EOF > "$TEST_DIR/test.setup.sh"
packages=( pm:fortune-mod )
a_function() { echo 'run'; }
echo_file() { echo $ADM_FILE; }
EOF
    export TEST_SETUP="$TEST_DIR/test.setup.sh"

    touch "$TEST_DIR/setup.sh"
    mkdir "$TEST_DIR/A"
    touch "$TEST_DIR/A/a spaced name.setup.sh"
    touch "$TEST_DIR/A/setup.sh"
    touch "$TEST_DIR/A/not_setup.sh"
    mkdir "$TEST_DIR/B"
    touch "$TEST_DIR/B/some.setup.sh"

    TEST_EXPECTED_SETUPS=( $TEST_DIR/**/*.setup.sh $TEST_DIR/**/setup.sh )
}

__setup_deps() {
    __setup_base

    cp --recursive tests/depends/* "${TEST_DIR}"
}

describe "test adm.sh internals"
    it "asserts adm__extract_var"
        __setup
        adm__extract_var "$TEST_SETUP" "packages"

        assert equal "${#ret[@]}" "1"
        assert equal "${ret[0]}" "pm:fortune-mod"
    end

    it "find setups"
        __setup
        adm_find_setups "$TEST_DIR"
        setups=( "${ret[@]}" )

        assert equal ${#setups[@]} ${#TEST_EXPECTED_SETUPS[@]}

        for i in $(seq 0 ${#expected[@]}); do
            assert equal "${setups[$i]}" "${TEST_EXPECTED_SETUPS[$i]}"
        done
    end

    it "extract setup path"
        __setup
        adm_opts_init

        adm_extract_setup_paths "$TEST_DIR"

        setups=( "${ret[@]}" )
        assert equal ${#setups[@]} 1
        assert equal ${setups[0]} "$TEST_DIR/setup.sh"
    end

    it "extract setup path (empty dir)"
        __setup
        adm_opts_init

        adm_extract_setup_paths "$TEST_DIR/B"

        setups=( "${ret[@]}" )
        assert equal ${#setups[@]} 1
        assert equal ${setups[0]} "$TEST_DIR/B"
    end

    it "extract setups paths recursively"
        __setup
        adm_opts_init
        adm_opts_set_true recursive

        adm_extract_setup_paths "$TEST_DIR"
        setups=( "${ret[@]}" )

        assert equal ${#setups[@]} ${#TEST_EXPECTED_SETUPS[@]}

        for i in $(seq 0 ${#expected[@]}); do
            assert equal "${setups[$i]}" "${TEST_EXPECTED_SETUPS[$i]}"
        done
    end

    it "extracts var"
        __setup
        adm__extract_var "$TEST_SETUP" "packages"

        assert equal "1" "${#ret[@]}"
        assert equal "pm:fortune-mod" "${ret[0]}"
    end

    it "run function"
        __setup
        out=$(adm__run_function a_function "$TEST_SETUP" )

        assert equal "$?" "0"
        assert equal "$out" "run"
    end

    it "passes correct helpers vars"
        __setup

        out=$(adm__run_function echo_file "$TEST_SETUP" )

        assert equal "$?" "0"
        assert equal "$out" "$TEST_SETUP"
    end
end

describe "testing lib.sh functions"
    describe "btr_unset"
        it "unsets 1 var"
            __setup
            local a=1
            btr_unset "a"
            assert equal "" "$a" '`a` was not unset'
        end

        it "btr_unset (multi args)"
            local b=1
            local c=1
            btr_unset "b" "c"
            assert equal "" "$b" '`b` was not unset'
            assert equal "" "$c" '`c` was not unset'
        end

        it "btr_unset_f"
            __setup
            f() { return 0; }
            btr_unset_f "-f" "f"
            f >/dev/null 2>&1 # call f
            assert equal "127" "$?" '`f` was not unset'
        end
    end
end

describe "package managers wrappers"
    describe "register"
        it "register pm"
            __setup
            pm_test() { _called=1; }

            adm_pm_register "test" "pm_test" 1>/dev/null 2>&1

            assert equal "$?" "0"
            assert equal "${package_manager[test]}" "pm_test"
        end

        it "call registered pm"
            __setup
            _called=0
            pm_test() { _called=1; }
            adm_pm_register "test" "pm_test" 1>/dev/null 2>&1

            "${package_manager[test]}"

            assert equal "1" "$_called"
        end

        it "repeated register"
            __setup
            local _called=0
            pm_test1() { _called=1; }
            pm_test2() { _called=2; }

            adm_pm_register "test" "pm_test1" 1>/dev/null 2>&1
            adm_pm_register "test" "pm_test2" 1>/dev/null 2>&1

            assert equal "$?" "1"
            assert equal "${package_manager[test]}" "pm_test1"
        end
    end

    describe "install"
        it "install (empty args)"
            __setup
            adm_pm_install

            assert equal "$?" "0"
        end

        it "install test packages"
            __setup
            local p_called=0
            pm_suffixA() {
                local args=( "$@" )
                local expected=( install foo bar )

                assert arrayeq "${args[@]}" "${expected[@]}"

                p_called=1
                return 77 # arbitrary number different than 0, 1, and 127
            }

            adm_pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1

            local packages=( "suffixA:foo" "suffixA:bar" )
            adm_pm_install "${packages[@]}"

            assert equal "$?" "77"
            assert equal "$p_called" "1"
        end

        it "install test packages (multi suffix)"
            __setup
            local calledA=0
            pm_suffixA() {
                local args=( "$@" )
                local expected=( install foo )

                assert arrayeq "${args[@]}" "${expected[@]}"

                calledA=1
                return 0
            }

            local calledB=0
            pm_suffixB() {
                local args=( "$@" )
                local expected=( install bar )

                assert arrayeq "${args[@]}" "${expected[@]}"

                calledB=1
                return 0
            }

            adm_pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1
            adm_pm_register "suffixB" "pm_suffixB" 1>/dev/null 2>&1

            local packages=( "suffixA:foo" "suffixB:bar" )
            adm_pm_install "${packages[@]}"

            assert equal "$?" "0"
            assert equal "$calledA" "1"
            assert equal "$calledB" "1"
        end

        it "handles dependencies"
            __setup_deps

            export DEP_COUNTER=1 # used for tracking call order

            adm_install_setup "${TEST_DIR}/a.setup.sh"

            assert equal "$A" 3
            assert equal "$B" 2
            assert equal "$C" 1
        end
    end
    describe "linker"
        it "normal file"
            __setup

            adm_link "$TEST_DIR/"{a_file,some-link} >/dev/null 2>&1

            [[ -L "$TEST_DIR/"some-link ]]
            assert equal "$?" 0
            assert symlink "$TEST_DIR/some-link" "$TEST_DIR/a_file"
        end

        it "dont create link to non-existent target"
            __setup
            local target="/this/file/does/not/exist"

            adm_link "$target" "$TEST_DIR/some-link" >/dev/null 2>&1

            assert equal "$?" 1
            assert test "[ ! -e $TEST_DIR/some-link ]"
        end

        it "dont override existent (valid) link"
            __setup

            adm_link "$HOME" "$TEST_DIR/a_link" >/dev/null 2>&1

            assert equal "$?" 1
            assert symlink "$TEST_DIR/a_link" "$TEST_DIR/a_file"
        end

        it "dont override existent file"
            __setup

            adm_link "$HOME" "$TEST_DIR/a_file" >/dev/null 2>&1

            assert equal "$?" 1
            assert symlink "$TEST_DIR/a_link" "$TEST_DIR/a_file"
        end

        it "do nothing if link already points to target"
            __setup

            adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1
            adm_link "$TEST_DIR/"{a_file,another_link} >/dev/null 2>&1

            assert equal "$?" 0
            assert symlink "$TEST_DIR/another_link" "$TEST_DIR/a_file"
        end

        it "linker creates dirs as needed"
            __setup

            adm_link "$TEST_DIR/"{a_file,path/to/link} >/dev/null 2>&1

            assert equal "$?" 0
            assert symlink "$TEST_DIR/path/to/link" "$TEST_DIR/a_file"
        end
    end
end

test_opts_init () {
    adm_opts_init

    adm_opts_add alpha a f adm_opts_set_true "alpha desc"
    adm_opts_add beta b f adm_opts_set_true
    adm_opts_add gamma g f adm_opts_set_true "beta desc"
}

test_opts_assert () {
    assert equal "${ADM_OPT[alpha]}" "$1"
    assert equal "${ADM_OPT[beta]}" "$2"
    assert equal "${ADM_OPT[gamma]}" "$3"
}

describe "Options parsing"
    it "trivial"
        test_opts_init

        test_opts_assert f f f

        adm_opts_parse -a
        test_opts_assert t f f

        test_opts_init
        adm_opts_parse --alpha -a
        test_opts_assert t f f
    end

    it "only intended option has its value changed"
        test_opts_init
        adm_opts_parse -ab
        test_opts_assert t t f

        test_opts_init
        adm_opts_parse -bg
        test_opts_assert f t t

        test_opts_init
        adm_opts_parse -ag
        test_opts_assert t f t

        test_opts_init
        adm_opts_parse --gamma --alpha
        test_opts_assert t f t

        test_opts_init
        adm_opts_parse -b --gamma
        test_opts_assert f t t

        test_opts_init
        adm_opts_parse --gamma -a --beta
        test_opts_assert t t t

        test_opts_init
        adm_opts_parse -gba
        test_opts_assert t t t
    end

    it "Ignores non option"
        test_opts_init

        adm_opts_parse -a
        assert equal $? 0

        adm_opts_parse a
        assert equal $? 0

        adm_opts_parse -a a -a b -a c
        assert equal $? 0
    end

    it "Prints help descriptions"
        test_opts_init

        assert equal "$(adm_opts_help alpha)" "  -a, --alpha\n    alpha desc"
        assert equal "$(adm_opts_help beta)" "  -b, --beta"
    end
end
