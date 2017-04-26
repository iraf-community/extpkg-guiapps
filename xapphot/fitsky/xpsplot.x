include <gset.h>
include "../lib/fitsky.h"
include <gio.h>


# XP_SPLOT -- Plot the radial profile plot and histogram of the sky pixels.

procedure xp_splot (gd, xp, wcs1, wcs2, wcs3)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the main xapphot structure
int	wcs1			#I the wcs of the first plot
int	wcs2			#I the wcs of the second plot
int	wcs3			#I the wcs of the third plot

int	xp_stati(), xp_sradplot(), xp_spaplot(), xp_shistplot()
pointer	xp_statp()
real	xp_statr()

begin
	# Return if there is no graphics stream.
	if (gd == NULL)
	    return 

	# Return if there is no data.
	if (IS_INDEFR(xp_statr (xp, SXCUR)) || IS_INDEFR(xp_statr(xp, SYCUR)))
	    return

	# Clear the screen.
	call gclear (gd)

	if (xp_stati (xp, NSKYPIX) <= 0)
	    return

	# Set the WCS and viewport for the radial plot.
	call gseti (gd, G_WCS, wcs1)
	call gsview (gd, 0.10, 0.95, 0.72, 0.95)
	if (xp_sradplot (gd,  Memr[xp_statp (xp,SKYPIX)],
	    Memi[xp_statp(xp,SCOORDS)], Memi[xp_statp(xp,SINDEX)+
	    xp_stati(xp,SILO)-1], xp_stati(xp,NSKYPIX)-xp_stati(xp,SILO)+1,
	    xp_statr(xp,SXCUR), xp_statr(xp,SYCUR), xp_statr(xp,SXC),
	    xp_statr(xp,SYC), xp_stati(xp,SNX), xp_stati(xp,SNY),
	    xp_statr(xp,SKY_MODE), xp_statr(xp,SKY_STDEV)) == ERR)
	    ;

	call gseti (gd, G_WCS, wcs2)
	call gsview (gd, 0.10, 0.95, 0.38, 0.62)
	if (xp_spaplot (gd,  Memr[xp_statp(xp, SKYPIX)],
	    Memi[xp_statp(xp,SCOORDS)], Memi[xp_statp (xp,SINDEX)+
	    xp_stati(xp,SILO)-1], xp_stati(xp, NSKYPIX)-xp_stati(xp,SILO)+1,
	    xp_statr(xp,SXCUR), xp_statr(xp,SYCUR), xp_statr(xp,SXC),
	    xp_statr(xp,SYC), xp_stati(xp,SNX), xp_stati(xp,SNY),
	    xp_statr(xp,SKY_MODE), xp_statr(xp,SKY_STDEV)) == ERR)
	    ;

	# Set the WCS and viewport for the histogram plot.
	call gseti (gd, G_WCS, wcs3)
	call gsview (gd, 0.10, 0.95, 0.05, 0.28)
	call amovkr (1.0, Memr[xp_statp(xp,SWEIGHTS)], xp_stati (xp,NSKYPIX))
	if (xp_shistplot (gd,  Memr[xp_statp (xp, SKYPIX)],
	    Memr[xp_statp(xp,SWEIGHTS)], Memi[xp_statp(xp,SINDEX)+
	    xp_stati(xp,SILO)-1], xp_stati(xp,NSKYPIX)-xp_stati(xp,SILO)+1,
	    xp_statr(xp,SHWIDTH), INDEFR, xp_statr(xp,SHBINSIZE),
	    xp_stati(xp,SHSMOOTH), xp_statr(xp,SKY_MODE),
	    xp_statr(xp,SKY_STDEV)) == ERR)
	    ;
end


define	HPLOT_LINE	1
define	HPLOT_BOX	2


# XP_SHISTPLOT -- Plot the histogram of the sky pixels.

int procedure xp_shistplot (gd, skypix, wgt, index, nskypix, k1, hwidth,
	binsize, smooth, sky_mode, sky_sigma)

pointer	gd			#I the pointer to graphics stream
real	skypix[ARB]		#I the array of unsorted sky pixels
real	wgt[ARB]		#I the array of weights for rejection
int	index[ARB]		#I the array of sort indices
int	nskypix			#I the  number of sky pixels
real	k1			#I the ksigma rejection criterion
real	hwidth			#I the half-width of the histogram in k1 units
real	binsize			#I the histogram bin size in sigma
int	smooth			#I smooth the histogram ?
real	sky_mode		#I the computed  sky value
real	sky_sigma		#I the computed sky sigma

double	dsky, sumpx, sumsqpx, sumcbpx
int	i, nsky, nreject, nbins, nker
pointer	sp, x, hgm, shgm
real	sky_zero, hmin, hmax, dh, dmin, dmax, mean, median, sigma, skew, cut
real	ymin, ymax, symin, symax
int	xp_higmr()
real	xp_asumr(), xp_medr()

