#!/bin/bash

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
source "$ADM/lib.sh"

__setup() {
    export TEST_DIR="/tmp/ADM-TEST-DIR"
    [[ -e "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    mkdir "$TEST_DIR"

    ln -s "/this/path/does/not/exist" "$TEST_DIR/broken-link"

    echo -e "A_FILE=1\n" > "$TEST_DIR/a_file"
    btr_unset "A_FILE"

    ln -s "$TEST_DIR/a_file" "$TEST_DIR/a_link"

    cat <<EOF > "$TEST_DIR/test.setup.sh"
packages=( pm:fortune-mod )
a_function() { echo 'run'; }
EOF
    export TEST_SETUP="$TEST_DIR/test.setup.sh"


    pm_reset
}

describe "test adm.sh internals"
    it "asserts __extract_var"
        __setup
        __extract_var "$TEST_SETUP" "packages"

        assert equal "${#ret[@]}" "1"
        assert equal "${ret[0]}" "pm:fortune-mod"
    end

    it "find setups"
        __setup
        adm_find_setups "$TEST_DIR"

        assert equal ${#ret[@]} 1
        assert equal "${ret[0]}" "$(realpath $TEST_SETUP)"
    end

    it "extract var"
        __setup
        __extract_var "$TEST_SETUP" "packages"

        assert equal "1" "${#ret[@]}"
        assert equal "pm:fortune-mod" "${ret[0]}"
    end

    it "run function"
        __setup
        out=$(__run_function a_function "$TEST_SETUP" )

        assert equal "$?" "0"
        assert equal "$out" "run"
    end


    it "btr_unset"
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

describe "package managers wrappers"
    describe "register"
        it "register pm"
            __setup
            pm_test() { _called=1; }

            pm_register "test" "pm_test" 1>/dev/null 2>&1

            assert equal "$?" "0"
            assert equal "${package_manager[test]}" "pm_test"
        end

        it "call registered pm"
            __setup
            _called=0
            pm_test() { _called=1; }
            pm_register "test" "pm_test" 1>/dev/null 2>&1

            "${package_manager[test]}"

            assert equal "1" "$_called"
        end

        it "repeated register"
            __setup
            local _called=0
            pm_test1() { _called=1; }
            pm_test2() { _called=2; }

            pm_register "test" "pm_test1" 1>/dev/null 2>&1
            pm_register "test" "pm_test2" 1>/dev/null 2>&1

            assert equal "$?" "1"
            assert equal "${package_manager[test]}" "pm_test1"
        end
    end

    describe "install"
        it "install (empty args)"
            __setup
            pm_install

            assert equal "$?" "0"
        end

        it "install test packages"
            __setup
            local p_called=0
            pm_suffixA() {
                local args=( "$@" )
                local expected=( install foo bar )

                for i in {0..2}; do assert equal "${args[$i]}" "${expected[$i]}"; done

                p_called=1
                return 77 # random number different than 0, 1, and 127
            }

            pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1

            local packages=( "suffixA:foo" "suffixA:bar" )
            pm_install "${packages[@]}"

            assert equal "$?" "77"
            assert equal "$p_called" "1"
        end

        it "install test packages (multi suffix)"
        __setup
            local calledA=0
            pm_suffixA() {
                local args=( "$@" )
                local expected=( install foo )

                for i in {0..2}; do assert equal "${args[$i]}" "${expected[$i]}"; done

                calledA=1
                return 0
            }

            local calledB=0
            pm_suffixB() {
                local args=( "$@" )
                local expected=( install bar )

                for i in {0..2}; do assert equal "${args[$i]}" "${expected[$i]}"; done

                calledB=1
                return 0
            }

            pm_register "suffixA" "pm_suffixA" 1>/dev/null 2>&1
            pm_register "suffixB" "pm_suffixB" 1>/dev/null 2>&1

            local packages=( "suffixA:foo" "suffixB:bar" )
            pm_install "${packages[@]}"

            assert equal "$?" "0"
            assert equal "$calledA" "1"
            assert equal "$calledB" "1"
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