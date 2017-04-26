include "../lib/xphot.h"
include "../lib/fitsky.h"


# XP_SCOLON --  Examine and edit the sky fitting algorithm parameters.

int procedure xp_scolon (gd, xp, out, cmdstr)

pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
int	out		#I the output file descriptor
char	cmdstr[ARB]	#I the input command string

bool	bval
int	ncmd, stat, ival, update
pointer	sp, keyword, units, hunits, cmd, pstatus
real	rval
bool	itob()
int	strdic(), nscan(), btoi(), xp_stati(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	# Get the command
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (hunits, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp,PSTATUS)

	# Process the command.
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_LINE, SCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, USCMDS) <= 0)
		Memc[units] = EOS
	    if (xp_strwrd (ncmd, Memc[hunits], SZ_FNAME, HSCMDS) <= 0)
		Memc[units] = EOS
	} else {
	    Memc[units] = EOS
	    Memc[hunits] = EOS
	}

	switch (ncmd) {

	case SCMD_SMODE:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, SMSTRING, Memc[cmd], SZ_FNAME)
	        call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[cmd])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, SMODES)
		if (stat > 0) {
		    call xp_seti (xp, SMODE, stat)
		    call xp_sets (xp, SMSTRING, Memc[cmd])
		    NEWSKY(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
               		call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[hunits], "")
		    update = YES
		}
	    }

	case SCMD_SALGORITHM:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, SSTRING, Memc[cmd], SZ_FNAME)
	        call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[cmd])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, SALGS)
		if (stat > 0) {
		    call xp_seti (xp, SALGORITHM, stat)
		    call xp_sets (xp, SSTRING, Memc[cmd])
		    NEWSKY(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
               		call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[hunits], "")
		    update = YES
		}
	    }

	case SCMD_SGEOMETRY:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, SGEOSTRING, Memc[cmd], SZ_FNAME)
	        call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[cmd])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, SGEOMS)
		if (stat > 0) {
		    call xp_seti (xp, SGEOMETRY, stat)
		    call xp_sets (xp, SGEOSTRING, Memc[cmd])
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
               		call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[hunits], "")
		    update = YES
		}
	    }

	case SCMD_SRANNULUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SRANNULUS))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SRANNULUS, rval)
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SRANNULUS), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SWANNULUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SWANNULUS))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SWANNULUS, rval)
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SWANNULUS), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SAXRATIO:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SAXRATIO))
	    } else {
		call xp_setr (xp, SAXRATIO, max (0.0, min (rval, 1.0)))
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SAXRATIO), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SPOSANGLE:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SPOSANGLE))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SPOSANGLE, max (0.0, min (rval, 360.0)))
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SPOSANGLE), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SCONSTANT:
	    call gargr (rval)
	    if (nscan () == 1) {
		call printf ("%s = %g %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SCONSTANT))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SCONSTANT, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SCONSTANT), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SLOCLIP:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SLOCLIP))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SLOCLIP, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SLOCLIP), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SHICLIP:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SHICLIP))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SHICLIP, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SHICLIP), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SHWIDTH:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SHWIDTH))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SHWIDTH, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SHWIDTH), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SHBINSIZE:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SHBINSIZE))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SHBINSIZE, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
		        SHBINSIZE), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SHSMOOTH:
	    call gargb (bval)
	    if (nscan () == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, SHSMOOTH)))
	    } else {
		call xp_seti (xp, SHSMOOTH, btoi (bval))
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_bparam (out, Memc[keyword], itob (xp_stati (xp,
                        SHSMOOTH)), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SMAXITER:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, SMAXITER))
	    } else {
		call xp_seti (xp, SMAXITER, ival)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_iparam (out, Memc[keyword], xp_stati (xp,
			SMAXITER), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SNREJECT:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, SNREJECT))
	    } else {
		call xp_seti (xp, SNREJECT, ival)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_iparam (out, Memc[keyword], xp_stati (xp,
			SNREJECT), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SLOREJECT:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SLOREJECT))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SLOREJECT, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			SLOREJECT), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SHIREJECT:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SHIREJECT))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SHIREJECT, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			SHIREJECT), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SRGROW:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, SRGROW))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, SRGROW, rval)
		NEWSKY(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			SRGROW), Memc[hunits], "")
		update = YES
	    }

	case SCMD_SKYMARK:
	    call gargb (bval)
	    if (nscan () == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, SKYMARK)))
	    } else {
		call xp_seti (xp, SKYMARK, btoi (bval))
		update = YES
	    }

	case SCMD_SCOLORMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, SCOLORMARK), Memc[cmd], SZ_FNAME,
		    SCOLORS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[cmd])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, SCOLORS)
		if (stat > 0) {
		    call xp_seti (xp, SCOLORMARK, stat)
		    update = YES
		}
	    }

	default:
	    ;
	}

	call sfree (sp)

	return (update)
end
