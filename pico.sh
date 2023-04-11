#!/bin/bash

shopt -s expand_aliases

fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
alias args='(($#)) || { declare -f ${FUNCNAME[0]}; false; }'
alias check='declare -p $1 &> /dev/null || declare -f $1 > /dev/null || fail «$1» neither var nor func; '
alias decl='check declare -p $1 &> /dev/null && declare -p $1; declare -f $1'
alias run='(($#)) && { declare -f $1 || fail «$1» not a func; echo "${@@Q}"; }'
with () { args && until [[ $# == 1 || $1 == -- ]]; do decl; shift; done; [[ $1 == -- ]] && shift; run; }
unalias args check decl run

main () { (($#)) && { eval "$@"; exit $?; } || true; }

wrap () { echo "$1 () { $(with ${@:2}); }"; }
load () { source <($@); }

with fail with main wrap load --
