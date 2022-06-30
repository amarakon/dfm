#!/bin/sh

main() {
    parse_opts "$@"
    
    { [ -n "$help" ] && help; } ||
    { [ -n "$raw" ] && prompt_raw "$@"; } ||
    { [ -n "$copy" ] && prompt_copy "$@"; } ||
    { [ -n "$copy_contents" ] && prompt_copy_contents "$@"; } ||
    { [ -n "$program" ] && prompt_program "$@"; } ||
    { no_key=1 && prompt_program "$@"; } 
}

quotes() { printf "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/"; }
check() { file -E "$@" | grep "(No such file or directory)$"; }

prompt_base() {
    { [ -n "$no_key" ] && [ $# -ne 0 ] && PWD="`realpath -s "$1"`" && p="$2"; } ||
    { [ $# -gt 1 ] && PWD="`realpath -s "$2"`" && p="$3"; }

    target="$PWD"

    while true; do
	prompt="$p"
	[ -z "$prompt" ] && prompt="`printf "$target" | sed 's@/home/'"$USER"'@~@'`"
	sel="$(echo "$(ls "$target"; ls -A "$target" | grep '^\.' )" | dmenu -p "$prompt" -i -l 10)"
	ec=$?
	[ "$ec" -ne 0 ] && exit $ec

	c="`echo "$sel" | cut -b1`"
	if [ "$c" = "/" ]; then
	    newt="$sel"
	elif [ "$c" = "." -o "$c" ]; then
	    newt="`realpath -s "$target/$sel"`"
	else
	    newt="`printf "$target/$sel"`"
	fi

	if [ `ls | wc -l` -ge 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		if [ `check "$target" | wc -l` -eq 1 -a `echo "$target" | grep "*" | wc -l` -ge 1 ]; then
		    target=`ls -d "$PWD"/$sel`
		    cmd ; exit 0
		elif [ `echo "$target" | wc -l` -eq 1 -a `check "$target" | wc -l` -eq 1 ]; then
		    target="$PWD"
		else
		    target=`printf "$target" | head -1 && echo "$target" | tac | head -n -1 | tac | sed 's@^@'"$PWD"/'@'`
		    cmd ; exit 0
		fi
	    else
		PWD="$target"
	    fi
	fi

    done
}

prompt_raw() {
    cmd () { quotes | xargs ls -d; }
    prompt_base "$@"
}

prompt_copy() {
    cmd() {
	quotes | tr '\n' ' ' | xclip -r -i -selection clipboard
    }
    prompt_base "$@"
}

prompt_copy_contents() {
    cmd() {
	if [ "`file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2`" = "image" ]; then
	    program="xclip -i -selection clipboard -t image/png"
	else
	    program="xclip -r -i -selection clipboard"
	fi
	quotes | xargs $program
    }   
    prompt_base "$@"
}

prompt_program() {
    cmd() {
	quotes\
	| xargs gtk-launch $(xdg-mime query default $(grep /${target##*.}= /usr/share/applications/mimeinfo.cache\
	| cut -d '/' -f 1)/${target##*.})
    }
    prompt_base "$@"
}

help() {
    printf "Usage:	dbrowse [options] [target] [prompt]

Options:
 -r|--raw           │ Print the raw output of the selection
 -c|--copy          │ Copy the raw output of the selection
-cc|--copy-contents │ Copy the contents of the selection
 -p|--program       │ Open the appropriate program for the selection
 -h|--help          │ Print this help message and exit

When no arguments are supplied, the target and prompt will be the working directory, and the program option will be used.
"
}

parse_opts() {
    while [ $# -gt 0 ]; do
	case "$1" in
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
