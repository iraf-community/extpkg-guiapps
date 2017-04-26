include <imhdr.h>
include <mach.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/impars.h"
include "../lib/centerdef.h"
include "../lib/center.h"

# XP_CTRBUF -- Fetch the centering aperture pixels given the pointer to the
# IRAF image, the coordinates of the initial center, and the width of the 
# centering box.

int procedure xp_cbuf (xp, im, wx, wy)

pointer	xp		#I the main xapphot descriptor
pointer	im		#I the input image descriptor
real	wx, wy		#I the initial x and y coordinates

int	icpix
pointer	ip, cp
real	cpix, gdatamin, gdatamax, datamin, datamax
pointer	xp_cpix()

begin
	# Get pointer to centering structure.
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)

	# Check for 0 sized aperture.
	if (XP_CRADIUS(cp) <= 0.0)
	    return (XP_CTR_NOPIXELS)

	# Get the centering buffer of pixels.
	cpix = max (1.0, XP_CRADIUS(cp) * XP_ISCALE(ip))
	icpix = 2 * int (cpix) + 1
	if (XP_CTRPIX(cp) != NULL)
	    call mfree (XP_CTRPIX(cp), TY_REAL)
	XP_CTRPIX(cp) = xp_cpix (im, wx, wy, icpix, XP_CXC(cp), XP_CYC(cp),
	    XP_CNX(cp), XP_CNY(cp))
	if (XP_CTRPIX(cp) == NULL)
	    return (XP_CTR_NOPIXELS)

	# Compute the data limits.
	if (IS_INDEFR(XP_IMINDATA(ip)))
	    gdatamin = -MAX_REAL
	else
	    gdatamin = XP_IMINDATA(ip)
	if (IS_INDEFR(XP_IMAXDATA(ip)))
	    gdatamax = MAX_REAL
	else
	    gdatamax = XP_IMAXDATA(ip)
	call alimr (Memr[XP_CTRPIX(cp)], XP_CNX(cp) * XP_CNY(cp), datamin,
	    datamax)

	if (datamin < gdatamin || datamax > gdatamax)
	    return (XP_CTR_BADDATA)
	else if (XP_CNX(cp) < icpix || XP_CNY(cp) < icpix)
	    return (XP_CTR_OFFIMAGE)
	else
	    return (XP_OK)
end


# XP_CTRPIX -- Read fetch the pixels to be used for centering from the
# input image.

pointer procedure xp_cpix (im, wx, wy, capert, xc, yc, nx, ny)

pointer	im		#I the input image descriptor
real	wx, wy		#I the initial x and y coordinates
int	capert		#I the width of subraster to be extracted
real	xc, yc		#O the x and y center of the extracted subraster
int	nx, ny		#O the dimensions of extracted subraster

int	i, ncols, nlines, c1, c2, l1, l2, half_capert
pointer	buf, lbuf
real	xc1, xc2, xl1, xl2
pointer	imgs2r()

begin
	# Check for nonsensical input.
	half_capert = (capert - 1) / 2
	if (half_capert <= 0)
	    return (NULL)

	# Test for out-of-bounds pixels.
	ncols = IM_LEN(im,1)
	nlines = IM_LEN(im,2)
	xc1 = wx - half_capert
	xc2 = wx + half_capert
	xl1 = wy - half_capert
	xl2 = wy + half_capert
	if (xc1 > real (ncols) || xc2 < 1.0 || xl1 > real (nlines) || xl2 < 1.0)
	    return (NULL)

	# Get column and line limits, dimensions, and center of subraster.
	c1 = max (1.0, min (real (ncols), xc1)) + 0.5
	c2 = min (real (ncols), max (1.0, xc2)) + 0.5
	l1 = max (1.0, min (real (nlines), xl1)) + 0.5
	l2 = min (real (nlines), max (1.0, xl2)) + 0.5
	nx = c2 - c1 + 1
	ny = l2 - l1 + 1
	xc = wx - c1 + 1
	yc = wy - l1 + 1

	# Read pixels.
	if (nx < 1 && ny < 1)
	    return (NULL)
	else {
	    call malloc (buf, nx * ny, TY_REAL)
	    lbuf = buf
	    do i = l1, l2 {
	        call amovr (Memr[imgs2r (im, c1, c2, i, i)], Memr[lbuf], nx)
	        lbuf = lbuf + nx
	    }
	    return (buf)
	}
end


# XP_CSNRATIO -- Estimate the signal to noise ratio in the centering aperture.

real procedure xp_csnratio (array, nx, ny, noisemodel, threshold, noise,
	gain)

real	array[nx,ny]	#I the input object subarray
int	nx, ny		#I the dimensions of the subarray
int	noisemodel	#I the input noise model
real	threshold	#I the threshold value for snr computation
real	noise		#I the  background noise estimate in counts
real	gain		#I the gain in electrons per count

#real	xp_cratio()
real	xp_pratio()

begin
	switch (noisemodel) {
	#case XP_NCONSTANT:
	    #return (xp_cratio (array, nx, ny, threshold, noise))
	case XP_INPOISSON:
	    return (xp_pratio (array, nx, ny, threshold, noise, gain))
	default:
	    return (MAX_REAL)
	}
end


# XP_CRATIO -- Estimate the signal to noise ratio in the centering aperture
# assuming that the noise is due to a constant sky sigma. This computation
# is approximate only.

real procedure xp_cratio (array, nx, ny, threshold, noise)

real	array[nx,ny]		#I the input object subarray
int	nx, ny			#I the dimensions of the subarray
real	threshold		#I the threshold value for snr computation
real	noise			#I the background estimate in counts

int	npts
real	signal, tnoise
real	asumr()

begin
	npts = nx * ny
	signal = asumr (array, npts) - npts * threshold
	if (IS_INDEFR(noise))
	    tnoise = 0.0
	else
	    tnoise = sqrt (npts * noise ** 2)
	if (signal <= 0.0)
	    return (0.0)
	else if (tnoise <= 0.0)
	    return (MAX_REAL)
	else
	    return (signal / tnoise)
end


# XP_PRATIO -- Estimate the signal to noise ratio in the centering aperture
# assuming the noise is due to a constant sky sigma and poisson statistics in
# the image. This computation is approximate only.

real procedure xp_pratio (array, nx, ny, threshold, noise, gain)

real	array[nx,ny]		#I the input object subarray
int	nx, ny			#I the  dimensions of the 
real	threshold		#I the threshold for snr computation
real	noise			#I background noise estimate in counts
real	gain			#I the gain in electrons per count

int	npts
real	signal, tnoise
real	asumr()

begin
	npts = nx * ny
	signal = asumr (array, npts) - npts * threshold
	if (IS_INDEFR(noise))
	    tnoise = sqrt (abs (signal / gain))
	else
	    tnoise = sqrt (abs (signal / gain) + npts * noise ** 2)
	if (signal <= 0.0)
	    return (0.0)
	else if (tnoise <= 0.0)
	    return (MAX_REAL)
	else
	    return (signal / tnoise)
end
