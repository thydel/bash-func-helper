#!/bin/bash

self=$(basename "${BASH_SOURCE[0]}" .sh)

load () { source <($@); }
comment () { echo -n '# '; "$@"; }
fail() { unset -v fail; : "${fail:?$@}"; }

####

macro.dispatch.body () { ${FUNCNAME[0]}.$1 "${@:2}"; }
macro.dispatch () { declare -f ${FUNCNAME[0]}.body | { mapfile; MAPFILE[0]="$1 ()"; echo "${MAPFILE[@]}"; }; }
load macro.dispatch macro

####

dict.new () { for i in "$@"; do echo declare -Ag "$i=()"; done; }
dict.self () { local -n d=$1; declare -p $1; }
dict.set () { local -n d=$1; d[$2]="${@:3:$#}"; }
dict.get () { local -n d=$1; echo "${d[$2]}"; }
dict.split () { dict.get "$@" | map split; }
dict.push () { local -n d=$1; d[$2]+="${IFS:0:1}${@:3:$#}"; }
dict.pop () { local -n d=$1; declare -a a=(${d[$2]}); unset a[-1]; d[$2]="${a[@]}"; }
dict.append () { local -n d=$1; d[$2]+="${@:3:$#}"; }
dict.keys () { local -n d=$1; list "${!d[@]}"; }
dict.values () { local -n d=$1; list "${d[@]}"; }
dict.list () { local -n d=$1; paste <(dict.keys $1) <(dict.values $1); }
dict.del () { local -n d=$1; unset d[$2]; }

####

list () { for i in "$@"; do echo "$i"; done; }
split () { list $@; }
map () { while read; do "${@:-echo}" "$REPLY"; done; }
args () {
    declare -a a=("$@"); local k=(${!a[@]}) v=(${a[@]}) s=-- p={} i x y; declare -A A=()
    for i in ${k[@]}; do A[${v[$i]}]=$i; done
    x=${A[$s]:-$(($i-1))} y=${A[$s]:-$i}
    declare -a b=("${a[@]:0:$y}") c=("${a[@]:$(($x + 1))}")
    for i in "${c[@]}"; do "${b[@]//$p/$i}"; done
}

####

load macro dispatch dict
load dict new dict
dict set dict dicts import doc
load dict new $(dict split dict dicts)
dict set dict funcs new self set get split push pop append keys values list del
dict set import dict $(args echo dict.{} -- $(dict get dict funcs))

dict push import dict.split dict.get
args dict push import dict.{} list -- keys values

dict push import split list

####

array.push () { : ${2:?}; declare -n v=$1; v+=($2); }
string-to-array () { : ${2:?}; declare -n v=$1; v=(); local i; for ((i=0; i < ${#2}; ++i)); do v[$i]=${2:$i:1}; done; }

@λ () { func.run λ; unset -f λ; }
try-λ () { seq 3 | map eval $(λ () { expr $1 + $1; }; @λ); }

####

full () { show=full "$@"; }
short () { show=short "$@"; }

load dict new prefix
dict push dict dicts prefix
args dict set prefix {} 2 -- full short

# comment dict self dict

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
func.run () { func use $1; [[ -v prefix[$1] ]] && func use ${@:${prefix[$1]}}; echo "$@"; }

load macro dispatch func
dict set import func.src.std func.name fail
dict set import func.src.one-line func.src.std
dict set import func.src func.src.std func.src.one-line
dict set import func.use func.closure
dict set import func.run func.use

####

funcs () { func all | map func src; }
arrays () { dict split dict dicts | map dict self; }

all () { funcs; alias; arrays; dict self dict; }
none () { :; }

self () { source /dev/stdin <<< "$self () { :; }"; func closure $self | map func src; }

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"

all
