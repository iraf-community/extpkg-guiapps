include <gset.h>
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/phot.h"
include <gio.h>


# XP_APLOT1 -- Draw the object plots.

procedure xp_aplot1 (gd, im, xp, xver, yver, nver, plottype, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the y coordinates of the polygon vertices
int	nver			#I the number of vertices
int	plottype		#I the type of plot
int	wcs			#I the input wc

int	i
int	xp_stati(), xp_araplot(), xp_acogplot(), xp_ahwplot(), xp_axplot()
int	xp_atplot()
real	xp_statr()
int	wcs_save[LEN_WCSARRAY]

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no data.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 

	# Save the WCS for raster 1, the image raster. Note that this is
	# an interace violation but it might work for now.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Clear the screen.
	call gclear (gd)

	if (xp_stati(xp,NAPIX) > 0) {

	    switch (plottype) {

	    # Plot the radial profile.
	    case OBJPLOT_RADIUS:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
	        if (xp_araplot (gd,  im, xp, xver, yver, nver, wcs, 0) == ERR)
	            ;

	    # Plot the position angle profile.
	    case OBJPLOT_PA:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
	        if (xp_araplot (gd,  im, xp, xver, yver, nver, 0, wcs) == ERR)
	            ;

	    # Plot the magnitude as a function of aperture.
	    case OBJPLOT_COG:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
	        if (xp_acogplot (gd, xp) == ERR)
	            ;

	    # Plot the moment analysis half-width as a function of aperture.
	    case OBJPLOT_MHWIDTH:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (xp_ahwplot (gd, xp) == ERR)
		    ;

	    # Plot the moment analysis axis ratio as a function of aperture.
	    case OBJPLOT_MAXRATIO:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (xp_axplot (gd, xp) == ERR)
		    ;

	    # Plot the moment analysis position angle as a function of aperture.
	    case OBJPLOT_MPOSANGLE:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (xp_atplot (gd, xp) == ERR)
		    ;
	    }
	}

	# Restore the WCS for raster 1, the image raster. Note that this is
	# an interace violation but it might work for now.
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


# XP_OAPLOT1 -- Draw the object plots.

procedure xp_oaplot1 (gd, im, xp, symbol, xver, yver, nver, plottype, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure
pointer	symbol			#I the current object symbol
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the y coordinates of the polygon vertices
int	nver			#I the number of vertices
int	plottype		#I the type of plot
int	wcs			#I the input wcs

int	i
pointer	sp, str, opsymbol
int	xp_stati(), xp_oaraplot(), xp_oacogplot(), xp_oahwplot(), xp_oaxplot()
int	xp_oatplot(), xp_araplot()
pointer	stfind(), xp_statp()
real	xp_statr()
int	wcs_save[LEN_WCSARRAY]

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no data.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 

	# Return if there is no symbol
	if (symbol == NULL)
	    return
	if (XP_ONPOLYGON(symbol) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	    call sfree (sp)
	} else
	    opsymbol = NULL

	# Save the WCS for raster 1, the image raster. Note that this is
	# an interace violation but it might work for now.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Clear the screen.
	call gclear (gd)

	if (xp_stati(xp,NAPIX) > 0) {

	    switch (plottype) {

	    # Plot the radial profile.
	    case OBJPLOT_RADIUS:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (XP_OGEOMETRY(symbol) == XP_OINDEF) { 
	            if (xp_araplot (gd, im, xp, xver, yver, nver,
		        wcs, 0) == ERR)
			;
	        } else if (xp_oaraplot (gd,  im, xp, symbol, opsymbol,
		    xp_statr (xp, XSHIFT), xp_statr (xp, YSHIFT), xver,
		    yver, nver, wcs, 0) == ERR)
	            ;

	    # Plot the position angle profile.
	    case OBJPLOT_PA:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (XP_OGEOMETRY(symbol) == XP_OINDEF) { 
	            if (xp_araplot (gd, im, xp, xver, yver, nver,
		        0, wcs) == ERR)
			;
		} else if (xp_oaraplot (gd, im, xp, symbol, opsymbol,
		    xp_statr (xp, XSHIFT), xp_statr (xp, YSHIFT), xver,
		    yver, nver, 0, wcs) == ERR)
	            ;

	    # Plot the magnitude versus aperture.
	    case OBJPLOT_COG:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
	        if (xp_oacogplot (gd, xp, symbol, opsymbol) == ERR)
	            ;

	    # Plot the moment analysis half-width versus aperture.
	    case OBJPLOT_MHWIDTH:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
                if (xp_oahwplot (gd,  xp, symbol, opsymbol) == ERR)
                    ;

	    # Plot the moment analysis axis ratio versus aperture.
	    case OBJPLOT_MAXRATIO:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
                if (xp_oaxplot (gd,  xp, symbol, opsymbol) == ERR)
                    ;


	    # Plot the moment analysis postion angle versus aperture.
	    case OBJPLOT_MPOSANGLE:
	        call gseti (gd, G_WCS, wcs)
	        call gsview (gd, 0.10, 0.95, 0.10, 0.90)
		if (xp_oatplot (gd, xp, symbol, opsymbol) == ERR)
		    ;
	    }

	}

	# Restore the WCS for raster 1, the image raster. Note that this is
	# an interace violation but it might work for now.
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
