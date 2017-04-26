include <mach.h>
include <gset.h>
include <gio.h>

# XP_SMARGINALS -- Draw line plots of the marginals of a subraster in x and y.

procedure xp_smarginals (gd, xp, data, ncols, nlines, x1, y1, xc, yc, wcs)
 
pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
real	data[ARB]	#I the input data
int	ncols, nlines	#I the size of the input buffer
int	x1, y1		#I the lower left hand corner of the data
real	xc, yc		#I the center position of the subraster
int	wcs		#I the wcs of the data

int	i, wcs_save[LEN_WCSARRAY]
pointer	sp, x, xm, y, ym
real	xmin, xmax, tymin, tymax, ymin, ymax

begin
	# Check for undefined graphics stream.
	if (gd == NULL) 
	    return

	# Save the pre-existing wcs's if any.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	# Allocate some working space.
	call smark (sp)
	call salloc (x, ncols, TY_REAL)
	call salloc (xm, ncols, TY_REAL)
	call salloc (y, nlines, TY_REAL)
	call salloc (ym, nlines, TY_REAL)

	# Compute the marginal distributions.
	do i = 1, ncols
	    Memr[x+i-1] = x1 + i - 1 - xc
	do i = 1, nlines
	    Memr[y+i-1] = y1 + i - 1 - yc
	xmin = min (Memr[x], Memr[y])
	xmax = max (Memr[x+ncols-1], Memr[y+nlines-1])
	call xp_mkmarg (data, Memr[xm], Memr[ym], ncols, nlines)
	call adivkr (Memr[xm], real (nlines), Memr[xm], ncols)
	call adivkr (Memr[ym], real (ncols), Memr[ym], nlines)
	call alimr (Memr[xm], ncols, ymin, ymax)
	call alimr (Memr[ym], nlines, tymin, tymax)
	ymin = min (ymin, tymin)
	ymax = max (ymax, tymax)

	# Set up the plot.
	call gclear (gd)
	call gseti (gd, G_WCS, wcs)
	call gsview (gd, 3.0*EPSILONR, 1.0-3.0*EPSILONR, 3.0*EPSILONR,
	    1.0-3.0*EPSILONR)
	call gseti (gd, G_DRAWTICKS, NO)

	# Draw the x marginal.
	call gswind (gd, xmin, xmax, ymin, ymax) 
	call glabax (gd, "", "", "")
	call gpline (gd, Memr[x], Memr[xm], ncols)
	call gpmark (gd, Memr[x], Memr[xm], ncols, GM_CROSS, 2.0, 2.0)

	# Draw the y marginal.
	call gswind (gd, ymin, ymax, xmin, xmax) 
	call glabax (gd, "", "", "")
	call gpline (gd, Memr[ym], Memr[y], nlines)
	call gpmark (gd, Memr[ym], Memr[y], nlines, GM_CIRCLE, 2.0, 2.0)

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