begin
	# Check that there is a list of sky pixels.
	if (nskypix <= 0)
	    return (ERR)

	# Compute the median of the sky pixels.
	sky_zero = xp_asumr (skypix, index, nskypix) / nskypix
	call xp_ialimr (skypix, index, nskypix, dmin, dmax)
	call xp_fimoments (skypix, index, nskypix, sky_zero, sumpx, sumsqpx,
	    sumcbpx, mean, sigma, skew)
	median = xp_medr (skypix, index, nskypix)
	median = max (dmin, min (median, dmax))
	nreject = 0

	# Compute histogram width and binsize.
	if (! IS_INDEFR(hwidth) && hwidth > 0.0) {
	    hmin = median - k1 * hwidth
	    hmax = median + k1 * hwidth
	    dh = binsize * hwidth
	} else {
	    cut = min (median - dmin, dmax - median, k1 * sigma)
	    hmin = median - cut
	    hmax = median + cut
	    dh = binsize * cut / k1
	}

	# Compute the number of histgram bins and the histogram resolution.
	if (dh <= 0.0) {
	    nbins = 1
	    dh = 0.0
	} else {
	    nbins = 2 * nint ((hmax - median) / dh) + 1
	    dh = (hmax - hmin) / (nbins - 1)
	}

	# Test for a valid histogram.
	if (dh <= 0.0 || k1 <= 0.0 || sigma <= 0.0 || sigma <= dh ||
	    nbins < 2)
	    return (ERR)

	# Allocate temporary space.
	call smark (sp)
	call salloc (x, nbins, TY_REAL)
	call salloc (hgm, nbins, TY_REAL)
	call salloc (shgm, nbins, TY_REAL)

	# Compute the x array and accumulate the histogram.
	do i = 1, nbins
	    Memr[x+i-1] = i
	call amapr (Memr[x], Memr[x], nbins, 1.0, real (nbins),
	    hmin + 0.5 * dh, hmax + 0.5 * dh) 
	call aclrr (Memr[hgm], nbins)
	nreject = nreject + xp_higmr (skypix, wgt, index, nskypix, Memr[hgm],
	    nbins, hmin, hmax)
	nsky = nskypix - nreject

	# Subtract the rejected pixels and recompute the moments.
	if (nreject > 0) {
	    do i = 1, nskypix {
		if (wgt[index[i]] <= 0.0) {
		    dsky = skypix[index[i]] - sky_zero
		    sumpx = sumpx - dsky
		    sumsqpx = sumsqpx - dsky ** 2
		    sumcbpx = sumcbpx - dsky ** 3
		}
	    }
	    call xp_moments (sumpx, sumsqpx, sumcbpx, nsky, sky_zero, mean,
	        sigma, skew)
	}

	# Smooth the histogram and compute the histogram plot limits.
	if (smooth == YES) {
	    nker = max (1, nint (sigma / dh))
	    #call xp_lucy_smooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call xp_bsmooth (Memr[hgm], Memr[shgm], nbins, nker, 2)
	    call alimr (Memr[hgm], nbins, ymin, ymax)
	    call alimr (Memr[shgm], nbins, symin, symax)
	    ymin = min (ymin, symin)
	    ymax = max (ymax, symax)
	} else
	    call alimr (Memr[hgm], nbins, ymin, ymax)

	# Plot the raw and smoothed histograms.
	call xp_ishplot (gd, hmin, hmax, ymin, ymax, nbins, dh)
	if (smooth == YES) {
	    call xp_hsplot (gd, Memr[x], Memr[hgm], nbins, dh, HPLOT_BOX,
	        GL_SOLID)
	    call xp_hsplot (gd, Memr[x], Memr[shgm], nbins, dh, HPLOT_LINE,
	        GL_SOLID)
	} else
	    call xp_hsplot (gd, Memr[x], Memr[hgm], nbins, dh, HPLOT_BOX,
	        GL_SOLID)

	if (! IS_INDEFR(sky_mode) && ! IS_INDEFR(sky_mode)) {
	    call gamove (gd, sky_mode, ymin)
	    call gadraw (gd, sky_mode, ymax)
	    call gseti (gd, G_PLTYPE, GL_DASHED)
	    call gamove (gd, sky_mode - sky_sigma, ymin)
	    call gadraw (gd, sky_mode - sky_sigma, ymax)
	    call gamove (gd, sky_mode + sky_sigma, ymin)
	    call gadraw (gd, sky_mode + sky_sigma, ymax)
	    call gseti (gd, G_PLTYPE, GL_SOLID)
	}

	call gflush (gd)

	# Close up.
	call sfree (sp)

	return (OK)
