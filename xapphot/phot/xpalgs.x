include <mach.h>
include <math.h>
include <imhdr.h>
include "../lib/impars.h"

procedure xp_cmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, aperts, sums,
	areas, flux, sumxsq, sumxy, sumysq, naperts, adatamin, adatamax)

pointer	im			#I the pointer to the image
real	wx, wy			#I the x and y center of the subraster
int	c1, c2			#I the subraster column limits
int	l1, l2			#I the subraster line limits
real	sky_mode		#I the input sky value
real	aperts[ARB]		#I the array of aperture radii
double	sums[ARB]		#O the output aperture sums
double	areas[ARB]		#O the output aperture areas
double	flux[ARB]		#O the output aperture fluxes
double	sumxsq[ARB]		#O the output aperture x-squared fluxes
double	sumxy[ARB]		#O the output aperture xy fluxes
double	sumysq[ARB]		#O the output aperture y-squared fluxes
int	naperts			#I the number of apertures
real	adatamin		#O the output minimum data value
real	adatamax		#O the output maximum data value

int	i, j, k, nx, yindex
pointer	buf
real	xc, yc, apmaxsq, dy, dy2, dx, dx2, r2, r, pixel, fpixel, fctn, fwt
pointer	imgs2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return
	nx = c2 - c1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	apmaxsq = (aperts[naperts] + 0.5) ** 2

	# Loop over the pixels.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == NULL)
		return
	    yindex = j - l1 + 1
	    dy = yindex - yc
	    dy2 = dy * dy
	    do i = 1, nx {
		dx = i - xc
		dx2 = dx * dx
		r2 = dx2 + dy2
		if (r2 > apmaxsq)
		    next
		r = sqrt (r2) - 0.5
		pixel = Memr[buf+i-1]
		fpixel = pixel - sky_mode
		adatamin = min (adatamin, pixel)
		adatamax = max (adatamax, pixel)
		do k = 1, naperts {
		    if (aperts[k] <= 0.0)
			next
		    if (r > aperts[k])
			next
		    fctn = max (0.0, min (1.0, aperts[k] - r))
		    fwt = fctn * fpixel
		    sums[k] = sums[k] + fctn * pixel
		    areas[k] = areas[k] + fctn
		    flux[k] = flux[k] + fwt
		    sumxsq[k] = sumxsq[k] + fwt * dx2 
		    sumxy[k] = sumxy[k] + fwt * dx * dy 
		    sumysq[k] = sumysq[k] + fwt * dy2 
		}
	    }
	}
end


# XP_CBMEASURE -- Measure the fluxes and effective areas of a set of concentric
# circular apertures while testing for bad pixels.

procedure xp_cbmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, datamin,
	datamax, aperts, sums, areas, flux, sumxsq, sumxy, sumysq, naperts,
	minapert, adatamin, adatamax)

pointer	im			#I the pointer to image
real	wx, wy			#I the x and y center of subraster
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the sky value
real	datamin			#I the minimum good data value
real	datamax			#I the maximum good data value
real	aperts[ARB]		#I the array of aperture radii
double	sums[ARB]		#O the ouotput array of sums
double	areas[ARB]		#O the output array of aperture areas
double	flux[ARB]		#O the output array of aperture fluxes
double	sumxsq[ARB]		#O the output array of aperture x-squared fluxes
double	sumxy[ARB]		#O the output array of aperture xy fluxes
double	sumysq[ARB]		#O the output array of aperture y-squared fluxes
int	naperts			#I the number of apertures
int	minapert		#O the minimum good aperture
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

int	i, j, k, nx, yindex, kindex
pointer	buf
real	xc, yc, apmaxsq, dy, dy2, dx, dx2, r2, r, pixval, fctn, fpixval, fwt
pointer	imgs2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return
	nx = c2 - c1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	minapert = naperts + 1
	apmaxsq = (aperts[naperts] + 0.5) ** 2

	# Loop over the pixels.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == NULL)
		return
	    yindex = j - l1 + 1
	    dy = yindex - yc
	    dy2 = dy * dy
	    do i = 1, nx {
		dx = i - xc
		dx2 = dx * dx
		r2 = dx2 + dy2
		if (r2 > apmaxsq)
		    next
		r = sqrt (r2) - 0.5
		pixval = Memr[buf+i-1]
		fpixval = pixval - sky_mode
		adatamin = min (adatamin, pixval)
		adatamax = max (adatamax, pixval)
		kindex = naperts + 1
		do k = 1, naperts {
		    if (aperts[k] <= 0.0)
			next
		    if (r > aperts[k])
			next
		    kindex = min (k, kindex)
		    fctn = max (0.0, min (1.0, aperts[k] - r))
		    fwt = fctn * fpixval
		    sums[k] = sums[k] + fctn * pixval
		    areas[k] = areas[k] + fctn
		    flux[k] = flux[k] + fwt
		    sumxsq[k] = sumxsq[k] + fwt * dx2
		    sumxy[k] = sumxy[k] + fwt * dx * dy
		    sumysq[k] = sumysq[k] + fwt * dy2
		}
		if (kindex < minapert) {
		    if (pixval < datamin || pixval > datamax)
		        minapert = kindex
		}
	    }
	}
