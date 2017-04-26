include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

# XP_PLIMITS -- Compute the maximum width of the object aperture.

real	procedure xp_plimits (xp, symbol, xver, yver, nver)

pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the object symbol (NULL if undefined)
real	xver[ARB]	#I the user defined x vertices
real	yver[ARB]	#I the user defined y vertices
int	nver		#I the number of vertices

pointer	sp, txver, tyver, str, opsymbol
real	xmin, xmax, ymin, ymax, radius, width
int	xp_stati()
pointer	xp_statp(), stfind()
real	xp_statr()

begin
        call smark (sp)
	radius = xp_statr(xp,ISCALE) * Memr[xp_statp(xp,PAPERTURES) +
	    xp_stati(xp,NAPERTS)-1]
	if (symbol == NULL) {
            if (xp_stati (xp, PGEOMETRY) == XP_APOLYGON) {
		if (radius <= 0.0) {
                    call alimr (xver, nver, xmin, xmax)
                    call alimr (yver, nver, ymin, ymax)
		} else {
		    call salloc (txver, nver, TY_REAL)
		    call salloc (tyver, nver, TY_REAL)
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver],
			nver, radius)
                    call alimr (Memr[txver], nver, xmin, xmax)
                    call alimr (Memr[tyver], nver, ymin, ymax)
		}
                width = max (xmax - xmin, ymax - ymin) + 2.0
            } else
                width = 2.0 * (radius + 1.0)
	} else {

            # Get the polygon symbol if any.
            if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {

                call salloc (str, SZ_FNAME, TY_CHAR)
                call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                    call pargi (XP_ONPOLYGON(symbol))
                opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
		if (radius <= 0.0) {
                    call alimr (XP_XVERTICES(opsymbol),
		        XP_ONVERTICES(opsymbol), xmin, xmax)
                    call alimr (XP_YVERTICES(opsymbol),
		        XP_ONVERTICES(opsymbol), ymin, ymax)
		} else {
		    call salloc (txver, XP_ONVERTICES(opsymbol), TY_REAL)
		    call salloc (tyver, XP_ONVERTICES(opsymbol), TY_REAL)
		    call xp_pyexpand (XP_XVERTICES(opsymbol),
		        XP_YVERTICES(opsymbol), Memr[txver], Memr[tyver],
			XP_ONVERTICES(opsymbol), radius)
                    call alimr (Memr[txver], XP_ONVERTICES(opsymbol),
		        xmin, xmax)
                    call alimr (Memr[tyver], XP_ONVERTICES(opsymbol),
		        ymin, ymax)
		}
                width =  max (xmax - xmin, ymax - ymin) + 2.0

            } else 
                width = 2.0 * (radius + 1.0)
	}
        call sfree (sp)

	return (width)
end


# XP_SLIMITS -- Compute the maximum width of the sky aperture.

real	procedure xp_slimits (xp, symbol, xver, yver, nver)

pointer	xp		#I the pointer to the main xapphot structure
pointer	symbol		#I the object symbol (NULL if undefined)
real	xver[ARB]	#I the user defined x vertices
real	yver[ARB]	#I the user defined y vertices
int	nver		#I the number of vertices

int	nsver
pointer	sp, txver, tyver, str, spsymbol
real	xmin, xmax, ymin, ymax, radius, wannulus, width
int	xp_stati()
pointer	xp_statp(), stfind()
real	xp_statr()

begin
        call smark (sp)
        radius = xp_statr (xp, ISCALE) * (xp_statr(xp,SORANNULUS) +
	    xp_statr(xp,SOWANNULUS) + 1.0)
	wannulus = xp_statr(xp,ISCALE) * xp_statr(xp,SOWANNULUS)
	if (symbol == NULL) {
            if (xp_stati (xp, SGEOMETRY) == XP_SPOLYGON) {
		if (radius <= 0.0) {
                    call alimr (xver, nver, xmin, xmax)
                    call alimr (yver, nver, ymin, ymax)
		} else {
		    call salloc (txver, nver, TY_REAL)
		    call salloc (tyver, nver, TY_REAL)
		    call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver],
			nver, radius)
                    call alimr (Memr[txver], nver, xmin, xmax)
                    call alimr (Memr[tyver], nver, ymin, ymax)
		}
                width = max (xmax - xmin, ymax - ymin) + 2.0
            } else
                width = 2.0 * (radius + 1.0)
	} else {

            # Get the polygon symbol if any.
            if (XP_OSGEOMETRY(symbol) == XP_OPOLYGON) {

                call salloc (str, SZ_FNAME, TY_CHAR)
                call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                    call pargi (XP_OSNPOLYGON(symbol))
                spsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])

                if (XP_ONVERTICES(spsymbol) > 0)
                    nsver = XP_ONVERTICES(spsymbol)
                else
                    nsver = XP_SNVERTICES(spsymbol)
		if (radius <= 0.0) {
                    call alimr (XP_XVERTICES(spsymbol), nsver, xmin, xmax)
                    call alimr (XP_YVERTICES(spsymbol), nsver, ymin, ymax)
		} else {
		    call salloc (txver, nsver, TY_REAL)
		    call salloc (tyver, nsver, TY_REAL)
		    call xp_pyexpand (XP_XVERTICES(spsymbol),
		        XP_YVERTICES(spsymbol), Memr[txver], Memr[tyver],
			nsver, radius)
                    call alimr (Memr[txver], nsver, xmin, xmax)
                    call alimr (Memr[tyver], nsver, ymin, ymax)
		}
                width =  max (xmax - xmin, ymax - ymin) + 2.0

            } else
                width = 2.0 * (radius + 1.0)
	}
        call sfree (sp)

	return (width)
end
