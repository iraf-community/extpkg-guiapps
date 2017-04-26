include	<mach.h>
include	<math.h>

# XP_TOPT - One-dimensional centering routine using repeated convolutions to
# locate image center.

define	MAX_SEARCH	3	# maximum number of initial search steps

int procedure xp_topt (data, npix, center, sigma, tol, maxiter, ortho)

real	data[ARB]		#I the input data
int	npix			#I the number of pixels
real	center			#U the input/ output value of center
real	sigma			#I the  width of the triangle function 
real	tol			#I the fitting tolerance
int	maxiter			#I maximum number of iterations
int	ortho			#I orthogonalize the weights ?

int	i, iter
pointer	sp, wgt
real	newx, x[3], news, s[3], delx
real	adotr(), xp_qzero()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (wgt, npix, TY_REAL)

	# Initialize.
	x[1] = center
	call mkt_prof_derv (Memr[wgt], npix, x[1], sigma, ortho)
	s[1] = adotr (Memr[wgt], data, npix)
	#if (abs (s[1]) <= EPSILONR) {
	if (abs (s[1]) == 0.0) {
	    center = x[1]
	    call sfree (sp)
	    return (0)
	} else
	    s[3] = s[1]

	# Search for the correct interval.
	for (i = 1; (s[3] * s[1] >= 0.0) && (i <= MAX_SEARCH); i = i + 1) {
	    s[3] = s[1]
	    x[3] = x[1]
	    x[1] = x[3] + sign (sigma, s[3])
	    call mkt_prof_derv (Memr[wgt], npix, x[1], sigma, ortho)
	    s[1] = adotr (Memr[wgt], data, npix)
	    #if (abs (s[1]) <= EPSILONR) {
	    if (abs (s[1]) == 0.0) {
		center = x[1]
		call sfree (sp)
		return (0)
	    }
	}

	# Location not bracketed.
	if (s[3] * s[1] > 0.0) {
	    call sfree (sp)
	    return (-1)
	}

	# Intialize the quadratic search.
	delx = x[1] - x[3]
	x[2] = x[3] - s[3] * delx / (s[1] - s[3])
	call mkt_prof_derv (Memr[wgt], npix, x[2], sigma, ortho)
	s[2] = adotr (Memr[wgt], data, npix)
	#if (abs (s[2]) <= EPSILONR) {
	if (abs (s[2]) == 0.0) {
	    center = x[2]
	    call sfree (sp)
	    return (1)
	}

	# Search quadratically.
	for (iter = 2; iter <= maxiter; iter = iter + 1)  {

	    # Check for completion.
	    #if (abs (s[2]) <= EPSILONR)
	    if (abs (s[2]) == 0.0)
		break
	    if (abs (x[2] - x[1]) <= tol)
		break
	    if (abs (x[3] - x[2]) <= tol)
		break

	    # Compute new intermediate value.
	    newx = x[1] + xp_qzero (x, s)
	    call mkt_prof_derv (Memr[wgt], npix, newx, sigma, ortho)
	    news = adotr (Memr[wgt], data, npix)

	    if (s[1] * s[2] > 0.0) {
		s[1] = s[2]
		x[1] = x[2]
		s[2] = news
		x[2] = newx
	    } else {
		s[3] = s[2]
		x[3] = x[2]
		s[2] = news
		x[2] = newx
	    }
	}

	# Evaluate the center.
	center = x[2]

	# Free space.
	call sfree (sp)

	return (iter)
end


# XP_TPROFDER -- Procedure to estimate the approximating triangle function
# and its derivatives.

procedure xp_tprofder (data, der, npix, center, sigma, ampl)

real	data[ARB]		#O the estimated data values
real	der[ARB]		#O the estimated derivatives
int	npix			#I the number of pixels
real	center			#I the center of input triangle function
real	sigma			#I the sigma of input triangle function
real	ampl			#I the amplitude of input triangle function

int	i
real	x, xabs, width

begin
	width = sigma * 2.35
	do i = 1, npix {
	    x = (i - center) / width
	    xabs = abs (x)
	    if (xabs <= 1.0) {
		data[i] = ampl * (1.0 - xabs)
		der[i] = x * data[i]
	    } else {
		data[i] = 0.0
		der[i] = 0.0
	    }
	}
end


# MKT_PROF_DERV - Make orthogonal profile derivative vector.

procedure mkt_prof_derv (weight, npix, center, sigma, norm)

real	weight[ARB]	#O the output weights
int	npix		#I the number of pixels
real	center		#I the input center
real	sigma		#I the input width of the trangle function
int	norm		#I orthogonalise weights ?

pointer	sp, der
real	coef
real	asumr(),  adotr()

begin
	call smark (sp)
	call salloc (der, npix, TY_REAL)

	# Fetch the weighting function and derivatives.
	call xp_tprofder (Memr[der], weight, npix, center, sigma, 1.0)

	if (norm == YES) {

	    # Make orthogonal to level background.
	    coef = -asumr (weight, npix) / npix
	    call aaddkr (weight, coef, weight, npix)
	    coef = -asumr (Memr[der], npix) / npix
	    call aaddkr (Memr[der], coef, Memr[der], npix)

	    # Make orthogonal to profile vector.
	    coef = adotr (Memr[der], Memr[der], npix)
	    if (coef <= 0.0)
		coef = 1.0
	    else
	        coef = adotr (weight, Memr[der], npix) / coef
	    call amulkr (Memr[der], coef, Memr[der], npix)
	    call asubr (weight, Memr[der], weight, npix)

	    # Normalize the final vector.
	    coef = adotr (weight, weight, npix)
	    if (coef <= 0.0)
		coef = 1.0
	    else
	        coef = sqrt (1.0 / coef)
	    call amulkr (weight, coef, weight, npix)
	}

	call sfree (sp)
end


define	QTOL	.125

# XP_QZERO - Solve for the root of a quadratic function defined by three
# points.

real procedure xp_qzero (x, y)

real	x[3]		#I the input x coordinates
real	y[3]		#I the input y coordinates

real	a, b, c, det, dx
real	x2, x3, y2, y3

begin
	# Compute the determinant.
	x2 = x[2] - x[1]
	x3 = x[3] - x[1]
	y2 = y[2] - y[1]
	y3 = y[3] - y[1]
	det = x2 * x3 * (x2 - x3)

	# Compute the shift in x.
	#if (abs (det) > 100.0 * EPSILONR) {
	if (abs (det) > 0.0) {
	    a = (x3 * y2 - x2 * y3) / det
	    b = - (x3 * x3 * y2 - x2 * x2 * y3) / det
	    c =  a * y[1] / (b * b)
	    if (abs (c) > QTOL)
		dx = (-b / (2.0 * a)) * (1.0 - sqrt (1.0 - 4.0 * c))
	    else
		dx = - (y[1] / b) * (1.0 + c)
	    return (dx)
	#} else if (abs (y3) > EPSILONR)
	} else if (abs (y3) > 0.0)
	    return (-y[1] * x3 / y3)
	else
	    return (0.0)
end
