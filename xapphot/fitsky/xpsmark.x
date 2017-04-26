include <math.h>
include <gset.h>
include <gim.h>
include "../lib/objects.h"
include "../lib/impars.h"
include "../lib/fitsky.h"


# XP_SMARK -- Mark the sky annulus on the image display.

procedure xp_smark (gd, xp, xver, yver, nver, raster, wcs)

pointer	gd		#I pointer to the graphics stream
pointer	xp		#I pointer to the main xapphot structure
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices
int	raster		#I the raster coordinate system to be used
int	wcs		#I the current wcs

int	xp_stati()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, SKYMARK) == NO)
	    return

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Do the actual marking.
	call xp_ssmark (gd, xp, xver, yver, nver)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_SSMARK -- Do the actual marking.

procedure xp_ssmark (gd, xp, xver, yver, nver)

pointer	gd		#I pointer to the graphics stream
pointer	xp		#I pointer to the main xapphot structure
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices

int	ocolor, oltype, omtype
pointer	sp, txver, tyver
real	srannulus, swannulus, theta, ratio, xshift, yshift
bool	fp_equalr()
int	gstati(), xp_stati()
real	xp_statr(), asumr()

begin
	if (IS_INDEFR(xp_statr(xp,SXCUR)) || IS_INDEFR(xp_statr(xp,SYCUR)))
	    return

	# Store the old color, marker type, and line type.
	ocolor = gstati (gd, G_PLCOLOR)
	oltype = gstati (gd, G_PLTYPE)
	omtype = gstati (gd, G_PMLTYPE)

	# Set the color.
	switch (xp_stati (xp, SCOLORMARK)) {
	case XP_SMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_SMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_SMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_SMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)
	call gseti (gd, G_PLTYPE, GL_SOLID)

	if (xp_stati(xp, SOMODE) == XP_SCONCENTRIC) {
	    srannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SORANNULUS)
	    swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SOWANNULUS)
	} else {
	    if (xp_stati (xp,SOGEOMETRY) == XP_SPOLYGON) {
	        srannulus = 0.0
	        swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SOWANNULUS)
	    } else {
	        srannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SORANNULUS)
	        swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SOWANNULUS)
	    }
	}
	theta = xp_statr (xp, SOPOSANGLE)
	ratio = xp_statr (xp, SOAXRATIO)

	switch (xp_stati (xp, SOGEOMETRY)) {

	case XP_SCIRCLE:
	    if (srannulus > 0.0)
	        call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	            GM_CIRCLE, -2.0 * srannulus, -2.0 * srannulus)
	    call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	        GM_CIRCLE, -2.0 * (srannulus + swannulus), -2.0 *
		(srannulus + swannulus))

	case XP_SELLIPSE:
	    if (fp_equalr (theta, 0.0) || fp_equalr (theta, 180.0)) {
	        if (srannulus > 0.0)
	            call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	                GM_CIRCLE, -2.0 * srannulus, -2.0 * ratio * srannulus)
	        call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	            GM_CIRCLE, -2.0 * (srannulus + swannulus), -2.0 * ratio *
		    (srannulus + swannulus))
	    } else if (fp_equalr (theta, 90.0) || fp_equalr (theta, 270.0)) {
	        if (srannulus > 0.0)
	            call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	                GM_CIRCLE, -2.0 * ratio * srannulus, -2.0 * srannulus)
	        call gmark (gd, xp_statr (xp, SXCUR), xp_statr (xp, SYCUR),
	            GM_CIRCLE, -2.0 * ratio * (srannulus + swannulus),
		    -2.0 * (srannulus + swannulus))
	    } else {
	        if (srannulus > 0.0)
		    call xp_emark (gd, xp_statr (xp,SXCUR), xp_statr(xp,SYCUR),
		        srannulus, ratio, theta)
		call xp_emark (gd, xp_statr(xp,SXCUR), xp_statr(xp,SYCUR),
		    srannulus + swannulus, ratio, theta)
	    }

	case XP_SRECTANGLE:
	    if (srannulus > 0.0)
		call xp_rmark (gd, xp_statr (xp,SXCUR), xp_statr(xp,SYCUR),
		    srannulus, ratio, theta)
	    call xp_rmark (gd, xp_statr(xp,SXCUR), xp_statr(xp,SYCUR),
		srannulus + swannulus, ratio, theta)
	default:
	    call smark (sp)
	    call salloc (txver, nver, TY_REAL)
	    call salloc (tyver, nver, TY_REAL)
	    xshift = xp_statr (xp, SXCUR) - asumr (xver, nver) / nver
	    yshift = xp_statr (xp, SYCUR) - asumr (yver, nver) / nver
	    if ((srannulus + swannulus) <= 0.0) {
		call aaddkr (xver, xshift, Memr[txver], nver)
		call aaddkr (yver, yshift, Memr[tyver], nver)
		call xp_pmark (gd, Memr[txver], Memr[tyver], nver)
	    } else {
		if (srannulus <= 0.0) {
		    call amovr (xver, Memr[txver], nver)
		    call amovr (yver, Memr[tyver], nver)
		} else
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], 
		        nver,  srannulus)
		call aaddkr (Memr[txver], xshift, Memr[txver], nver)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
		call xp_pmark (gd, Memr[txver], Memr[tyver], nver)
		call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], 
		    nver, srannulus + swannulus)
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


