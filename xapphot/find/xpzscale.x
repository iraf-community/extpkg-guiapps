include	<mach.h>
include	<error.h>
include	<imhdr.h>
include	<ctype.h>
include	"../lib/displaydef.h"


# XP_ZSCALE -- Compute the optimal Z1, Z2 (range of greyscale values to be
# displayed) of an image.  For efficiency a statistical subsample of an image
# is used.  The pixel sample evenly subsamples the image in x and y.  The entire
# image is used if the number of pixels in the image is smaller than the desired
# sample.
#
# The sample is accumulated in a buffer and sorted by greyscale value.
# The median value is the central value of the sorted array.  The slope of a
# straight line fitted to the sorted sample is a measure of the standard
# deviation of the sample about the median value.  Our algorithm is to sort
# the sample and perform an iterative fit of a straight line to the sample,
# using pixel rejection to omit gross deviants near the endpoints.  The fitted
# straight line is the transfer function used to map image Z into display Z.
# If more than half the pixels are rejected the full range is used.  The slope
# of the fitted line is divided by the user-supplied contrast factor and the
# final Z1 and Z2 are computed, taking the origin of the fitted line at the
# median value.

define	MIN_NPIXELS	5		# smallest permissible sample
define	MAX_REJECT	0.5		# max frac. of pixels to be rejected
define	GOOD_PIXEL	0		# use pixel in fit
define	BAD_PIXEL	1		# ignore pixel in all computations
define	REJECT_PIXEL	2		# reject pixel after a bit
define	KREJ		2.5		# k-sigma pixel rejection factor
define	MAX_ITERATIONS	5		# maximum number of fitline iterations


# XP_ZSCALE -- Sample the image and compute Z1 and Z2.

procedure xp_zscale (im, z1, z2, contrast, optimal_sample_size, len_stdline)

pointer	im			#I the image to be sampled
real	z1, z2			#O output min and max greyscale values
real	contrast		#I adj. to slope of transfer function
int	optimal_sample_size	#I desired number of pixels in sample
int	len_stdline		#I optimal number of pixels per line

int	npix, minpix, ngoodpix, center_pixel, ngrow
real	zmin, zmax, median
real	zstart, zslope
pointer	sample, left
int	zsc_sample_image(), zsc_fit_line()

begin
	# Subsample the image.
	npix = zsc_sample_image (im, sample, optimal_sample_size, len_stdline)
	center_pixel = max (1, (npix + 1) / 2)

	# Sort the sample, compute the minimum, maximum, and median pixel
	# values.

	call asrtr (Memr[sample], Memr[sample], npix)
	zmin = Memr[sample]
	zmax = Memr[sample+npix-1]

	# The median value is the average of the two central values if there 
	# are an even number of pixels in the sample.

	left = sample + center_pixel - 1
	if (mod (npix, 2) == 1 || center_pixel >= npix)
	    median = Memr[left]
	else
	    median = (Memr[left] + Memr[left+1]) / 2

	# Fit a line to the sorted sample vector.  If more than half of the
	# pixels in the sample are rejected give up and return the full range.
	# If the user-supplied contrast factor is not 1.0 adjust the scale
	# accordingly and compute Z1 and Z2, the y intercepts at indices 1 and
	# npix.

	minpix = max (MIN_NPIXELS, int (npix * MAX_REJECT))
	ngrow = max (1, nint (npix * .01))
	ngoodpix = zsc_fit_line (Memr[sample], npix, zstart, zslope,
	    KREJ, ngrow, MAX_ITERATIONS)

	if (ngoodpix < minpix) {
	    z1 = zmin
	    z2 = zmax
	} else {
	    if (contrast > 0)
		zslope = zslope / contrast
	    z1 = max (zmin, median - (center_pixel - 1) * zslope)
	    z2 = min (zmax, median + (npix - center_pixel) * zslope)
	}

	call mfree (sample, TY_REAL)
end


# ZSC_SAMPLE_IMAGE -- Extract an evenly gridded subsample of the pixels from
# a two-dimensional image into a one-dimensional vector.

int procedure zsc_sample_image (im, sample, optimal_sample_size, len_stdline)

pointer	im			#I the image to be sampled
pointer	sample			#O the output vector containing the sample
int	optimal_sample_size	#I the desired number of pixels in sample
int	len_stdline		#I the optimal number of pixels per line