end


# XP_EMEASURE -- Measure the fluxes and effective areas of a set of concentric
# elliptical apertures.

procedure xp_emeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, aperts, ratio,
	theta, sums, areas, flux, sumxsq, sumxy, sumysq, naperts,
	adatamin, adatamax)

pointer	im			#I the pointer to the image
real	wx, wy			#I the x and y center of the subraster
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode                #I the sky value
real	aperts[ARB]		#I the array of aperture radii
real	ratio			#I the ratio of major to minor axes
real	theta			#I the  position angle of major axis
double	sums[ARB]		#O the  array of aperture sums
double	areas[ARB]		#O the array of  aperture areas
double	flux[ARB]		#O the array of aperture fluxes
double	sumxsq[ARB]		#O the array  aperture x-squared fluxes
double	sumxy[ARB]		#O the array of aperture xy fluxes
double	sumysq[ARB]		#O the array of aperture y-squared fluxes
int	naperts			#I the number of apertures
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

int	i, j, k, nx, yindex
pointer	buf
real	xc, yc, apminsq, apmaxsq, aa, bb, cc, ff
real	dy, dy2, dx, dx2, r2, r, pixel, fpixel, fctn, fwt
pointer	imgs2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return
	nx = c2 - c1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	apminsq = aperts[naperts] ** 2
	apmaxsq = (ratio * (aperts[naperts] + 0.5)) ** 2

	# Initialize the ellipse coefficients.
	call xp_ellipse (aperts[naperts], ratio, theta, aa, bb, cc, ff)
	aa = aa / apminsq
	bb = bb / apminsq
	cc = cc / apminsq
	ff = ff / apminsq

	# Loop over the pixels.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == NULL)
		return
	    yindex = j - l1 + 1
	    dy = (yindex - yc)
	    dy2 = dy ** 2
	    do i = 1, nx {
		dx = (i - xc)
		dx2 = dx * dx
		r2 = aa * dx2 + bb * dx * dy + cc * dy2
		if (r2 > apmaxsq)
		    next
		r = sqrt (r2) - 0.5
		pixel = Memr[buf+i-1]
		fpixel = pixel - sky_mode
		adatamin = min (adatamin, pixel)
		adatamax = max (adatamax, pixel)
		do k = 1, naperts {
		    if (aperts[k] <= 0.0)
			next
		    if (r > (aperts[k] * ratio))
			next
		    fctn = max (0.0, min (1.0, ratio * aperts[k] - r))
		    fwt = fctn * fpixel
		    sums[k] = sums[k] + fctn * pixel
		    areas[k] = areas[k] + fctn
		    flux[k] = flux[k] + fwt
		    sumxsq[k] = sumxsq[k] + fwt * dx2
		    sumxy[k] = sumxy[k] + fwt * dx * dy
		    sumysq[k] = sumysq[k] + fwt * dy2
		}
	    }
	}
end


# XP_EBMEASURE -- Measure the fluxes and effective areas of a set of concentric
# elliptical apertures while testing for bad pixels.

procedure xp_ebmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, datamin, datamax,
	aperts, ratio, theta, sums, areas, flux, sumxsq, sumxy, sumysq,
	naperts, minapert, adatamin, adatamax)

pointer	im			#I the pointer to the image
real	wx, wy			#I the x and y  center of the subraster
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the  sky value
real	datamin			#I the minimum good data value
real	datamax			#I the  maximum good data value
real	aperts[ARB]		#I the array of aperture radii
real	ratio			#I the ratio of short to long axes
real	theta			#I the position angle of the long axis
double	sums[ARB]		#O the  array of aperture sums
double	areas[ARB]		#O the array of aperture areas
double	flux[ARB]		#O the array of aperture fluxes
double	sumxsq[ARB]		#O the array of aperture x-squared fluxes
double	sumxy[ARB]		#O the array of  aperture xy fluxes
double	sumysq[ARB]		#O the array of aperture y-squared fluxes
int	naperts			#I the number of apertures
int	minapert		#O the minimum good aperture
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

