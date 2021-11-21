#!/usr/bin/env bash

lib () { for i in ${@:2}; do BASH_ALIASES[$i]=${1:?}.$i; done; }

lib src macro
macro () { local -n a=BASH_ALIASES; for i; do [ -v a[$i] ] && { local v=${BASH_ALIASES[$i]}; [ "${v: -1}" != " " ] && a[$i]+=" "; }; done; }

lib std splitargs mapargs; macro mapargs
splitargs () {
    local i; local -n _a=${1:?} _b=${2:?}; shift 2; for ((i=1; i<=$#; ++i)); do test "${@:$i:1}" == -- && break; done; _a=("${@:1:(($i-1))}"); _b=("${@:(($i+1)):$#}"); }
mapargs () { local cmd args; splitargs cmd args "$@"; for i in "${args[@]}"; do "${cmd[@]}" "$i"; done; }

lib src one all loop head use
one () { test -v ${2:?} || test -v $2[@] && declare -p $2; declare -f $2; [ -v BASH_ALIASES[${2/#${1:?}.}] ] && alias ${2/#$1.}; }
all () { compgen -A function ${1:?}.; compgen -v $1_; echo $1; }
loop () { mapargs one ${1:?} -- $(all $1); }
head () { mapargs echo -- 'set -euo pipefail' 'shopt -s expand_aliases'; }
use () { head; local libs cmd; splitargs libs cmd "$@"; mapargs loop -- ${libs[@]}; echo ${cmd[@]}; }

lib meta src srcs self
src () { one ${1:?} ${1:?}.${2:?}; }
srcs () { mapargs src ${1:?} -- src ${@:2}; }
self () { ${FUNCNAME[1]}.${1:?} "${@:2}"; }

lib std fail assert self a2v cnt; macro cnt
fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
assert () { $@ || fail "${FUNCNAME[1]} $@"; }
self () { ${FUNCNAME[1]}.${1:?} "${@:2}"; }
a2v () { local -n a=$1; assert test ${#a[@]} -gt 0; for i in ${!a[@]}; do declare -g $i="${a[$i]}"; done; "${@:2}"; }
cnt () { "$@" | wc -l; }

lib std list map pipe
list () { for i; do echo "$i"; done; }
map () { while read; do "$@" $REPLY; done; }
pipe () { loc a b; splitargs a b "$@"; < <(${a[@]}) ${b[@]}; }


as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh -A ${user:+${user}@}${1:?}.admin2 bash; }


lib ft files dirs list unit du-sum info; declare -A ft=(); ft () { self "$@"; }

ft.find () { assert test -d ${1:?}/; find $1 "${@:2}"; }

files () { ft find $1 -type f "${@:2}"; }
dirs () { ft find $1 -type d "${@:2}"; }

list () { files "$@" -print0 | xargs -0r ls -lsht; }
unit () { unit=${1:?}; "${@:2}"; }
ft.du () { files "$@" -print0 | xargs -0r du -c -B${unit:-K}; }

ft[du-sum-jq]='[inputs] | map(split("\t")[0] | tonumber) | add / 1024 | floor | "\(.)G"'
du-sum () { unit=1M; ft.du "$@" | grep total | jq -nRr "${ft[du-sum-jq]}"; }

ft[info-jq]='[inputs] as [ $host, $files, $dirs, $sizeM, $path ] | { $host, $files, $dirs, $sizeM, $path }'
ft.info () { { hostname; ft.find $1/ -type f | wc -l; ft.find $1/ -type d | wc -l; du -sm $1/ | fmt -1; } | jq -nR "${ft[info-jq]}"; }
