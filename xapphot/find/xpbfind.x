include <fset.h>
include <gset.h>
include <imhdr.h>
include <imset.h>
include <mach.h>
include <math.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/find.h"
include "../lib/objects.h"

define  FND_HSTR "Xinit%14tYinit%24tMag%33tArea%41tHwidth%49tEll%56tPa\
%64tSharprat%73tId%80t \n"


# XP_AFIND -- Find stars in an image using a pattern matching technique and
# a circularly symmetric Gaussian pattern and write the results to the
# output file.

int procedure xp_afind (gd, im, rl, xp, verbose)

pointer gd		#I pointer to the graphics stream
pointer	im		#I pointer to the input image
int	rl		#I the output file descriptor
pointer xp		#I pointer to the apphot structure
int	verbose		#I verbose switch

int	i, j, fwidth, swidth, norm, nxb, nyb, nstars, l1, l2, nlines
int	c1, c2, ncols, ntotal
pointer	sp, str, gker2d, ngker2d, skip, imbuf, denbuf
real	sigma, nsigma, a, b, c, f, dmin, dmax, relerr
real	gsums[LEN_GAUSS]
int	xp_stafind()
pointer	xp_statp()
real	xp_statr(), xp_egkernel()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Compute the parameters of the Gaussian kernel.
	sigma = HWHM_TO_SIGMA * xp_statr (xp, IHWHMPSF) * xp_statr (xp, ISCALE)
	nsigma =  xp_statr (xp, FRADIUS) * xp_statr (xp, ISCALE) / HWHM_TO_SIGMA
	call xp_egparams (sigma, 1.0, 0.0, nsigma, a, b, c, f, fwidth, fwidth)

	# Compute the separation parameter
	swidth = max (2, int (xp_statr (xp, FSEPMIN) * xp_statr (xp, IHWHMPSF) *
	    xp_statr (xp, ISCALE) + 0.5))

	# Compute the minimum and maximum pixel values.
	if (IS_INDEFR(xp_statr(xp,IMINDATA)) &&
	    IS_INDEFR(xp_statr(xp,IMAXDATA))) {
	    norm = YES
	    dmin = -MAX_REAL
	    dmax = MAX_REAL
	} else {
	    norm = NO
	    if (IS_INDEFR(xp_statr(xp,IMINDATA)))
		dmin = -MAX_REAL
	    else
		dmin = xp_statr (xp,IMINDATA)
	    if (IS_INDEFR(xp_statr(xp,IMAXDATA)))
		dmax = MAX_REAL
	    else
		dmax = xp_statr(xp,IMAXDATA)
	}

	# Set up the image boundary extension characteristics.
        call imseti (im, IM_TYBNDRY, BT_NEAREST)
        call imseti (im, IM_NBNDRYPIX, 1 + fwidth / 2 + swidth)

	# Set up the blocking factor.
	nxb = IM_LEN(im,1)
	nyb = DEF_NYBLOCK

	# Print the detection criteria on the standard output.
	if (verbose == YES) {
	    call fstats (rl, F_FILENAME, Memc[str], SZ_LINE)
	    call printf ("\nImage: %s  Output: %s\n")
		call pargstr (IM_HDRFILE(im))
		call pargstr (Memc[str])
	    call printf ("Detection Parameters\n")
	    call printf (
	    "    Hwhmpsf: %0.3f (pixels)  Threshold: %g (ADU)\n")
		call pargr (xp_statr(xp,IHWHMPSF) * xp_statr(xp,ISCALE))
		call pargr (xp_statr(xp,FTHRESHOLD))
	    call printf ("    Datamin: %g (ADU)  Datamax: %g (ADU)\n")
		call pargr (xp_statr(xp,IMINDATA))
		call pargr (xp_statr(xp,IMAXDATA))
	    call printf ("    Fradius: %0.3f (HWHM)  Sepmin: %0.3f (HWHM)\n\n")
		call pargr (xp_statr(xp, FRADIUS))
		call pargr (xp_statr(xp, FSEPMIN))
	    call printf (FND_HSTR)
	}


	# Process the image block by block.
	ntotal = 0
	do j = 1, IM_LEN(im,2), nyb {

	    l1 = j
	    l2 = min (IM_LEN(im,2), j + nyb - 1)
	    nlines = l2 - l1 + 1 + 2 * (fwidth / 2 + swidth)

	    do i = 1, IM_LEN(im,1), nxb {

		# Allocate space for the convolution kernel.
		call malloc (gker2d, fwidth * fwidth, TY_REAL)
		call malloc (ngker2d, fwidth * fwidth, TY_REAL)
		call malloc (skip, fwidth * fwidth, TY_INT)

		# Allocate space for the data and the convolution.
	        c1 = i
	        c2 = min (IM_LEN(im,1), i + nxb - 1)
		ncols = c2 - c1 + 1 + 2 * (fwidth / 2 + swidth)
		call malloc (imbuf, ncols * nlines, TY_REAL)
		call malloc (denbuf, ncols * nlines, TY_REAL)

		# Compute the convolution kernels.
		relerr = xp_egkernel (Memr[gker2d], Memr[ngker2d], Memi[skip],
	    	    fwidth, fwidth, gsums, a, b, c, f)

		# Do the convolution.
		if (norm == YES)
	            call xp_fconvolve (im, c1, c2, l1, l2, swidth, Memr[imbuf],
		        Memr[denbuf], ncols, nlines, Memr[ngker2d], Memi[skip],
			fwidth, fwidth)
		else
	            call xp_gconvolve (im, c1, c2, l1, l2, swidth, Memr[imbuf],
		        Memr[denbuf], ncols, nlines, Memr[gker2d], Memi[skip],
			fwidth, fwidth, gsums, dmin, dmax)

	        # Find the stars.
		#nstars = xp_stfind (rl, Memr[imbuf], Memr[denbuf], ncols,
		    #nlines, c1, c2, l1, l2, swidth, Memi[skip], fwidth,
		    #fwidth, xp_statr(xp,IHWHMPSF) * xp_statr(xp, ISCALE),
		    #xp_statr(xp,FTHRESHOLD), dmin, dmax, xp_statr(xp,FROUNDLO),
		    #xp_statr(xp,FROUNDHI), xp_statr(xp,FSHARPLO),
		    #xp_statr(xp,FSHARPHI), SEQNO(xp_statp(xp,PSTATUS))
		    #verbose)

	        # Find, mark, and save the stars.
		nstars = xp_stafind (gd, rl, xp, Memr[imbuf], Memr[denbuf],
		    ncols, nlines, c1, c2, l1, l2, swidth, Memi[skip], fwidth,
		    fwidth, dmin, dmax, SEQNO(xp_statp(xp,PSTATUS)), verbose)

		# Increment the counter and the sequence number.
		if (rl != NULL)
		    SEQNO(xp_statp(xp,PSTATUS)) =
		        SEQNO(xp_statp(xp,PSTATUS)) + nstars
		ntotal = ntotal + nstars

		# Free the memory.
		call mfree (imbuf, TY_REAL)
		call mfree (denbuf, TY_REAL)
		call mfree (gker2d, TY_REAL)
		call mfree (ngker2d, TY_REAL)
		call mfree (skip, TY_INT)
	    }
	}

	# Print out the selection parameters.
	if (verbose == YES) {
	    call printf ("\nSelection Parameters\n")
	    call printf ( "    Roundlo: %0.3f  Roundhi: %0.3f\n")
		call pargr (xp_statr(xp,FROUNDLO))
		call pargr (xp_statr(xp,FROUNDHI))
	    call printf ( "    Sharplo: %0.3f  Sharphi: %0.3f\n")
		call pargr (xp_statr(xp,FSHARPLO))
		call pargr (xp_statr(xp,FSHARPHI))
	}

	call sfree (sp)

	return (ntotal)