int	i, j, k, nx, yindex, kindex
pointer	buf
real	xc, yc, apmaxsq, apminsq,  aa, bb, cc, ff, dy2, r2, r, pixval, fctn
real	dy, dx, dx2, fpixval, fwt
pointer	imgs2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return
	nx = c2 - c1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1
	apminsq = aperts[naperts] ** 2
	apmaxsq = (ratio * (aperts[naperts] + 0.5)) ** 2
	minapert = naperts + 1

	# Initialize the ellipse coefficients.
	call xp_ellipse (aperts[naperts], ratio, theta, aa, bb, cc, ff)
	aa = aa / apminsq
	bb = bb / apminsq
	cc = cc / apminsq
	ff = ff / apminsq

	# Loop over the pixels.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do j = l1, l2 {
	    buf = imgs2r (im, c1, c2, j, j)
	    if (buf == NULL)
		return
	    yindex = j - l1 + 1
	    dy = yindex - yc
	    dy2 = dy ** 2
	    do i = 1, nx {
		dx = i - xc
		dx2 = dx * dx
		r2 = aa * dx2 + bb * dx * dy + cc * dy2
		if (r2 > apmaxsq)
		    next
		r = sqrt (r2) - 0.5
		pixval = Memr[buf+i-1]
		fpixval = pixval - sky_mode
		adatamin = min (adatamin, pixval)
		adatamax = max (adatamax, pixval)
		kindex = naperts + 1
		do k = 1, naperts {
		    if (aperts[k] <= 0.0)
			next
		    if (r > (aperts[k] * ratio))
			next
		    kindex = min (k, kindex)
		    fctn = max (0.0, min (1.0, ratio * aperts[k] - r))
		    fwt = fctn * fpixval
		    sums[k] = sums[k] + fctn * pixval
		    areas[k] = areas[k] + fctn
		    flux[k] = flux[k] + fwt
		    sumxsq[k] = sumxsq[k] + fwt * dx2
		    sumxy[k] = sumxy[k] + fwt * dx * dy
		    sumysq[k] = sumysq[k] + fwt * dy2
		}
		if (kindex < minapert) {
		    if (pixval < datamin || pixval > datamax)
		        minapert = kindex
		}
	    }
	}
end


# XP_RMEASURE -- Measure the fluxes and effective areas of a set of concentric
# rectangular apertures.

procedure xp_rmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, aperts, ratio,
	theta, sums, areas, flux, sumxsq, sumxy, sumysq, naperts,
	adatamin, adatamax)

pointer	im			#I the pointer to the input image
real	wx, wy			#I the x and y center of subraster
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the sky value
real	aperts[ARB]		#I the array of aperture radii
real	ratio			#I the ratio of major to minor axes
real	theta			#I the position angle of the major axis
double	sums[ARB]		#O the array of aperture sums
double	areas[ARB]		#O the array of aperture areas
double	flux[ARB]		#O the array of aperture fluxes
double	sumxsq[ARB]		#O the array of aperture x-squared fluxes
double	sumxy[ARB]		#O the array of aperture xy fluxes
double	sumysq[ARB]		#O the array aperture y-squared fluxes
int	naperts			#I the number of apertures
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

double	sumx, areax, fluxx, sumxsqx, sumxyx, sumysqx
int	i, k, j, jj, nintr, colmin, colmax
pointer	sp, work1, work2, xintr, buf
real	ymin, ymax, lx, ld, aymin, aymax, axmin, axmax, dy, dy2, dx, dx2
real	fctny, fctnx, pixel, fpixel, fwt
real	xver[5], yver[5]
int	xp_pyclip()
pointer	imgl2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return

	# Allocate working space.
	call smark (sp)
	call salloc (work1, 5, TY_REAL)
	call salloc (work2, 5, TY_REAL)
	call salloc (xintr, 5, TY_REAL)

	# Compute the minimum and maximum y values.
	call xp_pyrectangle (aperts[naperts], ratio, theta, xver, yver)
	call aaddkr (xver, wx, xver, 4)
	call aaddkr (yver, wy, yver, 4)
	call alimr (yver, 4, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))
	#linemin = min (int (ymin + 0.5), IM_LEN(im,2)) 
	#linemax = min (int (ymax + 0.5), IM_LEN(im,2)) 

	# Set up the line segment limit.
	lx = real(IM_LEN(im,1))

	# Loop over the range of lines of interest.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do i = l1, l2 {

	    # Read in the image line.
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next
	    if (ymin > i)
		ld = min (i + 1, l2)
	    else if (ymax < i)
		ld = max (i - 1, l1)
	    else
		ld = i
	    dy = i - wy
	    dy2 = dy * dy

	    # Loop over the apertures.
	    do k = 1, naperts {
		
		# Compute the vertices.
		if (aperts[k] <= 0.0)
		    next
		call xp_pyrectangle (aperts[k], ratio, theta, xver, yver)
		call aaddkr (xver, wx, xver, 4)
		call aaddkr (yver, wy, yver, 4)
		xver[5] = xver[1]
		yver[5] = yver[1]

		# Compute the intersection points
		nintr = xp_pyclip (xver, yver, Memr[work1], Memr[work2],
		    Memr[xintr], 5, lx, ld)
		if (nintr <= 0)
		    next

		# Sort the intersection points.
		call asrtr (Memr[xintr], Memr[xintr], nintr)

		# Determine any fractional pixel contribution in y
		call alimr (yver, 4, aymin, aymax)
		aymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), aymin))
		aymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, aymax))
		fctny = min (i + 0.5, aymax) - max (i - 0.5, aymin)

		# Integrate the line segments.
		sumx = 0.0d0
		areax = 0.0d0
		fluxx = 0.0d0
		sumxsqx = 0.0d0
		sumxyx = 0.0d0
		sumysqx = 0.0d0
		do j = 1, nintr, 2 {

                    axmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j-1]))
                    axmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j]))
                    colmin = min (int (axmin + 0.5), int (IM_LEN(im,1)))
                    colmax = min (int (axmax + 0.5), int (IM_LEN(im,1)))

                    # Sum the contribution from a particular line segment.
                    do jj = colmin, colmax {
			dx = jj - wx
			dx2 = dx * dx
                        fctnx = min (jj + 0.5, axmax) - max (jj - 0.5, axmin)
			pixel = Memr[buf+jj-1]
			adatamin = min (adatamin, pixel)
			adatamax = max (adatamax, pixel)
                        sumx = sumx + fctnx * pixel
                        areax = areax + fctnx
			fpixel = pixel - sky_mode
			fwt = fctnx * fpixel
			fluxx = fluxx + fwt
			sumxsqx = sumxsqx + fwt * dx2
			sumxyx = sumxyx + fwt * dx * dy
			sumysqx = sumysqx + fwt * dy2
                    }
		}

		# Add sum to the aperture
		sums[k] = sums[k] + sumx * fctny
		areas[k] = areas[k] + areax * fctny
		flux[k] = flux[k] + fluxx * fctny
		sumxsq[k] = sumxsq[k] + sumxsqx * fctny
		sumxy[k] = sumxy[k] + sumxyx * fctny
		sumysq[k] = sumysq[k] + sumysqx * fctny

	    }
	}


	call sfree (sp)
