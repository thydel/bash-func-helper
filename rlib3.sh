set -euo pipefail
shopt -s expand_aliases

# This script acts as a modulino to export parts of a bash workspace as a bash script
#
# It uses pseudo namespace via aliases or declared dependency trees to select parts of a
# workspace
#
# It allows remote execution of a simple command (without any special characters) with all
# its dependencies (functions, variable of any type and aliases) via ssh

#### meta lib

declare -A _items=()            # dependency trees
declare -A _comments=()         # items comments

alias name=meta.name
name () {
    : ${1:?}; unset -v fail;
    for i in ${@:2}; do [ -v BASH_ALIASES[$i] ] && "${fail:?$1 $i redefined}" || BASH_ALIASES[$i]=$1.$i; done; }

name meta expand comment splitargs item list header lib use deps closure items

expand () {
    unset -v fail; local -n _n=${1:?}; ((${#_n})) || "${fail:?$1 in ${FUNCNAME[1]} has no value}";
    [ -v BASH_ALIASES[$_n] ] && _n=${BASH_ALIASES[$_n]% *}; }

comment () { : ${2:?}; local k=$1; expand k; _comments[$k]+="${@:2}"; }

comment name "name pseudo namespace for functions via alias"
comment expand "expand var value to first word of alias if value is an alias"
comment comment "fill comments table for item"

comment splitargs "split @ by -- in two array ref"
splitargs () {
    local -n _a=$1 _b=$2; shift 2;
    for ((i=1; i<=$#; ++i)); do test "${@:$i:1}" == -- && break; done; _a=("${@:1:(($i-1))}"); _b=("${@:(($i+1)):$#}"); }

comment item "emit src for func var or namespace alias"
item () {
    : ${1:?}; local a=(${1//./ }) b=${1/#${a[0]}.};
    test -v $1 || test -v $1[@] && declare -p $1; ${_src:-declare -f} $1;
    [ -v BASH_ALIASES[$b] ] && [ ${BASH_ALIASES[$b]} == $1 ] && alias $b || true; }

# list of names in a namespace N via compgen (N.func, N_var, N)
list () { compgen -A function $1.; compgen -v $1_; echo $1; }

# header of output script
header () { local i; for i in 'set -euo pipefail' 'shopt -s expand_aliases'; do echo $i; done; }

lib () {             # emit header, src for all items of a namespace list, then a command
    header; local libs cmd l; splitargs libs cmd "$@";
    for l in ${libs[@]}; do list $l | while read; do item $REPLY; done; done; echo ${cmd[@]:-:}; }

use () {           # fill dependencies tree from list of targets and list of dependencies
    local users uses user; splitargs users uses "$@";
    for user in ${users[@]}; do deps $user ${uses[@]}; done; }

deps () {            # insert list of dependencies for a target with aliases substitution
    : ${2:?}; local -n alias=BASH_ALIASES; local user=$1; shift;
    [ -v alias[$user] ] && user=${alias[$user]% *};
    local use; local uses=()
    for use; do [ -v alias[$use] ] && uses+=(${alias[$use]% *}) || uses+=($use); done
    local deps=(${_items[$user]:-});
    deps+=(${uses[@]});
    _items[$user]=${deps[@]}; }

closure () {                    # emit all items of a dependency tree for a list of items
    local i a; set +u; [[ "${seen@a}" = A ]] || local -A seen=(); set -u
    for i; do
        [ -v BASH_ALIASES[$i] ] && i=${BASH_ALIASES[$i]% *};
        [[ -v seen[$i] ]] && continue
        item $i; ((++seen[$i]))
        a=(${_items[$i]:-});
        ((${#a[*]})) && ${FUNCNAME[0]} ${a[@]}
    done; }

items () {         # emit header, src for all dependencie for a listof itens, then a command
    header; local items cmd; splitargs items cmd "$@";
    closure ${items[@]}; echo ${cmd[@]:-:}; }

comments () { local comment; for comment in "${!_comments[@]}"; do echo $comment "${_comments[$comment]}"; done; }
use comments -- _comments

use lib -- header splitargs list item
use use items -- splitargs
use closure -- item
use items -- header closure

unalias item list header deps closure

#### std lib

name std macro fail assert a2v

macro () {                      # tells a list of aliases to expand their first arg
    local -n a=BASH_ALIASES;
    for i; do if [ -v a[$i] ]; then local v=${BASH_ALIASES[$i]}; [ "${v: -1}" != " " ] && a[$i]+=" "; fi; done; }

# break script without exiting an interactive shell
fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }

# assert a simple command
assert () { $@ || fail "${FUNCNAME[1]} $@"; }

# emit a list of global var declaration from a associative array
a2v () { local -n a=$1; assert test ${#a[@]} -gt 0; for i in ${!a[@]}; do declare -g $i="${a[$i]}"; done; "${@:2}"; }

use assert -- fail
use a2v -- assert

name std list map maparg pipe cnt; macro maparg cnt
list () { for i; do echo "$i"; done; }
map () { while read; do "$@" $REPLY; done; }
mapargs () { local cmd args; splitargs cmd args "$@"; for i in "${args[@]}"; do "${cmd[@]}" "$i"; done; }
pipe () { local a b; splitargs a b "$@"; < <(${a[@]}) ${b[@]}; }
cnt () { "$@" | wc -l; }

name std terse func; macro terse
terse () { local _src=std.func; "$@"; }
func () { # output a func as a single line
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
    echo ${a[@]}; }

name ft files dirs unit du-sum info; declare -A ft=()
use ft.find -- assert
use files dirs info -- ft.find
use ft.list ft.du -- files
use du-sum -- ft.du
use du-sum info -- ft

ft.find () { assert test -d ${1:?}/; find $1 "${@:2}"; }
files () { ft.find $1 -type f "${@:2}"; }
dirs () { ft.find $1 -type d "${@:2}"; }
ft.list () { files "$@" -print0 | xargs -0r ls -lsht; }
unit () { unit=${1:?}; "${@:2}"; }
ft.du () { files "$@" -print0 | xargs -0r du -c -B${unit:-K}; }

ft[du-sum-jq]='[inputs] | map(split("\t")[0] | tonumber) | add / 1024 | floor | "\(.)G"'
du-sum () { unit=1M; ft.du "$@" | grep total | jq -nRr "${ft[du-sum-jq]}"; }

ft[info-jq]='[inputs] as [ $host, $files, $dirs, $sizeM, $path ] | { $host, $files, $dirs, $sizeM, $path }'
ft.info () {
    { hostname; ft.find $1/ -type f | wc -l; ft.find $1/ -type d | wc -l; du -sm $1/ | fmt -1; } | jq -nR "${ft[info-jq]}"; }

main () { (($#)) && { eval "$@"; exit $?; } || true; }
main "$@"
terse lib meta

# Local Variables:
# indent-tabs-mode: nil
# fill-column: 92
# End:
