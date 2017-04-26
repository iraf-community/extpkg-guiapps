include <imhdr.h>
include <imset.h>
include <mach.h>
include <math.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/find.h"

# XP_BSKY -- Compute sky vlaues for a list of objects.

int procedure xp_bsky (im, ol, rl, xp, verbose)

pointer im                      #I pointer to the input image descriptor
int     ol                      #I input objects file descriptor
int     rl                      #I output results file descriptor
pointer xp                      #I pointer to the main xapphot structure
int     verbose                 #I print summary of output

int     ier, loseqno, seqno
pointer sp, imname, olname, symbol
real	xver, yver
int     xp_robjects(), xp_ofitsky()
pointer sthead(), xp_statp()

begin
        if (ol == NULL)
            return

	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)

	loseqno = 0
	seqno = SEQNO(xp_statp(xp,PSTATUS))
        while (xp_robjects (ol, xp, RLIST_TEMP) > 0) {
            symbol = sthead (xp_statp (xp, OBJLIST))
            if (symbol == NULL)
                break
	    loseqno = loseqno + 1
            ier = xp_ofitsky (xp, im, symbol, 0.0, 0.0, xver, yver, 0,
	        NULL, NULL)
	    if (rl == NULL) {
                if (verbose == YES)
                    call xp_sqprint (xp, Memc[imname], ier, NO)
    		next
	    } else if (verbose == YES)
                call xp_sqprint (xp, Memc[imname], ier, YES)
	    seqno = seqno + 1
	    call xp_swrite (xp, rl, seqno, Memc[olname], loseqno, ier)
        }
	SEQNO(xp_statp(xp,PSTATUS)) = seqno

	call sfree (sp)

	return (loseqno)
end



# XP_ASKY -- Compute sky values for a list of objects.

int procedure xp_asky (gd, im, rl, xp, verbose)

pointer gd                      #I pointer to the graphics stream
pointer im                      #I pointer to the input image descriptor
int     rl                      #I output results file descriptor
pointer xp                      #I pointer to the main xapphot structure
int     verbose                 #I print summary of output

int     i, j, k, fwidth, swidth, norm, nxb, nyb, nstars, l1, l2, nlines, ntotal
int     c1, c2, ncols, ier, seqno
pointer gker2d, ngker2d, skip, imbuf, denbuf, x, y
real    sigma, nsigma, a, b, c, f, dmin, dmax, relerr, xver, yver
real    gsums[LEN_GAUSS]
int     xp_staget(), xp_fitsky()
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

                # Find the stars.
                nstars = xp_staget (xp, Memr[imbuf], Memr[denbuf], Memr[x],
                    Memr[y], ncols, nlines, c1, c2, l1, l2, swidth, Memi[skip],
                    fwidth, fwidth, dmin, dmax)

		# Mark the stars
		if (gd != NULL)
		    call xp_mkfobjects (gd, xp, Memr[x], Memr[y], nstars,
			seqno, 1, 1)

                # Center, mark, and record the stars
                do k = 1, nstars {
                    ier = xp_fitsky (xp, im, Memr[x+k-1], Memr[y+k-1], xver,
			yver, 0, NULL, gd)
                    if (gd != NULL)
                        call xp_smark (gd, xp, xver, yver, 0, 1, 1)
                    if (rl == NULL) {
                        if (verbose == YES)
                            call xp_sqprint (xp, IM_HDRFILE(im), ier, NO)
                        next
		    } else if (verbose == YES)
                        call xp_sqprint (xp, IM_HDRFILE(im), ier, YES)
                    call xp_swrite (xp, rl, seqno + k, "none", 0, ier)
                }

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
