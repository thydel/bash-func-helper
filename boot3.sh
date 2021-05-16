#!/usr/bin/env bash

bash -version

self=$(basename "${BASH_SOURCE[0]}" .sh)

shopt -s expand_aliases

alias self='local self=${FUNCNAME[0]}'

str.cat () { local IFS=''; echo "$*"; }

declare -A funcs_map=();
func.new.assert () { :; }
if [ $(str.cat ${BASH_VERSINFO[@]:0:3}) == "5 0 3" ]
then
    alias func-to-var='local A=${1//[.-?]/_}_'
    func.new () { self; $self.assert "$@"; func-to-var; funcs_map[$1]=$A; eval declare -ag "$A=()"; func.use "$@"; }
    func.use () { func-to-var; shift; local -n __=$A; __+=("$@"); }
    unalias func-to-var
else
    func.new () { self; $self.assert "$@"; local A=${1//[.-?]/_}_; funcs_map[$1]=$A; eval declare -ag "$A=()"; func.use "$@"; }
    func.use () { local A=${1//[.-?]/_}_; shift; local -n __=$A; __+=("$@"); }
fi

alias new=func.new

new func.new func.new.assert funcs_map func.use
new func.use

fail() { unset -v fail; : "${fail:?$@}"; }; new fail
assert() { "$@" || fail ${BASH_SOURCE[-1]}, ${FUNCNAME[-1]}, "$@"; }; new assert

enum () {
    echo '('
    local a i
    for ((a = 1, i = ${first:-0}; a <= $#; ++a, i += ${incr:-1})) do echo [${!a}]=$i; done
    echo ')'
}; new enum

name.type () {
    assert test $# -eq 1;
    declare -A types=([--]=var [-a]=array [-A]=dict);
    local declare=($(declare -p "$1" 2> /dev/null));
    local type=${declare[@]:1:1};
    [ -v types[$type] ] && { echo ${types[$type]}; return; };
    declare -f "$1" > /dev/null && { echo func; return; }
    echo undef
}; new name.type

name.is? () { [[ $(name.type $1) == $2 ]]; }; new name.is?

name.src.var () { local -n __=$1; echo $1=${__@Q}; }
name.src.array () { declare -p $1; }
name.src.dict () { declare -p $1; }
name.src.func () { declare -f $1; }
name.src.undef () { fail $1 is undef;  }
name.src_ () { name.src.$(name.type $1) $1; }
name.src () { for type in $(name.type $1); do name.src.$type $1; done; }

name_src_funcs=(var array dict func undef)
for func in ${name_src_funcs[@]}; do new name.src.$func; done
func.use name.src.undef fail
new name.src ${name_src_funcs[@]/#/name.src.}

name () {
    assert test $# -ge 2;
    declare -A func=$(first=2 incr=0 enum type src);
    declare -A func+=$(first=3 enum is?)
    assert test -v func[$2];
    assert test $# -eq ${func[$2]};
    declare -A type=$(enum var array dict func undef);
    [ $# -eq 3 ] && assert test -v type[$3];
    local a=("$@");
    unset a[1];
    name.$2 "${a[@]}"
}
func.new.assert () { assert name $1 is? func; }

new name name.type name.is? name.src

loop () {
    declare -A seen=();
    for func in "${funcs_map[@]}"; do
	declare -n names="$func";
	for name in "${names[@]}"; do
	    [ -v seen[$name] ] || { ((++seen[$name])); name.src $name; }
	done;
    done;
}

main () { (($#)) && { "$@"; exit $?; }; }

main "$@"
loop
