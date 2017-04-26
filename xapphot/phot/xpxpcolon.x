include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "../lib/contour.h"
include "../lib/surface.h"

# XP_XPCOLON -- Process the XPHOT task colon commands.

pointer procedure xp_xpcolon (gd, xp, dirlist, imlist, im, objlist, ol,
	reslist, rl, greslist, gl, cmdstr, symbol)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
int	dirlist			#I the current directory list descriptor
int	imlist			#I the image list descriptor
pointer	im			#I the pointer to the input image
int	objlist			#I the object file list descriptor
int	ol			#I the object file descriptor
int	reslist			#I the results file list descriptor
int	rl			#I the results file descriptor
int	greslist		#I the objects results file list descriptor
int	gl			#I the objects results file descriptor
char	cmdstr[ARB]		#I the input command string
pointer	symbol			#I the  current symbol

int	pset
pointer	sp, incmd, pstatus
int	strdic(), xp_ucolon(), xp_xcolon(), xp_dcolon()
int	xp_icolon(), xp_ccolon(), xp_scolon(), xp_pcolon(), xp_ecolon()
int	xp_ocolon(), xp_fcolon(), xp_acolon()
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

        # Process the colon commands.
        if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, FCMDS) > 0) {
            if (xp_xcolon (gd, xp, dirlist, imlist, im, objlist, ol, "obj",
	        reslist, rl, "mag", greslist, gl, "geo", cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, AUCMDS) > 0) {
            if (xp_ucolon (gd, xp, cmdstr, AUCMDS, APSETS, pset) == YES) {
		switch (pset) {
		case PSET_IMPARS:
		    call xp_keyset (im, xp)
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0) {
			call xp_whimpars (xp, rl)
			call xp_whiminfo (xp, rl)
		    }
		case PSET_CENPARS:
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_whctrpars (xp, rl)
		case PSET_SKYPARS:
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_whskypars (xp, rl)
		case PSET_PHOTPARS:
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    if (SEQNO(pstatus) > 0)
			call xp_whphotpars (xp, rl)
		default:
		    ;
		}
	    }
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, LCMDS) > 0) {
            if (xp_fcolon (gd, xp, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ICMDS) > 0) {
            if (xp_icolon (gd, xp, im, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, CCMDS) > 0) {
            if (xp_ccolon (gd, xp, rl, cmdstr) == YES)
	        ;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, SCMDS) > 0) {
            if (xp_scolon (gd, xp, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, PCMDS) > 0) {
            if (xp_pcolon (gd, xp, rl, cmdstr) == YES)
		;
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, DCMDS) > 0) {
            if (xp_dcolon (gd, xp, cmdstr) == YES)
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
	} else
	    call printf ("Unknown or ambiguous colon command\7\n")

        call sfree (sp)

	return (symbol)
end