end


# XP_ISHPLOT -- Set up the axes labels and window for the histogram plot.

procedure xp_ishplot (gd, xmin, xmax, ymin, ymax, nbins, dh)

pointer	gd		#I the pointer to the graphics stream
real	xmin, xmax	#I the minimum and maximum of the histogram values
real	ymin, ymax	#I the minimum and maximum of the histogram
int	nbins		#I the number of bins
real	dh		#I the bin size

pointer	sp, title

begin
	# Initialize
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)

	# Set the plot title.
	call sprintf (Memc[title], SZ_LINE,
	    "Sky Histogram: nbins = %d hmin = %g hmax = %g dh = %g\n\n")
	    call pargi (nbins)
	    call pargr (xmin)
	    call pargr (xmax)
	    call pargr (dh)

	# Set the plot axes.
	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Sky Value", "Number of Pixels")
	call glabax (gd, Memc[title], "", "")

	call sfree (sp)
end


# XP_HSPLOT -- Plot the histogram.

procedure xp_hsplot (gd, x, hgm, nbins, dh, plot_type, poly_type) 

pointer	gd		#I the pointer to graphics stream
real	x[ARB]		#I the histogram bin values
real	hgm[ARB]	#I the histogram values
int	nbins		#I the number of bins
real	dh		#I the histogram bin width
int	plot_type	#I the plot type, "box" or "line"
int	poly_type	#I the polyline type

begin
	call gseti (gd,  G_PLTYPE, poly_type)

	switch (plot_type) {
	case HPLOT_LINE:
	    call gvline (gd, hgm, nbins, x[1], x[nbins])
	case HPLOT_BOX:
	    call xp_hbox (gd, hgm, nbins, x[1] - dh / 2.0, x[nbins] + dh / 2.0)
	default:
	    call gvline (gd, hgm, nbins, x[1], x[nbins])
	}
	call gflush (gd)
end


# XP_HBOX -- Draw a stepped curve of the histogram data.

procedure xp_hbox (gp, ydata, npts, x1, x2)

pointer gp              #I the graphics descriptor
real    ydata[ARB]      #I the y coordinates of the line endpoints
int     npts            #I the number of line endpoints
real    x1, x2		#I the starting and ending x coordinates

int     pixel
real    left, right, top, bottom, x, y, dx

begin
        call ggwind (gp, left, right, bottom, top)
        dx = (x2 - x1) / npts

        # Do the first vertical line.
        call gamove (gp, x1, bottom)
        call gadraw (gp, x1, ydata[1])

        # Do the first horizontal line.
        call gadraw (gp, x1 + dx, ydata[1])

        # Draw the remaining horizontal lines.
        do pixel = 2, npts {
            x = x1 + dx * (pixel - 1)
            y = ydata[pixel]
            call gadraw (gp, x, y)
            call gadraw (gp, x + dx, y)
        }

        # Draw the last vertical line.
        call gadraw (gp, x + dx, bottom)
end



# XP_SRADPLOT -- Compute a radial profile plot for the sky pixels.

int procedure xp_sradplot (gd, skypix, coords, index, nskypix, wxc, wyc, xc, yc,
        nx, ny, sky_mode, sky_sigma)

pointer	gd			#I the pointer to graphics stream
real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the array of sky coordinates
int	index[ARB]		#I the sky pixels sort index  array
int	nskypix			#I the number of sky pixels
real	wxc, wyc		#I the world center of symmetry of sky pixels 
real	xc, yc			#I the center of symmetry of the sky pixels
int	nx, ny			#I the extent of the sky pixels
real	sky_mode		#I the  sky value
real	sky_sigma		#I the sky sigma

pointer	sp, r
real	xmin, xmax, ymin, ymax

begin
	# Check that there is a list of sky pixels.
	if (nskypix <= 0)
	    return (ERR)

	# Allocate working space
	call smark (sp)
	call salloc (r, nskypix, TY_REAL)

	# Compute the radii.
	call xp_sxytor (coords, index, Memr[r], nskypix, xc, yc, nx, ny) 
	call alimr (Memr[r], nskypix, xmin, xmax)
	call alimr (skypix, nskypix, ymin, ymax)

	# Plot the data.
	call xp_irsset (gd, wxc, wyc, xmin, xmax, ymin, ymax)
	call xp_sxyplot (gd, Memr[r], skypix, nskypix, GM_PLUS, xmin, xmax,
	    sky_mode, sky_sigma)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_IRSSET -- Set up the axes window and labelling for the radial distance
# plot of the sky pixels.

procedure xp_irsset (gd, xc, yc, xmin, xmax, ymin, ymax)

