include <imhdr.h>
include <imset.h>
include <mach.h>
include <math.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"

# XP_BCENTER -- Compute centers for a list of objects.

int procedure xp_bcenter (im, ol, rl, xp, verbose)

pointer	im			#I the input image descriptor
int	ol			#I the input objects file descriptor
int	rl			#I the output results file descriptor
pointer	xp			#I the main xapphot descriptor
int	verbose			#I print summary of output ?

int	ier, loseqno, seqno
pointer	sp, imname, olname, symbol
real	xc, yc
int	xp_robjects(), xp_fitcenter()
pointer	sthead(), xp_statp()

begin
	if (ol == NULL)
	    return

	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)

	seqno = SEQNO(xp_statp(xp,PSTATUS))
	loseqno = 0
	while (xp_robjects (ol, xp, RLIST_TEMP) > 0) {
	    symbol = sthead (xp_statp (xp, OBJLIST))
	    if (symbol == NULL)
		break
	    loseqno = loseqno + 1
	    xc = XP_OXINIT(symbol)
	    yc = XP_OYINIT(symbol)
	    ier = xp_fitcenter (xp, im, xc, yc)
	    if (rl == NULL) {
	        if (verbose == YES)
	            call xp_cqprint (xp, Memc[imname], ier, NO)
		next
	    } else if (verbose == YES)
	        call xp_cqprint (xp, Memc[imname], ier, YES)
	    seqno = seqno + 1
	    call xp_cwrite (xp, rl, seqno, Memc[olname], loseqno, ier)
	}
	SEQNO(xp_statp(xp,PSTATUS)) = seqno

	call sfree (sp)

	return (loseqno)
end


# XP_ACENTER -- Compute centers for a list of objects.

int procedure xp_acenter (gd, im, rl, xp, verbose)

pointer	gd			#I the graphics descriptor
pointer	im			#I the input image descriptor
int	rl			#I the output results file descriptor
pointer	xp			#I the main xapphot descriptor
int	verbose			#I print summary of output ?

int     i, j, k, fwidth, swidth, norm, nxb, nyb, nstars, l1, l2, nlines, ntotal
int     c1, c2, ncols, ier, seqno
pointer gker2d, ngker2d, skip, imbuf, denbuf, x, y
real    sigma, nsigma, a, b, c, f, dmin, dmax, relerr
real    gsums[LEN_GAUSS]
int     xp_staget(), xp_fitcenter()
pointer	xp_statp()
real    xp_statr(), xp_egkernel()


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

        # Process the image block by block.
        ntotal = 0
	seqno = SEQNO(xp_statp(xp,PSTATUS))
        do j = 1, IM_LEN(im,2), nyb {

            l1 = j
            l2 = min (IM_LEN(im,2), j + nyb - 1)
            nlines = l2 - l1 + 1 + 2 * (fwidth / 2 + swidth)

            do i = 1, IM_LEN(im,1), nxb {

                # Allocate space for the convolution kernel.
                call malloc (gker2d, fwidth * fwidth, TY_REAL)
                call malloc (ngker2d, fwidth * fwidth, TY_REAL)
                call malloc (skip, fwidth * fwidth, TY_INT)

                # Compute the convolution kernels.
                relerr = xp_egkernel (Memr[gker2d], Memr[ngker2d], Memi[skip],
                    fwidth, fwidth, gsums, a, b, c, f)

                # Allocate space for the data and the convolution.
                c1 = i
                c2 = min (IM_LEN(im,1), i + nxb - 1)
                ncols = c2 - c1 + 1 + 2 * (fwidth / 2 + swidth)
                call malloc (imbuf, ncols * nlines, TY_REAL)
                call malloc (denbuf, ncols * nlines, TY_REAL)
                call malloc (x, ncols * nlines, TY_REAL)
                call malloc (y, ncols * nlines, TY_REAL)

                # Do the convolution.
                if (norm == YES)
                    call xp_fconvolve (im, c1, c2, l1, l2, swidth, Memr[imbuf],
                        Memr[denbuf], ncols, nlines, Memr[ngker2d], Memi[skip],
                        fwidth, fwidth)
                else
                    call xp_gconvolve (im, c1, c2, l1, l2, swidth, Memr[imbuf],
                        Memr[denbuf], ncols, nlines, Memr[gker2d], Memi[skip],
                        fwidth, fwidth, gsums, dmin, dmax)

		# Find, the stars.
                nstars = xp_staget (xp, Memr[imbuf], Memr[denbuf], Memr[x],
		    Memr[y], ncols, nlines, c1, c2, l1, l2, swidth, Memi[skip],
		    fwidth, fwidth, dmin, dmax)

		# Center and record the stars
		do k = 1, nstars {
	    	    ier = xp_fitcenter (xp, im, Memr[x+k-1], Memr[y+k-1])
		    Memr[x+k-1] = xp_statr (xp, XCENTER)
		    Memr[y+k-1] = xp_statr (xp, YCENTER)
		    #if (gd != NULL)
			#call xp_cmark (gd, xp, 1, 1)
	    	    if (rl == NULL) {
	                if (verbose == YES)
	                    call xp_cqprint (xp, IM_HDRFILE(im), ier, NO)
		        next
		    } else if (verbose == YES)
	                call xp_cqprint (xp, IM_HDRFILE(im), ier, YES)
	    	    call xp_cwrite (xp, rl, seqno + k, "none", 0, ier)
		}

		# Mark the stars using the computed centers and the
		# object marking routine.
		if (gd != NULL)
		    call xp_mkfobjects (gd, xp, Memr[x], Memr[y], nstars,
			ntotal + seqno, 1, 1)

                # Increment the star counter and sequence number.
                ntotal = ntotal + nstars
                if (rl != NULL)
                    seqno = seqno + nstars

                # Free the memory.
                call mfree (gker2d, TY_REAL)
                call mfree (ngker2d, TY_REAL)
                call mfree (skip, TY_INT)
                call mfree (imbuf, TY_REAL)
                call mfree (denbuf, TY_REAL)
                call mfree (x, TY_REAL)
                call mfree (y, TY_REAL)
            }
        }
	SEQNO(xp_statp(xp,PSTATUS)) = seqno

        return (ntotal)
