include <imhdr.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/photdef.h"
include "../lib/phot.h"

# XP_MAGBUF -- Determine the mapping of the aperture list into the input image.

int procedure xp_magbuf (xp, im, wx, wy, xver, yver, nver, c1, c2, l1, l2)

pointer	xp		#I the pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the x and y center coordinates
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of polygon vertices
int	c1, c2		#O the column limits
int	l1, l2		#O the line limits

int	i
pointer	imp, phot, sp, txver, tyver
real	rbuf, xshift, yshift
int	xp_cphotpix(), xp_ephotpix(), xp_rphotpix(), xp_pphotpix()
real	asumr()

begin
	# Get some pointers.
	imp = XP_PIMPARS(xp)
	phot = XP_PPHOT(xp)

        # Make sure the geometry is current.
        #call strcpy (XP_PGEOSTRING(phot), XP_POGEOSTRING(phot), SZ_FNAME)
        #XP_POGEOMETRY(phot) = XP_PGEOMETRY(phot)
        #if (strne (XP_PAPSTRING(phot), XP_POAPSTRING(phot)))
            #call xp_sets (xp, PAPSTRING, XP_PAPSTRING(phot))
        #XP_POAXRATIO(phot) = XP_PAXRATIO(phot)
        #XP_POPOSANGLE(phot) = XP_PPOSANGLE(phot)

	# Check for 0 radius aperture.
	#if (Memr[XP_PAPERTURES(phot)] <= 0.0 && XP_PGEOMETRY(phot) !=
	    #XP_APOLYGON)
	    #return (XP_APERT_NOAPERT)
	if (Memr[XP_PAPERTURES(phot)] < 0.0 && XP_PGEOMETRY(phot) !=
	    XP_APOLYGON)
	    return (XP_APERT_NOAPERT)
	if (nver < 3 && XP_PGEOMETRY(phot) == XP_APOLYGON)
	    return (XP_APERT_NOAPERT)

	# Compute the maximum aperture size
	XP_NAPIX(phot) = NULL
	switch (XP_PGEOMETRY(phot)) {

	case XP_ACIRCLE:
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_cphotpix (im, wx, wy, rbuf, c1, c2, l1, l2)
	        XP_AXC(phot) = wx - c1 + 1 
	        XP_AYC(phot) = wy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }

	case XP_AELLIPSE:
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_ephotpix (im, wx, wy, rbuf,
		    XP_PAXRATIO(phot), XP_PPOSANGLE(phot), c1, c2, l1, l2)
	        XP_AXC(phot) = wx - c1 + 1 
	        XP_AYC(phot) = wy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }
	case XP_ARECTANGLE:
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_rphotpix (im, wx, wy, rbuf,
		    XP_PAXRATIO(phot), XP_PPOSANGLE(phot), c1, c2, l1, l2)
	        XP_AXC(phot) = wx - c1 + 1 
	        XP_AYC(phot) = wy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }

	default:
	    call smark (sp)
	    call salloc (txver, nver, TY_REAL)
	    call salloc (tyver, nver, TY_REAL)
	    xshift = wx - asumr (xver, nver) / nver
	    yshift = wy - asumr (yver, nver) / nver
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
		if (XP_NAPERTS(phot) == 1) {
		    call amovr (xver, Memr[txver], nver)
		    call amovr (yver, Memr[tyver], nver)
		} else {
	            rbuf =  Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver],
		        nver, rbuf)
		}
		call aaddkr (Memr[txver], xshift, Memr[txver], nver)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
	        XP_NAPIX(phot) = xp_pphotpix (im, Memr[txver], Memr[tyver],
		    nver, c1, c2, l1, l2)
	        XP_AXC(phot) = wx - c1 + 1 
	        XP_AYC(phot) = wy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }
	    call sfree (sp)
	}

	# Return the appropriate error code.
	if (XP_NAPIX(phot) == 0) {
	    return (XP_APERT_NOAPERT)
	} else if (XP_NMAXAP(phot) < XP_NAPERTS(phot)) {
	    return (XP_APERT_OUTOFBOUNDS)
	} else {
	    return (XP_OK)
	}
end


# XP_CPHOTPIX -- Determine the line and column limits of a subraster
# required to enclose a circle.

int procedure xp_cphotpix (im, wx, wy, dapert, c1, c2, l1, l2)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the x and y center of the subraster
real	dapert		#I the diameter of the circular aperture
int	c1, c2		#O the column limits
int	l1, l2		#O line limits

int	ncols, nlines
real	radius, xc1, xc2, xl1, xl2

begin
	# Check for 0 radius aperture.
	radius = dapert / 2.
	if (radius <= 0)
	    return (0)
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Test for an out of bounds aperture.
	xc1 = wx - radius
	xc2 = wx + radius
	xl1 = wy - radius
	xl2 = wy + radius
	if ((xc1 < 0.5) || (xc2 > (real (ncols) + 0.5)) ||
	    (xl1 < 0.5) || (xl2 > (real (nlines) + 0.5)))
	    return (0)

	# Get the column and line limits, dimensions and center of the subraster
	# to be extracted.
	c1 = max (1.0, min (real (ncols), xc1))
	c2 = min (real (ncols), max (1.0, xc2 + 0.5))
	l1 = max (1.0, min (real (nlines), xl1))
	l2 = min (real (nlines), max (1.0, xl2 + 0.5))
	return ((c2 - c1 + 1) * (l2 - l1 + 1))
end


# XP_EPHOTPIX -- Determine the line and column limits of a subraster required
# to enclose an ellipse.

