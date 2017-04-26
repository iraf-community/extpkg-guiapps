include <mach.h>
include <math.h>
include <imhdr.h>
include <gset.h>
include "../lib/objects.h"
include "../lib/impars.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

include <gio.h>


# XP_APLOT -- Plot the radial profile plot and histogram of the photometry
# pixels.

procedure xp_aplot (gd, im, xp, xver, yver, nver, wcs1, wcs2, wcs3)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the y coordinates of the polygon vertices
int	nver			#I the number of vertices
int	wcs1			#I the wcs of the first plot
int	wcs2			#I the wcs of the second plot
int	wcs3			#I the wcs of the third plot

int	xp_stati(), xp_araplot(), xp_acogplot()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no object.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 

	# Clear the screen.
	call gclear (gd)

	# Return if there is no data.
	if (xp_stati (xp,NAPIX) <= 0)
	    return

	# Set the WCS and viewport for the radial and position angle plots.
	call gseti (gd, G_WCS, wcs1)
	call gsview (gd, 0.10, 0.95, 0.72, 0.95)
	call gseti (gd, G_WCS, wcs2)
	call gsview (gd, 0.10, 0.95, 0.38, 0.62)
	if (xp_araplot (gd,  im, xp, xver, yver, nver, wcs1, wcs2) == ERR)
	    ;

	call gseti (gd, G_WCS, wcs3)
	call gsview (gd, 0.10, 0.95, 0.05, 0.28)
	if (xp_acogplot (gd, xp) == ERR)
	    ;
end


# XP_EPLOT -- Plot the results of the 2D moments analysis.

procedure xp_eplot (gd, xp, wcs1, wcs2, wcs3)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
int	wcs1			#I the wcs of the first plot
int	wcs2			#I the wcs of the second plot
int	wcs3			#I the wcs of the third plot

int	xp_stati(), xp_ahwplot(), xp_axplot(), xp_atplot()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no object.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 

	# Clear the screen.
	call gclear (gd)

	# Return if there is no data.
	if (xp_stati (xp,NAPIX) <= 0)
	    return

	# Set the WCS and viewport for the half width plot.
	call gseti (gd, G_WCS, wcs1)
	call gsview (gd, 0.10, 0.95, 0.72, 0.95)
	if (xp_ahwplot (gd, xp) == ERR)
	    ;

	# Set the WCS and viewport for the axis ratio plot.
	call gseti (gd, G_WCS, wcs2)
	call gsview (gd, 0.10, 0.95, 0.38, 0.62)
	if (xp_axplot (gd, xp) == ERR)
	    ;

	# Set the WCS and viewport for the position angle plot.
	call gseti (gd, G_WCS, wcs3)
	call gsview (gd, 0.10, 0.95, 0.05, 0.28)
	if (xp_atplot (gd, xp) == ERR)
	    ;
end


# XP_OAPLOT -- Plot the radial profile plot and histogram of the sky pixels.

procedure xp_oaplot (gd, im, xp, symbol, xver, yver, nver, wcs1, wcs2, wcs3)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure
pointer	symbol			#I the current object symbol
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the y coordinates of the polygon vertices
int	nver			#I the number of vertices
int	wcs1			#I the wcs of the first plot
int	wcs2			#I the wcs of the second plot
int	wcs3			#I the wcs of the third plot

pointer	sp, str, opsymbol
int	xp_stati(), xp_araplot(), xp_oaraplot(), xp_acogplot(), xp_oacogplot()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no object or data.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 
	if (xp_stati (xp,NAPIX) <= 0)
	    return

	# Return if there is no symbol.
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

	# Clear the screen.
	call gclear (gd)

	# Set the WCS and viewport for the radial and position angle plots.
	call gseti (gd, G_WCS, wcs1)
	call gsview (gd, 0.10, 0.95, 0.72, 0.95)
	call gseti (gd, G_WCS, wcs2)
	call gsview (gd, 0.10, 0.95, 0.38, 0.62)
	if (XP_OGEOMETRY(symbol) == XP_OINDEF) {
	    if (xp_araplot (gd, im, xp, xver, yver, nver, wcs1, wcs2) == ERR)
	        ;
	} else {
	    if (xp_oaraplot (gd,  im, xp, symbol, opsymbol, xp_statr (xp,
	        XSHIFT), xp_statr (xp, YSHIFT), xver, yver, nver, wcs1,
		wcs2) == ERR)
	    ;
	}

	call gseti (gd, G_WCS, wcs3)
	call gsview (gd, 0.10, 0.95, 0.05, 0.28)
	if (XP_OGEOMETRY(symbol) == XP_OINDEF) {
	    if (xp_acogplot (gd, xp) == ERR)
	        ;
	} else {
	    if (xp_oacogplot (gd, xp, symbol, opsymbol) == ERR)
	        ;
	}
