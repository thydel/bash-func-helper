#!/bin/bash

source <(bfh boot2)
self=$(basename "${BASH_SOURCE[0]}" .sh)

awk.sum () { awk '{ s += $1 } END { print s }'; }

kmgt () {
    declare -A units=([b]=0 [k]=10 [m]=20 [g]=30 [t]=40);
    declare unit=${units[${1:-k}]};
    echo "2^${unit:-$(fail $1 not in ${!units[@]})}" | bc;
}
dict set import kmgt fail

bc.kmgt () { map args echo {} / $(kmgt $1) | bc; }
dict set import bc.kmgt map args kmgt

find.size () { find -type f -name "*.${1:?}" -print0 | xargs -0 du -sb | awk.sum | bc.kmgt ${2}; }
dict set import find.size awk.sum bc.kmgt

use-greek-letters () {
    xmodmap -pke | grep dead_greek | ifne -n xmodmap -pk | grep Control_R | awk '{print $1}' |
	xargs -i echo xmodmap -e '"keycode {} = dead_greek dead_greek dead_greek dead_greek"'; }

inside-git-p () { [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == true ]]; }
init-git-store-date () {
    inside-git-p || return;
    git-store-dates hooks;
    [[ -f .saved-dates ]] || {
	git-store-dates;
	git ci -m 'Uses git-store-dates';
	git push;
    }
}
dict set import init-git-store-date inside-git-p

dict set import $self awk.sum bc.kmgt find.size use-greek-letters init-git-store-date

main "$@"
all
