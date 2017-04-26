include <imhdr.h>


# XP_MPLOT -- Plot the x and y marginals of the measured object.

procedure xp_mplot (gd, xp, im, xc, yc, radius, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I pointer to the xapphot structure (not used)
pointer	im			#I the pointer to the input image
real	xc, yc			#I the x and y center coordinates
real	radius			#I the radius of subraster to be extracted
int	wcs			#I the data wcs number

int	j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines
pointer	data, pdata, ldata
pointer	imgs2r()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no image.
	if (im == NULL)
	    return 

	# Return if there is no data.
	if (IS_INDEFR(xc) || IS_INDEFR(yc))
	    return 

	# Compute the subraster limits.
	xcenter = nint (xc)
	ycenter = nint (yc)
	x1 = xcenter - radius
	x2 = xcenter + radius + 0.5
	y1 = ycenter - radius
	y2 = ycenter + radius + 0.5

	# Check the limits.
	if (x1 > IM_LEN(im,1) || x2 < 1 || y1 > IM_LEN(im,2) || y2 < 1)
	    return
	x1 = max (1, min (x1, IM_LEN(im,1)))
	x2 = max (1, min (x2, IM_LEN(im,1)))
	ncols = x2 - x1 + 1
	y1 = max (1, min (y1, IM_LEN(im,2)))
	y2 = max (1, min (y2, IM_LEN(im,2)))
	nlines = y2 - y1 + 1

	# Read the data.
	call malloc (data, ncols * nlines, TY_REAL)
        pdata = data
        do j = y1, y2 {
            ldata = imgs2r (im, x1, x2, j, j)
            call amovr (Memr[ldata], Memr[pdata], ncols)
            pdata = pdata + ncols
        }

	# Plot the marginals.
	call xp_smarginals (gd, xp, Memr[data], ncols, nlines, x1, y1,
	    xc, yc, wcs)

	# Free the data.
	call mfree (data, TY_REAL)
end



# XP_OMPLOT -- Plot the x and y marginals of the measured object.

procedure xp_omplot (gd, xp, im, xc, yc, radius, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I pointer to the input image
real	xc, yc			#I the x and y center coordinates
real	radius			#I the radius of the subraster to be extracted
int	wcs			#I the data wcs number

int	j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines
pointer	data, pdata, ldata
pointer	imgs2r()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no image.
	if (im == NULL)
	    return 

	# Return if there is no data.
	if (IS_INDEFR(xc) || IS_INDEFR(yc))
	    return 

	# Compute the subraster limits.
	xcenter = nint (xc)
	ycenter = nint (yc)
	x1 = xcenter - radius
	x2 = xcenter + radius + 0.5
	y1 = ycenter - radius
	y2 = ycenter + radius + 0.5

	# Check the limits.
	if (x1 > IM_LEN(im,1) || x2 < 1 || y1 > IM_LEN(im,2) || y2 < 1)
	    return
	x1 = max (1, min (x1, IM_LEN(im,1)))
	x2 = max (1, min (x2, IM_LEN(im,1)))
	ncols = x2 - x1 + 1
	y1 = max (1, min (y1, IM_LEN(im,2)))
	y2 = max (1, min (y2, IM_LEN(im,2)))
	nlines = y2 - y1 + 1

	# Read the data.
	call malloc (data, ncols * nlines, TY_REAL)
        pdata = data
        do j = y1, y2 {
            ldata = imgs2r (im, x1, x2, j, j)
            call amovr (Memr[ldata], Memr[pdata], ncols)
            pdata = pdata + ncols
        }

	# Contour the subraster.
	call xp_smarginals (gd, xp, Memr[data], ncols, nlines, x1, y1,
	    xc, yc, wcs)

	# Free the data.
	call mfree (data, TY_REAL)
end
