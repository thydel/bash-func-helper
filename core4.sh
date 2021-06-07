#!/bin/bash

# [Bash - Functions in Shell Variables]: https://unix.stackexchange.com/questions/233091/bash-functions-in-shell-variables

shopt -s expand_aliases
declare -n alias=BASH_ALIASES

[[ "$Names" ]] || [[ "${Names@a}" ]] && ${FUNCNAME:?}; declare -A Names=()
[[ "$Docs" ]] || [[ "${Docs@a}" ]] && ${FUNCNAME:?}; declare -A Docs=()

f () { f=${1:?}; alias f=$f; }
alias @doc='read -rd "" t <<@cod'
alias @end='Docs+=([$f]=$t); unalias f'


#f Names.dict.pp.add-deps
#@doc
#Set name dependencies in dict from positional parameters
#$f DICT NAME [DEPENDENCY] ...
#If NAME is an ALIAS, add a dependency for NAME to head of ALIAS
#@cod
#f_ () {
#    local -n A=${1:?}; shift; local i
#    for i; do test -v A[$i] || A[$i]=; done
#    local a=(${A[$1]}); a+=(${@:2})
#    [[ -v alias[${1:?}] ]] && { local b=(${alias[$1]}); a+=(${b[0]}); }
#    A[$1]=${a[@]}
#}
#f () {
#    : ${2:?}; local -n A=$1; shift; local name=$1; shift
#    [[ -v alias[$name] ]] && [[ ! -v A[$name] ]] && { A[$name]=${alias[$name]% *}; name=${A[$name]}; }
#    local i; local d=()
#    for i; do
#	[[ -v alias[$i] ]] && d+=(${alias[$i]% *}) || d+=($i)
#    done
#    local a=(${A[$name]})
#    a+=(${d[@]})
#    A[$name]=${a[@]}
#}
#alias name="$f Names"
#name name
#@end

Names.doc () {
    : ${3:?}; local -n A=$1; shift; local name
    [[ -v alias[$1] ]] && name=${alias[$1]% *} || name=$1
    A[$name]+=${2/SELF /$name }
}
alias doc='Names.doc Docs'

alias deps=Names.dict.pp.add-deps
doc deps "
Set name dependencies in dict from positional parameters
SELF DICT NAME [DEPENDENCY] ...
If NAME is an ALIAS, add a dependency for NAME to head of ALIAS"
deps () {
    : ${2:?}; local -n A=$1; shift; local name=$1; shift
    [[ -v alias[$name] ]] && [[ ! -v A[$name] ]] && { A[$name]=${alias[$name]% *}; name=${A[$name]}; }
    local i; local d=()
    for i; do [[ -v alias[$i] ]] && d+=(${alias[$i]% *}) || d+=($i); done
    local a=(${A[$name]})
    a+=(${d[@]})
    A[$name]=${a[@]}
}
alias name='deps Names'
name deps
name doc

alias names=Names.dict.pp.add-names
doc names "Add names to dict" "SELF DICT NAME ..."
names () { local i; for i; do name $i; done; }
name names

#f Names.dict.pp.add-names
#@doc
#Add names to dict
#$f DICT NAME ...
#@cod
#f () { local i; for i; do name $i; done; }
#alias names=$f
#name names
#@end

f Names.dict.pp.dist-dep
@doc
Distribute a dependency to names in a dict
$f DICT DEPENDENCY NAME ...
@cod
f () { local i; for i in ${@:2}; do name $i $1; done; }
alias name-dist=$f
name name-dist name
@end

f Names.dict.list
@doc
List names in dict
$f DICT
@cod
f () { local -n A=${1:?}; local i; for i in ${!A[@]}; do echo $i; done }
alias names-list=$f
name names-list
@end

f Names.dict.item
@doc
Show a name and its dependencies in a dict
$f DICT NAME
@cod
f () { local -n A=${1:?}; echo ${2:?}: ${A[$2]}; }
alias name-show=$f
name name-show
@end

f Names.list.map
@doc
The map func on STDIN
LIST | $f FUNC ARG ...
@cod
f () { while read; do "$@" "$REPLY"; done; }
alias list-map=$f' '
name list-map
@end

#f Names.dict.items
#@doc
#Show all names in a dict with their dependencies
#@cod
#f () { names-list | list-map name-show $1 | sort | column -ts:; }
#alias names-show="$f Names"
#name names-show names-list list-map name-show
#@end

