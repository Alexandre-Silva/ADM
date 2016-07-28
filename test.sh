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

shpec test.shpec.sh
