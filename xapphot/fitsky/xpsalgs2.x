include <mach.h>
include <math/nlfit.h>
include "../lib/fitsky.h"

define	TOL		.001		# fitting tolerance

# XP_CENTROID -- Compute the mode, standard deviation and skew of the sky
# distribution by computing the moments of the histogram. 

int procedure xp_centroid (skypix, coords, wgt, index, nskypix, snx, sny, k1,
	hwidth, binsize, smooth, losigma, hisigma, rgrow, maxiter, sky_mode,
	sky_sigma, sky_skew, nsky, nsky_reject)

real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the sky coordinates array for region growing
real	wgt[ARB]		#I the weights aray for bad data rejection
int	index[ARB]		#I the array of sorted sky pixel indices
int	nskypix			#I the number of sky pixels
int	snx, sny		#I the maximum dimensions of the sky raster
real	k1			#I the size of the sky histogram in sigma
real	hwidth			#I the input sigma of the sky pixels
real	binsize			#I the resolution of the histogram in sigma
int	smooth			#I smooth the histogram before fitting ?
real	losigma, hisigma	#I the upper and lower k-sigma rejection limits
real	rgrow			#I region growing radius in pixels
int	maxiter			#I the maximum number of rejection cycles
real	sky_mode		#O the  computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used in fit
int	nsky_reject		#O the number of sky pixels rejected

double	dsky, sumpx, sumsqpx, sumcbpx
int	nreject, nbins, nker, ier, i, j
pointer	sp, hgm, shgm
real	sky_zero, dmin, dmax, sky_mean, hmin, hmax, dh, locut, hicut, cut
int	xp_grow_hist2(), xp_higmr()
real	xp_asumr(), xp_medr()

begin
	# Intialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Compute the histogram width and binsize.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	sky_mean = xp_medr (skypix, index, nskypix)
	sky_mean = max (dmin, min (sky_mean, dmax))
	if (! IS_INDEFR(hwidth) && hwidth > 0.0) {
	    hmin = sky_mean - k1 * hwidth
	    hmax = sky_mean + k1 * hwidth
	    dh = binsize * hwidth
	} else {
	    cut = min (sky_mean - dmin, dmax - sky_mean, k1 * sky_sigma)
	    hmin = sky_mean - cut
	    hmax = sky_mean + cut
	    dh = binsize * cut / k1
	}

	# Compute the number of histogram bins and the histogram resolution.
	if (dh <= 0.0) {
	    nbins = 1
	    dh = 0.0
	} else {
	    nbins = 2 * nint ((hmax - sky_mean) / dh) + 1
	    dh = (hmax - hmin) / (nbins - 1)
	}

	# Check for a valid histogram.
	if (nbins < 2 || k1 <= 0.0 || sky_sigma < dh || dh <= 0.0 ||
	    sky_sigma <= 0.0) {
	    sky_mode = sky_mean
	    sky_sigma = 0.0
	    sky_skew = 0.0
	    return (XP_SKY_NOHISTOGRAM)
	}

	# Allocate temporary space.
	call smark (sp)
	call salloc (hgm, nbins, TY_REAL)
	call salloc (shgm, nbins, TY_REAL)

	# Accumulate the histogram.
	call aclrr (Memr[hgm], nbins)
	nsky_reject = nsky_reject + xp_higmr (skypix, wgt, index, nskypix,
	    Memr[hgm], nbins, hmin, hmax)
	nsky = nskypix - nsky_reject

	# Do the initial rejection.
	if (nsky_reject > 0) {
	    do i = 1, nskypix {
		if (wgt[index[i]] <= 0.0) {
		    dsky = skypix[index[i]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky * dsky
		    sumcbpx = sumcbpx - dsky * dsky * dsky
		}
	    }
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero, sky_mean,
	        sky_sigma, sky_skew)
	}

	# Fit the mode, sigma an skew of the histogram.
	if (smooth == YES) {
	    nker = max (1, nint (sky_sigma / dh))
	    #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_imode (Memr[shgm], nbins, hmin, hmax, YES, sky_mode, ier)
	} else
	    call xp_imode (Memr[hgm], nbins, hmin, hmax, NO, sky_mode, ier)
	sky_mode = max (dmin, min (sky_mode, dmax))
	if ((IS_INDEFR(losigma) && IS_INDEFR(hisigma)) || (sky_sigma <= dh) ||
	    maxiter < 1) {
	    call sfree (sp)
	    return (XP_OK)
	}

	# Fit histogram with pixel rejection and optional region growing.
	do i = 1, maxiter {

	    # Compute new histogram limits.
	    if (IS_INDEFR(losigma))
		locut = -MAX_REAL
	    else
	        locut = sky_mode - losigma * sky_sigma
	    if (IS_INDEFR(hisigma))
		hicut = MAX_REAL
	    else
	        hicut = sky_mode + hisigma * sky_sigma

	    # Reject pixels.
	    nreject = 0
	    do j = 1, nskypix {
		if (skypix[index[j]] >= locut && skypix[index[j]] <= hicut)
		    next
		if (rgrow > 0.0)
		    nreject = nreject + xp_grow_hist2 (skypix, coords,
			wgt, nskypix, sky_zero, index[j], snx, sny, Memr[hgm],
			nbins, hmin, hmax, rgrow, sumpx, sumsqpx, sumcbpx)
		else if (wgt[index[j]] > 0.0) {
		    call xp_hgmsub2 (Memr[hgm], nbins, hmin, hmax,
		        skypix[index[j]], sky_zero, sumpx, sumsqpx, sumcbpx)
		    wgt[index[j]] = 0.0
		    nreject = nreject + 1
		}
	    }
	    if (nreject == 0)
		break
	    nsky_reject = nsky_reject + nreject
	    nsky = nskypix - nsky_reject 
	    if (nsky <= 0)
		break

	    # Recompute the moments.
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero, sky_mean,
	        sky_sigma, sky_skew)

	    # Recompute the histogram peak.
	    if (smooth == YES) {
		nker = max (1, nint (sky_sigma / dh))
	        #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	        call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	        call xp_imode (Memr[shgm], nbins, hmin, hmax, YES,
		    sky_mode, ier)
	    } else
	        call xp_imode (Memr[hgm], nbins, hmin, hmax, NO, sky_mode, ier)
	    sky_mode = max (dmin, min (sky_mode, dmax))
	    if (sky_sigma <= dh || ier != XP_OK)
		break
	}

	# Return the error codes.
	call sfree (sp)
	if (nsky == 0 || nsky_reject == nskypix || ier == XP_SKY_NOHISTOGRAM) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else
	    return (XP_OK)
