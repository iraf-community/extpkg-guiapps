include "../lib/xphot.h"
include "../lib/center.h"

# XP_CCOLON -- Process the centering algorithm colon commands.

int procedure xp_ccolon (gd, xp, out, cmdstr)

pointer	gd		#I the graphics descriptor
pointer	xp		#I the main xapphot descriptor
int	out		#I the output file descriptor
char	cmdstr[ARB]	#I the input command string

bool	bval
int	ncmd, stat, ival, update
pointer	sp, keyword, units, hunits, cmd, str, pstatus
real	rval
bool	itob()
int	strdic(), nscan(), xp_stati(), btoi(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (hunits, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp,PSTATUS)

	# Process the command.
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_LINE, CCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UCCMDS) <= 0)
		Memc[units] = EOS
	    if (xp_strwrd (ncmd, Memc[hunits], SZ_FNAME, HCCMDS) <= 0)
		Memc[units] = EOS
	} else {
	    Memc[units] = EOS 
	    Memc[hunits] = EOS 
	}

	switch (ncmd) {

	case CCMD_CALGORITHM:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, CSTRING, Memc[str], SZ_FNAME)
	        call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, CALGS)
		if (stat > 0) {
		    call xp_seti (xp, CALGORITHM, stat)
		    call xp_sets (xp, CSTRING, Memc[cmd])
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    update = YES
		    if (SEQNO(pstatus) > 0)
		        call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[hunits], "")
		}
	    }

	case CCMD_CRADIUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, CRADIUS))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, CRADIUS, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp, CRADIUS),
                        Memc[hunits], "")
		update = YES
	    }

	case CCMD_CTHRESHOLD:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, CTHRESHOLD))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, CTHRESHOLD, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			CTHRESHOLD), Memc[hunits], "")
		update = YES
	    }

	case CCMD_CMINSNRATIO:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, CMINSNRATIO))
	    } else {
		call xp_setr (xp, CMINSNRATIO, rval)
		NEWCENTER(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			CMINSNRATIO), Memc[hunits], "")
		update = YES
	    }

	case CCMD_CMAXITER:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, CMAXITER))
	    } else {
		call xp_seti (xp, CMAXITER, ival)
		NEWCENTER(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_iparam (out, Memc[keyword], xp_stati (xp,
			CMAXITER), Memc[hunits], "")
		update = YES
	    }

	case CCMD_CXYSHIFT:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, CXYSHIFT))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, CXYSHIFT, rval)
		NEWCENTER(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			CXYSHIFT), Memc[hunits], "")
		update = YES
	    }

	case CCMD_CTRMARK:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, CTRMARK)))
	    } else {
		call xp_seti (xp, CTRMARK, btoi (bval))
		update = YES
	    }

	case CCMD_CCHARMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, CCHARMARK), Memc[str], SZ_FNAME,
		    CMARKERS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, CMARKERS)
		if (stat > 0) {
		    call xp_seti (xp, CCHARMARK, stat)
		    update = YES
		}
	    }

	case CCMD_CCOLORMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, CCOLORMARK), Memc[str], SZ_FNAME,
		    CCOLORS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, CCOLORS)
		if (stat > 0) {
		    call xp_seti (xp, CCOLORMARK, stat)
		    update = YES
		}
	    }

	case CCMD_CSIZEMARK:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, CSIZEMARK))
	    } else {
		call xp_setr (xp, CSIZEMARK, rval)
		update = YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
