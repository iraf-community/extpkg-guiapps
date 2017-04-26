include <imhdr.h>
include <gset.h>
include <gim.h>
include <error.h>
include "../lib/displaydef.h"
include "../lib/display.h"
include <gio.h>

# XP_SDISPLAY -- Display a section of an image. 

procedure xp_sdisplay (gd, xp, im, buffer, ncols, nlines, c1, r1, raster, wcs,
	loadcmap)

pointer	gd			#I the graphics stream descriptor
pointer	xp			#I the pointer to the main photometry structure
pointer	im			#I the pointer to the input image
real	buffer[ARB]		#I the image to be displayed
int	ncols, nlines		#I the size of image buffer
int	c1, r1			#I the coordinates of the lower left corner
int	raster			#I the raster number
int	wcs			#I the mapping
int	loadcmap		#I load the color map ?

short	lut1, lut2
int	i, stat, npix
int	status, c2, r2, type, width, height, depth, wcs_save[LEN_WCSARRAY]
pointer	sp, pkras, str, lutptr
real	scale, dx, dy, pxsize, pysize, sx, sy, sxsize, sysize
real	xflip, yflip, z1, z2

int	v
pointer	r, g, b
real	slope, offset

bool	fp_equalr()
int	gim_queryraster(), xp_stati()
pointer	xp_ulutalloc(), xp_statp()
real	xp_statr(), xp_log10()
extern	xp_log10()
errchk	gim_querymaster(), xp_ulutalloc()

begin
	# Save the old wcs structure if any.
	call gflush (gd)
	call amovi (Memi[GP_WCSPTR(gd,1)], wcs_save, LEN_WCSARRAY)

	call smark (sp)
	call salloc (r, DEF_CNCOLORS, TY_INT)
	call salloc (g, DEF_CNCOLORS, TY_INT)
	call salloc (b, DEF_CNCOLORS, TY_INT)
	call calloc (pkras, ncols * nlines, TY_CHAR)

	c2 = c1 + ncols - 1
	r2 = r1 + nlines - 1

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
	    call gim_createraster (gd, 0, 0, 200, 200, 8)
	    width = 200
	    height = 200
	}

	# Associate a WCS with the raster.
	call gseti (gd, G_WCS, wcs)
	call gseti (gd, G_RASTER, raster)

	# Set the default x andy axis flip parameters.
	xflip = 1.0
	yflip = 1.0

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
	    #call gsview (gd, dx, dx + pxsize, dy, dy + pysize)
	    call gsview (gd, 0.0, 1.0, 0.0, 1.0)
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
		#sxsize = min (pxsize, ncols * xp_statr (xp, DXVIEWPORT) /
		    #xp_statr (xp, DXMAG))
	    if (xp_statr (xp, DYMAG) * nlines <= pysize)
	        sysize = nlines
	    else
		sysize = min (pysize, height * xp_statr (xp, DYVIEWPORT) /
		    xp_statr (xp, DYMAG))
		#sysize = min (pysize, nlines * xp_statr (xp, DYVIEWPORT) /
		    #xp_statr (xp, DYMAG))
	    sx = max (0.0, (ncols + 1) / 2.0 - sxsize / 2.0)
	    sy = max (0.0, (nlines + 1) / 2.0 - sysize / 2.0)

	    pxsize = pxsize / real (width)
	    pysize = pysize / real (height)
	    dx = max (0.0, 0.5 - pxsize / 2.0) 
	    dy = max (0.0, 0.5 - pysize / 2.0)

	    #call gsview (gd, dx, dx + pxsize, dy, dy + pysize)
	    call gsview (gd, 0.0, 1.0, 0.0, 1.0)
	    call gswind (gd, real (c1) - 0.5, real (c2) + 0.5, real (r1) - 0.5,
	        real (r2) + 0.5)
	    call gim_setmapping (gd, wcs, 0, raster, CT_PIXEL, sx, sy, sxsize,
	        sysize, 0, CT_NDC, dx, dy, xflip * pxsize,
	        yflip * pysize)
	}

	# Write a color map.
	#if (xp_stati (xp, DERASE) == YES) {
	if (loadcmap == YES) {
	    offset = 0.5
	    slope = -1.0
	    do i = 1, DEF_CNCOLORS {
	        v = DEF_CMAXINTENSITY * (real ((i - 1)) / (DEF_CNCOLORS - 1))
	        Memi[r+i-1] = v; Memi[g+i-1] = v; Memi[b+i-1] = v
	    }
	    call gim_writecolormap (gd, 0, DEF_CZ1, DEF_CNCOLORS, Memi[r],
	        Memi[g], Memi[b])
	    call gim_writecolormap (gd, 1, DEF_CZ1, DEF_CNCOLORS, Memi[r],
	        Memi[g], Memi[b])
	    call gim_loadcolormap (gd, 0, offset, slope)
	    call gim_loadcolormap (gd, 1, offset, slope)
	}
	#}

	# Determine the greylevels limits assuming the image has already
	# been displayed.
	switch (xp_stati (xp, DZTRANS)) {

	case XP_DZNONE:
	    z1 = xp_statr (xp, DIMZ1)
	    z2 = xp_statr (xp, DIMZ2)

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
	    z1 = xp_statr (xp, DIMZ1)
	    z2 = xp_statr (xp, DIMZ2)
	}

	# Load the image.
	npix = ncols * nlines
	stat = OK
	switch (xp_stati (xp, DZTRANS)) {

	case XP_DZNONE:
	    call amapr (buffer, buffer, npix, z1, z2, z1, z2)
	    call achtrb (buffer, Memc[pkras], npix)

	case XP_DZLUT:
	    if (xp_statp (xp, DLUT) == NULL) {
		call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
		call printf ("Error reading lutfile %s\n")
		    call pargstr (Memc[str])
		stat = ERR
	    } else {
		call alims (Mems[xp_statp(xp,DLUT)], DEF_UMAXPTS, lut1, lut2)
		if (lut2 < short (DEF_CZ1) || lut1 > short (DEF_CZ2)) {
		    call printf (
		        "User specified greyscales out of range\n")
		    stat = ERR
		} else if (z2 < IM_MIN(im) || z1 > IM_MAX(im)) {
		    call printf (
			"User specified intensities out of range\n")
		    stat = ERR
		} else {
	            call amapr (buffer, buffer, npix, z1, z2,
		        real (DEF_UZ1), real (DEF_UZ2))
	            call achtrs (buffer, Memc[pkras], npix)
		    call aluts (Memc[pkras], Memc[pkras], npix,
		        Mems[xp_statp(xp,DLUT)])
	            call achtsb (Memc[pkras], Memc[pkras], npix)
		}
	    }

	case XP_DZLOG:
	    call amapr (buffer, buffer, npix, z1, z2, 1.0, 10.0 ** DEF_UMAXLOG)
	    call alogr (buffer, buffer, npix, xp_log10)
	    call amapr (buffer, buffer, npix, 1.0, real (DEF_UMAXLOG),
	        real (DEF_CZ1), real (DEF_CZ2))
	    call achtrb (buffer, Memc[pkras], npix)

	default:
	    if (! fp_equalr (z1, z2))
	        call amapr (buffer, buffer, npix, z1, z2, real (DEF_CZ1),
		    real (DEF_CZ2))
	    else
		call amovkr (real(DEF_CZ1), buffer, npix)
	    call achtrb (buffer, Memc[pkras], npix)
	}

	if (stat == OK)
	    call gim_writepixels (gd, raster, Memc[pkras], 8, 0, 0,
	        ncols, nlines)

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
