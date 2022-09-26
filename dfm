#!/bin/sh

PROGRAM_NAME=$(basename $0) # This will be used in a few messages

main() {
	parse_opts "$@"
	[ -z "$mode" ] && mode=open # The default mode

	if [ -n "$copy" -a "$copy" != false -a "$cat" = true ]; then
		prompt_copy_contents "$@"
	elif [ "$open" = true ]; then
		prompt_open "$@"
	elif [ "$cat" = true ]; then
		prompt_print_contents "$@"
	elif [ "$print" = true ]; then
		prompt_print "$@"
	elif [ -n "$copy" -a "$copy" != false ]; then
		prompt_copy "$@"
	else
		prompt_$mode "$@"
	fi
}

prompt_base() {
	[ -z "$length" ] && length=10

	if [ "$case_sensitivity" = sensitive ]; then
		backtrack() { sed 's|\(.*/'$sel'[^/]*\).*|\1|'; }
		s=+i
	else
		backtrack() { perl -pe 's|(.*/'$sel'[^/]*).*|$1|i'; }
		i=-i
	fi

	[ -z "$menu" ] && menu="dmenu"
	if [ "$menu" = dmenu ]; then menu() { $menu $i -l $length -p "$@"; }
	elif [ "$menu" = fzf ]; then menu() { $menu $s $i --header="$@"; }
	else menu() { $menu; }; fi

	if [ "$path" = "full" ]; then prompt() { p="$target"; }
	else prompt() { p="$(printf '%s' "$target" | sed 's|^'"$HOME"'|~|')"; }; fi

	# Only GNU `ls` supports `--group-directories-first`
	if [ "$(ls --version | head -1 | cut -d " " -f 2-3)" = "(GNU coreutils)" ]
	then
		list() { ls --group-directories-first "$@"; }
	else
		list() {
			(ls -l "$@" | grep "^d"
			ls -l "$@" | grep -vE "^d|^total") | tr -s " " | cut -d " " -f 9-
		}
	fi

	# Commonly used functions in DFM
	truepath() { sh -c "realpath -s "$sel""; }
	slash() { printf '%s' "$target/$sel" | rev | cut -b 1-2; }
	check() { file -E "$@" | grep "(No such file or directory)$"; }
	fullcmd() {
		printf '%s' "$target" | sed -e "s/'/'\\\\''/g;s/\(.*\)/'\1'/" | cmd
	}

	while true; do
		p="$prompt" # Reset the prompt to have it update
		[ -z "$p" ] && prompt # Make the prompt if it does not exist

		# This is where the file manager actually first opens.
		sel="$(printf '%s' "$(list "$target"; list -A "$target" | grep '^\.')" |
			menu "$p")"

		# Exit if the user presses Escape, Control-C, etc.
		exit_code=$?
		[ "$exit_code" -ne 0 ] && exit $exit_code

		if [ $(printf '%s' "$sel" | wc -l) -eq 0 ]; then
			# If the input box is empty, go to the parent directory
			if [ "$sel" = "" ]; then
				newt="$(realpath -s "$target/..")"
			# Relative directories
			elif [ -e "$target/$sel" -a "$(slash)" != // ]; then
				newt="$(realpath -s "$target/$sel")"
			elif [ ! -e "$target/$sel" -a $(printf '%s' "$target" |
				grep $i "$(sh -c "printf '%s' "$sel"")" | wc -l) -eq 1 ]
						then
							# Go to a lower directory using the input box
							if [ ! -e "$(truepath)" ]; then
								newt="$(printf '%s' "$target" | backtrack)"
							# Go to certain directories like `~` `$HOME`, etc.
							else
								newt="$(truepath)"
							fi
			# Go to a directory when the input box begins with `/`
			elif [ -e "$(truepath)" ] &&
				[ ! -e "$target/$sel" -o "$(slash)" = "//" ]
						then
							newt="$(truepath)"
			else
				# This applies to wildcards
				newt="$(realpath -s "$target/$sel")"
			fi
		else
			newt="$sel"
		fi

		# If the current working directory is not empty
		if [ $(ls | wc -l) -ge 1 ]; then
			target="$newt"
			if [ ! -d "$target" ]; then
				# Check if the user used a wildcard
				if [ $(printf '%s' "$target" | grep "*" | wc -l) -ge 1 -a\
					$(check "$target" | wc -l) -eq 1 ]
								then
									IFS= # Needed to make wildcards work
									ls "$PWD"/$sel 1> /dev/null 2>& 1
									# Target is a file or directory
									if [ $? -ne 0 ]; then
										target="$PWD"
									# Target is a wildcard
									else
										echo lol
										target=$(ls -d "$PWD"/$sel) fullcmd
										exit 0
									fi
				# No such file or directory
				elif [ $(printf '%s' "$target" | wc -l) -eq 0 -a\
					$(check "$target" | wc -l) -eq 1 ]
								then
									target="$PWD"
				# More than one selection
				elif [ $(printf '%s' "$target" | wc -l) -gt 0 ]; then
					target=$(printf '%s' "$target" | sed 's|^|'"$PWD"/'|')
					fullcmd
					exit
				# Exactly one selection
				else
					fullcmd
					exit
				fi
			# Target is a directory
			else
				PWD="$target"
			fi
		fi
	done
}

