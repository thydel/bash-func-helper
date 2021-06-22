#!/bin/bash

source <(bfh core4)

shopt -s expand_aliases

# Don't use diff on big files
# sql-dump.no-USE () { [[ -f ${1:?}.gz ]] && { zcat $1.gz | sed '/^USE /d' | gzip > $1-no-USE.gz; zdiff $1{,-no-USE}.gz; }; }

with-mem-used () { command time -f '%C %M' "$@"; }
alias wmu=with-mem-used
sql-dump.no-USE () { [[ -f ${1:?}.gz ]] && wmu zcat $1.gz | wmu sed '/^USE /d' | wmu gzip > $1-no-USE.gz; }
name sql-dump.no-USE with-mem-used

# Use with caution
with-mem-limit () { : ${2:?}; echo 2^$1 | bc | command time -f '%C %M' prlimit --data=$(cat) ${@:2}; }
try-diff () { : ${3:?}; [[ -f $2 ]] && [[ -f $3 ]] &&  with-mem-limit $1 zdiff $2 $3; }
name try-diff with-mem-limit

yml2json () { python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin, Loader=yaml.FullLoader), sys.stdout, indent=4)'; }
name yml2json

main "$@"
all

