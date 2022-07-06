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

    if [ "$path" = "full" ]; then
	prompt() { prompt="`printf "$target"`"; }
    else
	prompt() { prompt="`printf "$target" | sed 's@^/home/'"$USER"'@~@'`"; }
    fi

    [ -z $mode ] && mode=open

    { [ -n "$copy" -o $mode = copy ] && [ -n "$cat" ] && prompt_copy_contents "$@"; } ||
    { [ -n "$open" ] && prompt_open "$@"; } ||
    { [ -n "$cat" ] && prompt_print_contents "$@"; } ||
    { [ -n "$print" ] && prompt_print "$@"; } ||
    { [ -n "$copy" ] && prompt_copy "$@"; } ||
    { prompt_$mode "$@"; } 
}

tilde() { printf "$sel" | sed 's@^~@/home/'"$USER"'@'; }
check() { file -E "$@" | grep "(No such file or directory)$"; }
quotes() { printf "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/"; }

prompt_base() {
    [ $# -eq 1 ] && eval last=\${$#}
    [ $# -ge 2 ] && eval second_last=\${$(($#-1))}

    { [ $# -gt 0 ] && [ -d "$last" ] && PWD="`realpath -s "$last"`"; } ||
    { [ $# -gt 1 ] && [ -d "$second_last" ] && PWD="`realpath -s "$second_last"`" && p="$last"; }

    target="$PWD"

    while true; do
	prompt="$p"
	[ -z "$prompt" ] && prompt
	sel="$(printf "$(ls "$target"; ls -A "$target" | grep '^\.' )" | $menu -p "$prompt")"
	ec=$?
	[ "$ec" -ne 0 ] && exit $ec

	c="`printf "$sel" | cut -b1`"
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

prompt_print() {
    cmd () { quotes | xargs ls -d; }
    prompt_base "$@"
}

prompt_print_contents() {
    cmd() { quotes | xargs cat; }
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

prompt_open() {
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
    printf "Usage:	`basename $0` [options] [target] [prompt]

Options:
  Modes:             │
  -p|--print         │ Print the output of the selection
  -c|--copy          │ Copy the output of the selection
  -o|--open          │ Open the appropriate program for the selection (default)
                     │
    --cat            │ Concatenate the selections before using a mode
                     │
 -s|--sensitive      │ Use case-sensitive matching
 -i|--insensitive    │ Use case-insensitive matching (default)
 -l|--length         │ Specify the length of dmenu (default: 10)
                     │
 -f|--full           │ Use the full path for the prompt
 -a|--abbreviated    │ Use the abbreviated path for the prompt (default)
                     │
 -h|--help           │ Print this help message and exit

By default, the target and prompt will be the working directory.
"
}

parse_opts() {
    die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
    needs_arg() { [ -z "$OPTARG" ] && die "No arg for --$OPT option"; }

    while getopts hpcosil:fa-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
	    OPT="${OPTARG%%=*}"       # extract long option name
	    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
	    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
	    h | help)     	help=1 ;;
	    p | print)      	print=1 ;;
	    c | copy)     	copy=1 ;;
	    cat)		cat=1 ;;
	    o | open)		open=1 ;;
	    s | sensitive)	case_sensitivity="sensitive" ;;
	    i | insensitive)	case_sensitivity="insensitive" ;;
	    l | length)		needs_arg ; length_option=1 length_arguments=$OPTARG ;;
	    f | full)		path="full" ;;
	    a | abbreviated)	path="abbreviated" ;;
	    ??*)          	die "Illegal option --$OPT" ;;  # bad long option
	    ?)            	exit 2 ;;  # bad short option (error reported via getopts)
	esac
    done
    shift $((OPTIND-1)) # remove parsed options and args from $@ list
}

main "$@"