end


# XP_SOFILTER -- Fit the peak and width of the histogram using repeated
# convolutions and a triangle function.

int procedure xp_sofilter (skypix, coords, wgt, index, nskypix, snx, sny, k1,
	hwidth, binsize, smooth, losigma, hisigma, rgrow, maxiter, sky_mode,
	sky_sigma, sky_skew, nsky, nsky_reject)

real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the sky coordinates array for region growing
real	wgt[ARB]		#I the weights aray for bad data rejection
int	index[ARB]		#I the array of sorted sky pixel indices
int	nskypix			#I the number of sky pixels
int	snx, sny		#I the maximum dimensions of the sky raster
real	k1			#I the size of the sky histogram in sigma
real	hwidth			#I the input sigma of the sky pixels
real	binsize			#I the resolution of the histogram in sigma
int	smooth			#I smooth the histogram before fitting ?
real	losigma, hisigma	#I the upper and lower k-sigma rejection limits
real	rgrow			#I region growing radius in pixels
int	maxiter			#I the maximum number of rejection cycles
real	sky_mode		#O the  computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used in fit
int	nsky_reject		#O the number of sky pixels rejected

double 	dsky, sumpx, sumsqpx, sumcbpx
int	nreject, nbins, nker, i, j, iter
pointer	sp, hgm, shgm
real	sky_zero, dmin, dmax, hmin, hmax, dh, locut, hicut, sky_mean
real	center, cut
int	xp_grow_hist2(), xp_higmr(), xp_topt()
real	xp_asumr(), xp_medr(), xp_mapr()

begin
	# Initialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Compute a first guess for the parameters.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	sky_mean = xp_medr (skypix, index, nskypix)
	sky_mean = max (dmin, min (sky_mean, dmax))

	# Compute the width and bin size of histogram.
	if (! IS_INDEFR(hwidth) && hwidth > 0.0) {
	    hmin = sky_mean - k1 * hwidth
	    hmax = sky_mean + k1 * hwidth
	    dh = binsize * hwidth
	} else {
	    cut = min (sky_mean - dmin, dmax - sky_mean, k1 * sky_sigma)
	    hmin = sky_mean - cut
	    hmax = sky_mean + cut
	    dh = binsize * cut / k1
	}

	# Compute the number of histogram bins and the resolution.
	# filter.
	if (dh <= 0.0) {
	    nbins = 1
	    dh = 0.0
	} else {
	    nbins = 2 * nint ((hmax - sky_mean) / dh) + 1
	    dh  = (hmax - hmin) / (nbins - 1)
	}

	# Test for a valid histogram.
	if (nbins < 2 || k1 <= 0.0 || sky_sigma <= 0.0 || dh <= 0.0 ||
	    sky_sigma <= dh) {
	    sky_mode = sky_mean
	    sky_sigma = 0.0
	    sky_skew = 0.0
	    return (XP_SKY_NOHISTOGRAM)
	}

	# Allocate temporary space.
	call smark (sp)
	call salloc (hgm, nbins, TY_REAL)
	call salloc (shgm, nbins, TY_REAL)

	# Accumulate the histogram.
	call aclrr (Memr[hgm], nbins)
	nsky_reject = nsky_reject + xp_higmr (skypix, wgt, index, nskypix,
	    Memr[hgm], nbins, hmin, hmax)
	nsky = nskypix - nsky_reject

	# Perform the initial rejection.
	if (nsky_reject > 0) {
	    do i = 1, nskypix {
	        if (wgt[index[i]] <= 0.0) {
		    dsky = skypix[index[i]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky * dsky
		    sumcbpx = sumcbpx - dsky * dsky * dsky
		}
	    }
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero, sky_mean,
	        sky_sigma, sky_skew)
	}

	# Fit the peak of the histogram.
	center = xp_mapr ((hmin + hmax) / 2.0, hmin + 0.5 * dh,
	    hmax + 0.5 * dh, 1.0, real (nbins))
	if (smooth == YES) {
	    nker = max (1, nint (sky_sigma / dh))
	    #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    iter =  xp_topt (Memr[shgm], nbins, center, sky_sigma / dh,
	        TOL, maxiter, NO)
	} else
	    iter = xp_topt (Memr[hgm], nbins, center, sky_sigma / dh, TOL,
	        maxiter, NO)
	sky_mode = xp_mapr (center, 1.0, real (nbins), hmin + 0.5 * dh,
	    hmax + 0.5 * dh)
	sky_mode = max (dmin, min (sky_mode, dmax))
	if (iter < 0) {
	    call sfree (sp)
	    return (XP_SKY_NOCONVERGE)
	}
	if ((IS_INDEFR(losigma) && IS_INDEFR(hisigma)) || (sky_sigma <= dh) ||
	    (maxiter < 1)) {
	    call sfree (sp)
	    return (XP_OK)
	}

	# Fit the histogram with pixel rejection and optional region growing.
	do i = 1, maxiter {

	    # Compute new histogram limits.
	    if (IS_INDEFR(losigma))
		locut = -MAX_REAL
	    else
	        locut = sky_mode - losigma * sky_sigma
	    if (IS_INDEFR(hisigma))
		hicut = MAX_REAL
	    else
	        hicut = sky_mode + hisigma * sky_sigma

	    # Detect and reject the pixels.
	    nreject = 0
	    do j = 1, nskypix {
		if (skypix[index[j]] >= locut && skypix[index[j]] <= hicut)
		    next
		if (rgrow > 0.0)
		    nreject = nreject + xp_grow_hist2 (skypix, coords,
			wgt, nskypix, sky_zero, index[j], snx, sny, Memr[hgm],
			nbins, hmin, hmax, rgrow, sumpx, sumsqpx, sumcbpx)
		else if (wgt[index[j]] > 0.0) {
		    call xp_hgmsub2 (Memr[hgm], nbins, hmin, hmax,
		        skypix[index[j]], sky_zero, sumpx, sumsqpx, sumcbpx)
		    wgt[index[j]] = 0.0
		    nreject = nreject + 1
		}
	    }
	    if (nreject == 0)
		break

	    # Recompute the data limits.
	    nsky_reject = nsky_reject + nreject
	    nsky = nskypix - nsky_reject 
	    if (nsky <= 0)
		break
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	    if (sky_sigma <= dh)
		break

	    # Refit the sky.
	    if (smooth == YES) {
		nker = max (1, nint (sky_sigma / dh))
	        #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	        call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    	iter = xp_topt (Memr[shgm], nbins, center, sky_sigma / dh,
		    TOL, maxiter, NO)
	    } else
	    	iter = xp_topt (Memr[hgm], nbins, center, sky_sigma / dh,
		    TOL, maxiter, NO)
	    sky_mode = xp_mapr (center, 1.0, real (nbins), hmin + 0.5 * dh,
	        hmax + 0.5 * dh)
	    sky_mode = max (dmin, min (sky_mode, dmax))
	    if (iter < 0) 
		break
	}

	# Return an appropriate error code.
	call sfree (sp)
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else if (sky_sigma <= 0.0) {
	    sky_sigma = 0.0
	    sky_skew = 0.0
	    return (XP_OK)
	} else if (iter < 0) {
	    return (XP_SKY_NOCONVERGE)
	} else {
	    return (XP_OK)
	}
end


# XP_CROSSCOR -- Compute the sky value by calculating the
# cross-correlation function of the histogram of the sky pixels and
# a Gaussian function with the same sigma as the sky distribution.
# The peak of the cross-correlation function is found by parabolic
# interpolation.

int procedure xp_crosscor (skypix, coords, wgt, index, nskypix, snx, sny, k1,
	hwidth, binsize, smooth, losigma, hisigma, rgrow, maxiter, sky_mode,
	sky_sigma, sky_skew, nsky, nsky_reject)

real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the sky coordinates array for region growing
real	wgt[ARB]		#I the weights aray for bad data rejection
int	index[ARB]		#I the array of sorted sky pixel indices
int	nskypix			#I the number of sky pixels
int	snx, sny		#I the maximum dimensions of the sky raster
real	k1			#I the size of the sky histogram in sigma
real	hwidth			#I the input sigma of the sky pixels
real	binsize			#I the resolution of the histogram in sigma
int	smooth			#I smooth the histogram before fitting ?
real	losigma, hisigma	#I the upper and lower k-sigma rejection limits
real	rgrow			#I region growing radius in pixels
int	maxiter			#I the maximum number of rejection cycles
real	sky_mode		#O the  computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used in fit
int	nsky_reject		#O the number of sky pixels rejected

double 	dsky, sumpx, sumsqpx, sumcbpx
int	nreject, nbins, nker, nsmooth, ier, i, j
pointer	sp, x, hgm, shgm, kernel
real	dmin, dmax, hmin, hmax, dh, kmin, kmax, locut, hicut, sky_mean, cut
real	sky_zero
int	xp_grow_hist2(), xp_higmr()
real	xp_asumr(), xp_medr()

