include <math.h>
include <gset.h>


# XP_MKPOLY -- Mark the coordinates of a polygon on the display device.

int procedure xp_mkpoly (gd, x, y, max_nvertices, itype, icolor, raster, object)

pointer	gd		#I the graphics stream pointer
real	x[ARB]		#I the x coordinates of the polygon vertices
real	y[ARB]		#I the y coordinatess of the polygon vertices
int	max_nvertices	#I the maximum number of vertices
int	itype		#I the input line type
int	icolor		#I the input line color
int	raster		#I the image display raster number
int	object		#I object polygon or sky polygon ?

int	ocolor, oltype, nvertices
int	gstati(), xp_trpoly()

begin
	if (gd == NULL)
	    return (0)

	# Set the raster.
	call gim_setraster (gd, raster)

	# Store the previous color and line type.
	ocolor = gstati (gd, G_PLCOLOR)
	oltype = gstati (gd, G_PLTYPE)

        # Set the color and line type.
	call gseti (gd, G_PLCOLOR, icolor)
        call gseti (gd, G_PLTYPE, itype)

	# Trace the polygon.
	nvertices = xp_trpoly (gd, x, y, max_nvertices, object)

	# Restore the old color and line type.
	call gseti (gd, G_PLCOLOR, ocolor)
	call gseti (gd, G_PLTYPE, oltype)

	# Reset the raster to zero.
	call gim_setraster (gd, 0)

	return (nvertices)
end


# XP_TRPOLY -- Trace the vertices of a polygon on the display device.

int procedure xp_trpoly (gd, x, y, max_nvertices, object)

pointer	gd		#I the graphics stream pointer
real	x[ARB]		#I the x coordinates of the polygon vertices
real	y[ARB]		#I the y coordinatess of the polygon vertices
int	max_nvertices	#I the maximum number of vertices
int	object		#I object polygon or sky polygon ?

int	wcs, key, stat, nvertices
pointer	sp, cmd
real	xtemp, ytemp
int	clgcur()

begin
	# Initialize.
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	# Type prompt and read the cursor.
	if (object == YES)
	    call printf (
	        "Mark object polygon vertex [v=mark,q=quit]\n")
	else
	    call printf (
	        "Mark sky polygon vertex [v=mark,q=quit]\n")
	stat = clgcur ("gcommands", xtemp, ytemp, wcs, key, Memc[cmd], SZ_LINE)

	# Fetch the polygon and draw it on the display.
	nvertices = 0
	while (stat != EOF) {

	    # Break on the q key.
	    if (key == 'q')
		break

	    # Decode and draw vertices on the space bark key.
	    if (key == 'v') {
	        if (nvertices < max_nvertices) {
	            nvertices = nvertices + 1
		    x[nvertices] = xtemp
		    y[nvertices] = ytemp
		    if (nvertices == 1) {
			call gmark (gd, x[1], y[1], GM_POINT, 0.0, 0.0)
		        call gamove (gd, x[1], y[1])
		    } else
		        call gadraw (gd, x[nvertices], y[nvertices])
	        } else
		    break
	    }

	    # Type prompt and read cursor once more.
	    if (object == YES)
	        call printf (
	            "Mark object polygon vertex [v=mark,q=quit]\n")
	    else
	        call printf (
	            "Mark sky polygon vertex [v=mark,q=quit]\n")
	    stat = clgcur ("gcommands", xtemp, ytemp, wcs, key, Memc[cmd],
	        SZ_LINE)
	}

	call printf ("\n")
	call sfree (sp)

	# Return the number of vertices in the polygon after adding the
	# last vertex and closing the polygon.
	if (stat == EOF || nvertices <= 2)
	    nvertices = 0
	else {
	    x[nvertices+1] = x[1]
	    y[nvertices+1] = y[1]
	    call gamove (gd, x[nvertices], y[nvertices])
	    call gadraw (gd, x[1], y[1])

	}

	return (nvertices)
end


# XP_PYEXPAND -- Expand a polygon given a list of vertices and an expansion
# factor in pixels.

procedure xp_pyexpand (xin, yin, xout, yout, nver, width)

real	xin[ARB]		#I the x coordinates of the input vertices
real	yin[ARB]		#I the y coordinates of the input vertices
real	xout[ARB]		#O the x coordinates of the output vertices
real	yout[ARB]		#O the y coordinates of the output vertices
int	nver			#I the number of vertices
real	width			#I the width of the expansion region