end


# XP_OEPLOT -- Plot the results of the 2D moments analysis for an object.

procedure xp_oeplot (gd, xp, symbol, wcs1, wcs2, wcs3)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	symbol			#I the current object symbol
int	wcs1			#I the wcs of the first plot
int	wcs2			#I the wcs of the second plot
int	wcs3			#I the wcs of the third plot

pointer	sp, str, opsymbol
int	xp_stati(), xp_ahwplot(), xp_oahwplot(), xp_axplot(), xp_oaxplot()
int	xp_atplot(), xp_oatplot()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no object.
	if (IS_INDEFR(xp_statr(xp, PXCUR)) || IS_INDEFR(xp_statr(xp, PYCUR)))
	    return 

	# Return if there is no data.
	if (xp_stati (xp,NAPIX) <= 0)
	    return

	# Return if no symbol.
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

	# Clear the screen.
	call gclear (gd)

	# Set the WCS and viewport for the radial and position angle plots.
	call gseti (gd, G_WCS, wcs1)
	call gsview (gd, 0.10, 0.95, 0.72, 0.95)
	if (XP_OGEOMETRY(symbol) == XP_OINDEF) {
	    if (xp_ahwplot (gd, xp) == ERR)
	        ;
	} else {
	    if (xp_oahwplot (gd,  xp, symbol, opsymbol) == ERR)
	    ;
	}

	call gseti (gd, G_WCS, wcs2)
	call gsview (gd, 0.10, 0.95, 0.38, 0.62)
	if (XP_OGEOMETRY(symbol) == XP_OINDEF) {
	    if (xp_axplot (gd, xp) == ERR)
	        ;
	} else {
	    if (xp_oaxplot (gd,  xp, symbol, opsymbol) == ERR)
	    ;
	}

	call gseti (gd, G_WCS, wcs3)
	call gsview (gd, 0.10, 0.95, 0.05, 0.28)
	if (XP_OGEOMETRY(symbol) == XP_OINDEF) {
	    if (xp_atplot (gd, xp) == ERR)
	        ;
	} else {
	    if (xp_oatplot (gd, xp, symbol, opsymbol) == ERR)
	        ;
	}
end


# XP_ARAPLOT -- Compute a major axis and position angle plot for the object
# pixels.

int procedure xp_araplot (gd, im, xp, xver, yver, nver, wcsa, wcsp)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the  pointer to the main xapphot structure
real	xver[ARB]		#I the x vertices of the polygon
real	yver[ARB]		#I the y vertices of the polygon
int	nver			#I the number of vertices
int	wcsa			#I the wcs for the semi-major axis plot
int	wcsp			#I the wcs for the position angle plot

int	i
pointer	sp, title, exver, eyver
real	xc, yc, dmin, dmax, rmin, rmax, amin, amax, ymin, ymax, r2, r2max
real	xshift, yshift, txver[5], tyver[5]
bool	fp_equalr()
int	xp_stati()
pointer	xp_statp()
real	xp_statr(), asumr()

