#!/bin/bash

source <(bfh boot2)
self=$(basename "${BASH_SOURCE[0]}" .sh)

gh.release-latest () { curl --silent https://api.github.com/repos/${1:?}/releases/latest | jq; }

gh.tag-name () { gh.release-latest ${1:?} | jq -r .tag_name; }
dict set import gh.tag-name gh.release-latest

gh.download-url () {
    local arch=$(dpkg --print-architecture);
    local jq='.assets[] | select(.name | test("_linux_" + $arch + ".deb")).browser_download_url';
    gh.release-latest ${1:?} | jq -r --arg arch ${2:-$arch} "$jq";
}
import gh.download-url gh.release-latest

gh_dist=/usr/local/dist
array push vars gh_dist

gh.get-deb () { local d=${1:-$gh_dist}; [[ -w $d ]] && gh.download-url cli/cli | xargs wget -qNP $d; }

gh.install-deb () {
    local d=${1:-$gh_dist};
    gh.download-url cli/cli | xargs basename | xargs -i echo $d/{} | xargs sudo apt install;
}

import $self gh.download-url gh.tag-name gh.download-url gh.get-deb gh.install-deb

main "$@"
all
self declare