end


# XP_STAFIND -- Detect images in the convolved image and then compute image
# characteristics using the original image.

int procedure xp_stafind (gd, out, xp, imbuf, denbuf, ncols, nlines, c1, c2,
        l1, l2, sepmin, skip, nxk, nyk, datamin, datamax, seqno, verbose)

pointer	gd			#I pointer to the graphics stream
int     out                     #I the output file descriptor
pointer	xp			#I pointer to the xapphot structure
real    imbuf[ncols,nlines]     #I the input data buffer
real    denbuf[ncols,nlines]    #I the input density enhancements buffer
int     ncols, nlines           #I the dimensions of the input buffers
int     c1, c2                  #I the image columns limits
int     l1, l2                  #I the image lines limits
int     sepmin                  #I the minimum object separation
int     skip[nxk,ARB]           #I the pixel fitting array
int     nxk, nyk                #I the dimensions of the fitting array
real    datamin, datamax        #I the minimum and maximum good data values
int     seqno                   #U the object sequence number
int	verbose			#I verbose mode

int     inline, line1, line2, xmiddle, ymiddle, ntotal, nobjs, nstars
pointer sp, cols, x, y, mag, npix, size, ellip, theta, sharp
int     xp_detect(), xp_test()
real	xp_statr()

begin
        # Set up useful line and column limits.
        line1 = 1 + sepmin + nyk / 2
        line2 = nlines - sepmin - nyk / 2
        xmiddle = 1 + nxk / 2
        ymiddle = 1 + nyk / 2

        # Set up a cylindrical buffers and some working space for
        # the detected images.
        call smark (sp)
        call salloc (cols, ncols, TY_INT)
        call salloc (x, ncols, TY_REAL)
        call salloc (y, ncols, TY_REAL)
        call salloc (mag, ncols, TY_REAL)
        call salloc (npix, ncols, TY_INT)
        call salloc (size, ncols, TY_REAL)
        call salloc (ellip, ncols, TY_REAL)
        call salloc (theta, ncols, TY_REAL)
        call salloc (sharp, ncols, TY_REAL)

        # Generate the starlist line by line.
        ntotal = 0
        do inline = line1, line2 {

            # Detect local maximum in the density enhancement buffer.
            nobjs = xp_detect (denbuf[1,inline-nyk/2-sepmin], ncols, sepmin,
                nxk, nyk, xp_statr (xp, FTHRESHOLD), Memi[cols])
            if (nobjs <= 0)
                next

            # Do not skip the middle pixel in the moments computation.
            call xp_dmoments (imbuf[1,inline-nyk/2], denbuf[1,inline-nyk/2],
                ncols, skip, nxk, nyk, Memi[cols], Memr[x], Memr[y],
                Memi[npix], Memr[mag], Memr[size], Memr[ellip], Memr[theta],
                Memr[sharp], nobjs, datamin, datamax, xp_statr(xp, FTHRESHOLD),
		xp_statr(xp, IHWHMPSF) * xp_statr(xp, ISCALE),
		real (-sepmin - nxk / 2 + c1 - 1), real (inline - sepmin -
                nyk + l1 - 1))

            # Test the image characeteristics of detected objects.
            nstars = xp_test (Memi[cols], Memr[x], Memr[y], Memi[npix],
                Memr[mag], Memr[size], Memr[ellip], Memr[theta], Memr[sharp],
                nobjs, real (c1 - 0.5), real (c2 + 0.5), real (l1 - 0.5),
                real (l2 + 0.5), xp_statr(xp,FROUNDLO), xp_statr(xp,FROUNDHI),
		xp_statr(xp,FSHARPLO), xp_statr(xp,FSHARPHI))

	    # Mark the objects.
	    if (gd != NULL)
	        call xp_mkfobjects (gd, xp, Memr[x], Memr[y], nstars, ntotal +
	            seqno, 1, 1)

	    # Print the results on the standard output.
	    if (verbose == YES)
                call xp_write (STDOUT, Memr[x], Memr[y], Memr[mag], Memi[npix],
                    Memr[size], Memr[ellip], Memr[theta], Memr[sharp], nstars,
                    ntotal + seqno)

            # Save the results in the file.
            call xp_write (out, Memr[x], Memr[y], Memr[mag], Memi[npix],
                Memr[size], Memr[ellip], Memr[theta], Memr[sharp], nstars,
                ntotal + seqno)

            ntotal = ntotal + nstars

        }

        # Free space
        call sfree (sp)

        return (ntotal)
