include <mach.h>
include <gset.h>
include <gio.h>
include "../lib/contour.h"

# XP_SCNTOUR -- Draw a contour plot of a data subraster.

procedure xp_scntour (gd, xp, data, ncols, nlines, x1, y1, raster, wcs, overlay)
 
pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
real	data[ARB]	#I the input data
int	ncols, nlines	#I the size of the input buffer
int	x1, y1		#I the lower left hand corner of the data
int	raster		#I the raster number
int	wcs		#I the wcs of the data
int	overlay 	#I overlay the plot ?

int	i, x2, y2, fcolor, nhi, dashpat, npts, wkid, ncontours, nset
pointer	sp, data1
real	wx1, wx2, wy1, wy2, vx1, vx2, vy1, vy2
real	floor, ceiling, zero, zmin, zmax, interval, finc
bool	fp_equalr()
int	xp_stati(), gstati()
real	xp_statr()

int	first
int	wcs_save[LEN_WCSARRAY]
common  /conflg/ first
int	isizel, isizem, isizep, nrep, ncrt, ilab, nulbll, ioffd
int	ioffm, isolid, nla, nlm
real	xlt, ybt, side, ext
common  /conre4/ isizel, isizem , isizep, nrep, ncrt, ilab, nulbll, 
         ioffd, ext, ioffm, isolid, nla, nlm, xlt, ybt, side

#common  /noaolb/ hold
#real	hold[5]

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

	if (overlay == NO) {

	    # Initialize the plot.
	    call gclear (gd)

	    # Set the current wcs.
	    call gseti (gd, G_WCS, wcs)
	    wx1 = x1
	    wx2 = x2
	    wy1 = y1
	    wy2 = y2
	    call gsview (gd, 0.0, 1.0, 0.0, 1.0)
	    call gswind (gd, wx1, wx2, wy1, wy2)
	    if (xp_stati (xp, EFILL) == NO)
	        call gsetr (gd, G_ASPECT, real (nlines-1) / real (ncols-1))
	    call gseti (gd, G_ROUND, xp_stati (xp, EROUND))
	    fcolor = gstati (gd, G_FRAMECOLOR)

	} else {

	    call gseti (gd, G_WCS, wcs)
	    call gim_setraster (gd, raster)
	    call ggview (gd, vx1, vx2, vy1, vy2)
	    if (vx1 <= 0.0)
		vx1 = 3.0 * EPSILONR
	    if (vx2 >= 1.0)
		vx2 = 1.0 - 3.0 * EPSILONR
	    if (vy1 <= 0.0)
		vy1 = 3.0 * EPSILONR
	    if (vy2 >= 1.0)
		vy2 = 1.0 - 3.0 * EPSILONR
	    call gsview (gd, vx1, vx2, vy1, vy2)
	    call ggwind (gd, wx1, wx2, wy1, wy2)
	    fcolor = gstati (gd, G_FRAMECOLOR)
	    call gseti (gd, G_FRAMECOLOR, 0)

	}

	if (xp_stati (xp, EBOX) == YES) {

	    # Get number of major and minor tick marks.
	    call gseti (gd, G_XNMAJOR, xp_stati (xp, EXMAJOR))
	    call gseti (gd, G_XNMINOR, xp_stati (xp, EXMINOR))
	    call gseti (gd, G_YNMAJOR, xp_stati (xp, EYMAJOR))
	    call gseti (gd, G_YNMINOR, xp_stati (xp, EYMINOR))

	    # Label tick marks on axes ?
	    call gseti (gd, G_LABELTICKS, xp_stati (xp, ETICKLABEL))
	    call glabax (gd, "\n\n", "", "")
	}

	# Initialize conrec's block data before altering any parameters in
	# common.
	first = 1
	call conbd

	# Set the contouring parameters.
	zero = xp_statr (xp, EZ0)
	floor = xp_statr (xp, EZ1)
	ceiling = xp_statr (xp, EZ2)
	switch (xp_stati (xp, EHILOMARK)) {
	case XP_ENONE:
	    nhi = -1
	case XP_EHILO:
	    nhi = 0
	case XP_EPIXEL:
	    nhi = 1
	default:
	    nhi = -1
	}
	dashpat = xp_stati (xp, EDASHPAT)

	# Resolve INDEF limits.
	npts = ncols * nlines
	if (IS_INDEFR (floor) || IS_INDEFR (ceiling)) {
	    call alimr (data, npts, zmin, zmax)
	    if (IS_INDEFR (floor))
	        floor = zmin
	    if (IS_INDEFR (ceiling))
	        ceiling = zmax
	}
	if (IS_INDEFR(zero))
	    zero = 0.0

	# Apply the zero point shift.
	call smark (sp)
	call salloc (data1, npts, TY_REAL)
	if (abs (zero) > EPSILON) {
	    call asubkr (data, zero, Memr[data1], npts)
	    floor = floor - zero
	    ceiling = ceiling - zero
	} else
	    call amovr (data, Memr[data1], npts)

	# Avoid conrec's automatic scaling.
	if (fp_equalr (floor, 0.0))
	    floor = EPSILON
	if (fp_equalr (ceiling, 0.0))
	    ceiling = EPSILON

	# The user can suppress the contour labelling by setting the common
	# parameter "ilab" to zero.
	if (xp_stati (xp, ELABEL) == NO)
	    ilab = 0
	else
	    ilab = 1

	# User can specify either the number of contours or the contour
	# interval, or let conrec pick a nice number.  Get params and
	# encode the FINC param expected by conrec.

	ncontours = xp_stati (xp, ENCONTOURS)
	if (IS_INDEFI(ncontours)) {
	    interval = xp_statr (xp, EDZ)
	    if (IS_INDEFR(interval))
		finc = 0.0
	    else
		finc = interval
	} else
	    finc = - abs (ncontours)

	call ggview (gd, vx1, vx2, vy1, vy2)
	call gswind (gd, 1., real (ncols), 1., real (nlines))

	# Open device and make contour plot.
	call gopks (STDERR)
	wkid = 1
	call gopwk (wkid, 6, gd)
	call gacwk (wkid)
	nset = 1	# No conrec viewport
	ioffm = 1	# No conrec box
	call set (vx1, vx2, vy1, vy2, 1.0, real (ncols), 1.0, real (nlines),
	    1)
	call conrec (Memr[data1], ncols, ncols, nlines, floor, ceiling, finc,
	    nset, nhi, -dashpat)
	call gdawk (wkid)
	call gclks ()

	# Set the current wcs.
	call gseti (gd, G_WCS, wcs)
	call gswind (gd, wx1, wx2, wy1, wy2)
	call gamove (gd, wx1, wy1)
	call gseti (gd, G_FRAMECOLOR, fcolor)
	#call gadraw (gd, wx1, wy1)
	#call gseti (gd, G_DRAWAXES, NO)
	#call glabax (gd, "\n\n", "", "")
	if (overlay == YES) 
	    call gim_setraster (gd, 0)

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

	call sfree (sp)
end
