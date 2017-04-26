include <mach.h>
include <math.h>
include <gio.h>
include <gset.h>
include <imhdr.h>
include <imset.h>
include <math/nlfit.h>
include "../lib/impars.h"

define	XP_FIT_INWIDTH  8.0
define	XP_FIT_ANWIDTH  16.0
define	XP_FIT_OUTWIDTH 24.0

define	XP_FIT_NPARS	7
define	XP_FIT_MAXITER	10
define	XP_FIT_KREJECT	3.0
define	XP_FIT_NREJECT	0
define	XP_FIT_TOL	0.001

define	FWHM_TO_SIGMA	0.42467

# XP_PMODFIT -- Fit a model to the data and print the results.

int procedure xp_pmodfit (gd, xp, im, wx, wy, rl, wcs, plotit, interactive)

pointer	gd			#I pointer to the graphics stream
pointer	xp			#I pointer to the xapphot data structure
pointer	im			#I pointer to the input image
real	wx, wy			#I the coordinates of the input object
int	rl			#I the output file descriptor
int	wcs			#I the wcs number for the plot.
int	plotit			#I plot the results
int	interactive		#I interact with the plot ?

int	i, ier, gwcs, gkey, update, wcs_save[LEN_WCSARRAY]
pointer	sp, mpars, pars, epars, gcmd
real	gwx, gwy
int	xp_elfit(), clgcur(), xp_icolon()
real	xp_statr()

begin
	call smark (sp)
	call salloc (mpars, XP_FIT_NPARS + 1, TY_REAL)
	call salloc (pars, XP_FIT_NPARS + 1, TY_REAL)
	call salloc (epars, XP_FIT_NPARS + 1, TY_REAL)
	call salloc (gcmd, SZ_LINE, TY_CHAR)

	# Update the parameters and output file.
	update = NO

	# Fit the model.
	ier = xp_elfit (xp, im, wx, wy, Memr[mpars], Memr[pars], Memr[epars])

	# Print the results and quit.
	if (plotit == NO) {
	    call xp_pelfit (Memr[pars], Memr[epars], XP_FIT_NPARS, ier, NO)
	    call sfree (sp)
	    return (update)
	}

	# Graph and print the results.
	call xp_gelfit (gd, xp, im, Memr[pars], Memr[epars], XP_FIT_NPARS,
	    ier, wcs)
	call xp_pelfit (Memr[pars], Memr[epars], XP_FIT_NPARS, ier, NO)

	if (interactive == YES) {

            # Save the old wcs structure if any.
            call gflush (gd)
            call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

            # Zero out the other wcs.
            do i = 1, wcs - 1
                call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
            do i = wcs + 1, MAX_WCS
                call amovki (0, Memi[GP_WCSPTR(gd,i)], LEN_WCS)
            GP_WCSSTATE(gd) = MODIFIED
            call gpl_cache (gd)


	    while (clgcur ("gcommands", gwx, gwy, gwcs, gkey, Memc[gcmd],
	        SZ_LINE) != EOF) {

		switch (gkey) {

		# Break.
		case 'q':
		    break

		# Set the half-width at half-maximum to the fitted value
		case 'h':
		    if (ier == OK) {
			call xp_setr (xp, IHWHMPSF, Memr[pars+3] / 2.0 /
			    xp_statr(xp, ISCALE))
			call printf (
			    "The new hmhmpsf value is: %0.2f scale units\n")
			    call pargr (Memr[pars+3] / 2.0 / xp_statr(xp,
				ISCALE))
			update = YES
		    } else
			call printf ("Error fitting profile\n")

		# Refit.
		case 'f':
		    ier = xp_elfit (xp, im, wx, wy, Memr[mpars], Memr[pars],
		        Memr[epars])
		    call xp_gelfit (gd, xp, im, Memr[pars], Memr[epars],
		        XP_FIT_NPARS, ier, wcs)
		    call xp_pelfit (Memr[pars], Memr[epars], XP_FIT_NPARS,
		        ier, NO)

		# Replot.
		case 'r':
		    call xp_gelfit (gd, xp, im, Memr[pars], Memr[epars],
		        XP_FIT_NPARS, ier, wcs)

		# Print the fit.
		case 'p':
		    call xp_pelfit (Memr[pars], Memr[epars], XP_FIT_NPARS,
		        ier, NO)

		# Print the moments analysis.
		case 'm':
		    call xp_pelfit (Memr[mpars], Memr[epars], XP_FIT_NPARS,
		        ier, YES)

		# Set the impars parameters.
		case ':':
		    update = xp_icolon (gd, xp, im, rl, Memc[gcmd])

		default:
		    ;
		}

	    }


           # Restore the old wcs array.
            call gflush (gd)
            call amovi (wcs_save, Memi[GP_WCSPTR(gd,1)], LEN_WCSARRAY)
            GP_WCSSTATE(gd) = MODIFIED
            call gpl_cache (gd)

	}

	call sfree (sp)

	return (update)
end


# XP_ELFIT -- Fit an elliptical Gaussian model to the data.

int procedure xp_elfit (xp, im, wx, wy, mpars, pars, epars)

pointer	xp			#I pointer to the xapphot data structure
pointer	im			#I pointer to the input image
real	wx, wy			#I the coordinates of the input object
real	mpars[ARB]		#O results of the moment analysis
real	pars[ARB]		#O results of the model fit
real	epars[ARB]		#O errors in the model fit

