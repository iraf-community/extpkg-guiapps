include	<error.h>
include	<imhdr.h>
include	<smw.h>

define	DEREDTYPES	"|A(V)|E(B-V)|c|"

# DEREDDEN -- Deredden spectrum

procedure deredden (x, y, z, n, av, rv, avold, rvold)

real	x[n]			# Wavelengths
real	y[n]			# Input fluxes
real	z[n]			# Output fluxes
int	n			# Number of points
real	av, avold		# A(V)
real	rv, rvold		# A(V)/E(B-V)

int	i
real	cor, ccm()
errchk	ccm

begin
	if (avold != 0.) {
	    if (rv != rvold) {
		do i = 1, n {
		    cor = 10. ** (0.4 *
			(av * ccm (x[i], rv) - avold * ccm (x[i], rvold)))
		    z[i] = y[i] * cor
		}
	    } else {
		do i = 1, n {
		    cor = 10. ** (0.4 * (av - avold) * ccm (x[i], rv))
		    z[i] = y[i] * cor
		}
	    }
	} else {
	    do i = 1, n {
		cor = 10. ** (0.4 * av * ccm (x[i], rv))
		z[i] = y[i] * cor
	    }
	}
end


# DEREDDEN1 -- Deredden fluxes at a single wavelength

procedure deredden1 (x, y, z, n, av, rv, avold, rvold)

real	x			# Wavelength
real	y[n]			# Input fluxes
real	z[n]			# Output fluxes
int	n			# Number of points
real	av, avold		# A(V)
real	rv, rvold		# A(V)/E(B-V)

int	i
real	cor, ccm()
errchk	ccm

begin
	if (avold != 0.) {
	    if (rv != rvold)
		cor = 10. ** (0.4 *
		    (av * ccm (x, rv) - avold * ccm (x, rvold)))
	    else
		cor = 10. ** (0.4 * (av - avold) * ccm (x, rv))
	} else
	    cor = 10. ** (0.4 * av * ccm (x, rv))
	do i = 1, n
	    z[i] = y[i] * cor
end


# CCM -- Compute CCM Extinction Law

real procedure ccm (wavelength, rv) 

real	wavelength		# Wavelength in Angstroms
real	rv			# A(V) / E(B-V)

real	x, y, a, b

begin
	# Convert to inverse microns
	x = 10000. / wavelength

	# Compute a(x) and b(x)
	if (x < 0.3) {
	    call error (1, "Wavelength out of range of extinction function")

	} else if (x < 1.1) {
	    y = x ** 1.61
	    a = 0.574 * y
	    b = -0.527 * y

	} else if (x < 3.3) {
	    y = x - 1.82
	    a = 1 + y * (0.17699 + y * (-0.50447 + y * (-0.02427 +
		y * (0.72085 + y * (0.01979 + y * (-0.77530 + y * 0.32999))))))
	    b = y * (1.41338 + y * (2.28305 + y * (1.07233 + y * (-5.38434 +
		y * (-0.62251 + y * (5.30260 + y * (-2.09002)))))))

	} else if (x < 5.9) {
	    y = (x - 4.67) ** 2
	    a = 1.752 - 0.316 * x - 0.104 / (y + 0.341)
	    b = -3.090 + 1.825 * x + 1.206 / (y + 0.263)

	} else if (x < 8.0) {
	    y = (x - 4.67) ** 2
	    a = 1.752 - 0.316 * x - 0.104 / (y + 0.341)
	    b = -3.090 + 1.825 * x + 1.206 / (y + 0.263)

	    y = x - 5.9
	    a = a - 0.04473 * y**2 - 0.009779 * y**3
	    b = b + 0.2130 * y**2 + 0.1207 * y**3

	} else if (x <= 10.0) {
	    y = x - 8
	    a = -1.072 - 0.628 * y + 0.137 * y**2 - 0.070 * y**3
	    b = 13.670 + 4.257 * y - 0.420 * y**2 + 0.374 * y**3

	} else {
	    call error (1, "Wavelength out of range of extinction function")

	}

	# Compute A(lambda)/A(V)
	y = a + b / rv
	return (y)
end
