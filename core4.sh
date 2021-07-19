#!/bin/bash

# [Bash - Functions in Shell Variables]: https://unix.stackexchange.com/questions/233091/bash-functions-in-shell-variables

shopt -s expand_aliases

[[ "$Names" ]] || [[ "${Names@a}" ]] && ${FUNCNAME:?}; declare -A Names=()
[[ "$Names_Doc" ]] || [[ "${Names_Doc@a}" ]] && ${FUNCNAME:?}; declare -A Names_Doc=()

alias doc='Names.doc Names_Doc'
Names.doc () {
    : ${3:?}; local -n A=$1 alias=BASH_ALIASES; shift; local name
    [[ -v alias[$1] ]] && name=${alias[$1]% *} || name=$1; shift
    for i; do
	! [[ -v A[$name] ]] && A[$name]=${i/SELF /$name } || A[$name]+=$'\n'${i/SELF /$name }
    done
}

alias deps=Names.dict.pp.add-deps
doc deps "Set name dependencies in dict from positional parameters"
doc deps "SELF DICT NAME [DEPENDENCY] ..."
doc deps "If NAME is an ALIAS, add a dependency for NAME to head of ALIAS"
doc deps "If DEPENDENCY is an ALIAS, replace NAME by head of ALIAS"
deps () {
    : ${2:?}; local -n A=$1 alias=BASH_ALIASES; shift; local name=$1; shift
    [[ -v alias[$name] ]] && [[ ! -v A[$name] ]] && { A[$name]=${alias[$name]% *}; name=${A[$name]}; }
    local i; local d=()
    for i; do [[ -v alias[$i] ]] && d+=(${alias[$i]% *}) || d+=($i); done
    local a=(${A[$name]})
    a+=(${d[@]})
    A[$name]=${a[@]}
}
alias name='deps Names'

alias names=Names.dict.pp.add-names
alias nameDist=Names.dict.pp.dist-dep
alias namesList=Names.dict.list
alias nameShow=Names.dict.item
alias listMap=Names.list.map' '

alias list='namesList Names'

doc names "Add names to dict" "SELF DICT NAME ..."
doc nameDist "Distribute a dependency to names in a dict"
doc namesList "List names in dict"
doc nameShow "Show a name and its dependencies in a dict"
doc listMap "The map func on STDIN" "LIST | SELF FUNC ARG ..."

names () { local i; for i; do name $i; done; }
nameDist () { local i; for i in ${@:2}; do name $i $1; done; }
namesList () { local -n A=${1:?}; local i; for i in ${!A[@]}; do echo $i; done }
nameShow () { local -n A=${1:?}; echo ${2:?}: "${A[$2]}"; }
listMap () { while read; do "$@" "$REPLY"; done; }

names deps doc name names nameDist namesList nameShow listMap list

alias items=Names.dict.items
doc items "Show all key value pair in a dict"
items () { namesList ${1:?}| listMap nameShow $1 | sort | column -ts:; }
alias namesShow='items Names'

names items namesShow

alias pnameP=Names.name.pnameP
alias aliasP=Names.name.aliasP
alias funcP=Names.name.funcP
alias paramP=Names.name.paramP
alias arrayP=Names.name.arrayP
alias assocP=Names.name.assocP

names pnameP aliasP funcP paramP arrayP assocP

