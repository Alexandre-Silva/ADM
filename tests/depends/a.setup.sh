#!/usr/bin/env bash

depends=( "${ADM_DIR}/b.setup.sh" )

st_install() {
    A=$DEP_COUNTER
    ((DEP_COUNTER += 1))
}
