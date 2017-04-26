include <mach.h>
include "../lib/fitsky.h"

define	MEDCUT		0.025


# XP_MEAN -- Compute the mean of the sky pixel array.

int procedure xp_mean (skypix, coords, wgt, index, nskypix, snx, sny, losigma,
	hisigma, rgrow, maxiter, sky_mean, sky_sigma, sky_skew, nsky,
	nsky_reject)

real	skypix[ARB]		#I the unsorted array of sky pixels
int	coords[ARB]		#I the coordinate array for region growing
real	wgt[ARB]		#I the weight array for rejection
int	index[ARB]		#I the array of sorted indices
int	nskypix			#I the total number of sky pixels
int	snx, sny		#I the dimensions of the sky subraster
real	losigma, hisigma	#I the ksigma sky pixel region criteria
real	rgrow			#I the radius of the region growing circle
int	maxiter			#I the maximum number of rejection cycles
real	sky_mean		#O the computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used
int	nsky_reject		#O the number of sky pixels rejected

double  dsky, sumpx, sumsqpx, sumcbpx
int	i, j, nreject
real	sky_zero, dmin, dmax, locut, hicut
int	xp_grow_regions()
real	xp_asumr()

begin
	# Intialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mean = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Compute the mean, sigma and skew.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	sky_mean = max (dmin, min (sky_mean, dmax))

	# Decide whether to do the rejection cycle.
	if (maxiter < 1 || (IS_INDEFR(losigma) && IS_INDEFR(hisigma)) ||
	    sky_sigma <= 0.0)
	    return (XP_OK)

	# Reject points within k1 * sky_sigma of the median.
	do i = 1, maxiter {

	    # Compute the new rejection limits.
	    if (IS_INDEFR(losigma))
		locut = max (-MAX_REAL, dmin)
	    else if (i == 1)
		locut = sky_mean -  min (sky_mean - dmin, dmax - sky_mean,
		    losigma * sky_sigma)
	    else
	        locut = sky_mean - losigma * sky_sigma
	    if (IS_INDEFR(hisigma))
		hicut = min (MAX_REAL, dmax)
	    else if (i == 1)
		hicut = sky_mean + min (dmax - sky_mean, sky_mean - dmin,
		    hisigma * sky_sigma)
	    else
	        hicut = sky_mean + hisigma * sky_sigma

	    nreject = 0
	    do j = 1, nskypix {
	        if (wgt[index[j]] <= 0.0)
		    next
	        if (skypix[index[j]] < locut || skypix[index[j]] > hicut) {
		    if (rgrow > 0.0) {
		        nreject = xp_grow_regions (skypix, coords, wgt,
			    nskypix, sky_zero, index[j], snx, sny, rgrow,
			    sumpx, sumsqpx, sumcbpx)
		    } else {
			dsky = (skypix[index[j]] - sky_zero)
		        sumpx = sumpx - dsky
		        sumsqpx = sumsqpx - dsky ** 2
		        sumcbpx = sumcbpx - dsky ** 3
		        wgt[index[j]] = 0.0 
		        nreject = nreject + 1
		    }
	        }
	    }

	    # Test the number of rejected pixels.
	    if (nreject <= 0)
		break
	    nsky_reject = nsky_reject + nreject

	    # Test that some pixels actually remain.
	    nsky = nskypix - nsky_reject
	    if (nsky <= 0)
		break

	    # Recompute the mean, sigma and skew.
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	    if (sky_sigma <= 0.0)
		break
	    sky_mean = max (dmin, min (sky_mean, dmax))
	}

	# Return an appropriate error code.
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mean = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else
	    return (XP_OK)
end


# XP_MEDIAN -- Compute the median of the sky pixel array.

int procedure xp_median (skypix, coords, wgt, index, nskypix, snx, sny,
	losigma, hisigma, rgrow, maxiter, sky_med, sky_sigma, sky_skew,
	nsky, nsky_reject)

