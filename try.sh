#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases

alias self='local self=${FUNCNAME[0]}'

fail() { unset -v fail; : "${fail:?$@}"; }
assert() { test "$@" || fail ${BASH_SOURCE[-1]}, ${FUNCNAME[-1]}, "$@"; }

read -rd '' name_type_var_help <<'!'
name.type.var NAME

output the type of variable NAME.

types are "var" "array" and "dict".

output "" and return 1 if NAME is an undefined variable.
!
name.type.var () {
    assert $# -eq 1
    local name="$1"
    declare -A types=([--]=var [-a]=array [-A]=dict)
    local declare=($(declare -p "$name" 2> /dev/null))
    local type=${declare[@]:1:1}
    [ -v types[$type] ] && { echo ${types[$type]}; return; }
    return 1;
}

read -rd '' name_types_help <<'!'
name.types ARRAY NAME

fill ARRAY with the types of NAME.

types are "var" "array" "dict" "func" and "undef".

namespace of functions is distinct from namespace for "var" "array"
and "dict", so NAME can have types, e.g. "array" and "func".

fail if ARRAY is not the name of an array.

when NAME is a variable and a function the type of the variable is
always first in ARRAY, so that one can use $ARRAY to ignore unction
namespace.
!
name.types () {
    assert $# -eq 2
    assert "$(name.type.var "$1")" == array
    [[ "$(name.type.var "$1")" == 'array' ]] || fail $1 not an array
    local -n name_type="$1"
    local name="$2"
    local type=$(name.type.var "$2") && name_type=($type)
    declare -f "$name" > /dev/null && name_type+=(func)
    ((${#name_type})) || name_type=(undef)
}


enum () {
    assert $# -ge 1
    assert "$(name.type.var "$1")" == dict
    local -n enum="$1";
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
f () { echo $version $full_version; }

test $version == "510" && date
