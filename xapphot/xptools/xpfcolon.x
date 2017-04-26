include "../lib/xphot.h"
include "../lib/find.h"

# XP_FCOLON -- Process the object detection algorithm colon commands.

int procedure xp_fcolon (gd, xp, out, cmdstr)

pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
int	out		#I the output file descriptor
char	cmdstr[ARB]	#I the input command string

int	ncmd, update
pointer	sp, keyword, units, hunits, cmd, str, pstatus
real	rval
int	strdic(), nscan(), xp_strwrd()
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
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_LINE, LCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, ULCMDS) <= 0)
		Memc[units] = EOS
	    if (xp_strwrd (ncmd, Memc[hunits], SZ_FNAME, HLCMDS) <= 0)
		Memc[units] = EOS
	} else {
	    Memc[units] = EOS 
	    Memc[hunits] = EOS 
	}

	switch (ncmd) {

	case LCMD_FTHRESHOLD:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FTHRESHOLD))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FTHRESHOLD, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FTHRESHOLD), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FRADIUS:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FRADIUS))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FRADIUS, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FRADIUS), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FSEPMIN:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FSEPMIN))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FSEPMIN, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FSEPMIN), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FROUNDLO:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FROUNDLO))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FROUNDLO, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FROUNDLO), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FROUNDHI:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FROUNDHI))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FROUNDHI, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FROUNDHI), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FSHARPLO:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FSHARPLO))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FSHARPLO, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FSHARPLO), Memc[hunits], "")
		update = YES
	    }

	case LCMD_FSHARPHI:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr(xp,FSHARPHI))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, FSHARPHI, rval)
		if (SEQNO(pstatus) > 0)
                    call xp_rparam (out, Memc[keyword], xp_statr (xp,
                        FSHARPHI), Memc[hunits], "")
		update = YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
