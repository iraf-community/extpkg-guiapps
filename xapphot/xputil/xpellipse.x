include <math.h>

# XP_ELLIPSE -- Given the semi-major axis, ratio of semi-minor to semi-major
# axes, and position angle, compute the parameters of the equation of
# the ellipse, where the ellipse is defined as A * X ** 2 + B * x * y +
# C * Y ** 2 - F = 0.

procedure xp_ellipse (a, ratio, theta, aa, bb, cc, ff)

real	a			#I the semi-major axis
real	ratio			#I the ratio of semi-minor to semi-major axes
real	theta			#I the position angle of the major axis
real	aa			#O the coefficient of x ** 2
real	bb			#O the coefficient of x * y
real	cc			#O the coefficient of y ** 2
real	ff			#O the constant term

real	cost, sint, costsq, sintsq
real	asq, bsq

begin
	# Get the angles.
	cost = cos (DEGTORAD(theta))
	sint = sin (DEGTORAD(theta))
	costsq = cost ** 2
	sintsq = sint ** 2

	# Compute the parameters of the outer ellipse.
	asq = a ** 2
	bsq = (ratio * a) ** 2
	aa = bsq * costsq + asq * sintsq
	bb = 2.0 * (bsq - asq) * cost * sint
	cc = asq * costsq + bsq * sintsq
	ff = asq * bsq
end
