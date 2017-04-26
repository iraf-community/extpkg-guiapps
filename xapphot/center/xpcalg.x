include <mach.h>
include <math.h>
include <math/nlfit.h>
include "../lib/center.h"


define	TOL	0.001		# tolerance for fitting algorithms


# XP_CTR1D -- Compute the center from the 1D marginal distributions.

int procedure xp_ctr1d (ctrpix, nx, ny, norm,  xc, yc, xerr, yerr)

real	ctrpix[nx, ny]		#I the input object subarray
int	nx, ny			#I the dimensions of the subarray
real	norm			#I the normalization factor
real	xc, yc			#O the  computed x and y centers
real	xerr, yerr		#O the estimated x and y centering errors

pointer	sp, xm, ym

begin
	call smark (sp)
	call salloc (xm, nx, TY_REAL)
	call salloc (ym, ny, TY_REAL)

	# Compute the marginal distributions.
	call xp_mkmarg (ctrpix, Memr[xm], Memr[ym], nx, ny)
	call adivkr (Memr[xm], real (ny), Memr[xm], nx)
	call adivkr (Memr[ym], real (nx), Memr[ym], ny)

	# Get the centers and errors.
	call xp_cmarg (Memr[xm], nx, norm, xc, xerr)
	call xp_cmarg (Memr[ym], ny, norm, yc, yerr)

	call sfree (sp)
	return (XP_OK)
end


# XP_MCTR1D -- Compute the center from the 1D marginal distributions using
# mean threshold of the marginal distributions.

int procedure xp_mctr1d (ctrpix, nx, ny, norm, xc, yc, xerr, yerr)

real	ctrpix[nx,ny]		#I the input  object subarry
int	nx, ny			#I the dimensions of subarray
real	norm			#I the normalization factor
real	xc, yc			#O the computed x and y centers
real	xerr, yerr		#O the estimated x and y centering errors

pointer	sp, xm, ym

begin
	call smark (sp)
	call salloc (xm, nx, TY_REAL)
	call salloc (ym, ny, TY_REAL)

	# Compute the marginal distributions.
	call xp_mkmarg (ctrpix, Memr[xm], Memr[ym], nx, ny)
	call adivkr (Memr[xm], real (ny), Memr[xm], nx)
	call adivkr (Memr[ym], real (nx), Memr[ym], ny)

	# Get the centers and errors.
	call xp_cmmarg (Memr[xm], nx, norm, xc, xerr)
	call xp_cmmarg (Memr[ym], ny, norm, yc, yerr)

	call sfree (sp)
	return (XP_OK)
end


# XP_CMMARG -- Compute the center and estimate its error given the
# marginal distribution and the number of points.

procedure xp_cmmarg (a, npts, norm, xc, err)

real	a[npts]		#I the input 1D array
int	npts		#I the number of points
real	norm		#I the normalization factor
real	xc		#O the output center value
real	err		#O the output error estimate

int	i
real	sumi, sumix, sumix2, mean, val
bool	fp_equalr()
real	asumr()

begin
	# Initialize.
	mean = asumr (a, npts) / npts
	sumi = 0.0
	sumix = 0.0
	sumix2 = 0.0

	# Accumulate the sums.
	do i = 1, npts {
	    val = (a[i] - mean)
	    if (val > 0.0) {
	        sumi = sumi + val
	        sumix = sumix + val * i
	        sumix2 = sumix2 + val * i ** 2
	    }
	}

	# Compute the position and the error.
	if (fp_equalr (sumi, 0.0)) {
	    xc =  (1.0 + npts) / 2.0
	    err = INDEFR
	} else {
	    xc = sumix / sumi
	    err = (sumix2 / sumi - xc ** 2)
	    if (err <= 0.0) {
		err = 0.0
	    } else {
	        err = sqrt (err / (sumi * norm))
		if (err > real (npts))
		    err = INDEFR
	    }
	}
end


# XP_CMARG -- Compute the center and estimate its error given the
# marginal distribution and the number of points.

procedure xp_cmarg (a, npts, norm, xc, err)

real	a[npts]		#I the input 1D array
int	npts		#I the number of points
real	norm		#I the normalization factor
real	xc		#I the output center value
real	err		#I the output error estimate

int	i
real	sumi, sumix, sumix2
bool	fp_equalr()

