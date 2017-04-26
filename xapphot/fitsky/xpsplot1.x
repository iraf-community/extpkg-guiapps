include <gset.h>
include "../lib/fitsky.h"
include <gio.h>


# XP_SPLOT1 -- Plot the selected sky plot.

procedure xp_splot1 (gd, xp, plottype, wcs)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xapphot structure
int	plottype		#I the default plottype
int	wcs			#I the input wcs

int	i
int	xp_stati(), xp_sradplot(), xp_spaplot(), xp_shistplot()
pointer	xp_statp()
real	xp_statr()
int	wcs_save[LEN_WCSARRAY]

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no object.
	if (IS_INDEFR(xp_statr (xp,SXCUR)) || IS_INDEFR(xp_statr(xp,SYCUR)))
	    return

	# Store the wcs for raster 1. This is a system interface violation
	# but is necessary for the moment until a proper system routine
	# is provided.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Clear the screen.
	call gclear (gd)

	# Set the WCS and viewport for the radial plot.
	if (xp_stati (xp, NSKYPIX) > 0) {

	    switch (plottype) {
	    case SKYPLOT_RADIUS:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.1, 0.95, 0.10, 0.90)
	        if (xp_sradplot (gd,  Memr[xp_statp(xp,SKYPIX)],
	            Memi[xp_statp(xp,SCOORDS)], Memi[xp_statp(xp,SINDEX)+
	            xp_stati(xp,SILO)-1], xp_stati(xp,NSKYPIX)-xp_stati(xp,
		    SILO)+1, xp_statr(xp,SXCUR), xp_statr(xp,SYCUR),
		    xp_statr(xp,SXC), xp_statr(xp,SYC), xp_stati(xp,SNX),
		    xp_stati(xp,SNY), xp_statr(xp,SKY_MODE),
		    xp_statr(xp,SKY_STDEV)) == ERR)
	            ;

	    # Set the WCS and viewport for the position angle plot.
	    case SKYPLOT_PA:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.1, 0.95, 0.10, 0.90)
	        if (xp_spaplot (gd,  Memr[xp_statp(xp,SKYPIX)],
	            Memi[xp_statp(xp,SCOORDS)], Memi[xp_statp(xp,SINDEX)+
	            xp_stati(xp,SILO)-1], xp_stati(xp,NSKYPIX)-
		    xp_stati(xp,SILO)+1, xp_statr(xp,SXCUR), xp_statr(xp,SYCUR),
		    xp_statr(xp,SXC), xp_statr(xp,SYC), xp_stati(xp,SNX),
		    xp_stati(xp,SNY), xp_statr(xp,SKY_MODE), xp_statr(xp,
		    SKY_STDEV)) == ERR)
	            ;

	    # Set the WCS and viewport for the histogram plot.
	    case SKYPLOT_HISTOGRAM:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.1, 0.95, 0.10, 0.90)
	        if (xp_shistplot(gd,  Memr[xp_statp(xp,SKYPIX)],
	            Memr[xp_statp (xp,SWEIGHTS)], Memi[xp_statp (xp,SINDEX)+
	            xp_stati(xp,SILO)-1], xp_stati(xp,NSKYPIX)-
		    xp_stati(xp,SILO)+1, xp_statr(xp,SHWIDTH), INDEFR,
		    xp_statr(xp,SHBINSIZE), xp_stati(xp,SHSMOOTH), xp_statr(xp,
		    SKY_MODE), xp_statr(xp,SKY_STDEV)) == ERR)
	            ;
	    }
	}

	# Restore the wcs for raster 1. This is a system interface violation
	# but is necessary for the moment until a proper system routine
	# is provided.
	call gflush (gd)
	do i = 1, wcs - 1
	    call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
	        LEN_WCS)
	do i = wcs + 1, MAX_WCS
	    call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
	        LEN_WCS)
	GP_WCSSTATE(gd) = MODIFIED
	call gpl_cache (gd)
end
