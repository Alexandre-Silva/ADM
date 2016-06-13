#!/bin/bash

packages=(
  'pm:fortune-mod'
)

links=(
    "/tmp/a_file" "/tmp/a_link"
)

st_install() {
    fortune

    return 0;
}

st_profile() {
    export TEST_PROFILE="asdaadasda"
}

st_rc() {
    export TEST_RC="asda"
}
