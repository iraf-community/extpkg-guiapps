# XP_MOMENTS -- Compute the first three moments of a distribution given
# the appropriate sums.

procedure xp_moments (sumpx, sumsqpx, sumcbpx, npix, sky_zero, mean,
	sigma, skew)

double	sumpx		#I the sum of the pixels
double	sumsqpx		#I the sum of pixels squared
double	sumcbpx		#I the sum of the pixels cubed
int	npix		#I the number of pixels
real	sky_zero	#I the zero point for moment analysis
real	mean		#O the mean of pixels
real	sigma		#O the sigma of pixels
real	skew		#O the  skew of pixels

double	dmean, dsigma, dskew

begin
	# Recompute the moments.
	dmean = sumpx / npix
	dsigma = sumsqpx / npix - dmean ** 2
	if (dsigma <= 0.0d0) {
	    sigma = 0.0
	    skew = 0.0
	} else {
	    dskew = sumcbpx / npix - 3.0d0 * dmean * dsigma - dmean ** 3
	    sigma = sqrt (dsigma)
	    if (dskew < 0.0d0)
	        skew = - (abs (dskew) ** (1.0d0 / 3.0d0))
	    else if (dskew > 0.0d0)
	        skew = dskew ** (1.0d0 / 3.0d0)
	    else
		skew = 0.0
	}
	mean = sky_zero + dmean
end


# XP_FMOMENTS -- Compute the first three moments of a distribution given the
# data. The sums are returned as well.

procedure xp_fmoments (pix, npix, sky_zero, sumpx, sumsqpx, sumcbpx,
	mean, sigma, skew)

real	pix[npix]	#I the  array of pixels
int	npix		#I the  number of pixels
real	sky_zero	#I the sky zero point for moment analysis
double	sumpx		#O the sum of the pixels
double	sumsqpx		#O the sum of the pixels squared
double	sumcbpx		#O the sum of the pixels cubed
real	mean		#O the mean of pixels
real	sigma		#O the sigma of pixels
real	skew		#O the skew of pixels

double	dpix, dmean, dsigma, dskew
int	i

begin
	# Zero and accumulate the sums.
	sumpx = 0.0d0
	sumsqpx = 0.0d0
	sumcbpx = 0.0d0
	do i = 1, npix {
	    dpix = pix[i] - sky_zero
	    sumpx = sumpx + dpix
	    sumsqpx = sumsqpx + dpix * dpix
	    sumcbpx = sumcbpx + dpix * dpix * dpix
	}

	# Compute the moments.
	dmean = sumpx / npix
	dsigma = sumsqpx / npix - dmean ** 2
	if (dsigma <= 0.0d0) {
	    sigma = 0.0
	    skew = 0.0
	} else {
	    dskew = sumcbpx / npix - 3.0d0 * dmean * dsigma - dmean ** 3
	    sigma = sqrt (dsigma)
	    if (dskew < 0.0d0)
	        skew = - (abs (dskew) ** (1.0d0 / 3.0d0))
	    else if (dskew > 0.0d0)
	        skew = dskew ** (1.0d0 / 3.0d0)
	    else
		skew = 0.0
	}
	mean = sky_zero + dmean
end


# XP_FIMOMENTS -- Procedure to compute the first three moments of a distribution
# given the data and an index array. The sums are returned as well.

procedure xp_fimoments (pix, index, npix, sky_zero, sumpx, sumsqpx,
	sumcbpx, mean, sigma, skew)

real	pix[ARB]	#I the array of pixels
int	index[ARB]	#I the index array
int	npix		#I the number of pixels
real	sky_zero	#I the zero point for moment analysis
double	sumpx		#O the sum of the pixels
double	sumsqpx		#O the  sum of pixels squared
double	sumcbpx		#O the sum of the pixels cubed
real	mean		#O the mean of the pixels
real	sigma		#O the sigma of the pixels
real	skew		#O the skew of the pixels

double	dpix, dmean, dsigma, dskew
int	i

begin
	# Zero and accumulate the sums.
	sumpx = 0.0d0
	sumsqpx = 0.0d0
	sumcbpx = 0.0d0
	do i = 1, npix {
	    dpix = pix[index[i]] - sky_zero
	    sumpx = sumpx + dpix
	    sumsqpx = sumsqpx + dpix * dpix
	    sumcbpx = sumcbpx + dpix * dpix * dpix
	}

	# Compute the moments.
	dmean = sumpx / npix
	dsigma = sumsqpx / npix - dmean ** 2
	if (dsigma <= 0.0d0) {
	    sigma = 0.0
	    skew = 0.0
	} else {
	    dskew = sumcbpx / npix - 3.0d0 * dmean * dsigma - dmean ** 3
	    sigma = sqrt (dsigma)
	    if (dskew < 0.0d0)
	        skew = - (abs (dskew) ** (1.0d0 / 3.0d0))
	    else if (dskew > 0.0d0)
	        skew = dskew ** (1.0d0 / 3.0d0)
	    else
		skew = 0.0
	}
	mean = sky_zero + dmean
end
