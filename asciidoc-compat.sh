#!/bin/bash
#
# Ugly hacked bash script to be compatible with asciidoc
#
# SPDX-License-Identifier: GPL-2.0+
#

version=8.6.10

OPTS=$(getopt -o "a:b:f:d:cheso:nv" --long "attribute:,backend:,conf-file:,doctest,doctype:,dump-conf,filter:,help,no-conf,no-header-footer,out-file:,section-numbers,safe,unsafe,theme:,verbose,version" -n "asciidoc" -- "$@") || exit 1
eval set -- "$OPTS"

args=()

usage () {
    echo "Usage: asciidoc [options] FILE"
    echo "  This is a wrapper script to process via asciidoctor"
    echo "  Many opetions are simply ignored"
    exit 1
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
	-a|--attribute|\
	    -d|--doctype|\
	    -o|--out-file)
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
		    echo "asciidoc-compat: Unsupported backend: $backend"
		    exit 1;;
	    esac
	    args+=("$1" "$backend")
	    shift 2;;
	# one argument to drop
	--doctest|\
	    -c|--dump-coef|\
	    -e|--no-conf)
	    shift;;
	# two arguments to drop
	-f|--conf-file|\
	    --theme|\
	    --filter)
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

exec asciidoctor "${args[@]}" "$@"