begin
	# Return if there is no image.
	if (im == NULL)
	    return

	# If both wcs are undefined (<= 0) quit.
	if (wcsa <= 0 && wcsp <= 0)
	    return

	# Define the center of symmetry.
	xc = xp_statr (xp, PXCUR)
	yc = xp_statr (xp, PYCUR)
	if (IS_INDEFR(xc) || IS_INDEFR(yc) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)

	# Compute the semi-major axis and position angle plot y limits.
	ymin = xp_statr (xp, ADATAMIN)
	ymax = xp_statr (xp, ADATAMAX)

	# Set up the semi-major axis plot.
	switch (xp_stati (xp, PGEOMETRY)) {
	case XP_ACIRCLE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1
	case XP_AELLIPSE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1
	case XP_ARECTANGLE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    dmin = xp_statr (xp, PAXRATIO) * dmax
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1
	case XP_APOLYGON:
	    if (xp_stati(xp, NAPERTS) == 1)
		dmax = 0.0
	    else
	        dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	            xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    r2max = -MAX_REAL
	    xshift = asumr (xver, nver) / nver
	    yshift = asumr (yver, nver) / nver
	    do i = 1, nver {
		r2 = (xver[i] - xshift) ** 2 + (yver[i] - yshift) ** 2
		r2max = max (r2max, r2)
	    }
	    rmax = sqrt (r2max) + dmax + 1.0
	}

	if (wcsa > 0) {
	    call gseti (gd, G_WCS, wcsa)
	    call sprintf (Memc[title], SZ_LINE,
	        "Object Semi-major Axis Profile at %.2f %.2f")
	        call pargr (xc)
	        call pargr (yc)
	    call gswind (gd, rmin, rmax, ymin, ymax)
	    call xp_rgfill (gd, rmin, rmax, ymin, ymax, GF_SOLID, 0)
	    #call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	    call gseti (gd, G_YNMINOR, 0)
	    call glabax (gd, Memc[title], "", "")
	}

	# Set up the position angle plot.
	if (wcsp > 0) {
	    call gseti (gd, G_WCS, wcsp)
	    amin = 0.0
	    amax = 360.0
	    call sprintf (Memc[title], SZ_LINE,
	        "Object Position Angle Profile at %.2f %.2f")
	        call pargr (xc)
	        call pargr (yc)
	    call gswind (gd, amin, amax, ymin, ymax)
	    call xp_rgfill (gd, amin, amax, ymin, ymax, GF_SOLID, 0)
	    call gseti (gd, G_YNMINOR, 0)
	    #call glabax (gd, Memc[title], "Position Angle (degrees)", "Counts")
	    call glabax (gd, Memc[title], "", "")
	}

	# Plot the points.
	switch (xp_stati (xp, PGEOMETRY)) {
	case XP_ACIRCLE:
	    call xp_acplot (gd, im, xc, yc, xp_statr (xp, AXC),
	        xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		dmax, wcsa, wcsp, GM_PLUS)
	case XP_AELLIPSE:
	    call xp_aeplot (gd, im, xc, yc, xp_statr (xp, AXC),
	        xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		dmax, xp_statr (xp, PAXRATIO), xp_statr (xp, PPOSANGLE), wcsa,
		wcsp, GM_PLUS)
	case XP_ARECTANGLE:
	    if (fp_equalr (xp_statr (xp, PPOSANGLE), 0.0) ||
	        fp_equalr (xp_statr (xp, PPOSANGLE), 180.0)) {
	        call xp_arplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmax, dmin, wcsa, wcsp, GM_PLUS)
	    } else if (fp_equalr (xp_statr (xp, PPOSANGLE), 90.0) ||
	        fp_equalr (xp_statr (xp, PPOSANGLE), 270.0)) {
	        call xp_arplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmin, dmax, wcsa, wcsp, GM_PLUS)
	    } else {
		call xp_pyrectangle (dmax, xp_statr (xp, PAXRATIO),
		    xp_statr (xp, PPOSANGLE), txver, tyver)
		call aaddkr (txver, xc, txver, 4)
		call aaddkr (tyver, yc, tyver, 4)
		txver[5] = txver[1]
		tyver[5] = tyver[1]
	        call xp_aryplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmax, xp_statr(xp, PAXRATIO), xp_statr(xp, PPOSANGLE),
		    txver, tyver, wcsa, wcsp, GM_PLUS)
	    }
	case XP_APOLYGON:
		xshift = xc - asumr (xver, nver) / nver
		yshift = yc - asumr (yver, nver) / nver
		call salloc (exver, nver + 1, TY_REAL)
		call salloc (eyver, nver + 1, TY_REAL)
		if (dmax <= 0.0) {
		    call amovr (xver, Memr[exver], nver)
		    call amovr (yver, Memr[eyver], nver)
		} else
		    call xp_pyexand (xver, yver, Memr[exver], Memr[eyver], nver,
		        dmax)
		call aaddkr (Memr[exver], xshift, Memr[exver], nver)
		call aaddkr (Memr[eyver], yshift, Memr[eyver], nver)
		Memr[exver+nver] = Memr[exver]
		Memr[eyver+nver] = Memr[eyver]
	        call xp_apyplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    Memr[exver], Memr[eyver], nver, wcsa, wcsp, GM_PLUS)
	}
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_OARAPLOT -- Compute a major axis and position angle plot for the object
# pixels.

int procedure xp_oaraplot (gd, im, xp, symbol, psymbol, xshift, yshift,
	xver, yver, nver, wcsa, wcsp)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure
pointer	symbol			#I the current object symbol
pointer	psymbol			#I the current polygon symbol
real	xshift			#I the x center shift
real	yshift			#I the y center shift
real	xver[ARB]		#I the x vertices of the polygon
real	yver[ARB]		#I the y vertices of the polygon
int	nver			#I the number of vertices
int	wcsa			#I the wcs for the semi-major axis plot
int	wcsp			#I the wcs for the position angle plot

int	i
pointer	sp, title, exver, eyver
real	xc, yc, xcp, ycp, dmin, dmax, rmin, rmax, amin, amax, ymin, ymax
real	r2, r2max
real	txver[5], tyver[5]
bool	fp_equalr()
int	xp_stati()
pointer	xp_statp()
real	xp_statr(), asumr()

