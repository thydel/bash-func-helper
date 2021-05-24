#!/bin/bash

self=$(basename "${BASH_SOURCE[0]}" .sh)
eval "$self () { :; }"

shopt -s expand_aliases

####

list.map () { while read; do "$@" "$REPLY"; done; }

####

Names=_names
unset $Names
declare -A $Names

name.add () {
    local -n A=${1:?}; shift; local i
    for i; do test -v A[$i] || A[$i]=; done
    local a=(${A[${1:?}]})
    a+=(${@:2}); A[$1]=${a[@]}
}
alias name='name.add $Names'
name Names $Names
name name name.add Names

names.pp.add () { local i; for i; do name $i; done; }
alias names=names.pp.add
name names name

name.pp.dist () { local i; for i in ${@:2}; do name $i $1; done; }
alias name-dist=name.pp.dist
name name-dist name.pp.dist name

names.list () { local -n A=${1:?}; local i; for i in ${!A[@]}; do echo $i; done }
alias names-list='names.list $Names'
name names-list names.list Names

name.show () { local -n A=${1:?}; echo ${2:?}: ${A[$2]}; }
name name.show Names

names.show () { names-list | list.map name.show $1 | sort | column -ts:; }
alias names-show='names.show $Names'
name names-show names.show Names

####

nil () { :; }
error () { echo "ERROR: $@" >&2; return 1; }
fail() { unset -v fail; (echo ${BASH_SOURCE[-1]} ${FUNCNAME[@]}; echo "FAIL: $@") >&2; : "${fail:?''}"; }
assert() { "$@" || fail "$@"; }
false && alias assert=': '
not () { ! "$@"; }

names nil not error
name assert fail

####

Stack=_stack
declare -a $Stack

alias stack.i='local -n STACK=${1:?}; shift'

stack.new () { stack.i; STACK=(); }
name Stack $Stack
name stack.new Stack
alias stack-clear='stack.new $Stack'
name stack-clear stack.new

stack.pp.push () { stack.i; local e="${@:?}"; STACK+=("$e"); }
alias push='stack.pp.push $Stack'
name push stack.pp.push Stack

stack.pp.pushm () { stack.i; STACK+=("${@:?}"); }
alias pushm='stack.pp.pushm $Stack'
name push stack.pp.pushm Stack

stack.ref.pop () { stack.i; local -n POP=${1:?}; local top=$((${#STACK[*]}-1)); POP=${STACK[$top]}; unset STACK[$top]; }
alias rpop='stack.ref.pop $Stack'
name rpop stack.ref.pop Stack

stack.io.pop () { local pop; stack.ref.pop ${1:?} pop; echo $pop; }
name stack.io.pop stack.ref.pop

stack.list () { stack.i; local i; for (( i = ${#STACK[*]} - 1; i >= 0; --i )); do echo ${STACK[$i]}; done; }
alias stack-list='stack.list $Stack'
name stack-list stack.list Stack

####

name.push () { local -n A=${1:?}; shift; push "${A[${1:?}]}"; }
alias name-push='name.push $Names'
name name-push name.push Names push

####

func.src () { local -A a=([std]=func.src.std [line]=func.src.line); ${a[${src:-line}]} "$@"; }
func.src.std () { declare -f ${1:?}; }
func.src.line () {
    < <(func.src.std $1) mapfile -t
    ((${#MAPFILE[*]})) || return 1
    local i
    for ((i = 2; i < $((${#MAPFILE[*]} - 1)); ++i))
    do
	printf -v n ${MAPFILE[(($i + 1))]}
	[[ ${#n} == 1 && ${n:(-1)} == "}" ]] || [[ ${#n} == 2 && ${n:(-2)} == "};" ]] && MAPFILE[$i]+=";";
    done
    MAPFILE[-1]+=';'
    echo ${MAPFILE[@]}
}

name func.src func.src.{std,line}

####

name.pname? () { test ${1:?} = ${1//[-.?]/}; }
name.alias? () { test -v BASH_ALIASES[${1:?}]; }
name.func? () { declare -f ${1:?} > /dev/null; }
name.param? () { declare -p ${1:?} &> /dev/null; }
name.array? () { name.pname? ${1:?} && test "${!1@a}" = a; }
name.assoc? () { name.pname? ${1:?} && test "${!1@a}" = A; }
name.src () {
    local -i found
    name.alias? ${1:?} && { alias $1; let ++found; }
    name.func? $1 && { func.src $1; let ++found; }
    { name.param? $1 || name.array? $1 || name.assoc? $1; } && { declare -p $1; let ++found; }
    ((found)) && return
    error $1 is not defined
}
names.src () {
    local -A seen=(); local i
    for i; do
	if name.alias? $i; then
	    test -v seen[$i] || { name.src $i; ((++seen[$i])); }
	    local a=(${BASH_ALIASES[$i]}); local f=${a[0]}
	    name.func? $f && test -v seen[$f] || { name.src $f; ((++seen[$f])); }
	fi
	test -v seen[$i] || { name.src $i; ((++seen[$i])); }
    done
}
alias src=names.src
name src names.src
name name.src name.{pname,alias,func,param,array,assoc}? func.src error
name-push name.src; rpop ret
name-dist nil $ret
name names.src name.src

####

names.closure () { assert test $# -ge 2; local -A seen=(); ${FUNCNAME[0]}-rec "$@"; }
names.closure-rec () {
    assert test ${FUNCNAME[1]} = names.closure -o ${FUNCNAME[1]} = main -o ${FUNCNAME[1]} = ${FUNCNAME[0]}
    local -n A=${1:?}; local i
    for i in ${@:2}; do
	test -v A[$i] || fail $i not in $1
	test -v seen[$i] && continue
	echo $i; ((++seen[$i]))
	local a=(${A[$i]})
	test ${#a[*]} -gt 0 && ${FUNCNAME[0]} $1 ${a[@]}
    done
}
alias closure='names.closure $Names'
name closure names.closure Names
name names.closure assert names.closure-rec
names.closure-rec assert

####

aliases () { echo shopt -s expand_aliases; }
name aliases

use () { aliases; src $(closure "${@:?}"); }
name use aliases src closure

run () { use ${1:?}; echo "${@@Q}"; }
name run use

main () { (($#)) && { eval "$@"; exit $?; }; }
name main all

all () { aliases; src $(closure $(names-list)); }
name all $(names-list)

main "$@"
all