begin
	# Initialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Set up initial guess at sky mean, sigma and skew.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	sky_mean = xp_medr (skypix, index, nskypix)
	sky_mean = max (dmin, min (sky_mean, dmax))

	# Compute the width and bin size of the histogram.
	if (! IS_INDEFR(hwidth) && hwidth > 0.0) {
	    hmin = sky_mean - k1 * hwidth
	    hmax = sky_mean + k1 * hwidth
	    dh = binsize * hwidth
	} else {
	    cut = min (sky_mean - dmin, dmax - sky_mean, k1 * sky_sigma)
	    hmin = sky_mean - cut
	    hmax = sky_mean + cut
	    dh = binsize * cut / k1
	} 

	# Compute the number of bins in and the width of the kernel.
	if (dh <= 0.0) {
	    nbins = 1
	    nker = 1
	    nsmooth = 1
	    dh = 0.0
	} else {
    	    nbins = 2 * nint ((hmax - sky_mean) / dh) + 1
	    nker = 2 * nint (2.0 * (hmax - sky_mean) / (dh * 3.0)) + 1
	    nsmooth = nbins - nker + 1
	    dh = (hmax - hmin) / (nbins - 1)
	}
	kmin = - dh * (nker / 2 + 0.5)
	kmax = dh * (nker / 2 + 0.5)

	# Test for a valid histogram.
	if (nbins < 2 || k1 <= 0.0 || sky_sigma <= 0.0 || dh <= 0.0 ||
	    sky_sigma <= dh) {
	    sky_mode = sky_mean
	    sky_sigma = 0.0
	    sky_skew = 0.0
	    return (XP_SKY_NOHISTOGRAM)
	}

	# Allocate space for the histogram and kernel.
	call smark (sp)
	call salloc (x, nbins, TY_REAL)
	call salloc (hgm, nbins, TY_REAL)
	call salloc (shgm, nbins, TY_REAL)
	call salloc (kernel, nker, TY_REAL)

	# Set up x array.
	do i = 1, nbins
	    Memr[x+i-1] = i
	call amapr (Memr[x], Memr[x], nbins, 1.0, real (nbins),
	    hmin + 0.5 * dh, hmax + 0.5 * dh)

	# Accumulate the histogram.
	call aclrr (Memr[hgm], nbins)
	call aclrr (Memr[shgm], nbins)
	nsky_reject = nsky_reject + xp_higmr (skypix, wgt, index, nskypix,
	    Memr[hgm], nbins, hmin, hmax)
	nsky = nskypix - nsky_reject

	# Perform the initial rejection cycle.
	if (nsky_reject > 0.0) {
	    do i = 1, nskypix {
	        if (wgt[index[i]] <= 0.0) {
		    dsky = skypix[index[i]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky * dsky
		    sumcbpx = sumcbpx - dsky * dsky * dsky
		}
	    }
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	}

	# Construct kernel and convolve with histogram.
	if (sky_sigma > 0.0) {
	    call xp_gauss_kernel (Memr[kernel], nker, kmin, kmax, sky_sigma)
	    call acnvr (Memr[hgm], Memr[shgm+nker/2], nsmooth, Memr[kernel],
	        nker)
	} else
	    call amovr (Memr[hgm], Memr[shgm], nbins)
	call xp_corfit (Memr[x], Memr[shgm], nbins, sky_mode, ier)
	sky_mode = max (dmin, min (sky_mode, dmax))
	if (ier != OK) {
	    call sfree (sp)
	    return (ier)
	}
	if ((IS_INDEFR(losigma) && IS_INDEFR(hisigma)) || (sky_sigma <= dh) ||
	    maxiter < 1) {
	    call sfree (sp)
	    return (XP_OK)
	}

	# Fit histogram with pixel rejection and optional region growing.
	do i = 1, maxiter {

	    # Compute new histogram limits.
	    if (IS_INDEFR(losigma))
		locut = -MAX_REAL
	    else
	        locut = sky_mode - losigma * sky_sigma
	    if (IS_INDEFR(hisigma))
		hicut = MAX_REAL
	    else
	        hicut = sky_mode + hisigma * sky_sigma

	    # Detect rejected pixels.
	    nreject = 0
	    do j = 1, nskypix {
		if (skypix[index[j]] >= locut && skypix[index[j]] <= hicut)
		    next
		if (rgrow > 0.0)
		    nreject = nreject + xp_grow_hist2 (skypix, coords,
			wgt, nskypix, sky_zero, index[j], snx, sny, Memr[hgm],
			nbins, hmin, hmax, rgrow, sumpx, sumsqpx, sumcbpx)
		else if (wgt[index[j]] > 0.0) {
		    call xp_hgmsub2 (Memr[hgm], nbins, hmin, hmax,
			skypix[index[j]], sky_zero, sumpx, sumsqpx, sumcbpx)
		    wgt[index[j]] = 0.0
		    nreject = nreject + 1
		}
	    }
	    if (nreject == 0)
		break

	    # Update the sky parameters.
	    nsky_reject = nsky_reject + nreject
	    nsky = nskypix - nsky_reject 
	    if (nsky <= 0)
		break
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	    if (sky_sigma <= dh)
		break

	    # Recompute the peak of the histogram.
	    call xp_gauss_kernel (Memr[kernel], nker, kmin, kmax, sky_sigma)
	    call aclrr (Memr[shgm], nbins)
	    call acnvr (Memr[hgm], Memr[shgm+nker/2], nsmooth, Memr[kernel],
	        nker)
	    call xp_corfit (Memr[x], Memr[shgm], nbins, sky_mode, ier)
	    sky_mode = max (dmin, min (sky_mode, dmax))
	    if (ier != XP_OK)
		 break
	}

	# Return the appropriate error code.
	call sfree (sp)
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else if (ier != XP_OK) {
	    sky_mode = sky_mean
	    sky_sigma = 0.0
	    sky_skew = 0.0 
	    return (ier)
	} else
	    return (XP_OK)
end


# XP_GAUSS -- Compute the peak, width and skew of the histogram by fitting a
# skewed Gaussian function to the histogram.

int procedure xp_gauss (skypix, coords, wgt, index, nskypix, snx, sny, maxfit,
	k1, hwidth, binsize, smooth, losigma, hisigma, rgrow, maxiter,
	sky_mode, sky_sigma, sky_skew, nsky, nsky_reject)

real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the sky coordinates array for region growing
real	wgt[ARB]		#I the weights aray for bad data rejection
int	index[ARB]		#I the array of sorted sky pixel indices
int	nskypix			#I the number of sky pixels
int	snx, sny		#I the maximum dimensions of the sky raster
int	maxfit			#I the  maximum number of iterations per fit
real	k1			#I the size of the sky histogram in sigma
real	hwidth			#I the input sigma of the sky pixels
real	binsize			#I the resolution of the histogram in sigma
int	smooth			#I smooth the histogram before fitting ?
real	losigma, hisigma	#I the upper and lower k-sigma rejection limits
real	rgrow			#I region growing radius in pixels
int	maxiter			#I the maximum number of rejection cycles
real	sky_mode		#O the  computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used in fit
int	nsky_reject		#O the number of sky pixels rejected

double	dsky, sumpx, sumsqpx, sumcbpx
int	i, j, nreject, nbins, nker, ier
pointer	sp, x, hgm, shgm, w
real	sky_mean, sky_msigma, dmin, dmax, hmin, hmax, dh, locut, hicut, cut
real	sky_zero
int	xp_grow_hist2(), xp_higmr()
real	xp_asumr(), xp_medr()

begin
	# Initialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Compute initial guess for sky statistics.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_msigma, sky_skew)
	sky_mean = xp_medr (skypix, index,  nskypix)
	sky_mean = max (dmin, min (sky_mean, dmax))

	# Compute the width and bin size of the sky histogram.
	if (! IS_INDEFR(hwidth) && hwidth > 0.0) {
	    hmin = sky_mean - k1 * hwidth
	    hmax = sky_mean + k1 * hwidth
	    dh = binsize * hwidth
	} else {
	    cut = min (sky_mean - dmin, dmax - sky_mean, k1 * sky_msigma)
	    hmin = sky_mean - cut
	    hmax = sky_mean + cut
	    dh = binsize * cut / k1
	}

	# Compute the number of histogram bins and width of smoothing kernel.
	if (dh <= 0.0) {
	    nbins = 1
	    dh = 0.0
	} else {
	    nbins = 2 * nint ((hmax - sky_mean) / dh) + 1
	    dh = (hmax - hmin) / (nbins - 1)
	}

	# Test for a valid histogram.
	if (sky_msigma <= dh || dh <= 0.0 ||  k1 <= 0.0 || sky_msigma <= 0.0 ||
	    nbins < 4) {
	    sky_mode = sky_mean
	    sky_sigma = 0.0
	    sky_skew = 0.0
	    return (XP_SKY_NOHISTOGRAM)
	}

	# Allocate temporary working space.
	call smark (sp)
	call salloc (x, nbins, TY_REAL)
	call salloc (hgm, nbins, TY_REAL)
	call salloc (shgm, nbins, TY_REAL)
	call salloc (w, nbins, TY_REAL)

	# Compute the x array.
	do i = 1, nbins
	    Memr[x+i-1] = i
	call amapr (Memr[x], Memr[x], nbins, 1.0, real (nbins),
	    hmin + 0.5 * dh, hmax + 0.5 * dh)

	# Accumulate the histogram.
	call aclrr (Memr[hgm], nbins)
	nsky_reject = nsky_reject + xp_higmr (skypix, wgt, index, nskypix,
	    Memr[hgm], nbins, hmin, hmax)
	nsky = nskypix - nsky_reject

	# Do the initial rejection.
	if (nsky_reject > 0) {
	    do i = 1, nskypix {
		if (wgt[index[i]] <= 0.0) {
		    dsky = skypix[index[i]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky * dsky
		    sumcbpx = sumcbpx - dsky * dsky * dsky
		}
	    }
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_msigma, sky_skew)
	}

	# Find the mode, sigma and skew of the histogram.
	if (smooth == YES) {
	    nker = max (1, nint (sky_msigma / dh))
	    #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_hist_mode (Memr[x], Memr[shgm], Memr[w], nbins,
		sky_mode, sky_sigma, sky_skew, maxfit, TOL, ier)
	} else
	    call xp_hist_mode (Memr[x], Memr[hgm], Memr[w], nbins,
		sky_mode, sky_sigma, sky_skew, maxfit, TOL, ier)
	sky_mode = max (dmin, min (sky_mode, dmax))
	if (ier != XP_OK) {
	    call sfree (sp)
	    return (ier)
	}
	if ((IS_INDEFR(losigma) && IS_INDEFR(hisigma)) || sky_sigma <= dh ||
	    maxiter < 1) {
	    call sfree (sp)
	    return (XP_OK)
	}

	# Fit histogram with pixel rejection and optional region growing.
	do i = 1, maxiter {

	    # Compute the new rejection limits.
	    if (IS_INDEFR(losigma))
		locut = -MAX_REAL
	    else
	        locut = sky_mode - losigma * sky_msigma
	    if (IS_INDEFR(hisigma))
		hicut = MAX_REAL
	    else
	        hicut = sky_mode + hisigma * sky_msigma

	    # Detect and reject pixels.
	    nreject = 0
	    do j = 1, nskypix {
		if (skypix[index[j]] >= locut && skypix[index[j]] <= hicut)
		    next
		if (rgrow > 0.0)
		    nreject = nreject + xp_grow_hist2 (skypix, coords,
			wgt, nskypix, sky_zero, index[j], snx, sny, Memr[hgm],
			nbins, hmin, hmax, rgrow, sumpx, sumsqpx, sumcbpx)
		else if (wgt[index[j]] > 0.0) {
		    call xp_hgmsub2 (Memr[hgm], nbins, hmin, hmax,
		        skypix[index[j]], sky_zero, sumpx, sumsqpx, sumcbpx)
		    wgt[index[j]] = 0.0
		    nreject = nreject + 1
		}
	    }
	    if (nreject == 0)
		break
	    nsky_reject = nsky_reject + nreject
	    nsky = nskypix - nsky_reject 
	    if (nsky <= 0)
		break
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero, sky_mean,
		sky_msigma, sky_skew)

	    # Recompute mean, mode, sigma and skew.
	    if (smooth == YES) {
		nker = max (1, nint (sky_msigma / dh))
	        #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	        call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    	call xp_hist_mode (Memr[x], Memr[shgm], Memr[w], nbins,
		    sky_mode, sky_sigma, sky_skew, maxfit, TOL, ier)
	    } else
	    	call xp_hist_mode (Memr[x], Memr[hgm], Memr[w], nbins,
		    sky_mode, sky_sigma, sky_skew, maxfit, TOL, ier)
	    sky_mode = max (dmin, min (sky_mode, dmax))
	    if (ier != XP_OK)
		break
	    if (sky_sigma <= dh)
		break
	}

	# Return appropriate error code.
	call sfree (sp)
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else if (ier == XP_SKY_TOOSMALL) {
	    return (XP_SKY_TOOSMALL)
	} else if (ier != XP_OK) {
	    return (ier)
	} else
	    return (XP_OK)
