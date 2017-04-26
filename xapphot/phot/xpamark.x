include <gset.h>
include <gim.h>
include "../lib/objects.h"
include "../lib/impars.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

# XP_AMARK -- Mark the photometry apertures on the image display.

procedure xp_amark (gd, xp, oxver, oyver, nover, sxver, syver, nsver,
	raster, wcs)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
real	oxver[ARB]	#I the x coordinates of the object polygon vertices
real	oyver[ARB]	#I the y coordinates of the object polygon vertices
int	nover		#I the number of object polygon vertices
real	sxver[ARB]	#I the x coordinates of the sky polygon vertices
real	syver[ARB]	#I the y coordinates of the sky polygon vertices
int	nsver		#I the number of sky polygon vertices
int	raster		#I the raster coordinate system to be used
int	wcs

int	xp_stati()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, CTRMARK) == NO && xp_stati (xp, SKYMARK) == NO &&
	    xp_stati (xp, PHOTMARK) == NO)
	    return

	# Set the coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	if (xp_stati (xp, CTRMARK) == YES)
	    call xp_ccmark (gd, xp)
	if (xp_stati (xp, SKYMARK) == YES)
	    call xp_ssmark (gd, xp, sxver, syver, nsver)
	if (xp_stati (xp, PHOTMARK) == YES)
	    call xp_aamark (gd, xp, oxver, oyver, nover)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_APMARK -- Mark the photometry apertures on the image display.

procedure xp_apmark (gd, xp, oxver, oyver, nover, raster, wcs)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
real	oxver[ARB]	#I the x coordinates of the object polygon vertices
real	oyver[ARB]	#I the y coordinates of the object polygon vertices
int	nover		#I the number of object polygon vertices
int	raster		#I the raster coordinate system to be used
int	wcs

int	xp_stati()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, PHOTMARK) == NO)
	    return

	# Set the coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Mark the plot.
	call xp_aamark (gd, xp, oxver, oyver, nover)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_AAMARK -- Actually do the marking.

procedure xp_aamark (gd, xp, xver, yver, nver)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices

int	i, ocolor, oltype, omtype, naperts
pointer	sp, txver, tyver
real	theta, ratio, rapert, xshift, yshift
bool	fp_equalr()
int	gstati(), xp_stati()
pointer	xp_statp()
real	xp_statr(), asumr()