int	i
real	xcen, ycen, m1, b1, m2, b2, xp1, yp1, xp2, yp2
real	asumr()

begin
	# Find the center of gravity of the polygon.
	xcen = asumr (xin, nver) / nver
	ycen = asumr (yin, nver) / nver

	do i = 1, nver {

	    # Compute the equations of the line segments parallel to the
	    # line seqments composing a single vertex.
	    if (i == 1) {
		call xp_psegment (xcen, ycen, xin[nver], yin[nver], xin[1],
		    yin[1], width, m1, b1, xp1, yp1) 
		call xp_psegment (xcen, ycen, xin[1], yin[1], xin[2], yin[2],
		    width, m2, b2, xp2, yp2) 
	    } else if (i == nver) {
		call xp_psegment (xcen, ycen, xin[nver-1], yin[nver-1],
		    xin[nver], yin[nver], width, m1, b1, xp1, yp1) 
		call xp_psegment (xcen, ycen, xin[nver], yin[nver], xin[1],
		    yin[1], width, m2, b2, xp2, yp2) 
	    } else {
		call xp_psegment (xcen, ycen, xin[i-1], yin[i-1], xin[i],
		    yin[i], width, m1, b1, xp1, yp1) 
		call xp_psegment (xcen, ycen, xin[i], yin[i], xin[i+1],
		    yin[i+1], width, m2, b2, xp2, yp2) 
	    }

	    # The new vertex is the intersection of the two new line
	    # segments.
	    if (m1 == m2) {
		xout[i] = xp2
		yout[i] = yp2
	    } else if (IS_INDEFR(m1)) {
		xout[i] = xp1
		yout[i] = m2 * xp1 + b2
	    } else if (IS_INDEFR(m2)) {
		xout[i] = xp2
		yout[i] = m1 * xp2 + b1
	    } else {
		xout[i] = (b2 - b1) / (m1 - m2) 
		yout[i] = (m2 * b1 - m1 * b2) / (m2 - m1)
	    }
	}
end


# XP_PSEGMENT -- Construct a line segment parallel to an existing line segment
# but a specified distance from it in a direction away from a fixed reference
# point.

procedure xp_psegment (xcen, ycen, xb, yb, xe, ye, width, m, b, xp, yp)

real	xcen, ycen		#I the position of the reference point
real	xb, yb			#I the starting coordinates of the line segment
real	xe, ye			#I the ending coordinates of the line segment
real	width			#I the distance of new line segment from old
real	m			#O the slope of the new line segment
real	b			#O the intercept of the new line segment
real	xp, yp			#O the coordinates of a points on new line

real	x1, y1, x2, y2, d1, d2

begin
	# Compute the slope of the line segment.
	m = (xe - xb)
	if (m == 0.0)
	    m = INDEFR
	else
	    m = (ye - yb) / m

	# Construct the perpendicular to the line segement and locate two
	# points which are equidistant from the line seqment
	if (IS_INDEFR(m)) {
	    x1 = xb - width
	    y1 = yb
	    x2 = xb + width
	    y2 = yb
	} else if (m == 0.0) {
	    x1 = xb
	    y1 = yb - width
	    x2 = xb
	    y2 = yb + width
	} else {
	    x1 = xb - sqrt ((m * width) ** 2 / (m ** 2 + 1))
	    y1 = yb - (x1 - xb) / m
	    x2 = xb + sqrt ((m * width) ** 2 / (m ** 2 + 1))
	    y2 = yb - (x2 - xb) / m
	}

	# Choose the point farthest away from the reference point.
	d1 = (x1 - xcen) ** 2 + (y1 - ycen) ** 2
	d2 = (x2 - xcen) ** 2 + (y2 - ycen) ** 2
	if (d1 <= d2) {
	    xp = x2
	    yp = y2
	} else {
	    xp = x1
	    yp = y1
	}

	# Compute the intercept.
	if (IS_INDEFR(m))
	    b = INDEFR
	else
	    b = yp - m * xp
end


# XP_PYRECTANGLE -- Construct a polygon representation of a rotated
# rectangle give the half-width of the long axis, the ratio of the
# half-width of the short axis to the long axis, and the rotation angle.

procedure xp_pyrectangle (hwidth, ratio, theta, xout, yout)

