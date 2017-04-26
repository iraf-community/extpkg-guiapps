include "../lib/xphot.h"
include <error.h>
include "../lib/display.h"

# XP_DCOLON  --  The image display colon commands.

int procedure xp_dcolon (gd, xp, cmdstr)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xphot structure
char	cmdstr[ARB]		#I the input command string

bool	bval
int	ip, ncmd, ival, stat, update
pointer	sp, keyword, units, cmd, str, pstatus
real	rval
bool	itob()
int	strdic(), nscan(), xp_stati(), btoi(), xp_strwrd(), ctowrd()
pointer	xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}

	# Process the command.
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, DCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UDCMDS) <= 0)
		Memc[units] = EOS
	} else
	    Memc[units] = EOS
	pstatus = xp_statp (xp, PSTATUS)

	switch (ncmd) {

	case DCMD_DERASE:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, DERASE)))
	    } else {
		call xp_seti (xp, DERASE, btoi (bval))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DFILL:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, DFILL)))
	    } else {
		call xp_seti (xp, DFILL, btoi (bval))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DXORIGIN:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DXORIGIN))
	    } else {
		call xp_setr (xp, DXORIGIN, max (0.0, min (rval, 1.0)))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DYORIGIN:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DYORIGIN))
	    } else {
		call xp_setr (xp, DYORIGIN, max (0.0, min (rval, 1.0)))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DXVIEWPORT:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DXVIEWPORT))
	    } else {
		call xp_setr (xp, DXVIEWPORT, max (0.0, min (rval, 1.0)))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DYVIEWPORT:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DYVIEWPORT))
	    } else {
		call xp_setr (xp, DYVIEWPORT, max (0.0, min (rval, 1.0)))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DXMAG:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DXMAG))
	    } else {
		call xp_setr (xp, DXMAG, rval)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DYMAG:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DYMAG))
	    } else {
		call xp_setr (xp, DYMAG, rval)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DZTRANSFORM:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		if (xp_strwrd (xp_stati (xp, DZTRANS), Memc[str], SZ_FNAME,
		    DZTRANS_OPTIONS) > 0)
		    ;
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, DZTRANS_OPTIONS)
		if (stat > 0) {
		    call xp_seti (xp, DZTRANS, stat)
		    REDISPLAY(pstatus) = YES
		    update = YES
		}
	    }
	case DCMD_DZLIMITS:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
		if (xp_strwrd (xp_stati (xp, DZLIMITS), Memc[str], SZ_FNAME,
		    DZLIMITS_OPTIONS) > 0)
		    ;
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, DZLIMITS_OPTIONS)
		if (stat > 0) {
		    call xp_seti (xp, DZLIMITS, stat)
		    REDISPLAY(pstatus) = YES
		    update = YES
		}
	    }

	case DCMD_DZCONTRAST:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DZCONTRAST))
	    } else {
		call xp_setr (xp, DZCONTRAST, rval)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DZNSAMPLE:
	    call gargi (ival)
	    if (nscan() == 1) {
		call printf ("%s = %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, DZNSAMPLE))
	    } else {
		call xp_seti (xp, DZNSAMPLE, ival)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DZ1:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DZ1))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, DZ1, rval)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DZ2:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, DZ2))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, DZ2, rval)
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	case DCMD_DLUTFILE:
	    call gargstr (Memc[cmd], SZ_LINE)
            #if (Memc[cmd] == EOS || (streq (Memc[cmd], Memc[str])) {
            if (Memc[cmd] == EOS) {
                call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
                call printf ("%s = %s\n")
                    call pargstr (Memc[keyword])
                    call pargstr (Memc[str])
            } else {
                if (xp_statp (xp, DLUT) != NULL) {
		    call xp_ulutfree (xp_statp (xp, DLUT))
		    call xp_setp (xp, DLUT, NULL)
                }
		ip = 1
		if (ctowrd (Memc[cmd], ip, Memc[str], SZ_FNAME) <= 0)
		    Memc[str] = EOS
		call xp_sets (xp, DLUTFILE, Memc[str])
		REDISPLAY(pstatus) = YES
		update = YES
            }


	case DCMD_DREPEAT:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, DREPEAT)))
	    } else {
		call xp_seti (xp, DREPEAT, btoi (bval))
		REDISPLAY(pstatus) = YES
		update = YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
