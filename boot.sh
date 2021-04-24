#!/bin/bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

arrays=(import assert awk help comment group)
for i in ${arrays[@]}; do eval "declare -A $i=()"; done

put1 () { (($# > 1)) || fail "$@" put array var [val]; }
put2 () { local -n __=$1; echo "${__[$2]}"; }
put3 () { local -n __=$1; local e; [[ -v txt ]] || e="${IFS:0:1}"; [[ "$3" ]] && __[$2]+="${@:3:$#}$e" || unset __[$2]; }
put () { put1 "$@" && { (($# == 2)) && put2 $1 "${@:2:$#}"; } || { (($# > 2)) && put3 $1 $2 "${@:3:$#}"; }; }

txt () { txt= "$@"; }
cmnt='txt put comment'
help='txt put help'

import='put import'

vars='import cmnt help'

$cmnt fail 'fail with an error message without exiting current shell'
fail() { unset -v fail; : "${fail:?$@}"; }

$cmnt check-tty 'fail if stdin is a tty'
check-tty () { [ -t 0 ] && fail "input shouldn't be a TTY"; }

awk.f () { echo "$1 () { awk '${awk[$1]}'; }"; }

func-name () { echo ${BASH_ALIASES[${1:?}]:-$1}; }
show-func () { func-name $1 | { read f; declare -f $f || fail no such func $f; }; }
$import show-func func-name fail
list-all-func () { declare -F | awk '{ print $NF }'; }
map () { while read; do "$@" "$REPLY"; done; }
show-all-func () { list-all-func | map show-func; }
$import show-all-func list-all-func map show-func

load () { source <($@); }

$cmnt join 'convert lines of args to line of args '
$cmnt join 'by joining IFS separated words from input whith "$1" (default " ").'$'\n'
$cmnt join 'When "$1" is "\n" acts as "split($join)"'
join () { while read -r; do echo -n "${REPLY}"; echo -ne "${1:-${IFS:0:1}}"; done; }
args () { join; }
$import args join

$cmnt split 'converts args to lines of arg'
split () { for i in "$@"; do echo "$i"; done; }

words () { while read -r; do split ${REPLY}; done; }

$cmnt list 'convert args or lines of args to line of args'
list () { (($#)) && split "$@"; [[ -t 0 ]] || words '\n'; }
$import list split join

put awk func-on-a-line.awk 'f && /^ +};?/ { print $0 ";"; next }'
put awk func-on-a-line.awk 'f { --f; print $0 ";"; next } NR == 1 || /^ +};?/ { print; ++f; next } 1'
load awk.f func-on-a-line.awk
func-on-a-line.sed () { sed -r -e 's/^ +//' -e 's/ +$//'; }
func-on-a-line () { show-func $1 | tac | func-on-a-line.awk | func-on-a-line.sed | tac | args; echo; }

show-all-func-on-a-line () { list-all-func | map func-on-a-line; }
show-array () { declare -p arrays $1; };
show-arrays () { declare -p arrays ${arrays[@]}; };
show-vars () { for n in $vars; do declare -n v=$n; echo $n=${v@Q}; done; }

with-var () { declare -n v=$1; echo $1=${v@Q}; shift; "$@"; }

local-vars () { for n in "$@"; do declare -n v=$n; echo local $n=${v@Q}; done; }
add-vars () { declare -f $1 | { mapfile; echo "${MAPFILE[@]:0:2}"; local-vars "${@:2:$#}"; echo "${MAPFILE[@]:2}"; }; }

full () { show=show-func "$@"; }
short () { show=func-on-a-line "$@"; }

show () { ${show:-func-on-a-line} "$@"; }

closure () { { for i in "$@"; do echo $i; closure ${import[$i]}; done; } | sort -u; }
use () { closure "$@" | map show; }
$import use closure map show

group () { put group ${1:?} | list | map use; }
$import group put list map use-in-md

run () { use $1; echo "$@"; }
$import run use

play () { play=bash "$@"; }

rem () { run "${@:2:$#}" | ssh $1 ${play:-cat}; }
$import rem run

funcs () { show-all-func-on-a-line; }
arrays () { show-arrays; }
vars () { show-vars; }
all () { funcs; alias; arrays; vars; }
none () { :; }

provide () { $import $self; }
self () { source /dev/stdin <<< "$self () { :; }"; closure $self | map func-on-a-line; }
$import self provide

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
all
