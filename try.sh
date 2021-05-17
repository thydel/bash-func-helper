#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases

alias self='local self=${FUNCNAME[0]}'

enum () {
    : ${1:?}; declare -Ag "$1"; local -n enum="$1";
    (( $# == 1 )) && { enum=(); return; }
    shift; local -- a i;
    for ((a = 1, i = ${first:-0}; a <= $#; ++a, i += ${incr:-1})) do enum[${!a}]=$i; done
}

push () { : ${2:?}; local -n push="$1"; shift; push+=("$@"); }
peek () { : ${2:?}; local -n peek="$1"; local -n peek2="$2"; peek2="${peek[-1]}"; }

pop () {
    : ${2:?}; local -n pop_array="$1"; shift; local -- var;
    for var; do local -n pop_var="$var"; pop_var="${pop_array[-1]}"; unset pop_array[-1]; done
}

str.cat () { : ${2:?}; local -n str_cat="$1"; shift; local IFS=''; push str_cat "$*"; }
str.join () { : ${3:?}; local -n str_join="$1"; local IFS="$2"; shift 2; push str_join "$*"; }

str.cat stack ${BASH_VERSINFO[@]:0:3};
str.join stack _ ${BASH_VERSINFO[@]};

pop stack full_version version
echo $version $full_version

test $version == "510" && date
