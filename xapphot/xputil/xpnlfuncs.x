# CGAUSS1D - Compute the value of a 1-D Gaussian function  on a constant
# background.

procedure cgauss1d (x, nvars, p, np, z)

real	x[ARB]		#I variables, x[1] = position coordinate
int	nvars		#I the number of variables, not used
real	p[ARB]		#I p[1]=amplitude p[2]=center p[3]=sigma p[4]=sky
int	np		#I number of parameters, np = 4
real	z		#O function return

real	r2

begin
	r2 = (x[1] - p[2]) ** 2 / (2. * p[3])
	if (abs (r2) > 25.0)
	    z = p[4]
	else
	    z = p[1] * exp (-r2) + p[4]
end


# CDGAUSS1D -- Compute the value a 1-D Gaussian profile on a constant
# background and its derivatives.

procedure cdgauss1d (x, nvars p, dp, np, z, der)

real	x[ARB]		#I variables, x[1] = position coordinate
int	nvars		#I the number of variables, not used
real	p[ARB]		#I p[1]=amplitude, p[2]=center, p[3]=sky p[4]=sigma
real	dp[ARB]		#I parameter derivatives, not used
int	np		#I number of parameters, np=4
real	z		#O function value
real	der[ARB]	#O derivatives

real	dx, r2

begin
	dx = x[1] - p[2]
	r2 = dx * dx / (2.0 * p[3])
	if (abs (r2) > 25.0) {
	    z = p[4]
	    der[1] = 0.0
	    der[2] = 0.0
	    der[3] = 0.0
	    der[4] = 1.0
	} else {
	    der[1] = exp (-r2)
	    z = p[1] * der[1]
	    der[2] = z * dx / p[3]
	    der[3] = z * r2 / p[3]
	    der[4] = 1.0
	    z = z + p[4]
	}
end


# GAUSSKEW - Compute the value of a 1-D skewed Gaussian profile.
# The background value is assumed to be zero.

procedure gausskew (x, nvars, p, np, z)

real	x[ARB]		#I variables, x[1] = position coordinate
int	nvars		#I number of variables, not used
real	p[ARB]		#I p[1]=amplitude p[2]=center p[3]=sigma p[4]=skew
int	np		#I number of parameters, np = 3
real	z		#O function return

real	dx, r2, r3

begin
	dx = (x[1] - p[2])
	r2 = dx ** 2 / (2.0 * p[3])
	r3 = r2 * dx / sqrt (2.0 * abs (p[3])) 
	if (abs (r2) > 25.0)
	    z = 0.0
	else
	    z = (1.0 + p[4] * r3) * p[1] * exp (-r2)
end


# DGAUSSKEW -- Compute the value of a 1-D skewed Gaussian and its derivatives. 
# The background value is assumed to be zero.

procedure dgausskew (x, nvars, p, dp, np, z, der)

real	x[ARB]		#I variables, x[1] = position coordinate
int	nvars		#I number of variables, not used
real	p[ARB]		#I p[1]=amplitude, p[2]=center, p[3]=sigma, p[4]=skew
real	dp[ARB]		#I parameter derivatives, not used
int	np		#I number of parameters, np = 3
real	z		#O function value
real	der[ARB]	#O derivatives

real	dx, d1, d2, d3, r, r2, r3, rint

begin
	dx = x[1] - p[2]
	r2 = dx ** 2 / (2.0 * p[3])
	if (abs (r2) > 25.0) {
	    z = 0.0
	    der[1] = 0.0
	    der[2] = 0.0
	    der[3] = 0.0
	    der[4] = 0.0
	} else {
	    r = dx / sqrt (2.0 * abs (p[3]))
	    r3 = r2 * r
	    d1 = exp (-r2)
	    z = d1 * p[1]
	    d2 = z * dx / p[3]
	    d3 = z * r2 / p[3]
	    rint = 1.0 + p[4] * r3
	    der[1] = d1 * rint
	    der[2] = d2 * (rint - 1.5 * p[4] * r)
	    der[3] = d3 * (rint - 1.5 * p[4] * r)
	    der[4] = z * r3
	    z = z * rint
	}
end
