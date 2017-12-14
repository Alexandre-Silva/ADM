#!/bin/bash

echo ">> Testing in bash <<"
NO_COLOR=t bash shpec/bin/shpec ./test.shpec.sh
echo

echo ">> Testing in zsh <<"
NO_COLOR=t zsh -c 'disable -r end; . $(dirname $0:A)/shpec/bin/shpec ./test.shpec.sh'
echo