begin
	if (IS_INDEFR(xp_statr(xp,PXCUR)) || IS_INDEFR(xp_statr(xp,PYCUR)))
	    return

	# Store the old color, marker type, and line type.
	ocolor = gstati (gd, G_PLCOLOR)
	oltype = gstati (gd, G_PLTYPE)
	omtype = gstati (gd, G_PMLTYPE)

	# Set the color.
	switch (xp_stati (xp, PCOLORMARK)) {
	case XP_AMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_AMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_AMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_AMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)
	call gseti (gd, G_PLTYPE, GL_SOLID)

	naperts = xp_stati(xp,NAPERTS)
	theta = xp_statr (xp, PPOSANGLE)
	ratio = xp_statr (xp, PAXRATIO)

	switch (xp_stati (xp, PGEOMETRY)) {

	case XP_ACIRCLE:
	    do i = naperts, naperts {
		rapert = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,
		    PAPERTURES)+i-1]
	        call gmark (gd, xp_statr (xp, PXCUR), xp_statr (xp, PYCUR),
	            GM_CIRCLE, -2.0 * rapert, -2.0 * rapert)
	    }

	case XP_AELLIPSE:
	    if (fp_equalr (theta, 0.0) || fp_equalr (theta, 180.0)) {
	        do i = naperts, naperts {
		    rapert = xp_statr (xp, ISCALE) *
		        Memr[xp_statp(xp,PAPERTURES)+i-1]
	            call gmark (gd, xp_statr (xp, PXCUR), xp_statr (xp, PYCUR),
	                GM_CIRCLE, -2.0 * rapert, -2.0 * ratio * rapert)
	        }
	    } else if (fp_equalr (theta, 90.0) || fp_equalr (theta, 270.0)) {
	        do i = naperts, naperts {
		    rapert = xp_statr (xp, ISCALE) *
		        Memr[xp_statp(xp,PAPERTURES)+i-1]
	            call gmark (gd, xp_statr (xp, PXCUR), xp_statr (xp, PYCUR),
	                GM_CIRCLE, -2.0 * ratio * rapert, -2.0 * rapert)
	        }
	    } else {
	        do i = naperts, naperts {
		    rapert = xp_statr (xp, ISCALE) *
		        Memr[xp_statp(xp,PAPERTURES)+i-1]
		    call xp_emark (gd, xp_statr(xp,PXCUR), xp_statr(xp,PYCUR),
		        rapert, ratio, theta)
		}
	    }

	case XP_ARECTANGLE:
	    do i = naperts, naperts {
		rapert = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,
		    PAPERTURES)+i-1]
		call xp_rmark (gd, xp_statr(xp,PXCUR), xp_statr(xp,PYCUR),
		    rapert, ratio, theta)
	    }

	default:
	    call smark (sp)
	    call salloc (txver, nver + 1, TY_REAL)
	    call salloc (tyver, nver + 1, TY_REAL)
	    xshift = xp_statr (xp, PXCUR) - asumr (xver, nver) / nver
	    yshift = xp_statr (xp, PYCUR) - asumr (yver, nver) / nver
	    do i = naperts, naperts {
		if (xp_stati(xp,NAPERTS) == 1) {
		    call amovr (xver, Memr[txver], nver)
		    call amovr (yver, Memr[tyver], nver)
		} else {
		    rapert = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,
		        PAPERTURES)+i-1]
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], 
		        nver,  rapert)
		}
		call aaddkr (Memr[txver], xshift, Memr[txver], nver)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
		call xp_pmark (gd, Memr[txver], Memr[tyver], nver)
	    }
	    call sfree (sp)
	}

	# Restore the mark type.
        call gseti (gd, G_PLTYPE, oltype)
        call gseti (gd, G_PMLTYPE, omtype)
        call gseti (gd, G_PLCOLOR, ocolor)
end


# XP_OAMARK -- Mark the photometry apertures on the image display.

procedure xp_oamark (gd, xp, symbol, oxver, oyver, nover, sxver, syver, nsver,
	raster, wcs)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the pointer to the current object
real	oxver[ARB]	#I the x coordinates of the object polygon vertices
real	oyver[ARB]	#I the y coordinates of the object polygon vertices
int	nover		#I the number of object polygon vertices
real	sxver[ARB]	#I the x coordinates of the sky polygon vertices
real	syver[ARB]	#I the y coordinates of the sky polygon vertices
int	nsver		#I the number of sky polygon vertices
int	raster		#I the raster coordinate system to be used
int	wcs

pointer	sp, str, spsymbol, opsymbol
int	xp_stati()
pointer	xp_statp(), stfind()
real	xp_statr()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, CTRMARK) == NO && xp_stati (xp, SKYMARK) == NO &&
	    xp_stati (xp, PHOTMARK) == NO)
	    return

	if (symbol == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	if (XP_ONPOLYGON(symbol) > 0) {
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	} else
	    opsymbol = NULL
        if (XP_OSNPOLYGON(symbol) > 0) {
            call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_OSNPOLYGON(symbol))
            spsymbol = stfind (xp_statp(xp,POLYGONLIST), Memc[str])
        } else
            spsymbol = NULL
	call sfree (sp)

	# Set the coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	if (xp_stati (xp, CTRMARK) == YES)
	    call xp_occmark (gd, xp, symbol, opsymbol)
	if (xp_stati (xp, SKYMARK) == YES) {
	    if (IS_INDEFR(XP_OSXINIT(symbol)) || IS_INDEFR(XP_OSYINIT(symbol)))
	        call xp_ossmark (gd, xp, symbol, spsymbol, xp_statr (xp,
		    XSHIFT), xp_statr (xp, YSHIFT), sxver, syver, nsver)
	    else
	        call xp_ossmark (gd, xp, symbol, spsymbol, xp_statr(xp,
		    SXCUR) - XP_OSXINIT(symbol), xp_statr (xp, SYCUR) -
		    XP_OSYINIT(symbol), sxver, syver, nsver)
	}
	if (xp_stati (xp, PHOTMARK) == YES)
	    call xp_oaamark (gd, xp, symbol, opsymbol, xp_statr (xp, XSHIFT),
	        xp_statr (xp, YSHIFT), oxver, oyver, nover)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_OAPMARK -- Mark the photometry apertures on the image display.

