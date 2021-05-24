#!/bin/bash

source <(bfh core2)

shopt -s expand_aliases
self=$(basename "${BASH_SOURCE[0]}" .sh)
eval "$self () { :; }"

debian-version-p () { (source /etc/os-release && ((VERSION_ID == ${1:-10}))); }

package-installed-p () { [[ $(dpkg-query -W -f '${Status}' ${1:?}) == 'install ok installed' ]]; }

install-package-if-not-installed () { package-installed-p $1 || sudo apt-get install $1; }

compile-and-install-bash-5.1 () {
    cd /usr/local/dist
    wget http://ftp.gnu.org/gnu/bash/bash-5.1.tar.gz
    cd ../src
    tar zxvf ../dist/bash-5.1.tar.gz
    cd bash-5.1
    ./configure
    make
    sudo make install
}

name $self debian-version-p package-installed-p install-package-if-not-installed compile-and-install-bash-5.1

main "$@"
use $self
