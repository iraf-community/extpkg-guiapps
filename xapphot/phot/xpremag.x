include <mach.h>
include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/photdef.h"
include "../lib/phot.h"

# XP_REMAG -- Recompute the magnitudes inside a set of apertures
# given that the sums and effective areas have already been computed.

int procedure xp_remag (xp, skyval, skysig, nsky)

pointer	xp		#I pointer to the main xapphot structure
real	skyval		#I the sky value
real	skysig		#I the sigma of sky pixel distribution
int	nsky		#I the number of sky pixels

int	nap
pointer	imp, phot
real	zmag

begin
	# Initalize.
	imp = XP_PIMPARS(xp)
	phot = XP_PPHOT(xp)
	call amovkr (INDEFR, Memr[XP_MAGS(phot)], XP_NAPERTS(phot)]
	call amovkr (INDEFR, Memr[XP_MAGERRS(phot)], XP_NAPERTS(phot)]

	# Check for errors.
	if (IS_INDEFR(XP_PXCUR(phot)) || IS_INDEFR(XP_PYCUR(phot)))
	    return (XP_APERT_NOAPERT)
	if (IS_INDEFR(skyval))
	    return (XP_APERT_NOSKYMODE)

	# Compute the magnitudes and errors.
	nap = min (XP_NMINAP(phot) - 1, XP_NMAXAP(phot))
	if (XP_IEMISSION(imp) == YES)
	    call xp_copmags (Memd[XP_FLUX(phot)], Memd[XP_AREAS(phot)],
	        Memr[XP_MAGS(phot)], Memr[XP_MAGERRS(phot)], nap,
	        skyval, skysig, nsky, XP_PZMAG(phot), XP_INOISEMODEL(imp),
		XP_IGAIN(imp))
	else
	    call xp_conmags (Memd[XP_SUMS(phot)], Memd[XP_AREAS(phot)],
	        Memd[XP_FLUX(phot)], Memr[XP_MAGS(phot)],
		Memr[XP_MAGERRS(phot)], nap, skyval, skysig, nsky,
		XP_PZMAG(phot), XP_INOISEMODEL(imp), XP_IGAIN(imp),
		XP_IREADNOISE(imp))

	# Correct for itime.
	zmag = 2.5 * log10 (XP_IETIME(imp))
	call aaddkr (Memr[XP_MAGS(phot)], zmag, Memr[XP_MAGS(phot)], nap)

	# Compute 2nd moments.
	call xp_2moments (Memd[XP_FLUX(phot)], Memd[XP_SUMXSQ(phot)],
	    Memd[XP_SUMXY(phot)], Memd[XP_SUMYSQ(phot)],
	    Memr[XP_MHWIDTHS(phot)], Memr[XP_MAXRATIOS(phot)],
	    Memr[XP_MPOSANGLES(phot)], nap)

	if (XP_NMAXAP(phot) < XP_NAPERTS(phot))
	    return (XP_APERT_OUTOFBOUNDS)
	else if (XP_NMINAP(phot) <= XP_NMAXAP(phot))
	    return (XP_APERT_BADDATA)
	else
	    return (XP_OK)
end
