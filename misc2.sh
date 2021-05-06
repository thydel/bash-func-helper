#!/bin/bash

source <(bfh boot2)
self=$(basename "${BASH_SOURCE[0]}" .sh)

awk.sum () { awk '{ s += $1 } END { print s }'; }

kmgt () {
    declare -A units=([b]=0 [k]=10 [m]=20 [g]=30 [t]=40);
    declare unit=${units[${1:-k}]};
    echo "2^${unit:-$(fail $1 not in ${!units[@]})}" | bc;
}

bc.kmgt () { map args echo {} / $(kmgt $1) | bc; }
dict set import bc.k map args kmgt

find.size () { find -type f -name "*.${1:?}" -print0 | xargs -0 du -sb | awk.sum | bc.kmgt ${2}; }
dict set import find.size awk.sum bc.kmgt

dict set import $self awk.sum bc.kmgt find.size

main "$@"
self
