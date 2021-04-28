#!/bin/bash

source <(bfh boot)
self=$(basename "${BASH_SOURCE[0]}" .sh)

no-ipv6-for-ufw () { local f=/etc/default/ufw; grep -q ^IPV6=no $f || echo -e '/^IPV6=yes/t//\n.,.s/yes/no/\nwq' | sudo ed $f; }

real-file-name () { [[ -L ${1:?} ]] && { readlink $1; return; } || [[ -f $1 ]] && echo $1 || fail $1 neither a symlink nor a file; }
$import real-file-name fail

rg () { : ${1:?}; local c=96; echo $1 | grep -E "^[[:digit:]]+$" && { c=$1; shift; }; command rg -L --no-messages "$@" | cut -c-$c; }

ssh-forget-ip () { (cd; ssh-keygen -f .ssh/known_hosts -R ${1:?}); }
ssh-learn-ip () { (cd; ssh-keyscan -H $1 | tee -a .ssh/known_hosts); }
an-ip-changed () { ssh-forget-ip $1; ssh-learn-ip ${1:?}; }
put group ssh-ip an-ip-changed ssh-forget-ip ssh-learn-ip
$import $(put group ssh-ip)

apt-search () { declare -A a=([full]= [short]='-F %p'); aptitude ${a[${show:-short}]} search "$@"; }
apt-alien () { apt-search '~i(!~ODebian)'; }
$import apt-alien apt-search
$help apt-alien 'Show installed package not from Debian'
apt-held () { apt-search "~ahold"; }
$import apt-held apt-search
$help apt-held 'Show package on hold'
put group apt apt-alien apt-held

$import $self no-ipv6-for-ufw real-file-name rg $(put group apt) $(put group ssh-ip)

main "$@"
self
arrays
show-array group