end


# XP_DETECT -- Detect stellar objects in an image line. In order to be
# detected as a star the candidate object must be above threshold and have
# a maximum pixel value greater than any pixels within sepmin pixels.

int procedure xp_detect (density, ncols, sepmin, nxk, nyk, threshold, cols)

real	density[ncols, ARB]	#I the input density enhancements array
int	ncols			#I the x dimension of the input array
int	sepmin			#I the minimum separation in pixels
int	nxk, nyk		#I size of the fitting area
real	threshold		#I density threshold
int	cols[ARB]		#O column numbers of detected stars

int	i, j, k, ymiddle, nxhalf, nyhalf, ny, b2, nobjs, rj2, r2
define	nextpix_	11

begin
	ymiddle = 1 + nyk / 2 + sepmin
	nxhalf = nxk / 2
	nyhalf = nyk / 2
	ny = 2 * sepmin + 1
	b2 = sepmin ** 2

	# Loop over all the columns in an image line.
	nobjs = 0
	for (i = 1 + nxhalf + sepmin; i <= ncols - nxhalf - sepmin; ) {

	    # Test whether the density enhancement is above threshold.
	    if (density[i,ymiddle] < threshold)
		goto nextpix_

	    # Test whether a given density enhancement satisfies the
	    # separation criterion.
	    do j = 1, ny {
		rj2 = (j - sepmin - 1) ** 2
		do k = i - sepmin, i + sepmin {
		    r2 = (i - k) ** 2 + rj2
		    if (r2 <= b2) {
		        if (density[i,ymiddle] < density[k,j+nyhalf])
		           goto nextpix_
		    }
		}
	    }

	    # Add the detected object to the list.
	    nobjs = nobjs + 1
	    cols[nobjs] = i

	    # If a local maximum is detected there can be no need to
	    # check pixels in this row between i and i + sepmin.
	    i = i + sepmin
nextpix_
	    # Work on the next pixel.
	    i = i + 1
	}

	return (nobjs)
