#!/usr/bin/env bash

RUN_BASH=0
RUN_ZSH=0

for arg in "$@"; do
    case $arg in
        bash|all) RUN_BASH=1 ;;&
        zsh|all) RUN_ZSH=1 ;;&
        bash|zsh|all) ;;
        *) echo "ERROR: Unrecognized option"; exit 1 ;;
    esac
done

export SHPEC_ROOT="$PWD"

if ((RUN_BASH)); then
    echo ">> Testing in bash <<"
    NO_COLOR=t bash shpec/bin/shpec ./test.shpec.sh
    echo
fi

if ((RUN_ZSH)); then
    echo ">> Testing in zsh <<"
    NO_COLOR=t zsh -c 'disable -r end; . $(dirname $0:A)/shpec/bin/shpec ./test.shpec.sh'
    echo
fi
