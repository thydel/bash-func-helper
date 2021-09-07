#!/bin/bash

shopt -s expand_aliases

meta.is-tree () { [[ ${1:?} =~ (^[^.]$)|(^[^.]+.*[^.]$) ]]; }
meta.tree () { { [[ $# -eq 0 ]] && echo $meta_tree; } || { [[ $# -eq 1 ]] && meta.is-tree $1 && meta_tree=$1; }; }
meta.macro () { local i; [[ $# -ge 1 ]] && for i; do alias $i=${meta_tree:?}.$i; done; }

meta.tree meta
meta.macro macro

macro un-macro tree {no,is}-tree funcs vars aliases items import use-aliases hof forget src run with {,un}use

un-macro () { local i; [[ $# -ge 1 ]] && for i; do [[ -v BASH_ALIASES[${1:?}] ]] && unalias $i; done; }
no-tree () { unset meta_tree; }

funcs () { [[ ${1:?} =~ (^[^.]$)|(^[^.]+.*[^.]$) ]] && compgen -A function ${1:?} | ifne -n false; }
vars () { compgen -v ${1:?}; }
aliases () { local k; [[ $# -eq 1 ]] && for k in ${!BASH_ALIASES[@]}; do [[ ${BASH_ALIASES[$k]} =~ ^$1[.]([^.]*)$ ]] && echo $k; done; true; }
# items () { vars ${1}_; funcs $1; aliases $1; }
items () { vars ${1}_; funcs $1; }

macro import.{item,tree}
meta_import_match_all=.
meta_import_match_top=[^.]
meta_import_match=$meta_import_match_top
import.item () { [[ $# -eq  2 ]] && [[ $2 =~ ^$1[.]($meta_import_match*)$ ]] && alias ${BASH_REMATCH[1]}=$2; }
import.tree () { local f; [[ $# -eq 1 ]] && is-tree $1 && for f in $(meta.funcs ${1:?}); do import.item $1 $f; done; }
import () { local t; [[ $# -ge 1 ]] && for t; do import.tree $t; done; }

macro hof.item
hof.item () { [[ -v BASH_ALIASES[${1:?}] ]] && BASH_ALIASES[$1]+=" "; }
hof () { local a; [[ $# -ge 1 ]] && for a; do hof.item $a; done; }
hof hof

macro use-aliases.tree
use-aliases.tree () { local k; [[ $# -eq 1 ]] && for k in ${!BASH_ALIASES[@]}; do [[ ${BASH_ALIASES[$k]} =~ ^$1[.]([^.]*)$ ]] && alias $k; done; }
use-aliases () { local t; [[ $# -ge 1 ]] && for t; do use-aliases.tree $t; done; }

macro forget.{item,tree}
forget.item () { [[ -v BASH_ALIASES[${1:?}] ]] && unalias $1; }
forget.tree () { local f; for f in $(meta.funcs ${1:?}); do [[ $f =~ ^$1[.](.*) ]] && forget.item ${BASH_REMATCH[1]}; done; }
forget () { local i; [[ $# -eq 1 ]] && for i; do forget.tree $i; done; }

macro src.is-{func,param,alias}
src.is-func ()  { declare -f ${1:?} > /dev/null; }
src.is-param () { declare -p ${1:?} &> /dev/null; }
src.is-alias () { [[ -v BASH_ALIASES[${1:?}] ]]; }
# src () { { src.is-func $1 && declare -f $1; } || { src.is-param $1 && declare -p $1; }; { src.is-alias $1 && alias $1; }; }
src () { { src.is-func $1 && declare -f $1; } || { src.is-param $1 && declare -p $1; }; }
hof src

run () { declare -f ${1:?}; echo "$@"; }
with () { until [[ ${1:?} == -- ]]; do src $1; shift; done; run "${@:2}"; }

macro use.declare-{item,tree}
use.declare-item () { [[ ${1:?} =~ ^[^._]*[._] ]] && src $1; }
use.declare-tree () { items ${1:?} | while read; do use.declare-item $REPLY; done; }
use () { echo shopt -s expand_aliases; until [[ ${1:?} == -- ]]; do use-aliases $1; use.declare-tree $1; shift; done; echo "${@:2}"; }
unuse () { unset -f $(funcs ${1:?}); unset $(vars ${1}_); meta.forget $1; }

un-macro forget.item src-is-{func,param} use.declare-{item,loop}

tree std
macro fail assert map as on{,-with-stdin} pipe amap task

fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
assert () { $@ || fail "$@"; }
map () { while read; do "$@" "$REPLY"; done; }
as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh ${user:+${user}@}${1:?} bash; }
on-with-stdin () { ssh ${user:+${user}@}${1:?} bash -c "'$(${@:2})'"; }

alias index--='local i; for ((i = 1; i <= $# ; ++i)); do [[ ${@:$i:1} == -- ]] && break; done;'
pipe () { index-- < <(${@:1:(($i - 1))}) ${@:(($i + 1)):$#}; }
amap () { index-- for f in ${@:1:(($i - 1))}; do $f ${@:(($i + 1)):$#}; done; }
unalias index--
task () { ${1:?}.target "${@:2}" || $1.rule "${@:2}"; }

awk.sum () { awk '{ s += $1 } END { print s }'; }

tree misc

misc_foo=42

macro showswap showswap.{find,show}
showswap.find () { find /proc -maxdepth 2 -mmin +1 -name status | xargs grep -l VmSwap | xargs grep -h -e Name -e Swap -e Tgid | cut -d: -f2; }
showswap.show () { cut -d: -f2 | paste - - - | column -t | sort -nr -k3 | grep -v ' 0 '; }
showswap () { showswap.find | showswap.show; }

no-tree

echo shopt -s expand_aliases

libs=(meta std misc)
hofs=(hof scr)

forget ${libs[@]}
import ${libs[@]}
hof ${ofs[@]}

use ${libs[@]} --
#use-aliases ${libs[@]}
