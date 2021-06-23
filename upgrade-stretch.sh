#!/bin/bash

source <(bfh boot)
source <(bfh misc)
bfh misc group apt
self=$(basename "${BASH_SOURCE[0]}" .sh)

keep-apt-held () { d=/var/local/apt-hold; mkdir -p $d; aptitude search ~ahold -F %p > $d/$(date +%F); }
apt-unhold-matching () { aptitude search ~ahold -F %p | grep ^$1 | xargs aptitude unhold; }
apt-unhold () { apt-unhold-matching .; }
$import apt-unhold apt-unhold-matching
$import $self keep-apt-held apt-unhold-matching apt-unhold

apt-hide-sources-list.d () { d=/etc/apt/sources.list.d; mv $d $d.hide; }
apt-show-sources () { d=/etc/apt; grep ^deb $d/sources.list; }
apt-hide-sources-list () { f=/etc/apt/sources.list; mv $f $f.hide; }
$import $self apt-hide-sources-list.d apt-show-sources apt-hide-sources-list


s=
s+=$'deb http://deb.debian.org/debian buster main\n'
s+=$'deb-src http://deb.debian.org/debian buster main\n'
s+=$'\n'
s+=$'deb http://deb.debian.org/debian-security/ buster/updates main\n'
s+=$'deb-src http://deb.debian.org/debian-security/ buster/updates main\n'
s+=$'\n'
s+=$'deb http://deb.debian.org/debian buster-updates main\n'
s+=$'deb-src http://deb.debian.org/debian buster-updates main\n'
buster="$s"
vars=buster
apt-version-sources-list () { declare -n v="$1"; echo -n "$v" > /etc/apt/sources.list; }
version-upgrade () { DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef $1 -y; }
$import $self apt-version-sources-list version-upgrade

hiden_source=/etc/apt/sources.list.d.hide
epi_source_deb_old='deb http://files.epiconcept.fr/repositories_apt/epiconcept jessie main'
apt-find-epi-source-list () { find $hiden_source -type f | xargs grep -l "$epi_source_deb_old"; }
load add-vars apt-find-epi-source-list hiden_source epi_source_deb_old
$import $self apt-find-epi-source-list


epi_source_deb='deb https://apt.epiconcept.fr/prep/ buster main'
epi_source_file=/etc/apt/sources.list.d/epiconcept.list
apt-add-epi-source-list () { echo "$epi_source_deb" > $epi_source_file; }
load add-vars apt-add-epi-source-list epi_source_deb epi_source_file
$import $self apt-add-epi-source-list

line () { IFS= read -r; echo "$REPLY"; [[ -z "$REPLY" ]] && return 0; }

apply-deborphan () { while deborphan | line; do deborphan | xargs -r aptitude -y remove; done; }
$import apply-deborphan line
$import $self apply-deborphan

main "$@"
self
arrays
vars
