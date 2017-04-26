include <gset.h>
include "../lib/display.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "uipars.h"

# XP_UDOPLOTS -- Procedure to draw the GUI plots.

procedure xp_udoplots (gd, ui, xp, im, psymbol, oxver, oyver, nover, sxver,
	syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface structure
pointer	xp			# pointer to the xapphot structure
pointer	im			# the image descriptor
pointer	psymbol			# pointer to the last measured list object
real	oxver[ARB]		# the object polygon x coordinates
real	oyver[ARB]		# the object polygon y coordinates
int	nover			# the number of object polygon vertices
real	sxver[ARB]		# the sky polygon x coordinates
real	syver[ARB]		# the sky polygon y coordinates
int	nsver			# the number of sky polygon vertices

int	mkmark
real	width
int	xp_stati()
real	xp_plimits(), xp_slimits(), xp_statr()

begin
	# Plot the object region.
	call gmsg (gd, UI_GTERM(ui), UI_VOBJREGIONPLOT)
	if (psymbol == NULL)
	    width = xp_plimits (xp, NULL, oxver, oyver, nover)
	else
	    width = xp_plimits (xp, psymbol, oxver, oyver, nover)

	switch (UI_OBJDISPLAY(ui)) {
	case OBJPLOT_OBJECT:
	    if (psymbol == NULL)
	        call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, NO)
	    else
	        call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, NO)

	case OBJPLOT_OVERLAY:
	    if (psymbol == NULL)
	        call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, YES)
	    else
	        call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, YES)

	case OBJPLOT_APERTURE:
	    mkmark = xp_stati (xp, PHOTMARK)
	    call xp_seti (xp, PHOTMARK, YES)
	    if (psymbol == NULL) {
	        call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, NO)
	        call xp_apmark (gd, xp, oxver, oyver, nover,
		    OBJPLOT_DISPLAY_WCS, OBJPLOT_DISPLAY_WCS)
	    } else {
		call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, NO)
		call xp_oapmark (gd, xp, psymbol, oxver, oyver, nover,
		    OBJPLOT_DISPLAY_WCS, OBJPLOT_DISPLAY_WCS)
	    }
	    call xp_seti (xp, PHOTMARK, mkmark)

	case OBJPLOT_MOMENTS:
	    if (psymbol == NULL)
	         call xp_cpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
	             xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		     OBJPLOT_DISPLAY_WCS, NO, NO)
	    else
	        call xp_ocpdisplay (gd, xp, im, xp_statr(xp, PXCUR),
	            xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS, NO, NO)

	case OBJPLOT_CONTOUR:
	    if (psymbol == NULL)
                call xp_cpplot (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS)
	    else
                call xp_ocpplot (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS)

	case OBJPLOT_SURFACE:
	    if (psymbol == NULL)
                call xp_asplot (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS)
	    else
                call xp_oasplot (gd, xp, im, xp_statr(xp, PXCUR),
		    xp_statr(xp,PYCUR), width, OBJPLOT_DISPLAY_WCS,
		    OBJPLOT_DISPLAY_WCS)
	}


	# Plot the sky region.
	call gmsg (gd, UI_GTERM(ui), UI_VSKYREGIONPLOT)
	if (psymbol == NULL)
	    width = xp_slimits (xp, NULL, sxver, syver, nsver)
	else
	    width = xp_slimits (xp, psymbol, sxver, syver, nsver)

	switch (UI_SKYDISPLAY(ui)) {
	case SKYPLOT_OBJECT:
	    if (psymbol == NULL)
	         call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		     xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		     SKYPLOT_DISPLAY_WCS, NO, NO)
	    else
	         call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		     xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		     SKYPLOT_DISPLAY_WCS, NO, NO)

	case SKYPLOT_OVERLAY:
	    if (psymbol == NULL)
	        call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS, NO, YES)
	    else
	        call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS, NO, YES)

	case SKYPLOT_APERTURE:
	    mkmark = xp_stati(xp, SKYMARK)
	    call xp_seti (xp, SKYMARK, YES)
	    if (psymbol == NULL) {
		call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS, NO, NO)
		call xp_smark (gd, xp, sxver, syver, nsver, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS)
	    } else {
		call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS, NO, NO)
		call xp_osmark (gd, xp, psymbol, sxver, syver, nsver,
		    SKYPLOT_DISPLAY_WCS, SKYPLOT_DISPLAY_WCS)
	    }
	    call xp_seti (xp, SKYMARK, mkmark)

	case SKYPLOT_CONTOUR:
	    if (psymbol == NULL)
                call xp_cpplot (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS)
	    else
                call xp_ocpplot (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS)

	case SKYPLOT_SURFACE:
	    if (psymbol == NULL)
	        call xp_asplot (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS)
	    else
		call xp_oasplot (gd, xp, im, xp_statr(xp, SXCUR),
		    xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
		    SKYPLOT_DISPLAY_WCS)
	}

	# Plot the photometry and sky results.

	call gmsg (gd, UI_GTERM(ui), UI_VOBJECTPLOT)
	switch (UI_OBJPLOTS(ui)) {
	case OBJPLOT_RADIUS:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
	case OBJPLOT_PA:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_PA, OBJPLOT_PA_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_PA, OBJPLOT_PA_WCS)
	case OBJPLOT_COG:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_COG, OBJPLOT_COG_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_COG, OBJPLOT_COG_WCS)
	case OBJPLOT_MHWIDTH:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
	case OBJPLOT_MAXRATIO:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
	case OBJPLOT_MPOSANGLE:
	    if (psymbol == NULL)
	        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		    OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
	    else
	        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver, nover,
	            OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
	}
		

	call gmsg (gd, UI_GTERM(ui), UI_VSKYPLOT)
	switch (UI_SKYPLOTS(ui)) {
	case SKYPLOT_RADIUS:
	    call xp_splot1 (gd, xp, SKYPLOT_RADIUS, SKYPLOT_RADIUS_WCS)
	case SKYPLOT_PA:
	    call xp_splot1 (gd, xp, SKYPLOT_PA, SKYPLOT_PA_WCS)
	case SKYPLOT_HISTOGRAM:
	    call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM, SKYPLOT_HISTOGRAM_WCS)
	}

	call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
	call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
	#call gflush (gd)
end
