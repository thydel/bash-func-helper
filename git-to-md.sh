#!/bin/bash

source <(bfh boot)
self=$(basename "${BASH_SOURCE[0]}" .sh)

jq-md-url () { jq --argjson s '"\n    "' -r "$1"; }

git-url () { git config --get remote.origin.url; }
git-repo () { git-url | jq -Rr 'split(":")[1]|split(".")[:-1][]'; }
git-repo () { git-url | jq -Rr 'split(":")[1]'; } # WTF
$import git-repo git-url

git-site () { git-url | jq -Rr 'split(":")[0]|split("@")[1]'; }
$import git-site git-url

git-repo-to-url () { echo https://$(git-site)/$(git-repo); }
$import git-repo-to-url git-site git-repo

git-repo-to-md () { git-repo-to-url | git-url-to-md; }
$import git-repo-to-md git-repo-to-url git-url-to-md
alias gr2md=git-repo-to-md

git-branch-or-tag () { if [ "$1" ]; then git tag | grep $1 || fail no $1 tag; else git branch --show-current; fi; }
$import git-branch-or-tag fail
git-file-to-url() { xargs -ri echo https://$(git-site)/$(git-repo)/blob/$(git-branch-or-tag "$@")/{}; }
$import git-file-to-url git-site git-repo git-branch-or-tag

git-url-to-md () { jq -R | jq-md-url 'split("/")[-1] as $p | "[\($p)]:\($s)\(.)\($s)\"github.com file\"\n"'; }
$import git-url-to-md jq-md-url

git-file-to-md () { check-tty; git-file-to-url "$@" | git-url-to-md; }
$import git-file-to-md check-tty git-file-to-url git-url-to-md
alias gf2md=git-file-to-md

git-repo-to-js () { git-repo-to-url | jq -R '{ url: .}'; }
$import git-repo-to-js git-repo-to-url
#git-commit-to-js () { git log -${1:-1} --pretty='{ "comment": "%s", "commit": "%H" }'; }
git-commit-to-js () { git log -${1:-1} --pretty='{ _XXX_comment_XXX_: _XXX_%s_XXX_, _XXX_commit_XXX_: _XXX_%H_XXX_ }' | sed -e 's/"/\\"/g' -e 's/_XXX_/"/g'; }
git-repo-and-commit-to-js () { (git-repo-to-js; git-commit-to-js "$@") | jq -n 'input as $r | [inputs] | map([$r, .] | add)[]'; }
$import git-repo-and-commit-to-js git-repo-to-js git-commit-to-js

git_commit_to_md='"[\(.comment)]:\($s)\(.url)/commit/\(.commit)\($s)\"github.com commit\"\n"'
git-commit-to-md () { git-repo-and-commit-to-js "$@" | jq-md-url "$git_commit_to_md"; }
load add-vars git-commit-to-md git_commit_to_md
$import git-commit-to-md git-repo-and-commit-to-js jq-md-url
alias gc2md=git-commit-to-md

relative-file-to-js () { jq -R '{ url: ., name: split(".")[0] | split("_")[2] }'; }
relative-file-to-md () { check-tty; relative-file-to-js | jq-md-url '"[\(.name)]:\($s)\(.url)\($s)\"github.com relative file\"\n"'; }
$import relative-file-to-md check-tty relative-file-to-js jq-md-url
alias grf2md=relative-file-to-md

$import $self git-repo-to-md git-file-to-md git-commit-to-md relative-file-to-md

main "$@"
self
alias
