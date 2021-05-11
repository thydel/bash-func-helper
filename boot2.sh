#!/bin/bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

####

load () { source <($@); }
comment () { echo -n '# '; "$@"; }
fail() { unset -v fail; : "${fail:?$@}"; }

####

list () { for i in "$@"; do echo "$i"; done; }
split () { list $@; }
map () { while read; do "${@:-echo}" "$REPLY"; done; }
words () { map split; }
args () {
    declare -a a=("$@"); local k=(${!a[@]}) v=(${a[@]}) s=-- p={} i x y; declare -A A=()
    for i in ${k[@]}; do A[${v[$i]}]=$i; done
    x=${A[$s]:-$(($i-1))} y=${A[$s]:-$i}
    declare -a b=("${a[@]:0:$y}") c=("${a[@]:$(($x + 1))}")
    for i in "${c[@]}"; do "${b[@]//$p/$i}"; done
}

####

var.self () { local -n __=$1; echo $1=${__@Q}; }
var.use () { var.self "$@"; shift; "$@"; }

array-or-dict.self () { declare -p $1; }

dict.new () { args echo declare -Ag '{}=()' -- "$@"; }
dict.self () { array-or-dict.self "$@"; }
dict.set () { local -n __=$1; __[$2]="${@:3:$#}"; }
dict.get () { local -n __=$1; echo "${__[$2]}"; }
dict.split () { dict.get "$@" | words; }
dict.push () { local -n __=$1; __[$2]+="${IFS:0:1}${@:3:$#}"; }
dict.pop () { local -n __=$1; declare -a a=(${__[$2]}); unset a[-1]; __[$2]="${a[@]}"; }
dict.append () { local -n __=$1; __[$2]+="${@:3:$#}"; }
dict.keys () { local -n __=$1; list "${!__[@]}"; }
dict.values () { local -n __=$1; list "${__[@]}"; }
dict.list () { paste <(dict.keys $1) <(dict.values $1) | column -s "$(echo -e '\t')" -t; }
dict.del () { local -n __=$1; unset __[$2]; }

array.new () { args echo declare -ag '{}=()' -- "$@"; }
array.self () { array-or-dict.self "$@"; }
array.set () { local -n __=${1:?}; __=("${@:2}"); }
array.get () { local -n __=${1:?}; echo "${__[@]}"; }
array.push () { : ${2:?}; declare -n __=$1; __+=($2); }
array.values () { dict.values "$@"; }

string.to-array () { : ${2:?}; declare -n v=$1; v=(); local i; for ((i=0; i < ${#2}; ++i)); do v[$i]=${2:$i:1}; done; }

####

macro.dispatch.body () { ${FUNCNAME[0]}.${1:-default} "${@:2}"; }
macro.dispatch () { declare -f ${FUNCNAME[0]}.body | { mapfile; MAPFILE[0]="$1 ()"; echo "${MAPFILE[@]}"; }; }

####

load macro.dispatch macro
load macro dispatch dict
load macro dispatch array

load array new arrays
array set arrays vars dicts
load array new $(array get arrays)
array push arrays arrays

array set dicts array dict import
load dict new $(array get dicts)

import () { dict set import "$@"; }

import split list
import words map split

dict set dict funcs new self set get split push pop append keys values list del
import dict $(args echo dict.{} -- $(dict get dict funcs))

import dict.self array-or-dict.self
import dict.split dict.get words
args import dict.{} list -- keys values

####

dict set array funcs new self set push values
import array $(args echo array.{} -- $(dict get array funcs))

import array.self array-or-dict.self
import array.values dict.values

####

test='test vars'
array push vars test

####

@λ () { func.run λ; unset -f λ; }
try-λ () { seq 3 | map eval $(λ () { expr $1 + $1; }; @λ); }

####

full () { show=full "$@"; }
short () { show=short "$@"; }

load dict new prefix
array push dicts prefix
args dict set prefix {} 2 -- full short

####

func.name () { echo ${BASH_ALIASES[${1:?}]:-$1}; }
func.all () { declare -F | while read -a a; do echo ${a[-1]}; done; }
func.src () { declare -A a=([full]=func.src.std [short]=func.src.one-line); ${a[${show:-short}]} "$@"; }
func.src.std () { func.name $1 | { read f; declare -f $f || fail no such func $f; }; }
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
}
func.closure () { { for i in "$@"; do echo $i; ${FUNCNAME[0]} ${import[$i]}; done; } | sort -u; }
func.use () { func closure "$@" | map func src; }
func.run () { func use $1; [[ -v prefix[$1] ]] && func use ${@:${prefix[$1]}}; echo "${@@Q}"; }

load macro dispatch func
import func.src.std func.name fail
import func.src.one-line func.src.std
import func.src func.src.std func.src.one-line
import func.use func.closure
import func.run func.use

####

funcs () { func all | map func src; }
dicts () { array values dicts | map dict self; }
arrays () { array values arrays | map array self; }
vars () { array values vars | map var.self; }

all () { funcs; alias; dicts; arrays; vars; }
none () { :; }

load macro dispatch self
self.declare.build.body () { vars; func use ${FUNCNAME[0]}; echo "${@@Q:2}"; }
self.declare.build () { declare -f ${FUNCNAME[0]}.body | { mapfile; MAPFILE[0]="$1 ()"; echo "${MAPFILE[@]}"; }; }
self.declare () { [[ "$self" ]] || return 1; load self.declare.build $self; func src $self; }
self.default () { vars; self.declare && func closure $self | map func src; }
self.list () { self.declare && dict get import $self | words | map func src; }

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
all
