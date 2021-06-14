#!/bin/bash

source <(bfh core4)

shopt -s expand_aliases

gh.logout () { echo | gh auth logout --hostname github.com; }

gh.thydel () { pass github/tokens/thydel/gh | gh auth login -h github.com --with-token; gh auth status; }

gh.thyepi () { pass github/tokens/thyepi/gh | gh auth login -h github.com --with-token; gh auth status; }

gh.create () {
    local u=thydel r=${1:?} t=template-minimal d="${2:?}"
    (cd ~/tmp; gh repo create $u/$r --public -y -p $u/$t)
    gh api /repos/$u/$r --raw-field description="$d"
}    

gh.create-private () {
    local g=Epiconcept-Paris r=${1:?} t=thy-template d="${2:?}"
    (cd ~/tmp; gh repo create $g/$r --private -y -p $g/$t)
    gh api /repos/$g/$r --raw-field description="$d"
}

main "$@"
use gh.logout gh.thydel gh.thyepi gh.create gh.create-private
