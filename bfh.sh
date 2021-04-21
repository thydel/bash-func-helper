#!/bin/bash

fail() { unset -v fail; : "${fail:?$@}"; }
lib=${BFH_LIB:-/usr/local/lib/bfh}/${1:?}.sh
[[ -x $lib ]] || fail $lib not a script && $lib "${@:2:$#}" 
