include <gio.h>
include "../lib/phot.h"

# XP_ORBJPLOTS -- Plots the object information in various ways.

procedure xp_orbjplots (gd, xp, im, psymbol, oxver, oyver, nover)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	oxver[ARB]		# sky polygon x vertices
real	oyver[ARB]		# sky polygon y vertices
int	nover			# number of vertices

int	wcs, key, markap, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy, width
int	clgcur(), xp_stati()
real	xp_plimits(), xp_statr()

begin
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)


        # Save the old wcs structure if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	while (clgcur ("gcommands", wx, wy, wcs, key, Memc[cmd], SZ_LINE) !=
	    EOF) {

	    switch (key) {

	    case 'q':
		break

	    case 'i':
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		} else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		}

	    case 'o':
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, YES)
		} else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, YES)
		}

	    case 'a':
		markap = xp_stati(xp, PHOTMARK)
		call xp_seti (xp, PHOTMARK, YES)
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		    call xp_apmark (gd, xp, oxver, oyver, nover,
		        OBJPLOT_DISPLAY_WCS, OBJPLOT_DISPLAY_WCS)
		} else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		    call xp_oapmark (gd, xp, psymbol, oxver, oyver, nover,
		        OBJPLOT_DISPLAY_WCS, OBJPLOT_DISPLAY_WCS)
		}
		call xp_seti (xp, PHOTMARK, markap)

	    case 'm':
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		} else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS, NO, NO)
		}

	    case 'c':
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
                    call xp_cpplot (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS)
		} else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
                    call xp_ocpplot (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS)
		}

	    case 's':
		if (psymbol == NULL) {
		    width = xp_plimits (xp, NULL, oxver, oyver, nover)
		    call xp_asplot (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS)
	        } else {
		    width = xp_plimits (xp, psymbol, oxver, oyver, nover)
		    call xp_oasplot (gd, xp, im, xp_statr(xp, PXCUR),
		        xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
			OBJPLOT_DISPLAY_WCS)
		}

	    default:
		;
	    }
	}

        # Restore the old wcs array.
        call gflush (gd)
        call amovi (wcs_save, Memi[GP_WCSPTR(gd,1)], LEN_WCSARRAY)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

	call sfree (sp)
end


# XP_OBJPLOTS -- Plots the object information in various ways.

procedure xp_objplots (gd, xp, im, psymbol, oxver, oyver, nover)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	oxver[ARB]		# sky polygon x vertices
real	oyver[ARB]		# sky polygon y vertices
int	nover			# number of vertices

int	wcs, key, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy
int	clgcur()

begin
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

        # Save the old wcs structure if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

        # Pick one wcs to use for the sky analysis plots.
        call amovki (0, Memi[GP_WCSPTR(gd,1)], LEN_WCSARRAY)

	while (clgcur ("gcommands", wx, wy, wcs, key, Memc[cmd], SZ_LINE) !=
	    EOF) {

            switch (key) {

            case 'q':
                break

	    case 'r':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_RADIUS, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_RADIUS, OBJPLOT_ANALYSIS_WCS)

	    case 't':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_PA, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_PA, OBJPLOT_ANALYSIS_WCS)
	    case 'g':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_COG, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_COG, OBJPLOT_ANALYSIS_WCS)

	    case 'e':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MAXRATIO, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MAXRATIO, OBJPLOT_ANALYSIS_WCS)

	    case 'p':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MPOSANGLE, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MPOSANGLE, OBJPLOT_ANALYSIS_WCS)

	    case 'w':
		if (psymbol == NULL)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MHWIDTH, OBJPLOT_ANALYSIS_WCS)
		else
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MHWIDTH, OBJPLOT_ANALYSIS_WCS)


	    default:
		;
	    }
	}

        # Restore the old wcs array.
        call gflush (gd)
        call amovi (wcs_save, Memi[GP_WCSPTR(gd,1)], LEN_WCSARRAY)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

        call sfree (sp)
end