int	inwidth, anwidth, outwidth, niter, fnx, fny, ier, npar, nborder, ngood
pointer	fbuf, bbuf
real	nwx, nwy, fxc, fyc, mthreshold, mean, sigma
real	gdatamin, gdatamax, datamin, datamax, threshold

int	xp_stati(), xp_qmodmom(), xp_modmom(), xp_modegauss(), xp_border()
int	xp_znmedian()
pointer	xp_fbuf()
real	xp_statr(), amedr()

begin
	# Initialize.
	call amovkr (INDEFR, mpars, XP_FIT_NPARS)
	call amovkr (INDEFR, pars, XP_FIT_NPARS)
	call amovkr (INDEFR, epars, XP_FIT_NPARS)

	# Compute the required subraster sizes. 
	inwidth = nint (XP_FIT_INWIDTH * xp_statr(xp, IHWHMPSF))
	if (mod (inwidth, 2) == 0)
	    inwidth = inwidth + 1
	anwidth = nint (XP_FIT_ANWIDTH * xp_statr(xp, IHWHMPSF))
	if (mod (anwidth, 2) == 0)
	    anwidth = anwidth + 1
	outwidth = nint (XP_FIT_OUTWIDTH * xp_statr(xp, IHWHMPSF))
	if (mod (outwidth, 2) == 0)
	    outwidth = outwidth + 1

	# Set the threshold.
	mthreshold = INDEFR

	# Compute the good data minimum and maximum.
        if (IS_INDEFR(xp_statr(xp,IMINDATA)))
            gdatamin = -MAX_REAL
        else
            gdatamin = xp_statr(xp,IMINDATA)
        if (IS_INDEFR(xp_statr(xp,IMAXDATA)))
            gdatamax = MAX_REAL
        else
            gdatamax = xp_statr(xp,IMAXDATA)

	# Initialize the moments analysis.
	niter = 0
	nwx = wx
	nwy = wy

	# Find the center of the object.
	repeat {

	    # Get the data buffer.
	    fbuf = xp_fbuf (im, nwx, nwy, inwidth, fxc, fyc, fnx, fny)
	    if (fbuf == NULL)
	        return (ERR)

	    # Do the moments analysis.
	    call alimr (Memr[fbuf], fnx * fny, datamin, datamax)
	    if (xp_stati(xp,IEMISSION) == YES) {
	        ier = xp_qmodmom (Memr[fbuf], fnx, fny, gdatamin, gdatamax,
		    datamin, YES, mpars)
	    } else {
	        ier = xp_qmodmom (Memr[fbuf], fnx, fny, gdatamin, gdatamax,
		    datamax, NO, mpars)
	    }
	    if (ier == ERR)
		return (ERR)

	    # Compute new coordinates.
	    nwx = mpars[2] + nwx - fxc
	    nwy = mpars[3] + nwy - fyc
	    if (abs (nwx - wx) < 1.0 && abs (nwy - wy) < 1.0)
		break

	    niter = niter + 1

	} until (niter >= 3)

	# Get the final data buffer.
	if (IS_INDEFR(mthreshold)) {
	    fbuf = xp_fbuf (im, nwx, nwy, outwidth, fxc, fyc, fnx, fny)
	    if (fbuf == NULL)
	        return (ERR)
	    nborder = xp_border (Memr[fbuf], fnx, fny, anwidth, anwidth, bbuf)
	    if (nborder <= 0 || bbuf == NULL) {
		threshold = amedr (Memr[fbuf], fnx * fny)
                call aavgr (Memr[fbuf], fnx * fny, mean, sigma)
	    } else  {
	        ngood = xp_znmedian (Memr[bbuf], nborder, threshold, sigma,
		    3.0, 3.0)
	        if (ngood <= 0) {
		    threshold = amedr (Memr[bbuf], nborder)
                    call aavgr (Memr[bbuf], nborder, mean, sigma)
		} else {
                    call aavgr (Memr[bbuf], ngood, mean, sigma)
		}
	    }
	    if (bbuf != NULL)
	        call mfree (bbuf, TY_REAL)
	} else
	    threshold = mthreshold

	# Get the final data fitting buffer.
	fbuf = xp_fbuf (im, nwx, nwy, inwidth, fxc, fyc, fnx, fny)
	if (fbuf == NULL)
	    return (ERR)

	# Fit an elliptical Gaussian function to the data. Use a full second
	# order moments analysis to get initial estimates for the parameters.
	if (xp_stati(xp,IEMISSION) == YES) {
	    ier = xp_modmom (Memr[fbuf], fnx, fny, gdatamin, gdatamax,
	        threshold, YES, mpars)
	    ier = xp_modegauss (Memr[fbuf], fnx, fny, gdatamin, gdatamax, YES,
		xp_stati(xp,INOISEMODEL), xp_statr(xp,IGAIN),
		xp_statr(xp,IREADNOISE), xp_statr(xp, IHWHMPSF) *
		xp_statr(xp,ISCALE), XP_FIT_TOL, XP_FIT_MAXITER,
		XP_FIT_KREJECT, XP_FIT_NREJECT, mpars, pars, epars, npar)
	} else {
	    ier = xp_modmom (Memr[fbuf], fnx, fny, gdatamin, gdatamax,
	        threshold, NO, mpars)
	    ier = xp_modegauss (Memr[fbuf], fnx, fny, gdatamin, gdatamax, NO,
		xp_stati(xp,INOISEMODEL), xp_statr(xp,IGAIN),
		xp_statr(xp,IREADNOISE), xp_statr(xp,IHWHMPSF) *
		xp_statr(xp,ISCALE), XP_FIT_TOL, XP_FIT_MAXITER,
		XP_FIT_KREJECT, XP_FIT_NREJECT, mpars, pars, epars, npar)
	}

	# If the model fitting failed set the amplitude and sky parameters
	# to INDEF and replace the remaining parameters with ones derived
	# from a moments analysis.
	if (ier == ERR) {
	    pars[1] = INDEFR
	    pars[2] = mpars[2]
	    pars[3] = mpars[3]
	    pars[4] = mpars[4]
	    pars[5] = mpars[5]
	    pars[6] = mpars[6]
	    pars[7] = mpars[7]
	}
	pars[8] = sigma

	# Compute the final coordinates.
	mpars[2] = mpars[2] + nwx - fxc
	mpars[3] = mpars[3] + nwy - fyc
	mpars[8] = sigma
	pars[2] = pars[2] + nwx - fxc
	pars[3] = pars[3] + nwy - fyc
	mpars[8] = sigma

	return (ier)
