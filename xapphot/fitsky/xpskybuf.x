include <imhdr.h>
include <mach.h>
include <math.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"

# XP_SKYBUF -- Extract the sky pixels given the pointer to the image,
# the coordinates of the center, and the vertices of the aperture.

int procedure xp_skybuf (xp, im, wx, wy, xver, yver, nver)

pointer	xp		#I the pointer to main xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the coordinates of the aperture center
real	xver[ARB]	#I the x coordinates of the aperture vertices
real	yver[ARB]	#I the y coordinates of the aperture vertices
int	nver		#I the number of vertices

int	lenbuf
pointer	imp, sky, sp, ixver, iyver, oxver, oyver
real	rannulus, wannulus, rmin, rmax, ratio, xmin, xmax, ymin, ymax
real	datamin, datamax, theta, xshift, yshift
real	xin[5], yin[5], xout[5], yout[5]

bool	fp_equalr()
int	xp_cskypix(), xp_cbskypix(), xp_eskypix(), xp_ebskypix() 
int	xp_rskypix(), xp_rbskypix(), xp_pskypix(), xp_pbskypix()
real	asumr()

begin
	# Get the substructure pointers.
	imp = XP_PIMPARS(xp)
	sky = XP_PSKY(xp)

        # Make sure the geometry is current.
	XP_SOMODE(sky) = XP_SMODE(sky)
        call strcpy (XP_SMSTRING(sky), XP_SOMSTRING(sky), SZ_FNAME)
        XP_SOGEOMETRY(sky) = XP_SGEOMETRY(sky)
        call strcpy (XP_SGEOSTRING(sky), XP_SOGEOSTRING(sky), SZ_FNAME)
	if (XP_SMODE(sky) == XP_SCONCENTRIC) {
            XP_SORANNULUS(sky) = XP_SRANNULUS(sky)
            XP_SOWANNULUS(sky) = XP_SWANNULUS(sky)
	} else {
	    if (XP_SGEOMETRY(sky) == XP_SPOLYGON) {
                XP_SORANNULUS(sky) = 0.0
                XP_SOWANNULUS(sky) = XP_SWANNULUS(sky)
	    } else {
                XP_SORANNULUS(sky) = XP_SRANNULUS(sky)
                XP_SOWANNULUS(sky) = XP_SWANNULUS(sky)
	    }
	}
        XP_SOAXRATIO(sky) = XP_SAXRATIO(sky)
        XP_SOPOSANGLE(sky) = XP_SPOSANGLE(sky)

	# Define some temporary variables.
	if (XP_SMODE(sky) == XP_SCONCENTRIC) {
	    rannulus = XP_SRANNULUS(sky) * XP_ISCALE(imp)
	    wannulus = XP_SWANNULUS(sky) * XP_ISCALE(imp)
	} else {
	    if (XP_SGEOMETRY(sky) == XP_SPOLYGON) {
	        rannulus = 0.0
	        wannulus = XP_SWANNULUS(sky) * XP_ISCALE(imp)
	    } else {
	        rannulus = XP_SRANNULUS(sky) * XP_ISCALE(imp)
	        wannulus = XP_SWANNULUS(sky) * XP_ISCALE(imp)
	    }
	}
	if (rannulus <= 0.0) {
	    rmin = 0.0
	    rmax = wannulus
	} else {
	    rmin = rannulus
	    rmax = rannulus + wannulus
	}
	ratio = XP_SAXRATIO(sky)
	theta = XP_SPOSANGLE(sky)

	# Check that the sky annulus has a finite width.
	if (wannulus <= 0.0 && XP_SGEOMETRY(sky) != XP_SPOLYGON)
	    return (XP_SKY_NOPIXELS)
	if (nver < 3 && XP_SGEOMETRY(sky) == XP_SPOLYGON)
	    return (XP_SKY_NOPIXELS)

	# Allocate space for the sky pixels.
	switch (XP_SGEOMETRY(sky)) {
	case XP_SCIRCLE:
	    lenbuf = PI * (2.0 * rannulus + wannulus + 1.0) * (wannulus + 1.0)
	case XP_SELLIPSE:
	    lenbuf = PI * ratio * (2.0 * rannulus + wannulus + 1.0) *
	        (wannulus + 1.0)
	case XP_SRECTANGLE:
	    lenbuf = 4.0 * ratio * (2.0 * rannulus + wannulus + 1.0) *
	        (wannulus + 1.0)
	case XP_SPOLYGON:
	    call alimr (xver, nver, xmin, xmax)
	    call alimr (yver, nver, ymin, ymax)
	    lenbuf = (xmax - xmin + rannulus + wannulus + 2.0) *
	        (ymax - ymin + rannulus + wannulus + 2.0)
	}

	if (lenbuf != XP_LENSKYBUF(sky)) {
	    if (XP_SKYPIX(sky) != NULL)
		call mfree (XP_SKYPIX(sky), TY_REAL)
	    call malloc (XP_SKYPIX(sky), lenbuf, TY_REAL)
	    if (XP_SCOORDS(sky) != NULL)
		call mfree (XP_SCOORDS(sky), TY_INT)
	    call malloc (XP_SCOORDS(sky), lenbuf, TY_INT)
	    if (XP_SINDEX(sky) != NULL)
		call mfree (XP_SINDEX(sky), TY_INT)
	    call malloc (XP_SINDEX(sky), lenbuf, TY_INT)
	    if (XP_SWEIGHTS(sky) != NULL)
		call mfree (XP_SWEIGHTS(sky), TY_REAL)
	    call malloc (XP_SWEIGHTS(sky), lenbuf, TY_REAL)
	    XP_LENSKYBUF(sky) = lenbuf
	}

	# Check for bad pixels.
	if (IS_INDEFR(XP_IMINDATA(imp)) && IS_INDEFR(XP_IMAXDATA(imp))) {
	    datamin = INDEFR
	    datamax = INDEFR
	} else {
	    if (IS_INDEFR(XP_IMINDATA(imp)))
		datamin = -MAX_REAL
	    else
		datamin = XP_IMINDATA(imp)
	    if (IS_INDEFR(XP_IMAXDATA(imp)))
		datamax = MAX_REAL
	    else
		datamax = XP_IMAXDATA(imp)
	}

	# Fetch the sky pixels.
	switch (XP_SGEOMETRY(sky)) {

	case XP_SCIRCLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_cskypix (im, wx, wy, rmin, rmax,
	            Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
		    XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else {
	        XP_NSKYPIX(sky) = xp_cbskypix (im, wx, wy, rmin, rmax,
	            datamin, datamax, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	case XP_SELLIPSE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_eskypix (im, wx, wy, rmin, rmax, ratio,
		    theta, Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
		    XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else {
	        XP_NSKYPIX(sky) = xp_ebskypix (im, wx, wy, rmin, rmax,
	            ratio, theta, datamin, datamax, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	case XP_SRECTANGLE:

	    if (fp_equalr (theta, 0.0) || fp_equalr (theta, 180.0)) {
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_rskypix (im, wx, wy, rmin, rmax,
		        ratio, Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_rbskypix (im, wx, wy, rmin, rmax,
		        ratio, datamin, datamax, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    } else if (fp_equalr (theta, 90.0) || fp_equalr (theta, 270.0)) {
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_rskypix (im, wx, wy, ratio * rmin,
		        ratio * rmax, 1.0 / ratio, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_rbskypix (im, wx, wy, ratio * rmin,
		        ratio * rmax, 1.0 / ratio, datamin, datamax,
			Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky),
			XP_SNY(sky), XP_NBADSKYPIX(sky))
	    } else {
		call xp_rvertices (wx, wy, rmin, rmax, ratio, theta, xin, yin,
		    xout, yout)
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_pskypix (im, xin, yin, xout, yout, 5,
		        Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_pbskypix (im, xin, yin, xout, yout, 5,
		        datamin, datamax, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	default:
	    call smark (sp)
	    call salloc (ixver, nver + 1, TY_REAL)
	    call salloc (iyver, nver + 1, TY_REAL)
	    call salloc (oxver, nver + 1, TY_REAL)
	    call salloc (oyver, nver + 1, TY_REAL)
	    xshift = wx - asumr (xver, nver) / nver
	    yshift = wy - asumr (yver, nver) / nver
	    if ((rannulus + wannulus) <= 0.0) {
		call aaddkr (xver, xshift, Memr[oxver], nver + 1)
		call aaddkr (yver, yshift, Memr[oyver], nver + 1)
		call aclrr (Memr[ixver], nver + 1)
		call aclrr (Memr[ixver], nver + 1)
	    } else  {
		if (rannulus <=  0.0) {
		    call aaddkr (xver, xshift, Memr[ixver], nver + 1)
		    call aaddkr (yver, yshift, Memr[iyver], nver + 1)
		} else {
		    call xp_pyexpand (xver, yver, Memr[ixver], Memr[iyver],
		        nver, rannulus)
		    Memr[ixver+nver] = Memr[ixver]
		    Memr[iyver+nver] = Memr[iyver]
		    call aaddkr (Memr[ixver], xshift, Memr[ixver], nver + 1)
		    call aaddkr (Memr[iyver], yshift, Memr[iyver], nver + 1)
		}
		call xp_pyexpand (xver, yver, Memr[oxver], Memr[oyver],
		    nver, rannulus + wannulus)
		Memr[oxver+nver] = Memr[oxver]
		Memr[oyver+nver] = Memr[oyver]
		call aaddkr (Memr[oxver], xshift, Memr[oxver], nver + 1)
		call aaddkr (Memr[oyver], yshift, Memr[oyver], nver + 1)
	    }
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_pskypix (im, Memr[ixver], Memr[iyver],
		    Memr[oxver], Memr[oyver], nver + 1, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else
	        XP_NSKYPIX(sky) = xp_pbskypix (im, Memr[ixver], Memr[iyver],
		    Memr[oxver], Memr[oyver], nver + 1, datamin, datamax,
		    Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)], XP_SXC(sky),
		    XP_SYC(sky), XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    call sfree (sp)
	}

	if (XP_NSKYPIX(sky) <= 0)
	    return (XP_SKY_NOPIXELS)
	else
	    return (XP_OK)
end


# XP_CSKYPIX -- Fetch the sky pixels from a circular annular region in the
# image.

int procedure xp_cskypix (im, wx, wy, rin, rout, skypix, coords, xc, yc,
        nx, ny)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	rin, rout	#I the inner and outer radii of the sky annulus
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	xc1, xc2, xl1, xl2, rin2, rout2, rj2, r2
pointer	imgs2r()

begin
	# Test for non physical sky annulus.
	if (rout <= rin)
	    return (0)

	# Test for out of bounds sky regions.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	xc1 = wx - rout
	xc2 = wx + rout
	xl1 = wy - rout
	xl2 = wy + rout
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line limits.
	c1 = max (1.0, min (real (ncols), xc1)) + 0.5
	c2 = min (real (ncols), max (1.0, xc2)) + 0.5
	l1 = max (1.0, min (real (nlines), xl1)) + 0.5
	l2 = min (real (nlines), max (1.0, xl2)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1

	# Fetch the sky pixels.
	rin2 = rin ** 2
	rout2 = rout ** 2
	nskypix = 0

	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    rj2 = (wy - j) ** 2
	    do i = c1, c2 {
	        r2 = (wx - i) ** 2 + rj2
		if (r2 <= rin2 || r2 > rout2)
		    next
		skypix[nskypix+1] = Memr[buf+i-c1]
		coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		nskypix = nskypix + 1
	    }
	}

	return (nskypix)
end


# XP_ESKYPIX -- Fetch the sky pixels from an elliptical annular region in the
# image.

int procedure xp_eskypix (im, wx, wy, ain, aout, ratio, theta, skypix, coords,
	xc, yc, nx, ny)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	ain, aout	#I the inner and outer semi-major axes of sky ellipse
real	ratio		#I the ratio of the minor major axes of sky ellipse
real	theta		#I the position angle of sky ellipse
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	Al, Bl, Cl, Fl, dx, dy, dxsq, dysq, dlsq, slratio, xc1, xc2, xl1, xl2
pointer	imgs2r()

begin
	# Test for non-physical sky annulus.
	if (aout <= ain || ratio <= 0.0)
	    return (0)

	# Get the size of the input image.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Get the parameters of the ellipse.
	call xp_ellipse (aout, ratio, theta, Al, Bl, Cl, Fl)

	# Compute the x and y limits of the large ellipse and test for
	# out of bounds ellipses.
	dx = sqrt (Fl / (Al - Bl * Bl / 4.0 / Cl))
	dy = sqrt (Fl / (Cl - Bl * Bl / 4.0 / Al))
	xc1 = wx - dx
	xc2 = wx + dx
	xl1 = wy - dy
	xl2 = wy + dy
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line in the input image limits.
	c1 = max (1.0, min (real (ncols), wx - dx)) + 0.5
	c2 = min (real (ncols), max (1.0, wx + dx)) + 0.5
	l1 = max (1.0, min (real (nlines), wy - dy)) + 0.5
	l2 = min (real (nlines), max (1.0, wy + dy)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1

	slratio = (ain / aout) ** 2
	nskypix = 0
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    dy = (j - wy)
	    dysq = dy * dy
	    do i = c1, c2 {
		dx = (i - wx)
		dxsq = dx * dx
	        dlsq = Al * dxsq + Bl * dx * dy + Cl * dysq
		if ((dlsq <= slratio * Fl) || (dlsq > Fl))
		    next
		nskypix = nskypix + 1
		skypix[nskypix] = Memr[buf+i-c1]
		coords[nskypix] = (i - c1 + 1) + nx * (j - l1)
	    }
	}

	return (nskypix)
end


# XP_CBSKYPIX -- Fetch the sky pixels from a circular annulus region and
# reject any bad pixels encountered.

int procedure xp_cbskypix (im, wx, wy, rin, rout, datamin, datamax,
	skypix, coords, xc, yc, nx, ny, nbad)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	rin, rout	#I the inner and outer radii of the sky annulus
real	datamin		#I the input minimum good data value
real	datamax		#I the input maximum good data value
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions
int	nbad		#O the number of bad pixels

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	xc1, xc2, xl1, xl2, rin2, rout2, rj2, r2, pixval
pointer	imgs2r()

begin
	# Test for non-physical sky annulus.
	if (rout <= rin)
	    return (0)

	# Test for out of bounds sky regions.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	xc1 = wx - rout
	xc2 = wx + rout
	xl1 = wy - rout
	xl2 = wy + rout
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line limits.
	c1 = max (1.0, min (real (ncols), xc1)) + 0.5
	c2 = min (real (ncols), max (1.0, xc2)) + 0.5
	l1 = max (1.0, min (real (nlines), xl1)) + 0.5
	l2 = min (real (nlines), max (1.0, xl2)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1

	rin2 = rin ** 2
	rout2 = rout ** 2
	nskypix = 0
	nbad = 0

	# Fetch the sky pixels.
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    rj2 = (wy - j) ** 2
	    do i = c1, c2 {
	        r2 = (wx - i) ** 2 + rj2
		if (r2 <= rin2 || r2 > rout2)
		    next
		pixval = Memr[buf+i-c1] 
		if (pixval < datamin || pixval > datamax)
		    nbad = nbad + 1
		else {
		    skypix[nskypix+1] = pixval
		    coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		    nskypix = nskypix + 1
		}
	    }
	}

	return (nskypix)
end


# XP_EBSKYPIX -- Fetch the sky pixels from an elliptical annular region in the
# image, rejecting bad data if present.

int procedure xp_ebskypix (im, wx, wy, ain, aout, ratio, theta, datamin,
        datamax, skypix, coords, xc, yc, nx, ny, nbad)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	ain, aout	#I the inner and outer semi-major axes of sky ellipse
real	ratio		#I the ratio of the minor major axes of sky ellipse
real	theta		#I the position angle of sky ellipse
real	datamin		#I the minimum good data value
real	datamax		#I the maximum good data value
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions
int	nbad		#O the number of bad dat sky pixels

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	Al, Bl, Cl, Fl, dx, dy, dxsq, dysq, dlsq, slratio, xc1, xc2, xl1, xl2
real	pixel
pointer	imgs2r()

begin
	# Test for non-physical sky annulus.
	if (aout <= ain || ratio <= 0.0)
	    return (0)

	# Get the size of the input image.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Get the parameters of the ellipse.
	call xp_ellipse (aout, ratio, theta, Al, Bl, Cl, Fl)

	# Compute the x and y limits of the large ellipse and test for
	# out of bounds ellipses.
	dx = sqrt (Fl / (Al - Bl * Bl / 4.0 / Cl))
	dy = sqrt (Fl / (Cl - Bl * Bl / 4.0 / Al))
	xc1 = wx - dx
	xc2 = wx + dx
	xl1 = wy - dy
	xl2 = wy + dy
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line in the input image limits.
	c1 = max (1.0, min (real (ncols), wx - dx)) + 0.5
	c2 = min (real (ncols), max (1.0, wx + dx)) + 0.5
	l1 = max (1.0, min (real (nlines), wy - dy)) + 0.5
	l2 = min (real (nlines), max (1.0, wy + dy)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1

	slratio = (ain / aout) ** 2
	nskypix = 0
	nbad = 0
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    dy = (j - wy)
	    dysq = dy * dy
	    do i = c1, c2 {
		dx = (i - wx)
		dxsq = dx * dx
	        dlsq = Al * dxsq + Bl * dx * dy + Cl * dysq
		if ((dlsq <= slratio * Fl) || (dlsq > Fl))
		    next
		pixel = Memr[buf+i-c1]
		if (pixel < datamin || pixel > datamax)
		    nbad = nbad + 1
		else {
		    nskypix = nskypix + 1
		    skypix[nskypix] = pixel
		    coords[nskypix] = (i - c1 + 1) + nx * (j - l1)
		}
	    }
	}

	return (nskypix)
end


# XP_RSKYPIX -- Fetch the sky pixels from a rectangular annular region in the
# image.

int procedure xp_rskypix (im, wx, wy, rxin, rxout, ratio, skypix, coords,
	xc, yc, nx, ny)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	rxin, rxout	#I the inner and outer half-width of sky annulus
real	ratio		#I the ratio of the minor major axes of sky ellipse
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	xc1, xc2, xl1, xl2, xwidth, ywidth
pointer	imgs2r()

begin
	# Test for non physical sky annulus.
	if (rxout <= rxin || ratio <= 0)
	    return (0)

	# Test for out of bounds sky regions.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	xc1 = wx - rxout
	xc2 = wx + rxout
	xl1 = wy - ratio * rxout
	xl2 = wy + ratio * rxout
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line limits.
	c1 = max (1.0, min (real (ncols), xc1)) + 0.5
	c2 = min (real (ncols), max (1.0, xc2)) + 0.5
	l1 = max (1.0, min (real (nlines), xl1)) + 0.5
	l2 = min (real (nlines), max (1.0, xl2)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	xwidth = rxout - rxin
	ywidth = ratio * xwidth

	# Fetch the sky pixels.
	nskypix = 0
	do j = l1, l2 {
	    if (j < xl1 || j > xl2)
		next
	    buf = imgs2r (im, c1, c2, j, j)
	    if (j < xl1 + ywidth || j > xl2 - ywidth) {
	        do i = c1, c2 {
		    if (i < xc1 || i > xc2)
			next
		    skypix[nskypix+1] = Memr[buf+i-c1]
		    coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		    nskypix = nskypix + 1
	        }
	    } else {
		do i = c1, c2 {
		    if (i < xc1 || i > xc2)
			next
		    if (i >= xc1 + xwidth && i <= xc2 - xwidth)
			next
		    skypix[nskypix+1] = Memr[buf+i-c1]
		    coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		    nskypix = nskypix + 1
		}
	    }
	}

	return (nskypix)
end


# XP_RBSKYPIX -- Fetch the sky pixels from a rectangular annular region in the
# image, detecting and rejecting any bad pixels.

int procedure xp_rbskypix (im, wx, wy, rxin, rxout, ratio, datamin, datamax,
	skypix, coords, xc, yc, nx, ny, nbad)

pointer	im		#I the pointer to the input image
real	wx, wy		#I the center of the circular sky annulus
real	rxin, rxout	#I the inner and outer half-width of sky annulus
real	ratio		#I the ratio of the minor major axes of sky ellipse
real	datamin		#I the minimum good data value
real	datamax		#I the maximum good data value
real	skypix[ARB]	#O the output array of sky pixels
int	coords[ARB]	#O the sky pixel coordinates array [i + nx * (j - 1)]
real	xc, yc		#O the sky subraster center coordinates
int	nx, ny		#O the sky subraster dimensions
int	nbad		#O the number of bad pixels

int	i, j, ncols, nlines, c1, c2, l1, l2, nskypix
pointer	buf
real	xc1, xc2, xl1, xl2, xwidth, ywidth, pixel
pointer	imgs2r()

begin
	# Test for non physical sky annulus.
	if (rxout <= rxin || ratio <= 0)
	    return (0)

	# Test for out of bounds sky regions.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	xc1 = wx - rxout
	xc2 = wx + rxout
	xl1 = wy - ratio * rxout
	xl2 = wy + ratio * rxout
	if (xc2 < 1.0 || xc1 > real (ncols) || xl2 < 1.0 || xl1 > real (nlines))
	    return (0)

	# Compute the column and line limits.
	c1 = max (1.0, min (real (ncols), xc1)) + 0.5
	c2 = min (real (ncols), max (1.0, xc2)) + 0.5
	l1 = max (1.0, min (real (nlines), xl1)) + 0.5
	l2 = min (real (nlines), max (1.0, xl2)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	xwidth = rxout - rxin
	ywidth = ratio * xwidth

	# Fetch the sky pixels.
	nskypix = 0
	nbad = 0
	do j = l1, l2 {
	    if (j < xl1 || j > xl2)
		next
	    buf = imgs2r (im, c1, c2, j, j)
	    if (j < xl1 + ywidth || j > xl2 - ywidth) {
	        do i = c1, c2 {
		    if (i < xc1 || i > xc2)
			next
		    pixel = Memr[buf+i-c1]
		    if (pixel < datamin || pixel > datamax)
			nbad = nbad + 1
		    else {
		        skypix[nskypix+1] = pixel
		        coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		        nskypix = nskypix + 1
		    }
	        }
	    } else {
		do i = c1, c2 {
		    if (i < xc1 || i > xc2)
			next
		    if (i >= xc1 + xwidth && i <= xc2 - xwidth)
			next
		    pixel = Memr[buf+i-c1]
		    if (pixel < datamin || pixel > datamax)
			nbad = nbad + 1
		    else {
		        skypix[nskypix+1] = pixel
		        coords[nskypix+1] = (i - c1 + 1) + nx * (j - l1)
		        nskypix = nskypix + 1
		    }
		}
	    }
	}

	return (nskypix)
end


# XP_PSKYPIX -- Fetch the  sky pixels in a polygonal annulus defined by
# the vertices xin, yin and xout, yout.

int procedure xp_pskypix (im, xin, yin, xout, yout, nver, skypix, coords,
	xc, yc, nx, ny)

pointer	im			#I the pointer to the input image
real	xin[ARB], yin[ARB]	#I the vertices of the inner polygon
real	xout[ARB], yout[ARB]	#I the vertices of the outer polygon
int	nver			#I the number of vertices
real	skypix[ARB]		#O the output array of sky pixels
int	coords[ARB]		#O the  output sky pixel coordinates
				#           [i + nx * (j - 1)]
real	xc, yc			#O the output sky subraster center coordinates
int	nx, ny			#O the output sky subraster dimensions

int	i, j, jj, k, nskypix, linemin, linemax, colmin, colmax, nintr1, nintr2
int	c1, c2
pointer	sp, wk1, wk2, xintr1, xintr2, buf
real	xmin, xmax, ymin, ymax, lx, ld, x1, x2
int	xp_pyclip()
pointer	imgl2r()
real	asumr()

begin
	# Check the number of vertices.
	if (nver < 4)
	    return (0)

	# Check the limits of the polygons.
	call alimr (xout, nver, xmin, xmax)
	call alimr (yout, nver, ymin, ymax)
	
	if (xmax < 0.5 || xmin > IM_LEN(im,1) || ymax < 0.5 || ymin >
	    IM_LEN(im,2))
	    return (0)

	# Allocate working space.
	call smark (sp)
	call salloc (wk1, nver, TY_REAL)
	call salloc (wk2, nver, TY_REAL)
	call salloc (xintr1, nver, TY_REAL)
	call salloc (xintr2, nver, TY_REAL)

	# Find the minimum and maximum column and line numbers.
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))
	linemin = min (int (ymin + 0.5), int (IM_LEN(im,2)))
	linemax = min (int (ymax), int (IM_LEN(im,2)))
	ny = linemax - linemin + 1
	yc = asumr (yout, nver - 1) / (nver - 1) - linemin + 1
	xmin = max (0.5, min (real(IM_LEN(im,1) + 0.5), xmin))
	xmax = min (real (IM_LEN(im,1)+0.5), max (0.5, xmax))
	colmin = min (int (xmin + 0.5), int (IM_LEN(im,1)))
	colmax = min (int (xmax), int (IM_LEN(im,1)))
	nx = colmax - colmin + 1
	xc = asumr (xout, nver - 1) / (nver - 1) - colmin + 1

	# Set up the line segment parameters and initialize the sky pixel
	# count.
	xmin = 0.5
	xmax = IM_LEN(im,1) + 0.5
	lx = xmax - xmin
	nskypix = 0

	# Loop over the range of lines of interest.
	do i = linemin, linemax {

	    # Read in the image line
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next

	    # Check the line limits
	    if (ymin > i)
		ld = min (i + 1, linemax)
	    else if (ymax < i)
		ld = max (i - 1, linemin)
	    else
		ld = i

	    # Find all the intersection points of the outer polygon
	    # and the image line.
	    nintr2 = xp_pyclip (xout, yout, Memr[wk1], Memr[wk2], Memr[xintr2],
	        nver, lx, ld)
	    if (nintr2 <= 0)
		next
	    call asrtr (Memr[xintr2], Memr[xintr2], nintr2)

	    # Find all the intersection points of the inner polygon
	    # and the image line.
	    nintr1 = xp_pyclip (xin, yin, Memr[wk1], Memr[wk2], Memr[xintr1],
	        nver, lx, ld)

	    # There is no inner boundary to the sky annulus.
	    if (nintr1 <= 0) {
		do j = 1, nintr2, 2 {
		    xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			Memr[xintr2+j-1]))
		    xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			Memr[xintr2+j]))
		    c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		    c2 = min (int (xmax), int (IM_LEN(im,1)))
		    do k = c1, c2 {
			if (k < xmin || k > xmax)
			    next
			nskypix = nskypix + 1
			skypix[nskypix] = Memr[buf+k-1]
			coords[nskypix] = (k - colmin + 1) + nx * (i - linemin) 
		    }
		}
	    } else {
	        call asrtr (Memr[xintr1], Memr[xintr1], nintr1)
		jj = 1
		x1 = Memr[xintr1+jj-1]
		x2 = Memr[xintr1+jj]
		do j = 1, nintr2, 2 {
		    if (Memr[xintr2+j-1] < x1 && Memr[xintr2+j] > x2) {
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			    Memr[xintr2+j-1]))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5, x1))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k < xmin || k >= xmax)
			        next
			    nskypix = nskypix + 1
			    skypix[nskypix] = Memr[buf+k-1]
			    coords[nskypix] = (k - colmin + 1) + nx *
			        (i - linemin) 
		        }
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, x2))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			    Memr[xintr2+j]))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k <= xmin || k > xmax)
			        next
			    nskypix = nskypix + 1
			    skypix[nskypix] = Memr[buf+k-1]
			    coords[nskypix] = (k - colmin + 1) + nx *
			        (i - linemin) 
		        }
			jj = jj + 2
			if (jj < nintr1) {
			    x1 = Memr[xintr1+jj-1]
			    x2 = Memr[xintr1+jj]
			}
		    } else {
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			    Memr[xintr2+j-1]))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			    Memr[xintr2+j]))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k < xmin || k > xmax)
			        next
			    nskypix = nskypix + 1
			    skypix[nskypix] = Memr[buf+k-1]
			    coords[nskypix] = (k - colmin + 1) + nx *
			        (i - linemin) 
		        }
		    }
		}
	    }
	}

	call sfree (sp)

	return (nskypix)