begin
	# Return if there is no image.
	if (im == NULL)
	    return

	# If both wcs are undefined (<= 0) quit.
	if (wcsa <= 0 && wcsp <= 0)
	    return

	# Define the center of symmetry.
	xc = XP_OXINIT(symbol) + xshift
	yc = XP_OYINIT(symbol) + yshift
	if (IS_INDEFR(xc) || IS_INDEFR(yc) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)

	# Compute the semi-major axis and position angle plot y limits.
	ymin = xp_statr (xp, ADATAMIN)
	ymax = xp_statr (xp, ADATAMAX)

	# Set up the semi-major axis plot.
	switch (XP_OGEOMETRY(symbol)) {

	case XP_OCIRCLE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1

	case XP_OELLIPSE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1

	case XP_ORECTANGLE:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    dmin = xp_statr (xp, PAXRATIO) * dmax
	    rmin = 0.0
	    rmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1] + 1

	case XP_OPOLYGON:
	    dmax = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,PAPERTURES)+
	        xp_stati(xp,NMAXAP)-1]
	    rmin = 0.0
	    r2max = -MAX_REAL
	    xcp = asumr (XP_XVERTICES(psymbol), XP_ONVERTICES(psymbol)) /
	        XP_ONVERTICES(psymbol)
	    ycp = asumr (XP_YVERTICES(psymbol), XP_ONVERTICES(psymbol)) /
	        XP_ONVERTICES(psymbol)
	    do i = 1, XP_ONVERTICES(psymbol) {
		r2 = (XP_XVERTICES(psymbol+i-1) - xcp) ** 2 +
		    (XP_YVERTICES(psymbol+i-1) - ycp) ** 2
		r2max = max (r2max, r2)
	    }
	    rmax = sqrt (r2max) + dmax + 1.0

	case XP_OINDEF:
	    dmax = INDEFR
	    rmin = 0.0
	    rmax = INDEFR
	}

	if (wcsa > 0) {
	    call gseti (gd, G_WCS, wcsa)
	    call sprintf (Memc[title], SZ_LINE,
	        "Object Semi-major Axis Profile at %.2f %.2f")
	        call pargr (xc)
	        call pargr (yc)
	    call gswind (gd, rmin, rmax, ymin, ymax)
	    call xp_rgfill (gd, rmin, rmax, ymin, ymax, GF_SOLID, 0)
	    #call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	    call gseti (gd, G_YNMINOR, 0)
	    call glabax (gd, Memc[title], "", "")
	}

	# Set up the position angle plot.
	if (wcsp > 0) {
	    call gseti (gd, G_WCS, wcsp)
	    amin = 0.0
	    amax = 360.0
	    call sprintf (Memc[title], SZ_LINE,
	        "Object Position Angle Profile at %.2f %.2f")
	        call pargr (xc)
	        call pargr (yc)
	    call gswind (gd, amin, amax, ymin, ymax)
	    call xp_rgfill (gd, amin, amax, ymin, ymax, GF_SOLID, 0)
	    call gseti (gd, G_YNMINOR, 0)
	    #call glabax (gd, Memc[title], "Position Angle (degrees)", "Counts")
	    call glabax (gd, Memc[title], "", "")
	}

	# Plot the points.
	switch (XP_OGEOMETRY(symbol)) {

	case XP_OCIRCLE:
	    call xp_acplot (gd, im, xc, yc, xp_statr (xp, AXC),
	        xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		dmax, wcsa, wcsp, GM_PLUS)

	case XP_OELLIPSE:
	    call xp_aeplot (gd, im, xc, yc, xp_statr (xp, AXC),
	        xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		dmax, XP_OAXRATIO(symbol), XP_OPOSANG(symbol), wcsa, wcsp,
		GM_PLUS)

	case XP_ORECTANGLE:
	    if (fp_equalr (XP_OPOSANG(symbol), 0.0) ||
	        fp_equalr (XP_OPOSANG(symbol), 180.0)) {
	        call xp_arplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmax, dmin, wcsa, wcsp, GM_PLUS)
	    } else if (fp_equalr (XP_OPOSANG(symbol), 90.0) ||
	        fp_equalr (XP_OPOSANG(symbol), 270.0)) {
	        call xp_arplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmin, dmax, wcsa, wcsp, GM_PLUS)
	    } else {
		call xp_pyrectangle (dmax, XP_OAXRATIO(symbol),
		    XP_OPOSANG(symbol), txver, tyver)
		call aaddkr (txver, xc, txver, 4)
		call aaddkr (tyver, yc, tyver, 4)
		txver[5] = txver[1]
		tyver[5] = tyver[1]
	        call xp_aryplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    dmax, XP_OAXRATIO(symbol), XP_OPOSANG(symbol), txver,
		    tyver, wcsa, wcsp, GM_PLUS)
	    }

	case XP_OPOLYGON:
		call salloc (exver, XP_ONVERTICES(psymbol) + 1, TY_REAL)
		call salloc (eyver, XP_ONVERTICES(psymbol) + 1, TY_REAL)
		if (dmax <= 0.0) {
		    call amovr (XP_XVERTICES(psymbol), Memr[exver],
		        XP_ONVERTICES(psymbol))
		    call amovr (XP_YVERTICES(psymbol), Memr[eyver],
		        XP_ONVERTICES(psymbol))
		} else
		    call xp_pyexand (XP_XVERTICES(psymbol),
		        XP_YVERTICES(psymbol), Memr[exver], Memr[eyver],
			XP_ONVERTICES(psymbol), dmax)
		call aaddkr (Memr[exver], XP_OXSHIFT(symbol) + xshift,
		    Memr[exver], XP_ONVERTICES(psymbol))
		call aaddkr (Memr[eyver], XP_OYSHIFT(symbol) + yshift,
		    Memr[eyver], XP_ONVERTICES(psymbol))
		Memr[exver+XP_ONVERTICES(psymbol)] = Memr[exver]
		Memr[eyver+XP_ONVERTICES(psymbol)] = Memr[eyver]
	        call xp_apyplot (gd, im, xc, yc, xp_statr (xp, AXC),
	            xp_statr (xp, AYC), xp_stati(xp, ANX), xp_stati(xp, ANY),
		    Memr[exver], Memr[eyver], XP_ONVERTICES(psymbol),
		    wcsa, wcsp, GM_PLUS)

	default:
	    ;
	}

	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_ACOGPLOT -- Plot the curve of growth of the points

