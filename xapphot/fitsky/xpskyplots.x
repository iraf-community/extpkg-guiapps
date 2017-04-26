include <gio.h>
include "../lib/fitsky.h"

# XP_RSKYPLOTS -- Plot the sky region in various ways.

procedure xp_rskyplots (gd, xp, im, psymbol, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	sxver[ARB]		# sky polygon x vertices
real	syver[ARB]		# sky polygon y vertices
int	nsver			# number of vertices

int	wcs, key, marksky, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy, width
int	clgcur(), xp_stati()
real	xp_slimits(), xp_statr()

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

	    case 'o':
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

	    case 'a':
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

	    case 'c':
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

	    case 's':
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


# XP_SKYPLOTS -- Plot the sky analysis results in various ways.

procedure xp_skyplots (gd, xp, im, psymbol, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the xapphot descriptor
pointer	im			# pointer to the input image
pointer	psymbol			# the symbol of the last object measured
real	sxver[ARB]		# sky polygon x vertices
real	syver[ARB]		# sky polygon y vertices
int	nsver			# number of vertices

int	wcs, key, wcs_save[LEN_WCSARRAY]
pointer	sp, cmd
real	wx, wy
int	clgcur(),

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
	        call xp_splot1 (gd, xp, SKYPLOT_RADIUS, SKYPLOT_ANALYSIS_WCS)

	    case 't':
	        call xp_splot1 (gd, xp, SKYPLOT_PA, SKYPLOT_ANALYSIS_WCS)

	    case 'h':
	        call xp_splot1 (gd, xp, SKYPLOT_HISTOGRAM, SKYPLOT_ANALYSIS_WCS)

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