real	hwidth		#I the half-width of the long axis of the rectangle
real	ratio		#I the ratio of short to long axes of the rectangle
real	theta		#I the rotation angle
real	xout[ARB]	#O the x coordinates of the output vertices
real	yout[ARB]	#O the y coordinates of the output vertices

real	cost, sint, x, y

begin
	cost = cos (DEGTORAD(theta))
	sint = sin (DEGTORAD(theta))
	x = hwidth
	y = ratio * x
	xout[1] = x * cost - y * sint
	yout[1] = x * sint + y * cost
	x = -x
	y = y
	xout[2] = x * cost - y * sint
	yout[2] = x * sint + y * cost
	x = x
	y = -y
	xout[3] = x * cost - y * sint
	yout[3] = x * sint + y * cost
	x = -x 
	y = y
	xout[4] = x * cost - y * sint
	yout[4] = x * sint + y * cost
end


# XP_PYCLIP -- Compute the intersection of an image line with a polygon defined
# by a list of vertices.  The output is a list of ranges stored in the array
# xranges. Two work additional work arrays xintr and slope are required for
# the computation.

int procedure xp_pyclip (xver, yver, xintr, slope, xranges, nver, lx, ld)

real	xver[ARB]		#I the x vertex coords
real	yver[ARB]		#I the y vertex coords
real	xintr[ARB]		#O the array of x intersection points
real	slope[ARB]		#O the array of y slopes at intersection points
real	xranges[ARB]		#O the  x line segments
int	nver			#I the number of vertices
real	lx, ld 			#I the equation of the image line

bool	collinear
int	i, j, nintr, nplus, nzero, nneg, imin, imax, nadd
real	u1, u2, u1u2, dx, dy, dd, xa, wa

