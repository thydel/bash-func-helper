#!/bin/bash

run () { declare -f ${1:?}; echo "$@"; }
is-func ()  { declare -f ${1:?} > /dev/null; }
is-param () { declare -p ${1:?} &> /dev/null; }
src () { { is-func $1 && declare -f $1; } || { is-param $1 && declare -p $1; }; }
with () { until [[ ${1:?} == -- ]]; do src $1; shift; done; run "${@:2}"; }
on () { ssh ${1:?} bash -c "'$(${@:2})'"; }
