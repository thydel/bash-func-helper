#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)
fail () { unset -v fail; : "${fail:?$@}"; }
list () { ls ${1:?}/*.sh | xargs basename -s .sh | xargs -i echo source "<($self {})"; }
in-git () { git rev-parse 2> /dev/null; }
repo-name () { git config --get remote.origin.url | xargs basename -s .git; }
dev-mode () { in-git && [[ $(repo-name) == bash-func-helper ]]; }
dev-mode && BFH_LIB=.
lib=${BFH_LIB:-/usr/local/lib/bfh}
[[ $# == 0 ]] && { list $lib; exit 0; }
mod=$lib/${1:?}.sh
[[ -x $mod ]] || fail $mod not a script && $mod "${@:2:$#}" 
