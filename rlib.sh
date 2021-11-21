#!/usr/bin/env bash

# Mini bash lib to dump src of part of bash worspace (funcs an vars)
# to allow remote execution of a func with its dependencies

# run $func $arg ...               # ouput fonction definition and invocation from a function invocation
# src $item                        # output homoiconic version of its var or func $item arg
# with $item ... -- $func $arg ... # run "$func $arg ..." with "src $item" for all item args

run () { declare -f $1; echo "$@"; }
#src () { declare -p ${1:?} &> /dev/null && declare -p $1 || declare -f $1; }
src () { declare -p ${1:?} &> /dev/null && declare -p $1; [ -v BASH_ALIASES[$1] ] && alias $1; declare -f $1; }
with () { until [[ $1 == -- ]]; do src ${1:?}; shift; done; run "${@:2}"; }

# Pseudo lib namespace via aliases and compgen

# short $lib $func ...             # define alias $func as $lib.$func for all func args
# srcs $lib                        # list all funcs in worspace libed by "$lib." and all vars libed by "$lib_"
# use $lib ... -- $func $arg ...   # echo "$func $arg ..." with "src $item" for all items of all $lib args

short () { for i in ${@:2}; do BASH_ALIASES[$i]=${1:?}.$i; done; }
#srcs () { compgen -A function ${1:?}.; compgen -v $1_; }
#srcs () { compgen -A function ${1:?}.; compgen -v $1_; compgen -A function $1. | while read; do [ -v BASH_ALIASES[$REPLY] ] && alias $REPLY; done; }
srcs () { compgen -A function ${1:?}.; compgen -v $1_; compgen -A function $1. | while read; do [ -v BASH_ALIASES[${REPLY/#$1.}] ] && echo ${REPLY/#$1.}; done; }
use () { echo shopt -s expand_aliases; until [[ ${1:?} == -- ]]; do srcs ${1:?} | while read; do src $REPLY; done; shift; done; echo "${@:2}"; }

# Syntaxic sugar to use minilib with ssh

as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh -A ${user:+${user}@}${1:?} bash; }

shopt -s expand_aliases

# demo libs

std_version=2021-11-16
short std fail assert map list func assoc has

fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
assert () { $@ || fail "${FUNCNAME[1]} $@"; }
map () { while read; do "$@" "$REPLY"; done; }
list () { for i; do echo $i; done; }
#std.src () { declare -p ${1:?} &> /dev/null && declare -p $1 || func $1; }
std.src () { declare -p ${1:?} &> /dev/null && declare -p $1; [ -v BASH_ALIASES[$1] ] && alias $1; func $1; }
func () { # output a func as a single line
    local -n a=MAPFILE
    < <(declare -f ${1:?}) mapfile -t
    ((${#a[*]})) || return 1
    local i t
    for ((i = 2; i < $((${#a[*]} - 1)); ++i)); do
	t=${a[(($i + 1))]}
	printf -v n -- ${t/\%/%%}
	[[ ${#n} == 1 && ${n:(-1)} == "}" ]] || [[ ${#n} == 2 && ${n:(-2)} == "};" ]] && a[$i]+=";";
    done
    a[-1]+=';'
    echo ${a[@]}
}
assoc () { assert [ $# -ge 1 ]; for i; do declare -Ag A_$i; declare -n _A=A_$i _a=$i; for i in ${_a[@]}; do _A[$i]=''; done; done; }
has () { assert [ $# -eq 2 ]; [ -v A_$1[$2] ]; }

awk_version=2021-11-16
awk.sum () { awk '{ s += $1 } END { print s }'; }

# modulino

_with=(run src with)
_use=(src short srcs use)
_on=(as on)
_self=("${_with[@]}" "${_use[@]/%src}" "${_on[@]}")
self=(with use on self)

libs=(self std awk)

assoc self libs

terse () { assert [ $# -ge 1 ]; _src=std.src "$@"; }
lib () {
    assert [ $# -eq 1 ];
    if has self $1; then local -n _a=_$1; list ${_a[@]};
    else assert std.has libs $1; srcs $1;
    fi | map ${_src:-src};
}
libs () { (($#)) && libs=("$@"); for i in ${libs[@]}; do lib $i; done; }

#self () { terse lib self; "$@"; }
#macro () { test -v BASH_ALIASES[$1] && alias $1; }

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
echo shopt -s expand_aliases
terse libs
