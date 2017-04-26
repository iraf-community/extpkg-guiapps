include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/contour.h"
include "../lib/surface.h"

# XP_XCCOLON -- Process the XCENTER task colon commands.

pointer	procedure xp_xccolon (gd, xp, dirlist, imlist, im, objlist, ol, reslist, rl,
	greslist, gl, cmdstr, symbol)

pointer	gd			#I the graphics descriptor
pointer	xp			#I the main xapphot descriptor
int	dirlist			#I the current directory list descriptor
int	imlist			#I the image list descriptor
pointer	im			#I the input image descriptor
int	objlist			#I the input object file list descriptor
int	ol			#I the input object file descriptor
int	reslist			#I the output results file list descriptor
int	rl			#I the results file descriptor
int	greslist		#I the output objects file list descriptor
int	gl			#I the output objects file descriptor
char	cmdstr[ARB]		#I the input command string
pointer	symbol			#U the current object symbol

int	pset
pointer	sp, incmd, pstatus
int	strdic(), xp_xcolon(), xp_dcolon(), xp_ocolon(), xp_ecolon()
int	xp_icolon(), xp_ccolon(), xp_ucolon(), xp_fcolon(), xp_acolon()
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
	pstatus = xp_statp(xp, PSTATUS)

        # Process the command.
        if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, FCMDS) > 0) {
            if (xp_xcolon (gd, xp, dirlist, imlist, im, objlist, ol, "fnd",
	        reslist, rl, "ctr", greslist, gl, "obj", cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, AUCMDS) > 0) {
	    if (xp_ucolon (gd, xp, cmdstr, AUCMDS, CPSETS, pset) == YES) {
		switch (pset) {
		case PSET_IMPARS:
		    call xp_keyset (im, xp)
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    if (SEQNO(pstatus) > 0) {
			call xp_whimpars (xp, rl)
			call xp_whiminfo (xp, rl)
		    }
		case PSET_CENPARS:
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_whctrpars (xp, rl)
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
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, CCMDS) > 0) {
            if (xp_ccolon (gd, xp, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ECMDS) > 0) {
            if (xp_ecolon (gd, xp, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ACMDS) > 0) {
            if (xp_acolon (gd, xp, cmdstr) == YES)
		;
	} else
	    call printf ("Unknown or ambiguous colon command\7\n")

        call sfree (sp)

	return (symbol)
end
