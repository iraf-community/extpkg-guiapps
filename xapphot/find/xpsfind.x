include <imhdr.h>
include <imset.h>
include <mach.h>
include <math.h>
include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/find.h"

# XP_SFIND -- Find stars in an image using a pattern matching technique and
# a circularly symmetric Gaussian pattern and write the results to the object
# symbol table

int procedure xp_sfind (im, xp)

pointer	im		#I pointer to the input image
pointer xp		#I pointer to the apphot structure

int	i, j, fwidth, swidth, norm, nxb, nyb, seqno, nstars, l1, l2, nlines
int	c1, c2, ncols
pointer	gker2d, ngker2d, skip, imbuf, denbuf, stptr, plyptr
real	sigma, nsigma, a, b, c, f, dmin, dmax, relerr
real	gsums[LEN_GAUSS]
int	xp_stsfind()
real	xp_statr(), xp_egkernel()

begin
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

	# Initialize the symbol table
	call xp_openobjects (xp, stptr, plyptr)

	# Process the image block by block.
	seqno = 0
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
		nstars = xp_stsfind (stptr, Memr[imbuf], Memr[denbuf], ncols,
		    nlines, c1, c2, l1, l2, swidth, Memi[skip], fwidth,
		    fwidth, xp_statr(xp,IHWHMPSF) * xp_statr(xp, ISCALE),
		    xp_statr(xp,FTHRESHOLD), dmin, dmax, xp_statr(xp,FROUNDLO),
		    xp_statr(xp,FROUNDHI), xp_statr(xp,FSHARPLO),
		    xp_statr(xp,FSHARPHI), seqno)

		# Increment the sequence number.
		seqno = seqno + nstars

		# Free the memory.
		call mfree (imbuf, TY_REAL)
		call mfree (denbuf, TY_REAL)
		call mfree (gker2d, TY_REAL)
		call mfree (ngker2d, TY_REAL)
		call mfree (skip, TY_INT)
	    }
	}

	return (seqno)

end


# XP_STSFIND -- Detect images in the convolved image and then compute image
# characteristics using the original image.

int procedure xp_stsfind (stptr, imbuf, denbuf, ncols, nlines, c1, c2, l1, l2,
	sepmin, skip, nxk, nyk, hwhmpsf, threshold, datamin, datamax,
	roundlo, roundhi, sharplo, sharphi, seqno)

int	stptr			#I the symbol tabel pointer
real	imbuf[ncols,nlines]	#I the input data buffer
real	denbuf[ncols,nlines]	#I the input density enhancements buffer
int	ncols, nlines		#I the dimensions of the input buffers
int	c1, c2			#I the image columns limits
int	l1, l2			#I the image lines limits
int	sepmin			#I the minimum object separation
int	skip[nxk,ARB]		#I the pixel fitting array
int	nxk, nyk		#I the dimensions of the fitting array
real	hwhmpsf			#I the HWHM of the PSF in pixels
real	threshold		#I the threshold for object detection
real	datamin, datamax	#I the minimum and maximum good data values
real	roundlo,roundhi		#I the ellipticity estimate limits
real	sharplo, sharphi	#I the sharpness estimate limits
int	seqno			#U the object sequence number

int	inline, line1, line2, xmiddle, ymiddle, ntotal, nobjs, nstars
pointer	sp, cols, x, y, mag, npix, size, ellip, theta, sharp
int	xp_detect(), xp_test()

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
	        nxk, nyk, threshold, Memi[cols])
	    if (nobjs <= 0)
		next

	    # Do not skip the middle pixel in the moments computation.
	    call xp_dmoments (imbuf[1,inline-nyk/2], denbuf[1,inline-nyk/2],
	        ncols, skip, nxk, nyk, Memi[cols], Memr[x], Memr[y],
		Memi[npix], Memr[mag], Memr[size], Memr[ellip], Memr[theta],
		Memr[sharp], nobjs, datamin, datamax, threshold, hwhmpsf,
		real (-sepmin - nxk / 2 + c1 - 1), real (inline - sepmin -
		nyk + l1 - 1))

	    # Test the image characeteristics of detected objects.
	    nstars = xp_test (Memi[cols], Memr[x], Memr[y], Memi[npix],
	        Memr[mag], Memr[size], Memr[ellip], Memr[theta], Memr[sharp],
		nobjs, real (c1 - 0.5), real (c2 + 0.5), real (l1 - 0.5),
		real (l2 + 0.5),  roundlo, roundhi, sharplo, sharphi)

	    # Save the results in the file.
	    call xp_wsymbols (stptr, Memr[x], Memr[y], Memr[mag], Memi[npix],
	        Memr[size], Memr[ellip], Memr[theta], Memr[sharp], nstars,
		ntotal + seqno)

	    ntotal = ntotal + nstars

	}

	# Free space
	call sfree (sp)

	return (ntotal)
end


# XP_WSYMBOLS -- Write the results to the symbols table.

procedure xp_wsymbols (stptr, x, y, mag, npix, size, ellip, theta, sharp,
	nstars, seqno)

pointer stptr                           #I the output symbol table
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
pointer	sp, str, symbol
pointer	stenter()

begin
	if (stptr == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Add the stars to the symbol table.
        do i = 1, nstars {

	    # Add the symbol.
	    call sprintf (Memc[str], SZ_FNAME, "objlist%d")
		call pargi (seqno + i)
	    symbol = stenter (stptr, Memc[str], LEN_OBJLIST_STRUCT)

	    # Define the object characteristics.
	    XP_ODELETED(symbol) = NO
	    XP_OXINIT(symbol) = x[i]
	    XP_OYINIT(symbol) = y[i]
	    XP_OGEOMETRY(symbol) = XP_OINDEF
	    if (IS_INDEFR(ellip[i]))
	        XP_OAXRATIO(symbol) = INDEFR
	    else
	        XP_OAXRATIO(symbol) = 1.0 - ellip[i]
	    XP_OPOSANG(symbol) = theta[i]
	    XP_ONPOLYGON(symbol) = 0
	    XP_OXSHIFT(symbol) = 0.0
	    XP_OYSHIFT(symbol) = 0.0
	    #call strcpy ("INDEF", XP_OAPERTURES(symbol), MAX_SZAPERTURES)
	    call sprintf (XP_OAPERTURES(symbol), MAX_SZAPERTURES, "%0.2f")
		call pargr(size[i])

	    # Define the sky characteristics.
	    XP_OSXINIT(symbol) = INDEFR
	    XP_OSYINIT(symbol) = INDEFR
	    XP_OSRIN(symbol) = INDEFR
	    XP_OSROUT(symbol) = INDEFR
	    XP_OSGEOMETRY(symbol) = XP_OINDEF
	    XP_OSAXRATIO(symbol) = 1.0
	    XP_OSPOSANG(symbol) = 0.0
	    XP_OSNPOLYGON(symbol) = 0
	    XP_OSXSHIFT(symbol) = 0.0
	    XP_OSYSHIFT(symbol) = 0.0
        }

	call sfree (sp)
end