end


# XP_PBSKYPIX -- Fetch the  sky pixels in a polygonal annulus defined by
# the vertices xin, yin and xout, yout, after detecting and rejecting any
# bad data.

int procedure xp_pbskypix (im, xin, yin, xout, yout, nver, datamin, datamax,
	skypix, coords, xc, yc, nx, ny, nbad)

pointer	im			#I the pointer to the input image
real	xin[ARB], yin[ARB]	#I the vertices of the inner polygon
real	xout[ARB], yout[ARB]	#I the vertices of the outer polygon
int	nver			#I the number of vertices
real	datamin			#I the minimum good data value
real	datamax			#I the maximum good data value
real	skypix[ARB]		#O the output array of sky pixels
int	coords[ARB]		#O the output sky pixel coordinates [i+nx*(j-1)]
real	xc, yc			#O the output sky subraster center coordinates
int	nx, ny			#O the output sky subraster dimensions
int	nbad			#O the number of baf pixels

int	i, j, jj, k, nskypix, linemin, linemax, colmin, colmax, nintr1, nintr2
int	c1, c2
pointer	sp, wk1, wk2, xintr1, xintr2, buf
real	xmin, xmax, ymin, ymax, lx, ld, x1, x2, pixel
int	xp_pyclip()
pointer	imgl2r()
real	asumr()