int	ncols, nlines, col_step, line_step, maxpix, line
int	opt_npix_per_line, npix_per_line
int	opt_nlines_in_sample, min_nlines_in_sample, max_nlines_in_sample
pointer	op
pointer	imgl2r()

begin
	ncols  = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	# Compute the number of pixels each line will contribute to the sample,
	# and the subsampling step size for a line.  The sampling grid must
	# span the whole line on a uniform grid.

	opt_npix_per_line = max (1, min (ncols, len_stdline))
	col_step = max (1, (ncols + opt_npix_per_line-1) / opt_npix_per_line)
	npix_per_line = max (1, (ncols + col_step-1) / col_step)

	# Compute the number of lines to sample and the spacing between lines.
	# We must ensure that the image is adequately sampled despite its
	# size, hence there is a lower limit on the number of lines in the
	# sample.  We also want to minimize the number of lines accessed when
	# accessing a large image, because each disk seek and read is expensive.
	# The number of lines extracted will be roughly the sample size divided
	# by len_stdline, possibly more if the lines are very short.

	min_nlines_in_sample = max (1, optimal_sample_size / len_stdline)
	opt_nlines_in_sample = max(min_nlines_in_sample, min(nlines,
	    (optimal_sample_size + npix_per_line-1) / npix_per_line))
	line_step = max (1, nlines / (opt_nlines_in_sample))
	max_nlines_in_sample = (nlines + line_step-1) / line_step

	# Allocate space for the output vector.  Buffer must be freed by our
	# caller.

	maxpix = npix_per_line * max_nlines_in_sample
	call malloc (sample, maxpix, TY_REAL)

	# Extract the vector.
	op = sample
	do line = (line_step + 1) / 2, nlines, line_step {
	    call zsc_subsample (Memr[imgl2r(im,line)], Memr[op],
		npix_per_line, col_step)
	    op = op + npix_per_line
	    if (op - sample + npix_per_line > maxpix)
		break
	}

	return (op - sample)
end


# ZSC_SUBSAMPLE -- Subsample an image line.  Extract the first pixel and
# every "step"th pixel thereafter for a total of npix pixels.

procedure zsc_subsample (a, b, npix, step)

real	a[ARB]			#I the input array
real	b[npix]			#O the output array
int	npix			#I the number of pixels
int	step			#I the step size

int	ip, i

begin
	if (step <= 1)
	    call amovr (a, b, npix)
	else {
	    ip = 1
	    do i = 1, npix {
		b[i] = a[ip]
		ip = ip + step
	    }
	}
end


# ZSC_FIT_LINE -- Fit a straight line to a data array of type real.  This is
# an iterative fitting algorithm, wherein points further than ksigma from the
# current fit are excluded from the next fit.  Convergence occurs when the
# next iteration does not decrease the number of pixels in the fit, or when
# there are no pixels left.  The number of pixels left after pixel rejection
# is returned as the function value.

int procedure zsc_fit_line (data, npix, zstart, zslope, krej, ngrow, maxiter)

real	data[npix]		#I the data to be fitted
int	npix			#I the number of pixels before rejection
real	zstart			#O the Z-value of pixel data[1]	(output)
real	zslope			#O the dz/pixel			(output)
real	krej			#I the k-sigma pixel rejection factor
int	ngrow			#I the number of pixels of growing
int	maxiter			#I the maximum number of iterations

int	i, ngoodpix, last_ngoodpix, minpix, niter
real	xscale, z0, dz, x, z, mean, sigma, threshold
double	sumxsqr, sumxz, sumz, sumx, rowrat
pointer	sp, flat, badpix, normx
int	zsc_reject_pixels(), zsc_compute_sigma()

