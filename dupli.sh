#!/bin/bash

source <(bfh core)

self=$(basename "${BASH_SOURCE[0]}" .sh)
eval "$self () { :; }"

dupli_fulls_set=(big medium small)
dupli_fulls_mode=(older newer)
dupli_fulls_weeks='[ 1 <= N <= 52 ]'
read -rd '' dupli_fulls_help <<!
dupli.fulls SET [-m MODE] [-w WEEKS]
    SET=[${dupli_fulls_set[@]}]
    MODE=[${dupli_fulls_mode[@]}]
    WEEKS=$dupli_fulls_weeks
!
dupli.fulls () {
    [[ $# -eq 0 ]] && fail "$dupli_fulls_help"
    array.has dupli_fulls_set $1 || fail $1 not in "${dupli_fulls_set[@]}"
    local -A args; enum.add args "$@"; local index=("$@")
    local mode weeks
    [[ -v args[-m] ]] && mode=${index[((${args[-m]}+1))]}
    array.has dupli_fulls_mode ${mode:-older} || fail $mode not in "${dupli_fulls_mode[@]}"
    [[ $mode == older ]] && mode=''
    [[ -v args[-w] ]] && weeks=${index[((${args[-w]}+1))]}
    test $weeks -ge 1 -a $weeks -le 52 || fail $weeks not in "$dupli_fulls_weeks"
    dupli sets list $1 | xargs -i dupli files $mode fulls set={} weeks=${weeks:-12} | xargs -r ls -lt
}

deps dupli.fulls fail array.has enum.add dupli_fulls_help
deps dupli_fulls_help dupli_fulls_set dupli_fulls_mode

deps $self dupli.fulls foo

if false; then
    vars.add show_full_weeks
    funcs.add show.full
else any.sync
fi

main "$@"
all

