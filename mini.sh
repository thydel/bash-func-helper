#!/bin/bash

# pseudo namespace and remote execution lib

shopt -s expand_aliases

################ bootstrap

std.fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }; alias fail=std.fail
std.assert () { $@ || fail "${FUNCNAME[1]} $@"; }; alias assert=std.assert

alias self='local self=${FUNCNAME[0]} {a..z}'

# pseudo func namespace via alias
meta.macro () { self; case ${1:?} in -l) f=local; shift;; -e) f=expand; shift;; -*) fail $1;; *) f=global;; esac; $self.$f "$@"; }
# alias not yet defined or alias redefine with same value
meta.macro.global.ok () { [[ ! -v BASH_ALIASES[$1] || ${BASH_ALIASES[$1]} == $2.$1 || ${BASH_ALIASES[$1]} == $2.$1" " ]]; }
# will be importable
meta.macro.global () { self; for i in ${@:2}; do assert $self.ok $i ${1:?}; alias $i=$1.$i; alias $1.$i=$1.$i; done; }
# only for functions definition
meta.macro.local () { self; for i in ${@:2}; do alias $i=${1:?}.$i; done; }
# can't be used on undefined aliases
meta.macro.expand.ok () { [[ -v BASH_ALIASES[${1:?}] ]]; }
# for idempotency
meta.macro.expand.item () { [[ ${BASH_ALIASES[${1:?}]} =~ [\ ]$ ]] || BASH_ALIASES[$1]+=" "; }
# tell alias will expand it first arg
meta.macro.expand () { self; [[ $# -ge 1 ]] && for i; do assert $self.ok $i; $self.item $i; done; }
meta.macro meta macro

macro meta is-{func,param,alias} src funcs vars aliases items use short
macro std fail assert

is-func ()  { case ${1:?} in -*) fail $1;; esac; declare -f $1 > /dev/null; }
is-param () { case ${1:?} in -*) fail $1;; esac; declare -p ${1:?} &> /dev/null; }
is-alias () { [[ -v BASH_ALIASES[${1:?}] ]]; }

short () { show=short "$@"; }

macro -l meta src.{alias,func{,.{std,short}}}
macro -e src short

src () { local _f; { is-func $1 && { src.func $1 && _f=1; }; } || { is-alias $1 && { src.alias $1; _f=1; }; }; is-param $1 && { declare -p $1; _f=1; }; assert [ "$_f" ]; }
src.alias () { local a=${BASH_ALIASES[$1]% }; alias $1; [[ ( ! -v show || $show != short ) && "$a" = "${BASH_ALIASES[$a]}" ]] && echo alias $a=$a; }
src.func () { self; s=${show:-std}; case $s in std|short) :;; *) fail $s;; esac; $self.$s "$@"; }
src.func.std () { declare -f ${1:?}; }
src.func.short () {
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

funcs () { compgen -A function ${1:?} | ifne -n false; }
vars () { compgen -v ${1:?}; }
aliases () { compgen -a ${1:?} | cut -d. -f2; }
items () { vars ${1}_; funcs $1.; aliases $1.; }

macro -l meta use.tree
use.tree () { items ${1:?} | { ifne -n false || fail $1; } | while read; do meta.src $REPLY; done; }
use () { : ${1:?}; echo shopt -s expand_aliases; until [[ $1 == -- || $# -eq 0 ]]; do use.tree $1; shift; done; eval "${@:2}"; }

################ more lib funcs

macro play run with as on

run () { declare -f ${1:?}; echo -n "$1"; shift; echo "${IFS:0:1}" "${@@Q}"; }

with () {
    case $1 in
	-i) assert [ $# -ge 2 ]; stdin=true ${FUNCNAME[0]} "${@:2}";;
	-d) assert [ $# -ge 3 ]; chdir=$2 ${FUNCNAME[0]} "${@:3}" ;;
	-*) fail $1;;
	*)
	    assert [ $# -ge 1 ];
	    until [[ $1 == -- || $# -eq 0 ]]; do src $1; shift; done;
	    (($#)) || return;
	    if [ "$chdir" ]; then echo -n "(cd $chdir;"; shift; echo -n "${IFS:0:1}${@@Q}"; echo ')'; else shift; echo -n "${IFS:0:1}${@@Q}"; fi
	    if [ "$stdin" ]; then echo -e " <<EOF\n\$(cat)\nEOF"; cat; else echo; fi
	;;
    esac;
}

as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh ${user:+${user}@}${1:?} bash; }

macro std map task

map () { while read; do "$@" "$REPLY"; done; }
task () { ${1:?}.target "${@:2}" || $1.rule "${@:2}"; }

awk.sum () { awk '{ s += $1 } END { print s }'; }

unalias self
self () { use meta std play awk; }
main () { (($#)) && { eval "$@"; exit $?; }; }
main "$@"

####

_f_ () { case $1 in -[a-d]) eval ${1#-}=1 ${FUNCNAME[0]} "${@:2}";; -*) fail $1;; *) echo $a - $b - $c - $d;; esac; }
