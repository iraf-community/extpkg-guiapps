include <imhdr.h>
include <mach.h>
include <math.h>
include "../lib/xphotdef.h"
include "../lib/objects.h"
include "../lib/imparsdef.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"

# XP_OSKYBUF -- Extract the sky pixels given the pointer to the image,
# the coordinates of the center, and the vertices of the aperture.

int procedure xp_oskybuf (xp, im, objsym, polysym, xshift, yshift, xver, yver,
	nver)

pointer	xp		#I pointer to main xapphot structure
pointer	im		#I pointer to the input image
pointer	objsym		#I the sky object symbol
pointer	polysym		#I the sky polygon symbol
real	xshift, yshift	#I the x and y shifts
real	xver[ARB]	#I the x vertices of the user defined polygon
real	yver[ARB]	#I the y vertices of the user defined polygon
int	nver		#I the number of vertices in the user defined polygon

int	lenbuf, nsver, ier
pointer	imp, sky, sp, ixver, iyver, oxver, oyver
real	owx, owy, rannulus, wannulus, rmin, rmax, ratio, xmin, xmax, ymin, ymax
real	datamin, datamax, theta, xin[5], yin[5], xout[5], yout[5]

bool	fp_equalr()
int	xp_skybuf()
int	xp_cskypix(), xp_cbskypix(), xp_eskypix(), xp_ebskypix() 
int	xp_rskypix(), xp_rbskypix(), xp_pskypix(), xp_pbskypix()

