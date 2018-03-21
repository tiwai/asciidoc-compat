#!/bin/bash
#
# Ugly hacked bash script to be compatible with asciidoc
#
# SPDX-License-Identifier: GPL-2.0+
#

version=8.6.10

OPTS=$(getopt -o "a:b:f:d:cheso:nv" --long "attribute:,backend:,conf-file:,doctest,doctype:,dump-conf,filter:,help,no-conf,no-header-footer,out-file:,section-numbers,safe,unsafe,theme:,verbose,version" -n "asciidoc" -- "$@") || exit 1
eval set -- "$OPTS"

doctype=""
backend=""
outfile=""
args=("-acompat-mode")

usage () {
    echo "Usage: asciidoc [options] FILE"
    echo "  This is a wrapper script to process via asciidoctor"
    echo "  Many opetions are simply ignored"
    exit 1
}

fixup_manpage () {
    test x"$1" = x"-" && return
    if ! grep -q '<refmiscinfo class="source">' "$1"; then
	sed -i -e's@</refmeta>@<refmiscinfo class="source">\&\#160\;</refmiscinfo>\n</refmeta>@' "$1"
    fi
    if ! grep -q '<refmiscinfo class="manual">' "$1"; then
	sed -i -e's@</refmeta>@<refmiscinfo class="manual">\&\#160\;</refmiscinfo>\n</refmeta>@' "$1"
    fi
}

while true; do
    case "$1" in
	# one argument
	-s|--no-header-footer|\
            -n|--section-numbers|\
	    --safe|\
	    -v|--verbose)
	    args+=("$1")
	    shift;;
	--unsafe)
	    args+=("-S" "unsafe")
	    shift;;
	# two arguments
	-a|--attribute)
	    args+=("$1" "$2")
	    shift 2;;
	-o|--out-file)
	    outfile="$2"
	    args+=("$1" "$2")
	    shift 2;;
	-d|--doctype)
	    doctype="$2"
	    args+=("$1" "$2")
	    shift 2;;
	-b|--backend)
	    backend="$2"
	    case "$backend" in
		xhtml*)
		    backend="xhtml5";;
		html*)
		    backend="html5";;
		docbook5|docbook45)
		    ;;
		docbook*)
		    backend="docbook45";;
		*)
		    echo "error: asciidoc-compat: Unsupported backend: $backend"
		    exit 1;;
	    esac
	    args+=("$1" "$backend")
	    shift 2;;
	# one argument to drop
	--doctest|\
	    -c|--dump-coef|\
	    -e|--no-conf)
	    echo "warning: asciidoc-compat: ignoring $1"
	    shift;;
	# two arguments to drop
	-f|--conf-file|\
	    --theme|\
	    --filter)
	    echo "warning: asciidoc-compat: ignoring $1 $2"
	    shift 2;;
	-h|--help)
	    usage "$1";;
	--version)
	    echo "asciidoc $version"
	    exit 0;;
	--)
	    shift
	    break;;
	-)
	    break;;
	-*)
	    usage;;
	*)
	    break;;
    esac
done

asciidoctor "${args[@]}" "$@" || exit $?

# fix up manpage
case "$backend" in
    docbook*)
    ;;
    *)
	exit 0;;
esac

if [ "$doctype" = "manpage" ]; then
    if [ -n "$outfile" ]; then
	fixup_manpage "$outfile"
    else
	for i in "$@"; do
	    f="${i%.*}.xml"
	    test -f "$f" && fixup_manpage "$f"
	done
    fi
fi

exit 0