begin
	# Initialize.
	sumi = 0.0
	sumix = 0.0
	sumix2 = 0.0

	# Accumulate the sums.
	do i = 1, npts {
	    sumi = sumi + a[i]
	    sumix = sumix + a[i] * i
	    sumix2 = sumix2 + a[i] * i ** 2
	}

	# Compute the position and the error.
	if (fp_equalr (sumi, 0.0)) {
	    xc =  (1.0 + npts) / 2.0
	    err = INDEFR
	} else {
	    xc = sumix / sumi
	    err = (sumix2 / sumi - xc ** 2)
	    if (err <= 0.0) {
		err = 0.0
	    } else {
	        err = sqrt (err / (sumi * norm))
		if (err > real (npts))
		    err = INDEFR
	    }
	}
end


# XP_MKMARG -- Accumulate the marginal distributions.

procedure xp_mkmarg (ctrpix, xm, ym, nx, ny)

real	ctrpix[nx, ny]		#I the input object subarray
real	xm[nx]			#O the output x marginal distribution
real	ym[ny]			#O the output y marginal distribution
int	nx, ny			#I the dimensions of the input subarray

int	i, j
real	sum

begin
	# Compute the x marginal.
	do i = 1, nx {
	    sum = 0.0
	    do j = 1, ny
		sum = sum + ctrpix[i,j]
	    xm[i] = sum
	}

	# Compute the y marginal.
	do j = 1, ny {
	    sum = 0.0
	    do i = 1, nx
		sum = sum + ctrpix[i,j]
	    ym[j] = sum
	}
end


define	NPARS	4		# the total number of parameters
define	NAPARS	3		# the total number of active parameters

# XP_GCTR1D -- Procedure to compute the x and y centers from the 1D marginal
# distributions using 1D Gaussian fits. Three parameters are fit for each
# marginal, the amplitude, the center of the Gaussian function itself
# and a constant background value. The sigma is set by the user and is
# assumed to be fixed.

int procedure xp_gctr1d (ctrpix, nx, ny, sigma, maxiter, xc, yc, xerr, yerr)

real	ctrpix[nx, ny]		#I the input object subarray
int	nx, ny			#I the dimensions of data subarray
real	sigma			#I the  sigma of PSF
int	maxiter			#I the  maximum number of iterations
real	xc, yc			#O the computed x and y centers
real	xerr, yerr		#O the estimated x and y centering error

extern	cgauss1d, cdgauss1d
int	i, minel, maxel, xier, yier, npar, npts
pointer	sp, x, xm, ym, w, fit, list, nl
real	chisqr, variance, p[NPARS], dp[NPARS]
int	locpr()

begin
	# Check the number of points.
	if (nx < NAPARS || ny < NAPARS)
	    return (XP_CTR_TOOSMALL)
	npts = max (nx, ny)

	# Allocate working space.
	call smark (sp)
	call salloc (list, NAPARS, TY_INT)
	call salloc (xm, nx, TY_REAL)
	call salloc (ym, ny, TY_REAL)
	call salloc (x, npts, TY_REAL)
	call salloc (w, npts, TY_REAL)
	call salloc (fit, npts, TY_REAL)

	# Compute the marginal distributions.
	do i = 1, npts
	    Memr[x+i-1] = i
	call xp_mkmarg (ctrpix, Memr[xm], Memr[ym], nx, ny)
	call adivkr (Memr[xm], real (nx), Memr[xm], nx)
	call adivkr (Memr[ym], real (ny), Memr[ym], ny)

	# Specify which parameters are to be fit.
	Memi[list] = 1
	Memi[list+1] = 2
	Memi[list+2] = 4

	# Initialize the x fit parameters.
	call xp_alimr (Memr[xm], nx, p[4], p[1], minel, maxel)
	p[1] = p[1] - p[4]
	p[2] = maxel
	p[3] = sigma ** 2

	# Compute the x center and error.
	call nlinitr (nl, locpr (cgauss1d), locpr (cdgauss1d), p, dp, NPARS,
	    Memi[list], NAPARS, TOL, maxiter)
	call nlfitr (nl, Memr[x], Memr[xm], Memr[w], nx, 1, WTS_UNIFORM, xier)
	call nlvectorr (nl, Memr[x], Memr[fit], nx, 1)
	call nlpgetr (nl, p, npar)
	call nlerrorsr (nl, Memr[xm], Memr[fit], Memr[w], nx, variance,
	    chisqr, dp)
	call nlfreer (nl)
	xc = p[2]
	xerr = dp[2] / sqrt (real (nx))

	# Initialize the y fit parameters.
	call xp_alimr (Memr[ym], ny, p[4], p[1], minel, maxel)
	p[1] = p[1] - p[4]
	p[2] = maxel
	p[3] = sigma ** 2

	# Compute the y center and error.
	call nlinitr (nl, locpr (cgauss1d), locpr (cdgauss1d), p, dp, NPARS,
	    Memi[list], NAPARS, TOL, maxiter)
	call nlfitr (nl, Memr[x], Memr[ym], Memr[w], ny, 1, WTS_UNIFORM, yier)
	call nlvectorr (nl, Memr[x], Memr[fit], ny, 1)
	call nlpgetr (nl, p, npar)
	call nlerrorsr (nl, Memr[ym], Memr[fit], Memr[w], ny, variance,
	    chisqr, dp)
	call nlfreer (nl)
	yc = p[2]
	yerr = dp[2] / sqrt (real (ny))

	# Free working space.
	call sfree (sp)

	# Return the appropriate error code.
	if (xier == NO_DEG_FREEDOM || yier == NO_DEG_FREEDOM)
	    return (XP_CTR_TOOSMALL)
	else if (xier == SINGULAR || yier == SINGULAR)
	    return (XP_CTR_SINGULAR)
	else if (xier == NOT_DONE || yier == NOT_DONE)
	    return (XP_CTR_NOCONVERGE)
	else
	    return (XP_OK)