begin
	if (npix <= 0)
	    return (0)
	else if (npix == 1) {
	    zstart = data[1]
	    zslope = 0.0
	    return (1)
	} else
	    xscale = 2.0 / (npix - 1)

	# Allocate a buffer for data minus fitted curve, another for the
	# normalized X values, and another to flag rejected pixels.

	call smark (sp)
	call salloc (flat, npix, TY_REAL)
	call salloc (normx, npix, TY_REAL)
	call salloc (badpix, npix, TY_SHORT)
	call aclrs (Mems[badpix], npix)

	# Compute normalized X vector.  The data X values [1:npix] are
	# normalized to the range [-1:1].  This diagonalizes the lsq matrix
	# and reduces its condition number.

	do i = 0, npix - 1
	    Memr[normx+i] = i * xscale - 1.0

	# Fit a line with no pixel rejection.  Accumulate the elements of the
	# matrix and data vector.  The matrix M is diagonal with
	# M[1,1] = sum x**2 and M[2,2] = ngoodpix.  The data vector is
	# DV[1] = sum (data[i] * x[i]) and DV[2] = sum (data[i]).

	sumxsqr = 0
	sumxz = 0
	sumx = 0
	sumz = 0

	do i = 1, npix {
	    x = Memr[normx+i-1]
	    z = data[i]
	    sumxsqr = sumxsqr + (x ** 2)
	    sumxz   = sumxz + z * x
	    sumz    = sumz + z
	}

	# Solve for the coefficients of the fitted line.
	z0 = sumz / npix
	dz = sumxz / sumxsqr

	# Iterate, fitting a new line in each iteration.  Compute the flattened
	# data vector and the sigma of the flat vector.  Compute the lower and
	# upper k-sigma pixel rejection thresholds.  Run down the flat array
	# and detect pixels to be rejected from the fit.  Reject pixels from
	# the fit by subtracting their contributions from the matrix sums and
	# marking the pixel as rejected.

	ngoodpix = npix
	minpix = max (MIN_NPIXELS, int (npix * MAX_REJECT))

	for (niter=1;  niter <= maxiter;  niter=niter+1) {
	    last_ngoodpix = ngoodpix

	    # Subtract the fitted line from the data array.
	    call zsc_flatten_data (data, Memr[flat], Memr[normx], npix, z0, dz)

	    # Compute the k-sigma rejection threshold.  In principle this
	    # could be more efficiently computed using the matrix sums
	    # accumulated when the line was fitted, but there are problems with
	    # numerical stability with that approach.

	    ngoodpix = zsc_compute_sigma (Memr[flat], Mems[badpix], npix,
		mean, sigma)
	    threshold = sigma * krej

	    # Detect and reject pixels further than ksigma from the fitted
	    # line.
	    ngoodpix = zsc_reject_pixels (data, Memr[flat], Memr[normx],
		Mems[badpix], npix, sumxsqr, sumxz, sumx, sumz, threshold,
		ngrow)

	    # Solve for the coefficients of the fitted line.  Note that after
	    # pixel rejection the sum of the X values need no longer be zero.

	    if (ngoodpix > 0) {
		rowrat = sumx / sumxsqr
		z0 = (sumz - rowrat * sumxz) / (ngoodpix - rowrat * sumx)
		dz = (sumxz - z0 * sumx) / sumxsqr
	    }

	    if (ngoodpix >= last_ngoodpix || ngoodpix < minpix)
		break
	}

	# Transform the line coefficients back to the X range [1:npix].
	zstart = z0 - dz
	zslope = dz * xscale

	call sfree (sp)
	return (ngoodpix)
end


# ZSC_FLATTEN_DATA -- Compute and subtract the fitted line from the data array,
# returned the flattened data in FLAT.

procedure zsc_flatten_data (data, flat, x, npix, z0, dz)

real	data[npix]		#I the raw data array
real	flat[npix]		#O the flattened data  (output)
real	x[npix]			#I the x value of each pixel
int	npix			#I the number of pixels
real	z0, dz			#I the  z-intercept, dz/dx of fitted line
int	i

begin
	do i = 1, npix
	    flat[i] = data[i] - (x[i] * dz + z0)
end


# ZSC_COMPUTE_SIGMA -- Compute the root mean square deviation from the
# mean of a flattened array.  Ignore rejected pixels.

int procedure zsc_compute_sigma (a, badpix, npix, mean, sigma)

real	a[npix]			#I the flattened data array
short	badpix[npix]		#I the bad pixel flags (!= 0 if bad pixel)
int	npix			#I the number of pixels
real	mean, sigma		#O the compute mean and sigma

real	pixval
int	i, ngoodpix
double	sum, sumsq, temp

begin
	sum = 0
	sumsq = 0
	ngoodpix = 0

	# Accumulate sum and sum of squares.
	do i = 1, npix
	    if (badpix[i] == GOOD_PIXEL) {
		pixval = a[i]
		ngoodpix = ngoodpix + 1
		sum = sum + pixval
		sumsq = sumsq + pixval ** 2
	    }

	# Compute mean and sigma.
	switch (ngoodpix) {
	case 0:
	    mean = INDEF
	    sigma = INDEF
	case 1:
	    mean = sum
	    sigma = INDEF
	default:
	    mean = sum / ngoodpix
	    temp = sumsq / (ngoodpix - 1) - sum**2 / (ngoodpix * (ngoodpix - 1))
	    if (temp < 0)		# possible with roundoff error
		sigma = 0.0
	    else
		sigma = sqrt (temp)
	}

	return (ngoodpix)
