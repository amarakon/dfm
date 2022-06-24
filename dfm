#!/bin/sh

main() {
    parse_opts "$@"
    
    { [ -n "$help" ] && help; } ||
    { [ -n "$raw" ] && prompt_raw "$@"; } ||
    { [ -n "$copy" ] && prompt_copy "$@"; } ||
    { [ -n "$copy_contents" ] && prompt_copy_contents "$@"; } ||
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
    sel="$(echo "$(ls "$target"; ls -A "$target" | grep '^\.' )" | dmenu -p "$p" -i -l 10)"
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

	if [ -e "$newt" -o $(echo "$sel" | wc -l) -gt 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		    echo "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@'
		    exit 0
	    else
		PWD="$target"
	    fi
	fi
done
}

prompt_copy() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" -o $(echo "$sel" | wc -l) -gt 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		printf "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | tr '\n' ' ' | xclip -r -i -selection clipboard
		exit 0
	    else
		PWD="$target"
	    fi
	fi
done
}

prompt_copy_contents() {
    prompt_prep "$@"
    while true; do
	prompt_base "$@"

	if [ -e "$newt" -o $(echo "$sel" | wc -l) -gt 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		data2="$(file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2)"
		{ [ "$data2" = "image" ] && program="xclip -i -selection clipboard -t image/png"; } ||
		{ program="xclip -r -i -selection clipboard"; }
		if [ $(echo "$sel" | wc -l) -gt 1 ]; then
		    printf "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | xargs $program
		    exit 0
		else
		    $program "$target"
		    exit 0
		fi
	    else
		PWD="$target"
	    fi
	fi
done
}

prompt_program() {
    prompt_prep "$@"

    while true; do
	prompt_base "$@"

	if [ -e "$newt" -o $(echo "$sel" | wc -l) -gt 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		if [ $(echo "$sel" | wc -l) -gt 1 ]; then
		    printf "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | xargs gtk-launch $(xdg-mime query default $(grep /${target##*.}= /usr/share/applications/mimeinfo.cache | cut -d '/' -f 1)/${target##*.})
		    exit 0
		else
		    xdg-open "$target"
		    exit 0
		fi
	    else
		PWD="$target"
	    fi
	fi
    done
}

help() {
    printf "Usage:	dbrowse [options] [target] [prompt]

Options:
 -r|--raw           │ Print the raw output of the selection
 -c|--copy          │ Copy the raw output of the selection
-cc|--copy-contents │ Copy the contents of the selection
 -p|--program       │ Open the appropriate program for the selection
 -h|--help	    │ Print this help message and exit

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
	-cc|--copy-contents)
	    copy_contents=1
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
