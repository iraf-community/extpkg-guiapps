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
include "uipars.h"

# XP_GXPCOLON -- Process the XPHOT task colon commands.

pointer procedure xp_gxpcolon (gd, ui, xp, dirlist, imlist, im, objlist, ol,
	reslist, rl, greslist, gl, cmdstr, symbol)

pointer	gd			#I the pointer to the graphics stream
pointer	ui			#I the pointer to the user interface
pointer	xp			#I the pointer to the main xapphot structure
int	dirlist			#U the current directory list descriptor
int	imlist			#U the image list descriptor
pointer	im			#U the pointer to the input image
int	objlist			#U the object file list descriptor
int	ol			#U the object file descriptor
int	reslist			#U the results file list  descriptor
int	rl			#U the results file descriptor
int	greslist		#U the output objects file list descriptor
int	gl			#U the output objects file descriptor
char	cmdstr[ARB]		#I the input command
pointer	symbol			#U the current object symbol

int	pset, xupdate, update, dupdate, iupdate, cupdate, supdate
int	pupdate, cpupdate, oupdate, fupdate, sfupdate
pointer	sp, incmd, str, tmpsymbol, pstatus
real	xver, yver
int	strdic(), xp_xcolon(), xp_dcolon(), xp_icolon(), xp_ccolon()
int	xp_scolon(), xp_pcolon(), xp_ecolon(), xp_ucolon(), xp_ocolon()
int	xp_gcolon(), xp_fcolon(), xp_acolon(), xp_stati()
pointer	xp_statp()
data	xupdate /YES/, dupdate /YES/, iupdate /YES/, cupdate /YES/
data	supdate /YES/, pupdate /YES/, cpupdate /YES/, oupdate /YES/
data	fupdate /YES/, sfupdate /YES/

