set -euo pipefail
shopt -s expand_aliases

with () { : ${1:?}; unset -v fail; for i in ${@:2}; do [ -v BASH_ALIASES[$i] ] && "${fail:?$1 $i redefined}" || BASH_ALIASES[$i]=$1.$i; done; }

with lib splitargs item list head use self
splitargs () { local -n _a=$1 _b=$2; shift 2; for ((i=1; i<=$#; ++i)); do test "${@:$i:1}" == -- && break; done; _a=("${@:1:(($i-1))}"); _b=("${@:(($i+1)):$#}"); }
item () { : ${1:?}; local a=(${1//./ }) b=${1/#${a[0]}.}; test -v $1 || test -v $1[@] && declare -p $1; declare -f $1; [ -v BASH_ALIASES[$b] ] && alias $b || true; }
list () { compgen -A function $1.; compgen -v $1_; echo $1; }
head () { local i; for i in 'set -euo pipefail' 'shopt -s expand_aliases'; do echo $i; done; }
use () { head; local libs cmd l; splitargs libs cmd "$@"; for l in ${libs[@]}; do list $l | while read; do item $REPLY; done; done; echo ${cmd[@]}; }
unalias item list head

main () { (($#)) && { eval "$@"; exit $?; } || true; }

main "$@"
use lib