end


# XP_RBMEASURE -- Measure the fluxes and effective areas of a set of concentric
# rectangular apertures while testing for bad pixels.

procedure xp_rbmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode, datamin, datamax,
	aperts, ratio, theta, sums, areas, flux, sumxsq, sumxy, sumysq,
	naperts, minapert, adatamin, adatamax)

pointer	im			#I the pointer to the image
real	wx, wy			#I the x and y center of subraster
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the sky value
real	datamin			#I the minimum good data value
real	datamax			#I the maximum good data value
real	aperts[ARB]		#I the array of aperture radii
real	ratio			#I the ratio of short to long axes
real	theta			#I the position angle of the long axis
double	sums[ARB]		#O the array of aperture sums
double	areas[ARB]		#O the array of aperture areas
double	flux[ARB]		#O the array of  aperture fluxes
double	sumxsq[ARB]		#O the array of aperture x-squared fluxes
double	sumxy[ARB]		#O the array of aperture xy fluxes
double	sumysq[ARB]		#O the array of aperture y-squared fluxes
int	naperts			#I the number of apertures
int	minapert		#O the  minimum good aperture
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

double	sumx, areax, fluxx, sumxsqx, sumxyx, sumysqx
int	i, k, j, jj, nintr, colmin, colmax, kindex
pointer	sp, work1, work2, xintr, buf
real	ymin, ymax, lx, ld, aymin, aymax, axmin, axmax, dy, dy2, dx, dx2
real	fctny, fctnx, pixel, fpixel, fwt
real	xver[5], yver[5]
int	xp_pyclip()
pointer	imgl2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (aperts[naperts] <= 0.0)
	    return

	# Allocate working space.
	call smark (sp)
	call salloc (work1, 5, TY_REAL)
	call salloc (work2, 5, TY_REAL)
	call salloc (xintr, 5, TY_REAL)

	# Compute the minimum and maximum y values.
	call xp_pyrectangle (aperts[naperts], ratio, theta, xver, yver)
	call aaddkr (xver, wx, xver, 4)
	call aaddkr (yver, wy, yver, 4)
	call alimr (yver, 4, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))

	# Set up the line segment limit.
	lx = real(IM_LEN(im,1))

	# Loop over the range of lines of interest.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	minapert = naperts + 1
	do i = l1, l2 {

	    # Read in the image line.
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next
	    if (ymin > i)
		ld = min (i + 1, l2)
	    else if (ymax < i)
		ld = max (i - 1, l1)
	    else
		ld = i
	    dy = i - wy
	    dy2 = dy * dy

	    # Loop over the apertures.
	    kindex = naperts + 1
	    do k = 1, naperts {
		
		# Compute the vertices.
		if (aperts[k] <= 0.0)
		    next
		call xp_pyrectangle (aperts[k], ratio, theta, xver, yver)
		call aaddkr (xver, wx, xver, 4)
		call aaddkr (yver, wy, yver, 4)
		xver[5] = xver[1]
		yver[5] = yver[1]

		# Compute the intersection points
		nintr = xp_pyclip (xver, yver, Memr[work1], Memr[work2],
		    Memr[xintr], 5, lx, ld)
		if (nintr <= 0)
		    next
		kindex = min (k, kindex)

		# Sort the intersection points.
		call asrtr (Memr[xintr], Memr[xintr], nintr)

		# Determine any fractional pixel contribution in y
		call alimr (yver, 4, aymin, aymax)
		aymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), aymin))
		aymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, aymax))
		fctny = min (i + 0.5, aymax) - max (i - 0.5, aymin)

		# Integrate the line segments.
		sumx = 0.0d0
		areax = 0.0d0
		fluxx = 0.0d0
		sumxsqx = 0.0d0
		sumxyx = 0.0d0
		sumysqx = 0.0d0
		do j = 1, nintr, 2 {

                    axmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j-1]))
                    axmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j]))
                    colmin = min (int (axmin + 0.5), int (IM_LEN(im,1)))
                    colmax = min (int (axmax + 0.5), int (IM_LEN(im,1)))

                    # Sum the contribution from a particular line segment.
                    do jj = colmin, colmax {
			dx = jj - wx
			dx2 = dx * dx
                        fctnx = min (jj + 0.5, axmax) - max (jj - 0.5, axmin)
			pixel = Memr[buf+jj-1]
			if ((pixel < datamin || pixel > datamax) &&
			    (kindex < minapert))
			    minapert = kindex
			adatamin = min (adatamin, pixel)
			adatamax = max (adatamax, pixel)
                        sumx = sumx + fctnx * pixel
                        areax = areax + fctnx
			fpixel = pixel - sky_mode
			fwt = fpixel * fctnx
			fluxx = fluxx + fwt
			sumxsqx = sumxsqx + fwt * dx2
			sumxyx = sumxyx + fwt * dx * dy
			sumysqx = sumysqx + fwt * dy2
                    }
		}

		# Add sum to the aperture
		sums[k] = sums[k] + sumx * fctny
		areas[k] = areas[k] + areax * fctny
		flux[k] = flux[k] + fluxx * fctny
		sumxsq[k] = sumxsq[k] + sumxsqx * fctny
		sumxy[k] = sumxy[k] + sumxyx * fctny
		sumysq[k] = sumysq[k] + sumysqx * fctny
	    }
	}


	call sfree (sp)