begin
	# Allocate working space.
        call smark (sp)
        call salloc (incmd, SZ_LINE, TY_CHAR)
        call salloc (str, SZ_LINE, TY_CHAR)

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
	        reslist, rl, "mag", greslist, gl, "geo", cmdstr) == YES) {
		if (xupdate == YES) {
		    call xp_stats (xp, STARTDIR, Memc[incmd], SZ_FNAME)
		    call xp_stats (xp, CURDIR, Memc[str], SZ_FNAME)
		    call xp_mkdlist (gd, ui, Memc[incmd], Memc[str], dirlist)
		    call xp_stats (xp, IMTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_mkilist (gd, ui, Memc[str], imlist)
		    call xp_stats (xp, OFTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_mkclist (gd, ui, Memc[str], objlist)
		    call xp_stats (xp, RFTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_stats (xp, GFTEMPLATE, Memc[incmd], SZ_FNAME)
		    call xp_mkmlist (gd, ui, Memc[str], reslist, xp_stati (xp,
		        RFNUMBER), Memc[incmd], greslist, xp_stati (xp,
			GFNUMBER))
		    if (LOGRESULTS(pstatus) == YES)
		        call gmsg (gd, UI_LOGRESULTS(ui), "yes")
		    else
		        call gmsg (gd, UI_LOGRESULTS(ui), "no")
		}
	    }

	# Parameter set updating commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, UUCMDS) > 0) {
            update = xp_ucolon (gd, xp, cmdstr, UUCMDS, APSETS, pset)
	    switch (pset) {
	    case PSET_IMPARS:
		iupdate = update
		if (iupdate == YES)
		    call xp_iguipars (gd, ui, xp)
	    case PSET_DISPARS:
		dupdate = update
		if (dupdate == YES)
		    call xp_dguipars (gd, ui, xp)
	    case PSET_FINDPARS:
		fupdate = update
		if (fupdate == YES)
		    call xp_fguipars (gd, ui, xp)
	    case PSET_OMARKPARS:
		oupdate = update
		if (oupdate == YES)
		    call xp_oguipars (gd, ui, xp)
	    case PSET_CENPARS:
		cupdate = update
		if (cupdate == YES)
		    call xp_cguipars (gd, ui, xp)
	    case PSET_SKYPARS:
		supdate = update
		if (supdate == YES)
		    call xp_sguipars (gd, ui, xp)
	    case PSET_PHOTPARS:
		pupdate = update
		if (pupdate == YES)
		     call xp_pguipars (gd, ui, xp)
	    case PSET_EPLOTPARS:
		cpupdate = update
		if (cpupdate == YES)
		     call xp_eguipars (gd, ui, xp)
	    case PSET_APLOTPARS:
		sfupdate = update
		if (sfupdate == YES)
		     call xp_aguipars (gd, ui, xp)
	    default:
		call printf ("Unknown parameter set\n")
	    }

	# Image display parameter commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, DCMDS) > 0) {
            if (xp_dcolon (gd, xp, cmdstr) == YES) {
		if (dupdate == YES)
		    call xp_dguipars (gd, ui, xp)
	    }

	# Contour plotting parameter commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ECMDS) > 0) {
            if (xp_ecolon (gd, xp, cmdstr) == YES) {
		if (cpupdate == YES)
		    call xp_eguipars (gd, ui, xp)
	    }

	# Surface plotting parameter commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ACMDS) > 0) {
            if (xp_acolon (gd, xp, cmdstr) == YES) {
		if (sfupdate == YES)
		    call xp_aguipars (gd, ui, xp)
	    }

	# Object detection algorithm commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, LCMDS) > 0) {
            if (xp_fcolon (gd, xp, rl, cmdstr) == YES) {
		if (fupdate == YES)
		    call xp_fguipars (gd, ui, xp)
	    }

	# Object list manipulation and marking commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, OCMDS) > 0) {
	    tmpsymbol = symbol
            if (xp_ocolon (gd, xp, cmdstr, tmpsymbol) == YES) {
		if (oupdate == YES) {
		    call xp_oguipars (gd, ui, xp)
		    if (UI_SHOWOBJLIST(ui) == YES)
		        call xp_mkslist (gd, ui, xp)
	            call gmsgi (gd, UI_OBJNO(ui), OBJNO(xp_statp(xp,PSTATUS)))
		}
	    }
	    if (tmpsymbol != NULL) {
		call gim_setraster (gd, 1)
		call gscur (gd, XP_OXINIT(tmpsymbol), XP_OYINIT(tmpsymbol)) 
		call gim_setraster (gd, 0)
		if (tmpsymbol != symbol) {
		    call xp_ogeometry (xp, tmpsymbol, xver, yver, 0, xver, yver,
		        0, Memc[str], SZ_LINE)
		    call gmsg (gd, UI_OBJMARKER(ui), Memc[str])
		}
	    }
	    symbol = tmpsymbol

	# Image data dependent commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, ICMDS) > 0) {
            if (xp_icolon (gd, xp, im, rl, cmdstr) == YES) {
		if (iupdate == YES)
		    call xp_iguipars (gd, ui, xp)
	    }

	# Centering parameter commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, CCMDS) > 0) {
            if (xp_ccolon (gd, xp, rl, cmdstr) == YES) {
		if (cupdate == YES)
		    call xp_cguipars (gd, ui, xp)
	    }

	# Sky fitting parameter commands
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, SCMDS) > 0) {
            if (xp_scolon (gd, xp, rl, cmdstr) == YES) {
		if (supdate == YES)
		    call xp_sguipars (gd, ui, xp)
	    }

	# Photometry parameter commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, PCMDS) > 0) {
            if (xp_pcolon (gd, xp, rl, cmdstr) == YES) {
		if (pupdate == YES)
		    call xp_pguipars (gd, ui, xp)
	    }

	# Object and sky aperture geometry commands.
        } else if (strdic (Memc[incmd], Memc[incmd], SZ_LINE, GEOCMDS) > 0) {
            if (xp_gcolon (gd, xp, cmdstr) == YES) {
		if (supdate == YES)
		    call xp_sguipars (gd, ui, xp)
		if (pupdate == YES)
		    call xp_pguipars (gd, ui, xp)
		call xp_gsapoly (gd, ui, xp)
	    }
	} else
	    call printf ("Unknown or ambiguous colon command\7\n")

        call sfree (sp)

	return (symbol)
end
