include <mach.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/centerdef.h"
include "../lib/center.h"

define	CONVERT		.8493218	# conversion from fwhmpsf to sigma

# XP_FITCENTER -- Procedure to fit the centers using either 1) the intensity
# weighted mean of the marginal distributions, 2) a Gaussian fit to the
# marginals assuming a fixed sigma or 3) a simplified version of the optimal
# filtering method using a Gaussian of fixed sigma to model the profile.

int procedure xp_fitcenter (xp, im, wx, wy)

pointer	xp		#I the main xapphot descriptor
pointer	im		#I the input image descriptor
real	wx, wy		#I the initial x and y coordinates

int	ier, niter, lowsnr, fier
pointer	ip, cp
real	owx, owy, cthreshold, datamin, datamax, xshift, yshift
int	xp_cbuf(), xp_ctr1d(), xp_mctr1d(), xp_gctr1d(), xp_lgctr1d()
real	xp_csnratio()

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
	ier = XP_OK

	# Initialize.
	XP_CXCUR(cp) = wx
	XP_CYCUR(cp) = wy
	XP_XCENTER(cp) = INDEFR
	XP_YCENTER(cp) = INDEFR
	XP_XSHIFT(cp) = 0.0
	XP_YSHIFT(cp) = 0.0
	XP_XERR(cp) = INDEFR
	XP_YERR(cp) = INDEFR

	# Return input coordinates if centering is disabled.
	if (im == NULL)
	    return (XP_CTR_NOIMAGE)
	if (IS_INDEFR(wx) || IS_INDEFR(wy))
	    return (XP_CTR_NOPIXELS)
	if (XP_CALGORITHM(cp) == XP_NONE) {
	    XP_XCENTER(cp) = wx
	    XP_YCENTER(cp) = wy
	    return (XP_OK)
	} 

	# Intialize.
	owx = wx
	owy = wy 
	niter = 0
	if (IS_INDEFR(XP_ISKYSIGMA(ip)) || IS_INDEFR(XP_CTHRESHOLD(cp)))
	    cthreshold = 0.0
	else
	    cthreshold = XP_CTHRESHOLD(cp) * XP_ISKYSIGMA(ip) 

	repeat {

	    # Set initial cursor position.
	    XP_CXCUR(cp) = owx
	    XP_CYCUR(cp) = owy

	    # Get cptering pixels.
	    ier = xp_cbuf (xp, im, owx, owy)
	    if (ier == XP_CTR_NOPIXELS) {
	    	XP_XCENTER(cp) = wx
	    	XP_YCENTER(cp) = wy
	    	XP_XSHIFT(cp) = 0.0
	    	XP_YSHIFT(cp) = 0.0
	    	XP_XERR(cp) = INDEFR
	    	XP_YERR(cp) = INDEFR
	    	return (ier)
	    }

	    # Apply threshold and check for positive or negative features.
	    call alimr (Memr[XP_CTRPIX(cp)], XP_CNX(cp) * XP_CNY(cp),
		datamin, datamax)
	    if (XP_IEMISSION(ip) == YES) {
		XP_CDATALIMIT(cp) = datamin
		call asubkr (Memr[XP_CTRPIX(cp)], datamin +
		    cthreshold, Memr[XP_CTRPIX(cp)], XP_CNX(cp) * XP_CNY(cp))
		call amaxkr (Memr[XP_CTRPIX(cp)], 0.0, Memr[XP_CTRPIX(cp)],
		    XP_CNX(cp) * XP_CNY(cp))
	    } else {
		XP_CDATALIMIT(cp) = datamax
		call anegr (Memr[XP_CTRPIX(cp)], Memr[XP_CTRPIX(cp)],
		    XP_CNX(cp) * XP_CNY(cp))
		call aaddkr (Memr[XP_CTRPIX(cp)], datamax -
		    cthreshold, Memr[XP_CTRPIX(cp)], XP_CNX(cp) *
		    XP_CNY(cp))
		call amaxkr (Memr[XP_CTRPIX(cp)], 0.0,
		    Memr[XP_CTRPIX(cp)], XP_CNX(cp) * XP_CNY(cp))
	    }

	    # Test signal to noise ratio.
	    if (xp_csnratio (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
	        XP_CNY(cp), XP_INOISEMODEL(ip), 0.0, XP_ISKYSIGMA(ip),
		XP_IGAIN(ip)) < XP_CMINSNRATIO(cp))
	    	lowsnr = YES
	    else
		lowsnr = NO

	    # Compute the x and y cpters.
	    switch (XP_CALGORITHM(cp)) {

	    case XP_CENTROID1D:
		if (cthreshold > 0.0) {
	            fier = xp_ctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
		        XP_CNY(cp), XP_IGAIN(ip), XP_XCENTER(cp),
			XP_YCENTER(cp), XP_XERR(cp), XP_YERR(cp))
		    if (IS_INDEFR (XP_XERR(cp)))
			XP_XCENTER(cp) = XP_CXC(cp)
		    if (IS_INDEFR (XP_YERR(cp)))
			XP_YCENTER(cp) = XP_CYC(cp)
		} else {
	            fier = xp_mctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
		        XP_CNY(cp), XP_IGAIN(ip), XP_XCENTER(cp),
			XP_YCENTER(cp), XP_XERR(cp), XP_YERR(cp))
		    if (IS_INDEFR (XP_XERR(cp)))
			XP_XCENTER(cp) = XP_CXC(cp)
		    if (IS_INDEFR (XP_YERR(cp)))
			XP_YCENTER(cp) = XP_CYC(cp)
		}

	    case XP_GAUSS1D:

	        fier = xp_gctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
		    XP_CNY(cp), CONVERT * XP_IHWHMPSF(ip) * XP_ISCALE(ip),
		    XP_CMAXITER(cp), XP_XCENTER(cp), XP_YCENTER(cp),
		    XP_XERR(cp), XP_YERR(cp))

	    case XP_OFILT1D:

	        fier = xp_lgctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
		    XP_CNY(cp), XP_CXC(cp), XP_CYC(cp), CONVERT *
		    XP_IHWHMPSF(ip) * XP_ISCALE(ip), XP_CMAXITER(cp),
		    XP_IGAIN(ip), XP_ISKYSIGMA(ip), XP_XCENTER(cp),
		    XP_YCENTER(cp), XP_XERR(cp), XP_YERR(cp))

	    default:
		# do nothing gracefully
	    }

	    # Confine the next x cpter to the data box.
	    XP_XCENTER(cp) = max (0.5, min (XP_CNX(cp) + 0.5,
	        XP_XCENTER(cp)))
	    xshift = XP_XCENTER(cp) - XP_CXC(cp)
	    XP_XCENTER(cp) = xshift + owx
	    XP_XSHIFT(cp) = XP_XCENTER(cp) - wx

	    # Confine the next y cpter to the data box.
	    XP_YCENTER(cp) = max (0.5, min (XP_CNY(cp) + 0.5,
	        XP_YCENTER(cp)))
	    yshift = XP_YCENTER(cp) - XP_CYC(cp)
	    XP_YCENTER(cp) = yshift + owy
	    XP_YSHIFT(cp) = XP_YCENTER(cp) - wy

	    # Setup for next iteration.
	    niter = niter + 1
	    owx = XP_XCENTER(cp)
	    owy = XP_YCENTER(cp)

	} until ((fier != XP_OK && fier != XP_CTR_NOCONVERGE) ||
	    (niter >= XP_CMAXITER(cp)) || (abs (xshift) < 1.0 &&
	    abs (yshift) < 1.0))

	# Return appropriate error code.
	if (fier != XP_OK) {
	    XP_XCENTER(cp) = wx
	    XP_YCENTER(cp) = wy
	    XP_XSHIFT(cp) = 0.0
	    XP_YSHIFT(cp) = 0.0
	    XP_XERR(cp) = INDEFR
	    XP_YERR(cp) = INDEFR
	    return (fier)
	} else if (ier == XP_CTR_BADDATA) {
	    return (XP_CTR_BADDATA)
	} else if (lowsnr == YES) {
	    return (XP_CTR_LOWSNRATIO)
	} else if (abs (XP_XSHIFT(cp)) > (XP_CXYSHIFT(cp) * XP_ISCALE(ip))) {
	    return (XP_CTR_BADSHIFT)
	} else if (abs (XP_YSHIFT(cp)) > (XP_CXYSHIFT(cp) * XP_ISCALE(ip))) {
	    return (XP_CTR_BADSHIFT)
	} else if (ier == XP_CTR_OFFIMAGE) {
	    return (XP_CTR_OFFIMAGE)
	} else {
	    return (XP_OK)
	}