begin
	# Check the number of vertices.
	if (nver < 4)
	    return (0)

	# Check the limits of the polygons.
	call alimr (xout, nver, xmin, xmax)
	call alimr (yout, nver, ymin, ymax)
	
	if (xmax < 0.5 || xmin > IM_LEN(im,1) || ymax < 0.5 || ymin >
	    IM_LEN(im,2))
	    return (0)

	# Allocate working space.
	call smark (sp)
	call salloc (wk1, nver, TY_REAL)
	call salloc (wk2, nver, TY_REAL)
	call salloc (xintr1, nver, TY_REAL)
	call salloc (xintr2, nver, TY_REAL)

	# Find the minimum and maximum line numbers.
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))
	linemin = min (int (ymin + 0.5), int (IM_LEN(im,2)))
	linemax = min (int (ymax), int (IM_LEN(im,2)))
	ny = linemax - linemin + 1
	yc = asumr (yout, nver - 1) / (nver - 1) - linemin + 1

	# Find the minimum and maximum column numbers.
	xmin = max (0.5, min (real(IM_LEN(im,1) + 0.5), xmin))
	xmax = min (real (IM_LEN(im,1)+0.5), max (0.5, xmax))
	colmin = min (int (xmin + 0.5), int (IM_LEN(im,1)))
	colmax = min (int (xmax), int (IM_LEN(im,1)))
	nx = colmax - colmin + 1
	xc = asumr (xout, nver - 1) / (nver - 1) - colmin + 1

	# Set up the line segment parameters and initialize the sky pixel
	# count.
	xmin = 0.5
	xmax = IM_LEN(im,1) + 0.5
	lx = xmax - xmin
	nskypix = 0
	nbad = 0

	# Loop over the range of lines of interest.
	do i = linemin, linemax {

	    # Read in the image line
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next

	    # Check the line limits
	    if (ymin > i)
		ld = min (i + 1, linemax)
	    else if (ymax < i)
		ld = max (i - 1, linemin)
	    else
		ld = i

	    # Find all the intersection points of the outer polygon
	    # and the image line.
	    nintr2 = xp_pyclip (xout, yout, Memr[wk1], Memr[wk2], Memr[xintr2],
	        nver, lx, ld)
	    if (nintr2 <= 0)
		next
	    call asrtr (Memr[xintr2], Memr[xintr2], nintr2)

	    # Find all the intersection points of the inner polygon
	    # and the image line.
	    nintr1 = xp_pyclip (xin, yin, Memr[wk1], Memr[wk2], Memr[xintr1],
	        nver, lx, ld)

	    if (nintr1 <= 0) {
		do j = 1, nintr2, 2 {
		    xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			Memr[xintr2+j-1]))
		    xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			Memr[xintr2+j]))
		    c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		    c2 = min (int (xmax), int (IM_LEN(im,1)))
		    do k = c1, c2 {
			if (k < xmin || k > xmax)
			    next
			pixel = Memr[buf+k-1]
			if (pixel < datamin || pixel > datamax)
			    nbad = nbad + 1
			else {
			    nskypix = nskypix + 1
			    skypix[nskypix] = pixel
			    coords[nskypix] = (k - colmin + 1) + nx *
			        (i - linemin) 
			}
		    }
		}
	    } else {
	        call asrtr (Memr[xintr1], Memr[xintr1], nintr1)
		jj = 1
		x1 = Memr[xintr1+jj-1]
		x2 = Memr[xintr1+jj]
		do j = 1, nintr2, 2 {
		    if (Memr[xintr2+j-1] < x1 && Memr[xintr2+j] > x2) {
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			    Memr[xintr2+j-1]))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5, x1))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k < xmin || k >= xmax)
			        next
			    pixel = Memr[buf+k-1]
			    if (pixel < datamin || pixel > datamax)
				nbad = nbad + 1
			    else {
			        nskypix = nskypix + 1
			        skypix[nskypix] = pixel
			        coords[nskypix] = (k - colmin + 1) + nx *
			            (i - linemin) 
			    }
		        }
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, x2))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			    Memr[xintr2+j]))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k <= xmin || k > xmax)
			        next
			    pixel = Memr[buf+k-1]
			    if (pixel < datamin || pixel > datamax)
				nbad = nbad + 1
			    else {
			        nskypix = nskypix + 1
			        skypix[nskypix] = pixel
			        coords[nskypix] = (k - colmin + 1) + nx *
			            (i - linemin) 
			    }
		        }
			jj = jj + 2
			if (jj < nintr1) {
			    x1 = Memr[xintr1+jj-1]
			    x2 = Memr[xintr1+jj]
			}
		    } else {
		        xmin = min (real (IM_LEN(im,1) + 0.5), max (0.5, 
			    Memr[xintr2+j-1]))
		        xmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
			    Memr[xintr2+j]))
		        c1 = min (int (xmin + 0.5), int (IM_LEN(im,1)))
		        c2 = min (int (xmax), int (IM_LEN(im,1)))
		        do k = c1, c2 {
			    if (k < xmin || k > xmax)
			        next
			    pixel = Memr[buf+k-1]
			    if (pixel < datamin || pixel > datamax)
				nbad = nbad + 1
			    else {
			        nskypix = nskypix + 1
			        skypix[nskypix] = pixel
			        coords[nskypix] = (k - colmin + 1) + nx *
			            (i - linemin) 
			    }
		        }
		    }
		}
	    }
	}

	call sfree (sp)

	return (nskypix)

