include <mach.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/photdef.h"
include "../lib/phot.h"

# XP_MAG -- Compute the magnitudes inside a set of apertures for a single
# object.

int procedure xp_mag (xp, im, wx, wy, xver, yver, nver, skyval, skysig, nsky)

pointer	xp		#I the pointer to the max xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the object x and y coordinates
real	xver[ARB]	#I the x coordinates of the polygon vertices.
real	yver[ARB]	#I the y coordinates of the polygon vertices.
int	nver		#I the number of polygon vertices
real	skyval		#I the input sky value
real	skysig		#I the input sky sigma
int	nsky		#I the number of sky pixels

int	ier, c1, c2, l1, l2, nap
pointer	imp, phot, sp, temp
real	xshift, yshift, datamin, datamax, sky_mode, zmag
bool	strne()
int	xp_magbuf()
real	asumr()

begin
	# Initalize.
	imp = XP_PIMPARS(xp)
	phot = XP_PPHOT(xp)
	XP_PXCUR(phot) = wx
	XP_PYCUR(phot) = wy

        # Make sure the geometry is current.
        call strcpy (XP_PGEOSTRING(phot), XP_POGEOSTRING(phot), SZ_FNAME)
        XP_POGEOMETRY(phot) = XP_PGEOMETRY(phot)
        if (strne (XP_PAPSTRING(phot), XP_POAPSTRING(phot)))
            call xp_sets (xp, PAPSTRING, XP_PAPSTRING(phot))
        XP_POAXRATIO(phot) = XP_PAXRATIO(phot)
        XP_POPOSANGLE(phot) = XP_PPOSANGLE(phot)

	# Make sure the object center is defined and determine the limits
	# of the aperture pixels. 
	if (im == NULL)
	    ier = XP_APERT_NOIMAGE
	else if (IS_INDEFR(wx) || IS_INDEFR(wy))
	    ier = XP_APERT_NOAPERT
	else
	    ier = xp_magbuf (xp, im, wx, wy, xver, yver, nver, c1, c2, l1, l2)

	# Initialize.
	call amovkd (0.0d0, Memd[XP_SUMS(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_AREAS(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_FLUX(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_SUMXSQ(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_SUMXY(phot)], XP_NAPERTS(phot)]
	call amovkd (0.0d0, Memd[XP_SUMYSQ(phot)], XP_NAPERTS(phot)]

	call amovkr (INDEFR, Memr[XP_MAGS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MAGERRS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MPOSANGLES(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MAXRATIOS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MHWIDTHS(phot)], XP_NAPERTS(phot)]

	# Return if there is no image or no aperture.
	if (ier == XP_APERT_NOIMAGE)
	    return (XP_APERT_NOIMAGE)
	if (ier == XP_APERT_NOAPERT)
	    return (XP_APERT_NOAPERT)

	call smark (sp)
	call salloc (temp, XP_NAPERTS(phot), TY_REAL)

	# Determine the true apertures.
	if (XP_PGEOMETRY(phot) == XP_APOLYGON && XP_NAPERTS(phot) == 1)
	    Memr[temp] = 0.0
	else
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

	# Check for INDEF sky.
	if (IS_INDEFR(skyval))
	    sky_mode = 0.0
	else
	    sky_mode = skyval
	
	# Do the aperture photometry.
	switch (XP_PGEOMETRY(phot)) {
	case XP_ACIRCLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_cmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_cbmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	case XP_AELLIPSE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_emeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], XP_PAXRATIO(phot), XP_PPOSANGLE(phot),
		    Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_ebmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], XP_PAXRATIO(phot),
		    XP_PPOSANGLE(phot), Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	case XP_ARECTANGLE:
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call  xp_rmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    Memr[temp], XP_PAXRATIO(phot), XP_PPOSANGLE(phot),
		    Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
		    Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
		    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
		    XP_NMAXAP(phot), XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	        XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_rbmeasure (im, wx, wy, c1, c2, l1, l2, sky_mode,
		    datamin, datamax, Memr[temp], XP_PAXRATIO(phot),
		    XP_PPOSANGLE(phot), Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_NMINAP(phot),
		    XP_ADATAMIN(phot), XP_ADATAMAX(phot))
	    }

	default:
	    xshift = wx - asumr (xver, nver) / nver 
	    yshift = wy - asumr (yver, nver) / nver 
	    if (IS_INDEFR(datamin) && IS_INDEFR(datamax)) {
	        call xp_pmeasure (im, xshift, yshift, xver, yver, nver, c1,
		    c2, l1, l2, sky_mode, Memr[temp], Memd[XP_SUMS(phot)],
		    Memd[XP_AREAS(phot)], Memd[XP_FLUX(phot)],
		    Memd[XP_SUMXSQ(phot)], Memd[XP_SUMXY(phot)],
		    Memd[XP_SUMYSQ(phot)], XP_NMAXAP(phot), XP_ADATAMIN(phot),
		    XP_ADATAMAX(phot))
		    XP_NMINAP(phot) = XP_NMAXAP(phot) + 1
	    } else {
	        call  xp_pbmeasure (im, xshift, yshift, xver, yver, nver, c1,
		    c2, l1, l2, sky_mode, datamin, datamax, Memr[temp],
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

	    # Compute second moments
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