end


# XP_DMOMENTS -- Perform a moments analysis on the dectected objects.

procedure xp_dmoments (data, den, ncols, skip, nxk, nyk, cols, x, y,
	npix, mag, size, ellip, theta, sharp, nobjs, datamin, datamax,
	threshold, hwhmpsf, xoff, yoff)

real	data[ncols,ARB]		#I the input data array
real	den[ncols,ARB]		#I the input density enhancements array
int	ncols			#I the x dimension of the input buffer
int	skip[nxk,ARB]		#I the input fitting array
int	nxk, nyk		#I the dimensions of the fitting array
int	cols[ARB]		#I the input initial positions	
real	x[ARB]			#O the output x coordinates
real	y[ARB]			#O the output y coordinates
int	npix[ARB]		#O the output area in number of pixels
real	mag[ARB]		#O the output magnitude estimates
real	size[ARB]		#O the output size estimates
real	ellip[ARB]		#O the output ellipticity estimates
real	theta[ARB]		#O the output position angle estimates
real	sharp[ARB]		#O the output sharpness estimates
int	nobjs			#I the number of objects
real	datamin, datamax	#I the minium and maximum good data values
real	threshold		#I threshold for moments computation
real	hwhmpsf			#I the HWHM of the PSF
real	xoff, yoff		#I the x and y coordinate offsets

int	i, j, k, xmiddle, ymiddle, sumn
double	pixval, sumix, sumiy, sumi, sumixx, sumixy, sumiyy, r2, dx, dy, diff
real	mean

