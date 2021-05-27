#!/bin/bash

source <(bfh core3)

shopt -s expand_aliases
self=$(basename "${BASH_SOURCE[0]}" .sh)

top+=(pdf.encrypted)
pdf.encrypted () { qpdf --is-encrypted "$1" && echo "$1"; }

top+=(pdf.fix-some)
pdf.fix-some () {
    : ${2:?}
    pdf.encrypted "$2" || return 1
    # make uncrypted QDF from crypted PDF
    qpdf --decrypt --no-original-object-ids --qdf "$2" ~/tmp/decrypt.qdf
    # make JSON objects infos from QDF
    qpdf --json ~/tmp/decrypt.qdf | jq > ~/tmp/decrypt.json
    # SED to replace REF to unwanted objects to REF to unexistant object
    local sed="'"; sed+='s/ \(.)$/ 0 0 R/'; sed+="'"
    # JQ to extract REF of object containing STRING and generate SED to edit REF
    local jq='[path(.. | select(type == "string" and test($match; "i"))) | .[1]] | map("-e '"$sed"'") | join(" ")'
    # strip uncrypted QDF from object containing STRING
    eval sed -r $(jq -r --arg match "$1" "$jq" ~/tmp/decrypt.json) ~/tmp/decrypt.qdf > ~/tmp/stripped.qdf
    # fix QDF after edition
    fix-qdf ~/tmp/stripped.qdf > ~/tmp/fixed.qdf
    # make a PDF from stripped QDF removing unreferenced unwanted objects
    qpdf ~/tmp/fixed.qdf $(basename "$2" .pdf)-fixed.pdf
    touch -r $(basename "$2" .pdf)-fixed.pdf ~/tmp/fixed.qdf
}
name pdf.fix-some pdf.encrypted

top+=(pdfs.fix-some)
pdfs.fix-some () { : ${1:?}; list.map pdf.encrypted | list.map pdf.fix-some "$1"; }
name pdfs.fix-some list.map pdf.encrypted pdf.fix-some

eval "$self () { echo ${top[@]}; }"
name $self pdfs.fix-some

main "$@"
use $self