end


# XP_PMEASURE -- Measure the fluxes and effective areas of a set of concentric
# polygonal apertures.

procedure xp_pmeasure (im, xshift, yshift, xver, yver, nver, c1, c2, l1, l2,
	sky_mode, aperts, sums, areas, flux, sumxsq, sumxy, sumysq, naperts,
	adatamin, adatamax)

pointer	im			#I the pointer to the image
real	xshift, yshift		#I the polygon x and y shifts
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the x coordinates of the polygon vertices
int	nver			#I the number of vertices
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the sky value
real	aperts[ARB]		#I the array of aperture radii
double	sums[ARB]		#O the array of aperture sums
double	areas[ARB]		#O the array of aperture areas
double	flux[ARB]		#O the array of aperture fluxes
double	sumxsq[ARB]		#O the array of aperture x-squared fluxes
double	sumxy[ARB]		#O the array of  aperture xy  fluxes
double	sumysq[ARB]		#O the array of  aperture y-squared fluxes
int	naperts			#I the number of apertures
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

double	sumx, areax, fluxx, sumxsqx, sumxyx, sumysqx
int	i, k, j, jj, nintr, colmin, colmax
pointer	sp, work1, work2, xintr, txver, tyver, buf
real	ymin, ymax, lx, ld, aymin, aymax, axmin, axmax, dy, dy2, dx, dx2
real	wx, wy, fctny, fctnx, pixel, fpixel, fwt
int	xp_pyclip()
real	asumr()
pointer	imgl2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (nver < 3)
	    return
	#if (aperts[naperts] <= 0.0)
	    #return

	# Allocate working space.
	call smark (sp)
	call salloc (work1, nver + 1, TY_REAL)
	call salloc (work2, nver + 1, TY_REAL)
	call salloc (xintr, nver + 1, TY_REAL)
	call salloc (txver, nver + 1, TY_REAL)
	call salloc (tyver, nver + 1, TY_REAL)

	# Compute the minimum and maximum y values.
	if (aperts[naperts] <= 0.0) {
	    call amovr (xver, Memr[txver], nver)
	    call amovr (yver, Memr[tyver], nver)
	} else
	    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], nver,
	        aperts[naperts])
	call aaddkr (Memr[txver], xshift, Memr[txver], nver)
	call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
	wx = asumr (Memr[txver], nver) / nver
	wy = asumr (Memr[tyver], nver) / nver
	call alimr (Memr[tyver], nver, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))

	# Set up the line segment limit.
	lx = real(IM_LEN(im,1))

	# Loop over the range of lines of interest.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	do i = l1, l2 {

	    # Read in the image line.
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next
	    if (ymin > i)
		ld = min (i + 1, l2)
	    else if (ymax < i)
		ld = max (i - 1, l1)
	    else
		ld = i
	    dy = i - wy
	    dy2 = dy * dy

	    # Loop over the apertures.
	    do k = 1, naperts {
		
		# Compute the vertices.
		if (aperts[k] <= 0.0) {
	    	    call amovr (xver, Memr[txver], nver)
	    	    call amovr (yver, Memr[tyver], nver)
		} else
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver],
		        nver, aperts[k])
		Memr[txver+nver] = Memr[txver]
		Memr[tyver+nver] = Memr[tyver]
		call aaddkr (Memr[txver], xshift, Memr[txver], nver + 1)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver + 1)

		# Compute the intersection points
		nintr = xp_pyclip (Memr[txver], Memr[tyver], Memr[work1],
		    Memr[work2], Memr[xintr], nver + 1, lx, ld)
		if (nintr <= 0)
		    next

		# Sort the intersection points.
		call asrtr (Memr[xintr], Memr[xintr], nintr)

		# Determine any fractional pixel contribution in y
		call alimr (Memr[tyver], nver, aymin, aymax)
		aymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), aymin))
		aymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, aymax))
		fctny = min (i + 0.5, aymax) - max (i - 0.5, aymin)

		# Integrate the line segments.
		sumx = 0.0d0
		areax = 0.0d0
		fluxx = 0.0d0
		sumxsqx = 0.0d0
		sumxyx = 0.0d0
		sumysqx = 0.0d0
		do j = 1, nintr, 2 {

                    axmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j-1]))
                    axmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j]))
                    colmin = min (int (axmin + 0.5), int (IM_LEN(im,1)))
                    colmax = min (int (axmax + 0.5), int (IM_LEN(im,1)))

                    # Sum the contribution from a particular line segment.
                    do jj = colmin, colmax {
			dx = jj - wx
			dx2 = dx * dx
                        fctnx = min (jj + 0.5, axmax) - max (jj - 0.5, axmin)
			pixel = Memr[buf+jj-1]
			adatamin = min (adatamin, pixel)
			adatamax = max (adatamax, pixel)
                        sumx = sumx + fctnx * pixel
                        areax = areax + fctnx
			fpixel = pixel - sky_mode
			fwt = fpixel * fctnx
			fluxx = fluxx + fwt
			sumxsqx = sumxsqx + fwt * dx2
			sumxyx = sumxyx + fwt * dx * dy
			sumysqx = sumysqx + fwt * dy2
                    }
		}

		# Add sum to the aperture
		sums[k] = sums[k] + sumx * fctny
		areas[k] = areas[k] + areax * fctny
		flux[k] = flux[k] + fluxx * fctny
		sumxsq[k] = sumxsq[k] + sumxsqx * fctny
		sumxy[k] = sumxy[k] + sumxyx * fctny
		sumysq[k] = sumysq[k] + sumysqx * fctny

	    }
	}


	call sfree (sp)
