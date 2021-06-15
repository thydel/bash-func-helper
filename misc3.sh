#!/bin/bash

source <(bfh core4)

shopt -s expand_aliases

# Don't use diff on big files
# sql-dump.no-USE () { [[ -f ${1:?}.gz ]] && { zcat $1.gz | sed '/^USE /d' | gzip > $1-no-USE.gz; zdiff $1{,-no-USE}.gz; }; }

with-mem-used () { command time -f '%C %M' "$@"; }
alias wmu=with-mem-used
sql-dump.no-USE () { [[ -f ${1:?}.gz ]] && wmu zcat $1.gz | wmu sed '/^USE /d' | wmu gzip > $1-no-USE.gz; }
name sql-dump.no-USE with-mem-used

main "$@"
all