end


# XP_RVERTICES -- Compute the vertices of the inner and outer sky annulus
# rectangles.

procedure xp_rvertices (wx, wy, rannulus, wannulus, ratio, theta, xin, yin,
	xout, yout)

real	wx, wy			#I the center of the rectangular annulus
real	rannulus		#I the half-width of the inner rectangle
real	wannulus		#I the width of the annulus
real	ratio			#I the ratio of short to long axes
real	theta			#I the position angle of the long axis
real	xin[ARB], yin[ARB]	#O the inner rectangle vertices
real	xout[ARB], yout[ARB]	#O the inner rectangle vertices

begin
	# Construct the rotated polygon.
	if (rannulus <= 0.0) {
	    call aclrr (xin, 4)
	    call aclrr (yin, 4)
            call xp_pyrectangle (wannulus, ratio, theta, xout, yout) 
	} else {
	    call xp_pyrectangle (rannulus, ratio, theta, xin, yin) 
	    call aaddkr (xin, wx, xin, 4)
	    call aaddkr (yin, wy, yin, 4)
	    call xp_pyrectangle (wannulus, ratio, theta, xout, yout) 
	}

	# Shift it to the center coordinates.
	call aaddkr (xout, wx, xout, 4)
	call aaddkr (yout, wy, yout, 4)

	# Close the polygon.
	xin[5] = xin[1]; yin[5] = yin[1]
	xout[5]= xout[1]; yout[5] = yout[1]
end