begin
	# Initialize
	xmiddle = 1 + nxk / 2
	ymiddle = 1 + nyk / 2 

	# Compute the pixel sum, number of pixels, and the x and y centers.
	do i = 1, nobjs {

	    # Estimate the background using the input data and the
	    # best fitting Gaussian amplitude
	    sumi = 0.0
	    sumn = 0
	    do j = 1, nyk {
		do k = 1, nxk {
		    if (skip[k,j] == YES)
			next
		    pixval = data[cols[i]-xmiddle+k,j]
		    if (pixval < datamin || pixval > datamax)
			next
		    sumi = pixval - den[cols[i]-xmiddle+k,j]
		    sumn = sumn + 1
		}
	    }
	    if (sumn <= 0)
		mean = 0.0
	        #mean = data[cols[i],ymiddle] - den[cols[i],ymiddle]
	    else
		mean = sumi / sumn

	    # Compute the first order moments.
	    sumi = 0.0
	    sumn = 0
	    sumix = 0.0d0
	    sumiy = 0.0d0
	    do j = 1, nyk {
		do k = 1, nxk {
		    if (skip[k,j] == YES)
			next
		    pixval = data[cols[i]-xmiddle+k,j]
		    if (pixval < datamin || pixval > datamax)
			next
		    pixval = pixval - mean
		    if (pixval < 0.0)
			next
		    sumi = sumi + pixval
		    sumix = sumix + (cols[i] - xmiddle + k) * pixval
		    sumiy = sumiy + j * pixval
		    sumn = sumn + 1
		}

	    }

	    # Use the first order moments to estimate the positions
	    # magnitude, area, and amplitude of the object.
	    if (sumi <= 0.0) {
		x[i] = cols[i] 
		y[i] = (1.0 + nyk) / 2.0 
		mag[i] = INDEFR
		npix[i] = 0
	    } else {
		x[i] = sumix / sumi 
		y[i] = sumiy / sumi 
		mag[i] = -2.5 * log10 (sumi)
		npix[i] = sumn
	    }

	    # Compute the second order central moments using the results of
	    # the first order moment analysis.
	    sumixx = 0.0d0
	    sumiyy = 0.0d0
	    sumixy = 0.0d0
	    do j = 1, nyk {
		dy = j - y[i]
		do k = 1, nxk {
		    if (skip[k,j] == YES)
			next
		    pixval = data[cols[i]-xmiddle+k,j]
		    if (pixval < datamin || pixval > datamax)
			next
		    pixval = pixval - mean
		    if (pixval < 0.0)
			next
		    dx = cols[i] - xmiddle + k - x[i]
		    sumixx = sumixx + pixval * dx ** 2
		    sumixy = sumixy + pixval * dx * dy
		    sumiyy = sumiyy + pixval * dy ** 2
		}
	    }

	    # Use the second order central moments to estimate the size,
	    # ellipticity, position angle, and sharpness of the objects.
	    if (sumi <= 0.0) {
		size[i] = 0.0
		ellip[i] = INDEFR
		theta[i] = INDEFR
		sharp[i] = INDEFR
	    } else {
		sumixx = sumixx / sumi
		sumixy = sumixy / sumi
		sumiyy = sumiyy / sumi
		r2 = sumixx + sumiyy
		if (r2 <= 0.0) {
		    size[i] = INDEFR
		    ellip[i] = INDEFR
		    theta[i] = INDEFR
		    sharp[i] = INDEFR
		} else {
		    size[i] = sqrt (LN_2 * r2)
		    sharp[i] = size[i] / hwhmpsf
		    diff = sumixx - sumiyy
		    ellip[i] = sqrt (diff ** 2 + 4.0d0 * sumixy ** 2) / r2
		    if (diff == 0.0d0 && sumixy == 0.0d0)
			theta[i] = 0.0
		    else
		        theta[i] = RADTODEG (0.5d0 * atan2 (2.0d0 * sumixy,
			    diff))
		    if (theta[i] < 0.0)
			theta[i] = theta[i] + 180.0
		}
	    }

	    # Convert the computed coordinates to the image system.
	    x[i] = x[i] + xoff
	    y[i] = y[i] + yoff
	}
end


# XP_TEST -- Check that the detected objects are in the image, contain
# enough pixels above background to be measurable objects, and are within
# the specified magnitude, roundness and sharpness range.

int procedure xp_test (cols, x, y, npix, mag, size, ellip, theta, sharps,
	nobjs, c1, c2, l1, l2, roundlo, roundhi, sharplo, sharphi)

int	cols[ARB]			#U the column ids of detected object
real	x[ARB]				#U the x position estimates
real	y[ARB]				#U the y positions estimates
int	npix[ARB]			#U the area estimates
real	mag[ARB]			#U the magnitude estimates
real	size[ARB]			#U the size estimates
real	ellip[ARB]			#U the ellipticity estimates
real	theta[ARB]			#U the position angle estimates
real	sharps[ARB]			#U sharpness estimates
int	nobjs				#I the number of detected objects
real	c1, c2				#I the image column limits
real	l1, l2				#I the image line limits
real	roundlo, roundhi		#I the roundness limits
real	sharplo, sharphi		#I the sharpness limits

int	i, nstars

begin
	# Loop over the detected objects.
	nstars = 0
	do i = 1, nobjs {

	    if (x[i] < c1 || x[i] > c2)
		next
	    if (y[i] < l1 || y[i] > l2)
		next
	    if (IS_INDEFR(ellip[i]) || (ellip[i] < roundlo ||
	        ellip[i] > roundhi))
		next
	    if (IS_INDEFR(sharps[i]) || (sharps[i] < sharplo ||
	        sharps[i] > sharphi))
		next

	    # Add object to the list.
	    nstars = nstars + 1
	    cols[nstars] = cols[i]
	    x[nstars] = x[i]
	    y[nstars] = y[i]
	    mag[nstars] = mag[i]
	    npix[nstars] = npix[i]
	    size[nstars] = size[i]
	    ellip[nstars] = ellip[i]
	    theta[nstars] = theta[i]
	    sharps[nstars] = sharps[i]
	}

	return (nstars)