alias items=Names.dict.items
doc items "Show all key value pair in a dict"
items () { names-list ${1:?}| list-map name-show $1 | sort | column -ts:; }
alias names-show='items Names'
alias docs-show='items Docs'

f Names.name.pname?
@doc
Test if NAME is syntactically a PARAMETER
@cod
f () { [[ ${1:?} = ${1//[-.?]/} ]]; }
alias pname?=$f
@end

f Names.name.alias?
@doc
Test if NAME is an ALIAS
@cod
f () { [[ -v alias[${1:?}] ]]; }
alias alias?=$f
@end

f Names.name.func?
@doc
Test if NAME is a FUNCTION
$f NAME
@cod
f () { declare -f ${1:?} > /dev/null; }
alias func?=$f
@end

f Names.name.param?
@doc
Test if NAME is a PARAMETER
$f NAME
@cod
f () { declare -p ${1:?} &> /dev/null; }
alias param?=$f
@end

f Names.name.array?
@doc
Test if NAME is an ARRAY
$f NAME
@cod
f () { pname? ${1:?} && [[ "${!1@a}" = a ]]; }
alias array?=$f
@end

f Names.name.assoc?
@doc
Test if NAME is an ASSOC
$f NAME
@cod
f () { pname? ${1:?} && [[ "${!1@a}" = A ]]; }
alias assoc?=$f
@end

f Names.func.src.std
@doc
Output standard BASH reprensation of a FUNCTION
$f FUNCTION
@cod
f () { declare -f ${1:?}; }
alias func-src-std=$f
name func-src-std
@end

f Names.func.src.line
@doc
Ouput a reprensation of a FUNCTION on one line
@cod
f () {
    < <(declare -f ${1:?}) mapfile -t
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
alias func-src-line=$f
name func-src-line
@end

f Names.func.src
@doc
Call func-src-std or func-src-line depending on "src" variable value
src=[std|line] $f FUNCTION
@cod
f () { local -A a=([std]=Names.func.src.std [line]=Names.func.src.line); ${a[${src:-line}]} "$@"; }
alias func-src=$f
name func-src func-src-std func-src-line
@end

f Names.error
@doc
Error helper, output ARGS on STDERR and return 1
$1 TXT ...
@cod
f () { echo "ERROR: $@" >&2; return 1; }
alias error=$1
@end

f Names.name.src
@doc
Output a homoiconic reprensation of a NAME
$f NAME
@cod
f () {
    local -i found
    alias? ${1:?} && { alias $1; let ++found; }
    func? $1 && { func-src $1; let ++found; }
    { param? $1 || array? $1 || assoc? $1; } && { declare -p $1; let ++found; }
    ((found)) && return
    error $1 is not defined
}
alias name-src=$f
name name-src alias? func? func-src param? array? assoc? error
@end

f Names.names.pp.src
@doc
Call Names.name.src on positional parameters
$f NAME ...
If NAME is an ALIAS also call Names.name.src for head of ALIAS
@cod
f () {
    local -A seen=(); local i
    for i; do
	if alias? $i; then
	    test -v seen[$i] || { name-src $i; ((++seen[$i])); }
	    local a=(${alias[$i]}); local f=${a[0]}
	    func? $f && test -v seen[$f] || { name-src $f; ((++seen[$f])); }
	fi
	test -v seen[$i] || { name-src $i; ((++seen[$i])); }
    done
}
alias src=$f
name src name-src alias? alias
@end

alias closure=Names.closure
alias closure-rec=${alias[closure]}-rec
name closure closure-rec
closure () { assert test $# -ge 2; local -A seen=(); closure-rec "$@"; }
closure-rec () {
    assert test ${FUNCNAME[1]} = ${FUNCNAME[0]%-*} -o ${FUNCNAME[1]} = main -o ${FUNCNAME[1]} = ${FUNCNAME[0]}
    local -n A=${1:?}; local i
    for i in ${@:2}; do
	test -v A[$i] || fail $i not in $1
	test -v seen[$i] && continue
	echo $i; ((++seen[$i]))
	local a=(${A[$i]})
	test ${#a[*]} -gt 0 && ${FUNCNAME[0]} $1 ${a[@]}
    done
}

names-show
echo
docs-show

exit 0

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

run () { use ${1:?}; echo -n "$1"; shift; echo "${IFS:0:1}" "${@@Q}"; }
name run use

main () { (($#)) && { eval "$@"; exit $?; }; }
name main all

all () { aliases; src $(closure $(names-list)); }
name all $(names-list)

main "$@"
all