# XP_OSMARK -- Mark the sky annulus on the image display.

procedure xp_osmark (gd, xp, symbol, xver, yver, nver, raster, wcs)

pointer	gd		#I pointer to the graphics stream
pointer	xp		#I pointer to the main xapphot structure
pointer	symbol		#I pointer to the object symbol
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices
int	raster		#I the raster coordinate system to be used
int	wcs		#I the current wcs

pointer	sp, str, spsymbol
int	xp_stati()
pointer	xp_statp(), stfind()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	if (xp_stati (xp, SKYMARK) == NO)
	    return

	if (symbol == NULL)
	    return

        if (XP_OSNPOLYGON(symbol) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
            call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_OSNPOLYGON(symbol))
            spsymbol = stfind (xp_statp(xp,POLYGONLIST), Memc[str])
	    call sfree (sp)
        } else
            spsymbol = 0

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Do the actuall marking.
	if (XP_OSGEOMETRY(symbol) != XP_OPOLYGON)
	    call xp_ssmark (gd, xp, xver, yver, nver)
	else if (IS_INDEFR(XP_OSXINIT(symbol)) || IS_INDEFR(XP_OSYINIT(symbol)))
	    call xp_ossmark (gd, xp, symbol, spsymbol, xp_statr(xp,SXCUR) -
	        XP_OXINIT(symbol), xp_statr(xp,SYCUR) - XP_OYINIT(symbol),
		xver, yver, nver)
	else
	    call xp_ossmark (gd, xp, symbol, spsymbol, xp_statr(xp,SXCUR) -
	        XP_OSXINIT(symbol), xp_statr(xp,SYCUR) - XP_OSYINIT(symbol),
		xver, yver, nver)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_OSSMARK -- Do the actual marking.

procedure xp_ossmark (gd, xp, symbol, psymbol, xshift, yshift, xver, yver, nver)

pointer	gd		#I pointer to the graphics stream
pointer	xp		#I pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer	psymbol		#I the current polygon symbol
real	xshift, yshift	#I the x and y shifts of the sky polygon
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices

int	ocolor, oltype, omtype
real	mksize
int	gstati(), xp_stati()
real	xp_statr()

begin
	if (IS_INDEFR(xp_statr(xp,SXCUR)) || IS_INDEFR(xp_statr(xp,SYCUR)))
	    return

	# Store the old color, marker type, and line type.
	ocolor = gstati (gd, G_PLCOLOR)
	oltype = gstati (gd, G_PLTYPE)
	omtype = gstati (gd, G_PMLTYPE)

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)
	call gseti (gd, G_PLTYPE, GL_SOLID)

	# Set the color.
	switch (xp_stati (xp, SCOLORMARK)) {
	case XP_SMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_SMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_SMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_SMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

        # Set the marker size.
        if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
            mksize = - 2.0 * xp_statr (xp,IHWHMPSF) * xp_statr(xp,ISCALE)
        else
            mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr(xp,ISCALE)

	if (XP_OSGEOMETRY(symbol) == XP_OINDEF)
	    call xp_ssmark (gd, xp, xver, yver, nver)
	else
	    call xp_omkshape (gd, symbol, NULL, psymbol, xshift, yshift,
		xp_statr (xp, ISCALE), NO, YES, mksize)

	# Restore the mark type.
	call gseti (gd, G_PLTYPE, oltype)
	call gseti (gd, G_PMLTYPE, omtype)
	call gseti (gd, G_PLCOLOR, ocolor)
end


# XP_SCOLOR -- Return the gio color corresponding the user determined
# sky aperture marking color.

int procedure xp_scolor (xp)

pointer	xp		#I pointer to the main xapphot structure

int	xp_stati()

begin
	# Set the color.
	switch (xp_stati (xp, SCOLORMARK)) {
	case XP_SMARK_RED:
	    return (RED)
	case XP_SMARK_BLUE:
	    return (BLUE)
	case XP_SMARK_GREEN:
	    return (GREEN)
	case XP_SMARK_YELLOW:
	    return (YELLOW)
	default:
	    return (RED)
	}
end