end


# XP_PBMEASURE -- Measure the fluxes and effective areas of a set of concentric
# polygonal apertures while testing for bad pixels.

procedure xp_pbmeasure (im, xshift, yshift, xver, yver, nver, c1, c2, l1, l2,
	sky_mode, datamin, datamax, aperts, sums, areas, flux, sumxsq, sumxy,
	sumysq, naperts, minapert, adatamin, adatamax)

pointer	im			#I the pointer to input image
real	xshift, yshift		#I the x and y shift of the polygon
real	xver[ARB]		#I the x coordinates of the polygon vertices
real	yver[ARB]		#I the y coordinates of the polygon vertices
int	nver			#I the number of vertices
int	c1, c2			#I the column limits
int	l1, l2			#I the line limits
real	sky_mode		#I the sky value
real	datamin			#I the minimum good data value
real	datamax			#I the  maximum good data value
real	aperts[ARB]		#I the  array of aperture radii
double	sums[ARB]		#O the  array of aperture sums
double	areas[ARB]		#O the array of aperture areas
double	flux[ARB]		#O the array of aperture fluxes
double	sumxsq[ARB]		#O the array of aperture x-squared fluxes
double	sumxy[ARB]		#O the array of aperture xy fluxes
double	sumysq[ARB]		#O the array of  aperture y-squared fluxes
int	naperts			#I the number of apertures
int	minapert		#O the minimum good aperture
real	adatamin		#O the minimum data value
real	adatamax		#O the maximum data value

double	sumx, areax, fluxx, sumxsqx, sumxyx, sumysqx
int	i, k, j, jj, nintr, colmin, colmax, kindex
pointer	sp, work1, work2, xintr, buf, txver, tyver
real	ymin, ymax, lx, ld, aymin, aymax, axmin, axmax, dx, dx2, dy, dy2
real	wx, wy, fctny, fctnx, pixel, fpixel, fwt
int	xp_pyclip()
real	asumr()
pointer	imgl2r()

