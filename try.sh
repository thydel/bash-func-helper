#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases

alias self='local self=${FUNCNAME[0]}'

declare -A funcs_map=();
func.as_var () { local -n __=$1; __=${2//[-.?]/_}_; }
func.new () { local var; func.as_var var "$1"; funcs_map[$1]=$var; declare -ag $var; func.use $1; func.use "$@"; }
func.use () { local var; func.as_var var "$1"; shift; local -n __=$var; (($#)) && __+=("$@") || __=(); }

alias new=func.new

new func.as_var
new func.new func.as_var funcs_map func.use
new func.use func.as_var

fail() { unset -v fail; : "${fail:?$@}"; }; new fail
assert() { "$@" || fail ${BASH_SOURCE[-1]}, ${FUNCNAME[-1]}, "$@"; }; new assert fail
not () { ! "$@"; }; new not

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

enum () {
    assert test $# -ge 1
    assert test "$(name.type.var "$1")" == dict
    local -n enum="$1";
    (( $# == 1 )) && { enum=(); return; }
    shift; local -- a i;
    for ((a = 1, i = ${first:-0}; a <= $#; ++a, i += ${incr:-1})) do enum[${!a}]=$i; done
}; new func enum assert

name.random () {
    assert test $# -eq 1 -o $# -eq 2
    assert test "$(name.type.var "$1")" == var
    local -n name_random_var=$1;
    printf -v name_random_var %s%04d ${2:-random_} $(( RANDOM % 9999 ));
}; new name.random assert
		
name.is? () {
    local types=()
    name.types types $1
    [[ ${types[0]} == $2 ]] || { [[ $2 == func ]] && name.func? $1; }
}; new name.is? name.types name.func?
name.is?.test () {
    local var; name.random var
    local -- $var; assert name.is? $var var; assert not name.is? $var array
    local array; name.random array
    local -a $array; assert name.is? $array array; assert not name.is? $array var
    local dict; name.random dict
    local -A $dict; assert name.is? $dict dict; assert not name.is? $dict array
    local func; name.random func
    eval "$func () { :; }"
    assert name.is? $func func; assert not name.is? $func var
    local $func
    assert name.is? $func func; assert name.is? $func var; assert not name.is? $func array
    unset -f $func
}; new name.is?.test name.random assert not name.is?

func.src () { local -A a=([full]=func.src.std [short]=func.src.one-line); ${a[${show:-short}]} "$@"; }
new func.src func.src.std func.src.one-line
func.name () { echo ${BASH_ALIASES[${1:?}]:-$1}; }; new func.name
func.src.std () { func.name $1 | { read f; declare -f $f || fail no such func $f; }; }
new func.src.std func.name
func.src.one-line () {
    func.src.std $1 | {
	mapfile -t;
	for ((i=2; i < $((${#MAPFILE[*]} - 1)); ++i))
	do
	    printf -v n ${MAPFILE[(($i + 1))]}
	    [[ ${#n} == 1 && ${n:(-1)} == "}" ]] || [[ ${#n} == 2 && ${n:(-2)} == "};" ]] && MAPFILE[$i]+=";";
	done
	MAPFILE[-1]+=';'
	echo ${MAPFILE[@]}
    }
}; new func.src.one-line func.src.std

name.src.var () { local -n __=$1; echo $1=${__@Q}; }
name.src.array () { declare -p $1; }
name.src.dict () { declare -p $1; }
name.src.func () { declare -f $1; }
name.src.func () { func.src $1; }
name.src.undef () { fail $1 is undef;  }
name.src () {
    assert test $# -eq 1
    local types=(); name.types types "$1"
    local type
    for type in "${types[@]}"; do name.src.$type $1; done;
}

array.new () { assert test $# -ge 1; local -n __=$1; shift; (($#)) || { __=(); return; }; __=("$@"); }; new array.new assert

array.new name_src_funcs name.src.{var,array,dict,func,undef}
for func in ${name_src_funcs[@]}; do new $func; done
func.use name.src.undef fail
func.use name.src.func func.src
new name.src ${name_src_funcs[@]}

read -rd '' name__help <<'!'
name NAME is? [ var array dict func undef ] -- return 0 is of given type
name NAME types -- output types of NAME
name NAME src -- output src defining NAME (homoiconic NAME)
!
name.name.types () { assert test $# -eq 1; local types=(); name.types types $1; echo "${types[@]}"; }
new name.name.types assert name.types
name.name.is? () {
    assert test $# -eq 2
    local -A types=(); enum types var array dict func undef
    assert test -v types[$2];
    name.is? "$@"
}; new name.name.is? assert name.is?
name.name.src () { assert test $# -eq 1; name.src "$@"; }; new name.name.src assert name.src
name () {
    local -A funcs=(); enum funcs types is? src
    assert test -v funcs[$2]
    name.name.$2 $1 "${@:3}"
}; new name assert name.name.{types,is?,src}

func.help () {
    assert test $# -eq 1; name.func? "$1" || fail $1 not a function
    local var; func.as_var var "$1".help;
    local types=(); name.types types ${var:0:-1};
    [[ $types == var ]] && { help=${var:0:-1}; echo "${!help}"; }
}
new func.help assert name.func? fail func.as_var name.types
func.use name_type_var_help name_types_help

push () { : ${2:?}; local -n push="$1"; shift; push+=("$@"); }; new func push
peek () { : ${2:?}; local -n peek="$1"; local -n peek2="$2"; peek2="${peek[-1]}"; }; new func peek

pop () {
    : ${2:?}; local -n pop_array="$1"; shift; local -- var;
    for var; do local -n pop_var="$var"; pop_var="${pop_array[-1]}"; unset pop_array[-1]; done
}; new func pop

str.cat () { : ${2:?}; local -n str_cat="$1"; shift; local IFS=''; push str_cat "$*"; }; new func str.cat push
str.join () { : ${3:?}; local -n str_join="$1"; local IFS="$2"; shift 2; push str_join "$*"; }; new func str.join push

closure () { local -A seen=(); closure.many "$@"; }
closure.many () { local _name; for _name in "$@"; do closure.one $_name; done; }
closure.one () {
    [[ -v seen[$1] ]] && return
    name.src $1
    local -n closure_names=${funcs_map[$1]}
    local closure_name
    for closure_name in ${closure_names[@]}; do ${FUNCNAME[0]} $closure_name; done
    ((++seen[$1]))
}

func.all () { declare -F | while read -a a; do echo ${a[-1]}; done; }; new func.all
map () { while read; do "${@:-echo}" "$REPLY"; done; }


loop () {
    local -A seen=();
    for func in "${funcs_map[@]}"; do
	declare -p $func
	declare -n loop_names="$func"
	for name in "${loop_names[@]}"; do
	    # echo __ $name
	    [ -v seen[$name] ] || { ((++seen[$name])); name.src $name; }
	done;
    done;
}; new loop

all () { closure "${!funcs_map[@]}"; }

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
loop

exit

str.cat stack ${BASH_VERSINFO[@]:0:3};
str.join stack _ ${BASH_VERSINFO[@]};

pop stack full_version version
f () { echo $version $full_version; test $version == "510" && date; }
