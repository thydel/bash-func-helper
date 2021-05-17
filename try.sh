#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases

alias self='local self=${FUNCNAME[0]}'

declare -A funcs_map=();
func.as_var () { local -n __=$1; __=${2//[.-?]/_}_; }
func.new () { local var; func.as_var var "$1"; funcs_map[$1]=$var; declare -ag $var; func.use $1; func.use "$@"; }
func.use () { local var; func.as_var var "$1"; shift; local -n __=$var; (($#)) && __+=("$@") || __=(); }

alias new=func.new

new func.new func.new.as_var funcs_map func.use
new func.use func.new.as_var

fail() { unset -v fail; : "${fail:?$@}"; }; new fail
assert() { "$@" || fail ${BASH_SOURCE[-1]}, ${FUNCNAME[-1]}, "$@"; }; new assert fail

read -rd '' name_type_var_help <<'!'
name.type.var NAME

output the type of variable NAME.

types are "var" "array" and "dict".

output "" and return 1 if NAME is an undefined variable.
!
name.type.var () {
    assert test $# -eq 1
    local -A name_type_var__types=([--]=var [-a]=array [-A]=dict)
    local name_type_var__declare=($(declare -p "$1" 2> /dev/null))
    local name_type_var__type=${name_type_var__declare[@]:1:1}
    [ -v name_type_var__types[$name_type_var__type] ] && { echo ${name_type_var__types[$name_type_var__type]}; return; }
    return 1;
}; new name.type.var assert

read -rd '' name_types_help <<'!'
name.types ARRAY NAME

fill ARRAY with the types of NAME.

types are "var" "array" "dict" "func" and "undef".

namespace of functions is distinct from namespace for "var" "array"
and "dict", so NAME can have two types, e.g. "array" and "func".

fail if ARRAY is not the name of an array.

when NAME is a variable and a function the type of the variable is
always first in ARRAY, so that one can use $ARRAY to ignore unction
namespace.
!
name.types () {
    assert test $# -eq 2
    assert test "$(name.type.var "$1")" == array
    # [[ "$(name.type.var "$1")" == 'array' ]] || fail $1 not an array
    local -n name_type="$1"
    local name="$2"
    local type=$(name.type.var "$2") && name_type=($type)
    declare -f "$name" > /dev/null && name_type+=(func)
    ((${#name_type})) || name_type=(undef)
}; new name.types assert name.type.var
name.types.test () {
    local types=()
    local foo
    name.types types foo
    assert test "$types" == var && assert test ${#types[*]} == 1
    local bar=()
    name.types types bar
    assert test "$types" == array && assert test ${#types[*]} == 1
    local -A foobar
    name.types types foobar
    assert test "$types" == dict && assert test ${#types[*]} == 1
    barfoo () { :; }
    name.types types barfoo
    assert test "$types" == func && assert test ${#types[*]} == 1
    local barfoo=()
    name.types types barfoo
    assert test "$types" == array && assert test ${#types[*]} == 2 && assert test ${types[1]} == func
    unset -f barfoo
}; new name.types.test name.types assert

name.func? () {
    assert test $# -eq 1
    local types=(); name.types types "$1"
    [[ $types == func ]] || ((${#types[*]} == 2))
}; new name.func? assert name.types
name.func?.test () {
    assert name.func? name.func?
    ! name.func? name.func?.nil || fail
}; new name.func?.test assert name.func?

func.help () {
    assert test $# -eq 1; name.func? "$1" || fail $1 not a function
    local var; func.as_var var "$1".help;
    local types=(); name.types types ${var:0:-1};
    [[ $types == var ]] && { help=${var:0:-1}; echo "${!help}"; }
}
new func.help assert name.func? fail func.as_var name.types
func.use name_type_var_help name_types_help

enum () {
    assert test $# -ge 1
    assert test "$(name.type.var "$1")" == dict
    local -n enum="$1";
    (( $# == 1 )) && { enum=(); return; }
    shift; local -- a i;
    for ((a = 1, i = ${first:-0}; a <= $#; ++a, i += ${incr:-1})) do enum[${!a}]=$i; done
}; new func enum assert


push () { : ${2:?}; local -n push="$1"; shift; push+=("$@"); }; new func push
peek () { : ${2:?}; local -n peek="$1"; local -n peek2="$2"; peek2="${peek[-1]}"; }; new func peek

pop () {
    : ${2:?}; local -n pop_array="$1"; shift; local -- var;
    for var; do local -n pop_var="$var"; pop_var="${pop_array[-1]}"; unset pop_array[-1]; done
}; new func pop

str.cat () { : ${2:?}; local -n str_cat="$1"; shift; local IFS=''; push str_cat "$*"; }; new func str.cat push
str.join () { : ${3:?}; local -n str_join="$1"; local IFS="$2"; shift 2; push str_join "$*"; }; new func str.join push


str.cat stack ${BASH_VERSINFO[@]:0:3};
str.join stack _ ${BASH_VERSINFO[@]};

pop stack full_version version
f () { echo $version $full_version; test $version == "510" && date; }
