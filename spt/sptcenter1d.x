# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<math/iminterp.h>

# Type of features for one dimensional centering.

define	CTYPES		"|center1d|gaussian|parabola|peak|none|"
define	CENTER1D	1		# Center1D algorithm
define	GAUSSIAN	2		# Gaussian fit
define	PARABOLA	3		# Parabola
define	PEAK		4		# Peak
define	NONE		5		# Return input center

define	FTYPES		"|either|emission|absorption|"
define	EITHER		1		# Either emission or absorption
define	EMISSION	2		# Emission feature (center1d)
define	ABSORPTION	3		# Absorption feature (center1d)

define	MIN_WIDTH	3.		# Minimum centering width
define	EPSILON		0.001		# Accuracy of centering
define	EPSILON1	0.005		# Tolerance for convergence check
define	ITERATIONS	100		# Maximum number of iterations
define	MAX_DXCHECK	3		# Look back for failed convergence
define	INTERPTYPE	II_SPLINE3	# Image interpolation type


# From deblending routines:

# Profile types.
define  GAUSS           1       # Gaussian profile
define  LORENTZ         2       # Lorentzian profile
define  VOIGT           3       # Voigt profile

# Elements of fit array.
define  BKG             1       # Background
define  POS             2       # Position
define  INT             3       # Intensity
define  GAU             4       # Gaussian FWHM
define  LOR             5       # Lorentzian FWHM

# Type of constraints.
define  FIXED           1       # Fixed parameter
define  SINGLE          2       # Fit a single value for all lines
define  INDEP           3       # Fit independent values for all lines



# SPT_CENTER1D -- Locate the center of a one dimensional feature.
# A value of INDEF is returned in the centering fails for any reason.
# This procedure just sets up the data and adjusts for emission or
# absorption features.  The actual centering is done by C1D_CENTER.
# If twidth <= 1 return the nearest minima or maxima.

real procedure spt_center1d (x, data, npts, ctype, ptype,
	width, radius, threshold)

real	x				# Initial guess
int	npts				# Number of data points
real	data[npts]			# Data points
char	ctype[ARB]			# Centering type
char	ptype[ARB]			# Profile type
real	width				# Feature width
real	radius				# Centering radius
real	threshold			# Minimum range in feature

real	xc				# Center

char	junk[1]
int	i, j, x1, x2, nx, ct, pt
real	a, b, c, rad, wid
pointer	sp, data1

int	strdic()
real	spt_c1d_center(), spt_gcenter(), spt_pcenter()

begin
	# Check starting value.
	if (IS_INDEF(x) || (x < 1) || (x > npts))
	    return (INDEF)

	ct = strdic (ctype, junk, 1, CTYPES)
	pt = strdic (ptype, junk, 1, FTYPES)
	if (ct == 0 || pt == 0)
	    return (INDEF)

	# Set minimum width and error radius.  The minimum in the error radius
	# is for defining the data window.  The user error radius is used to
	# check for an error in the derived center at the end of the centering.

	wid = max (width, MIN_WIDTH)
	rad = max (2., radius)

	# Determine the pixel value range around the initial center, including
	# the width and error radius buffer.  Check for a minimum range.

	x1 = max (1., x - wid / 2 - rad - wid)
	x2 = min (real (npts), x + wid / 2 + rad + wid + 1)
	nx = x2 - x1 + 1
	call alimr (data[x1], nx, a, b)
	if (b - a < threshold)
	    return (INDEF)

	# Allocate memory for the continuum subtracted data vector.  The X
	# range is just large enough to include the error radius and the
	# half width.

	x1 = max (1., x - wid / 2 - rad)
	x2 = min (real (npts), x + wid / 2 + rad + 1)
	nx = x2 - x1 + 1

	call smark (sp)
	call salloc (data1, nx, TY_REAL)

	# Make the centering data positive, subtract the continuum, and
	# apply a threshold to eliminate noise spikes.

	switch (pt) {
	case EMISSION:
	    if (ct == 0)
		a = min (0., a)
	    call asubkr (data[x1], a + threshold, Memr[data1], nx)
	    call amaxkr (Memr[data1], 0., Memr[data1], nx)
	case ABSORPTION:
	    call anegr (data[x1], Memr[data1], nx)
	    call asubkr (Memr[data1], threshold - b, Memr[data1], nx)
	    call amaxkr (Memr[data1], 0., Memr[data1], nx)
	default:
	    c = data[x1+nx/2]
	    if (b - c < c - a) {
		call asubkr (data[x1], a + threshold, Memr[data1], nx)
		call amaxkr (Memr[data1], 0., Memr[data1], nx)
	    } else {
		call anegr (data[x1], Memr[data1], nx)
		call asubkr (Memr[data1], threshold - b, Memr[data1], nx)
		call amaxkr (Memr[data1], 0., Memr[data1], nx)
	    }
	}

	# Determine the center.
	switch (ct) {
	case CENTER1D:
	    xc = spt_c1d_center (real(x-x1+1), Memr[data1], nx, width)
	case GAUSSIAN:
	    j = 1
	    do i = 1, nx
		if (Memr[data1+j-1] < Memr[data1+i-1])
		    j = i
	    xc = spt_gcenter (real(j), Memr[data1], nx)
	case PARABOLA:
	    j = 1
	    do i = 1, nx
		if (Memr[data1+j-1] < Memr[data1+i-1])
		    j = i
	    xc = spt_pcenter (real(j), Memr[data1], nx)
	case PEAK:
	    j = 1
	    do i = 1, nx
		if (Memr[data1+j-1] < Memr[data1+i-1])
		    j = i
	    xc = j
	case NONE:
	    xc = x - x1 + 1
	}

	# Check user centering error radius.
	if (!IS_INDEF(xc)) {
	    xc = xc + x1 - 1
	    if (abs (x - xc) > radius)
		xc = INDEF
	}

	# Free memory and return the center position.
	call sfree (sp)
	return (xc)