end


# XP_GELFIT -- Graph the results.

procedure xp_gelfit (gd, xp, im, pars, epars, npars, ier, wcs)

pointer	gd			#I the input graphics stream
pointer	xp			#I the pointer to the xapphot structure
pointer	im			#I pointer to the input image
real	pars[ARB]		#I the fitted parameter values
real	epars[ARB]		#I the fitted parameter value errors
int	npars			#I the number of parameters
int	ier			#I the error code
int	wcs			#I the input wcs

int	outwidth, fnx, fny
pointer	fbuf
real	fxc, fyc
pointer	xp_fbuf()
real	xp_statr()

begin
	outwidth = nint (XP_FIT_OUTWIDTH * xp_statr(xp, IHWHMPSF))
	if (mod (outwidth, 2) == 0)
	    outwidth = outwidth + 1

	# Get the data.
	fbuf = xp_fbuf (im, pars[2], pars[3], outwidth, fxc, fyc, fnx, fny)
	if (fbuf != NULL)
	    call xp_plelfit (gd, Memr[fbuf], fnx, fny, pars[2], pars[3],
	        outwidth, fxc, fyc, pars[1], pars[4], pars[5], pars[6],
		pars[7], ier, wcs)
end


# XP_PLELFIT -- Plot the major axis profile and the fit.

procedure xp_plelfit (gd, data, nx, ny, wx, wy, outwidth, xc, yc, amp, fwhmpsf,
	axratio, theta, sky, ier, wcs)

pointer	gd			#I the input graphics stream
real	data[nx,ny]		#I the input subraster
int	nx, ny			#I the dimensions of the subraster
real	wx, wy			#I the image position
int	outwidth		#I the width of the data box
real	xc, yc			#I the center of the subraster
real	amp			#I the amplitude of the gaussian
real	fwhmpsf			#I the fwhmpsf of the gaussian
real	axratio			#I the axis ratio of the gaussian
real	theta			#I the position angle of the gaussian
real	sky			#I the background value
int	ier			#I the error code
int	wcs			#I the input wcs

int	i, j
real	dmax, d2max, rmin, rmax, ymin, ymax
real	aratio, atheta, aa, bb, cc, ff, dy, dy2, dx, dx2, dist, r
pointer	sp, title
int	wcs_save[LEN_WCSARRAY]

