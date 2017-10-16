#!/usr/bin/env bash

depends=()

st_install() {
    C=$DEP_COUNTER
    ((DEP_COUNTER += 1))
}
