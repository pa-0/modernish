#! /module/for/moderni/sh
\command unalias tac 2>/dev/null

# modernish sys/base/tac
#
# A clean-room cross-platform reimplementation of GNU 'tac' in shell and awk,
# with additional features.
#
# Usage: tac [ -rbBP ] [ -s SEP ] FILE ...
#
# Write each FILE to standard output, reversing the order of lines/records.
# With no FILE, or if FILE is -, read standard input.
# -s: Specify the record (line) separator. Default: linefeed.
# -r: Interpret the record separator as an extended regular expression.
# -b: Assume the separator comes before each record in the input, and also
#     output the separator before each record. Cannot be combined with -B.
# -B: Assume the separator comes after each record in the input, but output
#     the separator before each record. Cannot be combined with -b.
# -P: Paragraph mode: output text last paragraph first. Input paragraphs are
#     separated from each other by at least two linefeeds. Cannot be combined
#     with any other option.
#
# --- begin license ---
# Copyright (c) 2019 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

tac() {
	# ___ begin option parser ___
	# Generated by: generateoptionparser -o -n bBrP -a s -f tac -v _Msh_tac_
	unset -v _Msh_tac_b _Msh_tac_B _Msh_tac_r _Msh_tac_P _Msh_tac_s
	while	case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_tac__o=$1
			shift
			while _Msh_tac__o=${_Msh_tac__o#?} && not str empty "${_Msh_tac__o}"; do
				_Msh_tac__a=-${_Msh_tac__o%"${_Msh_tac__o#?}"} # "
				push _Msh_tac__a
				case ${_Msh_tac__o} in
				( [s]* ) # split optarg
					_Msh_tac__a=${_Msh_tac__o#?}
					not str empty "${_Msh_tac__a}" && push _Msh_tac__a && break ;;
				esac
			done
			while pop _Msh_tac__a; do
				set -- "${_Msh_tac__a}" "$@"
			done
			unset -v _Msh_tac__o _Msh_tac__a
			continue ;;
		( -[bBrP] )
			eval "_Msh_tac_${1#-}=''" ;;
		( -s )	let "$# > 1" || die "tac: -s: option requires argument"
			_Msh_tac_s=$2
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "tac: invalid option: $1" ;;
		( * )	break ;;
		esac
	do
		shift
	done
	# ^^^ end option parser ^^^

	# Validate options.
	if isset _Msh_tac_P; then
		if isset _Msh_tac_b || isset _Msh_tac_B || isset _Msh_tac_s; then
			die "tac: -P is incompatible with -b/-B/-s"
		fi
	fi
	if isset _Msh_tac_b && isset _Msh_tac_B; then
		die "tac: -b is incompatible with -B"
	fi
	if isset _Msh_tac_s; then
		if str empty "${_Msh_tac_s}"; then
			die "tac: separator cannot be empty"
		fi
	else
		_Msh_tac_s=$CCn
	fi

	# Set up env in a subshell and exec awk.
	(
		# BUG_EXPORTUNS compat: don't give unset variables the export flag
		export "PATH=$DEFPATH" POSIXLY_CORRECT=y _Msh_tac_s \
			${_Msh_tac_b+_Msh_tac_b} ${_Msh_tac_B+_Msh_tac_B} ${_Msh_tac_r+_Msh_tac_r}
		unset -f awk	# QRK_EXECFNBI compat

		if isset _Msh_tac_P; then
			# Paragraph mode.
			exec awk '
			BEGIN {
				RS = "";
			}

			{
				p[NR] = $0;
			}

			END {
				if (NR) {
					for (i = NR; i > 1; i--) {
						print (p[i])("\n");
					}
					print p[i];
				}
			}'

		else
			# Normal mode.
			exec awk -v ematch_lib=tac -f "$MSH_AUX/ematch.awk" -f "$MSH_AUX/sys/base/tac.awk"
		fi
	)

	_Msh_E=$?
	case ${_Msh_E} in
	( 0 | $SIGPIPESTATUS )
		eval "unset -v _Msh_E _Msh_tac_s _Msh_tac_b _Msh_tac_B _Msh_tac_r _Msh_tac_P; return ${_Msh_E}" ;;
	( * )	die "tac: awk failed with status ${_Msh_E}" ;;
	esac
}

if thisshellhas ROFUNC; then
	readonly -f tac
fi
