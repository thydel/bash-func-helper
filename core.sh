#!/usr/bin/env bash

self=$(basename "${BASH_SOURCE[0]}" .sh)
eval "$self () { :; }"

shopt -s expand_aliases
alias self='local self=${FUNCNAME[0]}; local name=${self//[-.?]/_}'

deps=${BFH_DEPS:-_deps}
funcs=${BFH_FUNCS:-_funcs}
vars=${BFH_VARS:-_vars}

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

declare -A $deps
alias deps='deps.set $deps'
deps deps.set $deps

nil () { :; }
fail() { unset -v fail; (echo ${BASH_SOURCE[-1]} ${FUNCNAME[@]}; echo "$@") >&2; : "${fail:?''}"; }
assert() { "$@" || fail "$@"; }; deps assert fail
not () { ! "$@"; }

pp.list () { local i; for i do echo "$i"; done; }
list.map () { while read; do "$@" "$REPLY"; done; }
enum.map () { local -n map_enum=$1; local i; for i in ${!map_enum[@]}; do $2 $i; done; }

array.has () { assert test $# -eq 2; local -n in_array=$1; local i; for i in "${in_array[@]}"; do [[ "$2" == "$i" ]] && return; done; return 1; }
deps array.has assert

enum.clear () { declare -Ag $1; local -n enum_clear=$1; enum_clear=(); }
enum.add () {
    local -n in_enum=$1; local -i i=${#in_enum[*]};
    if [[ $# -gt 1 ]]; then shift; local e; for e; do in_enum[$e]=$((i++)); done
    else while read; do in_enum[$REPLY]=$((i++)); done; fi
}

vars.set () { enum.clear $vars; enum.add $vars < <(comm -23 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^[A-Z_0-9]*$'); }
funcs.set () { enum.clear $funcs; enum.add $funcs < <(declare -F | while read; do echo ${REPLY#declare -f}; done;); }
deps vars.set enum.clear $vars enum.add
deps funcs.set enum.clear $funcs enum.add

vars.add () { enum.add $vars "$@"; }
funcs.add () { enum.add $funcs "$@"; }
deps $self vars.add funcs.add

var.src () { local -n ref_vars=$vars; test -v ref_vars[$1] || fail $1 is not a $vars; declare -p $1; }
deps var.src fail

func.ref-name () {
    assert test $# -eq 2
    local -n func_name=${1:?}; func_name=$2; local alias=${BASH_ALIASES[$2]}
    [[ "$alias" ]] || return
    local tmp=($alias)
    func_name=${tmp[0]}
}
func.is? () {
    assert test $# -eq 1
    local f; func.ref-name f $1
    local -n ref_funcs=$funcs
    test -v ref_funcs[$f] || return 1
}
func.src () { local -A a=([std]=func.src.std [line]=func.src.line); ${a[${src:-line}]} "$@"; }
func.src.std () {
    assert test $# -eq 1
    local f; func.ref-name f $1
    local -n ref_funcs=$funcs
    test -v ref_funcs[$f] || fail $f is not a $funcs && declare -f $f
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
deps func.ref-name assert
deps func.is? assert func.ref-name
deps func.src func.src.std func.src.line
deps func.src.line func.src.std $funcs
deps func.src.std assert func.ref-name fail

any.src () {
    assert test $# -eq 1
    local f; func.ref-name f $1
    local -n ref_funcs=$funcs ref_vars=$vars
    test -v ref_vars[$1] && declare -p $1
    test -v ref_funcs[$f] && func.src $f
    test -v BASH_ALIASES[$1] && echo alias deps=${BASH_ALIASES[deps]@Q}
}
deps any.src assert func.ref-name $vars $funcs func.src
alias src=any.src

closure () { deps.closure $deps "$@"; }
deps.closure () {
    assert test $# -ge 2
    local -n deps_closure=$1
    test ${#deps_closure[*]} -gt 0 || return 1
    local -A seen=()
    pp.deps.closure "$@"
}
pp.deps.closure () {
    local dep
    for i in "${@:2}"; do
	func.ref-name dep $i
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

main () { (($#)) && { eval "$@"; exit $?; }; }

all () { funcs.src; vars.src; alias; echo shopt -s expand_aliases; }
deps all main

deps $self func.run

any.sync () { funcs.set; vars.set; }
deps any.sync funcs.set vars.set
any.sync

main "$@"
all
