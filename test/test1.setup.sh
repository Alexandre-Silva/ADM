#!/bin/bash

packages=(
  'pm:fortune-mod'
)

install() {
    fortune

    return 0;
}

profile() {
    export TEST_PROFILE="asdaadasda"
}
