include	<error.h>
include	<smw.h>
include	"spectool.h"

define	CMDS "|open|close|save|logfile|clear|add|title|header|"
define	OPEN		1
define	CLOSE		2
define	SAVE		3	# Save GUI log
define	LOGFILE		4	# Set logfile file name
define	CLEAR		5	# Clear log
define	ADD		6	# Add a line of log information
define	TITLE		7	# Add a line of log title information
define	HEADER		8	# Add a line of log header information


# SPT_LOG - Set and save log information.

procedure spt_log (spt, reg, cmd, data)

pointer	spt			#I Spectool pointer
pointer	reg			#I Register pointer
char	cmd[ARB]		#I Log command
char	data[ARB]		#I Log data

char	path[SZ_FNAME], fname[SZ_FNAME], logfile[SZ_FNAME]
char	title[SZ_LINE], header[SZ_LINE], dunits[SZ_LINE], funits[SZ_LINE]
int	sysidflag, ncmd, logfd
pointer	sp, str, sh

int	strdic()
bool	strne()
errchk	spt_logopen, spt_logsave, spt_logappend

define	err_	10
define	add_	20

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN:
	    call fpathname ("", path, SZ_FNAME)
	    #path[1] = EOS
	    call clgstr ("logfile", fname, SZ_FNAME)
	    call spt_logopen (spt, path, fname, logfile, SZ_FNAME, logfd)
	    header[1] = EOS
	    title[1] = EOS
	    dunits[1] = EOS
	    funits[1] = EOS
	    sysidflag = NO

	case CLOSE:
	    call spt_logsave (spt, logfile, logfd)
	    if (logfd != NULL)
	        call close (logfd)

	case SAVE:
	    call spt_logsave (spt, logfile, logfd)

	case CLEAR:
	    if (logfd != NULL) {
		call close (logfd)
		iferr (call delete (logfile))
		    ;
	    }
	    call spt_logopen (spt, path, fname, logfile, SZ_FNAME, logfd)
	    header[1] = EOS
	    title[1] = EOS

	case LOGFILE:
	    if (logfd != NULL) {
		call spt_logsave (spt, logfile, logfd)
		call close (logfd)
		call strcpy (data, fname, SZ_FNAME)
		call spt_logopen (spt, path, fname, logfile, SZ_FNAME, logfd)
		header[1] = EOS
		title[1] = EOS
	    } else {
		call strcpy (data, fname, SZ_FNAME)
		call spt_logappend (spt, path, fname, logfile, SZ_FNAME)
		call spt_logopen (spt, path, fname, logfile, SZ_FNAME, logfd)
	    }

	case ADD: # add log information (assumes newlines are used)
add_	   
	    if (sysidflag == NO) {
		call strcpy ("# ", Memc[str], SZ_LINE)
		call sysid (Memc[str+2], SZ_LINE-2)
		call strcat ("\n\n", Memc[str], SZ_LINE)
		call gmsg (SPT_GP(spt), "logadd", Memc[str])
		sysidflag = YES
	    }
	    if (reg != NULL) {
		sh = REG_SH(reg)
		if (strne (UNITS(sh), dunits)) {
		    call strcpy (UNITS(sh), dunits, SZ_LINE)
		    call sprintf (Memc[str], SZ_LINE, "# dunits %s\n")
			call pargstr (UNITS(sh))
		    call gmsg (SPT_GP(spt), "logadd", Memc[str])
		}
		if (strne (FUNITS(sh), funits)) {
		    call strcpy (FUNITS(sh), funits, SZ_LINE)
		    call sprintf (Memc[str], SZ_LINE, "# funits %s\n")
			call pargstr (FUNITS(sh))
		    call gmsg (SPT_GP(spt), "logadd", Memc[str])
		}
	    }
	    call gmsg (SPT_GP(spt), "logadd", data)
	    if (logfd != NULL) {
		call putline (logfd, data)
		call flush (logfd)
	    }

	case TITLE: # add log title information if different
	    if (strne (data, title)) {
		call strcpy (data, title, SZ_LINE)
		goto add_
	    }

	case HEADER: # add log header information if different
	    if (strne (data, header)) {
		call strcpy (data, header, SZ_LINE)
		goto add_
	    }

	default: # error or unknown command