begin
	if (gd == NULL)
	    return

        # Save the WCS for raster 1, the image raster. Note that this is
        # an interace violation but it might work for now.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Clear the screen.
	call gclear (gd)

	# Set the wcs and viewport.
	call gseti (gd, G_WCS, wcs)
	call gsview (gd, 0.10, 0.95, 0.10, 0.95)

	# Set the plots limits.
	dmax = (outwidth - 1) / 2.0
	d2max = dmax * dmax
	rmin = -1.0
	rmax = nint (dmax + 1.0)
	call alimr (data, nx * ny, ymin, ymax)
	dy = ymax - ymin
	ymin = ymin - 0.05 * dy
	ymax = ymax + 0.05 * dy

	# Set up the plot axes and labels
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)
        call sprintf (Memc[title], SZ_LINE,
	    "Semi-major Axis Profile at %.2f %.2f")
            call pargr (wx)
            call pargr (wy)
        call gswind (gd, rmin, rmax, ymin, ymax)
        call xp_rgfill (gd, rmin, rmax, ymin, ymax, GF_SOLID, 0)
        #call glabax (gd, Memc[title], "Semi-major axis (pixels)", "Counts")
        call gseti (gd, G_YNMINOR, 0)
        call glabax (gd, Memc[title], "", "")
	call sfree (sp)

	# Compute the parameters of the ellipse.
	if (IS_INDEFR(axratio))
	    aratio = 1.0
	else
	    aratio = axratio
	if (IS_INDEFR(theta))
	    atheta = 0.0
	else
	    atheta = theta
	call xp_ellipse (dmax, aratio, atheta, aa, bb, cc, ff)
	aa = aa / d2max
	bb = bb / d2max
	cc = cc / d2max
	ff = ff / d2max

	# Plot the data points.
	do j = 1, ny {
	    dy = (yc - j)
	    dy2 = dy * dy
	    do i = 1, nx {
		dx = (xc - i)
		dx2 = dx * dx
		dist = aa * dx2 + bb * dx * dy + cc * dy2
		if (dist > ff)
		    next
		r = sqrt (dist) / aratio
		call gmark (gd, r, data[i,j], GM_PLUS, 1.0, 1.0)
	    }
	}

	# Plot the fit.
	if (ier == OK) {

	    # Mark the 0 radius.
	    call gamove (gd, 0.0, ymin)
	    call gadraw (gd, 0.0, ymax)

	    # Mark the background.
	    call gamove (gd, rmin, sky)
	    call gadraw (gd, rmax, sky)

	    call gseti (gd, G_PLTYPE, GL_DASHED)

	    # Plot the fitted curve.
	    call gamove (gd, 0.0, amp + sky)
	    dx2 = 2.0 * (FWHM_TO_SIGMA * fwhmpsf) ** 2
	    for (r = 0.5; r <= dmax; r = r + 0.5) {
		dist = amp * exp (-(r * r) / dx2) + sky
		call gadraw (gd, r, dist) 
	    }

	    # Mark the half-width at half maximum.
	    call gamove (gd, fwhmpsf / 2.0, ymin)
	    call gadraw (gd, fwhmpsf / 2.0, ymax)

	    call gseti (gd, G_PLTYPE, GL_SOLID)
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


# XP_PELFIT -- Print the results of the elliptical Gaussian model fit.

procedure xp_pelfit (pars, epars, npars, ier, moments)

real	pars[ARB]		#I the fitted parameter values
real	epars[ARB]		#I the fitted parameter errors
int	npars			#I the number of parameters
int	ier			#I the error code
int	moments			#I moments analysis

begin
	if (moments == YES) {
	    call printf (
	   "X: %0.2f Y: %0.2f F: %g Hw: %0.2f Ax: %0.2f Pa: %0.1f Sky: %g %g\n")
	} else {
	    call printf (
	   "X: %0.2f Y: %0.2f A: %g Hw: %0.2f Ax: %0.2f Pa: %0.1f Sky: %g %g\n")
	}

	if (ier != OK) {
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	    call pargr (INDEFR)
	} else {
	    call pargr (pars[2])
	    call pargr (pars[3])
	    call pargr (pars[1])
	    call pargr (pars[4] / 2.0)
	    call pargr (pars[5])
	    call pargr (pars[6])
	    call pargr (pars[7])
	    call pargr (pars[8])
	}
end


# XP_FBUF -- Get the image pixels inside the fitting box.

pointer procedure xp_fbuf (im, wx, wy, width, xc, yc, nx, ny)

pointer im              #I the pointer to the IRAF image
real    wx, wy          #I the center of the subraster to be extracted
int     width           #I the  width of subraster to be extracted
real    xc, yc          #O the center of extracted subraster 
int     nx, ny          #O the dimensions of extracted subraster

int     ncols, nlines, c1, c2, l1, l2, half_width
pointer buf
real    xc1, xc2, xl1, xl2
pointer imgs2r()

begin
        # Check for nonsensical input.
        half_width = (width - 1) / 2
        if (half_width <= 0)
            return (NULL)

        # Test for out of bounds pixels
        ncols = IM_LEN(im,1)
        nlines = IM_LEN(im,2)
        xc1 = wx - half_width
        xc2 = wx + half_width
        xl1 = wy - half_width
        xl2 = wy + half_width
        if (xc1 > real (ncols) || xc2 < 1.0 || xl1 > real (nlines) || xl2 < 1.0)
            return (NULL)

        # Get column and line limits, dimensions and center of subraster.
        c1 = max (1.0, min (real (ncols), xc1)) + 0.5
        c2 = min (real (ncols), max (1.0, xc2)) + 0.5
        l1 = max (1.0, min (real (nlines), xl1)) + 0.5
        l2 = min (real (nlines), max (1.0, xl2)) + 0.5
        nx = c2 - c1 + 1
        ny = l2 - l1 + 1
        xc = wx - c1 + 1
        yc = wy - l1 + 1

        # Get pixels and return.
        buf = imgs2r (im, c1, c2, l1, l2)
        if (buf == EOF)
            return (NULL)
        else
            return (buf)
end


# XP_BORDER -- Fetch the border pixels from a 2D subraster.

int procedure xp_border (buf, nx, ny, pnx, pny, ptr)

real    buf[nx,ARB]     #I the input data subraster
int     nx, ny          #I the dimensions of the input subraster
int     pnx, pny        #I the size of the data region
pointer ptr             #I the pointer to the output buffer

int     j, nborder, wxborder, wyborder, index

begin
        # Are there any border pixels at all.
        if ((nx * ny - pnx * pny) <= 0) {
            ptr = NULL
            return (0)
        }

	# Are there both x and y border pixels.
        wxborder = (nx - pnx) / 2
        wyborder = (ny - pny) / 2
	if (wxborder < 1 || wyborder < 1) {
            ptr = NULL
            return (0)
	}

	nborder = nx * ny - (nx - 2 * wxborder) * (ny - 2 * wyborder)
        call malloc (ptr, nborder, TY_REAL)

        # Fill the array.
        index = ptr
        do j = 1, wyborder {
            call amovr (buf[1,j], Memr[index], nx)
            index = index + nx
        }
        do j = wyborder + 1, ny - wyborder {
            call amovr (buf[1,j], Memr[index], wxborder)
            index = index + wxborder
            call amovr (buf[nx-wxborder+1,j], Memr[index], wxborder)
            index = index + wxborder
        }
        do j = ny - wyborder + 1, ny {
            call amovr (buf[1,j], Memr[index], nx)
            index = index + nx
        }

        return (nborder)
end


# XP_ZNMEDIAN -- Compute the median and number of good points in the array
# with one level of rejection.

int procedure xp_znmedian (data, npts, median, sigma, lcut, hcut)

real    data[ARB]       #I the input data array
int     npts            #I the number of data points
real    median          #O the median of the data
real	sigma           #O the sigma of the data
real    lcut, hcut      #I the good data limits

int     i, ngpts, lindex, hindex
pointer sp, sdata
real    mean, dif, lo, hi
real    amedr()

begin
	if (npts <= 0)
	    return (0)

        if (IS_INDEFR (lcut) && IS_INDEFR(hcut))  {
            median = amedr (data, npts)
            call aavgr (data, npts, mean, sigma)
            return (npts)
        }

        # Allocate working space.
        call smark (sp)
        call salloc (sdata, npts, TY_REAL)
        call asrtr (data, Memr[sdata], npts)
        if (mod (npts, 2) == 0)
            median = (Memr[sdata+(1+npts)/2-1] + Memr[sdata+(1+npts)/2]) / 2.0
        else
            median = Memr[sdata+(1+npts)/2-1]

        # Compute the sigma.
        call aavgr (Memr[sdata], npts, mean, sigma)
        if (sigma <= 0.0) {
            call sfree (sp)
            return (npts)
        }

        # Do rejection.
        ngpts = npts
        if (IS_INDEFR(lo))
            lo = -MAX_REAL
        else
            lo = -lcut * sigma
        if (IS_INDEFR(hi))
            hi = MAX_REAL
        else
            hi = hcut * sigma

        do i = 1, npts {
            lindex = i
            dif = Memr[sdata+i-1] - median
            if (dif >= lo)
                break
        }
        do i = npts, 1, -1 {
            hindex = i
            dif = Memr[sdata+i-1] - median
            if (dif <= hi)
                break
        }

        ngpts = hindex - lindex + 1
        if (ngpts <= 0) {
            median = INDEFR
	    sigma = INDEFR
        } else if (mod (ngpts, 2) == 0) {
            median = (Memr[sdata+lindex-1+(ngpts+1)/2-1] + Memr[sdata+lindex-1+
                (ngpts+1)/2]) / 2.0
            call aavgr (Memr[sdata+lindex-1], ngpts, mean, sigma)
        } else {
            median = Memr[sdata+lindex-1+(ngpts+1)/2-1]
            call aavgr (Memr[sdata+lindex-1], ngpts, mean, sigma)
	}

        call sfree (sp)

        return (ngpts)
end

# XP_QMODMOM -- Compute the 0th and 1st moments of an image in order to estimate
# the x,y center.

int procedure xp_qmodmom (ctrpix, nx, ny, lthreshold, uthreshold, threshold,
	positive, par)

real    ctrpix[nx, ny]          #I data subraster for moments compuation
int     nx, ny                  #I dimensions of the subraster
real    lthreshold              #I lower threshold for moments computation
real    uthreshold              #I upper threshold for moments computation
real    threshold               #I background threshold for moments computation
int     positive                #I emission feature ?
real    par[ARB]                #I computed parameters

int	i, j
double	sumi, sumxi, sumyi
real	temp
bool	fp_equald()

begin
        # Initialize the sums.
        sumi = 0.0d0
        sumxi = 0.0d0
        sumyi = 0.0d0

        # Accumulate the moments.
        if (positive == YES) {
            do j = 1, ny {
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = ctrpix[i,j] - threshold
                    if (temp <= 0.0)
                        next
                    sumi = sumi + temp
                    sumxi = sumxi + i * temp
                    sumyi = sumyi + j * temp
                }
            }
        } else {
            do j = 1, ny {
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = threshold - ctrpix[i,j]
                    if (temp <= 0.0)
                        next
                    sumi = sumi + temp
                    sumxi = sumxi + i * temp
                    sumyi = sumyi + j * temp
                }
            }
	}

        # Compute the parameters.
        if (fp_equald (sumi, 0.0d0)) {
            par[1] = 0.0
            par[2] = (1 + nx) / 2.0
            par[3] = (1 + ny) / 2.0
            par[4] = INDEFR
            par[5] = INDEFR
            par[6] = INDEFR
            par[7] = threshold
        } else {
            par[1] = sumi
            par[2] = sumxi / sumi
            par[3] = sumyi / sumi
	    par[4] = INDEFR
	    par[5] = INDEFR
	    par[6] = INDEFR
            par[7] = threshold
	}