begin
	# Get the substructure pointers.
	imp = XP_PIMPARS(xp)
	sky = XP_PSKY(xp)

	# Check for the minimum number of object list polygon vertices.
	if (polysym == NULL)
	    nsver = 0
	else if (XP_ONVERTICES(polysym) > 0)
	    nsver = XP_ONVERTICES(polysym)
	else
	    nsver = XP_SNVERTICES(polysym)
	if (nsver < 3 && XP_OSGEOMETRY(objsym) == XP_OPOLYGON)
	    return (XP_SKY_NOPIXELS)

	# Check for the minimum number of user polygon vertices.
	if (nver < 3 && XP_OSGEOMETRY(objsym) == XP_OINDEF &&
	    XP_SGEOMETRY(sky) == XP_SPOLYGON)
	    return (XP_SKY_NOPIXELS)

	# Define the width of the sky annulus.
	if (IS_INDEFR(XP_OSROUT(objsym))) {
	    if (XP_OSGEOMETRY(objsym) == XP_OPOLYGON)
		wannulus = 0.0
	    else
	        wannulus = XP_SWANNULUS(sky) * XP_ISCALE(imp)
		
	} else {
	    if (XP_OSGEOMETRY(objsym) == XP_OPOLYGON)
	        wannulus = XP_OSROUT(objsym) * XP_ISCALE(imp)
	    else
	        wannulus = (XP_OSROUT(objsym) - XP_OSRIN(objsym)) *
		    XP_ISCALE(imp)
	}

	# Check that the sky annulus has a finite width.
	if (wannulus <= 0.0) {
	    if ((XP_OSGEOMETRY(objsym) == XP_OINDEF) && (XP_SGEOMETRY(sky) !=
	        XP_SPOLYGON))
	        return (XP_SKY_NOPIXELS)
	    else if (XP_OSGEOMETRY(objsym) != XP_OPOLYGON)
	        return (XP_SKY_NOPIXELS)
	}

	# Define the inner radius of the sky annulus.
	if (IS_INDEFR(XP_OSRIN(objsym))) {
	    if (IS_INDEFR(XP_OSXINIT(objsym)) || IS_INDEFR(XP_OSYINIT(objsym)))
	        rannulus = XP_SRANNULUS(sky) * XP_ISCALE(imp)
	    else
		rannulus = 0.0
	} else
	    rannulus = XP_OSRIN(objsym) * XP_ISCALE(imp)

	# Define the maximum radial extent of non-polygonal apertures and the
	# shape parameters.
	if (rannulus <= 0.0) {
	    rmin = 0.0
	    rmax = wannulus
	} else {
	    rmin = rannulus
	    rmax = rannulus + wannulus
	}

	if (IS_INDEFR(XP_OSAXRATIO(objsym)))
	    ratio = XP_SAXRATIO(sky)
	else
	    ratio = XP_OSAXRATIO(objsym)
	if (IS_INDEFR(XP_OSPOSANG(objsym)))
	    theta = XP_SPOSANGLE(sky)
	else
	    theta = XP_OSPOSANG(objsym)

	# Define the sky center and set the current sky mode.
	if (IS_INDEFR(XP_OSXINIT(objsym)) || IS_INDEFR(XP_OSYINIT(objsym))) {
	    owx = XP_OXINIT(objsym) + xshift
	    owy = XP_OYINIT(objsym) + yshift
	    call strcpy ("concentric", XP_SOMSTRING(sky), SZ_FNAME)
	    XP_SOMODE(sky) = XP_SCONCENTRIC
	} else {
	    owx = XP_OSXINIT(objsym)
	    owy = XP_OSYINIT(objsym)
	    call strcpy ("offset", XP_SOMSTRING(sky), SZ_FNAME)
	    XP_SOMODE(sky) = XP_SOFFSET
	}

	# Make sure the geometry is current.
	XP_SORANNULUS(sky) = rannulus / XP_ISCALE(imp)
	XP_SOWANNULUS(sky) = wannulus / XP_ISCALE(imp)
	XP_SOAXRATIO(sky) = ratio
	XP_SOPOSANGLE(sky) = theta

	# Allocate space for the sky pixels.
	switch (XP_OSGEOMETRY(objsym)) {
	case XP_OCIRCLE:
	    XP_SOGEOMETRY(sky) = XP_SCIRCLE
	    call strcpy ("circle", XP_SOGEOSTRING(sky), SZ_FNAME)
	    lenbuf = PI * (2.0 * rannulus + wannulus + 1.0) * (wannulus + 1.0)
	case XP_OELLIPSE:
	    XP_SOGEOMETRY(sky) = XP_SELLIPSE
	    call strcpy ("ellipse", XP_SOGEOSTRING(sky), SZ_FNAME)
	    lenbuf = PI * ratio * (2.0 * rannulus + wannulus + 1.0) *
	        (wannulus + 1.0)
	case XP_ORECTANGLE:
	    XP_SOGEOMETRY(sky) = XP_SRECTANGLE
	    call strcpy ("rectangle", XP_SOGEOSTRING(sky), SZ_FNAME)
	    lenbuf = 4.0 * ratio * (2.0 * rannulus + wannulus + 1.0) *
	        (wannulus + 1.0)
	case XP_OPOLYGON:
	    XP_SOGEOMETRY(sky) = XP_SPOLYGON
	    call strcpy ("polygon", XP_SOGEOSTRING(sky), SZ_FNAME)
	    if (XP_ONVERTICES(polysym) > 0) {
		nsver = XP_ONVERTICES(polysym)
	        call alimr (XP_XVERTICES(polysym), nsver, xmin, xmax)
	        call alimr (XP_YVERTICES(polysym), nsver, ymin, ymax)
	    } else {
		nsver = XP_SNVERTICES(polysym)
	        call alimr (XP_XVERTICES(polysym), nsver, xmin, xmax)
	        call alimr (XP_YVERTICES(polysym), nsver, ymin, ymax)
	    }
	    lenbuf = (xmax - xmin + rannulus + wannulus + 2.0) *
	        (ymax - ymin + rannulus + wannulus + 2.0)
	default:
	    switch (XP_SGEOMETRY(sky)) {
	    case XP_SCIRCLE:
	        XP_SOGEOMETRY(sky) = XP_SCIRCLE
	        call strcpy ("circle", XP_SOGEOSTRING(sky), SZ_FNAME)
	        lenbuf = PI * (2.0 * rannulus + wannulus + 1.0) *
		    (wannulus + 1.0)
	    case XP_SELLIPSE:
	        XP_SOGEOMETRY(sky) = XP_SELLIPSE
	        call strcpy ("ellipse", XP_SOGEOSTRING(sky), SZ_FNAME)
	        lenbuf = PI * ratio * (2.0 * rannulus + wannulus + 1.0) *
	            (wannulus + 1.0)
	    case XP_SRECTANGLE:
	        XP_SOGEOMETRY(sky) = XP_SRECTANGLE
	        call strcpy ("rectangle", XP_SOGEOSTRING(sky), SZ_FNAME)
	        lenbuf = 4.0 * ratio * (2.0 * rannulus + wannulus + 1.0) *
	            (wannulus + 1.0)
	    case XP_SPOLYGON:
	        XP_SOGEOMETRY(sky) = XP_SPOLYGON
	        call strcpy ("polygon", XP_SOGEOSTRING(sky), SZ_FNAME)
	        call alimr (xver, nver, xmin, xmax)
	        call alimr (yver, nver, ymin, ymax)
	        lenbuf = (xmax - xmin + rannulus + wannulus + 2.0) *
	            (ymax - ymin + rannulus + wannulus + 2.0)
	    }
	}

	# Free any existing sky buffers.
	if (lenbuf != XP_LENSKYBUF(sky)) {
	    if (XP_SKYPIX(sky) != NULL)
		call mfree (XP_SKYPIX(sky), TY_REAL)
	    call malloc (XP_SKYPIX(sky), lenbuf, TY_REAL)
	    if (XP_SCOORDS(sky) != NULL)
		call mfree (XP_SCOORDS(sky), TY_INT)
	    call malloc (XP_SCOORDS(sky), lenbuf, TY_INT)
	    if (XP_SINDEX(sky) != NULL)
		call mfree (XP_SINDEX(sky), TY_INT)
	    call malloc (XP_SINDEX(sky), lenbuf, TY_INT)
	    if (XP_SWEIGHTS(sky) != NULL)
		call mfree (XP_SWEIGHTS(sky), TY_REAL)
	    call malloc (XP_SWEIGHTS(sky), lenbuf, TY_REAL)
	    XP_LENSKYBUF(sky) = lenbuf
	}

	# Check for bad pixels.
	if (IS_INDEFR(XP_IMINDATA(imp)) && IS_INDEFR(XP_IMAXDATA(imp))) {
	    datamin = INDEFR
	    datamax = INDEFR
	} else {
	    if (IS_INDEFR(XP_IMINDATA(imp)))
		datamin = -MAX_REAL
	    else
		datamin = XP_IMINDATA(imp)
	    if (IS_INDEFR(XP_IMAXDATA(imp)))
		datamax = MAX_REAL
	    else
		datamax = XP_IMAXDATA(imp)
	}

	# Fetch the sky pixels.
	switch (XP_OSGEOMETRY(objsym)) {

	case XP_OCIRCLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_cskypix (im, owx, owy, rmin, rmax,
	            Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
		    XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else {
	        XP_NSKYPIX(sky) = xp_cbskypix (im, owx, owy, rmin, rmax,
	            datamin, datamax, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	case XP_OELLIPSE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_eskypix (im, owx, owy, rmin, rmax, ratio,
		    theta, Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
		    XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else {
	        XP_NSKYPIX(sky) = xp_ebskypix (im, owx, owy, rmin, rmax,
	            ratio, theta, datamin, datamax, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	case XP_ORECTANGLE:

	    if (fp_equalr (theta, 0.0) || fp_equalr (theta, 180.0)) {
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_rskypix (im, owx, owy, rmin, rmax,
		        ratio, Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_rbskypix (im, owx, owy, rmin, rmax,
		        ratio, datamin, datamax, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    } else if (fp_equalr (theta, 90.0) || fp_equalr (theta, 270.0)) {
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_rskypix (im, owx, owy, ratio * rmin,
		        ratio * rmax, 1.0 / ratio, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_rbskypix (im, owx, owy, ratio * rmin,
		        ratio * rmax, 1.0 / ratio, datamin, datamax,
			Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky),
			XP_SNY(sky), XP_NBADSKYPIX(sky))
	    } else {
		call xp_rvertices (owx, owy, rmin, rmax, ratio, theta, xin, yin,
		    xout, yout)
	    	if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	            XP_NSKYPIX(sky) = xp_pskypix (im, xin, yin, xout, yout, 5,
		        Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)],
			XP_SXC(sky), XP_SYC(sky), XP_SNX(sky), XP_SNY(sky))
	            XP_NBADSKYPIX(sky) = 0
		} else
	            XP_NSKYPIX(sky) = xp_pbskypix (im, xin, yin, xout, yout, 5,
		        datamin, datamax, Memr[XP_SKYPIX(sky)],
			Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
			XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    }

	case XP_OPOLYGON:
	    call smark (sp)
	    call salloc (ixver, nsver + 1, TY_REAL)
	    call salloc (iyver, nsver + 1, TY_REAL)
	    call salloc (oxver, nsver + 1, TY_REAL)
	    call salloc (oyver, nsver + 1, TY_REAL)
	    if ((rannulus + wannulus) <= 0.0) {
		call aaddkr (XP_XVERTICES(polysym), XP_OSXSHIFT(objsym) +
		    xshift, Memr[oxver], nsver)
		call aaddkr (XP_YVERTICES(polysym), XP_OSYSHIFT(objsym) +
		    yshift, Memr[oyver], nsver)
		Memr[oxver+nsver] = Memr[oxver]
		Memr[oyver+nsver] = Memr[oyver]
		call aclrr (Memr[ixver], nsver + 1)
		call aclrr (Memr[ixver], nsver + 1)
	    } else  {
		if (rannulus <=  0.0) {
		    call aaddkr (XP_XVERTICES(polysym), XP_OSXSHIFT(objsym) +
		        xshift, Memr[ixver], nsver)
		    call aaddkr (XP_YVERTICES(polysym), XP_OSYSHIFT(objsym) +
		        yshift, Memr[iyver], nsver)
		    Memr[ixver+nsver] = Memr[ixver]
		    Memr[iyver+nsver] = Memr[iyver]
		} else {
		    call xp_pyexpand (XP_XVERTICES(polysym),
		        XP_YVERTICES(polysym), Memr[ixver], Memr[iyver], nsver,
			rannulus)
		    Memr[ixver+nsver] = Memr[ixver]
		    Memr[iyver+nsver] = Memr[iyver]
		    call aaddkr (Memr[ixver], XP_OSXSHIFT(objsym) +
		        xshift, Memr[ixver], nsver + 1)
		    call aaddkr (Memr[iyver], XP_OSYSHIFT(objsym) +
		        yshift, Memr[iyver], nsver + 1)
		}
		call xp_pyexpand (XP_XVERTICES(polysym), XP_YVERTICES(polysym),
		    Memr[oxver], Memr[oyver], nsver, rannulus + wannulus)
		Memr[oxver+nsver] = Memr[oxver]
		Memr[oyver+nsver] = Memr[oyver]
		call aaddkr (Memr[oxver], XP_OSXSHIFT(objsym) +
		    xshift, Memr[oxver], nsver + 1)
		call aaddkr (Memr[oyver], XP_OSYSHIFT(objsym) +
		    yshift, Memr[oyver], nsver + 1)
	    }
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        XP_NSKYPIX(sky) = xp_pskypix (im, Memr[ixver], Memr[iyver],
		    Memr[oxver], Memr[oyver], nsver + 1, Memr[XP_SKYPIX(sky)],
		    Memi[XP_SCOORDS(sky)], XP_SXC(sky), XP_SYC(sky),
		    XP_SNX(sky), XP_SNY(sky))
	        XP_NBADSKYPIX(sky) = 0
	    } else
	        XP_NSKYPIX(sky) = xp_pbskypix (im, Memr[ixver], Memr[iyver],
		    Memr[oxver], Memr[oyver], nsver + 1, datamin, datamax,
		    Memr[XP_SKYPIX(sky)], Memi[XP_SCOORDS(sky)], XP_SXC(sky),
		    XP_SYC(sky), XP_SNX(sky), XP_SNY(sky), XP_NBADSKYPIX(sky))
	    call sfree (sp)
	default:
	    ier = xp_skybuf (xp, im, owx, owy, xver, yver, nver)
	}

	if (XP_NSKYPIX(sky) <= 0)
	    return (XP_SKY_NOPIXELS)
	else
	    return (XP_OK)
end
