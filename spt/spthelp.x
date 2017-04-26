include	"spectool.h"

# Help file.
define	HELP		"spt$doc/spectool.html"
define	KEY		"spt$doc/spectool.key"

# List of colon commands.
define	CMDS "|open|close|load|reload|show|"
define	OPEN	1
define	CLOSE	2
define	LOAD	3
define	RELOAD	4
define	SHOW	5


# SPT_HELP -- Interpret help colon commands.

procedure spt_help (spt, cmd)

pointer	spt			#I SPECTOOLS pointer
char	cmd[ARB]		#I Command

int	i, strdic()
pointer	helpfile
bool	strne()
errchk	spt_helpopen

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	i = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (i) {
	case OPEN: # open
	    call malloc (helpfile, SZ_FNAME, TY_CHAR)

	    # The following sends the help file to the GUI and it is up
	    # to the GUI to then request the help file be loaded.  This
	    # allows the GUI to only load the help when it first starts up.

	    call clgstr ("help", Memc[helpfile], SZ_FNAME)
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "helpfile %s")
		call pargstr (Memc[helpfile])
	    Memc[helpfile] = EOS
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))

	    call clgstr ("topic", SPT_STRING(spt), SPT_SZSTRING)
	    if (SPT_STRING(spt) != EOS)
		call gmsg (SPT_GP(spt), "showhelp", SPT_STRING(spt))

	case CLOSE: # close
	    if (Memc[helpfile] != EOS)
		call clpstr ("help", Memc[helpfile])
	    call mfree (helpfile, TY_CHAR)

	case LOAD: # load file
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    if (strne (SPT_STRING(spt), Memc[helpfile])) {
		call spt_helpopen (spt, SPT_STRING(spt))
		call strcpy (SPT_STRING(spt), Memc[helpfile], SZ_FNAME)

		call clgstr ("topic", SPT_STRING(spt), SPT_SZSTRING)
		if (SPT_STRING(spt) != EOS)
		    call gmsg (SPT_GP(spt), "showhelp", SPT_STRING(spt))
	    }

	case RELOAD: # reload
	    if (Memc[helpfile] == EOS)
		call clgstr ("help", Memc[helpfile], SZ_FNAME)
	    if (Memc[helpfile] != EOS)
		call spt_helpopen (spt, Memc[helpfile])

	case SHOW: # show name
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    if (SPT_GUI(spt) == YES)
		call gmsg (SPT_GP(spt), "showhelp", SPT_STRING(spt))
	    else
		call gpagefile (SPT_GP(spt), KEY, "spectool")

	default: # error or unknown command
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in help command: help %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


# SPT_HELPOPEN - Open help file and send to GUI

procedure spt_helpopen (spt, helpfile)

pointer	spt		#I SPECTOOL pointer
char	helpfile[ARB]	#I Help filename

int	i, fd, len_str, open(), getline()
pointer	line, help
errchk	open()

begin
	len_str = 10 * SZ_LINE
	call calloc (help, len_str, TY_CHAR)
	line = help

	fd = open (helpfile, READ_ONLY, TEXT_FILE)
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
	call gmsg (SPT_GP(spt), "help", Memc[help])

	call mfree (help, TY_CHAR)
end