int procedure xp_acogplot (gd, xp)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)
	call salloc (ftemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i - 0.5
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	    do i = xp_stati(xp,NAPERTS), 2, -1
		Memr[atemp+i-1] = (Memr[atemp+i-1] + Memr[atemp+i-2]) / 2.0
	    Memr[atemp] = Memr[atemp] / 2.0
	}
	call amovr (Memr[xp_statp(xp,MAGS)], Memr[ftemp], xp_stati(xp,NMAXAP)) 
	do i = xp_stati(xp,NMAXAP), 2, -1
	    Memr[ftemp+i-1] = Memr[ftemp+i-1] - Memr[ftemp+i-2]
	if (xp_stati (xp, NMAXAP) > 1) {
	    call alimr (Memr[ftemp+1], xp_stati(xp, NMAXAP)-1, ymin, ymax)
	    ymax = max (ymax, 0.0)
	} else {
	    ymax = 0.0
	    ymin = -0.1
	}
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE, "Curve-of-Growth at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 2, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_AHWPLOT -- Plot the hwidths computed from the 2D moment analysis.

int procedure xp_ahwplot (gd, xp)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp (xp, MHWIDTHS)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE, "HWHMs of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_AXPLOT -- Plot the axis ratios computed from the 2D moment analysis.

int procedure xp_axplot (gd, xp)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp (xp, MAXRATIOS)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE,
	    "Axis Ratios of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_ATPLOT -- Plot the positions angles computed from the 2D moment analysis.

int procedure xp_atplot (gd, xp)

pointer	gd		# the graphics stream descriptor
pointer	xp		# the pointer to the main xapphot structure

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp (xp, MPOSANGLES)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE,
	    "Position Angles of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_OACOGPLOT -- Plot the curve of growth of the points

int procedure xp_oacogplot (gd, xp, symbol, psymbol)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer	psymbol		#I the current polygon symbol

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)
	call salloc (ftemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i - 0.5
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
            do i = xp_stati(xp,NAPERTS), 2, -1
                Memr[atemp+i-1] = (Memr[atemp+i-1] + Memr[atemp+i-2]) / 2.0
            Memr[atemp] = Memr[atemp] / 2.0
	}
	call amovr (Memr[xp_statp(xp,MAGS)], Memr[ftemp], xp_stati(xp,NMAXAP)) 
        do i = xp_stati(xp,NMAXAP), 2, -1
            Memr[ftemp+i-1] = Memr[ftemp+i-1] - Memr[ftemp+i-2]
        if (xp_stati (xp, NMAXAP) > 1) {
            call alimr (Memr[ftemp+1], xp_stati(xp, NMAXAP)-1, ymin, ymax)
            ymax = max (ymax, 0.0)
        } else {
            ymax = 0.0
            ymin = -0.1
        }
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE, "Curve-of-Growth at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_OAHWPLOT -- Plot the half widths derived from the 2D moments analysis.

int procedure xp_oahwplot (gd, xp, symbol, psymbol)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer	psymbol		#I the current polygon symbol

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp(xp, MHWIDTHS)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE, "HWHMs of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_OAXPLOT -- Plot the axis ratios derived from the 2D moments analysis.

int procedure xp_oaxplot (gd, xp, symbol, psymbol)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer	psymbol		#I the current polygon symbol

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp(xp, MAXRATIOS)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE,
	    "Axis Ratios of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_OATPLOT -- Plot the positon angles derived from the 2D moments analysis.

