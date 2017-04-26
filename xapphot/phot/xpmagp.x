include <mach.h>
include "../lib/xphotdef.h"
include "../lib/objects.h"
include "../lib/imparsdef.h"
include "../lib/photdef.h"
include "../lib/phot.h"

# XP_MAGP -- Compute the magnitudes inside a set of apertures for a single
# object.

int procedure xp_magp (xp, im, objsym, xshift, yshift, xver, yver, nver,
	skyval, skysig, nsky)

pointer	xp		#I the pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
pointer	objsym		#I the current object symbol
real	xshift, yshift	#I the object x and y shift
real	xver[ARB]	#I the x coordinates of the polygon vertices.
real	yver[ARB]	#I the y coordinates of the polygon vertices.
int	nver		#I the number of polygon vertices
real	skyval		#I the input sky value
real	skysig		#I the input sky sigma
int	nsky		#I the number of sky pixels

int	ier, c1, c2, l1, l2, nap
pointer	sp, str, temp, polysym, imp, phot
real	owx, owy, datamin, datamax, sky_mode, zmag
bool	strne()
int	xp_mbufp(), xp_mag()
pointer	xp_statp(), stfind()

begin
	# User default apertures if the symbol is NULL.
	if (objsym == NULL)
	    return (xp_mag (xp, im, INDEFR, INDEFR, xver, yver, nver,
	        skyval, skysig, nsky))

	if (XP_ONPOLYGON(objsym) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(objsym))
            polysym = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	    call sfree (sp)
	} else
	    polysym = NULL

	# Initalize.
	imp = XP_PIMPARS(xp)
	phot = XP_PPHOT(xp)
	owx = XP_OXINIT(objsym) + xshift
	XP_PXCUR(phot) = owx
	owy = XP_OYINIT(objsym) + yshift
	XP_PYCUR(phot) = owy

	# If the object is undefined use the default geometry.
	if (XP_OGEOMETRY(objsym) == XP_OINDEF)
	    return (xp_mag (xp, im, owx, owy, xver, yver, nver, skyval, skysig,
	        nsky))

	# Check that the geometry is current.
	#XP_POAXRATIO(phot) = XP_OAXRATIO(objsym)
	#XP_POPOSANGLE(phot) = XP_OPOSANG(objsym)
	if (strne (XP_OAPERTURES(objsym), XP_PAPSTRING(phot)))
	    call xp_sets (xp, POAPSTRING, XP_OAPERTURES(objsym))

	# Make sure the object center is defined and determine the limits
	# of the aperture pixels.
	if (im == NULL)
	    ier = XP_APERT_NOIMAGE
	else if (IS_INDEFR(owx) || IS_INDEFR(owy))
	    ier = XP_APERT_NOAPERT
	else
	    ier = xp_mbufp (xp, im, objsym, polysym, xshift, yshift, xver, yver,
	        nver, c1, c2, l1, l2)

	# Initialize.
	call amovkd (0.0d0, Memd[XP_SUMS(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_AREAS(phot)], XP_NAPERTS(phot))
	call amovkd (0.0d0, Memd[XP_FLUX(phot)], XP_NAPERTS(phot))
	call amovkd (0.0d0, Memd[XP_SUMXSQ(phot)], XP_NAPERTS(phot))
	call amovkd (0.0d0, Memd[XP_SUMXY(phot)], XP_NAPERTS(phot))
	call amovkd (0.0d0, Memd[XP_SUMYSQ(phot)], XP_NAPERTS(phot))

	call amovkr (INDEFR, Memr[XP_MAGS(phot)], XP_NAPERTS(phot))
	call amovkr (INDEFR, Memr[XP_MAGERRS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MPOSANGLES(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MAXRATIOS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MHWIDTHS(phot)], XP_NAPERTS(phot)]

	if (ier == XP_APERT_NOIMAGE)
	    return (XP_APERT_NOIMAGE)
	if (ier == XP_APERT_NOAPERT)
	    return (XP_APERT_NOAPERT)

	# Determine the true apertures.
	call smark (sp)
	call salloc (temp, XP_NAPERTS(phot), TY_REAL)
	call amulkr (Memr[XP_PAPERTURES(phot)], XP_ISCALE(imp), Memr[temp],
	    XP_NAPERTS(phot)]

	# Determine the true datamin and datamax parameters,
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

	if (IS_INDEFR(skyval))
	    sky_mode = 0.0
	else
	    sky_mode = skyval
	
	# Do the aperture photometry.
	switch (XP_OGEOMETRY(objsym)) {
	case XP_OCIRCLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_cmeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_cbmeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	case XP_OELLIPSE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_emeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], XP_POAXRATIO(phot), XP_POPOSANGLE(phot),
		    Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_ebmeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], XP_POAXRATIO(phot),
		    XP_POPOSANGLE(phot), Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	case XP_ORECTANGLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_rmeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], XP_POAXRATIO(phot), XP_POPOSANGLE(phot),
		    Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_rbmeasure (im, owx, owy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], XP_POAXRATIO(phot),
		    XP_POPOSANGLE(phot), Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	case XP_OPOLYGON:
	    # Compute the magnitudes and errors.
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_pmeasure (im, XP_OXSHIFT(objsym) + xshift,
		    XP_OYSHIFT(objsym) + yshift, XP_XVERTICES(polysym),
		    XP_YVERTICES(polysym), XP_ONVERTICES(polysym), c1, c2,
		    l1, l2, sky_mode, Memr[temp], Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_ADATAMIN(phot),
		    XP_ADATAMAX(phot))
		    XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call xp_pbmeasure (im, XP_OXSHIFT(objsym) + xshift,
		    XP_OYSHIFT(objsym) + yshift, XP_XVERTICES(polysym),
		    XP_YVERTICES(polysym), XP_ONVERTICES(polysym), c1, c2,
		    l1, l2, sky_mode, datamin, datamax, Memr[temp],
		    Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_NMINAP(phot), XP_ADATAMIN(phot),
		    XP_ADATAMAX(phot))
	    }
	}


	# Make sure that the sky value has been defined.
	if (IS_INDEFR(skyval))
	    ier = XP_APERT_NOSKYMODE
	else {

	    # Check for bad pixels.
	    if ((ier == XP_OK) && (XP_NMINAP(phot) <= XP_NMAXAP(phot)))
		ier = XP_APERT_BADDATA
	    nap = min (XP_NMINAP(phot) - 1, XP_NMAXAP(phot))

	    # Compute the magnitudes and errors.
	    if (XP_IEMISSION(imp) == YES)
	        call xp_copmags (Memd[XP_FLUX(phot)], Memd[XP_AREAS(phot)],
	            Memr[XP_MAGS(phot)], Memr[XP_MAGERRS(phot)],
		    nap, skyval, skysig, nsky, XP_PZMAG(phot),
		    XP_INOISEMODEL(imp), XP_IGAIN(imp))
	    else
	        call xp_conmags (Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
	            Memd[XP_FLUX(phot)], Memr[XP_MAGS(phot)],
		    Memr[XP_MAGERRS(phot)], nap, skyval, skysig, nsky,
		    XP_PZMAG(phot), XP_INOISEMODEL(imp), XP_IGAIN(imp),
		    XP_IREADNOISE(imp))

	    # Compute correction for itime.
	    zmag = 2.5 * log10 (XP_IETIME(imp))
	    call aaddkr (Memr[XP_MAGS(phot)], zmag, Memr[XP_MAGS(phot)], nap)

	    # Compute the second moments.
	    call xp_2moments (Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
	        Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		Memr[XP_MHWIDTHS(phot)], Memr[XP_MAXRATIOS(phot)],
		Memr[XP_MPOSANGLES(phot)], nap)
	}

	call sfree (sp)
	if (ier != XP_OK)
	    return (ier)
	else
	    return (XP_OK)
end