real	skypix[ARB]		#I the unsorted array of sky pixels
int	coords[ARB]		#I the sky coordinates array for region growing
real	wgt[ARB]		#I the sky weights for bad data rejection
int	index[ARB]		#I the array of sorted sky pixel indices
int	nskypix			#I the total number of sky pixels
int	snx, sny		#I the dimensions of the sky subraster
real	losigma, hisigma	#I the upper and lower ksigma rejection limits
real	rgrow			#I the radius of the region growing circle
int	maxiter			#I the maximum number of rejection cycles
real	sky_med			#O the computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewness
int	nsky			#O the number of sky pixels used
int	nsky_reject		#O the number of sky pixels rejected

double  dsky, sumpx, sumsqpx, sumcbpx
int	i, j, ilo, ihi, il, ih, med, medcut
real	sky_zero, sky_mean, locut, hicut, dmin, dmax
int	xp_grow_regions(), xp_imed()
real	xp_asumr(), xp_smed(), xp_wsmed()

begin
	# Intialize.
	nsky = nskypix
	nsky_reject = 0
	sky_med = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Sort the sky pixels and compute the median, mean, sigma and skew.
	# MEDCUT tries to correct for quantization effects
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	medcut = nint (MEDCUT * real (nskypix))
	sky_med = xp_smed (skypix, index, nskypix, medcut)
	sky_med = max (dmin, min (sky_med, dmax))
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	sky_mean = max (dmin, min (sky_mean, dmax))
	if (maxiter < 1 || (IS_INDEFR(losigma) && IS_INDEFR(hisigma)) ||
	    sky_sigma <= 0.0)
	    return (XP_OK)

	# Reject points outside losigma * sky_sigma and hisigma * sky_sigma
	# of the median.
	ilo = 1
	ihi = nskypix
	do i = 1, maxiter {

	    # Compute the new rejection limits.
	    if (IS_INDEFR(losigma))
		locut = max (-MAX_REAL, dmin)
	    else if (i == 1)
		locut = sky_med - min (sky_med - dmin, dmax - sky_med,
		    losigma * sky_sigma)
	    else
	        locut = sky_med - losigma * sky_sigma
	    if (IS_INDEFR(hisigma))
		hicut = min (MAX_REAL, dmax)
	    else if (i == 1)
		hicut = sky_med + min (dmax - sky_med, sky_med - dmin,
		    hisigma * sky_sigma)
	    else
	        hicut = sky_med + hisigma * sky_sigma

	    # Detect pixels to be rejected.
	    for (il = ilo; il <= nskypix; il = il + 1) {
		if (skypix[index[il]] >= locut)
		    break
	    }
	    for (ih = ihi; ih >= 1; ih = ih - 1) {
		if (skypix[index[ih]] <= hicut)
		    break
	    }
	    if (il == ilo && ih == ihi)
		break

	    # Reject pixels with optional region growing.
	    if (rgrow > 0.0) {

		# Reject low side pixels with region growing.
	        do j = ilo, il - 1 
		    nsky_reject = nsky_reject + xp_grow_regions (skypix,
		        coords, wgt, nskypix, sky_zero, index[j], snx, sny,
			rgrow, sumpx, sumsqpx, sumcbpx)

		# Reject high side pixels with region growing.
		do j = ih + 1, ihi
		    nsky_reject = nsky_reject + xp_grow_regions (skypix,
		        coords, wgt, nskypix, sky_zero, index[j], snx, sny,
			rgrow, sumpx, sumsqpx, sumcbpx)

		# Recompute the median.
		nsky = nskypix - nsky_reject
		med = xp_imed (wgt, index, il, ih, (nsky + 1) / 2)


	    } else {

		# Recompute the number of sky pixels, the number of rejected
		# pixels and median pixel
		nsky_reject = nsky_reject + (il - ilo) + (ihi - ih)
		nsky = nskypix - nsky_reject
		med = (ih + il) / 2

		# Reject pixels on the low side.
		do j = ilo, il - 1 {
		    dsky = skypix[index[j]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		}

		# Reject pixels on the high side.
		do j = ih + 1, ihi {
		    dsky = skypix[index[j]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		}
	    }
	    if (nsky <= 0)
		break

	    # Recompute the median, sigma and skew.
	    medcut = nint (MEDCUT * real (nsky))
	    sky_med = xp_wsmed (skypix, index, wgt, nskypix, med, medcut)
	    sky_med = max (dmin, min (sky_med, dmax))
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	    sky_mean = max (dmin, min (sky_mean, dmax))
	    if (sky_sigma <= 0.0)
		break
	    ilo = il
	    ihi = ih
	}

	# Return an appropriate error code.
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_med = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else
	    return (XP_OK)
end


# XP_MODE -- Compute the mode of the sky pixel array.

int procedure xp_mode (skypix, coords, wgt, index, nskypix, snx, sny, losigma,
	hisigma, rgrow, maxiter, sky_mode, sky_sigma, sky_skew, nsky,
	nsky_reject)

real	skypix[ARB]		#I the unsorted array of skypixels
int	coords[ARB]		#I the coordinate array for region growing
real	wgt[ARB]		#I the array of weights for rejection
int	index[ARB]		#I the sorted array of sky pixel indices
int	nskypix			#I the total number of sky pixels
int	snx, sny		#I the dimensions of the sky subraster
real	losigma, hisigma	#I the upper and lower ksigma rejection limits
real	rgrow			#I the radius of the region growing circle
int	maxiter			#I the maximum number of cycles of rejection
real	sky_mode		#O the computed sky value
real	sky_sigma		#O the computed sky sigma
real	sky_skew		#O the computed sky skewnes
int	nsky			#O the number of sky pixels used
int	nsky_reject		#O the number of sky pixels rejected

double	dsky, sumpx, sumsqpx, sumcbpx
int	i, j, ilo, ihi, il, ih, med, medcut
real	sky_zero, dmin, dmax, locut, hicut, sky_mean, sky_med
int	xp_grow_regions(), xp_imed()
real	xp_asumr(), xp_smed(), xp_wsmed()

begin
	# Initialize.
	nsky = nskypix
	nsky_reject = 0
	sky_mode = INDEFR
	sky_sigma = INDEFR
	sky_skew = INDEFR
	if (nskypix <= 0)
	    return (XP_SKY_NOPIXELS)

	# Compute the median, sigma, skew and sky mode.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	medcut = nint (MEDCUT * real (nskypix))
	sky_med = xp_smed (skypix, index, nskypix, medcut)
	sky_med = max (dmin, min (sky_med, dmax))
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, sky_mean, sky_sigma, sky_skew)
	sky_mean = max (dmin, min (sky_mean, dmax))
	if (sky_mean < sky_med)
	    sky_mode = sky_mean
	else
	    sky_mode = 3.0 * sky_med - 2.0 * sky_mean
	sky_mode = max (dmin, min (sky_mode, dmax))
	if (maxiter < 1 || (IS_INDEFR(losigma) && IS_INDEFR(hisigma)) ||
	    sky_sigma <= 0.0)
	    return (XP_OK)

	# Reject points outside losigma * sky_sigma and hisigma * sky_sigma
	# of the mode.
	ilo = 1
	ihi = nskypix
	do i = 1, maxiter {

	    # Compute the new rejection limits.
	    if (i == 1) {
		if (IS_INDEFR(losigma))
		    locut = max (-MAX_REAL, dmin)
		else
	            locut = sky_med - min (sky_med - dmin, dmax - sky_med,
		        losigma * sky_sigma)
		if (IS_INDEFR(hisigma))
		    hicut = min (MAX_REAL, dmax)
		else
	            hicut = sky_med + min (sky_med - dmin, dmax - sky_med,
		        hisigma * sky_sigma)
	    } else {
		if (IS_INDEFR(losigma))
		    locut = max (-MAX_REAL, dmin)
		else
	            locut = sky_mode - losigma * sky_sigma
		if (IS_INDEFR(hisigma))
		    hicut = min (MAX_REAL, dmax)
		else
	            hicut = sky_mode + hisigma * sky_sigma
	    }

	    # Perform lower bound pixel rejection.
	    for (il = ilo; il <= nskypix; il = il + 1) {
		if (skypix[index[il]] >= locut)
		    break
	    }

	    # Perform upper bound pixel rejection.
	    for (ih = ihi; ih >= 1; ih = ih - 1) {
		if (skypix[index[ih]] <= hicut)
		    break
	    }
	    if (il == ilo && ih == ihi)
		break

	    # Compute number of rejected pixels with optional region growing.
	    if (rgrow > 0.0) {

		# Reject lower bound pixels with region growing.
	        do j = ilo, il - 1 
		    nsky_reject = nsky_reject + xp_grow_regions (skypix, coords,
		        wgt, nskypix, sky_zero, index[j], snx, sny, rgrow,
			sumpx, sumsqpx, sumcbpx)

		# Reject upper bound pixels with region growing.
		do j = ih + 1, ihi
		    nsky_reject = nsky_reject + xp_grow_regions (skypix, coords,
		        wgt, nskypix, sky_zero, index[j], snx, sny, rgrow,
			sumpx, sumsqpx, sumcbpx)

		# Compute the new median.
		nsky = nskypix - nsky_reject
		med = xp_imed (wgt, index, il, ihi, (nsky + 1) / 2)

	    } else {

		# Recompute the number of sky pixels, number of rejected
		# pixels and the median.
		nsky_reject = nsky_reject + (il - ilo) + (ihi - ih)
	        nsky = nskypix - nsky_reject
		med = (ih + il) / 2

		# Reject number of lower bound pixels.
		do j = ilo, il - 1 {
		    dsky = skypix[index[j]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		}

		# Reject number of upper bound pixels.
		do j = ih + 1, ihi {
		    dsky = skypix[index[j]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		}
	    }
	    if (nsky <= 0)
		break

	    # Recompute mean, median, mode, sigma and skew.
	    medcut = nint (MEDCUT * real (nsky))
	    sky_med = xp_wsmed (skypix, index, wgt, nskypix, med, medcut)
	    sky_med = max (dmin, min (sky_med, dmax))
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero,
	        sky_mean, sky_sigma, sky_skew)
	    sky_mean = max (dmin, min (sky_mean, dmax))
	    if (sky_mean < sky_med)
		sky_mode = sky_mean
	    else
	        sky_mode = 3.0 * sky_med - 2.0 * sky_mean
	    sky_mode = max (dmin, min (sky_mode, dmax))
	    if (sky_sigma <= 0.0)
		break
	    ilo = il
	    ihi = ih
	}

	# Return an appropriate error code.
	if (nsky == 0 || nsky_reject == nskypix) {
	    nsky = 0
	    nsky_reject = nskypix
	    sky_mode = INDEFR
	    sky_sigma = INDEFR
	    sky_skew = INDEFR
	    return (XP_SKY_TOOSMALL)
	} else
	    return (XP_OK)
end


# XP_GROW_REGIONS -- Perform region growing around a rejected pixel.

int procedure xp_grow_regions (skypix, coords, wgt, nskypix, sky_zero,
	index, snx, sny, rgrow, sumpx, sumsqpx, sumcbpx)

real	skypix[ARB]		#I the sky pixels array
int	coords[ARB]		#I the sky cordinates array
real	wgt[ARB]		#I the weights array
int	nskypix			#I the total number of sky pixels
real	sky_zero		#I the sky zero point
int	index			#I the index of the pixel to be rejected
int	snx, sny		#I the size of the sky subraster
real	rgrow			#I the region growing radius
double	sumpx			#U the sum of the sky pixels
double	sumsqpx			#U the sum of the squares of the sky pixels
double	sumcbpx			#U the sum of the cubes of the sky pixels

double	dsky
int	j, k, ixc, iyc, xmin, xmax, ymin, ymax, cstart, c, nreject
real	rgrow2, r2, d

begin
	# Find the center of the region to be rejected.
	ixc = mod (coords[index], snx)
	if (ixc == 0)
	    ixc = snx
	iyc = (coords[index] - ixc) / snx + 1

	# Define the region to be rejected.
	rgrow2 = rgrow ** 2
	ymin = max (1, int (iyc - rgrow)) 
	ymax = min (sny, int (iyc + rgrow))
	xmin = max (1, int (ixc - rgrow))
	xmax = min (snx, int (ixc + rgrow)) 
	if (ymin <= iyc)
	    cstart = min (nskypix, max (1, index - int (rgrow) + snx *
	    (ymin - iyc)))
	else
	    cstart = index

	# Reject the pixels.
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
		    dsky = skypix[cstart] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		    nreject = nreject + 1
		    wgt[cstart] = 0.0
		}
	    }
	}

	return (nreject)
end