end


# XP_MODMOM -- Compute the 0, 1st and second moments of an image and estimate
# the x,y center, the ellipticity and the position angle.

int procedure xp_modmom (ctrpix, nx, ny, lthreshold, uthreshold, threshold,
	positive, par)

real    ctrpix[nx, ny]          #I data subraster for moments compuation
int     nx, ny                  #I dimensions of the subraster
real    lthreshold              #I lower threshold for moments computation
real    uthreshold              #I upper threshold for moments computation
real	threshold		#I background threshold for moments computation
int     positive                #I emission feature ?
real    par[ARB]                #I computed parameters

int     i, j
double	sumi, sumxi, sumyi, sumx2i, sumy2i, sumxyi, temp, dx, dy, diff, r2
bool    fp_equald()

begin
        # Initialize the sums.
        sumi = 0.0d0
        sumxi = 0.0d0
        sumyi = 0.0d0
        sumxyi = 0.0d0
        sumx2i = 0.0d0
        sumy2i = 0.0d0

        # Accumulate the moments.
        if (positive == YES) {
            do j = 1, ny {
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = ctrpix[i,j] - threshold
                    if (temp <= 0.0)
                        next
                    sumi = sumi + temp
                    sumxi = sumxi + i * temp
                    sumyi = sumyi + j * temp
                }
            }
        } else {
            do j = 1, ny {
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = threshold - ctrpix[i,j]
                    if (temp <= 0.0)
                        next
                    sumi = sumi + temp
                    sumxi = sumxi + i * temp
                    sumyi = sumyi + j * temp
                }
            }
        }

	if (fp_equald (sumi, 0.0d0)) {
	    par[1] = 0.0
            par[2] = (1 + nx) / 2.0
            par[3] = (1 + ny) / 2.0
            par[4] = INDEFR
            par[5] = INDEFR
            par[6] = INDEFR
            par[7] = threshold
	    return (OK)
	}

        par[1] = sumi
        par[2] = sumxi / sumi
        par[3] = sumyi / sumi
        par[4] = INDEFR
        par[5] = INDEFR
        par[6] = INDEFR
        par[7] = threshold

        # Accumulate the moments.
        if (positive == YES) {
            do j = 1, ny {
		dy = j - par[3]
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = ctrpix[i,j] - threshold
                    if (temp <= 0.0)
                        next
		    dx = i - par[2]
                    sumx2i = sumx2i + temp * dx * dx
                    sumxyi = sumxyi + temp * dx * dy
		    sumy2i = sumy2i + temp * dy * dy
                }
            }
	} else {
            do j = 1, ny {
		dy = j - par[3]
                do i = 1, nx {
                    if (ctrpix[i,j] < lthreshold || ctrpix[i,j] > uthreshold)
                        next
                    temp = threshold - ctrpix[i,j]
                    if (temp <= 0.0)
                        next
		    dx = i - par[2]
                    sumx2i = sumx2i + temp * dx * dx
                    sumxyi = sumxyi + temp * dx * dy
		    sumy2i = sumy2i + temp * dy * dy
                }
            }
	}

        # Compute the parameters.
	sumx2i = sumx2i / sumi
	sumy2i = sumy2i / sumi
	sumxyi = sumxyi / sumi
        r2 = sumx2i+ sumy2i
        if (r2 <= 0.0d0) {
            par[4] = INDEFR
            par[5] = INDEFR
            par[6] = INDEFR
        } else {
            par[4] = 2.0 * sqrt (LN_2 * r2)
	    diff = sumx2i - sumy2i
            par[5] = 1.0d0 - sqrt (diff ** 2 + 4.0 * sumxyi ** 2) / r2
	    par[5] = max (0.0, min (par[5], 1.0))
	    if (fp_equald (diff, 0.0d0) && fp_equald (sumxyi, 0.0d0))
		par[6] = 0.0
	    else
                par[6] = RADTODEG (0.5d0 * atan2 (2.0d0 * sumxyi, diff)) 
	    if (par[6] < 0.0)
	        par[6] = par[6] + 180.0
        }

        return (OK)