int procedure xp_oatplot (gd, xp, symbol, psymbol)

pointer	gd		#I the graphics stream descriptor
pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the current object symbol
pointer	psymbol		#I the current polygon symbol

int	i
pointer	sp, title, atemp, ftemp
real	xmin, xmax, ymin, ymax, ydiff
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Check that there is a valid measurment.
	if (IS_INDEFR(xp_statr (xp, PXCUR)) || IS_INDEFR(xp_statr (xp,
	    PYCUR)) || xp_stati (xp, NAPIX) <= 0)
	    return (ERR)

	# Allocate working space.
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
	call salloc (atemp, xp_stati (xp,NAPERTS), TY_REAL)

	# Compute the plot limits.
	if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
	    do i = 1, xp_stati (xp, NAPERTS)
		Memr[atemp+i-1] = i
	    xmin = 0.0
	    xmax = xp_stati (xp, NAPERTS) + 1 
	} else {
	    call amulkr (Memr[xp_statp(xp,PAPERTURES)], xp_statr (xp,ISCALE),
	        Memr[atemp], xp_stati(xp, NAPERTS))
	    call alimr (Memr[atemp], xp_stati(xp, NAPERTS), xmin, xmax)
	    xmin = 0.0
	    xmax = xmax + 1.0
	}
	ftemp = xp_statp(xp, MPOSANGLES)
	call alimr (Memr[ftemp], xp_stati(xp, NMAXAP), ymin, ymax)
	ydiff = ymax - ymin
	if (ydiff <= 0.0) {
	    ymin = ymin - 0.1 * ymin
	    ymax = ymax + 0.1 * ymax
	} else {
	    ymin = ymin - 0.1 * ydiff
	    ymax = ymax + 0.1 * ydiff
	}

	# Draw the labels and axes.
	call sprintf (Memc[title], SZ_LINE,
	    "Positions Angles of Object at %.2f %.2f")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	# Mark the points.
	call gmark (gd, 0.0, 0.0, GM_PLUS, 1.0, 1.0)
	do i = 1, xp_stati (xp, NMAXAP)
	    call gmark (gd, Memr[atemp+i-1], Memr[ftemp+i-1], GM_PLUS, 1.0, 1.0)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_ACPLOT -- Compute and plot the semi-major axis (radius) and position
# angle of the points inside the largest circular aperture.

procedure xp_acplot (gd, im, xc, yc, axc, ayc, anx, any, rmax, wcsa, wcsp,
	marker)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the  pointer to the input image
real	xc, yc			#I the center of symmetry in the image
real	axc, ayc		#I the center of symmetry in the "subraster"
int	anx, any		#I the size of the subraster
real	rmax			#I the maximum radius
int	wcsa, wcsp		#I the semi-major axis and position angle wcs
int	marker			#I the plot marker type

int	i, j, c1, c2, l1, l2
pointer	buf
real	r2max, r2, dx, dy, dy2, r, theta
pointer	imgs2r()

