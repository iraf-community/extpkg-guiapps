include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"

# XP_REFITSKY -- Refit the sky using the pixels currently stored in
# the sky fitting buffers.

int procedure xp_refitsky (xp, gd)

pointer	xp		#I pointer to the (xp)phot structure
pointer	gd		#I pointer to gr(xp)hics stream

int	ier, nclip, nsky, ilo, ihi
pointer	sky, imp
int	xp_clip(), xp_mean(), xp_median(), xp_mode(), xp_centroid()
int	xp_sofilter(), xp_crosscor(), xp_gauss()

begin
	# Set some pointers.
	imp = XP_PIMPARS((xp))
	sky = XP_PSKY((xp))

	# Initialize.
	XP_SKY_MEAN(sky) = INDEFR
	XP_SKY_MEDIAN(sky) = INDEFR
	XP_SKY_MODE(sky) = INDEFR
	XP_SKY_STDEV(sky) = INDEFR
	XP_SKY_SKEW(sky) = INDEFR
	XP_NSKY(sky) = 0
	XP_NSKY_REJECT(sky) = 0
	if (IS_INDEFR(XP_SXCUR(sky)) || IS_INDEFR(XP_SYCUR(sky)))
	    return (XP_SKY_NOPIXELS)

	switch (XP_SALGORITHM(sky)) {


	case XP_ZERO:

	    XP_SKY_MODE(sky) = 0.0
	    XP_SKY_STDEV(sky) = XP_ISKYSIGMA(imp)
	    XP_SKY_SKEW(sky) = INDEFR
	    XP_NSKY(sky) = 0
	    XP_NSKY_REJECT(sky) = 0
	    return (XP_OK)

	case XP_CONSTANT:

	    XP_SKY_MODE(sky) = XP_SCONSTANT(sky)
	    XP_SKY_STDEV(sky) = XP_ISKYSIGMA(imp)
	    XP_SKY_SKEW(sky) = INDEFR
	    XP_NSKY(sky) = 0
	    XP_NSKY_REJECT(sky) = 0
	    return (XP_OK)

	case XP_MEAN:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_mean (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SNREJECT(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

	case XP_MEDIAN:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_qsort (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_median (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SNREJECT(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 
	    return (ier)

	case XP_MODE32:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_qsort (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_mode (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SNREJECT(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

	case XP_HCENTROID:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_centroid (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)+ilo-1], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SHWIDTH(sky), INDEFR,
		XP_SHBINSIZE(sky), XP_SHSMOOTH(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SMAXITER(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

	case XP_HOFILTER:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_sofilter (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SHWIDTH(sky), INDEFR,
		XP_SHBINSIZE(sky), XP_SHSMOOTH(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SMAXITER(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

	case XP_HCROSSCOR:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_crosscor (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SHWIDTH(sky), INDEFR,
		XP_SHBINSIZE(sky), XP_SHSMOOTH(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SMAXITER(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

	case XP_HGAUSS:

	    # Initialize the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
		    ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }

	    ier = xp_gauss (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SMAXITER(sky),
		XP_SHWIDTH(sky), INDEFR, XP_SHBINSIZE(sky), XP_SHSMOOTH(sky),
		XP_SLOREJECT(sky), XP_SHIREJECT(sky), XP_SRGROW(sky) *
		XP_ISCALE(imp), XP_SNREJECT(sky), XP_SKY_MODE(sky),
		XP_SKY_STDEV(sky), XP_SKY_SKEW(sky), XP_NSKY(sky),
		XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky) 

	    return (ier)

#	case XP_SKYFILE:
#
#	    return (XP_OK)
#
#	case XP_RADPLOT:
#
#	    # Check the status of the gr(xp)hics stream.
#	    if (gd == NULL)
#		return (XP_SKY_NOGRAPHICS)
#
#	    # Clip the data.
#	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
#		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
#		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
#		    ihi)
#		if (nclip >= XP_NSKYPIX(sky))
#		    return (XP_SKY_TOOSMALL)
#		nsky = XP_NSKYPIX(sky) - nclip
#	    } else {
#		nclip = 0
#		call (xp)_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
#		ilo = 1
#		nsky = XP_NSKYPIX(sky) 
#	    }
#
#	    call gactivate (gd, 0)
#	    gt = (xp)_gtinit (XP_IMNAME((xp)), XP_SXCUR(sky), XP_SYCUR(sky))
#	    ier = (xp)_radplot (gd, gt, Memr[XP_SKYPIX(sky)],
#	        Memi[XP_SCOORDS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
#		XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky),
#		XP_ISCALE(imp), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
#		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
#	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
#	        XP_NSKY_REJECT(sky) 
#	    call (xp)_gtfree (gt)
#	    call gdeactivate (gd, 0)
#
#	    return (ier)
#
#	case XP_HISTPLOT:
#
#	    # Check the status of the gr(xp)hics stream.
#	    if (gd == NULL)
#		return (XP_SKY_NOGRAPHICS)
#
#	    # Initialize the weights.
#	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))
#
#	    # Clip the data.
#	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
#		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
#		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky), ilo,
#		    ihi)
#		if (nclip >= XP_NSKYPIX(sky))
#		    return (XP_SKY_TOOSMALL)
#		nsky = XP_NSKYPIX(sky) - nclip
#	    } else {
#		nclip = 0
#		call (xp)_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
#		ilo = 1
#		nsky = XP_NSKYPIX(sky) 
#	    }
#
#	    #call gactivate (gd, 0)
#	    gt = (xp)_gtinit (XP_IMNAME((xp)), XP_SXCUR(sky), XP_SYCUR(sky))
#	    ier = (xp)_histplot (gd, gt, Memr[XP_SKYPIX(sky)],
#	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
#		XP_K1(sky), INDEFR, XP_BINSIZE(sky), XP_SMOOTH(sky),
#		XP_SKY_MODE(sky), XP_SKY_STDEV(sky), XP_SKY_SKEW(sky),
#		XP_NSKY(sky), XP_NSKY_REJECT(sky))	
#	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
#	        XP_NSKY_REJECT(sky) 
#	    call (xp)_gtfree (gt)
#	    #call gdeactivate (gd, 0)
#
#	    return (ier)


	default:

	    XP_SKY_MODE(sky) = INDEFR
	    XP_SKY_STDEV(sky) = INDEFR
	    XP_SKY_SKEW(sky) = INDEFR
	    XP_NSKY(sky) = XP_NSKYPIX(sky)
	    XP_NSKY_REJECT(sky) = 0
	    return (XP_OK)
	}
end