pnameP () { [[ ${1:?} = ${1//[-.?]/} ]]; }
aliasP () { [[ -v BASH_ALIASES[${1:?}] ]]; }
funcP ()  { declare -f ${1:?} > /dev/null; }
paramP () { declare -p ${1:?} &> /dev/null; }
arrayP () { pnameP ${1:?} && [[ "${!1@a}" = a ]]; }
assocP () { pnameP ${1:?} && [[ "${!1@a}" = A ]]; }

doc pnameP "Test if NAME is syntactically a PARAMETER"
doc aliasP "Test if NAME is an ALIAS"
doc funcP  "Test if NAME is a FUNCTION"
doc paramP "Test if NAME is a PARAMETER"
doc arrayP "Test if NAME is an ARRAY"
doc assocP "Test if NAME is an ASSOC"

alias funcSrcStd=Names.func.src.std
alias funcSrcLine=Names.func.src.line
alias funcSrc=Names.func.src

names funcSrcStd funcSrcLine funcSrc

doc funcSrcStd "Output standard BASH reprensation of a FUNCTION"
doc funcSrcLine "Ouput a reprensation of a FUNCTION on one line"
read -rd '' funcSrc  <<!
Call ${BASH_ALIASES[funcSrcStd]} or ${BASH_ALIASES[funcSrcLine]} depending on "src" variable value
src=[std|line] SELF FUNCTION
"src" default to "line"
!
doc funcSrc "$funcSrc"

funcSrcStd () { declare -f ${1:?}; }
funcSrcLine () {
    local -n a=MAPFILE
    < <(declare -f ${1:?}) mapfile -t
    ((${#a[*]})) || return 1
    local i t
    for ((i = 2; i < $((${#a[*]} - 1)); ++i)); do
	t=${a[(($i + 1))]}
	printf -v n ${t/\%/%%}
	[[ ${#n} == 1 && ${n:(-1)} == "}" ]] || [[ ${#n} == 2 && ${n:(-2)} == "};" ]] && a[$i]+=";";
    done
    a[-1]+=';'
    echo ${a[@]}
}
funcSrc () { local -A a=([std]=Names.func.src.std [line]=Names.func.src.line); ${a[${src:-line}]} "$@"; }

alias error=Names.error
alias fail=Names.fail
alias assert=Names.assert
alias not=Names.not

doc error "Error helper, output ARGS on STDERR and return 1"

error () { echo "ERROR: $@" >&2; return 1; }
fail () { unset -v fail; (echo ${BASH_SOURCE[-1]} ${FUNCNAME[@]}; echo "FAIL: $@") >&2; : "${fail:?''}"; }
assert () { "$@" || fail "$@"; }
false && alias assert=': '
not () { ! "$@"; }

names fail

alias nameSrc=Names.name.src
doc nameSrc "Output a homoiconic reprensation of a NAME"
nameSrc () {
    local -i found
    aliasP ${1:?} && { alias $1; let ++found; }
    funcP $1 && { funcSrc $1; let ++found; }
    { paramP $1 || arrayP $1 || assocP $1; } && { declare -p $1; let ++found; }
    ((found)) && return
    error $1 is not defined
}
name nameSrc aliasP funcP funcSrc paramP arrayP assocP error

alias src=Names.names.pp.src
doc src "Call Names.name.src on positional parameters" "SELF NAME ..."
doc src "If NAME is an ALIAS recurse head of ALIAS"
src () {
    local i a; assocP seen || local -A seen=()
    for i; do
	test -v seen[$i] && continue
	aliasP $i && { a=(${BASH_ALIASES[$i]}); ${FUNCNAME[0]} ${a[0]}; }
	nameSrc $i; ((++seen[$i]))
    done
}
name src aliasP nameSrc funcP nameSrc

alias closure='Names.closure Names'
name closure
Names.closure () {
    local n=${1:?}; shift; local -n A=$n; local i a
    assocP seen || local -A seen=()
    for i; do
	false && { [[ -v A[$i] ]] || fail $i not in $n; }
	[[ -v seen[$i] ]] && continue
	echo $i; ((++seen[$i]))
	a=(${A[$i]}); ((${#a[*]})) && ${FUNCNAME[0]} $n ${a[@]}
    done
}

alias show='Names.show-doc Names_Doc'
Names.show-doc () {
    : ${2:?}; local -n A=$1 alias=BASH_ALIASES; shift; local name
    [[ -v alias[$1] ]] && name=${alias[$1]% *} || name=$1; shift
    mapfile -t <<< "${A[$name]}"
    for i in "${MAPFILE[@]}"; do echo "# $i"; done
    funcP $name && { echo; src=std funcSrc $name; }
}
name show funcP funcSrc

aliases () { echo shopt -s expand_aliases; }
name aliases

use () { aliases; src $(closure "${@:?}"); }
name use aliases src closure

run () { use ${1:?}; echo -n "$1"; shift; echo "${IFS:0:1}" "${@@Q}"; }
name run use

run-in () { : ${2:?}; local d=$1; use $2; echo -n "(cd $1; $2"; shift 2; echo "${IFS:0:1}" "${@@Q})"; }
name run-in use

main () { (($#)) && { eval "$@"; exit $?; }; }
name main all

all () { aliases; src $(closure $(list)); }
name all $(list) Names Names_Doc

main "$@"
all
