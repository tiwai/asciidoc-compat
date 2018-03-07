#!/bin/bash
#
# Ugly hacked bash script to be compatible with a2x
#
# SPDX-License-Identifier: GPL-2.0+
#

version="8.6.10"

OPTS=$(getopt -o "a:b:D:d:f:hLr:m:vk" --long "attribute:,backend:,asciidoc-opts:,conf-file:,destination-dir:,doctype:,format:,help,no-xmllint,resource:,resource-manifest:,verbose,version,xsltproc-opts:,xsl-file:,fop,fop-opts:,dblatex-opts:,keep-artifacts" -n "a2x" -- "$@") || exit 1
eval set -- "$OPTS"

backend=""
format=""
asciidoc_opts=()
# let's be lazy
xmlto_opts=("--skip-validation")
use_fop=""
dest_dir=""
remove_xml=1

usage () {
    echo "usage: a2x [options] FILE"
    echo "  This is a wrapper script to process via asciidoctor and xmlto"
    echo "  Many options are simply ignored"
    exit 1
}

while true; do
    case "$1" in
	-a|--attribute)
	    asciidoc_opts+=("$1" "$2")
	    shift 2;;
	--asciidoc-opts)
	    asciidoc_opts+=("$2")
	    shift 2;;
	-b|--backend)
	    backend="$2"
	    shift 2;;
	-D|--destination-dir)
	    dest_dir="$2"
	    shift 2;;
	-d|--doctype)
	    doctype="$2"
	    shift 2;;
	-f|--format)
	    format="$2"
	    shift 2;;
	-v|--verbose)
	    xmlto_opts+=("-v")
	    shift;;
	--fop)
	    xmlto_opts+=("--with-fop")
	    shift;;
	--fop-opts)
	    shift 2;;
	--xsl-file)
	    shift 2;;
	--xsltproc-opts)
	    xmlto_opts+=("--xsltopts" "$2")
	    shift 2;;
	--dblatex-opts)
	    shift 2;;
	--safe)
	    shift;;
	-k|--keep-artifacts)
	    remove_xml=
	    shift;;
	-s|--skip-asciidoc)
	    shift;;
	-r|--resource-dir)
	    shift 2;;
	-m|--resource-manifest)
	    shift 2;;
	-L|--no-xmllint)
	    shift;;
	-h|--help)
	    usage;;
	--version)
	    echo "a2x $version"
	    exit 0;;
	--)
	    shift
	    break;;
	*)
	    break;;
    esac
done

if [ -z "$format" ]; then
    echo "a2x: no format is specified"
    exit 1
fi

case "$format" in
    manpage|pdf|xhtml|chunked|dvi|ps|docbook)
	;;
    *)
	echo "a2x: Unsupported format: $format"
	exit 1;;
esac

test -z "$backend" && backend="$format"

asciidoc_file="$1"
if [ ! -f "$asciidoc_file" ]; then
    echo "a2x: cannot find source: $asciidoc_file"
    exit 1
fi

if [ -z "$dest_dir" ]; then
    dest_dir=$(dirname "$asciidoc_file")
fi

basefile=$(basename $asciidoc_file)
basefile=${basefile%.*}
docbook_file="$dest_dir/$basefile.xml"

case "$format" in
    chunked)
	dir="${docbook_file%.xml}".chunked
	xmlto_opts+=("-o" "$dir")
	;;
    *)
	xmlto_opts+=("-o" "$dest_dir")
	;;
esac

to_docbook () {
    asciidoc --backend docbook45 -a "a2x-format=$format" \
		"$@" "${asciidoc_opts[@]}" \
		--out-file "$docbook_file" "$asciidoc_file"
}

to_xhtml () {
    to_docbook
    xmlto "${xmlto_opts[@]}" xhtml-nochunks "$docbook_file"
}

to_chunked () {
    to_docbook
    xmlto "${xmlto_opts[@]}" xhtml "$docbook_file"
}

to_manpage () {
    to_docbook -d manpage
    xmlto "${xmlto_opts[@]}" man "$docbook_file"
}

to_pdf () {
    to_docbook
    xmlto "${xmlto_opts[@]}" pdf "$docbook_file"
}

to_dvi () {
    to_docbook
    xmlto "${xmlto_opts[@]}" dvi "$docbook_file"
}

to_ps () {
    to_docbook
    xmlto "${xmlto_opts[@]}" ps "$docbook_file"
}

eval to_$backend
rc=$?

test -n "$remove_xml" -a "$backend" != "docbook" && rm -f "$docbook_file"

exit $rc
