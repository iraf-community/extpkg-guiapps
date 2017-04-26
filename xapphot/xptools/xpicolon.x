include "../lib/xphot.h"
include <error.h>
include "../lib/impars.h"

# XP_ICOLON -- Process colon commands for showing / setting the image data
# parameters.

int procedure xp_icolon (gd, xp, im, out, cmdstr)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xphot structure
pointer	im			#I the  pointer to the input image
int	out			#I the the output file descriptor
char	cmdstr[ARB]		#I the input command string

bool	bval
int	ip, ncmd, stat, update
pointer	sp, keyword, units, hunits, cmd, str, pstatus
real	rval
bool	itob()
int	strdic(), nscan(), btoi(), xp_stati(), ctowrd()
int	xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (hunits, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp, PSTATUS)

	# Process the command.
	ip = 1
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, ICMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UICMDS) <= 0)
		Memc[units] = EOS
	    if (xp_strwrd (ncmd, Memc[hunits], SZ_FNAME, HICMDS) <= 0)
		Memc[hunits] = EOS
	} else {
	    Memc[units] = EOS
	    Memc[hunits] = EOS
	}
	switch (ncmd) {

	case ICMD_ISCALE:
	    call gargr (rval)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (1.0 / xp_statr (xp, ISCALE))
	    } else if (rval > 0.0) {
		call xp_setr (xp, ISCALE, (1.0 / rval))
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], 1.0 / xp_statr (xp,
			ISCALE), Memc[hunits], "")
		update =YES
	    }

	case ICMD_IHWHMPSF:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IHWHMPSF))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IHWHMPSF, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp, IHWHMPSF),
                        Memc[hunits], "")
		update =YES
	    }

	case ICMD_IEMISSION:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, IEMISSION)))
	    } else {
		call xp_seti (xp, IEMISSION, btoi (bval))
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_bparam (out, Memc[keyword], itob (xp_stati (xp,
                        IEMISSION)), Memc[hunits], "")
		update =YES
	    }

	case ICMD_ISKYSIGMA:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, ISKYSIGMA))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, ISKYSIGMA, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			ISKYSIGMA), Memc[hunits], "")
		update =YES
	    }

	case ICMD_IMINDATA:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IMINDATA))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IMINDATA, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp, IMINDATA),
                        Memc[hunits], "")
		update =YES
	    }

	case ICMD_IMAXDATA:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IMAXDATA))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IMAXDATA, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp, IMAXDATA),
                        Memc[hunits], "")
		update =YES
	    }

	case ICMD_INOISEMODEL:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, INSTRING, Memc[str], SZ_FNAME)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, NFUNCS)
		if (stat > 0) {
		    call xp_seti (xp, INOISEMODEL, stat)
		    call xp_sets (xp, INSTRING, Memc[cmd])
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
                	call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[hunits], "")
		    update =YES
		}
	    }

	case ICMD_IKREADNOISE:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IKREADNOISE, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKREADNOISE, Memc[str])
		if (im != NULL)
		    call xp_rdnoise (im, xp)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IREADNOISE, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IREADNOISE, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			IREADNOISE), Memc[hunits], "")

		}
		update =YES
	    }

	case ICMD_IREADNOISE:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IREADNOISE))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IREADNOISE, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			IREADNOISE), Memc[hunits], "")
		update =YES
	    }

	case ICMD_IKGAIN:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd]  == EOS) {
		call xp_stats (xp, IKGAIN, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKGAIN, Memc[str])
		if (im != NULL)
		    call xp_gain (im, xp)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IGAIN, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IGAIN, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			IGAIN), Memc[hunits], "")

		}
		update =YES
	    }

        case ICMD_IGAIN:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IGAIN))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IGAIN, rval)
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
			IGAIN), Memc[hunits], "")
		update =YES
	    }

	case ICMD_IKEXPTIME:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IKEXPTIME, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKEXPTIME, Memc[str])
		if (im != NULL)
		    call xp_etime (im, xp)
		NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IETIME, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IETIME, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,IETIME),
                        Memc[hunits], "")
		}
		update =YES
	    }

	case ICMD_IETIME:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IETIME))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, IETIME, rval)
		NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,IETIME),
                        Memc[hunits], "")
		update =YES
	    }

	case ICMD_IKFILTER:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IKFILTER, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKFILTER, Memc[str])
		if (im != NULL)
		    call xp_filter (im, xp)
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IFILTER, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IFILTER, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
		    call xp_stats (xp, IFILTER, Memc[str], SZ_LINE)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
		}
		update =YES
	    }

	case ICMD_IFILTER:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IFILTER, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IFILTER, Memc[str])
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("INDEF", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
		}
		update =YES
	    }

	case ICMD_IKAIRMASS:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IKAIRMASS, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKAIRMASS, Memc[str])
		if (im != NULL)
		    call xp_airmass (im, xp)
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IAIRMASS, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IAIRMASS, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,IAIRMASS),
                        Memc[hunits], "")
		}
		update =YES
	    }

	case ICMD_IAIRMASS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, IAIRMASS))
	    } else {
		call xp_setr (xp, IAIRMASS, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,IAIRMASS),
                        Memc[hunits], "")
		update =YES
	    }


	case ICMD_IKOBSTIME:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IKOBSTIME, Memc[str], SZ_LINE)
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IKOBSTIME, Memc[str])
		if (im != NULL)
		    call xp_otime (im, xp)
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("\"\"", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
	            if (xp_strwrd (ICMD_IOTIME, Memc[keyword], SZ_FNAME,
		        ICMDS) <= 0)
			;
	            if (xp_strwrd (ICMD_IOTIME, Memc[hunits], SZ_FNAME,
		        HICMDS) <= 0)
			Memc[hunits] = EOS
		    call xp_stats (xp, IOTIME, Memc[str], SZ_LINE)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
		}
		update =YES
	    }

	case ICMD_IOTIME:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		call xp_stats (xp, IOTIME, Memc[str], SZ_LINE)
		call printf ("%s = %s %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
		    call pargstr (Memc[units])
	    } else {
	        if (ctowrd (Memc[cmd], ip, Memc[str], SZ_LINE) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, IOTIME, Memc[str])
		if (SEQNO(pstatus) > 0) {
                    if (Memc[str] == EOS)
                        call strcpy ("INDEF", Memc[str], SZ_FNAME)
                    call xp_sparam (out, Memc[keyword], Memc[str],
			Memc[hunits], "")
		}
		update =YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}
	call flush (STDOUT)

	call sfree (sp)

	return (update)
end
