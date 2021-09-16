#!/bin/bash

shopt -s expand_aliases

################ bootstrap

std.fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
std.assert () { $@ || std.fail "$@"; }

# pseudo func namespace via alias
meta.macro () { local f; case ${1:?} in -l) f=local; shift;; -e) f=expand; shift;; *) f=global;; esac; meta.macro.$f "$@"; }
# alias not yet defined or alias redefine with same value
meta.macro.global.ok () { [[ ! -v BASH_ALIASES[$1] || ${BASH_ALIASES[$1]} == $2.$1 || ${BASH_ALIASES[$1]} == $2.$1" " ]]; }
# will be importable
meta.macro.global () { local i; for i in ${@:2}; do std.assert ${FUNCNAME[0]}.ok $i ${1:?}; alias $i=$1.$i; alias $1.$i=$1.$i; done; }
# only for functions definition
meta.macro.local () { local i; for i in ${@:2}; do alias $i=${1:?}.$i; done; }
# can't be used on undefined aliases
meta.macro.expand.ok () { [[ -v BASH_ALIASES[${1:?}] ]]; }
# for idempotency
meta.macro.expand.item () { [[ ${BASH_ALIASES[${1:?}]} =~ [\ ]$ ]] || BASH_ALIASES[$1]+=" "; }
# tell alias will expand it first arg
meta.macro.expand () { local i; [[ $# -ge 1 ]] && for i; do std.assert ${FUNCNAME[0]}.ok $i; meta.macro.expand.item $i; done; }
meta.macro meta macro

macro meta is-{func,var,alias} src funcs vars aliases items use
macro std fail assert

is-func ()  { declare -f ${1:?} > /dev/null; }
is-param () { declare -p ${1:?} &> /dev/null; }
is-alias () { [[ -v BASH_ALIASES[${1:?}] ]]; }
src () { { is-func $1 && declare -f $1; } || { is-alias $1 && alias $1; }; { is-param $1 && declare -p $1; }; }
macro -e src

funcs () { compgen -A function ${1:?} | ifne -n false; }
vars () { compgen -v ${1:?}; }
aliases () { compgen -a ${1:?} | cut -d. -f2; }
items () { vars ${1}_; funcs $1.; aliases $1.; }

macro -l meta use.tree
use.tree () { items ${1:?} | while read; do meta.src $REPLY; done; }
use () { : ${1:?}; echo shopt -s expand_aliases; until [[ $1 == -- || $# -eq 0 ]]; do use.tree $1; shift; done; echo "${@:2}"; }

################ more lib funcs

macro run run with as on on-with-stdin

run () { declare -f ${1:?}; echo "$@"; }
with () { until [[ ${1:?} == -- ]]; do src $1; shift; done; run "${@:2}"; }
as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh ${user:+${user}@}${1:?} bash; }
on-with-stdin () { ssh ${user:+${user}@}${1:?} bash -c "'$(${@:2})'"; }

macro std map task

map () { while read; do "$@" "$REPLY"; done; }
task () { ${1:?}.target "${@:2}" || $1.rule "${@:2}"; }

awk.sum () { awk '{ s += $1 } END { print s }'; }

use meta std run awk
