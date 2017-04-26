include "../lib/xphotdef.h"
include "../lib/objects.h"
include "../lib/imparsdef.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"

# XP_OFITSKY -- Compute the sky value in an annular region around a given
# object center.

int procedure xp_ofitsky (xp, im, objsym, xshift, yshift, xver,
	yver, nver, sd, gd)

pointer	xp			#I pointer to the main xapphot structure
pointer	im			#I pointer to the input image
pointer	objsym			#I the current object symbol
real	xshift, yshift		#I the object shift in x and y
real	xver[ARB]		#I the x vertices of the user polygon
real	yver[ARB]		#I the y vertices of the user polygon
int	nver			#I the number of vertices on the user polygon
int	sd			#I the input sky file descriptor
pointer	gd			#I the pointer to the graphics stream

int	ier, nclip, nsky, ilo, ihi
pointer	sp, str, polysym, imp, sky
int	xp_oskybuf(), xp_clip(), xp_mean(), xp_median(), xp_mode()
int	xp_centroid(), xp_sofilter(), xp_crosscor(), xp_gauss()
pointer	xp_statp(), stfind()

begin
	# Define some temporary pointers.
	imp = XP_PIMPARS(xp)
	sky = XP_PSKY(xp)

	# Initialize.
	XP_SXCUR(sky) = INDEFR
	XP_SYCUR(sky) = INDEFR
	XP_SKY_MEAN(sky) = INDEFR
	XP_SKY_MEDIAN(sky) = INDEFR
	XP_SKY_MODE(sky) = INDEFR
	XP_SKY_STDEV(sky) = INDEFR
	XP_SKY_SKEW(sky) = INDEFR
	XP_NSKY(sky) = 0
	XP_NSKY_REJECT(sky) = 0

	if (im == NULL)
	    return (XP_SKY_NOIMAGE)
	if (objsym == NULL)
	    return (XP_SKY_NOPIXELS)
        if (XP_OSNPOLYGON(objsym) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
            call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_OSNPOLYGON(objsym))
            polysym = stfind (xp_statp(xp,POLYGONLIST), Memc[str])
	    call sfree (sp)
        } else
            polysym = NULL

	# Check the sky center.
	if (IS_INDEFR(XP_OSXINIT(objsym)))
	    XP_SXCUR(sky) = XP_OXINIT(objsym) + xshift
	else
	    XP_SXCUR(sky) = XP_OSXINIT(objsym)
	if (IS_INDEFR(XP_OSYINIT(objsym)))
	    XP_SYCUR(sky) = XP_OYINIT(objsym) + yshift
	else
	    XP_SYCUR(sky) = XP_OSYINIT(objsym)

	switch (XP_SALGORITHM(sky)) {

	case XP_ZERO, XP_CONSTANT:

	    # Initialize geometry.
            if (IS_INDEFR(XP_OSXINIT(objsym)) ||
		IS_INDEFR(XP_OSYINIT(objsym))) {
                call strcpy ("concentric", XP_SOMSTRING(sky), SZ_FNAME)
                XP_SOMODE(sky) = XP_SCONCENTRIC
            } else {
                call strcpy ("offset", XP_SOMSTRING(sky), SZ_FNAME)
                XP_SOMODE(sky) = XP_SOFFSET
            }
	    switch (XP_OSGEOMETRY(objsym)) {
	    case XP_OCIRCLE:
		XP_SOGEOMETRY(sky) = XP_SCIRCLE
		call strcpy ("circle", XP_SOGEOSTRING(sky), SZ_FNAME)
	    case XP_OELLIPSE:
		XP_SOGEOMETRY(sky) = XP_SELLIPSE
		call strcpy ("ellipse", XP_SOGEOSTRING(sky), SZ_FNAME)
	    case XP_ORECTANGLE:
		XP_SOGEOMETRY(sky) = XP_SRECTANGLE
		call strcpy ("rectangle", XP_SOGEOSTRING(sky), SZ_FNAME)
	    case XP_OPOLYGON:
		XP_SOGEOMETRY(sky) = XP_SPOLYGON
		call strcpy ("polygon", XP_SOGEOSTRING(sky), SZ_FNAME)
	    default:
		XP_SOGEOMETRY(sky) = XP_SGEOMETRY(sky)
		call strcpy (XP_SGEOSTRING(sky), XP_SOGEOSTRING(sky), SZ_FNAME)
	    }

            # Define the width of the sky annulus.
            if (IS_INDEFR(XP_OSROUT(objsym))) {
                if (XP_OSGEOMETRY(objsym) == XP_OPOLYGON)
                    XP_SOWANNULUS(sky) = 0.0
                else
                    XP_SOWANNULUS(sky) = XP_SWANNULUS(sky) 
            } else {
                if (XP_OSGEOMETRY(objsym) == XP_OPOLYGON)
                    XP_SOWANNULUS(sky) = XP_OSROUT(objsym)
                else
                    XP_SOWANNULUS(sky) = XP_OSROUT(objsym) - XP_OSRIN(objsym)
            }

	    # Define the size of the sky annulus.
            if (IS_INDEFR(XP_OSRIN(objsym))) {
                if (IS_INDEFR(XP_OSXINIT(objsym)) ||
		    IS_INDEFR(XP_OSYINIT(objsym)))
                    XP_SORANNULUS(sky) = XP_SRANNULUS(sky)
                else
                    XP_SORANNULUS(sky) = 0.0
            } else
                XP_SORANNULUS(sky) = XP_OSRIN(objsym)

	    # Define the axis ratio and orientation.
	    if (IS_INDEFR(XP_OSAXRATIO(objsym)))
	        XP_SOAXRATIO(sky) = XP_SAXRATIO(sky)
	    else
	        XP_SOAXRATIO(sky) = XP_OSAXRATIO(objsym)
	    if (IS_INDEFR(XP_OSPOSANG(objsym)))
	        XP_SOPOSANGLE(sky) = XP_SPOSANGLE(sky)
	    else
	        XP_SOPOSANGLE(sky) = XP_OSPOSANG(objsym)

	    # There are no sky pixels.
	    XP_NSKYPIX(sky) = 0

	    # Set the sky value to zero
	    if (XP_SALGORITHM(sky) == XP_ZERO)
	        XP_SKY_MODE(sky) = 0.0
	    else
	        XP_SKY_MODE(sky) = XP_SCONSTANT(sky)
	    XP_SKY_STDEV(sky) = XP_ISKYSIGMA(imp)
	    XP_SKY_SKEW(sky) = INDEFR
	    XP_NSKY(sky) = 0
	    XP_NSKY_REJECT(sky) = 0

	    return (XP_OK)

	case XP_MEAN:

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
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
	    XP_SILO(sky) = ilo

	    # Compute the mean of the sky pixel distribution with pixel
	    # rejection and region growing.
	    ier = xp_mean (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1],
		nsky, XP_SNX(sky), XP_SNY(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SNREJECT(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
		XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
		    XP_NSKY_REJECT(sky)

	    return (ier)

	case XP_MEDIAN:

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
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
	    XP_SILO(sky) = ilo

	    # Compute the median of the sky pixel distribution with pixel
	    # rejection and region growing.
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

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift, 
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
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
	    XP_SILO(sky) = ilo

	    # Compute the median of the sky pixel distribution with pixel
	    # rejection and region growing.
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

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
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
	    XP_SILO(sky) = ilo

	    # Compute the sky value by performing a moment analysis of the
	    # sky pixel histogram.
	    ier = xp_centroid (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SHWIDTH(sky), INDEFR,
		XP_SHBINSIZE(sky), XP_SHSMOOTH(sky), XP_SLOREJECT(sky),
		XP_SHIREJECT(sky), XP_SRGROW(sky) * XP_ISCALE(imp),
		XP_SMAXITER(sky), XP_SKY_MODE(sky), XP_SKY_STDEV(sky),
		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky)

	    return (ier)

	case XP_HOFILTER:

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky),
		    ilo, ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }
	    XP_SILO(sky) = ilo

	    # Compute the sky value using the histogram of the sky pixels
	    # and a variation of the optimal filtering technique.
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

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky),
		    ilo, ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }
	    XP_SILO(sky) = ilo

	    # Fit the sky value  by computing the cross-correlation
	    # function of the histogram and an estimate of the noise
	    # distribution.
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

	    # Fetch  the sky pixels.
	    ier = xp_oskybuf (xp, im, objsym, polysym, xshift, yshift,
	        xver, yver, nver)
	    if (ier != XP_OK)
		return (ier)

	    # Initialze the weights.
	    call amovkr (1.0, Memr[XP_SWEIGHTS(sky)], XP_NSKYPIX(sky))

	    # Clip the data.
	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky),
		    ilo, ihi)
		if (nclip >= XP_NSKYPIX(sky))
		    return (XP_SKY_TOOSMALL)
		nsky = XP_NSKYPIX(sky) - nclip
	    } else {
		nclip = 0
		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
		ilo = 1
		nsky = XP_NSKYPIX(sky) 
	    }
	    XP_SILO(sky) = ilo

	    # Compute the sky value by a fitting a skewed Gaussian function
	    # to the sky pixel histogram.
	    ier = xp_gauss (Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
	        Memr[XP_SWEIGHTS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
		XP_SNX(sky), XP_SNY(sky), XP_SMAXITER(sky), XP_SHWIDTH(sky),
		INDEFR, XP_SHBINSIZE(sky), XP_SHSMOOTH(sky),
		XP_SLOREJECT(sky), XP_SHIREJECT(sky), XP_SRGROW(sky) *
		XP_ISCALE(imp), XP_SNREJECT(sky), XP_SKY_MODE(sky),
		XP_SKY_STDEV(sky), XP_SKY_SKEW(sky), XP_NSKY(sky),
		XP_NSKY_REJECT(sky))
	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
	        XP_NSKY_REJECT(sky)

	    return (ier)

#	case XP_RADPLOT:
#
#	    # Check the status of the graphics stream.
#	    if (gd == NULL)
#		return (XP_SKY_NOGRAPHICS)
#
#	    # Fetch the sky pixels.
#	    ier = apskybufs (ap, im, objsym, polysym, xshift, yshift, 
#		xver, yver, nver)
#	    if (ier != XP_OK)
#		return (ier)
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
#		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
#		ilo = 1
#		nsky = XP_NSKYPIX(sky) 
#	    }
#	    XP_SILO(sky) = ilo
#
#	    # Mark the sky level on the radial profile plot.
#	    call gactivate (gd, 0)
#	    gt = ap_gtinit (XP_IMNAME(ap), wx, wy)
#	    ier = ap_radplot (gd, gt, Memr[XP_SKYPIX(sky)],
#	        Memi[XP_SCOORDS(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
#		XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky),
#		XP_ISCALE(imp), XP_SKY_MODE(sky), XP_SKY_SKEW(sky),
#		XP_SKY_SIG(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
#	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
#	        XP_NSKY_REJECT(sky)
#	    call ap_gtfree (gt)
#	    call gdeactivate (gd, 0)
#
#	    return (ier)

#	case XP_HISTPLOT:
#
#	    # Check the status of the graphics stream.
#	    if (gd == NULL)
#		return (XP_SKY_NOGRAPHICS)
#
#	    # Fetch the sky pixels.
#	    ier = apskybufs (ap, im, ojsym, polysym, xshift, yshift, 
#		xver, yver, nver)
#	    if (ier != XP_OK)
#		return (ier)
#
#	    # Initialze the weights.
#	    call amovkr (1.0, Memr[XP_SWGT(sky)], XP_NSKYPIX(sky))
#
#	    # Clip the data.
#	    if (XP_SLOCLIP(sky) > 0.0 || XP_SHICLIP(sky) > 0.0) {
#		nclip = xp_clip (Memr[XP_SKYPIX(sky)], Memi[XP_SINDEX(sky)],
#		    XP_NSKYPIX(sky), XP_SLOCLIP(sky), XP_SHICLIP(sky),
#		    ilo, ihi)
#		if (nclip >= XP_NSKYPIX(sky))
#		    return (XP_SKY_TOOSMALL)
#		nsky = XP_NSKYPIX(sky) - nclip
#	    } else {
#		nclip = 0
#		call xp_index (Memi[XP_SINDEX(sky)], XP_NSKYPIX(sky))
#		ilo = 1
#		nsky = XP_NSKYPIX(sky) 
#	    }
#	    XP_SILO(sky) = ilo
#
#	    # Mark the peak of the histogram on the histogram plot.
#	    #call gactivate (gd, 0)
#	    gt = ap_gtinit (XP_IMNAME(ap), wx, wy)
#	    ier = ap_histplot (gd, gt, Memr[XP_SKYPIX(sky)],
#	        Memr[XP_SWGT(sky)], Memi[XP_SINDEX(sky)+ilo-1], nsky,
#		XP_K1(sky), INDEFR, XP_BINSIZE(sky), XP_SMOOTH(sky),
#		XP_SKY_MODE(sky), XP_SKY_SIG(sky), XP_SKY_SKEW(sky),
#		XP_NSKY(sky), XP_NSKY_REJECT(sky))	
#	    XP_NSKY_REJECT(sky) = XP_NBADSKYPIX(sky) + nclip +
#	        XP_NSKY_REJECT(sky)
#	    call ap_gtfree (gt)
#	    #call gdeactivate (gd, 0)
#
#	    return (ier)

#	case XP_SKYFILE:
#
#	    # Read the sky values from a file.
#	    if (sd == NULL)
#		return (XP_SKY_NOFILE)
#	    ier = xp_readsky (sd, x, y, XP_SKY_MODE(sky), XP_SKY_SIG(sky),
#		XP_SKY_SKEW(sky), XP_NSKY(sky), XP_NSKY_REJECT(sky))
#	    if (ier == EOF)
#		return (XP_SKY_ATEOF)
#	    else if (ier != 7)
#		return (XP_SKY_BADSCAN)
#	    else if (XP_NSKY(sky) <= 0)
#		return (XP_SKY_NOPIXELS)
#	    else
#		return (XP_OK)

	default:

	    XP_SKY_MEAN(sky) = INDEFR
	    XP_SKY_MEDIAN(sky) = INDEFR
	    XP_SKY_MODE(sky) = INDEFR
	    XP_SKY_STDEV(sky) = INDEFR
	    XP_SKY_SKEW(sky) = INDEFR
	    XP_NSKY(sky) = XP_NSKYPIX(sky)
	    XP_NSKY_REJECT(sky) = 0
	    return (XP_OK)
	}
end
