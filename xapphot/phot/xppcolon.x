include "../lib/xphot.h"
include "../lib/phot.h"

# XP_PCOLON -- Show or edit the photometry parameters.

int procedure xp_pcolon (gd, xp, out, cmdstr)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to xapphot structure
int	out		#I the output file descriptor
char	cmdstr[ARB]	#I the command string

bool	bval
int	ncmd , stat, update
pointer	sp, keyword, units, cmd, str, pstatus
real	rval
bool	itob()
int	nscan(), xp_stati(), btoi(), strdic(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	# Get the command.
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp,PSTATUS)

	# Process the command
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, PCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UPCMDS) <= 0)
	        Memc[units] = EOS
	} else
	    Memc[units] = EOS

	switch (ncmd) {

	case PCMD_PGEOMETRY:

	    call gargwrd (Memc[cmd], SZ_LINE)
            if (Memc[cmd] == EOS) {
                call xp_stats (xp, PGEOSTRING, Memc[cmd], SZ_FNAME)
                call printf ("%s = %s\n")
                    call pargstr (Memc[keyword])
                    call pargstr (Memc[cmd])
            } else {
                stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, AGEOMS)
                if (stat > 0) {
                    call xp_seti (xp, PGEOMETRY, stat)
                    call xp_sets (xp, PGEOSTRING, Memc[cmd])
                    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_sparam (out, Memc[keyword], Memc[cmd],
			    Memc[units], "")
		    update = YES
                }
            }

	case PCMD_PAPERTURES:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        call xp_stats (xp, PAPSTRING, Memc[cmd], SZ_LINE)
	        call printf ("%s = %s %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[cmd])
		    call pargstr (Memc[units])
	    } else {
		call xp_sets (xp, PAPSTRING, Memc[cmd])
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
		    call xp_sparam (out, Memc[keyword], Memc[cmd],
		        Memc[units], "")
		update = YES
	    }

	case PCMD_PAXRATIO:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, PAXRATIO))
	    } else {
		call xp_setr (xp, PAXRATIO, rval)
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
		    call xp_rparam (out, Memc[keyword], xp_statr(xp, PAXRATIO),
		        Memc[units], "")
		update = YES
	    }

	case PCMD_PPOSANGLE:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, PPOSANGLE))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, PPOSANGLE, rval)
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
		    call xp_rparam (out, Memc[keyword], xp_statr(xp, PPOSANGLE),
		        Memc[units], "")
		update = YES
	    }

	case PCMD_PZMAG:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, PZMAG))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, PZMAG, rval)
		NEWMAG(pstatus) = YES
		if (SEQNO(pstatus) > 0)
		    call xp_rparam (out, Memc[keyword], xp_statr(xp, PZMAG),
		        Memc[units], "")
		update = YES
	    }

	case PCMD_PHOTMARK:
	    call gargb (bval)
	    if (nscan () == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, PHOTMARK)))
	    } else {
		call xp_seti (xp, PHOTMARK, btoi (bval))
		update = YES
	    }

	case PCMD_PCOLORMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		if (xp_strwrd (xp_stati(xp, PCOLORMARK), Memc[str], SZ_FNAME,
		    PCOLORS) > 0) {
		    call printf ("%s = %s\n")
			call pargstr (Memc[keyword])
			call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, PCOLORS)
		if (stat > 0) {
		    call xp_seti (xp, PCOLORMARK, stat)
		    update = YES
		}
	    }

	default:
	    call printf ("Unknown or ambiguous command\n")
	    update = NO
	}

	call sfree (sp)

	return (update)
end
