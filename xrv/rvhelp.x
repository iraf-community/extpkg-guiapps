include "rvpackage.h"

define	HELP	"xrv$doc/fxcor.html" 	# default help file


# RV_HELPOPEN - Open help file and send to GUI.

procedure rv_helpopen (rv)

pointer	rv				#I package pointer

int	i, fd, len_str, access(), open(), getline()
pointer	line, help
errchk	open()

begin
	len_str = 10 * SZ_LINE
	call calloc (help, len_str, TY_CHAR)
	line = help

	if (access(HELP,0,0) != YES)
	    return

	fd = open (HELP, READ_ONLY, TEXT_FILE)
	while (getline (fd, Memc[line]) != EOF) {
	    for (; Memc[line]!=EOS; line=line+1)
		;
	    i = line - help
	    if (i + SZ_LINE > len_str) {
		len_str = len_str + 10 * SZ_LINE
		call realloc (help, len_str, TY_CHAR)
		line = help + i
	    }
	}
	call close (fd)

	# Send results to GUI.
	call gmsg (RV_GP(rv), "help", Memc[help])

	call mfree (help, TY_CHAR)
end
