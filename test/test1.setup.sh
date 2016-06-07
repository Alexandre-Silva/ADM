#!/bin/bash

packages=(
  'pm:fortune-mod'
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
