include "../lib/surface.h"

# XP_ACOLON -- Process colon commands for showing / setting the surface
# plotting parameters.

int procedure xp_acolon (gd, xp, cmdstr)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xphot structure
char	cmdstr[ARB]		#I the input command string

bool	bval
int	ip, ncmd, ival, update
pointer	sp, keyword, units, cmd, str
real	rval
bool	itob()
int	strdic(), nscan(), btoi(), xp_stati()
int	xp_strwrd()
real	xp_statr()

begin
	# Allocate working space.
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
	ip = 1
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, ACMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UACMDS) <= 0)
		Memc[units] = EOS
	} else
	    Memc[units] = EOS

	switch (ncmd) {

	case ACMD_ASNX:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, ASNX))
	    } else {
		call xp_seti (xp, ASNX, ival)
		update =YES
	    }

	case ACMD_ASNY:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, ASNY))
	    } else {
		call xp_seti (xp, ASNY, ival)
		update =YES
	    }

	case ACMD_ALABEL:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, ALABEL)))
	    } else {
		call xp_seti (xp, ALABEL, btoi (bval))
		update =YES
	    }

	case ACMD_AZ1:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, AZ1))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, AZ1, rval)
		update =YES
	    }

	case ACMD_AZ2:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, AZ2))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, AZ2, rval)
		update =YES
	    }

	case ACMD_ANGH:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, ANGH))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, ANGH, rval)
		update =YES
	    }

	case ACMD_ANGV:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, ANGV))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, ANGV, rval)
		update =YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
