#!/bin/bash

source <(bfh boot)
self=$(basename "${BASH_SOURCE[0]}" .sh)

no-ipv6-for-ufw () { local f=/etc/default/ufw; grep -q ^IPV6=no $f || echo -e '/^IPV6=yes/t//\n.,.s/yes/no/\nwq' | sudo ed $f; }

real-file-name () { [[ -L ${1:?} ]] && { readlink $1; return; } || [[ -f $1 ]] && echo $1 || fail $1 neither a symlink nor a file; }
$import real-file-name fail

$import $self no-ipv6-for-ufw real-file-name

main "$@"
self
