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

prompt_base() {
    target="$2"
    [ -z "$target" ] && target="`pwd`"
    prompt="$3"
    [ -z "$prompt" ] && prompt="`printf "$target" | sed 's|^/home/[^/]*|~|'`"

    while true; do
	sel="$(echo "$(ls "$target"; ls -A "$target" | grep '^\.' )" | dmenu -p "$prompt" -i -l 10)"
	ec=$?
	[ "$ec" -ne 0 ] && exit $ec

	c="`echo "$sel" | cut -b1`"
	if [ "$c" = "/" ]; then
	    newt="$sel"
	else
	    newt="`realpath -s "${target}/${sel}"`"
	fi

	if [ `ls | wc -l` -ge 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		if [ "`file -b "$target" |\
		    rev | awk '{print $1,$2,$3,$4,$5}' | rev`" = "(No such file or directory)"\
		    -a `echo "$target" | grep "*" | wc -l` -ge 1 ]
		then
		    target=`ls $target`
		    cmd ; exit 0
		else
		    cmd ; exit 0
		fi
	    else
		PWD="$target"
	    fi
	fi

    done
}

prompt_raw() {
    cmd () { echo "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@'; }
    prompt_base
}

prompt_copy() {
    cmd() {
	printf "$target" |\
	sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | tr '\n' ' ' |\
	xclip -r -i -selection clipboard
    }
    prompt_base
}

prompt_copy_contents() {
    cmd() {
	if [ "`file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2`" = "image" ]; then
	    program="xclip -i -selection clipboard -t image/png"
	else
	    program="xclip -r -i -selection clipboard"
	fi
	printf "$target" | sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | xargs $program
    }   
    prompt_base
}

prompt_program() {
    cmd() {
	printf "$target" |\
	sed 's@^'"$PWD"/'@@' | sed 's@^@'"$PWD"/'@' | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" |\
	xargs gtk-launch $(xdg-mime query default $(grep /${target##*.}= /usr/share/applications/mimeinfo.cache |\
	cut -d '/' -f 1)/${target##*.})
    }
    prompt_base
}

help() {
    echo "Usage:	dbrowse [options] [target] [prompt]

Options:
 -r|--raw           │ Print the raw output of the selection
 -c|--copy          │ Copy the raw output of the selection
-cc|--copy-contents │ Copy the contents of the selection
 -p|--program       │ Open the appropriate program for the selection
 -h|--help          │ Print this help message and exit

When no arguments are supplied, the target and prompt will be the working directory, and the program option will be used."
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