prompt_print() {
	cmd () { xargs ls -d; }
	prompt_base "$@"
}

prompt_print_contents() {
	cmd() { xargs cat; }
	prompt_base "$@"
}

prompt_open() {
	if [ -x "$(command -v sesame)" ]; then cmd() { xargs sesame; }
	else cmd() { xargs xdg-open; }; fi
	prompt_base "$@"
}

prompt_copy() {
	cmd() { tr '\n' ' ' | xclip -r -i -selection $copy; }
	prompt_base "$@"
}

prompt_copy_contents() {
	if [ "$(file -b "$target" | cut -d " " -f2)" = "image" ]; then
		cmd() { xargs xclip -i -selection $copy -t image/png; }
	else
		cmd() { xargs xclip -r -i -selection $copy; }
	fi
	prompt_base "$@"
}

help() {
	printf "Usage:\t$0 [options] [target] [prompt]

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
-m|--menu=MENU        │ Choose which menu program to use (default: dmenu)
-l|--length=LENGTH    │ Specify the length of dmenu (default: 10)
                      │
-f|--full             │ Use the full path for the prompt
-a|--abbreviated      │ Use the abbreviated path for the prompt (default)
                      │
-h|--help             │ Print this help message and exit
"; }

parse_opts() {
	: "${config_dir:=${XDG_CONFIG_HOME:-$HOME/.config}/$PROGRAM_NAME}"
	: "${config_file:=$config_dir/$PROGRAM_NAME.conf}"
	[ -f "$config_file" ] && . "$config_file"

	needs_arg() {
		if [ -z "$OPTARG" ]; then
			printf '%s\n' "No arg for --$OPT option" >&2
			exit 2
		fi
	}

	while getopts hpcosim:l:fa-: OPT; do
		# Support long options: https://stackoverflow.com/a/28466267/519360
		if [ "$OPT" = "-" ]; then
			OPT="${OPTARG%%=*}"
			OPTARG="${OPTARG#$OPT}"
			OPTARG="${OPTARG#=}"
		fi
		case "$OPT" in
			h|help)
				help
				exit 0
				;;
			p|print)
				print=true
				;;
			c|copy)
				shift
				[ $(printf '%s' "$OPT" | wc -c) -eq 1 ] && OPTARG="$1"
				case "$OPTARG" in
					primary|secondary|clipboard|buffer-cut)
						copy="$OPTARG"
						;;
					*)
						copy=clipboard
						;;
				esac
				[ -n "$1" -a "$OPTARG" = "$1" -a "$copy" = "$OPTARG" ] && shift
				;;
			no-copy)
				copy=false
				;;
			cat)
				cat=true
				;;
			o|open)
				open=true
				;;
			s|sensitive)
				case_sensitivity="sensitive"
				;;
			i|insensitive)
				case_sensitivity="insensitive"
				;;
			m|menu)
				needs_arg
				menu="$OPTARG"
				;;
			l|length)
				needs_arg
				length=$OPTARG
				;;
			f|full)
				path="full"
				;;
			a|abbreviated)
				path="abbreviated"
				;;
			??*)
				printf '%s\n' "Illegal option --$OPT" >&2
				exit 2
				;;
			?) # Error reported via `getopts`
				exit 2
				;;
		esac
	done
	shift $((OPTIND-1)) # Remove option arguments from the argument list

	if [ -n "$1" ]; then target="$1"
	elif [ -z "$target" ]; then target="$PWD"
	fi

	if [ -d "$target" ]; then
		target="$(realpath -s "$target")"
		PWD="$target"
	else
		printf '%s\n' "$PROGRAM_NAME: \`$target\` is not a directory." >&2
		exit 2
	fi

	[ -n "$2" ] && prompt="$2"
	# If the prompt is the same as the target, uset the prompt so that it can
	# update. This is useful if you set a prompt in your configuration file but
	# want to use the default prompt
	if [ -n "$prompt" ] && [ "$(realpath -s "$prompt")" = "$target" ]; then
		unset prompt
	fi
}

main "$@"