end


# ZSC_REJECT_PIXELS -- Detect and reject pixels more than "threshold" greyscale
# units from the fitted line.  The residuals about the fitted line are given
# by the "flat" array, while the raw data is in "data".  Each time a pixel
# is rejected subtract its contributions from the matrix sums and flag the
# pixel as rejected.  When a pixel is rejected reject its neighbors out to
# a specified radius as well.  This speeds up convergence considerably and
# produces a more stringent rejection criteria which takes advantage of the
# fact that bad pixels tend to be clumped.  The number of pixels left in the
# fit is returned as the function value.

int procedure zsc_reject_pixels (data, flat, normx, badpix, npix,
	 sumxsqr, sumxz, sumx, sumz, threshold, ngrow)

real	data[npix]		#I the raw data array
real	flat[npix]		#I the flattened data array
real	normx[npix]		#I the normalized x values of pixels
short	badpix[npix]		#U the  bad pixel flags (!= 0 if bad pixel)
int	npix			#I the number of pixels
double	sumxsqr,sumxz,sumx,sumz	#U the matrix sums
real	threshold		#I the threshold for pixel rejection
int	ngrow			#I the number of pixels of region growing

int	ngoodpix, i, j
real	residual, lcut, hcut
double	x, z

begin
	ngoodpix = npix
	lcut = -threshold
	hcut = threshold

	do i = 1, npix
	    if (badpix[i] == BAD_PIXEL)
		ngoodpix = ngoodpix - 1
	    else {
		residual = flat[i]
		if (residual < lcut || residual > hcut) {
		    # Reject the pixel and its neighbors out to the growing
		    # radius.  We must be careful how we do this to avoid
		    # directional effects.  Do not turn off thresholding on
		    # pixels in the forward direction; mark them for rejection
		    # but do not reject until they have been thresholded.
		    # If this is not done growing will not be symmetric.

		    do j = max(1,i-ngrow), min(npix,i+ngrow) {
			if (badpix[j] != BAD_PIXEL) {
			    if (j <= i) {
				x = normx[j]
				z = data[j]
				sumxsqr = sumxsqr - (x ** 2)
				sumxz = sumxz - z * x
				sumx = sumx - x
				sumz = sumz - z
				badpix[j] = BAD_PIXEL
				ngoodpix = ngoodpix - 1
			    } else
				badpix[j] = REJECT_PIXEL
			}
		    }
		}
	    }

	return (ngoodpix)
end


# XP_IMAXMIN -- Get the minimum and maximum pixel values of an image.  If valid
# header values are available they are used, otherwise the image is sampled
# on an even grid and the min and max values of this sample are returned.

procedure xp_imaxmin (im, zmin, zmax, size_sample, nsample_lines)

pointer	im			#I the pointer to the input image
real	zmin, zmax		#O the min and max intensity values
int	size_sample		#I the sample size
int	nsample_lines		#I the amount of image to sample

int	step, ncols, nlines, imlines, i
real	minval, maxval
pointer	imgl2r()

begin
	# Only calculate minimum, maximum pixel values if the current
	# values are unknown, or if the image was modified since the
	# old values were computed.

	ncols  = IM_LEN(im,1)
	nlines = IM_LEN(im,2)

	if (IM_LIMTIME(im) >= IM_MTIME(im)) {
	    # Use min and max values in image header if they are up to date.
	    zmin = IM_MIN(im)
	    zmax = IM_MAX(im)

	} else {
	    zmin = MAX_REAL
	    zmax = -MAX_REAL

	    # Try to include a constant number of pixels in the sample
	    # regardless of the image size.  The entire image is used if we
	    # have a small image, and at least sample_lines lines are read
	    # if we have a large image.

	    imlines = min(nlines, max(nsample_lines, size_sample / ncols))
	    step = nlines / (imlines + 1)

	    do i = 1 + step, nlines, max (1, step) {
		call alimr (Memr[imgl2r(im,i)], ncols, minval, maxval)
		zmin = min (zmin, minval)
		zmax = max (zmax, maxval)
	    }
	}
end


