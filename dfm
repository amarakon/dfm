#!/bin/sh
# TODO: multisel

main() {
    parse_opts "$@"
    
    { [ -n "$help" ] && help; } ||
    { [ -n "$raw" ] && prompt_raw "$@"; } ||
    { [ -n "$copy" ] && prompt_copy "$@"; } ||
    { [ -n "$copy_file" ] && prompt_copy_file "$@"; } ||
    { [ -n "$program" ] && prompt_program "$@"; } ||
    { prompt_program "$@"; } 
}

prompt_prep() {
    target="$2"
    [ -z "$target" ] && target="$(pwd)"
    prompt="$3"
}

prompt_base() {
    p="$prompt"
    [ -z "$p" ] && p="$(printf "$target" | sed 's|^/home/[^/]*|~|')"
    sel="$(printf "$(ls "$target"; ls -A "$target" | grep '^\.' )" | dmenu -p "$p" -i -l 10)"
    ec=$?
    [ "$ec" -ne 0 ] && exit $ec

    c="$(echo "$sel" | cut -b1)"
    if [ "$c" = "/" ]; then
	newt="$sel"
    else
	newt="$(realpath -s "${target}/${sel}")"
    fi
}

prompt_raw() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" ]; then
	    target="$newt"
	if [ ! -d "$target" ]; then
	    echo "$target"			
	    exit 0
	fi
	fi
done
}

prompt_copy() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" ]; then
	    target="$newt"

	    if [ ! -d "$target" ]; then		
		data2="$(file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2)"
		data3="$(file -b "$target" | cut -d ',' -f2 | cut -d ' ' -f3)"

		{ [ "$data2" = "image" ] && program="xclip -i -selection clipboard -t image/png"; } ||
		{ program="xclip -r -i -selection clipboard"; }

		{ [ -n "${program+1}" ] && $program "$target"; } ||
		{ echo "Failed to recognize file format"; }
		exit 0
		fi
	fi
done
}

prompt_copy_file() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" ]; then
	    target="$newt"

	    if [ ! -d "$target" ]; then		
		cat "$target" | dmenu -i -l 10 | xclip -r -i -selection clipboard
		exit 0
		fi
	fi
done
}

prompt_program() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" ]; then
	    target="$newt"

	    if [ ! -d "$target" ]; then		
		xdg-open "$target"
		exit 0
		fi
	fi
done
}

help() {
    printf "Usage:	dbrowse [options] [target] [prompt]

Options:
 -r|--raw       │ Get the raw output of the selection
 -c|--copy      │ Copy the contents of the selection
-cf|--copy-file │ Copy a line from the contents of the selection
 -p|--program   │ Open the appropriate program for the selection
 -h|--help	│ Print this help message and exit

When no arguments are supplied, the target and prompt will be the working directory, and the program option will be used.
\n"
}

parse_opts() {
    while [ $# -gt 0 ]; do
        key="$1"
        
	case $key in
	-h|--help)
	    help=1
	    shift
	    ;;
	-r|--raw)
	    raw=1
	    shift
	    ;;
	-c|--copy)
	    copy=1
	    shift
	    ;;
	-cf|--copy-file)
	    copy_file=1
	    shift
	    ;;
	-p|--program)
	    program=1
	    shift
	    ;;
	*)
	    shift
	    ;;
	esac

    done
}

main "$@"
