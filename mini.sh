#!/bin/bash

.run () { declare -f ${1:?}; echo "$@"; }

.src.is-func ()  { declare -f ${1:?} > /dev/null; }
.src.is-param () { declare -p ${1:?} &> /dev/null; }
.src () { { .src.is-func $1 && declare -f $1; } || { .src.is-param $1 && declare -p $1; }; }

.with () { until [[ ${1:?} == -- ]]; do .src $1; shift; done; .run "${@:2}"; }

.funcs () { compgen -A function ${1:?}; }
.vars () { compgen -v ${1:?}; }
.items () { .vars ${1}_; .funcs $1.; }

.use.declare-item () { [[ ${1:?} =~ ^[^._]*[._] ]] && .src $1; }
.use.declare-loop () { .items ${1:?} | while read; do .use.declare-item $REPLY; done; }
.use () { until [[ ${1:?} == -- ]]; do .use.declare-loop $1; shift; done; echo "${@:2}"; }

.unuse () { unset -f $(funcs ${1:?}.); unset $(vars ${1}_); }

.import () { local i; for i in ${@:2}; do alias $i="$1.$i "; done; }
.import '' run src with use unuse

.alias.item () { [[ ${1:?} =~ ^[^.]*[.](.*)$ ]] && alias ${BASH_REMATCH[1]}="$1 "; }
.alias () { for func in $(.funcs $1); do .alias.item $func; done; }

std.as () { user=${1:?} eval "${@:2}"; }
std.on () { eval "${@:2}" | ssh ${user:+${user}@}${1:?} bash; }

std.fail () { unset -v fail; : "${fail:?$@}"; }
std.assert () { $@ || std.fail "$@"; }
std.map () { while read; do "$@" "$REPLY"; done; }

alias index--='local i; for ((i = 1; i <= $# ; ++i)); do [[ ${@:$i:1} == -- ]] && break; done;'
std.pipe () { index-- < <(${@:1:(($i - 1))}) ${@:(($i + 1)):$#}; }
std.amap () { index-- for f in ${@:1:(($i - 1))}; do $f ${@:(($i + 1)):$#}; done; }

std.task () { ${1:?}.target "${@:2}" || $1.rule "${@:2}"; }
.alias std

awk.sum () { awk '{ s += $1 } END { print s }'; }