end


# XP_IMODE -- Procedure to compute the 1st, 2nd and third moments of the
# histogram of sky pixels.

procedure xp_imode (hgm, nbins, z1, z2, smooth, sky_mode, ier)

real	hgm[ARB]		#I the input  histogram
int	nbins			#I the number of bins
real	z1, z2			#I the  min and max of the histogram
int	smooth			#I has the histogram been smoothed ?
real	sky_mode		#O the computed mode of histogram
int	ier			#O error code

int	i, noccup
double	sumi, sumix, x, dh
real	hmean, dz
real	asumr()

begin
	# Initialize the sums.
	sumi = 0.0
	sumix = 0.0

	# Compute a continuum level.
	if (smooth == NO) 
	    hmean = asumr (hgm, nbins) / nbins
	else {
	    call alimr (hgm, nbins, dz, hmean)
	    hmean = 2.0 * hmean / 3.0
	}

	# Accumulate the sums.
	noccup = 1
	dz = (z2 - z1) / (nbins - 1)
	x = z1 + 0.5 * dz
	do i = 1, nbins {
	    dh = hgm[i] - hmean
	    if (dh > 0.0d0) {
	        sumi = sumi + dh
	        sumix = sumix + dh * x
	        noccup = noccup + 1
	    }
	    x = x + dz
	}

	# Compute the sky mode, sigma and skew.
	if (sumi > 0.0) {
	    sky_mode = sumix / sumi
	    ier = XP_OK
	} else {
	    sky_mode = INDEFR
	    ier = XP_SKY_NOHISTOGRAM
	}
