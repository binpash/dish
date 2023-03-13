#!/usr/bin/env bash

export DISH_TOP=${DISH_TOP:-${BASH_SOURCE%/*}}
export PASH_TOP=${PASH_TOP:-${DISH_TOP}/pash/}
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/"
# point to the local downloaded folders
export PYTHONPATH=${PASH_TOP}/python_pkgs/

"$PASH_TOP/pa.sh" "$@" --distributed_exec