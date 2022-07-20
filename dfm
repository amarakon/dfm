#!/bin/sh

main() { parse_opts "$@"
    [ -z $mode ] && mode=open
    { [ ! -n "$no_copy" ] && [ ! -z "$copy" ] && [ -n "$cat" ] && prompt_copy_contents "$@"; } ||
    { [ -n "$open" ] && prompt_open "$@"; } ||
    { [ -n "$cat" ] && prompt_print_contents "$@"; } ||
    { [ -n "$print" ] && prompt_print "$@"; } ||
    { [ ! -n "$no_copy" ] && [ ! -z "$copy" ] && prompt_copy "$@"; } ||
    { prompt_$mode "$@"; } 
}

prompt_base() {
    [ -z $length ] && length=10

    if [ "$case_sensitivity" = "sensitive" ]; then
	menu="dmenu -l $length" grep="grep"
	backtrack() { sed 's|\(.*/'$sel'[^/]*\).*|\1|'; }
    else
	menu="dmenu -i -l $length" grep="grep -i"
	backtrack() { perl -pe 's|(.*/'$sel'[^/]*).*|$1|i'; }
    fi

    { [ "$path" = "full" ] && prompt() { p="$target"; }; } ||
    { prompt() { p="`echo "$target" | sed 's|^'"$HOME"'|~|'`"; }; }

    truepath() { sh -c "realpath -s "$sel""; }
    slash() { echo "$target/$sel" | rev | cut -b 1-2; }
    check() { file -E "$@" | grep "(No such file or directory)$"; }
    fullcmd() { echo -n "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | cmd ; exit 0; }

    while true; do
	p="$prompt" ; [ -z "$p" ] && prompt
	sel="$(echo -n "$(ls --group-directories-first "$target"; ls --group-directories-first -A "$target" | grep '^\.' )" | $menu -p "$p")"
	ec=$? ; [ "$ec" -ne 0 ] && exit $ec

	if [ `echo "$sel" | wc -l` -eq 1 ]; then
	    if [ -e "$target/$sel" -a "`slash`" != "//" ]; then
		newt="`realpath -s "$target/$sel"`"
	    elif [ ! -e "$target/$sel" -a $(echo "$target" | $grep "$(sh -c "echo "$sel"")" | wc -l) -eq 1 ]; then
		{ [ ! -e "`truepath`" ] && newt="`echo "$target" | backtrack`"; } ||
		{ newt="`truepath`"; }
	    elif [ -e "`truepath`" ] && [ ! -e "$target/$sel" -o "`slash`" = "//" ]; then
		newt="`truepath`"
	    else
		newt="`realpath -s "$target/$sel"`"
	    fi
	else
	    newt="$sel"
	fi

	if [ `ls | wc -l` -ge 1 ]; then
	    target="$newt"
	    if [ ! -d "$target" ]; then
		if [ `echo "$target" | grep "*" | wc -l` -ge 1 -a `check "$target" | wc -l` -eq 1 ]; then
		    IFS=
		    ls "$PWD"/$sel 1> /dev/null 2>& 1
		    { [ $? -ne 0 ] && target="$PWD"; } ||
		    { target=`ls -d "$PWD"/$sel` fullcmd; }
		elif [ `echo "$target" | wc -l` -eq 1 -a `check "$target" | wc -l` -eq 1 ]; then
		    target="$PWD"
		elif [ `echo "$target" | wc -l` -gt 1 ]; then
		    target=`echo "$target" | sed 's|^|'"$PWD"/'|'` fullcmd
		else
		    fullcmd
		fi
	    else
		PWD="$target"
	    fi
	fi

    done
}

prompt_print() { cmd () { xargs ls -d; } ; prompt_base "$@"; }
prompt_print_contents() { cmd() { xargs cat; } ; prompt_base "$@"; }
prompt_open() { cmd() { { [ -x "`command -v sesame`" ] && xargs sesame; } || { xargs xdg-open; }; } ; prompt_base "$@"; }
prompt_copy() { cmd() { tr '\n' ' ' | xclip -r -i -selection $copy; } ; prompt_base "$@"; }
prompt_copy_contents() {
    cmd() {
	{ [ "`file -b "$target" | cut -d ',' -f1 | cut -d ' ' -f2`" = "image" ] && xargs xclip -i -selection $copy -t image/png; } ||
	{ xargs xclip -r -i -selection $copy; }
    }
    prompt_base "$@"
}


help() { echo -n "Usage:	`basename $0` [options] [target] [prompt]

Options:

Modes:
-p|--print       │ Print the output of the selection
-o|--open        │ Open the appropriate program for the selection (default)

   --cat         │ Concatenate the selections before using a mode
-c|--copy        │ Copy the output of the selection (\`primary\`, \`secondary\`, \`clipboard\` (default), or \`buffer-cut\`)
   --no-copy     │ Do not copy (always overrides \`--copy\`)
                 │
-s|--sensitive   │ Use case-sensitive matching
-i|--insensitive │ Use case-insensitive matching (default)
-l|--length      │ Specify the length of dmenu (default: 10)
                 │
-f|--full        │ Use the full path for the prompt
-a|--abbreviated │ Use the abbreviated path for the prompt (default)
                 │
-h|--help        │ Print this help message and exit
"; }

parse_opts() {
    : "${config_dir:=${XDG_CONFIG_HOME:-$HOME/.config}/`basename $0`}"
    : "${config_file:=$config_dir/`basename $0`.conf}"
    [ -f "$config_file" ] && . "$config_file"

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
	    h | help)     	help ; exit 0 ;;
	    p | print)      	print=1 ;;
	    c | copy)
		shift ; [ `printf "$OPT" | wc -c` -eq 1 ] && OPTARG="$1"
		case "$OPTARG" in
		    primary | secondary | clipboard | buffer-cut)	copy="$OPTARG" ;;
		    *)							copy="clipboard" ;;
		esac
		[ -n "$1" -a "$OPTARG" = "$1" -a "$copy" = "$OPTARG" ] && shift ;;
	    no-copy)		no_copy=1 ;;
	    cat)		cat=1 ;;
	    o | open)		open=1 ;;
	    s | sensitive)	case_sensitivity="sensitive" ;;
	    i | insensitive)	case_sensitivity="insensitive" ;;
	    l | length)		needs_arg ; length=$OPTARG ;;
	    f | full)		path="full" ;;
	    a | abbreviated)	path="abbreviated" ;;
	    ??*)          	die "Illegal option --$OPT" ;;  # bad long option
	    ?)            	exit 2 ;;  # bad short option (error reported via getopts)
	esac
    done
    shift $((OPTIND-1)) # remove parsed options and args from $@ list

    [ -n "$1" ] && target="$1" ; [ -z "$target" ] && target="$PWD"

    if [ -d "$target" ]; then
	target="`realpath -s "$target"`"
	PWD="$target"
    elif [ ! -d "$target" ]; then
	echo "`basename $0`: cannot access '$target': No such directory"
	exit 1
    fi

    [ -n "$2" ] && prompt="$2" ; [ ! -z "$prompt" ] && [ "`realpath -s "$prompt"`" = "$target" ] && unset prompt
}

main "$@"