begin
	c1 = nint (xc - axc + 1)
	c2 = c1 + anx - 1
	l1 = nint (yc - ayc + 1)
	l2 = l1 + any - 1

	r2max = rmax ** 2
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == EOF)
		next
	    dy = (j - yc)
	    dy2 = dy ** 2
	    if (dy2 > r2max)
		next
	    do i = 1, anx {
		dx = (i - axc)
		r2 = dx ** 2 + dy2
		if (r2 > r2max)
		    next
		if (wcsa > 0) {
		    r = sqrt (r2)
		    call gseti (gd, G_WCS, wcsa)
		    call gmark (gd, r, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
		if (wcsp > 0) {
		    theta = RADTODEG(atan2 (dy, dx))
		    if (theta < 0.0)
		        theta = theta + 360.0
		    call gseti (gd, G_WCS, wcsp)
		    call gmark (gd, theta, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
	    }
	}
end


# XP_AEPLOT -- Compute and plot the semi-major axis (radius) and position
# angle of the points inside the largest elliptical aperture.

procedure xp_aeplot (gd, im, xc, yc, axc, ayc, anx, any, amaj, aratio, atheta,
        wcsa, wcsp, marker)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
real	xc, yc			#I the center of symmetry in the image
real	axc, ayc		#I the center of symmetry in the "subraster"
int	anx, any		#I the size of the subraster
real	amaj			#I the semi-major axis
real	aratio			#I the ratio of short to long axes
real	atheta			#I the ratio of short to long axes
int	wcsa, wcsp		#I the semi-major axis and position angle wcs
int	marker			#I the plot marker type


int	i, j, c1, c2, l1, l2
pointer	buf
real	a2max, aa, bb, cc, ff, dy, dy2, dx, dx2, dist, r, theta
pointer	imgs2r()

begin
	# Compute the parameters of the ellipse.
	a2max = amaj ** 2
	call xp_ellipse (amaj, aratio, atheta, aa, bb, cc, ff)
	aa = aa / a2max
	bb = bb / a2max
	cc = cc / a2max
	ff = ff / a2max

	# Compute the data limits.
	c1 = nint (xc - axc + 1)
	c2 = c1 + anx - 1
	l1 = nint (yc - ayc + 1)
	l2 = l1 + any - 1

	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == EOF)
		next
	    dy = (j - yc)
	    dy2 = dy ** 2
	    do i = 1, anx {
		dx = (i - axc)
		dx2 = dx ** 2
		dist = aa * dx2 + bb * dx * dy + cc * dy2
		if (dist > ff)
		    next
		if (wcsa > 0) {
		    r = sqrt (dist) / aratio
		    call gseti (gd, G_WCS, wcsa)
		    call gmark (gd, r, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
		if (wcsp > 0) {
		    theta = RADTODEG(atan2 (dy, dx))
		    if (theta < 0.0)
		        theta = theta + 360.0
		    call gseti (gd, G_WCS, wcsp)
		    call gmark (gd, theta, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
	    }
	}
end


# XP_ARPLOT -- Compute and plot the semi-major axis (radius) and position
# angle of the points inside the largest rectangular aperture.

procedure xp_arplot (gd, im, xc, yc, axc, ayc, anx, any, xwidth, ywidth,
        wcsa, wcsp, marker)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the  pointer to the input image
real	xc, yc			#I the center of symmetry in the image
real	axc, ayc		#I the center of symmetry in the "subraster"
int	anx, any		#I the size of the subraster
real	xwidth			#I the x half width of the data
real	ywidth			#I the y half width of the data
int	wcsa, wcsp		#I the semi-major axis and position angle wcs
int	marker			#I the plot marker type


int	i, j, c1, c2, l1, l2
real	dx, adx, dy, ady, r, theta
pointer	buf
pointer	imgs2r()

begin
	# Compute the data limits.
	c1 = nint (xc - axc + 1)
	c2 = c1 + anx - 1
	l1 = nint (yc - ayc + 1)
	l2 = l1 + any - 1

	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == EOF)
		next
	    dy = j - yc
	    ady = abs (dy)
	    if (ady > ywidth)
		next
	    do i = 1, anx {
		dx = i - axc
		adx = abs (dx)
		if (adx > xwidth)
		    next
		if (wcsa > 0) {
		    call gseti (gd, G_WCS, wcsa)
		    if (xwidth >= ywidth)
		        r = max (adx, ady * xwidth / ywidth)
		    else
		        r = max (ady, adx * ywidth / xwidth)
		    call gmark (gd, r, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
		if (wcsp > 0) {
		    theta = RADTODEG(atan2 (dy, dx))
		    if (theta < 0.0)
		        theta = theta + 360.0
		    call gseti (gd, G_WCS, wcsp)
		    call gmark (gd, theta, Memr[buf+i-1], marker, 1.0, 1.0) 
		}
	    }
	}
end


# XP_ARYPLOT -- Compute and plot the semi-major axis (radius) and position
# angle of the points inside the largest rotated rectangular aperture.

procedure xp_aryplot (gd, im, xc, yc, axc, ayc, anx, any, amaj, aratio, atheta,
        xver, yver, wcsa, wcsp, marker)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I the pointer to the input image
real	xc, yc			#I the center of symmetry in the image
real	axc, ayc		#I the center of symmetry in the "subraster"
int	anx, any		#I the size of the subraster
real	amaj			#I the length of the long axis
real	aratio			#I the ratio of short to long axes
real	atheta			#I the position angle
real	xver[ARB]		#I the x vertices
real	yver[ARB]		#I the y vertices
int	wcsa, wcsp		#I the semi-major axis and position angle wcs
int	marker			#I the plot marker type


int	i, j, k, c1, c2, l1, l2, nintr, colmin, colmax
pointer	sp, wk1, wk2, xintr, buf
real	xmin, xmax, ymin, ymax, cost, sint, lx, ld, dx, dy, adx, ady, r, theta
int	xp_pyclip()
pointer	imgs2r()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (wk1, 5, TY_REAL)
	call salloc (wk2, 5, TY_REAL)
	call salloc (xintr, 5, TY_REAL)

	# Compute the data limits.
	#c1 = nint (xc - axc + 1)
	#c2 = c1 + anx - 1
	c1 = 1
	c2 = IM_LEN(im,1)
	l1 = nint (yc - ayc + 1)
	l2 = l1 + any - 1
	call alimr (yver, 5, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))

	# Initialize.
	lx = c2
	cost = cos (DEGTORAD(atheta))
	sint = sin (DEGTORAD(atheta))

	do j = l1, l2 {

	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == EOF)
		next

	    # Check the line limits.
	    if (ymin > j)
		ld = min (j + 1, l2)
	    else if (ymax < j)
		ld = max (j - 1, l1)
	    else
		ld = j

	    # Find the intersection points.
	    nintr = xp_pyclip (xver, yver, Memr[wk1], Memr[wk2], Memr[xintr],
		5, lx, ld)
	    if (nintr <= 0)
		next
	    call asrtr (Memr[xintr], Memr[xintr], nintr)

	    # Plot the points.
	    do i = 1, nintr, 2 {
                xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
		    Memr[xintr+i-1]))
                xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                    Memr[xintr+i]))
                colmin = min (int (xmin + 0.5), int (IM_LEN(im,1)))
                colmax = min (int (xmax), int (IM_LEN(im,1)))
                do k = colmin, colmax {
                    if (k < xmin || k > xmax)
                        next
		    dx = k - xc
		    dy = j - yc
		    if (wcsa > 0) {
		        adx = abs (dx * cost + dy * sint)
		        ady = abs (-dx * sint + dy * cost)
		        r = max (adx, ady / aratio)
		        call gseti (gd, G_WCS, wcsa)
		        call gmark (gd, r, Memr[buf+k-1], marker, 1.0, 1.0) 
		    }
		    if (wcsp > 0) {
		        theta = RADTODEG(atan2 (dy, dx))
		        if (theta < 0.0)
		            theta = theta + 360.0
		        call gseti (gd, G_WCS, wcsp)
		        call gmark (gd, theta, Memr[buf+k-1], marker, 1.0, 1.0) 
		    }
		}
            } 
	}

	call sfree (sp)
