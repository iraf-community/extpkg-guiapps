include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/fitsky.h"
include "../lib/contour.h"
include "../lib/surface.h"

# XP_XSCOLON -- Process the XFITSKTY task colon commands.

pointer procedure xp_xscolon (gd, xp, dirlist, imlist, im, objlist, ol,
	reslist, rl, greslist, gl, cmdstr, symbol)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xapphot structure
int	dirlist			#I the current directory list descriptor
int	imlist			#I the image list descriptor
pointer	im			#I the pointer to the input image
int	objlist			#I the object list descriptor
int	ol			#I the object file descriptor
int	reslist			#I the results list descriptor
int	rl			#I the results file descriptor
int	greslist		#I the geometry results list descriptor
int	gl			#I the geometry results file descriptor
char	cmdstr[ARB]		#I the input command string
pointer	symbol			#I the current object symbol

int	pset
pointer	sp, incmd, pstatus
int	strdic(), xp_dcolon(), xp_ecolon(), xp_icolon(), xp_scolon()
int	xp_xcolon(), xp_ocolon(), xp_ucolon(), xp_fcolon(), xp_acolon()
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
	pstatus = xp_statp(xp,PSTATUS)

        # Process the command.
        if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, FCMDS) > 0) {
            if (xp_xcolon (gd, xp, dirlist, imlist, im, objlist, ol, "fnd",
	        reslist, rl, "sky", greslist, gl, "obj", cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, AUCMDS) > 0) {
	    if (xp_ucolon (gd, xp, cmdstr, AUCMDS, SPSETS, pset) == YES) {
		switch (pset) {
		case PSET_IMPARS:
		    call xp_keyset (im, xp)
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    if (SEQNO(pstatus) > 0) {
			call xp_whimpars (xp, rl)
			call xp_whiminfo (xp, rl)
		    }
		case PSET_SKYPARS:
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_whskypars (xp, rl)
		default:
		    ;
		}
	    }
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
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, SCMDS) > 0) {
            if (xp_scolon (gd, xp, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ECMDS) > 0) {
            if (xp_ecolon (gd, xp, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ACMDS) > 0) {
            if (xp_acolon (gd, xp, cmdstr) == YES)
		;
	} else {
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

        call sfree (sp)

	return (symbol)
end
