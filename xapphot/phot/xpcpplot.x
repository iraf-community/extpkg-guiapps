include <imhdr.h>
include "../lib/contour.h"
include <gio.h>


# XP_CPPLOT -- Display the measured object and plot contours on it.

procedure xp_cpplot (gd, xp, im, xc, yc, width, raster, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
real	xc, yc			#I the x and y center coordinates
real	width			#I width of the extracted region in pixels
int	raster			#I the data raster number
int	wcs			#I the data wcs number

int	j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines, maxrad
pointer	data, pdata, ldata
int	xp_stati()
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

        if (IS_INDEFR(width))
            maxrad = max (xp_stati(xp,ENX), xp_stati(xp,ENY)) / 2 + 1
        else
            maxrad = int (width / 2.0) + 1

	# Compute the subraster limits.
	xcenter = nint (xc)
	ycenter = nint (yc)
	x1 = xcenter - maxrad
	x2 = xcenter + maxrad
	y1 = ycenter - maxrad
	y2 = ycenter + maxrad
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
	 call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	    wcs, NO)

	# Free the data buffers.
	call mfree (data, TY_REAL)
end


# XP_OCPPLOT -- Display the measured object and plot contours on it.

procedure xp_ocpplot (gd, xp, im, xc, yc, width, raster, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
real	xc, yc			#I the input x and y center coordinates
real	width			#I the width of the extracted region in pixels
int	raster			#I the data raster number
int	wcs			#I the data wcs number

int	j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines, maxrad
pointer	data, pdata, ldata
int	xp_stati()
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

        if (IS_INDEFR(width))
            maxrad = max (xp_stati(xp,ENX), xp_stati(xp,ENY)) / 2 + 1
        else
            maxrad = int (width / 2.0) + 1

	# Compute the subraster limits.
	xcenter = nint (xc)
	ycenter = nint (yc)
	x1 = xcenter - maxrad
	x2 = xcenter + maxrad
	y1 = ycenter - maxrad
	y2 = ycenter + maxrad
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
	 call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	    wcs, NO)

	# Free the data buffer.
	call mfree (data, TY_REAL)
end