end


# XP_STAGET -- Automatically detect the stars to be centered.

int procedure xp_staget (xp, imbuf, denbuf, x, y, ncols, nlines, c1, c2,
        l1, l2, sepmin, skip, nxk, nyk, datamin, datamax)

pointer xp                      #I pointer to the xapphot structure
real    imbuf[ncols,nlines]     #I the input data buffer
real    denbuf[ncols,nlines]    #I the input density enhancements buffer
real	x[ARB]			#O the output x coordinates
real	y[ARB]			#O the output y coordinates
int     ncols, nlines           #I the dimensions of the input buffers
int     c1, c2                  #I the image columns limits
int     l1, l2                  #I the image lines limits
int     sepmin                  #I the minimum object separation
int     skip[nxk,ARB]           #I the pixel fitting array
int     nxk, nyk                #I the dimensions of the fitting array
real    datamin, datamax        #I the minimum and maximum good data values

int     inline, line1, line2, xmiddle, ymiddle, ntotal, nobjs, nstars
pointer sp, cols, mag, npix, size, ellip, theta, sharp, str
int     xp_detect(), xp_test()
real    xp_statr()

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
        call salloc (mag, ncols, TY_REAL)
        call salloc (npix, ncols, TY_INT)
        call salloc (size, ncols, TY_REAL)
        call salloc (ellip, ncols, TY_REAL)
        call salloc (theta, ncols, TY_REAL)
        call salloc (sharp, ncols, TY_REAL)
	call salloc (str, SZ_FNAME, TY_CHAR)

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
                ncols, skip, nxk, nyk, Memi[cols], x[ntotal+1], y[ntotal+1],
		Memi[npix], Memr[mag], Memr[size], Memr[ellip], Memr[theta],
		Memr[sharp], nobjs, datamin, datamax, xp_statr(xp,FTHRESHOLD),
		xp_statr(xp,IHWHMPSF) * xp_statr(xp,ISCALE), real (-sepmin -
		nxk / 2 + c1 - 1), real (inline - sepmin - nyk + l1 - 1))

            # Test the image characeteristics of detected objects.
            nstars = xp_test (Memi[cols], x[ntotal+1], y[ntotal+1], Memi[npix],
	        Memr[mag], Memr[size], Memr[ellip], Memr[theta], Memr[sharp],
		nobjs, real (c1 - 0.5), real (c2 + 0.5), real (l1 - 0.5),
                real (l2 + 0.5), xp_statr(xp,FROUNDLO), xp_statr(xp,FROUNDHI),
                xp_statr(xp,FSHARPLO), xp_statr(xp,FSHARPHI))

            ntotal = ntotal + nstars

        }

        # Free space
        call sfree (sp)

        return (ntotal)
end