begin
	# Initialize.
	call aclrd (sums, naperts)
	call aclrd (areas, naperts)
	call aclrd (flux, naperts)
	call aclrd (sumxsq, naperts)
	call aclrd (sumxy, naperts)
	call aclrd (sumysq, naperts)
	if (nver < 3)
	    return
	#if (aperts[naperts] <= 0.0)
	    #return

	# Allocate working space.
	call smark (sp)
	call salloc (work1, nver + 1, TY_REAL)
	call salloc (work2, nver + 1, TY_REAL)
	call salloc (xintr, nver + 1, TY_REAL)
	call salloc (txver, nver + 1, TY_REAL)
	call salloc (tyver, nver + 1, TY_REAL)

	# Compute the minimum and maximum y values.
	if (aperts[naperts] <= 0.0) {
	    call amovr (xver, Memr[txver], nver)
	    call amovr (yver, Memr[tyver], nver)
	} else
	    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], nver,
	        aperts[naperts])
	call aaddkr (Memr[txver], xshift, Memr[txver], nver)
	call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
	wx = asumr (Memr[txver], nver) / nver
	wy = asumr (Memr[tyver], nver) / nver
	call alimr (Memr[tyver], nver, ymin, ymax)
	ymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), ymin))
	ymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, ymax))

	# Set up the line segment limit.
	lx = real(IM_LEN(im,1)) - 0.5

	# Loop over the range of lines of interest.
	adatamin = MAX_REAL
	adatamax = -MAX_REAL
	minapert = naperts + 1
	do i = l1, l2 {

	    # Read in the image line.
	    buf = imgl2r (im, i)
	    if (buf == EOF)
		next
	    if (ymin > i)
		ld = min (i + 1, l2)
	    else if (ymax < i)
		ld = max (i - 1, l1)
	    else
		ld = i
	    dy = i - wy
	    dy2 = dy * dy

	    # Loop over the apertures.
	    kindex = naperts + 1
	    do k = 1, naperts {
		
		# Compute the vertices.
		if (aperts[k] <= 0.0) {
	    	    call amovr (xver, Memr[txver], nver)
	    	    call amovr (yver, Memr[tyver], nver)
		} else
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver],
		        nver, aperts[k])
		Memr[txver+nver] = Memr[txver]
		Memr[tyver+nver] = Memr[tyver]
		call aaddkr (Memr[txver], xshift, Memr[txver], nver + 1)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver + 1)

		# Compute the intersection points
		nintr = xp_pyclip (Memr[txver], Memr[tyver], Memr[work1],
		    Memr[work2], Memr[xintr], nver + 1, lx, ld)
		if (nintr <= 0)
		    next
		kindex = min (k, kindex)

		# Sort the intersection points.
		call asrtr (Memr[xintr], Memr[xintr], nintr)

		# Determine any fractional pixel contribution in the y
		# direction.
		call alimr (Memr[tyver], nver, aymin, aymax)
		aymin = max (0.5, min (real(IM_LEN(im,2) + 0.5), aymin))
		aymax = min (real (IM_LEN(im,2) + 0.5), max (0.5, aymax))
		fctny = min (i + 0.5, aymax) - max (i - 0.5, aymin)

		# Integrate the line segments.
		sumx = 0.0d0
		areax = 0.0d0
		fluxx = 0.0d0
		sumxsqx = 0.0d0
		sumxyx = 0.0d0
		sumysqx = 0.0d0
		do j = 1, nintr, 2 {

		    # Compute the limits of the line segment including
		    # any fractional contribution.
                    axmin = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j-1]))
                    axmax = min (real (IM_LEN(im,1) + 0.5), max (0.5,
                        Memr[xintr+j]))
                    colmin = min (int (axmin + 0.5), int (IM_LEN(im,1)))
                    colmax = min (int (axmax + 0.5), int (IM_LEN(im,1)))

                    # Sum the contribution from a particular line segment.
                    do jj = colmin, colmax {
			dx = jj - wx
			dx2 = dx * dx
                        fctnx = min (jj + 0.5, axmax) - max (jj - 0.5, axmin)
			pixel = Memr[buf+jj-1]
			if ((pixel < datamin || pixel > datamax) &&
			    (kindex < minapert))
			    minapert = kindex
			adatamin = min (adatamin, pixel)
			adatamax = max (adatamax, pixel)
                        sumx = sumx + fctnx * pixel
                        areax = areax + fctnx
			fpixel = pixel - sky_mode
			fwt = fpixel * fctnx
			fluxx = fluxx + fwt
			sumxsqx = sumxsqx + fwt * dx2
			sumxyx = sumxyx + fwt * dx * dy
			sumysqx = sumysqx + fwt * dy2
                    }
		}

		# Add sum to the aperture
		sums[k] = sums[k] + sumx * fctny
		areas[k] = areas[k] + areax * fctny
		flux[k] = flux[k] + fluxx * fctny
		sumxsq[k] = sumxsq[k] + sumxsqx * fctny
		sumxy[k] = sumxy[k] + sumxyx * fctny
		sumysq[k] = sumysq[k] + sumysqx * fctny
	    }
	}

	call sfree (sp)
end


# XP_COPMAGS -- Procedure to compute the magnitudes from the aperture sums,
# areas and sky values.

procedure xp_copmags (flux, areas, mags, magerrs, naperts, sky, sigma, nsky,
        zmag, noise, padu)

double	flux[ARB]		#I the aperture fluxes
double	areas[ARB]		#I the aperture areas
real	mags[ARB]		#O the output magnitudes
real	magerrs[ARB]		#O the errors in the magnitudes
int	naperts			#I the number of apertures
real	sky			#I the sky value
real	sigma			#I the sigma of the sky values
int	nsky			#I the number of sky pixels
real	zmag			#I the magnitude zero point
int	noise			#I the noise model
real	padu			#I the photons per adu

