#!/usr/bin/env bash

depends=( "${ADM_DIR}/c.setup.sh" )

st_install() {
    B=$DEP_COUNTER
    ((DEP_COUNTER += 1))
}