end


# XP_MODEGAUSS -- Fit an elliptical gaussian to the data using non-linear
# least squares techniques. 

int procedure xp_modegauss (ctrpix, nx, ny, datamin, datamax, emission,
	noise, gain, rdnoise, hwhmpsf, tol, maxiter, kreject, nreject,
	inpar, outpar, outperr, npar)

real    ctrpix[nx,ny]           #I the data subraster containing data to be fit
int     nx, ny                  #I the dimensions of the data subraster
real    datamin                 #I the minimum good data value
real    datamax                 #I the maximum good data value
int     emission                #I an emission or absorption object ?
int     noise                   #I the noise model
real    gain                    #I the gain value in e- / count
real    rdnoise                 #I the readout noise in e-
real	hwhmpsf			#I the estimated input hwhm of the psf
real	tol			#I fitting tolerance
int     maxiter			#I the maximum number of iterations
real    kreject                 #I the ksigma rejection criterion
int     nreject                 #I the maximum number of rejection cycles
real    inpar[ARB]              #I the input parameter values
real    outpar[ARB]             #O the output parameter values
real    outperr[ARB]            #O the errors in the output parameters
int	npar			#O the number of parameters

extern  xp_felgauss, xp_felgaussd
int     i, j, npts, fier, imin, imax
pointer sp, x, w, list, zfit, nl, ptr
real    sumw, dummy, chisqr, locut, hicut
int     locpr(), xp_reject()
real    asumr(), xp_wssqr()

