#!/bin/bash

source <(bfh core3)

shopt -s expand_aliases
self=$(basename "${BASH_SOURCE[0]}" .sh)

top+=(pdf.encrypted)
pdf.encrypted () { qpdf --is-encrypted "$1" && echo "$1"; }

read -rd '' pdf_fix_some_refs <<!
[PDF documents. Orphaned objects and references.]: https://forum.patagames.com/posts/t497-PDF-documents--Orphaned-objects-and-references
[Remove not needed objects from pdf]: https://github.com/qpdf/qpdf/issues/174
!
top+=(pdf.fix-some)
pdf.fix-some () {
    : ${2:?}
    pdf.encrypted "$2" || return 1
    # make uncrypted QDF from crypted PDF
    qpdf --decrypt --no-original-object-ids --qdf "$2" ~/tmp/decrypt.qdf
    # make JSON objects infos from QDF
    qpdf --json ~/tmp/decrypt.qdf | jq > ~/tmp/decrypt.json
    local fixed=$(basename "$2" .pdf)-fixed.pdf
    if grep -q "$1" ~/tmp/decrypt.json; then
	# SED to replace REF to unwanted objects to REF to unexistant object
	local sed="'"; sed+='s/ \(.)$/ 0 0 R/'; sed+="'"
	# JQ to extract REF of object containing STRING and generate SED to edit REF
	local jq='[path(.. | select(type == "string" and test($match; "i"))) | .[1]] | map("-e '"$sed"'") | join(" ")'
	# strip uncrypted QDF from object containing STRING
	eval sed -r $(jq -r --arg match "$1" "$jq" ~/tmp/decrypt.json) ~/tmp/decrypt.qdf > ~/tmp/stripped.qdf
	# fix QDF after edition
	fix-qdf ~/tmp/stripped.qdf > ~/tmp/fixed.qdf
	# make a PDF from stripped QDF removing unreferenced unwanted objects
	qpdf ~/tmp/fixed.qdf $fixed; touch -r $2 $fixed
    else
	mv ~/tmp/decrypt.qdf $fixed; touch -r $2 $fixed
    fi
}
name pdf.fix-some pdf.encrypted

top+=(pdfs.fix-some)
pdfs.fix-some () { : ${1:?}; list.map pdf.encrypted | list.map pdf.fix-some "$1"; }
name pdfs.fix-some list.map pdf.encrypted pdf.fix-some

eval "$self () { echo ${top[@]}; }"
name $self pdfs.fix-some

main "$@"
use $self
