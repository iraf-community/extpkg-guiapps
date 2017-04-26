include <imhdr.h>
include "../lib/objects.h"
include "../lib/impars.h"
include "../lib/phot.h"
include "../lib/contour.h"


# XP_CPDISPLAY -- Display the measured object and plots contours on it.

procedure xp_cpdisplay (gd, xp, im, xc, yc, width, raster, wcs, loadcmap,
	overlay)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
real	xc, yc			#I the x and y center coordinates
real	width			#I the width of the extracted region
int	raster			#I the data raster number
int	wcs			#I the data wcs number
int	loadcmap		#I load the color map ?
int	overlay			#I overlay the subraster with a contour plot ?

int	j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines, maxrad
pointer	data, pdata, ldata
int	xp_stati()
pointer	imgs2r()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
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

	# Display the subraster.
	call xp_sdisplay (gd, xp, im, Memr[data], ncols, nlines, x1, y1,
	    raster, wcs, loadcmap)

	# Mark the aperture.
	#call xp_apmark (gd, xp, xver, yver, nver, raster, wcs)

	# Overlay the contours.
	if (overlay == YES)
	    call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	        wcs, YES)

	# Free the data.
	call mfree (data, TY_REAL)
end


# XP_MPDISPLAY -- Display the measured object and the ellipses computed from
# the moment analysis on it.

procedure xp_mpdisplay (gd, xp, im, xver, yver, nver, max_radius, raster,
	wcs, loadcmap, overlay)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
real	xver[ARB]		#I the x vertices of the object
real	yver[ARB]		#I the y vertices of the object
int	nver			#I the number of object vertices
int	max_radius		#I maximum radius of subraster to be extracted
int	raster			#I the data raster number
int	wcs			#I the data wcs number
int	loadcmap		#I load the color map ?
int	overlay			#I overlay the subraster with a contour plot ?

int	j, xcenter, ycenter, radius, x1, x2, y1, y2, ncols, nlines
pointer	data, pdata, ldata
real	xc, yc, xmin, xmax, ymin, ymax
int	xp_stati()
pointer	xp_statp(), imgs2r()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no data.
	xc = xp_statr (xp, PXCUR)
	yc = xp_statr (xp, PYCUR)
	if (IS_INDEFR(xc) || IS_INDEFR(yc) || xp_stati (xp, NAPIX) <= 0)
	    return 

	# Compute the subraster limits.
	xcenter = nint (xc)
	ycenter = nint (yc)
	if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
	    call alimr (xver, nver, xmin, xmax)
	    call alimr (yver, nver, ymin, ymax)
	    radius = min (int (max ((xmax - xmin) / 2.0, (ymax - ymin) / 2.0)),
	        max_radius)
	} else
	    radius = min (int (xp_statr (xp, ISCALE) *
	        Memr[xp_statp(xp,PAPERTURES)+xp_stati(xp,NAPERTS)-1] + 1),
		max_radius)
	x1 = xcenter - radius
	x2 = xcenter + radius
	y1 = ycenter - radius
	y2 = ycenter + radius
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

	# Display the subraster.
	call xp_sdisplay (gd, xp, im, Memr[data], ncols, nlines, x1, y1,
	    raster, wcs, loadcmap)
	#call xp_mpmark (gd, xp, xver, yver, nver, raster, wcs)
	if (overlay == YES)
	    call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	        wcs, YES)

	# Free the data.
	call mfree (data, TY_REAL)
end


# XP_OCPDISPLAY -- Display the measured list object and plots contours on it.

procedure xp_ocpdisplay (gd, xp, im, xc, yc, width, raster, wcs, loadcmap,
	overlay)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
real	xc, yc			#I the x and y center coordinates
real	width			#I the width of the extracted region in pixels
int	raster			#I the data raster number
int	wcs			#I the data wcs number
int	loadcmap		#I load the color map ?
int	overlay			#I overlay the subraster with a contour plot ?

int     j, xcenter, ycenter, x1, x2, y1, y2, ncols, nlines, maxrad
pointer data, pdata, ldata
int     xp_stati()
pointer imgs2r()


begin
	# Return if there is no graphics stream.
	if (gd == NULL)
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

	# Test the limits against the image.
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

        # Display the subraster.
        call xp_sdisplay (gd, xp, im, Memr[data], ncols, nlines, x1, y1,
            raster, wcs, loadcmap)

	# Mark the aperture.
        #call xp_oapmark (gd, xp, symbol, xver, yver, nver, raster,
	    #wcs)

	# Overlay the contours.
        if (overlay == YES)
            call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	        wcs, YES)

	# Free the data.
	call mfree (data, TY_REAL)
end


# XP_OMPDISPLAY -- Display the measured list object and plots contours on it.

procedure xp_ompdisplay (gd, xp, im, symbol, xver, yver, nver, max_radius,
	raster, wcs, overlay)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main xapphot structure
pointer	im			#I the pointer to the input image
pointer symbol          	#I the current object symbol
real	xver[ARB]		#I the x vertices of the user object
real	yver[ARB]		#I the y vertices of the user object
int	nver			#I the number of user object vertices
int	max_radius		#I the maximum data subraster radius 
int	raster			#I the data raster number
int	wcs			#I the data wcs number
int	loadcmap		#I load the coloar map ?
int	overlay			#I overlay the subraster with a contour plot ?

int     j, xcenter, ycenter, radius, x1, x2, y1, y2, ncols, nlines
pointer sp, str, opsymbol, data, pdata, ldata
real    xc, yc, xmin, xmax, ymin, ymax
int     xp_stati()
pointer stfind(), xp_statp(), imgs2r()
real    xp_statr()


begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no data.
	xc = xp_statr (xp, PXCUR)
	yc = xp_statr (xp, PYCUR)
	if (IS_INDEFR(xc) || IS_INDEFR(yc) || xp_stati (xp, NAPIX) <= 0)
	    return 

	# Return if there is no symbol.
	if (symbol == NULL)
	    return

	# Get the polygon symbol if any.
	if (XP_ONPOLYGON(symbol) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	    call sfree (sp)
	} else
	    opsymbol = NULL

	# Compute the subraster limits.
        xcenter = nint (xc)
        ycenter = nint (yc)
        if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
            call alimr (XP_XVERTICES(opsymbol), XP_ONVERTICES(opsymbol),
	        xmin, xmax)
            call alimr (XP_YVERTICES(opsymbol), XP_ONVERTICES(opsymbol),
	        ymin, ymax)
            radius = min (int (max ((xmax - xmin) / 2.0, (ymax - ymin) / 2.0)),
	        max_radius)
        } else
            radius = min (int (xp_statr (xp, ISCALE) *
                Memr[xp_statp(xp,PAPERTURES)+xp_stati(xp,NAPERTS)-1] + 1),
                max_radius)
	x1 = xcenter - radius
        x2 = xcenter + radius
        y1 = ycenter - radius
        y2 = ycenter + radius

	# Test the limits against the image.
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

        # Display the subraster.
        call xp_sdisplay (gd, xp, im, Memr[data], ncols, nlines, x1, y1,
            raster, wcs, loadcmap)
	#call xp_mpmark (gd, xp, xver, yver, nver, raster, wcs)
        if (overlay == YES)
            call xp_scntour (gd, xp, Memr[data], ncols, nlines, x1, y1, raster,
	        wcs, YES)

	# Free the data.
	call mfree (data, TY_REAL)
end