end


define  FND_WSTR "%-13.3f%-10.3f%-9.3f%-8d%-8.2f%-7.2f%-8.2f%-9.2f%-6d%80t \n"

# XP_WRITE -- Write the results to the output file.

procedure xp_write (fd, x, y, mag, npix, size, ellip, theta, sharp, nstars,
	seqno)

int     fd                              #I the output file descriptor
real    x[ARB]                          #I xcoords
real    y[ARB]                          #I y coords
real    mag[ARB]                        #I magnitudes
int     npix[ARB]                       #I number of pixels
real    size[ARB]                       #I object sizes
real    ellip[ARB]                      #I ellipticities
real    theta[ARB]                      #I position angles
real    sharp[ARB]                      #I sharpnesses
int     nstars                          #I number of detected stars in the line
int     seqno                           #I output file sequence number

int     i

begin
        if (fd == NULL)
            return

        do i = 1, nstars {
            call fprintf (fd, FND_WSTR)
                call pargr (x[i])
                call pargr (y[i])
                call pargr (mag[i])
		call pargi (npix[i])
                call pargr (size[i])
                call pargr (ellip[i])
                call pargr (theta[i])
		call pargr (sharp[i])
                call pargi (seqno + i)
        }
end


# XP_MKFOBJECTS -- Mark the found objects on the image display regardless.

procedure xp_mkfobjects (gd, xp, x, y, nstars, seqno, raster, wcs)

pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
real	x[ARB]		#I the input x coordinates
real	y[ARB]		#I the input y coordinates
int	nstars		#I the number of detected objects
int	seqno		#I the output file sequence number
int	raster		#I the raster coordinate system to be used
int	wcs		#I the current wcs

int	i, omarktype, omkcolor, otxcolor, markchar
pointer	sp, text, format
real	mksize
int	xp_stati(), gstati(), xp_opcolor(), itoc()
real	xp_statr()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, OBJMARK) == NO)
	    return

	call smark (sp)
	call salloc (text, SZ_FNAME, TY_CHAR)
	call salloc (format, SZ_FNAME, TY_CHAR)
	Memc[text] = 'O'
	Memc[format] = EOS

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Save the mark type.
	omarktype = gstati (gd, G_PMLTYPE)
	omkcolor = gstati (gd, G_PLCOLOR)
	otxcolor = gstati (gd, G_TXCOLOR)

	# Set the mark character.
	switch (xp_stati (xp, OCHARMARK)) {
	case XP_OMARK_POINT:
	    markchar = GM_POINT
	case XP_OMARK_BOX:
	    markchar = GM_BOX
	case XP_OMARK_CROSS:
	    markchar = GM_CROSS
	case XP_OMARK_PLUS:
	    markchar = GM_PLUS
	case XP_OMARK_CIRCLE:
	    markchar = GM_CIRCLE
	case XP_OMARK_DIAMOND:
	    markchar = GM_DIAMOND
	default:
	    markchar = GM_PLUS
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)

	# Set the marker size.
	if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
	    mksize = - 2.0 
	else
	    mksize = - 2.0 * xp_statr (xp, OSIZEMARK)

	# Set the colors.
	call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	call gseti (gd, G_TXCOLOR, xp_opcolor (xp))

	# Mark the points.
	do i = 1, nstars {

	    # Mark the object.
	    call gmark (gd, x[i], y[i], markchar, mksize, mksize)

	    # Number the marked objects.
	    if (xp_stati (xp, ONUMBER) == YES) {
		if (itoc (i + seqno, Memc[text+1], SZ_FNAME) <= 0)
		    ;
		call gtext (gd, x[i] + 2.0, y[i] + 2.0, Memc[text],
		    Memc[format])
	    }
	}

	# Restore the mark type.
	call gseti (gd, G_PMLTYPE, omarktype)
	call gseti (gd, G_PLCOLOR, omkcolor)
	call gseti (gd, G_TXCOLOR, otxcolor)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)

	call sfree (sp)
end
