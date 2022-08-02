#!/bin/sh

main() { parse_opts "$@"
	[ -z $mode ] && mode=open
	if [ -n "$copy" -a "$copy" != false ] && [ "$cat" = true ]; then
		prompt_copy_contents "$@"
	elif [ "$open" = true ]; then prompt_open "$@"
	elif [ "$cat" = true ]; then prompt_print_contents "$@"
	elif [ "$print" = true ]; then prompt_print "$@"
	elif [ -n "$copy" -a "$copy" != false ]; then prompt_copy "$@"
	else prompt_$mode "$@"; fi
}

prompt_base() {
	[ -z $length ] && length=10
	[ "$copy" = true ] && copy="clipboard"

	if [ "$case_sensitivity" = "sensitive" ]; then
		menu="dmenu -l $length" grep="grep"
		backtrack() { sed 's|\(.*/'$sel'[^/]*\).*|\1|'; }
	else
		menu="dmenu -i -l $length" grep="grep -i"
		backtrack() { perl -pe 's|(.*/'$sel'[^/]*).*|$1|i'; }
	fi

	if [ "$path" = "full" ]; then prompt() { p="$target"; }
	else prompt() { p="$(printf '%s' "$target" | sed 's|^'"$HOME"'|~|')"; }; fi

	truepath() { sh -c "realpath -s "$sel""; }
	slash() { printf '%s' "$target/$sel" | rev | cut -b 1-2; }
	check() { file -E "$@" | grep "(No such file or directory)$"; }
	fullcmd() {
		printf '%s' "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" |
			cmd
	}

	while true; do
		p="$prompt" ; [ -z "$p" ] && prompt
		list() { ls --group-directories-first "$@"; }
		sel="$(printf '%s' "$(list "$target"; list -A "$target" | grep '^\.')" |
			$menu -p "$p")"
		ec=$? ; [ "$ec" -ne 0 ] && exit $ec

		if [ $(printf '%s' "$sel" | wc -l) -eq 0 ]; then
			if [ -e "$target/$sel" -a "$(slash)" != "//" ]; then
				newt="$(realpath -s "$target/$sel")"
			elif [ ! -e "$target/$sel" -a $(printf '%s' "$target" |
				$grep "$(sh -c "printf '%s' "$sel"")" | wc -l) -eq 1 ]
	    	then
				if [ ! -e "$(truepath)" ]; then
					newt="$(printf '%s' "$target" | backtrack)"
				else newt="$(truepath)"; fi
			elif [ -e "$(truepath)" ] &&
				[ ! -e "$target/$sel" -o "$(slash)" = "//" ]
			then newt="$(truepath)"
			else newt="$(realpath -s "$target/$sel")"; fi
		else newt="$sel"; fi

		if [ $(ls | wc -l) -ge 1 ]; then
			target="$newt"
			if [ ! -d "$target" ]; then
				if [ $(printf '%s' "$target" | grep "*" | wc -l) -ge 1 -a\
					$(check "$target" | wc -l) -eq 1 ]
				then
					IFS=
					ls "$PWD"/$sel 1> /dev/null 2>& 1
					if [ $? -ne 0 ]; then target="$PWD"
					else target=$(ls -d "$PWD"/$sel) fullcmd ; exit 0; fi
				elif [ $(printf '%s' "$target" | wc -l) -eq 0 -a\
					$(check "$target" | wc -l) -eq 1 ]
				then target="$PWD"
				elif [ $(printf '%s' "$target" | wc -l) -gt 0 ]; then
					target=$(printf '%s' "$target" | sed 's|^|'"$PWD"/'|')
					fullcmd ; exit 0
				else fullcmd ; exit 0; fi
			else PWD="$target"; fi
		fi
	done
}

prompt_print() { cmd () { xargs ls -d; } ; prompt_base "$@"; }
prompt_print_contents() { cmd() { xargs cat; } ; prompt_base "$@"; }

prompt_open() {
	cmd() {
		if [ -x "$(command -v sesame)" ]; then xargs sesame
		else xargs xdg-open; fi
	}
	prompt_base "$@"
}

prompt_copy() {
	cmd() { tr '\n' ' ' | xclip -r -i -selection $copy; }
	prompt_base "$@"
}

prompt_copy_contents() {
	cmd() {
		if [ "$(file -b "$target" | cut -d " " -f2)" = "image" ]; then
			xargs xclip -i -selection $copy -t image/png
		else xargs xclip -r -i -selection $copy; fi
	}
	prompt_base "$@"
}


help() { printf 'Usage:\t%s' "$(basename $0) [options] [target] [prompt]

Options:

Modes:
-p|--print            │ Print the output of the selection
-o|--open             │ Open the appropriate program for the selection (default)

   --cat              │ Concatenate the selections before using a mode
-c|--copy=[CLIPBOARD] │ Copy the output of the selection
   --no-copy          │ Do not copy (always overrides \`--copy\`)
                      │
-s|--sensitive        │ Use case-sensitive matching
-i|--insensitive      │ Use case-insensitive matching (default)
-l|--length=LENGTH    │ Specify the length of dmenu (default: 10)
                      │
-f|--full             │ Use the full path for the prompt
-a|--abbreviated      │ Use the abbreviated path for the prompt (default)
                      │
-h|--help             │ Print this help message and exit
"; }

parse_opts() {
	: "${config_dir:=${XDG_CONFIG_HOME:-$HOME/.config}/$(basename $0)}"
	: "${config_file:=$config_dir/$(basename $0).conf}"
	[ -f "$config_file" ] && . "$config_file"

	needs_arg() {
		if [ -z "$OPTARG" ]; then
			printf '%s\n' "No arg for --$OPT option" >&2
			exit 2
		fi
	}

	while getopts hpcosil:fa-: OPT; do
		# Support long options: https://stackoverflow.com/a/28466267/519360
		if [ "$OPT" = "-" ]; then
			OPT="${OPTARG%%=*}"
			OPTARG="${OPTARG#$OPT}"
			OPTARG="${OPTARG#=}"
		fi
		case "$OPT" in
			h | help) help ; exit 0 ;;
			p | print) print=true ;;
			c | copy)
				shift
				[ $(printf '%s' "$OPT" | wc -c) -eq 1 ] && OPTARG="$1"
				case "$OPTARG" in
					primary | secondary | clipboard | buffer-cut)
						copy="$OPTARG"
						;;
					*) copy=true ;;
				esac
				[ -n "$1" -a "$OPTARG" = "$1" -a "$copy" = "$OPTARG" ] && shift
				;;
			no-copy) copy=false ;;
			cat) cat=true ;;
			o | open) open=true ;;
			s | sensitive) case_sensitivity="sensitive" ;;
			i | insensitive) case_sensitivity="insensitive" ;;
			l | length) needs_arg ; length=$OPTARG ;;
			f | full) path="full" ;;
			a | abbreviated) path="abbreviated" ;;
			??*)
				printf '%s\n' "Illegal option --$OPT" >&2
				exit 2
				;;
			?) exit 2 ;;
		esac
	done
	shift $((OPTIND-1))

	[ -n "$1" ] && target="$1" ; [ -z "$target" ] && target="$PWD"

	if [ -d "$target" ]; then
		target="$(realpath -s "$target")"
		PWD="$target"
	elif [ ! -d "$target" ]; then
		printf '%s\n' "$(basename $0): \`$target\` is not a directory." >&2
		exit 2
	fi

	[ -n "$2" ] && prompt="$2"
	if [ -n "$prompt" ] && [ "$(realpath -s "$prompt")" = "$target" ]; then
		unset prompt
	fi
}

main "$@"