# XP_ULUTALLOC -- Generates a look up table from data supplied by user.
# The data is read from a two column text file of intensity, greyscale values.
# The input data are sorted, then mapped to the x range [0-4095].  A 
# piecewise linear look up table of 4096 values is then constructed from 
# the (x,y) pairs given.  A pointer to the look up table, as well as the z1 
# and z2 intensity endpoints, is returned.

pointer procedure xp_ulutalloc (fname, z1, z2)

char	fname[ARB]	#I the name of file with intensity, greyscale values
real	z1		#O the intensity mapped to minimum gs value
real	z2		#O the intensity mapped to maximum gs value

int	nvalues, i, j, x1, x2, y1
pointer	lut, sp, x, y
real	delta_gs, delta_xv, slope
errchk	xp_ulutread(), xp_ulutsort(), malloc()		

begin
	call smark (sp)
	call salloc (x, DEF_UMAXPTS, TY_REAL)	
	call salloc (y, DEF_UMAXPTS, TY_REAL)

	# Read intensities and greyscales from the user's input file.  The
	# intensity range is then mapped into a standard range and the 
	# values sorted.

	call xp_ulutread (fname, Memr[x], Memr[y], nvalues)
	call alimr (Memr[x], nvalues, z1, z2)
	call amapr (Memr[x], Memr[x], nvalues, z1, z2, real(DEF_UZ1),
	    real(DEF_UZ2))
	call xp_ulutsort (Memr[x], Memr[y], nvalues)

	# Fill lut in straight line segments - piecewise linear
	call malloc (lut, DEF_UMAXPTS, TY_SHORT)	
	do i = 1, nvalues-1 {
	    delta_gs = Memr[y+i] - Memr[y+i-1]
	    delta_xv = Memr[x+i] - Memr[x+i-1]
	    slope = delta_gs / delta_xv
	    x1 = int (Memr[x+i-1]) 
	    x2 = int (Memr[x+i])
	    y1 = int (Memr[y+i-1])
	    do j = x1, x2
		Mems[lut+j] = y1 + slope * (j-x1)
	}
	Mems[lut+DEF_UMAXPTS-1] = y1 + (slope * DEF_UZ2)

	call sfree (sp)
	return (lut)
end


# XP_ULUTFREE -- Free the lookup table allocated by XP_ULUT.

procedure xp_ulutfree (lut)

pointer	lut			#U pointer to the lookup table

begin
	call mfree (lut, TY_SHORT)
end


# XP_ULUTREAD -- Read text file of x, y, values.

procedure xp_ulutread (utab, x, y, nvalues)

char	utab[ARB]		#I name of list file
real	x[ARB]			#O array of x values, filled on return
real	y[ARB]			#O array of y values, filled on return
int	nvalues			#O number of values in x, y vectors - returned

int	n, fd
pointer	sp, lbuf, ip
real	xval, yval
int	getline(), open()
errchk	open, sscan, getline, salloc

begin
	call smark (sp)
	call salloc (lbuf, SZ_LINE, TY_CHAR)

	iferr (fd = open (utab, READ_ONLY, TEXT_FILE))
	    call error (0, "Error opening user lookup table")

	n = 0
	while (getline (fd, Memc[lbuf]) != EOF) {
	    # Skip comment lines and blank lines.
	    if (Memc[lbuf] == '#')
		next
	    for (ip=lbuf;  IS_WHITE(Memc[ip]);  ip=ip+1)
		;
	    if (Memc[ip] == '\n' || Memc[ip] == EOS)
		next

	    # Decode the points to be plotted.
	    call sscan (Memc[ip])
		call gargr (xval)
		call gargr (yval)

	    n = n + 1
	    if (n > DEF_UMAXPTS)
	        call error (2,
		    "Intensity transformation table cannot exceed 4096 values")

	    x[n] = xval
	    y[n] = yval
	}

	nvalues = n
	call close (fd)
	call sfree (sp)
end


# XP_ULUTSORT -- Bubble sort of paired arrays.  

procedure xp_ulutsort (xvals, yvals, nvals)

real	xvals[ARB]		#U array of x values
real	yvals[ARB]		#U array of y values
int	nvals			#I number of values in each array

int	i, j
real	temp
define	swap	{temp=$1;$1=$2;$2=temp}

begin
	for (i = nvals; i > 1; i = i - 1)
	    for (j = 1;  j < i;  j = j + 1) 
		if (xvals[j] > xvals[j+1]) {
		    swap (xvals[j], xvals[j+1])
		    swap (yvals[j], yvals[j+1])
		}
end
