include	"spectool.h"

define	SZ_STRFILE	1024

# List of colon commands.
define	CMDS	"|open|close|sbands|"
define	OPEN	1
define	CLOSE	2
define	SBANDS	3	# Bandpass spectrophotometry


# SPT_SBANDS -- Compute band fluxes, indices, and equivalent widths.

procedure spt_sbands (spt, reg, cmd)

pointer	spt
pointer	reg
char	cmd[ARB]

int	ncmd, nbands, nsubbands, fd
bool	norm, mag
real	magzero
pointer	sp, type, str, bands

int	strdic(), open(), stropen()
errchk	open, stropen, sb_bands, sb_proc

define	err_	10
define	done_	20

begin
	call smark (sp)
	call salloc (type, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_STRFILE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    ;

	case CLOSE: # close
	    ;

	case SBANDS: # sbands
	    call gargb (norm)
	    call gargb (mag)
	    call gargr (magzero)
	    call gargwrd (Memc[type], SZ_FNAME)
	    call gargstr (Memc[str], SZ_STRFILE)

	    # Read bands from the band file.
	    if (Memc[type] == 'f')
		fd = open (Memc[str], READ_ONLY, TEXT_FILE)
	    else
		fd = stropen (Memc[str], SZ_STRFILE, READ_ONLY)

	    call sb_bands (fd, bands, nbands, nsubbands)
	    call close (fd)

	    # Open output file, write header, measure bands, and write results.
	    fd = stropen (Memc[str], SZ_STRFILE, WRITE_ONLY)
	    call sb_header (fd, norm, mag, magzero, "", bands, nbands, nsubbands)
	    call sb_proc (fd, REG_SH(reg), bands, nbands, norm, mag, magzero)
	    call close (fd)

	    # Finish up.
	    call spt_log (spt, reg, "add", Memc[str])
	    call sb_free (bands, nbands)

	default: # error or unknown command
err_	    call sprintf (Memc[str], SZ_LINE,
		"Error in colon command: sbands %s")
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

done_
	call sfree (sp)
end
