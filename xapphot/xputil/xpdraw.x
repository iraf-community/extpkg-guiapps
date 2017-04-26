include <gset.h>

# XP_EMARK -- Draw an ellipse on the screen.

procedure xp_emark (gd, xc, yc, a, ratio, theta) 

pointer	gd			#I pointer to the graphics descriptor
real	xc, yc			#I coordinates of the ellipse center
real	a			#I the semi-major axis of the ellipse
real	ratio			#I the ratio of semi-minor to semi-major axes
real	theta			#I the position angle of the ellipse

real	aa, bb, cc, ff, bp, cp, discr, x, y, x1, x2, y1, y2	

begin
	if (a <= 0.0)
	    return

	# Compute the parameters of the ellipse.
	call xp_ellipse (a, ratio, theta, aa, bb, cc, ff)

	# Compute the limits of the ellipse.
        y = sqrt (ff / (cc - bb * bb / 4.0 / aa))
	y1 = -y
	x1 = -bb * y1 / (2.0 * aa) 
	y2 = y
	x2 = -bb * y2 / (2.0 * aa) 

	# Draw first half of the ellipse.
	call gamove (gd, x1 + xc, y1 + yc)
	for (y = y1 + 1.0; y <= y2; y = y + 1.0) {
	    bp = bb * y
	    cp = cc * y * y - ff
	    discr = bp * bp - 4.0 * aa * cp
	    if (discr >= 0.0)
		discr = sqrt (discr)
	    else
		discr = 0.0
	    x = (-bp - discr) / (2.0 * aa)
	    call gadraw (gd, x + xc, y + yc)
	}
	call gadraw (gd, x2 + xc, y2 + yc)

	# Draw second half of the ellipse.
	for (y = y2 - 1.0; y >= y1; y = y - 1.0) {
	    bp = bb * y
	    cp = cc * y * y - ff
	    discr = bp * bp - 4.0 * aa * cp
	    if (discr >= 0.0)
		discr = sqrt (discr)
	    else
		discr = 0.0
	    x = (-bp + discr) / (2.0 * aa)
	    call gadraw (gd, x + xc, y + yc)
	}
	call gadraw (gd, x1 + xc, y1 + yc)
end


# XP_RMARK -- Draw a rectangle on the image display.

procedure xp_rmark (gd, xc, yc, w, ratio, theta) 

pointer	gd			#I the pointer to the graphics descriptor
real	xc, yc			#I the coordinates of the ellipse center
real	w			#I the half-width of the long axis
real	ratio			#I the ratio of the short to long axes
real	theta			#I the position angle of the ellipse

real	x[4], y[4]
begin
	call xp_pyrectangle (w, ratio, theta, x, y)
	call aaddkr (x, xc, x, 4)
	call aaddkr (y, yc, y, 4)

	call gamove (gd, x[1], y[1])
	call gadraw (gd, x[2], y[2])
	call gadraw (gd, x[3], y[3])
	call gadraw (gd, x[4], y[4])
	call gadraw (gd, x[1], y[1])
end


# XP_PMARK -- Draw a polygon on the image display.

procedure xp_pmark (gd, xver, yver, nver)

pointer	gd		#I the pointer to the graphics stream
real	xver[ARB]	#I the x coordinates of the vertices
real	yver[ARB]	#I the y coordinates of the vertices
int	nver		#I the number of vertices

int	i

begin
	call gamove (gd, xver[1], yver[1])
	do i = 2, nver 
	    call gadraw (gd, xver[i], yver[i])
	call gadraw (gd, xver[1], yver[1])
end


# XP_RGFILL -- Fill a rectangular area with a given style and color.

procedure xp_rgfill (gd, xmin, xmax, ymin, ymax, fstyle, fcolor)

pointer	gd			#I the pointer to the graphics stream
real	xmin, xmax		#I the x coordinate limits
real	ymin, ymax		#I the y coordinate limits
int	fstyle			#I the fill style
int	fcolor			#I the fill color

real	x[4], y[4]

begin
	call gseti (gd, G_FACOLOR, fcolor)
	x[1] = xmin; y[1] = ymin
	x[2] = xmax; y[2] = ymin
	x[3] = xmax; y[3] = ymax
	x[4] = xmin; y[4] = ymax
	call gfill (gd, x, y, 4, fstyle)
end