end


# XP_REFITCENTER -- Refit the center of the current object assuming that the
# appropriate pixel buffer is already in memory. See xp_fitcenter for further
# information.

int procedure xp_refitcenter (xp, ier)

pointer	xp		#I the main xapphot descriptor
int	ier		#O the output error code

int	fier
pointer	ip, cp
real	cthreshold
int	xp_ctr1d(), xp_mctr1d(), xp_gctr1d(), xp_lgctr1d()

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)

	# Initialize
        XP_XCENTER(cp) = XP_CXCUR(cp)
	XP_YCENTER(cp) = XP_CYCUR(cp)
	XP_XSHIFT(cp) = 0.0
	XP_YSHIFT(cp) = 0.0
	XP_XERR(cp) = INDEFR
	XP_YERR(cp) = INDEFR

	# Return input coordinates if no center fitting.
	if (IS_INDEFR(XP_CXCUR(cp)) || IS_INDEFR(XP_CYCUR(cp)))
	    return (XP_CTR_NOPIXELS)
	else if (XP_CALGORITHM(cp) == XP_NONE)
	    return (XP_OK)

	# Get the centering threshold.
	if (IS_INDEFR(XP_ISKYSIGMA(ip)) || IS_INDEFR(XP_CTHRESHOLD(cp)))
	    cthreshold = 0.0
	else
	    cthreshold = XP_CTHRESHOLD(cp) * XP_ISKYSIGMA(ip)

	# Choose the centering algorithm.
	switch (XP_CALGORITHM(cp)) {

	case XP_CENTROID1D:

	    # Compute the x and y cptroids.
	    if (cthreshold > 0.0) {
	        fier = xp_ctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp), XP_CNY(cp),
		    XP_IGAIN(ip), XP_XCENTER(cp), XP_YCENTER(cp), XP_XERR(cp),
		    XP_YERR(cp))
		if (IS_INDEFR(XP_XERR(cp)))
		    XP_XCENTER(cp) = XP_CXC(cp)
		if (IS_INDEFR(XP_YERR(cp)))
		    XP_YCENTER(cp) = XP_CYC(cp)
	    } else {
	        fier = xp_mctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp),
		    XP_CNY(cp), XP_IGAIN(ip), XP_XCENTER(cp), XP_YCENTER(cp),
		    XP_XERR(cp), XP_YERR(cp))
		if (IS_INDEFR(XP_XERR(cp)))
		    XP_XCENTER(cp) = XP_CXC(cp)
		if (IS_INDEFR(XP_YERR(cp)))
		    XP_YCENTER(cp) = XP_CYC(cp)
	    }
	    XP_XCENTER(cp) = XP_XCENTER(cp) + XP_CXCUR(cp) - XP_CXC(cp)
	    XP_YCENTER(cp) = XP_YCENTER(cp) + XP_CYCUR(cp) - XP_CYC(cp)
	    XP_XSHIFT(cp) = XP_XCENTER(cp) - XP_CXCUR(cp)
	    XP_YSHIFT(cp) = XP_YCENTER(cp) - XP_CYCUR(cp)

	case XP_GAUSS1D:

	    # Compute the 1D Gaussian x and y cpters.
	    fier = xp_gctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp), XP_CNY(cp),
		CONVERT * XP_IHWHMPSF(ip) * XP_ISCALE(ip), XP_CMAXITER(cp),
		XP_XCENTER(cp), XP_YCENTER(cp), XP_XERR(cp), XP_YERR(cp))
	    XP_XCENTER(cp) = XP_XCENTER(cp) + XP_CXCUR(cp) - XP_CXC(cp)
	    XP_YCENTER(cp) = XP_YCENTER(cp) + XP_CYCUR(cp) - XP_CYC(cp)
	    XP_XSHIFT(cp) = XP_XCENTER(cp) - XP_CXCUR(cp)
	    XP_YSHIFT(cp) = XP_YCENTER(cp) - XP_CYCUR(cp)

	case XP_OFILT1D:

	    # Compute the Goad 1D x and y cpters.
	    fier = xp_lgctr1d (Memr[XP_CTRPIX(cp)], XP_CNX(cp), XP_CNY(cp),
		 XP_CXC(cp), XP_CYC(cp), CONVERT * XP_IHWHMPSF(ip) *
		 XP_ISCALE(ip), XP_CMAXITER(cp), XP_IGAIN(ip), XP_ISKYSIGMA(ip),
		 XP_XCENTER(cp), XP_YCENTER(cp), XP_XERR(cp), XP_YERR(cp))
	    XP_XCENTER(cp) = XP_XCENTER(cp) + XP_CXCUR(cp) - XP_CXC(cp)
	    XP_YCENTER(cp) = XP_YCENTER(cp) + XP_CYCUR(cp) - XP_CYC(cp)
	    XP_XSHIFT(cp) = XP_XCENTER(cp) - XP_CXCUR(cp)
	    XP_YSHIFT(cp) = XP_YCENTER(cp) - XP_CYCUR(cp)

	default:

	    # do nothing gracefully
        }

	# Return appropriate error code.
	if (fier != XP_OK) {
	    XP_XCENTER(cp) = XP_CXCUR(cp)
	    XP_YCENTER(cp) = XP_CYCUR(cp)
	    XP_XSHIFT(cp) = 0.0
	    XP_YSHIFT(cp) = 0.0
	    XP_XERR(cp) = INDEFR
	    XP_YERR(cp) = INDEFR
	    return (fier)
	} else if (ier == XP_CTR_BADDATA) {
	    return (XP_CTR_BADDATA)
	} else if (ier == XP_CTR_LOWSNRATIO) {
	    return (XP_CTR_LOWSNRATIO)
	} else if (abs (XP_XSHIFT(cp)) > (XP_CXYSHIFT(cp) * XP_ISCALE(ip))) {
	    return (XP_CTR_BADSHIFT)
	} else if (abs (XP_YSHIFT(cp)) > (XP_CXYSHIFT(cp) * XP_ISCALE(ip))) {
	    return (XP_CTR_BADSHIFT)
	} else if (ier == XP_CTR_OFFIMAGE) {
	    return (XP_CTR_OFFIMAGE)
	} else
	    return (XP_OK)
end
