#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests related to file descriptors, redirection, pipelines, and other I/O matters.

doTest1() {
	title='blocks can save a closed file descriptor'
	{
		{
			while :; do
				{
					exec 4>/dev/tty
				} 4>&-
				break
			done 4>&-
			# does the 4>/dev/tty leak out of of both a loop and a { ...; } block?
			if { true >&4; } 2>/dev/null; then
				mustHave BUG_SCLOSEDFD
			else
				mustNotHave BUG_SCLOSEDFD
			fi
		} 4>&-
	} 4>/dev/null	# BUG_SCLOSEDFD workaround
	if eq $? 1 || { true >&4; } 2>/dev/null; then
		return 1
	elif isset xfailmsg; then
		return 2
	fi
} 4>&-

doTest2() {
	title="pipeline commands are run in subshells"
	# POSIX says at http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_12
	#	"[...] as an extension, however, any or all commands in
	#	a pipeline may be executed in the current environment."
	# Some shells execute the last element of a pipeline in the current environment (feature ID:
	# LEPIPEMAIN), but there are no currently existing shells that execute any other element of a
	# pipeline in the current environment. Scripts may break if a shell ever does. At the very least
	# it would require another modernish feature ID (e.g. ALLPIPEMAIN). Until then, this sanity check
	# should fail if that condition is ever detected.
	v1= v2= v3= v4=
	# QRK_APIPEMAIN compat: use assignment-arguments, not real assignments
	# QRK_PPIPEMAIN compat: don't use assignments in parameter substitutions, eg. : ${v1=1}
	unexport v1=1 | unexport v2=2 | unexport v3=3 | unexport v4=4
	case $v1$v2$v3$v4 in
	( '' )	mustNotHave LEPIPEMAIN ;;
	( 4 )	mustHave LEPIPEMAIN ;;
	(1234)	failmsg="need ALLPIPEMAIN feature ID"; return 1 ;;
	( * )	failmsg="need new shell quirk ID ($v1$v2$v3$v4)"; return 1 ;;
	esac
}

doTest3() {
	title='simple assignments in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no assignment in last element
	true | v1=foo | putln "junk" | v2=bar | cat
	case ${v1-U},${v2-U} in
	( U,U )	mustNotHave QRK_APIPEMAIN ;;
	( foo,bar )
		mustHave QRK_APIPEMAIN ;;
	( * )	return 1 ;;
	esac
}

doTest4() {
	title='param substitutions in pipeline elements'
	unset -v v1 v2
	# LEPIPEMAIN compat: no param subst in last element
	true | : ${v1=foo} | putln "junk" | : ${v2=bar} | cat
	case ${v1-U},${v2-U} in
	( U,U )	mustNotHave QRK_PPIPEMAIN ;;
	( foo,bar )
		mustHave QRK_PPIPEMAIN ;;
	( * )	return 1 ;;
	esac
}

lastTest=4