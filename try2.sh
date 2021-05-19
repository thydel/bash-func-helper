#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases
alias self='local self=${FUNCNAME[0]}'

deps=${BFH_DEPS:-_deps}
funcs=${BFH_FUNCS:-_funcs}
vars=${BFH_VARS:-_vars}

alias deps='deps.set $deps'
declare -A $deps

deps.set () {
    local -n deps_dict=${1:?}
    (($# == 2)) && { unset deps_dict[$2]; return; }
    local deps_array=(${deps_dict[${2:?}]})
    deps_array+=(${@:3})
    deps_dict[$2]=${deps_array[@]}
}

deps.get () {
    local -n deps_ret=${1:?}
    local -n deps_dict=${2:?}
    deps_ret=(${deps_dict[${3:?}]})
}

fail() { unset -v fail; echo ${FUNCNAME[@]} >&2; : "${fail:?$@}"; }
assert() { "$@" || fail ${BASH_SOURCE[-1]}, ${FUNCNAME[-1]}, "$@"; }; deps assert fail
not () { ! "$@"; }

pp.list () { local i; for i do echo "$i"; done; }
list.map () { while read; do "$@" "$REPLY"; done; }
enum.map () { local -n map_enum=$1; local i; for i in ${!map_enum[@]}; do $2 $i; done; }

list.to-enum () { self; declare -Ag $1; eval "$1=()"; $self.loop $1; }
list.to-enum.loop () { local -n list_to_enum=$1; local -i i; while read; do list_to_enum[$REPLY]=$((i++)); done; }
deps list.to-enum.loop list.to-enum

vars.set () { list.to-enum $vars < <(comm -23 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^[A-Z_0-9]*$'); }
funcs.set () { list.to-enum $funcs < <(declare -F | while read; do echo ${REPLY#declare -f}; done;); }
deps vars.set list.to-enum $vars
deps funcs.set list.to-enum $funcs

var.src () { local -n ref_vars=$vars; test -v ref_vars[$1] || fail $1 is not a $var; declare -p $1; }
deps var.src fail

func.src () { local -A a=([std]=func.src.std [line]=func.src.line); ${a[${src:-line}]} "$@"; }
func.src.std () {
    local f=${BASH_ALIASES[${1:?}]:-$1}
    local -n ref_funcs=$funcs
    test -v ref_funcs[$f] || fail $f is not in $func && declare -f $f
}
func.src.line () {
    < <(func.src.std $1) mapfile -t
    ((${#MAPFILE[*]})) || return 1
    for ((i=2; i < $((${#MAPFILE[*]} - 1)); ++i))
    do
	printf -v n ${MAPFILE[(($i + 1))]}
	[[ ${#n} == 1 && ${n:(-1)} == "}" ]] || [[ ${#n} == 2 && ${n:(-2)} == "};" ]] && MAPFILE[$i]+=";";
    done
    MAPFILE[-1]+=';'
    echo ${MAPFILE[@]}
}
deps func.src func.src.std func.src.line
deps func.src.line func.src.std $funcs
deps func.src.std fail

any.src () {
    local -n ref_funcs=$funcs ref_vars=$vars
    test -v ref_vars[${1:?}] && declare -p $1; test -v ref_funcs[${BASH_ALIASES[$1]:-$1}] && func.src $1
}
deps any.src $vars $funcs func.src
alias src=any.src

closure () { deps.closure $deps "$@"; }
deps.closure () {
    assert test $# -ge 2
    local -n deps_closure=$1
    test ${#deps_closure[*]} -gt 0 || return 1
    local -Ag seen=()
    pp.deps.closure "$@"
}
pp.deps.closure () {
    for i in "${@:2}"; do
	local dep=${BASH_ALIASES[$i]:-$i}
	[[ -v deps_closure[$dep] ]] || fail $dep not in $1; echo $i; deps.closure.one $dep
    done
}
deps.closure.one () {
    for i in ${deps_closure[$1]}; do
	[[ -v seen[$i] ]] || echo $i; ((++seen[$i])); [[ -v deps_closure[$i] ]] && ${FUNCNAME[0]} $i;
    done
}
deps closure deps.closure $deps
deps deps.closure pp.deps.closure
deps pp.deps.closure deps.closure.one

funcs_src=(enum.map $funcs func.src)
funcs.src () { ${funcs_src[@]}; }
deps funcs.src ${funcs_src[@]}
alias funcs=funcs.src

vars.src () { local -n ref_vars=$vars; ref_vars+=([$vars]=${#ref_vars[*]}); enum.map $vars var.src; }
deps vars.src enum.map $vars var.src
alias vars=vars.src

func.use () { closure "$@" | list.map any.src; }
deps func.use closure list.map func.src
alias use=func.use

func.run () { func.use ${1:?}; echo "${@@Q}"; }
deps func.run func.use
alias run=func.run

all () { funcs.src; vars.src; alias; }

eval "$self () { :; }"
deps $self func.run

any.sync () { funcs.set; vars.set; }
deps any.sync funcs.set vars.set
any.sync

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
all
