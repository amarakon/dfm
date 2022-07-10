#!/bin/sh

main() {
    : "${config_dir:=${XDG_CONFIG_HOME:-$HOME/.config}/dfm}"
    : "${config_file:=$config_dir/dfm.conf}"
    [ -f "$config_file" ] && . "$config_file"

    parse_opts "$@"
    
    [ -n "$length_option" ] && length=$length_arguments
    [ -z  $length ] && length=10

    if [ "$case_sensitivity" = "sensitive" ]; then
	menu="dmenu -l $length" greps="grep"
	replace() { sed 's|\(.*/'$sel'[^/]*\).*|\1|'; }
    else
	menu="dmenu -i -l $length" greps="grep -i"
	replace() { perl -pe 's|(.*/'$sel'[^/]*).*|$1|i'; }
    fi

    { [ "$path" = "full" ] && prompt() { p="`echo "$target"`"; }; } ||
    { prompt() { p="`echo "$target" | sed 's@^/home/'"$USER"'@~@'`"; }; }

    [ -z $mode ] && mode=open
    { [ ! -n "$no_copy" ] && [ ! -z "$copy" ] && [ -n "$cat" ] && prompt_copy_contents "$@"; } ||
    { [ -n "$open" ] && prompt_open "$@"; } ||
    { [ -n "$cat" ] && prompt_print_contents "$@"; } ||
    { [ -n "$print" ] && prompt_print "$@"; } ||
    { [ ! -n "$no_copy" ] && [ ! -z "$copy" ] && prompt_copy "$@"; } ||
    { prompt_$mode "$@"; } 
}

truepath() { sh -c "realpath -s "$sel""; }
check() { file -E "$@" | grep "(No such file or directory)$"; }
quotes() { echo "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/"; }

prompt_base() {
    while true; do
	p="$prompt"
	[ -z "$p" ] && prompt
	sel="$(echo "$(ls "$target"; ls -A "$target" | grep '^\.' )" | $menu -p "$p")"
	ec=$?
	[ "$ec" -ne 0 ] && exit $ec

	if [ `echo "$sel" | wc -l` -eq 1 ]; then
	    if [ ! -e "$target/$sel" -o "`realpath -s "$target/$sel"`" != "$target/$sel" ]; then
		if [ ! -e "`truepath`" ]; then
		    if [ $(echo "$target" | $greps "$(sh -c "echo "$sel"")" | wc -l) -eq 1 ]; then
			newt="`echo "$target" | replace`"
		    else
			newt="`realpath -s "$target/$sel"`"
		    fi
		else
		    newt="`truepath`"
		fi
	    else
		newt="`realpath -s "$target/$sel"`"
	    fi
	else
	    newt="`echo "$target/$sel"`"
	fi

	if [ `ls | wc -l` -ge 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		if [ `echo "$target" | grep "*" | wc -l` -ge 1 -a `check "$target" | wc -l` -eq 1 ]; then
		    IFS=
		    ls "$PWD"/$sel 1> /dev/null 2>& 1
		    if [ $? -ne 0 ]; then
			target="$PWD"
		    else
			target=`ls -d "$PWD"/$sel`
			cmd ; exit 0
		    fi
		elif [ `echo "$target" | wc -l` -eq 1 -a `check "$target" | wc -l` -eq 1 ]; then
		    target="$PWD"
		else
		    target=`echo "$target" | head -1 && echo "$target" | tac | head -n -1 | tac | sed 's@^@'"$PWD"/'@'`
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
	quotes | tr '\n' ' ' | xclip -r -i -selection $copy
    }
    prompt_base "$@"
}

prompt_copy_contents() {
    cmd() {
	if [ "`file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2`" = "image" ]; then
	    program="xclip -i -selection $copy -t image/png"
	else
	    program="xclip -r -i -selection $copy"
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
  Modes:
  -p|--print        │ Print the output of the selection
  -o|--open         │ Open the appropriate program for the selection (default)

   --cat            │ Concatenate the selections before using a mode
-c|--copy           │ Copy the output of the selection (\"primary\", \"secondary\", \"clipboard\" or \"buffer-cut\")
   --no-copy        │ Do not copy (always overrides \`--copy\`)
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

    while getopts hpc:osil:fa-: OPT; do
	# support long options: https://stackoverflow.com/a/28466267/519360
	if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
	    OPT="${OPTARG%%=*}"       # extract long option name
	    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
	    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
	fi
	case "$OPT" in
	    h | help)     	help ; exit 0 ;;
	    p | print)      	print=1 ;;
	    c | copy)     	needs_arg ; copy="$OPTARG" ;;
	    no-copy)		no_copy=1 ;;
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

    [ -n "$1" ] && target="$1"
    [ -z "$target" ] && target="$PWD"

    if [ -d "$target" ]; then
	target="`realpath -s "$target"`"
	PWD="$target"
    elif [ ! -d "$target" ]; then
	echo "`basename $0`: cannot access '$target': No such directory"
	exit 1
    fi

    [ -n "$2" ] && prompt="$2"
    [ ! -z "$prompt" ] && [ "`realpath -s "$prompt"`" = "$target" ] && unset prompt
}

main "$@"
