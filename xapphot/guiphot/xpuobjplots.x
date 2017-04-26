include <gio.h>
include <gset.h>
include "../lib/display.h"
include "../lib/phot.h"
include "uipars.h"

# XP_UROBJPLOTS -- Plots the object region information in various ways.

procedure xp_urobjplots (gd, ui, xp, im, psymbol, oxver, oyver, nover)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	oxver[ARB]		# sky polygon x vertices
real	oyver[ARB]		# sky polygon y vertices
int	nover			# number of vertices

int	i, cwcs, key, markap, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy, width
int	clgcur(), xp_stati()
real	xp_plimits(), xp_statr()

begin
	if (UI_SHOWPLOTS(ui) == NO)
	    return

        # Save the old wcs structure if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	#call gmsg (gd, UI_GTERM(ui), UI_VOBJREGIONPLOT)

        # Zero out the other wcs.
        do i = 1, OBJPLOT_DISPLAY_WCS - 1
            call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        do i = OBJPLOT_DISPLAY_WCS + 1, MAX_WCS
            call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	while (clgcur ("gcommands", wx, wy, cwcs, key, Memc[cmd], SZ_LINE) !=
	    EOF) {


	    switch (key) {

	    # Quit.
	    case 'q':
		#call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		#call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
		#call gflush (gd)
		break

	    # Replot.
	    case 'g':
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
		    markap = xp_stati(xp, PHOTMARK)
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
		    call xp_seti (xp, PHOTMARK, markap)
		    UI_OBJDISPLAY(ui) = OBJPLOT_APERTURE

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

		default:
		}

	    # Display the object region.
	    case 'i':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_OBJECT)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_OBJECT

	    # Display the object region with contour overlays.
	    case 'o':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_OVERLAY)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_OVERLAY

	    # Display the object region with object aperture overlays.
	    case 'a':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_APERTURE)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_APERTURE

	    # Display the object region with moment analysis overlays.
	    case 'm':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_MOMENTS)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_MOMENTS

	    # Display a contour plot of the region.
	    case 'c':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_CONTOUR)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_CONTOUR

	    # Display a surface plot of the region.
	    case 's':
		if (UI_OBJDISPLAY(ui) == OBJPLOT_SURFACE)
		    next
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
		UI_OBJDISPLAY(ui) = OBJPLOT_SURFACE


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


# XP_UOBJPLOTS -- Plots the sky information in various ways.

procedure xp_uobjplots (gd, ui, xp, im, psymbol, oxver, oyver, nover)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	oxver[ARB]		# sky polygon x vertices
real	oyver[ARB]		# sky polygon y vertices
int	nover			# number of vertices

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

	#call gmsg (gd, UI_GTERM(ui), UI_VOBJECTPLOT)

	switch (UI_OBJPLOTS(ui)){
	case OBJPLOT_RADIUS:
	    wcs = OBJPLOT_RADIUS_WCS
	case OBJPLOT_PA:
	    wcs = OBJPLOT_PA_WCS
	case OBJPLOT_COG:
	    wcs = OBJPLOT_COG_WCS
	case OBJPLOT_MAXRATIO:
	    wcs = OBJPLOT_MAXRATIO_WCS
	case OBJPLOT_MPOSANGLE:
	    wcs = OBJPLOT_MPOSANGLE_WCS
	case OBJPLOT_MHWIDTH:
	    wcs = OBJPLOT_MHWIDTH_WCS
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

	    case 'q':
		#call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		#call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
		#call gflush (gd)
		break

	    case 'g':
		switch (UI_OBJPLOTS(ui)) {
		case OBJPLOT_RADIUS:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_RADIUS, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
			    #nover, OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
			    nover, OBJPLOT_RADIUS, wcs)

		case OBJPLOT_PA:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_PA, OBJPLOT_PA_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_PA, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            #nover, OBJPLOT_PA, OBJPLOT_PA_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            nover, OBJPLOT_PA, wcs)

		case OBJPLOT_COG:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_COG, OBJPLOT_COG_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_COG, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            #nover, OBJPLOT_COG, OBJPLOT_COG_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            nover, OBJPLOT_COG, wcs)

		case OBJPLOT_MAXRATIO:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_MAXRATIO, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            #nover, OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            nover, OBJPLOT_MAXRATIO, wcs)

		case OBJPLOT_MPOSANGLE:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_MPOSANGLE, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            #nover, OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            nover, OBJPLOT_MPOSANGLE, wcs)

		case OBJPLOT_MHWIDTH:
		    if (psymbol == NULL)
		        #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            #OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
		        call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		            OBJPLOT_MHWIDTH, wcs)
		    else
		        #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            #nover, OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
		        call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		            nover, OBJPLOT_MHWIDTH, wcs)

		default:
		    ;
		}

	    case 'r':
		if (UI_OBJPLOTS(ui) == OBJPLOT_RADIUS)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_RADIUS, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_RADIUS, OBJPLOT_RADIUS_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_RADIUS, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_RADIUS

	    case 't':
		if (UI_OBJPLOTS(ui) == OBJPLOT_PA)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_PA, OBJPLOT_PA_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_PA, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_PA, OBJPLOT_PA_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_PA, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_PA

	    case 'c':
		if (UI_OBJPLOTS(ui) == OBJPLOT_COG)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_COG, OBJPLOT_COG_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_COG, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_COG, OBJPLOT_COG_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_COG, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_COG

	    case 'e':
		if (UI_OBJPLOTS(ui) == OBJPLOT_MAXRATIO)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MAXRATIO, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_MAXRATIO, OBJPLOT_MAXRATIO_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MAXRATIO, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_MAXRATIO

	    case 'p':
		if (UI_OBJPLOTS(ui) == OBJPLOT_MPOSANGLE)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MPOSANGLE, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_MPOSANGLE, OBJPLOT_MPOSANGLE_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MPOSANGLE, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_MPOSANGLE

	    case 'w':
		if (UI_OBJPLOTS(ui) == OBJPLOT_MHWIDTH)
		    next
		if (psymbol == NULL)
		    #call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        #OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
		    call xp_aplot1 (gd, im, xp, oxver, oyver, nover,
		        OBJPLOT_MHWIDTH, wcs)
		else
		    #call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        #nover, OBJPLOT_MHWIDTH, OBJPLOT_MHWIDTH_WCS)
		    call xp_oaplot1 (gd, im, xp, psymbol, oxver, oyver,
		        nover, OBJPLOT_MHWIDTH, wcs)
		UI_OBJPLOTS(ui) = OBJPLOT_MHWIDTH

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
