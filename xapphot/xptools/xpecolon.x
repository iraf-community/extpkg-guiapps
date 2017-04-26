include <error.h>
include "../lib/contour.h"

# XP_ECOLON -- Process colon commands for showing / setting the contour
# plotting parameters.

int procedure xp_ecolon (gd, xp, cmdstr)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xphot structure
char	cmdstr[ARB]		#I the input command string

bool	bval
int	ip, ncmd, ival, update, stat
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
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, ECMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UECMDS) <= 0)
		Memc[units] = EOS
	} else
	    Memc[units] = EOS

	switch (ncmd) {

	case ECMD_ENX:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, ENX))
	    } else {
		call xp_seti (xp, ENX, ival)
		update =YES
	    }

	case ECMD_ENY:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, ENY))
	    } else {
		call xp_seti (xp, ENY, ival)
		update =YES
	    }

	case ECMD_EZ1:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, EZ1))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, EZ1, rval)
		update =YES
	    }

	case ECMD_EZ2:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, EZ2))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, EZ2, rval)
		update =YES
	    }

	case ECMD_EZ0:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, EZ0))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, EZ0, rval)
		update =YES
	    }

	case ECMD_ENCONTOURS:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, ENCONTOURS))
	    } else {
		call xp_seti (xp, ENCONTOURS, ival)
		update =YES
	    }

	case ECMD_EDZ:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, EDZ))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, EDZ, rval)
		update =YES
	    }

	case ECMD_EHILOMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
            if (Memc[cmd] == EOS) {
                if (xp_strwrd (xp_stati (xp, EHILOMARK), Memc[str], SZ_FNAME,
                    EHILOMARK_OPTIONS) > 0)
                    ;
                call printf ("%s = %s\n")
                    call pargstr (Memc[keyword])
                    call pargstr (Memc[str])
            } else {
                stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE,
		    EHILOMARK_OPTIONS)
                if (stat > 0) {
                    call xp_seti (xp, EHILOMARK, stat)
                    update = YES
                }
            }


	case ECMD_EDASHPAT:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, EDASHPAT))
	    } else {
		call xp_seti (xp, EDASHPAT, ival)
		update =YES
	    }

	case ECMD_ELABEL:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, ELABEL)))
	    } else {
		call xp_seti (xp, ELABEL, btoi (bval))
		update =YES
	    }

	case ECMD_EBOX:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, EBOX)))
	    } else {
		call xp_seti (xp, EBOX, btoi (bval))
		update =YES
	    }

	case ECMD_ETICKLABEL:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, ETICKLABEL)))
	    } else {
		call xp_seti (xp, ETICKLABEL, btoi (bval))
		update =YES
	    }

	case ECMD_EXMAJOR:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, EXMAJOR))
	    } else {
		call xp_seti (xp, EXMAJOR, ival)
		update =YES
	    }

	case ECMD_EXMINOR:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, EXMINOR))
	    } else {
		call xp_seti (xp, EXMINOR, ival)
		update =YES
	    }

	case ECMD_EYMAJOR:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, EYMAJOR))
	    } else {
		call xp_seti (xp, EYMAJOR, ival)
		update =YES
	    }

	case ECMD_EYMINOR:
	    call gargi (ival)
	    if (nscan () == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, EYMINOR))
	    } else {
		call xp_seti (xp, EYMINOR, ival)
		update =YES
	    }

	case ECMD_EROUND:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, EROUND)))
	    } else {
		call xp_seti (xp, EROUND, btoi (bval))
		update =YES
	    }

	case ECMD_EFILL:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, EFILL)))
	    } else {
		call xp_seti (xp, EFILL, btoi (bval))
		update =YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