begin
        # Initialize.
        npts = nx * ny
        if (npts < XP_FIT_NPARS)
            return (ERR)

        # Allocate working space.
        call smark (sp)
        call salloc (x, 2 * npts, TY_REAL)
        call salloc (w, npts, TY_REAL)
        call salloc (zfit, npts, TY_REAL)
        call salloc (list, XP_FIT_NPARS, TY_INT)

        # Define the active parameters. Note that all are active except the
	# sky.
        do i = 1, XP_FIT_NPARS - 1
        #do i = 1, XP_FIT_NPARS
            Memi[list+i-1] = i

        # Set up the x and y variables array.
        ptr = x
        do j = 1, ny {
            do i = 1, nx {
                Memr[ptr] = i
                Memr[ptr+1] = j
                ptr = ptr + 2
            }
        }

        # Set up the weight array.
        switch (noise) {
        case XP_INPOISSON:
            #call amaxkr (ctrpix, 0.0, Memr[w], npts)
            #if (gain > 0.0)
                #call adivkr (Memr[w], gain, Memr[w], npts)
            #if (rdnoise > 0.0 && gain > 0.0)
                #call aaddkr (Memr[w], (rdnoise / gain) ** 2, Memr[w], npts)
            #call xp_reciprocal (Memr[w], Memr[w], npts, 1.0)
            call amovkr (1.0, Memr[w], npts)
        default:
            call amovkr (1.0, Memr[w], npts)
        }

        # Initialize the fitting parameters.
        if (emission == YES)
            call xp_wlimr (ctrpix, Memr[w], nx * ny, datamin, datamax,
                outpar[7], outpar[1], imin, imax)
        else
            call xp_wlimr (ctrpix, Memr[w], nx * ny, datamin, datamax,
                outpar[7], outpar[1], imax, imin)
	outpar[7] = inpar[7]
        outpar[1] = outpar[1] - outpar[7]

	if (IS_INDEFR(inpar[3])) {
            if (mod (imax, nx) == 0)
                imin = imax / nx
            else
                imin = imax / nx + 1
            outpar[3] = imin
	} else 
	    outpar[3] = inpar[3]
	if (IS_INDEFR(inpar[2])) {
            imin = imax - (imin - 1) * nx
            outpar[2] = imin
	} else
	    outpar[2] = inpar[2]
	if (IS_INDEFR(inpar[4]))
            outpar[4] = 2.0* FWHM_TO_SIGMA * hwhmpsf
	else
	    outpar[4] = FWHM_TO_SIGMA * inpar[4] 
	if (IS_INDEFR(inpar[5]))
            outpar[5] = 1.0
	else
	    outpar[5] = inpar[5]
	if (IS_INDEFR(inpar[6]))
            outpar[6] = 0.0
	else
	    outpar[6] = DEGTORAD(inpar[6])

        # Compute the initial fit.
        call nlinitr (nl, locpr (xp_felgauss), locpr (xp_felgaussd), outpar,
	    outperr, XP_FIT_NPARS, Memi[list], XP_FIT_NPARS - 1, tol, maxiter)
	    #outperr, XP_FIT_NPARS, Memi[list], XP_FIT_NPARS, tol, maxiter)
        call nlfitr (nl, Memr[x], ctrpix, Memr[w], npts, 2, WTS_USER, fier)

        # Perform the rejection cycle.
        if (nreject > 0 && kreject > 0.0) {
            do i = 1, nreject {
                call nlvectorr (nl, Memr[x], Memr[zfit], npts, 2)
                call asubr (ctrpix, Memr[zfit], Memr[zfit], npts)
                chisqr = xp_wssqr (Memr[zfit], Memr[w], npts)
                sumw = asumr (Memr[w], npts)
                if (sumw <= 0.0)
                    break
                if (chisqr <= 0.0)
                    break
                else
                    chisqr = sqrt (chisqr / sumw)
                locut = - kreject * chisqr
                hicut = kreject * chisqr
                if (xp_reject (Memr[zfit], Memr[w], npts, locut, hicut) == 0)
                    break
                call nlpgetr (nl, outpar, npar)
                call nlfreer (nl)
                call nlinitr (nl, locpr (xp_felgauss), locpr (xp_felgaussd),
		    outpar, outperr, XP_FIT_NPARS, Memi[list], XP_FIT_NPARS - 1,
		    #outpar, outperr, XP_FIT_NPARS, Memi[list], XP_FIT_NPARS,
		    tol, maxiter)
                call nlfitr (nl, Memr[x], ctrpix, Memr[w], npts, 2, WTS_USER,
                    fier)
            }
        }

        # Fetch the parameters.
        call nlvectorr (nl, Memr[x], Memr[zfit], npts, 2)
        call nlpgetr (nl, outpar, npar)
	outpar[4] = abs(outpar[4]) / FWHM_TO_SIGMA
	outpar[5] = abs(outpar[5])
	outpar[6] = RADTODEG(outpar[6])

        # Fetch the errors.
        call nlerrorsr (nl, ctrpix, Memr[zfit], Memr[w], npts, dummy,
            chisqr, outperr)
	outperr[4] = abs(outperr[4])
	outperr[5] = abs(outperr[5])
	outperr[6] = RADTODEG(outperr[6])

        # Compute the mean errors. Don't want to do this at the moment.
        #dummy = 0.0
        #do i = 1, npts {
            #if (Memr[w+i-1] > 0.0)
                #dummy = dummy + 1.0
        #}
        #dummy = sqrt (dummy)
        #if (dummy > 0.0)
            #call adivkr (perr, dummy, perr, npar)

        # Transform the parameters if the fitted ratio > 1.
	if (outpar[5] > 1.0) {
	    outpar[4] = outpar[4] * outpar[5]
	    outperr[4] = sqrt (outperr[4] ** 2 + outperr[5] ** 2)
	    outperr[5] = (outperr[5] / outpar[5] ** 2)
	    outpar[5] = 1.0 / outpar[5]
	    outpar[6] = outpar[6] + 90.0
	}

        # Next check for angles whose magnitude is greater than 360.0 and for
        # angles which are negative. Angles which are between 180 and 360 need
	# to be converted to 0 to 180.0.
        outpar[6] = mod (outpar[6], 360.0)
        if (outpar[6] < 0.0)
            outpar[6] = outpar[6] + 360.0
        if (outpar[6] > 180.0)
            outpar[6] = outpar[6] - 180.0

	# Cleanup.
        call nlfreer (nl)
        call sfree (sp)

        # Return the appropriate error code.
        if (fier == NO_DEG_FREEDOM) {
            return (ERR)
        } else if (fier == SINGULAR) {
            return (ERR)
        } else if (fier == NOT_DONE) {
            return (ERR)
        } else {
            return (OK)
        }