end


# XP_GAUSS_KERNEL -- Compute a Gaussian kernel of given length and sigma.

procedure xp_gauss_kernel (kernel, nker, kmin, kmax, sky_sigma)

real	kernel[ARB]		#O the computed kernel 
int	nker			#I the length of the kernel
real	kmin, kmax		#I the limits of the kernel
real	sky_sigma		#I the sigma of the kernel

int	i
real	dk, x, sumx

begin
	# Return 1 if unit sized kernel.
	if (nker == 1) {
	    kernel[1] = 1.0
	    return
	}

	# Intialize.
	sumx = 0.0
	x = kmin
	dk = (kmax - kmin ) / (nker - 1)

 	# Compute and normalize the kernel.
	do i = 1, nker {
	    kernel[i] = exp (- (x ** 2) / (2. * sky_sigma ** 2))
	    sumx = sumx + kernel[i]
	    x = x + dk
	}
        do i = 1, nker
            kernel[i] = kernel[i] / sumx
end


# XP_CORFIT -- Compute the peak of the cross-correlation function using
# parabolic interpolation.

procedure xp_corfit (x, shgm, nbins, sky_mode, ier)

real	x[ARB]				#I the x coordinates of histogram
real	shgm[ARB]			#I the input  convolved histogram
int	nbins				#I the size of the histogram
real	sky_mode			#O the computed sky mode
int	ier				#O the error code