end



# XP_LGCTR1D -- Compute the center from the 1D marginal
# distributions using a simplified version of the optimal filtering
# technique and addopting a Gaussian model for the fit. The method
# is streamlined by replacing the Gaussian with a simple triangle
# following L.Goad.

int procedure xp_lgctr1d (ctrpix, nx, ny, cx, cy, sigma, maxiter, norm,
	skysigma, xc, yc, xerr, yerr)

real	ctrpix[nx, ny]		#I the input object subarray
int	nx, ny			#I the dimensions of the input data
real	cx, cy			#I the starting x and y center 
real	sigma			#I the width of the psf
int	maxiter			#I the maximum number of iterations
real	norm			#I the normlization factor
real	skysigma		#I the  standard deviation of the pixels
real	xc, yc			#O the  computed x and y centers
real	xerr, yerr		#O the estimated x and y centering errors

int	nxiter, nyiter
pointer	sp, xm, ym
real	ratio, constant

int	xp_topt()
real	asumr()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (xm, nx, TY_REAL)
	call salloc (ym, ny, TY_REAL)

	# Compute the marginal distributions.
	call xp_mkmarg (ctrpix, Memr[xm], Memr[ym], nx, ny)
	xerr = asumr (Memr[xm], nx)
	yerr = asumr (Memr[ym], ny)
	call adivkr (Memr[xm], real (nx), Memr[xm], nx)
	call adivkr (Memr[ym], real (ny), Memr[ym], ny)

	# Compute the x center and error.
	xc = cx
	nxiter = xp_topt (Memr[xm], nx, xc, sigma, TOL, maxiter, YES)
	if (xerr <= 0.0)
	    xerr = INDEFR
	else {
	    if (IS_INDEFR(skysigma))
	        constant = 0.0
	    else
	        constant = 4.0 * SQRTOFPI * sigma * skysigma ** 2 
	    ratio = constant / xerr
	    xerr = sigma ** 2 / (xerr * norm)
	    xerr = sqrt (max (xerr, ratio * xerr))
	}

	# Compute the y center and error.
	yc = cy
	nyiter = xp_topt (Memr[ym], ny, yc, sigma, TOL, maxiter, YES)
	if (yerr <= 0.0)
	    yerr = INDEFR
	else {
	    if (IS_INDEFR(skysigma))
	        constant = 0.0
	    else
	        constant = 4.0 * SQRTOFPI * sigma * skysigma ** 2 
	    ratio = constant / (yerr * norm)
	    yerr = sigma ** 2 / yerr
	    yerr = sqrt (max (yerr, ratio * yerr))
	}

	# Return appropriate error code.
	call sfree (sp)
	if (nxiter < 0 || nyiter < 0)
	    return (XP_CTR_SINGULAR)
	else if (nxiter > maxiter || nyiter > maxiter)
	    return (XP_CTR_NOCONVERGE)
	else
	    return (XP_OK)
end