int	i
real	err1, err2, err3, err

begin
	# Compute the magnitudes and errors
	do i = 1, naperts {
	    mags[i] = flux[i]
	    if (mags[i] <= 0.0)
		mags[i] = INDEFR
	    else {
		if (IS_INDEFR(sigma))
		    err1 = 0.0
		else
		    err1 = areas[i] * sigma ** 2
		switch (noise) {
		#case XP_INCONSTANT:
		    #err2 = 0.0
		case XP_INPOISSON:
		    err2 = mags[i] / padu
		default:
		    err2 = 0.0
		}
		if (nsky <= 0)
		    err3 = 0.0
		else if (IS_INDEFR(sigma))
		    err3 = 0.0
		else
		    err3 = sigma ** 2 * areas[i] ** 2 / nsky
		err = err1 + err2 + err3
		if (err <= 0.0)
		    magerrs[i] = 0.0
		else {
		    magerrs[i] = 1.0857 * sqrt (err) / mags[i]
		}
		mags[i] = zmag - 2.5 * log10 (mags[i])
	    }
	}
end


# XP_CONMAGS -- Procedure to compute the magnitudes from the aperture sums,
# areas and sky values.

procedure xp_conmags (sums, areas, flux, mags, magerrs, naperts, sky, sigma,
	nsky, zmag, noise, padu, readnoise)

double	sums[ARB]		#I the aperture sums
double	areas[ARB]		#I the aperture areas
double	flux[ARB]		#I the aperture fluxes
real	mags[ARB]		#O the output magnitudes
real	magerrs[ARB]		#O the errors in the magnitudes
int	naperts			#I the number of apertures
real	sky			#I the sky value
real	readnoise		#I the readout noise in electrons
real	sigma			#I the sigma of the sky values
int	nsky			#I the number of sky pixels
real	zmag			#I the magnitude zero point
int	noise			#I the noise model
real	padu			#I the photons per adu

int	i
real	err1, err2, err3, err

begin
	# Compute the magnitudes and errors
	do i = 1, naperts {
	    mags[i] = - flux[i]
	    if (mags[i] <= 0.0)
		mags[i] = INDEFR
	    else {
		if (IS_INDEFR(readnoise))
		    err1 = 0.0
		else
		    err1 = areas[i] * (readnoise / padu) ** 2
		switch (noise) {
		#case XP_INCONSTANT:
		    #err2 = 0.0
		case XP_INPOISSON:
		    err2 = abs (sums[i]) / padu
		default:
		    err2 = 0.0
		}
		if (nsky <= 0)
		    err3 = 0.0
		else if (IS_INDEFR(sigma))
		    err3 = 0.0
		else
		    err3 = sigma ** 2 * areas[i] ** 2 / nsky
		err = err1 + err2 + err3
		if (err <= 0.0)
		    magerrs[i] = 0.0
		else {
		    magerrs[i] = 1.0857 * sqrt (err) / abs (sums[i])
		}
		mags[i] = zmag - 2.5 * log10 (mags[i])
	    }
	}
end


# XP_2MOMENTS -- Perform a 2D moments shape analysis on the objects)

procedure xp_2moments (fluxes, sumxsq, sumxy, sumysq, hwidths, axratios,
	posangles, naperts)

double	fluxes[ARB]		#I the aperture fluxes
double	sumxsq[ARB]		#I the aperture x-squared fluxes
double	sumxy[ARB]		#I the aperture xy fluxes
double	sumysq[ARB]		#I the aperture y-squared fluxes
real	hwidths[ARB]		#O the output halfwidth estimates
real	axratios[ARB]		#O the output axis ratio estimates
real	posangles[ARB]		#O the output position angle estimates
int	naperts			#I the number of apertures

double	sumixx, sumixy, sumiyy, r2, diff
int	i

begin
	do i = 1, naperts {
	    if (fluxes[i] == 0.0d0) {
		hwidths[i] = INDEFR
		axratios[i] = INDEFR
		posangles[i] = INDEFR
	    } else {
	        sumixx = sumxsq[i] / fluxes[i]
	        sumixy = sumxy[i] / fluxes[i]
	        sumiyy = sumysq[i] / fluxes[i]
		r2 = sumixx + sumiyy
		if (r2 <= 0.0) {
		    hwidths[i] = INDEFR
		    axratios[i] = INDEFR
		    posangles[i] = INDEFR
		} else {
		    hwidths[i] = sqrt (LN_2 * r2)
		    diff = sumixx - sumiyy
		    axratios[i] = 1.0 - sqrt (diff ** 2 + 4.0 * sumixy ** 2) /
			r2
		    axratios[i] = max (0.0, min (axratios[i], 1.0))
		    if (diff == 0.0d0 && sumixy == 0.0d0)
			posangles[i] = 0.0
		    else
			posangles[i] = RADTODEG (0.5d0 * atan2 (2.0d0 * sumixy,
			    diff))
		    if (posangles[i] < 0.0)
			posangles[i] = posangles[i] + 180.0
		}
	    }
	}
end
