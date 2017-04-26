include <imhdr.h>
include "../lib/xphotdef.h"
include "../lib/objects.h"
include "../lib/imparsdef.h"
include "../lib/photdef.h"
include "../lib/phot.h"

# XP_MBUFP -- Determine the mapping of the aperture list into the input image.

int procedure xp_mbufp (xp, im, objsym, polysym, xshift, yshift, xver, yver,
	nver, c1, c2, l1, l2)

pointer	xp		#I the pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
pointer	objsym		#I the current object symbol
pointer	polysym		#I the current polygon symbol
real	xshift, yshift	#I the object x and y shifts
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of polygon vertices
int	c1, c2		#I the column limits
int	l1, l2		#I the line limits

int	i, ier
pointer	imp, phot, sp, txver, tyver
real	rbuf, owx, owy
bool	strne()
int	xp_magbuf()
int	xp_cphotpix(), xp_ephotpix(), xp_rphotpix(), xp_pphotpix()

begin
	imp = XP_PIMPARS(xp)
	phot = XP_PPHOT(xp)

	# Check for 0 radius aperture.
	if (XP_OGEOMETRY(objsym) == XP_OINDEF) {
	    if (Memr[XP_PAPERTURES(phot)] < 0.0 && XP_PGEOMETRY(phot) !=
	        XP_APOLYGON)
	        return (XP_APERT_NOAPERT)
	    if (nver < 3 && XP_PGEOMETRY(phot) == XP_APOLYGON)
	        return (XP_APERT_NOAPERT)
	} else {
	    if (Memr[XP_PAPERTURES(phot)] < 0.0 && XP_OGEOMETRY(objsym) !=
	        XP_OPOLYGON)
	        return (XP_APERT_NOAPERT)
	    if (XP_OGEOMETRY(objsym) == XP_OPOLYGON) {
		if (XP_ONVERTICES(polysym) < 3)
	            return (XP_APERT_NOAPERT)
	    }
	}

        # Check that the geometry is current.
        XP_POAXRATIO(phot) = XP_OAXRATIO(objsym)
        XP_POPOSANGLE(phot) = XP_OPOSANG(objsym)
        if (strne (XP_OAPERTURES(objsym), XP_PAPSTRING(phot)))
            call xp_sets (xp, POAPSTRING, XP_OAPERTURES(objsym))

	owx = XP_OXINIT(objsym) + xshift
	owy = XP_OYINIT(objsym) + yshift

	# Compute the maximum aperture size
	XP_NAPIX(phot) = NULL
	switch (XP_OGEOMETRY(objsym)) {

	case XP_OCIRCLE:
            XP_POGEOMETRY(phot) = XP_ACIRCLE
            call strcpy ("circle", XP_POGEOSTRING(phot), SZ_FNAME)
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_cphotpix (im, owx, owy, rbuf, c1, c2,
		    l1, l2)
	        XP_AXC(phot) = owx - c1 + 1 
	        XP_AYC(phot) = owy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }

	case XP_OELLIPSE:
            XP_POGEOMETRY(phot) = XP_AELLIPSE
            call strcpy ("ellipse", XP_POGEOSTRING(phot), SZ_FNAME)
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_ephotpix (im, owx, owy, rbuf,
		    XP_POAXRATIO(phot), XP_POPOSANGLE(phot), c1, c2, l1, l2)
	        XP_AXC(phot) = owx - c1 + 1 
	        XP_AYC(phot) = owy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }

	case XP_ORECTANGLE:
            XP_POGEOMETRY(phot) = XP_ARECTANGLE
            call strcpy ("rectangle", XP_POGEOSTRING(phot), SZ_FNAME)
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  2. * Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
	        XP_NAPIX(phot) = xp_rphotpix (im, owx, owy, rbuf,
		    XP_POAXRATIO(phot), XP_POPOSANGLE(phot), c1, c2, l1, l2)
	        XP_AXC(phot) = owx - c1 + 1 
	        XP_AYC(phot) = owy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }

	case XP_OPOLYGON:
            XP_POGEOMETRY(phot) = XP_APOLYGON
            call strcpy ("polygon", XP_POGEOSTRING(phot), SZ_FNAME)
	    call smark (sp)
	    call salloc (txver, XP_ONVERTICES(polysym), TY_REAL)
	    call salloc (tyver, XP_ONVERTICES(polysym), TY_REAL)
	    for (i = XP_NAPERTS(phot); XP_NAPIX(phot) == 0 && i >= 1;
	        i = i - 1) {
	        rbuf =  Memr[XP_PAPERTURES(phot)+i-1] * XP_ISCALE(imp)
		if (rbuf <= 0.0) {
		    call amovr (XP_XVERTICES(polysym), Memr[txver], 
			XP_ONVERTICES(polysym))
		    call amovr (XP_YVERTICES(polysym), Memr[tyver], 
			XP_ONVERTICES(polysym))
		} else
		    call xp_pyexpand (XP_XVERTICES(polysym),
		        XP_YVERTICES(polysym), Memr[txver], Memr[tyver],
			XP_ONVERTICES(polysym), rbuf)
		call aaddkr (Memr[txver], XP_OXSHIFT(objsym) + xshift,
		    Memr[txver], XP_ONVERTICES(polysym) + 1)
		call aaddkr (Memr[tyver], XP_OYSHIFT(objsym) + yshift,
		    Memr[tyver], XP_ONVERTICES(polysym) + 1)
	        XP_NAPIX(phot) = xp_pphotpix (im, Memr[txver], Memr[tyver],
		    XP_ONVERTICES(polysym), c1, c2, l1, l2)
	        XP_AXC(phot) = owx - c1 + 1 
	        XP_AYC(phot) = owy - l1 + 1
	        XP_ANX(phot) = c2 - c1 + 1
	        XP_ANY(phot) = l2 - l1 + 1
	        XP_NMAXAP(phot) = i
	    }
	    call sfree (sp)

	default:
	    ier = xp_magbuf (xp, im, owx, owy, xver, yver, nver, c1, c2, l1,
		l2)
	}

	# Return the appropriate error code.
	if (XP_NAPIX(phot) == 0) {
	    return (XP_APERT_NOAPERT)
	} else if (XP_NMAXAP(phot) < XP_NAPERTS(phot)) {
	    return (XP_APERT_OUTOFBOUNDS)
	} else {
	    return (XP_OK)
	}
end