int	bin
real	max, xo, dh1, dh2

begin
	call xp_amaxel (shgm, nbins, max, bin)
	if (max <= 0) {
	    ier = XP_SKY_FLATHISTOGRAM
	} else if (bin == 1) {
	    sky_mode = x[1]
	    ier = XP_OK
	} else if (bin == nbins) {
	    sky_mode = x[nbins]
	    ier = XP_OK
	} else {
	    xo = 0.5 * (x[bin] + x[bin-1])
	    dh1 = shgm[bin] - shgm[bin-1] 
	    dh2 = shgm[bin] - shgm[bin+1]
	    sky_mode = xo + (x[bin] - x[bin-1]) * (dh1 / (dh1 + dh2))
	    ier = XP_OK
	}
end


# XP_HIST_MODE -- Fit a skewed Gaussian function to the histogram of the sky
# pixels.

procedure xp_hist_mode (x, hgm, w, nbins, sky_mode, sky_sigma, sky_skew,
        maxiter, tol, ier)

real	x[ARB]			#I the x coordinates of the histogram
real	hgm[ARB]		#I the input histogram
real	w[ARB]			#I the histogram  weights array
int	nbins			#I the size of the histogram
real	sky_mode		#O the computed  sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	maxiter			#I the maximum number of iterations
real	tol			#I the fit tolerance
int	ier			#O the  error code

extern  gausskew, dgausskew
int	i, imin, imax, np, fier
pointer	sp, list, fit, nl
real	p[4], dp[4], dummy1
int	locpr()

begin
	# Allocate working memory.
	call smark (sp)
	call salloc (list, 4, TY_INT)
	call salloc (fit, nbins, TY_REAL)

	# Initialize.
	do i = 1, 4
	    Memi[list+i-1] = i

	# Compute initial guesses for the parameters.
	call xp_alimr (hgm, nbins, dummy1, p[1], imin, imax)
	p[2] = x[imax]
	p[3] = abs ((x[nbins] - x[1]) / 6.0) ** 2
	p[4] = 0.0
	np = 4

	# Fit the histogram.
	call nlinitr (nl, locpr (gausskew), locpr (dgausskew), p, dp, np,
	    Memi[list], 4, tol, maxiter)
	call nlfitr (nl, x, hgm, w, nbins, 1, WTS_UNIFORM, fier)
	call nlvectorr (nl, x, Memr[fit], nbins, 1)
	call nlpgetr (nl, p, np)
	call nlfreer (nl)

	call sfree (sp)

	# Return the appropriate error code.
	ier = XP_OK
	if (fier == NO_DEG_FREEDOM) {
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    ier = XP_SKY_TOOSMALL
	} else {
	    if (fier == SINGULAR)
		ier = XP_SKY_SINGULAR
	    else if (fier == NOT_DONE)
		ier = XP_SKY_NOCONVERGE
	    if (p[2] < x[1] || p[2] > x[nbins]) {
		sky_mode = x[imax]
		ier = XP_SKY_BADPARS
	    } else
	        sky_mode = p[2]
	    if (p[3] <= 0.0) {
		sky_sigma = 0.0
		sky_skew = 0.0
		ier = XP_SKY_BADPARS
	    } else {
	        sky_sigma = sqrt (p[3])
	        sky_skew = 1.743875281 * abs (p[4]) ** (1.0 / 3.0) * sky_sigma
	        if (p[4] < 0.0)
		    sky_skew = - sky_skew
	    }
	}
end


# XP_GROW_HIST -- Procedure to reject pixels with region growing.

int procedure xp_grow_hist (skypix, coords, wgt, nskypix, index, snx, sny, hgm,
        nbins, z1, z2, rgrow)

real	skypix[ARB]		#I the array of sky pixels
int	coords[ARB]		#I the array of sky pixel coordinates
real	wgt[ARB]		#I the array of sky pixel weights
int	nskypix			#I the  number of sky pixels
int	index			#I the  index of the pixel to be rejected
int	snx, sny		#I the  size of the sky subraster
real	hgm[ARB]		#U the input / output histogram
int	nbins			#I the size of the histogram
real	z1, z2			#I the values of the first and last bin
real	rgrow			#I the region growing radius

int	j, k, ixc, iyc, ymin, ymax, xmin, xmax, nreject, cstart, c, bin
real	dh, r2, rgrow2, d

begin
	# Find the x and y coordinates of the pixel to be rejected.
	ixc = mod (coords[index], snx)
	if (ixc == 0)
	    ixc = snx
	iyc = (coords[index] - ixc) / snx + 1

	# Find the coordinate space to be used for regions growing.
	ymin = max (1, int (iyc - rgrow))
	ymax = min (sny, int (iyc + rgrow))
	xmin = max (1, int (ixc - rgrow))
	xmax = min (snx, int (ixc + rgrow))
	if (ymin <= iyc)
	    cstart = min (nskypix, max (1, index - int (rgrow) + snx *
	        (ymin - iyc)))
	else
	    cstart = index

	# Perform the region growing.
	dh = real (nbins - 1) / (z2 - z1)
	rgrow2 = rgrow ** 2
	nreject = 0
	do j = ymin, ymax {
	    d = rgrow2 - (j - iyc) ** 2
	    if (d <= 0.0)
		d = 0.0
	    else
		d = sqrt (d)
	    do k = max (xmin, int (ixc - d)), min (xmax, int (ixc + d)) {
		c = k + (j - 1) * snx
		while (coords[cstart] < c && cstart < nskypix)
		    cstart = cstart + 1
		r2 = (k - ixc) ** 2 + (j - iyc) ** 2
		if (r2 <= rgrow2 && c == coords[cstart] && wgt[cstart] > 0.0) {
		    nreject = nreject + 1
		    wgt[cstart] = 0.0
		    if (skypix[cstart] >= z1 && skypix[cstart] <= z2) {
		        bin = int ((skypix[cstart] - z1) * dh) + 1
		        hgm[bin] = hgm[bin] - 1.0
		    }
		}
	    }
	}

	return (nreject)