err_	    call sprintf (Memc[str], SZ_LINE,
		"Error in colon command: %s")
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

	call sfree (sp)
end


# SPT_LOGOPEN -- Open log file and write to GUI.

procedure spt_logopen (spt, path, fname, logfile, maxchar, logfd)

pointer	spt		#I SPECTOOL pointer
char	path[ARB]	#I Path
char	fname[ARB]	#U Logfile
char	logfile[ARB]	#O Full logfile
int	maxchar		#I Size of full logfile
int	logfd		#I File descriptor

pointer	sp, str

int	nowhite(), access(), open(), getline()
errchk	open

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	call gmsg (SPT_GP(spt), "logcmd", "clear")
	call sprintf (Memc[str], SZ_LINE, "logfile %s")
	    call pargstr (fname)
	call gmsg (SPT_GP(spt), "logcmd", Memc[str])

	logfd = NULL
	logfile[1] = EOS
	if (nowhite (fname, fname, SZ_LINE) > 0) {
	    iferr {
		# Set full logfile name.
		call sprintf (logfile, maxchar, "%s%s")
		    call pargstr (path)
		    call pargstr (fname)

		# Copy to GUI
		if (access (logfile, READ_WRITE, TEXT_FILE) == YES) {
		    logfd = open (logfile, READ_WRITE, TEXT_FILE)
		    while (getline (logfd, Memc[str]) != EOF)
			call gmsg (SPT_GP(spt), "logadd", Memc[str])
		} else
		    logfd = open (logfile, NEW_FILE, TEXT_FILE)
	    } then {
		logfd = NULL
		fname[1] = EOS
		logfile[1] = EOS
		call sprintf (Memc[str], SZ_LINE, "logfile %s")
		    call pargstr (fname)
		call gmsg (SPT_GP(spt), "logcmd", Memc[str])
		call erract (EA_ERROR)
	    }
	}

	call sfree (sp)
end


# SPT_LOGSAVE -- Save GUI log text window.

procedure spt_logsave (spt, logfile, logfd)

pointer	spt		#I SPECTOOL pointer
char	logfile[ARB]	#I Logfile
int	logfd		#U File descriptor

int	wcs, key
real	wx, wy
pointer	sp, str

int	open(), clgcur()
errchk	open, delete

begin
	if (SPT_GUI(spt) == NO || logfd == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	call close (logfd)
	iferr (call delete (logfile))
	    ;
	logfd = open (logfile, APPEND, TEXT_FILE)

	call gmsg (SPT_GP(spt), "logcmd", "save")
	while (clgcur ("cursor", wx, wy, wcs, key, Memc[str], SZ_LINE) != EOF) {
	    switch (key) {
	    case ':':
		if (Memc[str+4] != EOS)
		    call putline (logfd, Memc[str+5])
		call putc (logfd, "\n")
	    default:
		break
	    }
	}
	call flush (logfd)

	call sfree (sp)
end


# SPT_LOGAPPEND -- Append GUI log to file.

procedure spt_logappend (spt, path, fname, logfile, maxchar)

pointer	spt		#I SPECTOOL pointer
char	path[ARB]	#I Path
char	fname[ARB]	#U Logfile
char	logfile[ARB]	#O Full logfile
int	maxchar		#I Size of full logfile

int	logfd, wcs, key
real	wx, wy
pointer	sp, str

int	nowhite(), open(), clgcur()
errchk	open

begin
	logfile[1] = EOS
	if (nowhite (fname, fname, ARB) == 0)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    # Set full logfile name.
	    call sprintf (logfile, maxchar, "%s%s")
		call pargstr (path)
		call pargstr (fname)

	    # Append to logfile.
	    logfd = open (logfile, APPEND, TEXT_FILE)

	    call gmsg (SPT_GP(spt), "logcmd", "save")
	    while (clgcur ("cursor",wx,wy,wcs,key,Memc[str],SZ_LINE) != EOF) {
		switch (key) {
		case ':':
		    if (Memc[str+4] != EOS)
			call putline (logfd, Memc[str+5])
		    call putc (logfd, "\n")
		default:
		    break
		}
	    }
	    call close (logfd)
	} then {
	    fname[1] = EOS
	    logfile[1] = EOS
	    call erract (EA_ERROR)
	}

	call sfree (sp)
end
