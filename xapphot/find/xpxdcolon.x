include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/contour.h"
include "../lib/surface.h"

# XP_XDCOLON -- Process the XDISPLAY task colon commands.

pointer procedure xp_xdcolon (gd, dirlist, xp, imlist, im, objlist, ol,
	reslist, rl, greslist, gl, cmdstr, symbol)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xapphot structure
int	dirlist			#I the current directory list descriptor
int	imlist			#I the current image list descriptor
pointer im			#I the current image descriptor
int	objlist			#I the current object list descriptor
int	ol			#I the current object file descriptor
int	reslist			#I the current results list descriptor
int	rl			#I the current results file descriptor
int	greslist		#I the current output objects list descriptor
int	gl			#I the current output objects file descriptor
char	cmdstr[ARB]		#I the input command string
pointer	symbol			#U the current object symbol

int	pjunk
pointer	sp, incmd
int	strdic(), xp_xcolon(), xp_icolon(), xp_dcolon(), xp_fcolon()
int	xp_ocolon(), xp_ecolon(), xp_acolon(), xp_ucolon()
pointer	xp_statp()

begin
	# Allocate working space.
        call smark (sp)
        call salloc (incmd, SZ_LINE, TY_CHAR)

        # Get the command.
        call sscan (cmdstr)
        call gargwrd (Memc[incmd], SZ_LINE)
        if (Memc[incmd] == EOS) {
            call sfree (sp)
            return (symbol)
        }

        # Process the command.
        if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, FCMDS) > 0) {
            if (xp_xcolon (gd, xp, dirlist, imlist, im, objlist, ol, "obj",
	        reslist, rl, "fnd", greslist, gl, "obj", cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ICMDS) > 0) {
            if (xp_icolon (gd, xp, im, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, DCMDS) > 0) {
            if (xp_dcolon (gd, xp, cmdstr) == YES)
		;
	} else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, LCMDS) > 0) {
            if (xp_fcolon (gd, xp, rl, cmdstr) == YES)
		;
	} else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, OCMDS) > 0) {
            if (xp_ocolon (gd, xp, cmdstr, symbol) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ECMDS) > 0) {
            if (xp_ecolon (gd, xp, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ACMDS) > 0) {
            if (xp_acolon (gd, xp, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, AUCMDS) > 0) {
	    if (xp_ucolon (gd, xp, cmdstr, AUCMDS, DPSETS, pjunk) == YES) {
		switch (pjunk) {
		case PSET_IMPARS:
		    call xp_keyset (im, xp)
		    if (SEQNO(xp_statp(xp, PSTATUS)) > 0) {
			call xp_whimpars (xp, rl)
			call xp_whiminfo (xp, rl)
		    }
		default:
		}
	    }
	} else
	    call printf ("Unknown or ambiguous colon command\7\n")

        call sfree (sp)

	return (symbol)
end
