#!/bin/bash

source <(bfh core4)

shopt -s expand_aliases

declare -A dupli_sets=([big]= [medium]= [small]=)
dupli-set-list () { [[ -v dupli_sets[$1] ]] || fail ${1:?} not in ${!dupli_sets[@]}; dupli sets list $1; }
name dupli-set-list dupli_sets

awk-sum () { awk '{s+=$1}END{print s}'; }
dupli-oldest-weeks-size () { dupli-set-list ${1:?} | xargs -i dupli files size weeks=${2:-16} set={} | tee /dev/stderr | awk-sum; }
name dupli-oldest-weeks-size dupli-set-list awk-sum

dupli-oldest-weeks-rm () { dupli-set-list ${1:?} | xargs -i dupli files raw weeks=${2:-16} set={} | xargs rm; }
name dupli-oldest-weeks-rm dupli-set-list

main "$@"
all
