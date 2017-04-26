include <gio.h>
include <gset.h>
include "../lib/display.h"
include "../lib/fitsky.h"
include "uipars.h"

# XP_USKYPLOTS -- Plots the sky information in various ways.

procedure xp_uskyplots (gd, ui, xp, im, psymbol, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	sxver[ARB]		# sky polygon x vertices
real	syver[ARB]		# sky polygon y vertices
int	nsver			# number of vertices

int	i, wcs, cwcs, key, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy
int	clgcur()

begin
	if (UI_SHOWPLOTS(ui) == NO)
	    return

        # Save the old wcs structure if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Select a default wcs
	#call gmsg (gd, UI_GTERM(ui), UI_VSKYPLOT)
	switch (UI_SKYPLOTS(ui)) {
	case SKYPLOT_RADIUS:
	    wcs = SKYPLOT_RADIUS_WCS
	case SKYPLOT_PA:
	    wcs = SKYPLOT_PA_WCS
	case SKYPLOT_HISTOGRAM:
	    wcs = SKYPLOT_HISTOGRAM_WCS
	}
	#call gseti (gd, G_WCS, wcs)

        # Zero out the other wcs.
        do i = 1, wcs - 1
	    call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        do i = wcs + 1, MAX_WCS
	    call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	while (clgcur ("gcommands", wx, wy, cwcs, key, Memc[cmd], SZ_LINE) !=
	    EOF) {


	    switch (key) {

	    # Quit sky analysis plots menu.
	    case 'q':
		#call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		#call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
		#call gflush (gd)
		break

	    # Redraw current plot.
	    case 'g':
		switch (UI_SKYPLOTS(ui)) {
		case SKYPLOT_RADIUS:
	            #call xp_splot1 (gd, xp, SKYPLOT_RADIUS, SKYPLOT_RADIUS_WCS)
	            call xp_splot1 (gd, xp, SKYPLOT_RADIUS, wcs)
		case SKYPLOT_PA:
	            #call xp_splot1 (gd, xp, SKYPLOT_PA, SKYPLOT_PA_WCS)
	            call xp_splot1 (gd, xp, SKYPLOT_PA, wcs)
		case SKYPLOT_HISTOGRAM:
	            #call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM,
		        #SKYPLOT_HISTOGRAM_WCS)
	            call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM, wcs)
		}

	    # Radial profile.
	    case 'r':
		if (UI_SKYPLOTS(ui) == SKYPLOT_RADIUS)
		    next
	        #call xp_splot1 (gd, xp, SKYPLOT_RADIUS, SKYPLOT_RADIUS_WCS)
	        call xp_splot1 (gd, xp, SKYPLOT_RADIUS, wcs)
		UI_SKYPLOTS(ui) = SKYPLOT_RADIUS

	    # Position angle profile.
	    case 't':
		if (UI_SKYPLOTS(ui) == SKYPLOT_PA)
		    next
	        #call xp_splot1 (gd, xp, SKYPLOT_PA, SKYPLOT_PA_WCS)
	        call xp_splot1 (gd, xp, SKYPLOT_PA, wcs)
		UI_SKYPLOTS(ui) = SKYPLOT_PA

	    # Histogram.
	    case 'h':
		if (UI_SKYPLOTS(ui) == SKYPLOT_HISTOGRAM)
		    next
	        #call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM,
		    #SKYPLOT_HISTOGRAM_WCS)
	        call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM, wcs)
		UI_SKYPLOTS(ui) = SKYPLOT_HISTOGRAM

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


# XP_URSKYPLOTS -- Plots the sky information in various ways.

procedure xp_urskyplots (gd, ui, xp, im, psymbol, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	sxver[ARB]		# sky polygon x vertices
real	syver[ARB]		# sky polygon y vertices
int	nsver			# number of vertices

int	i, cwcs, key, marksky, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy, width
int	clgcur(), xp_stati()
real	xp_slimits(), xp_statr()

begin
	if (UI_SHOWPLOTS(ui) == NO)
	    return

        # Save the old wcs structure if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	#call gmsg (gd, UI_GTERM(ui), UI_VSKYREGIONPLOT)

        # Zero out the other wcs.
        do i = 1, SKYPLOT_DISPLAY_WCS - 1
	    call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        do i = SKYPLOT_DISPLAY_WCS + 1, MAX_WCS
	    call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	while (clgcur ("gcommands", wx, wy, cwcs, key, Memc[cmd], SZ_LINE) !=
	    EOF) {


	    switch (key) {

	    # Quit sky region plotting menu.
	    case 'q':
		#call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		#call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
		#call gflush (gd)
		break

	    # Redraw current plot.
	    case 'g':
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
		    marksky = xp_stati(xp, SKYMARK)
		    call xp_seti (xp, SKYMARK, YES)
		    if (psymbol == NULL) {
		        call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		            xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			    SKYPLOT_DISPLAY_WCS, NO, NO)
		        call xp_smark (gd, xp, sxver, syver, nsver,
		            SKYPLOT_DISPLAY_WCS, SKYPLOT_DISPLAY_WCS)
		    } else {
		        call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		            xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			    SKYPLOT_DISPLAY_WCS, NO, NO)
		        call xp_osmark (gd, xp, psymbol, sxver, syver, nsver,
		            SKYPLOT_DISPLAY_WCS, SKYPLOT_DISPLAY_WCS)
		    }
		    call xp_seti (xp, SKYMARK, marksky)

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

	    case 'i':
		if (UI_SKYDISPLAY(ui) == SKYPLOT_OBJECT)
		    next
		if (psymbol == NULL) {
		    width = xp_slimits (xp, NULL, sxver, syver, nsver)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, NO)
		} else {
		    width = xp_slimits (xp, psymbol, sxver, syver, nsver)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, NO)
		}
		UI_SKYDISPLAY(ui) = SKYPLOT_OBJECT

	    case 'o':
		if (UI_SKYDISPLAY(ui) == SKYPLOT_OVERLAY)
		    next
		if (psymbol == NULL) {
		    width = xp_slimits (xp, NULL, sxver, syver, nsver)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, YES)
		} else {
		    width = xp_slimits (xp, psymbol, sxver, syver, nsver)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, YES)
		}
		UI_SKYDISPLAY(ui) = SKYPLOT_OVERLAY

	    case 'a':
		if (UI_SKYDISPLAY(ui) == SKYPLOT_APERTURE)
		    next
		marksky = xp_stati(xp, SKYMARK)
		call xp_seti (xp, SKYMARK, YES)
		if (psymbol == NULL) {
		    width = xp_slimits (xp, NULL, sxver, syver, nsver)
		    call xp_cpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, NO)
		    call xp_smark (gd, xp, sxver, syver, nsver,
		        SKYPLOT_DISPLAY_WCS, SKYPLOT_DISPLAY_WCS)
		} else {
		    width = xp_slimits (xp, psymbol, sxver, syver, nsver)
		    call xp_ocpdisplay (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS, NO, NO)
		    call xp_osmark (gd, xp, psymbol, sxver, syver, nsver,
		        SKYPLOT_DISPLAY_WCS, SKYPLOT_DISPLAY_WCS)
		}
		call xp_seti (xp, SKYMARK, marksky)
		UI_SKYDISPLAY(ui) = SKYPLOT_APERTURE

	    case 'c':
		if (UI_SKYDISPLAY(ui) == SKYPLOT_CONTOUR)
		    next
		if (psymbol == NULL) {
		    width = xp_slimits (xp, NULL, sxver, syver, nsver)
                    call xp_cpplot (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS)
		} else {
		    width = xp_slimits (xp, psymbol, sxver, syver, nsver)
                    call xp_ocpplot (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS)
		}
		UI_SKYDISPLAY(ui) = SKYPLOT_CONTOUR

	    case 's':
		if (UI_SKYDISPLAY(ui) == SKYPLOT_SURFACE)
		    next
		if (psymbol == NULL) {
		    width = xp_slimits (xp, NULL, sxver, syver, nsver)
		    call xp_asplot (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS)
	        } else {
		    width = xp_slimits (xp, psymbol, sxver, syver, nsver)
		    call xp_oasplot (gd, xp, im, xp_statr(xp, SXCUR),
		        xp_statr(xp,SYCUR), width, SKYPLOT_DISPLAY_WCS,
			SKYPLOT_DISPLAY_WCS)
		}
		UI_SKYDISPLAY(ui) = SKYPLOT_SURFACE

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
