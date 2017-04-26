include <mach.h>
include <imhdr.h>
include <gset.h>
include <gim.h>
include <error.h>
include "../lib/displaydef.h"
include "../lib/display.h"
include <gio.h>


# XP_DISPLAY -- Display an image.

procedure xp_display (gd, xp, im, c1, c2, r1, r2, raster, wcs)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main photometry structure
pointer	im			#I the image to be displayed
int	c1, c2			#I the column limits of region to be displayed
int	r1, r2			#I the row limits of region to be displayed
int	raster			#I the raster number
int	wcs			#I the mapping

short	lut1, lut2
int	i, l1, l2, npix, wcs_save[LEN_WCSARRAY]
int	status, ncols, nlines, type, width, height, depth, v, nswath
pointer	sp, r,g, b, pkras, str, data, lutptr
real	scale, dx, dy, pxsize, pysize, sx, sy, sxsize, sysize
real	xflip, yflip, offset, slope, z1, z2

bool	fp_equalr()
int	gim_queryraster(), xp_stati()
pointer	imgs2r(), xp_ulutalloc(), xp_statp()
real	xp_statr(), xp_log10()
extern	xp_log10()
errchk	gim_querymaster(), xp_ulutalloc()

begin
	# Compute the number of columns and lines in the image.
	ncols = c2 - c1 + 1
	nlines = r2 - r1 + 1
	nswath = 65536 / ncols
	if (nswath > 32)
	    nswath = 32
	else
	    nswath = max (1, min (32, nswath - 1))

	# Save the old wcs structure if any.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	call smark (sp)
	call salloc (r, DEF_CNCOLORS, TY_INT)
	call salloc (g, DEF_CNCOLORS, TY_INT)
	call salloc (b, DEF_CNCOLORS, TY_INT)
	#call malloc (pkras, ncols*32, TY_CHAR)
	call malloc (pkras, ncols*nswath, TY_CHAR)

	# Create an image raster.
	if (xp_stati (xp, DERASE) == YES)
	    call gclear (gd)
	call gim_createraster (gd, raster, 0, ncols, nlines, 8)

	# Check the screen raster.
	iferr (status = gim_queryraster (gd, 0, type, width, height, depth)) {
	    call gim_createraster (gd, 0, 0, 640, 480, 8)
	    width = 640
	    height = 480
	} else if (width <= 0 || height <= 0) {
	    call gim_createraster (gd, 0, 0, 512, 512, 8)
	    width = 512
	    height = 512
	}

	# Set the default x andy axis flip parameters.
	xflip = 1.0
	yflip = 1.0

	# Associate a WCS with the raster.
	call gseti (gd, G_WCS, wcs)
	call gseti (gd, G_RASTER, raster)

	# Map the image into the display.
	if (xp_stati (xp, DFILL) == YES) {

	    sx = 0.0
	    sy = 0.0
	    sxsize = real (ncols)
	    sysize = real (nlines)

	    scale = min (real (width) / real (ncols), real (height) /
	        real (nlines))
	    pxsize = real (ncols) * scale / real (width) 
	    pysize = real (nlines) * scale / real (height) 
	    dx = max (0.0, 0.5 - pxsize / 2.0)
	    dy = max (0.0, 0.5 - pysize / 2.0)

	    # Set the viewport, window and mapping.
	    call gswind (gd, real (c1) - 0.5, real (c2) + 0.5, real (r1) - 0.5,
	        real (r2) + 0.5)
	    call gim_setmapping (gd, wcs, 0, raster, CT_PIXEL, sx, sy, sxsize,
	        sysize, 0, CT_NDC, dx, dy, pxsize * xflip, pysize * yflip)

	} else {

	    pxsize = min (xp_statr (xp, DXMAG) * real (ncols),
	        xp_statr (xp, DXVIEWPORT) * real (width))
	    pysize = min (xp_statr (xp, DYMAG) * real (nlines),
	        xp_statr (xp, DYVIEWPORT) * real (height))
	    if (xp_statr (xp, DXMAG) * ncols <= pxsize)
	        sxsize = ncols
	    else
		sxsize = min (pxsize, width * xp_statr (xp, DXVIEWPORT) /
		    xp_statr (xp, DXMAG))
	    if (xp_statr (xp, DYMAG) * nlines <= pysize)
	        sysize = nlines
	    else
		sysize = min (pysize, height * xp_statr (xp, DYVIEWPORT) /
		    xp_statr (xp, DYMAG))
	    sx = max (0.0, (ncols + 1) / 2.0 - sxsize / 2.0)
	    sy = max (0.0, (nlines + 1) / 2.0 - sysize / 2.0)

	    pxsize = pxsize / real (width)
	    pysize = pysize / real (height)
	    dx = max (0.0, 0.5 - pxsize / 2.0) 
	    dy = max (0.0, 0.5 - pysize / 2.0)

	    call gswind (gd, real (c1) - 0.5, real (c2) + 0.5, real (r1) - 0.5,
	        real (r2) + 0.5)
	    call gim_setmapping (gd, wcs, 0, raster, CT_PIXEL, sx, sy, sxsize,
	        sysize, 0, CT_NDC, dx, dy, xflip * pxsize,
	        yflip * pysize)
	}

	# Load a default color map.
	#if (xp_stati (xp, DERASE) == YES) {
	    offset = 0.5
	    #slope = 1.0
	    slope = -1.0
	    do i = 1,  DEF_CNCOLORS {
	        v = DEF_CMAXINTENSITY * (real ((i - 1)) / (DEF_CNCOLORS - 1))
	        Memi[r+i-1] = v; Memi[g+i-1] = v; Memi[b+i-1] = v
	    }
	    call gim_writecolormap (gd, 0, DEF_CZ1, DEF_CNCOLORS, Memi[r],
	        Memi[g], Memi[b])
	    call gim_writecolormap (gd, 1, DEF_CZ1, DEF_CNCOLORS, Memi[r],
	        Memi[g], Memi[b])
	    call gim_loadcolormap (gd, 0, offset, slope)
	    call gim_loadcolormap (gd, 1, offset, slope)
	#}

	# Determine the greylevels limits
	if (xp_stati (xp, DREPEAT) == YES && !IS_INDEFR(xp_statr(xp, DIMZ1)) &&
	    !IS_INDEFR(xp_statr (xp, DIMZ2))) {

	    z1 = xp_statr (xp, DIMZ1)
	    z2 = xp_statr (xp, DIMZ2)

	} else {
	    switch (xp_stati (xp, DZTRANS)) {

	    case XP_DZNONE:
	        z1 = real (DEF_CZ1)
	        z2 = real (DEF_CZ2)

	    case XP_DZLUT:
	        call salloc (str, SZ_FNAME, TY_CHAR)
	        call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
	        iferr {
	            lutptr = xp_ulutalloc (Memc[str], z1, z2)
	        } then {
	            call xp_setp (xp, DLUT, NULL)
	        } else {
	            call xp_setp (xp, DLUT, lutptr)
	        }

	    default:
	        switch (xp_stati (xp, DZLIMITS)) {
	        case XP_DZMEDIAN:
		    call xp_zscale (im, z1, z2, xp_statr (xp, DZCONTRAST),
		        DEF_DSAMPLESIZE, DEF_DSAMPLESIZE / xp_stati (xp,
		        DZNSAMPLE))
	        case XP_DZIMAGE:
		    call xp_imaxmin (im, z1, z2, DEF_DSAMPLESIZE, xp_stati (xp,
		        DZNSAMPLE))
		    if (IS_INDEFR(z1) || IS_INDEFR(z2))
		        call xp_zscale (im, z1, z2, xp_statr (xp, DZCONTRAST),
		            DEF_DSAMPLESIZE, DEF_DSAMPLESIZE / xp_stati (xp,
		            DZNSAMPLE))
	        case XP_DZUSER:
		    z1 = xp_statr (xp, DZ1)
		    z2 = xp_statr (xp, DZ2)
		    if (IS_INDEFR(z1) || IS_INDEFR(z2))
		        call xp_zscale (im, z1, z2, xp_statr (xp, DZCONTRAST),
		            DEF_DSAMPLESIZE, DEF_DSAMPLESIZE / xp_stati (xp,
		            DZNSAMPLE))
	        default:
		    call xp_zscale (im, z1, z2, xp_statr (xp, DZCONTRAST),
		        DEF_DSAMPLESIZE, DEF_DSAMPLESIZE / xp_stati (xp,
		        DZNSAMPLE))
	        }
	    }

	    # Store the graylevel limits.
	    call xp_setr (xp, DIMZ1, z1)
	    call xp_setr (xp, DIMZ2, z2)
	}

	# Load the image.
	#do l1 = r1, r2, 32 {
	do l1 = r1, r2, nswath {
	    #l2 = min (l1 + 32 - 1, r2)
	    l2 = min (l1 + nswath - 1, r2)
	    npix = (l2 - l1 + 1) * ncols
	    data = imgs2r (im, c1, c2, l1, l2)
	    switch (xp_stati (xp, DZTRANS)) {

	    case XP_DZNONE:
		call amapr (Memr[data], Memr[data], npix, z1, z2, z1, z2)
		#call amapr (Memr[data], Memr[data], npix, z2, z1, z1, z2)
	        call achtrb (Memr[data], Memc[pkras], npix)

	    case XP_DZLUT:
		if (xp_statp (xp, DLUT) == NULL) {
		    call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
		    call printf ("Error reading lutfile %s\n")
			call pargstr (Memc[str])
		    break
		} else {
		    call alims (Mems[xp_statp(xp,DLUT)], DEF_UMAXPTS, lut1,
		        lut2)
		    if (lut2 < short (DEF_CZ1) || lut1 > short (DEF_CZ2)) {
		        call printf (
			    "User specified greyscales out of range\n")
			break
		    } else if (z2 < IM_MIN(im) || z1 > IM_MAX(im)) {
		        call printf (
			    "User specified intensities out of range\n")
			break
		    } else {
	                call amapr (Memr[data], Memr[data], npix, z1, z2,
		            real (DEF_UZ1), real (DEF_UZ2))
	                #call amapr (Memr[data], Memr[data], npix, z2, z1,
		            #real (DEF_UZ1), real (DEF_UZ2))
	                call achtrs (Memr[data], Memc[pkras], npix)
		        call aluts (Memc[pkras], Memc[pkras], npix,
		            Mems[xp_statp(xp,DLUT)])
	                call achtsb (Memc[pkras], Memc[pkras], npix)
		    }
		}
	    case XP_DZLOG:
		call amapr (Memr[data], Memr[data], npix, z1, z2, 1.0,
		    10.0 ** DEF_UMAXLOG)
		#call amapr (Memr[data], Memr[data], npix, z2, z1, 1.0,
		    #10.0 ** DEF_UMAXLOG)
		call alogr (Memr[data], Memr[data], npix, xp_log10)
		call amapr (Memr[data], Memr[data], npix, 1.0,
		    real (DEF_UMAXLOG), real (DEF_CZ1), real (DEF_CZ2))
	        call achtrb (Memr[data], Memc[pkras], npix)

	    default:
		if (! fp_equalr (z1, z2))
	            call amapr (Memr[data], Memr[data], npix, z1, z2,
		        real (DEF_CZ1), real (DEF_CZ2))
	            #call amapr (Memr[data], Memr[data], npix, z2, z1,
		        #real (DEF_CZ1), real (DEF_CZ2))
		else
		    call amovkr (real(DEF_CZ1), Memr[data], npix)
	        call achtrb (Memr[data], Memc[pkras], npix)

	    }
	    call gim_writepixels (gd, raster, Memc[pkras], 8, 0, l1 - r1, ncols,
		l2 - l1 + 1)
	}

	# Restore the old wcs array.
	call gflush (gd)
	do i = 1, wcs - 1
	    call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
	        LEN_WCS)
	do i = wcs + 1, MAX_WCS
	    call amovi (wcs_save[1+(i-1)*LEN_WCS], Memi[GP_WCSPTR(gd,i)],
	        LEN_WCS)
	GP_WCSSTATE(gd) = MODIFIED
	call gpl_cache (gd)

	call mfree (pkras, TY_CHAR)
	call sfree (sp)
end


# XP_LOG10 -- The error function for the log.

real procedure xp_log10 (x)

real	x		# the input argument

begin
	return (real(-MAX_EXPONENT))
end