end


# XP_APYPLOT -- Compute and plot the semi-major axis (radius) and position
# angle of the points inside the largest polygonal aperture.

procedure xp_apyplot (gd, im, xc, yc, axc, ayc, anx, any, xver, yver, nver,
	wcsa, wcsp, marker)

pointer	gd			#I the graphics stream descriptor
pointer	im			#I pointer to the input image
real	xc, yc			#I the center of symmetry in the image
real	axc, ayc		#I the center of symmetry in the "subraster"
int	anx, any		#I the size of the subraster
real	xver[ARB]		#I the x vertices
real	yver[ARB]		#I the y vertices
int	nver			#I the number of vertices
int	wcsa, wcsp		#I the semi-major axis and position angle wcs
int	marker			#I the plot marker type

int	i, j, k, c1, c2, l1, l2, nintr, colmin, colmax
pointer	sp, wk1, wk2, xintr, buf
real	ymin, ymax, xmin, xmax, lx, ld, dx, dy, r, theta
int	xp_pyclip()
pointer	imgs2r()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (wk1, nver + 1, TY_REAL)
	call salloc (wk2, nver + 1, TY_REAL)
	call salloc (xintr, nver + 1, TY_REAL)

	# Compute the data limits.
	#c1 = nint (xc - axc + 1)
	#c2 = c1 + anx - 1
	c1 = 1
	c2 = IM_LEN(im,1)
	l1 = nint (yc - ayc + 1)
	l2 = l1 + any - 1
	call alimr (yver, nver, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))

	# Initialize.
	lx = c2
	do j = l1, l2 {

	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == EOF)
		next

	    # Check the line limits.
	    if (ymin > j)
		ld = min (j + 1, l2)
	    else if (ymax < j)
		ld = max (j - 1, l1)
	    else
		ld = j

	    # Find the intersection points.
	    nintr = xp_pyclip (xver, yver, Memr[wk1], Memr[wk2], Memr[xintr],
		nver + 1, lx, ld)
	    if (nintr <= 0)
		next
	    call asrtr (Memr[xintr], Memr[xintr], nintr)

	    # Plot the points.
	    do i = 1, nintr, 2 {
                xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
		    Memr[xintr+i-1]))
                xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                    Memr[xintr+i]))
                colmin = min (int (xmin + 0.5), int (IM_LEN(im,1)))
                colmax = min (int (xmax), int (IM_LEN(im,1)))
                do k = colmin, colmax {
                    if (k < xmin || k > xmax)
                        next
		    dx = k - xc
		    dy = j - yc
		    if (wcsa > 0) {
		        r = sqrt (dx ** 2 + dy ** 2)
		        call gseti (gd, G_WCS, wcsa)
		        call gmark (gd, r, Memr[buf+k-1], marker, 1.0, 1.0) 
		    }
		    if (wcsp > 0) {
		        theta = RADTODEG(atan2 (dy, dx))
		        if (theta < 0.0) 
		            theta = theta + 360.0
		        call gseti (gd, G_WCS, wcsp)
		        call gmark (gd, theta, Memr[buf+k-1], marker, 1.0, 1.0) 
		    }
		}
	    }
	}

	call sfree (sp)
end