end


# XP_REJECT -- Reject points outside of the specified intensity limits by
# setting their weights to zero.

int procedure xp_reject (pix, w, npts, locut, hicut)

real    pix[ARB]                #I the input data
real    w[ARB]                  #U the input / output weights
int     npts                    #I the number of data points
real    locut, hicut            #I the good data limits

int     i, nreject

begin
        nreject = 0
        do i = 1, npts {
            if ((pix[i] < locut || pix[i] > hicut) && w[i] > 0.0) {
                w[i] = 0.0
                nreject = nreject + 1
            }
        }
        return (nreject)
end


# XP_FELGAUSS -- Compute the value of a 2-D elliptical Gaussian profile which is
# assumed to be sitting on a constant background.

# Parameter Allocation:
# 1     Amplitude
# 2     X-center
# 3     Y-center
# 4     Sigma
# 5     Axis ratio
# 6     Position angle in radians
# 7     Sky

procedure xp_felgauss (x, nvars, p, np, z)

real    x[ARB]          #I the input variables
int     nvars           #I the number of variables
real    p[np]           #I parameter vector
int     np              #I number of parameters
real    z               #O function return

real    cost, sint, dx, dy, dxt, dyt, r2

begin
        cost = cos (p[6])
        sint = sin (p[6])
        dx = x[1] - p[2]
        dy = x[2] - p[3]
        dxt =  dx * cost + dy * sint
        dyt = -dx * sint + dy * cost
        r2 = (dxt / p[4]) ** 2 + (dyt / (p[4] *
            p[5])) ** 2

        if (r2 > 34.0)
            z = p[7]
        else
            z = p[7] + p[1] * exp (-0.5 * r2)
end


# XP_FELGAUSSD -- Compute the value of a 2-D elliptical Gaussian profile which
# is assumed to be sitting on top of a constant background and its derivatives.

# Parameter Allocation:
# 1     Amplitude
# 2     X-center
# 3     Y-center
# 4     Sigma
# 5     Axis ratio
# 6     Position angle in radians
# 7     Sky

procedure xp_felgaussd (x, nvars, p, dp, np, z, der)

real    x[ARB]          #I the input variables
int     nvars           #I the number of variables
real    p[np]           #I parameter vector
real    dp[np]          #I dummy array of parameter increments
int     np              #I number of parameters
real    z               #O function return
real    der[np]         #O derivatives

real    crot, srot, dxsig, dysig, sigy, dx, dy, dxt, dyt, r2, txsig, tysig

begin
        z = p[7]
        der[1] = 0.0
        der[2] = 0.0
        der[3] = 0.0
        der[4] = 0.0
        der[5] = 0.0
        der[6] = 0.0
        der[7] = 1.0

        crot = cos (p[6])
        srot = sin (p[6])
        sigy = p[4] * p[5]
        dx = x[1] - p[2]
        dy = x[2] - p[3]
        dxt =  dx * crot + dy * srot
        dyt = -dx * srot + dy * crot
        dxsig = dxt / p[4]
        dysig = dyt / sigy
        r2 = dxsig ** 2 + dysig ** 2
        if (r2 > 34.0)
            return
        der[1] = exp (-0.5*r2)
        z = p[1] * der[1]
        txsig = dxsig / p[4]
        tysig = dysig / sigy
        der[2] = z * (txsig * crot - tysig * srot)
        der[3] = z * (txsig * srot + tysig * crot)
        der[4] = z * (r2 / p[4])
        der[5] = z * tysig * (dyt / p[5])
        der[6] = z * (-txsig * dyt + tysig * dxt)
        z = z + p[7]
        der[7] = 1.0
end