pointer	gd		#I the pointer to the graphics stream
real	xc, yc		#I the center of symmetry
real	xmin		#I the minimum x coordinate value
real	xmax		#I the maximum x coordinate value
real	ymin		#I the minimum y coordinate value
real	ymax		#I the maximum y coordinate value

pointer	sp, title

begin
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)

	call sprintf (Memc[title],
	    SZ_LINE, "Sky Radial Profile at %.2f %.2f\n\n") 
	    call pargr (xc)
	    call pargr (yc)

	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Radial Disance (pixels)", "Counts")
	call glabax (gd, Memc[title], "", "")

	call sfree (sp)
end


# XP_SPAPLOT -- Compute a position angle plot for the sky pixels.

int procedure xp_spaplot (gd, skypix, coords, index, nskypix, wxc, wyc,
	xc, yc, nx, ny, sky_mode, sky_sigma)

pointer	gd			#I the graphics descriptor
real	skypix[ARB]		#I the array of unsorted sky pixels
int	coords[ARB]		#I the sky coordinates array
int	index[ARB]		#I the sky pixels sort index array
int	nskypix			#I the number of sky pixels
real	wxc, wyc		#I the world center of symmetry of sky pixels
real	xc, yc			#I the center of symmetry of sky pixels
int	nx, ny			#I the extent of the sky pixels
real	sky_mode		#I the sky value
real	sky_sigma		#I the sigma of the sky

pointer	sp, pa
real	ymin, ymax

begin
	# Check that there is a list of sky pixels.
	if (nskypix <= 0)
	    return (ERR)

	# Allocate working space
	call smark (sp)
	call salloc (pa, nskypix, TY_REAL)

	# Compute the position angles.
	call xp_sxytoe (coords, index, Memr[pa], nskypix, xc, yc, nx, ny) 

	# Compute the plot limits
	call alimr (skypix, nskypix, ymin, ymax)
	call xp_ipaset (gd, wxc, wyc, 0.0, 360.0, ymin, ymax)
	call xp_sxyplot (gd, Memr[pa], skypix, nskypix, GM_PLUS, 0.0, 360.0,
	    sky_mode, sky_sigma)
	call gflush (gd)

	call sfree (sp)

	return (OK)
end


# XP_IPASET -- Set up the axes window and labelling for the position angle
# plot of the sky pixels.

procedure xp_ipaset (gd, xc, yc, xmin, xmax, ymin, ymax)

pointer	gd		#I the pointer to the graphics stream
real	xc, yc		#I the center of symmetry
real	xmin		#I the minimum x coordinate value
real	xmax		#I the maximum x coordinate value
real	ymin		#I the minimum y coordinate value
real	ymax		#I the maximum y coordinate value

pointer	sp, title

begin
	call smark (sp)
	call salloc (title, SZ_LINE, TY_CHAR)

	call sprintf (Memc[title], SZ_LINE,
	    "Sky Position Angle Profile at %.2f %.2f\n\n") 
	    call pargr (xc)
	    call pargr (yc)

	call gswind (gd, xmin, xmax, ymin, ymax)
	call xp_rgfill (gd, xmin, xmax, ymin, ymax, GF_SOLID, 0)
	call gseti (gd, G_YNMINOR, 0)
	#call glabax (gd, Memc[title], "Position Angle (degrees)", "Counts")
	call glabax (gd, Memc[title], "", "")

	call sfree (sp)
end


# XP_SXYPLOT -- Plot the x and y points.

procedure xp_sxyplot (gd, x, y, npts, marker, xmin, xmax, sky_mode, sky_sigma)

pointer	gd		#I the pointer to the graphics stream
real	x[ARB]		#I the x coordinates
real	y[ARB]		#I the y coordinates
int	npts		#I the number of points to be marked
int	marker		#I the point marker type
real	xmin		#I the minimum x coordinate
real	xmax		#I the maximum x coordinate
real	sky_mode	#I the sky value
real	sky_sigma	#I the sky sigma

int	i

begin
	# Plot the points.
	do i = 1, npts
	    call gmark (gd, x[i], y[i], marker, 1.0, 1.0)

	# Plot the sky and three sigma sky levels.
	if (! IS_INDEFR(sky_mode) && ! IS_INDEFR (sky_sigma)) {
	    call gamove (gd, xmin, sky_mode) 
	    call gadraw (gd, xmax, sky_mode) 
	    call gseti (gd, G_PLTYPE, GL_DASHED)
	    call gamove (gd, xmin, sky_mode - sky_sigma) 
	    call gadraw (gd, xmax, sky_mode - sky_sigma) 
	    call gamove (gd, xmin, sky_mode + sky_sigma) 
	    call gadraw (gd, xmax, sky_mode + sky_sigma) 
	    call gseti (gd, G_PLTYPE, GL_SOLID)
	}
end
