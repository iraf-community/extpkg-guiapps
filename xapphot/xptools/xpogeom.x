include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/fitsky.h"
include "../lib/phot.h"


# XP_OGEOMETRY -- Format the object geometry string.

procedure xp_ogeometry (xp, symbol, oxver, oyver, nover, sxver, syver, nsver,
	ogeom, max_ogeom)

pointer	xp		#I pointer to the xapphot structure
pointer	symbol		#I pointer to object in object symbol table 
real	oxver[ARB]	#I x vertices of the user photometry polygon
real	oyver[ARB]	#I y vertices of the user photometry polygon
int	nover		#I the number of object vertices
real	sxver[ARB]	#I x vertices of the user sky polygon
real	syver[ARB]	#I y vertices of the user sky polygon
int	nsver		#I the number of sky vertices
char	ogeom[ARB]	#O the object geometry parameter
int	max_ogeom	#I the maximum size of the geometry string

int	i, naperts, strfd, nver
pointer	sp, aperts, str, txver, tyver, dogeom, dsgeom, opsymbol, spsymbol
real	x, y, ratio, theta, rapert, scale, r1, r2
int	xp_decaperts(), stropen()
bool	streq()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	if (symbol == NULL)
	    return

	# Allocate working space.
	call smark (sp)
	call salloc (aperts, MAX_NOBJ_APERTURES, TY_REAL)
	call salloc (str, SZ_FNAME, TY_CHAR)
	txver = NULL
	tyver = NULL

	# Get the object geometry.
	x = XP_OXINIT(symbol)
	y = XP_OYINIT(symbol)
	ratio = XP_OAXRATIO(symbol)
	theta = XP_OPOSANG(symbol)
	if (streq (XP_OAPERTURES(symbol), "INDEF")) {
	    Memr[aperts] = 0.0
	    naperts = 1
	} else
	    naperts = xp_decaperts (XP_OAPERTURES(symbol), Memr[aperts],
	        MAX_NOBJ_APERTURES)
	scale = xp_statr (xp, ISCALE)
	if (XP_ONPOLYGON(symbol) > 0) {
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	} else
	    opsymbol = NULL
        if (XP_OSNPOLYGON(symbol) > 0) {
            call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_OSNPOLYGON(symbol))
            spsymbol = stfind (xp_statp(xp,POLYGONLIST), Memc[str])
        } else
            spsymbol = 0

	# Open the geometry string as a file.
	ogeom[1] = EOS
	strfd = stropen (ogeom, max_ogeom, NEW_FILE)
	call fprintf (strfd, " { ")

	switch (XP_OGEOMETRY(symbol)) {

	case XP_OCIRCLE:
	    call fprintf (strfd, " { %0.2f %0.2f circle %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[aperts+naperts-1])

	case XP_OELLIPSE:
	    call fprintf (strfd, " { %0.2f %0.2f ellipse %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[aperts+naperts-1])
		call pargr (ratio)
		call pargr (theta)

	case XP_ORECTANGLE:
	    call fprintf (strfd,
	        " { %0.2f %0.2f rectangle %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[aperts+naperts-1])
		call pargr (ratio)
		call pargr (theta)

	case XP_OPOLYGON:
	    rapert = scale * Memr[aperts+naperts-1]
	    nver = XP_ONVERTICES(opsymbol)
	    call malloc (txver, nver, TY_REAL)
	    call malloc (tyver, nver, TY_REAL)
	    if (rapert <= 0.0) {
		call aaddkr (XP_XVERTICES(opsymbol), XP_OXSHIFT(symbol),
		    Memr[txver], nver)
		call aaddkr (XP_YVERTICES(opsymbol), XP_OYSHIFT(symbol),
		    Memr[tyver], nver)
	    } else {
		call xp_pyexpand (XP_XVERTICES(opsymbol),
		    XP_YVERTICES(opsymbol), Memr[txver], Memr[tyver], nver,
		    rapert)
		call aaddkr (Memr[txver], XP_OXSHIFT(symbol), Memr[txver],
		    nver)
		call aaddkr (Memr[tyver], XP_OYSHIFT(symbol), Memr[tyver],
		    nver)
	    }
	    call fprintf (strfd, "{ %0.2f %0.2f polygon %d  { { ")
		call pargr (x)
		call pargr (y)
		call pargi (nver)
	    do i = 1, nver {
		call fprintf (strfd, " { %0.2f %0.2f } ")
		    call pargr (Memr[txver+i-1])
		    call pargr (Memr[tyver+i-1])
	    }
	    call fprintf (strfd, " } } } ")

	default:
	    call salloc (dogeom, max_ogeom, TY_CHAR)
	    call xp_dogeometry (xp, x, y, oxver, oyver, nover, Memc[dogeom],
	        max_ogeom)
	    call fprintf (strfd, "%s")
		call pargstr (Memc[dogeom])
	}

	if (! IS_INDEFR(XP_OSXINIT(symbol)))
	    x = XP_OSXINIT(symbol)
	if (! IS_INDEFR(XP_OSYINIT(symbol)))
	    y = XP_OSYINIT(symbol)
	ratio = XP_OSAXRATIO(symbol)
	theta = XP_OSPOSANG(symbol)

	switch (XP_OSGEOMETRY(symbol)) {

	case XP_OCIRCLE:
	    if (! IS_INDEFR(XP_OSRIN(symbol)))
	        r1 = XP_OSRIN(symbol)
	    else
	        r1 = xp_statr (xp, SRANNULUS)
	    if (! IS_INDEFR(XP_OSROUT(symbol)))
	        r2 = XP_OSROUT(symbol)
	    else
	        r2 = xp_statr (xp, SRANNULUS) + xp_statr (xp, SWANNULUS)
	    call fprintf (strfd, " { %0.2f %0.2f circle %0.2f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (r1)
		call pargr (r2)

	case XP_OELLIPSE:
	    if (! IS_INDEFR(XP_OSRIN(symbol)))
	        r1 = XP_OSRIN(symbol)
	    else
	        r1 = xp_statr (xp, SRANNULUS)
	    if (! IS_INDEFR(XP_OSROUT(symbol)))
	        r2 = XP_OSROUT(symbol)
	    else
	        r2 = xp_statr (xp, SRANNULUS) + xp_statr (xp, SWANNULUS)
	    call fprintf (strfd,
	        " { %0.2f %0.2f ellipse %0.2f %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (r1)
		call pargr (r2)
		call pargr (ratio)
		call pargr (theta)

	case XP_ORECTANGLE:
	    if (! IS_INDEFR(XP_OSRIN(symbol)))
	        r1 = XP_OSRIN(symbol)
	    else
	        r1 = xp_statr (xp, SRANNULUS)
	    if (! IS_INDEFR(XP_OSROUT(symbol)))
	        r2 = XP_OSROUT(symbol)
	    else
	        r2 = xp_statr (xp, SRANNULUS) + xp_statr (xp, SWANNULUS)
	    call fprintf (strfd,
	        " { %0.2f %0.2f rectangle %0.2f %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (r1)
		call pargr (r2)
		call pargr (ratio)
		call pargr (theta)

	case XP_OPOLYGON:
	    if (XP_ONVERTICES(spsymbol) > 0)
	        nver = XP_ONVERTICES(spsymbol)
	    else
	        nver = XP_SNVERTICES(spsymbol)
	    if (txver == NULL)
	        call malloc (txver, nver, TY_REAL)
	    else
	        call realloc (txver, nver, TY_REAL)
	    if (tyver == NULL)
	        call malloc (tyver, nver, TY_REAL)
	    else
	        call realloc (tyver, nver, TY_REAL)
	    if (! IS_INDEFR(XP_OSRIN(symbol)) &&
	        ! IS_INDEFR(XP_OSROUT(symbol))) {
	        r1 = XP_OSRIN(symbol)
	        r2 = XP_OSROUT(symbol)
	    } else {
	        r1 = xp_statr (xp, SRANNULUS)
	        r2 = xp_statr (xp, SWANNULUS)
	    }

	    if ((XP_OSRIN(symbol) + XP_OSROUT(symbol)) <= 0.0) {
		if (XP_ONVERTICES(spsymbol) > 0) {
		    call aaddkr (XP_XVERTICES(spsymbol), XP_OSXSHIFT(symbol),
		        Memr[txver], nver)
		    call aaddkr (XP_YVERTICES(spsymbol), XP_OSYSHIFT(symbol),
		        Memr[tyver], nver)
		} else {
		     call aaddkr (XP_XVERTICES(spsymbol), XP_OSXSHIFT(symbol),
		         Memr[txver], nver)
		    call aaddkr (XP_YVERTICES(spsymbol), XP_OSYSHIFT(symbol),
		        Memr[tyver], nver)
		}
	        call fprintf (strfd, " { %0.2f %0.2f polygon %d  ")
		    call pargr (x)
		    call pargr (y)
		    call pargi (nver)
	        call fprintf (strfd, " { ")
	        do i = 1, nver {
		    call fprintf (strfd, " { %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } ")
	        call fprintf (strfd, " { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } }")

	    } else {

	        call fprintf (strfd, "{ %0.2f %0.2f polygon %d ")
		    call pargr (x)
		    call pargr (y)
		    call pargi (nver)
		if (XP_ONVERTICES(spsymbol) > 0)
		    call xp_pyexpand (XP_XVERTICES(spsymbol),
		        XP_YVERTICES(spsymbol), Memr[txver], Memr[tyver],
			nver, r1)
		else
		    call xp_pyexpand (XP_XVERTICES(spsymbol),
			XP_YVERTICES(spsymbol), Memr[txver], Memr[tyver],
			nver, r1)
		call aaddkr (Memr[txver], XP_OSXSHIFT(symbol), Memr[txver],
		    nver)
		call aaddkr (Memr[tyver], XP_OSYSHIFT(symbol), Memr[tyver],
		    nver)
		call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")

		if (XP_ONVERTICES(spsymbol) > 0)
		    call xp_pyexpand (XP_XVERTICES(spsymbol),
			XP_YVERTICES(spsymbol), Memr[txver],
			Memr[tyver], nver, r1 + r2)
		else
		    call xp_pyexpand (XP_XVERTICES(spsymbol),
			XP_YVERTICES(spsymbol), Memr[txver],
			Memr[tyver], nver, r1 + r2)
		call aaddkr (Memr[txver], XP_OSXSHIFT(symbol), Memr[txver],
		    nver)
		call aaddkr (Memr[tyver], XP_OSYSHIFT(symbol), Memr[tyver],
		    nver)
		call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")
	        call fprintf (strfd, "} ")
	    }

	default:
	    call salloc (dsgeom, max_ogeom, TY_CHAR)
	    call xp_dsgeometry (xp, x, y, sxver, syver, nsver, Memc[dsgeom],
	        max_ogeom)
	    call fprintf (strfd, "%s")
		call pargstr (Memc[dsgeom])
	}

	# Free space.
	call fprintf (strfd, " } ")
	call close (strfd)
	if (txver != NULL)
	    call mfree (txver, TY_REAL)
	if (tyver != NULL)
	    call mfree (tyver, TY_REAL)
	call sfree (sp)
end


# XP_DOGEOMETRY -- Format the default object geometry string.

procedure xp_dogeometry (xp, x, y, xver, yver, nver, pgeom, max_pgeom)

pointer	xp		#I pointer to the xapphot structure
real	x, y		#I the input coordinates
real	xver[ARB]	#I the x vertices of the input user polygon
real	yver[ARB]	#I the y vertices of the input user polygon
int	nver		#I the number of vertices 
char	pgeom[ARB]	#O the object geometry parameter
int	max_pgeom	#I the maximum size of the geometry string

int	i, naperts, strfd
pointer	txver, tyver
real	ratio, theta, xshift, yshift, rapert, scale
int	xp_stati(), stropen()
pointer	xp_statp()
real	xp_statr(), asumr()

begin
	txver = NULL
	tyver = NULL

	# Get the object geometry.
	ratio = xp_statr (xp, PAXRATIO)
	theta = xp_statr (xp, PPOSANGLE)
	naperts = xp_stati (xp, NAPERTS)
	scale = xp_statr (xp, ISCALE)

	# Open the geometry string as a file.
	pgeom[1] = EOS
	strfd = stropen (pgeom, max_pgeom, NEW_FILE)

	switch (xp_stati(xp, PGEOMETRY)) {

	case XP_ACIRCLE:
	    call fprintf (strfd, " { %0.2f %0.2f circle %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[xp_statp(xp,PAPERTURES)+naperts-1])

	case XP_AELLIPSE:
	    call fprintf (strfd,
	        " { %0.2f %0.2f ellipse %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[xp_statp(xp,PAPERTURES)+naperts-1])
		call pargr (ratio)
		call pargr (theta)

	case XP_ARECTANGLE:
	    call fprintf (strfd,
	        " { %0.2f %0.2f rectangle %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (Memr[xp_statp(xp,PAPERTURES)+naperts-1])
		call pargr (ratio)
		call pargr (theta)

	case XP_APOLYGON:
            call malloc (txver, nver + 1, TY_REAL)
            call malloc (tyver, nver + 1, TY_REAL)
            xshift = x - asumr (xver, nver) / nver
            yshift = y - asumr (yver, nver) / nver
            if (naperts == 1) {
                call amovr (xver, Memr[txver], nver)
                call amovr (yver, Memr[tyver], nver)
            } else {
                rapert = scale * Memr[xp_statp(xp, PAPERTURES)+naperts-1]
                call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], nver,
		    rapert)
            }
            call aaddkr (Memr[txver], xshift, Memr[txver], nver)
            call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
	    call fprintf (strfd, "{ %0.2f %0.2f polygon %d { { ")
		call pargr (x)
		call pargr (y)
		call pargi (nver)
	    do i = 1, nver {
		call fprintf (strfd, " { %0.2f %0.2f } ")
		    call pargr (Memr[txver+i-1])
		    call pargr (Memr[tyver+i-1])
	    }
	    call fprintf (strfd, " } } } ")
	}

	if (txver != NULL)
	    call mfree (txver, TY_REAL)
	if (tyver != NULL)
	    call mfree (tyver, TY_REAL)
	call close (strfd)
end


# XP_DSGEOMETRY -- Format the default sky geometry string.

procedure xp_dsgeometry (xp, x, y, xver, yver, nver, sgeom, max_sgeom)

pointer	xp		#I pointer to the xapphot structure
real	x, y		#I the input coordinates
real	xver[ARB]	#I the x vertices of the input user sky polygon
real	yver[ARB]	#I the y vertices of the input user sky polygon
int	nver		#I the number of vertices 
char	sgeom[ARB]	#O the sky geometry parameter
int	max_sgeom	#I the maximum size of the geometry string

int	i, strfd
pointer	txver, tyver
real	ratio, theta, xshift, yshift, scale
int	xp_stati(), stropen()
real	xp_statr(), asumr()

begin
	txver = NULL
	tyver = NULL

	# Get the object geometry.
	ratio = xp_statr (xp, SAXRATIO)
	theta = xp_statr (xp, SPOSANGLE)
	scale = xp_statr (xp, ISCALE)

	# Open the geometry string as a file.
	sgeom[1] = EOS
	strfd = stropen (sgeom, max_sgeom, NEW_FILE)

	switch (xp_stati(xp, SGEOMETRY)) {

	case XP_SCIRCLE:
	    call fprintf (strfd, " { %0.2f %0.2f circle %0.2f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (xp_statr(xp,SRANNULUS))
		call pargr (xp_statr(xp,SRANNULUS) + xp_statr (xp, SWANNULUS))

	case XP_SELLIPSE:
	    call fprintf (strfd,
	        " { %0.2f %0.2f ellipse %0.2f %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (xp_statr(xp,SRANNULUS))
		call pargr (xp_statr(xp,SRANNULUS) + xp_statr (xp, SWANNULUS))
		call pargr (ratio)
		call pargr (theta)

	case XP_SRECTANGLE:
	    call fprintf (strfd,
	        " { %0.2f %0.2f rectangle %0.2f %0.2f %0.3f %0.2f } ")
		call pargr (x)
		call pargr (y)
		call pargr (xp_statr(xp,SRANNULUS))
		call pargr (xp_statr(xp,SRANNULUS) + xp_statr (xp, SWANNULUS))
		call pargr (ratio)
		call pargr (theta)

	case XP_SPOLYGON:
            call malloc (txver, nver + 1, TY_REAL)
            call malloc (tyver, nver + 1, TY_REAL)
            xshift = x - asumr (xver, nver) / nver
            yshift = y - asumr (yver, nver) / nver
	        call fprintf (strfd, " { %0.2f %0.2f polygon %d  ")
	        call pargr (x)
	        call pargr (y)
	        call pargi (nver)
	    if ((xp_statr (xp, SRANNULUS) + xp_statr (xp, SWANNULUS)) <= 0.0) {
                call aaddkr (xver, xshift, Memr[txver], nver)
                call aaddkr (yver, yshift, Memr[tyver], nver)
	        call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, " { %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")
	        call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")
	    } else {
		call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], nver,
		    scale * xp_statr (xp, SRANNULUS))
		call aaddkr (Memr[txver], xshift, Memr[txver], nver)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
		call xp_pyexpand (xver, yver, Memr[txver], Memr[tyver], nver,
		    scale * (xp_statr (xp, SRANNULUS) + xp_statr(xp,
		    SWANNULUS)))
		call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")
		call aaddkr (Memr[txver], xshift, Memr[txver], nver)
		call aaddkr (Memr[tyver], yshift, Memr[tyver], nver)
		call fprintf (strfd, " { { ")
	        do i = 1, nver {
		    call fprintf (strfd, "{ %0.2f %0.2f } ")
		        call pargr (Memr[txver+i-1])
		        call pargr (Memr[tyver+i-1])
	        }
	        call fprintf (strfd, " } } ")
	    }
	    call fprintf (strfd, " } ")
	}

	if (txver != NULL)
	    call mfree (txver, TY_REAL)
	if (tyver != NULL)
	    call mfree (tyver, TY_REAL)
	call close (strfd)
end