procedure xp_oapmark (gd, xp, symbol, oxver, oyver, nover, raster, wcs)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the pointer to the current object
real	oxver[ARB]	#I the x coordinates of the object polygon vertices
real	oyver[ARB]	#I the y coordinates of the object polygon vertices
int	nover		#I the number of object polygon vertices
int	raster		#I the raster coordinate system to be used
int	wcs

pointer	sp, str, opsymbol
int	xp_stati()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, PHOTMARK) == NO)
	    return

        # Get the polygon symbol if any.
        if (XP_ONPOLYGON(symbol) > 0) {
            call smark (sp)
            call salloc (str, SZ_FNAME, TY_CHAR)
            call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
            call sfree (sp)
        } else
            opsymbol = NULL

	# Set the coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Mark the object.
	call xp_oaamark (gd, xp, symbol, opsymbol, xp_statr (xp, XSHIFT),
	    xp_statr (xp, YSHIFT), oxver, oyver, nover)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_OAAMARK -- Actually do the marking.

procedure xp_oaamark (gd, xp, symbol, psymbol, xshift, yshift, xver, yver, nver)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer psymbol		#I the current polygon symbol
real	xshift, yshift	#I the polygon x and y shift
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices

int	ocolor, oltype, omtype
real	mksize
int	gstati(), xp_stati()
real	xp_statr()

begin
	if (IS_INDEFR(xp_statr(xp,PXCUR)) || IS_INDEFR(xp_statr(xp,PYCUR)))
	    return

	# Store the old color, marker type, and line type.
	ocolor = gstati (gd, G_PLCOLOR)
	oltype = gstati (gd, G_PLTYPE)
	omtype = gstati (gd, G_PMLTYPE)

	# Set the color.
	switch (xp_stati (xp, PCOLORMARK)) {
	case XP_AMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_AMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_AMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_AMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)
	call gseti (gd, G_PLTYPE, GL_SOLID)

        # Set the marker size.
        if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
            mksize = - 2.0 * xp_statr (xp,IHWHMPSF) * xp_statr(xp,ISCALE)
        else
            mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr(xp,ISCALE)

	# Do the marking.
	if (XP_OGEOMETRY(symbol) == XP_OINDEF)
	    call xp_aamark (gd, xp, xver, yver, nver)
	else
	    call xp_omkshape (gd, symbol, psymbol, NULL, xshift, yshift,
		xp_statr (xp, ISCALE), YES, NO, mksize)

	# Restore the mark type.
        call gseti (gd, G_PLTYPE, oltype)
        call gseti (gd, G_PMLTYPE, omtype)
        call gseti (gd, G_PLCOLOR, ocolor)
end


# XP_ACOLOR -- Return the gio color corresponding the user set aperture
# marking color.

int procedure xp_acolor (xp)

pointer	xp			#I the pointer to the main xapphot structure

int	xp_stati()

begin
	switch (xp_stati (xp, PCOLORMARK)) {
	case XP_AMARK_RED:
	    return (RED)
	case XP_AMARK_BLUE:
	    return (BLUE)
	case XP_AMARK_GREEN:
	    return (GREEN)
	case XP_AMARK_YELLOW:
	    return (YELLOW)
	default:
	    return (RED)
	}
end