end


# SPT_C1D_CENTER -- One dimensional centering algorithm.
# If the width is <= 1. return the nearest local maximum.

real procedure spt_c1d_center (x, data, npts, width)

real	x				# Starting guess
int	npts				# Number of points in data vector
real	data[npts]			# Data vector
real	width				# Centering width

int	i, j, iteration, dxcheck
real	xc, wid, hwidth, dx, dxabs, dxlast
real	a, b, sum1, sum2, intgrl1, intgrl2
pointer	asi1, asi2, sp, data1

real	asigrl()

define	done_	99

begin
	# Find the nearest local maxima as the starting point.
	# This is required because the threshold limit may have set
	# large regions of the data to zero and without a gradient
	# the centering will fail.

	i = x
	for (i=x+.5; (i<npts) && (data[i]<=data[i+1]); i=i+1)
	    ;
	for (j=x+.5; (j>1) && (data[j]<=data[j-1]); j=j-1)
	    ;

	if (i-x < x-j)
	    xc = i 
	else
	    xc = j

	if (width <= 1.)
	    return (xc)

	wid = max (width, MIN_WIDTH)

	# Check data range.
	hwidth = wid / 2
	if ((xc - hwidth < 1) || (xc + hwidth > npts))
	    return (INDEF)

	# Set interpolation functions.
	call asiinit (asi1, INTERPTYPE)
	call asiinit (asi2, INTERPTYPE)
	call asifit (asi1, data, npts)

	# Allocate, compute, and interpolate the x*y values.
	call smark (sp)
	call salloc (data1, npts, TY_REAL)
	do i = 1, npts
	    Memr[data1+i-1] = data[i] * i
	call asifit (asi2, Memr[data1], npts)
	call sfree (sp)

	# Iterate to find center.  This loop exits when 1) the maximum
	# number of iterations is reached, 2) the delta is less than
	# the required accuracy (criterion for finding a center), 3)
	# there is a problem in the computation, 4) successive steps
	# continue to exceed the minimum delta.

	dxlast = npts
	do iteration = 1, ITERATIONS {
	    # Ramp centering function.
	    # a = xc - hwidth
	    # b = xc + hwidth
	    # intgrl1 = asigrl (asi1, a, b)
	    # intgrl2 = asigrl (asi2, a, b)
	    # sum1 = intgrl2 - xc * intgrl1
	    # sum2 = intgrl1

	    # Triangle centering function.
	    a = xc - hwidth
	    b = xc - hwidth / 2
	    intgrl1 = asigrl (asi1, a, b)
	    intgrl2 = asigrl (asi2, a, b)
	    sum1 = (xc - hwidth) * intgrl1 - intgrl2
	    sum2 = -intgrl1
	    a = b
	    b = xc + hwidth / 2
	    intgrl1 = asigrl (asi1, a, b)
	    intgrl2 = asigrl (asi2, a, b)
	    sum1 = sum1 - xc * intgrl1 + intgrl2
	    sum2 = sum2 + intgrl1
	    a = b
	    b = xc + hwidth
	    intgrl1 = asigrl (asi1, a, b)
	    intgrl2 = asigrl (asi2, a, b)
	    sum1 = sum1 + (xc + hwidth) * intgrl1 - intgrl2
	    sum2 = sum2 - intgrl1

	    # Return no center if sum2 is zero.
	    if (sum2 == 0.)
		break

	    # Limit dx change in one iteration to 1 pixel.
	    dx = sum1 / abs (sum2)
	    dxabs = abs (dx)
	    xc = xc + max (-1., min (1., dx))

	    # Check data range.  Return no center if at edge of data.
	    if ((xc - hwidth < 1) || (xc + hwidth > npts))
		break

	    # Convergence tests.
	    if (dxabs < EPSILON)
		goto done_
	    if (dxabs > dxlast + EPSILON1) {
		dxcheck = dxcheck + 1
		if (dxcheck > MAX_DXCHECK)
		    break
	    } else if (dxabs > dxlast - EPSILON1) {
		xc = xc - max (-1., min (1., dx)) / 2
		dxcheck = 0
	    } else {
		dxcheck = 0
	        dxlast = dxabs
	    }
	}

	# If we get here then no center was found.
	xc = INDEF

