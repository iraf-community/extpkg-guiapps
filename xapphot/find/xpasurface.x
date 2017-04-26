include <mach.h>
include <gset.h>
include <gio.h>
include "../lib/surface.h"

define	CSIZE		24

# XP_ASURFACE -- Draw a perspective view of a surface.  The altitude
# and azimuth of the viewing angle are variable.
 
procedure xp_asurface (gd, xp, data, ncols, nlines, x1, y1, raster, wcs)
 
pointer	gd		#I the pointer to the graphics stream
pointer xp              #I the pointer to the main xapphot structure
real    data[ARB]       #I the input data
int     ncols, nlines   #I the size of the input buffer
int     x1, y1          #I the lower left hand corner of the data
int     raster          #I the raster number
int     wcs             #I the wcs of the data

int	i, x2, y2, npts, wkid
pointer	sp, sdata, work
real	floor, ceiling, angv, angh
int     wcs_save[LEN_WCSARRAY]
int	xp_stati()
real	xp_statr()

int	first
real	 vpx1, vpx2, vpy1, vpy2
common  /frstfg/ first
common  /noaovp/ vpx1, vpx2, vpy1, vpy2
 
begin
	# Check for undefined graphics stream.
	if (gd == NULL)
	    return

        # Save the pre-existing wcs's if any.
        call gflush (gd)
        call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

        # Get the coordinates of the upper right section of the data.
        x2 = x1 + ncols - 1
        y2 = y1 + nlines - 1

	call smark (sp)

	# Initialize the plot.
	call gclear (gd)

	# Set the viewport and wcs and turn off axes drawing.
	#call gsview (gd, 0.1, 0.9, 0.1, 0.9)
	call gsview (gd, 0.0, 1.0, 0.0, 1.0)
	call gseti (gd, G_DRAWAXES, NO)
	call glabax (gd, "", "", "")

	npts = ncols * nlines
	call smark (sp)
	call salloc (sdata, npts, TY_REAL)
	call amovr (data, Memr[sdata], npts)

	# Take floor and ceiling if enabled (nonzero).
	floor = xp_statr (xp, AZ1)
	ceiling = xp_statr (xp, AZ2)
	if (! IS_INDEFR (floor) || ! IS_INDEFR (ceiling)) {
	    if (! IS_INDEFR (floor) && ! IS_INDEFR (ceiling)) {
		floor = min (floor, ceiling)
		ceiling = max (floor, ceiling)
	    }
	    if (! IS_INDEFR (floor))
		call amaxkr (Memr[sdata], floor, Memr[sdata], npts)
	    if (! IS_INDEFR (ceiling))
		call aminkr (Memr[sdata], ceiling, Memr[sdata], npts)
	}

	# Open graphics device and make plot.
	call gopks (STDERR)
	wkid = 1
	call gopwk (wkid, 6, gd)
	call gacwk (wkid)

	first = 1
	call srfabd()
	call ggview (gd, vpx1, vpx2, vpy1, vpy2)
	call set (vpx1, vpx2, vpy1, vpy2, 1.0, 1024., 1.0, 1024., 1)

	angh = xp_statr(xp,ANGH)
	angv = xp_statr(xp,ANGV)
	call salloc (work, 2*(2*ncols*nlines+ncols+nlines), TY_REAL)
	call ezsrfc (Memr[sdata], ncols, nlines, angh, angv, Memr[work])

	if (xp_stati (xp, ALABEL) == YES) {
	    call gswind (gd, real (x1), real (x2), real (y1), real (y2))
	    call gseti (gd, G_CLIP, NO)
	    call xp_perimeter (gd, Memr[sdata], ncols, nlines, angh, angv)
	}

	call gdawk (wkid)
	call gclks ()
	call sfree (sp)

        # Restore the existing wcs if necessary.
        call gflush (gd)
        do i = 1, wcs - 1
            call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
                LEN_WCS)
        do i = wcs + 1, MAX_WCS
            call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
                LEN_WCS)
        GP_WCSSTATE(gd) = MODIFIED
        call gpl_cache (gd)

