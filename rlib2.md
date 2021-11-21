# Libs

## Mini lib

```bash
short () { for i in ${@:2}; do BASH_ALIASES[$i]=${1:?}.$i; done; }
meta () { local -n a=BASH_ALIASES; for i; do [ -v a[$i] ] && { local v=${BASH_ALIASES[$i]}; [ "${v: -1}" != " " ] && a[$i]+=" "; }; done; }
src () { test -v ${1:?} || test -v $1[@] && declare -p $1; declare -f $1; }
srcs () { compgen -A function ${1:?}.; compgen -v $1_; echo $1; }
macro () { [ -v BASH_ALIASES[${1/#$2.}] ] && alias ${1/#$2.}; }
use () { echo shopt -s expand_aliases; until [[ $# -eq 0 || ${1:?} == -- ]]; do srcs ${1:?} | while read; do src $REPLY; macro $REPLY $1; done; shift; done; echo "${@:2}"; }
safe () { echo set -euo pipefail; "$@"; }
```

## Syntactic sugar

```bash
as () { user=${1:?} eval "${@:2}"; }
on () { eval "${@:2}" | ssh -A ${user:+${user}@}${1:?}.admin2 bash; }
```

## Std lib

```bash
short std fail assert self a2v cnt; meta cnt

fail () { unset -v fail; : "${fail:?${FUNCNAME[1]} $@}"; }
assert () { $@ || fail "${FUNCNAME[1]} $@"; }
self () { ${FUNCNAME[1]}.${1:?} "${@:2}"; }
a2v () { local -n a=$1; assert test ${#a[@]} -gt 0; for i in ${!a[@]}; do declare -g $i="${a[$i]}"; done; "${@:2}"; }

cnt () { "$@" | wc -l; }
```

## FileTree lib

```bash
short ft files dirs list unit du-sum info; declare -A ft=(); ft () { self "$@"; }

ft.find () { assert test -d ${1:?}/; find $1 "${@:2}"; }

files () { ft find $1 -type f "${@:2}"; }
dirs () { ft find $1 -type d "${@:2}"; }

list () { files "$@" -print0 | xargs -0r ls -lsht; }
unit () { unit=${1:?}; "${@:2}"; }
ft.du () { files "$@" -print0 | xargs -0r du -c -B${unit:-K}; }

ft[du-sum-jq]='[inputs] | map(split("\t")[0] | tonumber) | add / 1024 | floor | "\(.)G"'
du-sum () { unit=1M; ft.du "$@" | grep total | jq -nRr "${ft[du-sum-jq]}"; }

ft[info-jq]='[inputs] as [ $host, $files, $dirs, $sizeM, $path ] | { $host, $files, $dirs, $sizeM, $path }'
ft.info () { { hostname; ft.find $1/ -type f | wc -l; ft.find $1/ -type d | wc -l; du -sm $1/ | fmt -1; } | jq -nR "${ft[info-jq]}"; }
```

## Anses

```bash
short anses fetch dry

dry () { dry=-n; fetch; }
fetch () { a2v anses; rsync -av ${dry:-} $from.admin2:$src/$dir/ $dst/$dir/; }
```

# Data

```bash
declare -A anses=()
anses+=(from profnt1 to profntphp7a1 dir code/enquetes/58630230/files_216627224)
anses+=(src /space/www/apps/ANSES)
anses+=(dst /space/www/apps/anses)

a2v anses
```

# Play

## Load libs and data

```bash
exec bash

code () { sed -n $'/^```/d\n/^# Libs/,/# Data/p' ${1:?}; }
data () { sed -n $'/^```/d\n/^# Data/,/# Play/p' ${1:?}; }

journal=~/journal/2021-11-18_TDE_migrate-anses-files-from-proftn1-to-profntphp7a1.md

source <(code $journal)
source <(data $journal)
```

## Lines

```bash
on $from safe use std ft -- cnt files $src/$dir
on $to safe use std ft -- cnt files $dst/$dir

on $from safe use std ft -- files $src/$dir
on $to safe use std ft -- files $dst/$dir

on $from safe use std ft -- info $src/$dir
on $to safe use std ft -- info $dst/$dir

on $from safe use std ft anses -- du-sum $src/$dir
on $to safe use std ft anses -- du-sum $dst/$dir

on $from safe use std ft -- info $src/$dir
on $to safe use std ft -- info $dst/$dir

on $from safe use std ft anses -- cnt files $src/$dir
on $to safe use std ft anses -- cnt files $dst/$dir

on $from safe use std ft anses -- cnt files $src -mtime -356
on $from safe use std ft anses -- cnt files $src -mtime +356

on $to safe use std ft anses -- cnt files $dst -mtime -356
on $to safe use std ft anses -- cnt files $dst -mtime +356

as root on $to safe use std ft anses -- dry fetch
as root on $to safe use std ft anses -- fetch
```

## Sessions