end


# XP_GROW_HIST2 -- Procedure to reject pixels with region growing.

int procedure xp_grow_hist2 (skypix, coords, wgt, nskypix, sky_zero, index,
	snx, sny, hgm, nbins, z1, z2, rgrow, sumpx, sumsqpx, sumcbpx)

real	skypix[ARB]		#I the sky pixel array
int	coords[ARB]		#I the sky pixel coordinates array
real	wgt[ARB]		#I the sky pixel weights array
int	nskypix			#I the number of sky pixels
real	sky_zero		#I the zero point for the moment analysis
int	index			#I the index of the pixel to be rejected
int	snx, sny		#I the size of the sky subraster
real	hgm[ARB]		#U the input / output histogram
int	nbins			#I the size of the histogram
real	z1, z2			#I the  value of first and last bin
real	rgrow			#I the  region growing radius
double	sumpx			#U the  sum of the sky values
double	sumsqpx			#U the sum of sky values squared
double	sumcbpx			#U the  sum of sky values cubed

double	dsky
int	j, k, ixc, iyc, ymin, ymax, xmin, xmax, nreject, cstart, c, bin
real	dh, r2, rgrow2, d

begin
	# Find the coordinates of the region growing center.
	ixc = mod (coords[index], snx)
	if (ixc == 0)
	    ixc = snx
	iyc = (coords[index] - ixc) / snx + 1

	ymin = max (1, int (iyc - rgrow))
	ymax = min (sny, int (iyc + rgrow))
	xmin = max (1, int (ixc - rgrow))
	xmax = min (snx, int (ixc + rgrow))
	dh = real (nbins - 1) / (z2 - z1)
	if (ymin <= iyc)
	    cstart = min (nskypix, max (1, index - int (rgrow) + snx *
	        (ymin - iyc)))
	else
	    cstart = index

	# Perform the region growing.
	nreject = 0
	rgrow2 = rgrow ** 2
	do j = ymin, ymax {
	    d = sqrt (rgrow2 - (j - iyc) ** 2)
	    do k = max (xmin, int (ixc - d)), min (xmax, int (ixc + d)) {
		c = k + (j - 1) * snx
		while (coords[cstart] < c && cstart < nskypix)
		    cstart = cstart + 1
		r2 = (k - ixc) ** 2 + (j - iyc) ** 2
		if (r2 <= rgrow2 && c == coords[cstart] && wgt[cstart] > 0.0) {
		    nreject = nreject + 1
		    wgt[cstart] = 0.0
		    dsky = skypix[cstart] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		    if (skypix[cstart] >= z1 && skypix[cstart] <= z2) {
		        bin = int ((skypix[cstart] - z1) * dh) + 1
		        hgm[bin] = hgm[bin] - 1.0
		    }
		}
	    }
	}

	return (nreject)
end


# XP_HGMSUB -- Procedure to subtract a point from an existing  histogram.

procedure xp_hgmsub (hgm, nbins, z1, z2, skypix)

real	hgm[ARB]		#U the input / output histogram
int	nbins			#I the size of the histogram
real	z1, z2			#I the  range of the histogram
real	skypix	               	#I the sky value to be subtracted

int	bin
real	dh

begin
	if (skypix < z1 || skypix > z2)
	    return
	dh = real (nbins - 1) / (z2 - z1)
	bin = int ((skypix - z1) * dh) + 1
	hgm[bin] = hgm[bin] - 1.0
end


# XP_HGMSUB2 -- Procedure to subract points from the accumulated sums
# and the existing histogram.

procedure xp_hgmsub2 (hgm, nbins, z1, z2, skypix, sky_zero, sumpx, sumsqpx,
	sumcbpx)

real	hgm[ARB]		#U the input / output histogram
int	nbins			#I the size of the histogram
real	z1, z2			#I the range of the histogram
real	skypix	               	#I the sky value to be subtracted
real	sky_zero		#I the zero point for the moment analysis
double	sumpx			#U the sum of the sky pixels
double	sumsqpx			#U the sum of the squares of the sky pixels
double	sumcbpx			#U the sum of the cubes of the sky pixels

double	dsky
int	bin
real	dh

begin
	if (skypix < z1 || skypix > z2)
	    return
	dsky = skypix - sky_zero
	sumpx = sumpx - dsky
	sumsqpx = sumsqpx - dsky ** 2
	sumcbpx = sumcbpx - dsky ** 3
	dh = real (nbins - 1) / (z2 - z1)
	bin = int ((skypix - z1) * dh) + 1
	hgm[bin] = hgm[bin] - 1.0
end