int procedure xp_ephotpix (im, wx, wy, dapert, ratio, theta, c1, c2, l1, l2)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the  center of the subraster
real	dapert		#I the  major axis of the ellipse
real	ratio		#I the ratio of the short to long axes
real	theta		#I the position angle of the long axis
int	c1, c2		#O the column limits
int	l1, l2		#O the line limits

int	ncols, nlines
real	a, aa, bb, cc, ff, dx, dy, xc1, xc2, xl1, xl2

begin
	# Check for 0 radius aperture.
	a = dapert / 2.
	if (a <= 0)
	    return (0)
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Compute the minimum and maximum x and y values of the ellipse.
	call xp_ellipse (a, ratio, theta, aa, bb, cc, ff)
	dx = sqrt (ff / (aa - bb * bb / 4.0 / cc))
	dy = sqrt (ff / (cc - bb * bb / 4.0 / aa))
	xc1 = wx - dx
	xc2 = wx + dx
	xl1 = wy - dy
	xl2 = wy + dy

	# Test for out of bounds aperture.
	if ((xc1 < 0.5) || (xc2 > (real (ncols) + 0.5)) ||
	    (xl1 < 0.5) || (xl2 > (real (nlines) + 0.5)))
	    return (0)

	# Get the column and line limits of the subraster to be extracted.
	c1 = max (1.0, min (real (ncols), xc1))
	c2 = min (real (ncols), max (1.0, xc2 + 0.5))
	l1 = max (1.0, min (real (nlines), xl1))
	l2 = min (real (nlines), max (1.0, xl2 + 0.5))
	return ((c2 - c1 + 1) * (l2 - l1 + 1))
end


# XP_RPHOTPIX -- Determine the line and column limits of a subraster required
# to enclose a rectangle.

int procedure xp_rphotpix (im, wx, wy, dapert, ratio, theta, c1, c2, l1, l2)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the x and y center of the subraster
real	dapert		#I the major axis of the rectangular aperture
real	ratio		#I the  ratio of the short to long axes
real	theta		#I the  position angle of the long axis
int	c1, c2		#O the column limits
int	l1, l2		#O the line limits

int	ncols, nlines
real	a, xc1, xc2, xl1, xl2, xver[4], yver[4]
bool	fp_equalr()

begin
	# Check for 0 radius aperture.
	a = dapert / 2.0
	if (a <= 0)
	    return (0)
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Find the and y limits.
	if (fp_equalr (0.0, theta) || fp_equalr (180.0, theta)) {
	    xc1 = wx - a
	    xc2 = wx + a
	    xl1 = wy - ratio * a
	    xl2 = wy + ratio * a
	} else if (fp_equalr (90.0, theta) || fp_equalr (270.0, theta)) {
	    xc1 = wx - ratio * a
	    xc2 = wx + ratio * a
	    xl1 = wy - ratio
	    xl2 = wy + ratio
	} else {
	    call xp_pyrectangle (a, ratio, theta, xver, yver)
	    call aaddkr (xver, wx, xver, 4)
	    call aaddkr (yver, wy, yver, 4)
	    call alimr (xver, 4, xc1, xc2)
	    call alimr (yver, 4, xl1, xl2)
	}

	# Test for out of bounds aperture.
	if ((xc1 < 0.5) || (xc2 > (real (ncols) + 0.5)) ||
	    (xl1 < 0.5) || (xl2 > (real (nlines) + 0.5)))
	    return (0)

	# Get the column and line limits of the subraster to be extracted.
	xc1 = max (0.5, min (real (IM_LEN(im,1) + 0.5), xc1))
	xc2 = min (real (IM_LEN(im,1) + 0.5), max (0.5, xc2))
	xl1 = max (0.5, min (real (IM_LEN(im,2) + 0.5), xl1))
	xl2 = min (real (IM_LEN(im,2) + 0.5), max (0.5, xl2))

	c1 = min (int (xc1 + 0.5), IM_LEN(im,1))
	c2 = min (int (xc2 + 0.5), IM_LEN(im,1))
	l1 = min (int (xl1 + 0.5), IM_LEN(im,2))
	l2 = min (int (xl2 + 0.5), IM_LEN(im,2))
	return ((c2 - c1 + 1) * (l2 - l1 + 1))
end


# XP_PPHOTPIX -- Determine the line and column limits of a subraster required
# to enclose a polygon.

int procedure xp_pphotpix (im, xver, yver, nver, c1, c2, l1, l2)

pointer	im		#I the pointer to the input image
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of vertices
int	c1, c2		#O the column limits
int	l1, l2		#O the line limits

int	ncols, nlines
real	xc1, xc2, xl1, xl2

begin
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	call alimr (xver, nver, xc1, xc2)
	call alimr (yver, nver, xl1, xl2)

	# Test for out of bounds aperture.
	if ((xc1 < 0.5) || (xc2 > (real (ncols) + 0.5)) ||
	    (xl1 < 0.5) || (xl2 > (real (nlines) + 0.5)))
	    return (0)

	# Get the column and line limits of the subraster to be extracted.
	xc1 = max (0.5, min (real (IM_LEN(im,1) + 0.5), xc1))
	xc2 = min (real (IM_LEN(im,1) + 0.5), max (0.5, xc2))
	xl1 = max (0.5, min (real (IM_LEN(im,2) + 0.5), xl1))
	xl2 = min (real (IM_LEN(im,2) + 0.5), max (0.5, xl2))

	c1 = min (int (xc1 + 0.5), IM_LEN(im,1))
	c2 = min (int (xc2 + 0.5), IM_LEN(im,1))
	l1 = min (int (xl1 + 0.5), IM_LEN(im,2))
	l2 = min (int (xl2 + 0.5), IM_LEN(im,2))
	return ((c2 - c1 + 1) * (l2 - l1 + 1))
end