end


# XP_PERIMETER -- Draw and label axes around the surface plot.

procedure xp_perimeter (gd, z, ncols, nlines, angh, angv)

pointer	gd			#I the graphics pointer
int	ncols			#I the number of image columns
int	nlines			#I the number of image lines
real	z[ncols, nlines]	#I the array of intensity values
real	angh			#I the angle of horizontal inclination
real	angv			#I the angle of vertical inclination

char	tlabel[10]
int	i, j
pointer	sp, x_val, y_val, kvec
real	xmin, ymin, delta, fact1, flo, hi, xcen, ycen
real	x1_perim, x2_perim, y1_perim, y2_perim, z1, z2
real	wc1, wc2, wl1, wl2, del
int	itoc()

data  	fact1 /2.0/
real	vpx1, vpx2, vpy1, vpy2
common	/noaovp/ vpx1, vpx2, vpy1, vpy2

begin
	call smark (sp)
	call salloc (x_val, ncols + 2, TY_REAL)
	call salloc (y_val, nlines + 2, TY_REAL)
	call salloc (kvec, max (ncols, nlines) + 2, TY_REAL)

	# Get window coordinates set up calling procedure.
	call ggwind (gd, wc1, wc2, wl1, wl2)

	# Set up window, viewport for output.  The coordinates returned
	# from trn32s are in the range [1-1024].
	call set (vpx1, vpx2, vpy1, vpy2, 1.0, 1024., 1.0, 1024., 1)

	# Find range of z for determining perspective.
	flo = MAX_REAL
	hi = -flo
	do j = 1, nlines {
	    call alimr (z[1,j], ncols, z1, z2)
	    flo = min (flo, z1)
	    hi = max (hi, z2)
	}

	# Set up linear endpoints and spacing as used in surface.
        delta = (hi-flo) / (max (ncols, nlines) -1.) * fact1
        xmin = -(real (ncols/2)  * delta + real (mod (ncols+1, 2))  * delta)
        ymin = -(real (nlines/2) * delta + real (mod (nlines+1, 2)) * delta)
	del = 2.0 * delta

	# The perimeter is separated from the surface plot by the 
	# width of delta.  
	x1_perim = xmin - delta
	y1_perim = ymin - delta
	x2_perim = xmin + (real (ncols)  * delta)
	y2_perim = ymin + (real (nlines) * delta)

	# Set up linear arrays over full perimeter range.
	do i = 1, ncols + 2
	    Memr[x_val+i-1] = x1_perim + (i-1) * delta
	do i = 1, nlines + 2
	    Memr[y_val+i-1] = y1_perim + (i-1) * delta

	# Draw and label axes and tick marks.
	# It is important that frame has not been called after calling srface.
	# First to draw the perimeter.  Which axes get drawn depends on the
	# values of angh and angv.  Get angles in the range [-180, 180].

	if (angh > 180.)
	    angh = angh - 360.
	else if (angh < -180.)
	    angh = angh + 360.
	if (angv > 180.)
	    angv = angv - 360.
	else if (angv < -180.)
	    angv = angv + 360.

	# Calculate positions for the axis labels.
	xcen = 0.5 * (x1_perim + x2_perim)
	ycen = 0.5 * (y1_perim + y2_perim)

	if (angh >= 0.0) {

	    # Case 1: xy rotation positive, looking down from above mid z.
	    if (angv >= 0.0) {

		# First draw x axis.
		call amovkr (y2_perim, Memr[kvec], ncols + 2)
		call xp_draw_axis (Memr[x_val+1], Memr[kvec], flo, ncols + 1)
		call xp_label_axis (xcen, y2_perim+del, flo, "X-AXIS", -1, -2)
		call xp_draw_ticksx (Memr[x_val+1], y2_perim, y2_perim+delta, 
		    flo, ncols)
		if (itoc (int (wc1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (xmin, y2_perim+del, flo, tlabel, -1, -2)
		if (itoc (int (wc2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (Memr[x_val+ncols], y2_perim+del, flo, 
		    tlabel, -1, -2)

		# Now draw y axis.
		call amovkr (x2_perim, Memr[kvec], nlines + 2)
		call xp_draw_axis (Memr[kvec], Memr[y_val+1], flo, nlines + 1)
		call xp_label_axis (x2_perim+del, ycen, flo, "Y-AXIS", 2, -1)
		call xp_draw_ticksy (x2_perim, x2_perim+delta, Memr[y_val+1],
		    flo, nlines)
		if (itoc (int (wl1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x2_perim+del, ymin, flo, tlabel, 2, -1)
		if (itoc (int (wl2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x2_perim+del, Memr[y_val+nlines], flo, 
		    tlabel, 2, -1)

	    # Case 2: xy rotation positive, looking up from below mid z.
	    } else {

		# First draw x axis.
		call amovkr (y1_perim, Memr[kvec], ncols + 2)
		call xp_draw_axis (Memr[x_val], Memr[kvec], flo, ncols + 1)
		call xp_label_axis (xcen, y1_perim-del, flo, "X-AXIS", -1, 2)
		call xp_draw_ticksx (Memr[x_val+1], y1_perim, y1_perim-delta, 
		    flo, ncols)
		if (itoc (int (wc1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (xmin, y1_perim-del, flo, tlabel, -1, 2)
		if (itoc (int (wc2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (Memr[x_val+ncols], y1_perim-del, flo, 
		    tlabel, -1, 2)

		# Now draw y axis.
		call amovkr (x1_perim, Memr[kvec], nlines + 2)
		call xp_draw_axis (Memr[kvec], Memr[y_val], flo, nlines + 1)
		call xp_label_axis (x1_perim-del, ycen, flo, "Y-AXIS", 2, 1)
		call xp_draw_ticksy (x1_perim, x1_perim-delta, Memr[y_val+1],
		    flo, nlines)
		if (itoc (int (wl1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x1_perim-del, ymin, flo, tlabel, 2, 1)
		if (itoc (int (wl2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x1_perim-del, Memr[y_val+nlines], flo, 
		    tlabel, 2, 1)
	    }
	}

	if (angh < 0.0) {

	    # Case 3: xy rotation negative, looking down from above  mid z 
	    # (default).
	    if (angv > 0.0) {

		# First draw x axis.
		call amovkr (y1_perim, Memr[kvec], ncols + 2)
		call xp_draw_axis (Memr[x_val+1], Memr[kvec], flo, ncols + 1)
		call xp_label_axis (xcen, y1_perim-del, flo, "X-AXIS", 1, 2)
		call xp_draw_ticksx (Memr[x_val+1], y1_perim, y1_perim-delta, 
		    flo, ncols)
		if (itoc (int (wc1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (xmin, y1_perim-del, flo, tlabel, 1, 2)
		if (itoc (int (wc2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (Memr[x_val+ncols], y1_perim-del, flo, 
		    tlabel, 1, 2)

		# Now draw y axis.
		call amovkr (x2_perim, Memr[kvec], nlines + 2)
		call xp_draw_axis (Memr[kvec], Memr[y_val], flo, nlines + 1)
		call xp_label_axis (x2_perim+del, ycen, flo, "Y-AXIS", 2, -1)
		call xp_draw_ticksy (x2_perim, x2_perim+delta, Memr[y_val+1],
		    flo, nlines)
		if (itoc (int (wl1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x2_perim+del, ymin, flo, tlabel, 2, -1)
		if (itoc (int (wl2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x2_perim+del, Memr[y_val+nlines], flo, 
		    tlabel, 2, -1)

	    # Case 4: xy rotation negative, looking up from below mid Z.
	    } else {

		# First draw x axis.
		call amovkr (y2_perim, Memr[kvec], ncols + 2)
		call xp_draw_axis (Memr[x_val], Memr[kvec], flo, ncols + 1)
		call xp_label_axis (xcen, y2_perim+del, flo, "X-AXIS", 1, -2)
		call xp_draw_ticksx (Memr[x_val+1], y2_perim, y2_perim+delta,
		    flo, ncols)
		if (itoc (int (wc1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (xmin, y2_perim+del, flo, tlabel, 1, -2)
		if (itoc (int (wc2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (Memr[x_val+ncols], y2_perim+del, flo, 
		    tlabel, 1, -2)

		# Now draw y axis.
		call amovkr (x1_perim, Memr[kvec], nlines + 2)
		call xp_draw_axis (Memr[kvec], Memr[y_val+1], flo, nlines + 1)
		call xp_label_axis (x1_perim-del, ycen, flo, "Y-AXIS", 2, 1)
		call xp_draw_ticksy (x1_perim, x1_perim-delta, Memr[y_val+1],
		    flo, nlines)
		if (itoc (int (wl1), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x1_perim-del, ymin, flo, tlabel, 2, 1)
		if (itoc (int (wl2), tlabel, 10) <= 0)
		    tlabel[1] = EOS
		call xp_label_axis (x1_perim-del, Memr[y_val+nlines], flo, 
		    tlabel, 2, 1)
	    }
	}

	# Flush plotit buffer before returning.
	call plotit (0, 0, 2)
	call sfree (sp)
end


# XP_DRAW_AXIS -- Draw the axes around the plot.

procedure xp_draw_axis (xvals, yvals, zval, nvals)

real	xvals[nvals]			#I the input x coordinates
real	yvals[nvals]			#I the input y coordinates
real	zval				#I the input contour value
int	nvals                           #I the number of x and y values

int	i
pointer	sp, xt, yt
real	dum

begin
	call smark (sp)
	call salloc (xt, nvals, TY_REAL)
	call salloc (yt, nvals, TY_REAL)

	do i = 1, nvals 
	    call trn32s (xvals[i], yvals[i], zval, Memr[xt+i-1], Memr[yt+i-1], 
		dum, 1)

	call gpl (nvals, Memr[xt], Memr[yt])
	call sfree (sp)
end


# XP_LABEL_AXIS -- Label the axes.

procedure xp_label_axis (xval, yval, zval, sppstr, path, up)

real	xval				#I the input x coordinate
real	yval				#I the input y coordinate
real	zval				#I the input contour value
char	sppstr[SZ_LINE]			#I the input spp string
int	path				#I
int	up				#I

int	nchars
int	strlen()
%	character*64 fstr

begin
	nchars = strlen (sppstr)
%	call f77pak (sppstr, fstr, 64)
    	call pwrzs (xval, yval, zval, fstr, nchars, CSIZE, path, up, 0)
end


# XP_DRAW_TICKSX -- Draw the x tick marks.

procedure xp_draw_ticksx (x, y1, y2, zval, nvals)

real	x[nvals]			#I the input x tick coordinates
real	y1, y2				#I the input y tick coordinates
real	zval				#I the contour level
int	nvals				#I the number of tick marks

int	i
real	tkx[2], tky[2], dum

begin
	do i = 1, nvals {
	    call trn32s (x[i], y1, zval, tkx[1], tky[1], dum, 1)
	    call trn32s (x[i], y2, zval, tkx[2], tky[2], dum, 1)
	    call gpl (2, tkx[1], tky[1])
	}
end


# XP_DRAW_TICKSY -- Draw the y tick marks.

procedure xp_draw_ticksy (x1, x2, y, zval, nvals)

real	x1, x2				#I the input x tick coordinates
real	y[nvals]			#I the input y tick coordinates
real	zval				#I the contour level
int	nvals				#I the number of tick marks

int	i
real	tkx[2], tky[2], dum

begin
	do i = 1, nvals {
	    call trn32s (x1, y[i], zval, tkx[1], tky[1], dum, 1)
	    call trn32s (x2, y[i], zval, tkx[2], tky[2], dum, 1)
	    call gpl (2, tkx[1], tky[1])
	}
end
