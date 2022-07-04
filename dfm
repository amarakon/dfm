#!/bin/sh

main() {
    parse_opts "$@"
    
    if [ -n "$help" ]; then
	help ; exit 0
    fi

    : "${config_dir:=${XDG_CONFIG_HOME:-$HOME/.config}/dfm}"
    : "${config_file:=$config_dir/dfm.conf}"
    [ -f "$config_file" ] && . "$config_file"

    [ -n "$length_option" ] && length=$length_arguments
    [ -z  $length ] && length=10

    if [ "$case_sensitivity" = "sensitive" ]; then
	menu="dmenu -l $length"
	newt() { newt="`printf "$target" | sed 's|\(.*/'$sel'[^/]*\).*|\1|'`"; }
    else
	menu="dmenu -i -l $length"
	newt() { newt="`printf "$target" | perl -pe 's|(.*/'$sel'[^/]*).*|$1|i'`"; }
    fi

    [ -z $default_mode ] && default_mode=program
    default_mode=`printf $default_mode | tr - _`

    { [ -n "$raw" ] && prompt_raw "$@"; } ||
    { [ -n "$copy" ] && prompt_copy "$@"; } ||
    { [ -n "$copy_contents" ] && prompt_copy_contents "$@"; } ||
    { prompt_$default_mode "$@"; } 
}

tilde() { printf "$sel" | sed 's@^~@/home/'"$USER"'@'; }
check() { file -E "$@" | grep "(No such file or directory)$"; }
quotes() { printf "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/"; }

prompt_base() {
    target="$PWD"

    while true; do
	prompt="$p"
	[ -z "$prompt" ] && prompt="`printf "$target" | sed 's@^/home/'"$USER"'@~@'`"
	sel="$(echo "$(ls "$target"; ls -A "$target" | grep '^\.' )" | $menu -p "$prompt")"
	ec=$?
	[ "$ec" -ne 0 ] && exit $ec

	c="`echo "$sel" | cut -b1`"
	if [ `echo "$sel" | grep -v "*" | wc -l` -eq 1 -a ! -e "`tilde`" -a ! -e "$target/$sel" ]; then
	    newt
	elif [ "$c" = "/" ]; then
	    newt="$sel"
	elif [ "$c" = "~" ]; then
	    newt="`tilde`"
	elif [ "$c" = "." -o `echo "$sel" | wc -l` -eq 1 ]; then
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
	quotes |\
	if [ -x "`command -v sesame`" ]; then
	    xargs sesame
	else
	    xargs gtk-launch $(xdg-mime query default $(grep /${target##*.}= /usr/share/applications/mimeinfo.cache |\
	    cut -d '/' -f 1)/${target##*.})
	fi
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
                    │
 -s|--sensitive     │ Use case-sensitive matching
 -i|--insensitive   │ Use case-insensitive matching
 -l|--length        │ Specify the length of dmenu
                    │
 -h|--help          │ Print this help message and exit

By default, the target and prompt will be the working directory, and the insensitive and program options will be used.
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
	    -s|--sensitive)
		case_sensitivity="sensitive"
		shift
		;;
	    -i|--insensitive)
		case_sensitivity="insensitive"
		shift
		;;
	    -l|--length)
		length_option=1
		shift
		length_arguments=$1
		;;
	    *)
		[ -d "$1" ] && PWD="`realpath -s "$1"`"
		shift
		[ $# -gt 0 ] && p="$1"
		;;
	esac

    done
}

main "$@"