begin
	# Compute the intersection points of the image line and the polygon.
	collinear = false
	nplus = 0
	nzero = 0
	nneg = 0
	nintr = 0
	u1 = lx * (- yver[1] + ld)
	do i = 2, nver {

	    u2 = lx * (- yver[i] + ld)
	    u1u2 = u1 * u2

	    # Does the polygon side intersect the image line ?
	    if (u1u2 <= 0.0) {


		# Compute the x intersection coordinate if the point of
		# intersection is not a vertex.

		if ((u1 != 0.0) && (u2 != 0.0)) {

		    dy = yver[i-1] - yver[i]
		    dx = xver[i-1] - xver[i]
		    dd = xver[i-1] * yver[i] - yver[i-1] * xver[i]
		    xa = lx * (dx * ld - dd)
		    wa = dy * lx
		    nintr = nintr + 1
		    xranges[nintr] = xa / wa
		    slope[nintr] = -dy
		    if (slope[nintr] < 0.0)
			nneg = nneg + 1
		    else if (slope[nintr] > 0.0)
			nplus = nplus + 1
		    else
			nzero = nzero + 1
		    collinear = false

		# For each collinear line segment add two intersection
		# points. Remove interior collinear intersection points.

		} else if (u1 == 0.0 && u2 == 0.0) {

		    if (! collinear) {
		        nintr = nintr + 1
			xranges[nintr] = xver[i-1]
			if (i == 2)
			    slope[nintr] = yver[1] - yver[nver-1]
			else
			    slope[nintr] = yver[i-1] - yver[i-2]
		        if (slope[nintr] < 0.0)
			    nneg = nneg + 1
		        else if (slope[nintr] > 0.0)
			    nplus = nplus + 1
		        else
			    nzero = nzero + 1
		        nintr = nintr + 1
		        xranges[nintr] = xver[i]
			slope[nintr] = 0.0
			nzero = nzero + 1
		    } else {
		        xranges[nintr] = xver[i]
			slope[nintr] = 0.0
			nzero = nzero + 1
		    }
		    collinear = true

		# If the intersection point is a vertex add it to the
		# list if it is not collinear with the next point. Add
		# another point to the list if the vertex is at the
		# apex of an acute angle.

		} else if (u1 != 0.0) {

		    if (i == nver) {
		        dx = (xver[2] - xver[nver])
			dy = (yver[2] - yver[nver])
			dd = dy * (yver[nver-1] - yver[nver])
		    } else {
			dx = (xver[i+1] - xver[i])
			dy = (yver[i+1] - yver[i])
			dd = dy * (yver[i-1] - yver[i])
		    }

		    # Test whether the point is collinear with the point
		    # ahead. If it is not include the intersection point. 

		    if (dy != 0.0) {
			nintr = nintr + 1
			xranges[nintr] = xver[i]
			slope[nintr] = yver[i] - yver[i-1]
		        if (slope[nintr] < 0.0)
			    nneg = nneg + 1
		        else if (slope[nintr] > 0.0)
		            nplus = nplus + 1
		        else
			    nzero = nzero + 1
		    }

		    # If the intersection point is an isolated vertex add
		    # another point to the list.

		    if (dd > 0.0) {
			nintr = nintr + 1
			xranges[nintr] = xver[i]
			slope[nintr] = dy
		        if (slope[nintr] < 0.0)
			    nneg = nneg + 1
		        else if (slope[nintr] > 0.0)
		            nplus = nplus + 1
		        else
			    nzero = nzero + 1
		    }

		    collinear = false

		} else
		    collinear = false
	    } else
		collinear = false

	    u1 = u2
	}

	# Join up any split collinear line segments.
	if (collinear && (slope[1] == 0.0)) {
	    xranges[1] = xranges[nintr-1]
	    slope[1] = slope[nintr-1]
	    nintr = nintr - 2
	    nzero = nzero - 2
	}

	# Return the number of intersection points if there are no interior
	# collinear line segments.
	if (nzero == 0 || nplus == 0 || nneg == 0)
	    return (nintr)

	# Find the minimum and maximum intersection points.
	call xp_alimr (xranges, nintr, u1, u2, imin, imax)

	# Check for vertices at the ends of the ranges.

	u1 = xranges[min(imin,imax)] - xranges[1]
	u2 = xranges[nintr] - xranges[max(imin,imax)]

	# Vertices were traversed in order of increasing x.
	if ((u1 >= 0.0 && u2 > 0.0) || (u1 > 0.0 && u2 >= 0.0) ||
	    (u1 == u2 && imax > imin)) {
	    do i = imax + 1, nintr {
		if (xranges[i] != xranges[i-1])
		    break
		imax = i
	    }
	    do i = imin - 1, 1, -1 {
		if (xranges[i] != xranges[i+1])
		    break
		imin = i
	    }
	}

	# Vertices were traversed in order of decreasing x.
	if ((u1 <= 0.0 && u2 < 0.0) || (u1 < 0.0 && u2 <= 0.0) || 
	    (u1 == u2 && imax < imin)) {
	    do i = imin + 1, nintr {
		if (xranges[i] != xranges[i-1])
		    break
		imin = i
	    }
	    do i = imax - 1, 1, -1 {
		if (xranges[i] != xranges[i+1])
		    break
		imax = i
	    }
	}

	# Reorder the x ranges and slopes if necessary. 
	if ((imax < imin) && ! (imin == nintr && imax == 1)) {
	    call amovr (xranges, xintr, nintr)
	    do i = 1, imax
	        xranges[nintr-imax+i] = xintr[i]
	    do i = imin, nintr
	        xranges[i-imax] = xintr[i]
	    call amovr (slope, xintr, nintr)
	    do i = 1, imax
	        slope[nintr-imax+i] = xintr[i]
	    do i = imin, nintr
	        slope[i-imax] = xintr[i]
	} else if ((imin < imax) && ! (imin == 1 && imax == nintr)) {
	    call amovr (xranges, xintr, nintr)
	    do i = 1, imin
		xranges[nintr-imin+i] = xintr[i]
	    do i = imax, nintr
		xranges[i-imin] = xintr[i]
	    call amovr (slope, xintr, nintr)
	    do i = 1, imin
		slope[nintr-imin+i] = xintr[i]
	    do i = imax, nintr
		slope[i-imin] = xintr[i]
	}

	# Add any extra intersection points that are required to deal with
	# the collinear line segments.

	nadd = 0
	for (i = 1; i <= nintr-2; ) {
	    if (slope[i] * slope[i+2] > 0.0) {
		i = i + 2
	    } else {
		nadd = nadd + 1
		xranges[nintr+nadd] = xranges[i+1]
		for (j = i + 3; j <= nintr; j = j + 1) {
		    if (slope[i] * slope[j] > 0)
			break
		    nadd = nadd + 1
		    xranges[nintr+nadd] = xranges[j-1]
		}
		i = j
	    }
	}

	return (nintr + nadd)
end