done_	call asifree (asi1)
	call asifree (asi2)
	return (xc)
end


# SPT_GCENTER -- Center from gaussian fit.

real procedure spt_gcenter (xc, data, npts)

real	xc				# Starting guess
int	npts				# Number of points in data vector
real	data[npts]			# Data vector

int	i, ng, fit[5]
real	scale, ag, bg, xp, yp, gp, chisq
pointer	sp, x, y, s

begin
	if (npts < 3) {
	    call eprintf ("At least 3 points are required.\n")
	    return (INDEF)
	}

	call smark (sp)
	call salloc (x, npts, TY_REAL)
	call salloc (y, npts, TY_REAL)
	call salloc (s, npts, TY_REAL)

	# Scale the data.
	scale = 0.
	do i = 1, npts {
	    Memr[x+i-1] = i
	    Memr[y+i-1] = data[i]
	    Memr[s+i-1] = 1
	    scale = max (scale, abs (data[i]))
	}
	call adivkr (Memr[y], scale, Memr[y], npts)

	# Set initial estimates and do fit.
	ng = 1
	bg = (Memr[y+npts-1] - Memr[y]) / (npts - 1)
	ag = Memr[y] - bg
	xp = xc
	yp = Memr[y+nint(xc)-1] - ag - bg * xp
	gp = npts / 4.

	fit[POS] = SINGLE
	fit[INT] = SINGLE
	fit[GAU] = SINGLE
	fit[LOR] = FIXED
	if (npts < 10)
	    fit[BKG] = FIXED
	else
	    fit[BKG] = SINGLE

	iferr (call dofit (fit, Memr[x], Memr[y],
	    Memr[s], npts, 1., 3, ag, bg, xp, yp, gp, 0., GAUSS, 1, chisq))
	    xp = INDEF

	call sfree (sp)
	return (xp)
end


# SPT_PCENTER -- Center from parabola fit.

real procedure spt_pcenter (xc, data, npts)

real	xc				# Starting guess
real	data[npts]			# Data vector
int	npts				# Number of points in data vector

real    x1, x2, x3, y1, y2, y3, x12, x13, x23, x212, x213, x223, y12, y13, y23
real	a, b, c

begin
	if (npts < 3) {
	    call eprintf ("At least 3 points are required.\n")
	    return (INDEF)
	}

	if (nint(xc) == 1 || nint(xc) == npts)
	    return (INDEF)

	x1 = xc
	x2 = xc - 1
	x3 = xc + 1
	y1 = data[nint(x1)]
	y2 = data[nint(x2)]
	y3 = data[nint(x3)]
        x12 = x1 - x2
        x13 = x1 - x3
        x23 = x2 - x3
        x212 = x1 * x1 - x2 * x2
        x213 = x1 * x1 - x3 * x3
        x223 = x2 * x2 - x3 * x3
        y12 = y1 - y2
        y13 = y1 - y3
        y23 = y2 - y3
        c = (y13 - y23 * x13 / x23) / (x213 - x223 * x13 / x23)
        b = (y23 - c * x223) / x23
        a = y3 - b * x3 - c * x3 * x3
	if (c == 0.)
	    return (INDEF)
	else
            return (-b / (2 * c))
end
