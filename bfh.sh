#!/bin/bash

self=$(basename "${BASH_SOURCE[0]}" .sh)
fail () { unset -v fail; : "${fail:?$@}"; }
list () { ls ${1:?} | xargs basename -s .sh | xargs -i echo source "<($self {})"; }
lib=${BFH_LIB:-/usr/local/lib/bfh}
[[ $# == 0 ]] && { list $lib; exit 0; }
mod=$lib/${1:?}.sh
[[ -x $mod ]] || fail $mod not a script && $mod "${@:2:$#}" 
