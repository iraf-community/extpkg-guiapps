include <gset.h>
include <gim.h>
include <math.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/objects.h"

# XP_OPENOBJECTS -- Open the objects and polygons symbol tables.

procedure xp_openobjects (xp, objptr, polyptr)

pointer	xp		#I   pointer to the main xapphot descriptor
pointer	objptr		#O pointer to the objects list symbol table
pointer	polyptr		#O pointer to the polygons list symbol table

pointer	xp_statp(), stopen()

begin
	# Open the objects symbol table.
	if (xp_statp (xp, OBJLIST) != NULL)
	    call stclose (xp_statp (xp, OBJLIST))
	objptr = stopen ("objsymlist", 2 * DEF_LEN_OBJLIST, DEF_LEN_OBJLIST,
	    10 * DEF_LEN_OBJLIST)
	call xp_setp (xp, OBJLIST, objptr)

	# Open the polygon symbol table.
	if (xp_statp (xp, POLYGONLIST) != NULL)
	    call stclose (xp_statp (xp, POLYGONLIST))
	polyptr = stopen ("polygonsymlist", 2 * DEF_LEN_POLYGONLIST,
	    DEF_LEN_POLYGONLIST, 10 * DEF_LEN_POLYGONLIST)
	call xp_setp (xp, POLYGONLIST, polyptr)
end


# XP_CLSOBJECTS -- Close the objects and polygons symbol tables.

procedure xp_clsobjects (xp)

pointer	xp		#I pointer to the main xapphot descriptor

pointer	xp_statp()

begin
	if (xp_statp (xp, OBJLIST) != NULL)
	    call stclose (xp_statp (xp, OBJLIST))
	call xp_setp (xp, OBJLIST, NULL)
	if (xp_statp (xp, POLYGONLIST) != NULL)
	    call stclose (xp_statp (xp, POLYGONLIST))
	call xp_setp (xp, POLYGONLIST, NULL)
end


# XP_ROBJECTS -- Read the object list into the symbol table in memory.

int procedure xp_robjects (ol, xp, mode)

int	ol		#I the input objects file descriptor
pointer	xp		#I pointer to the main xapphot descriptor
int	mode		#I mode of reading the object list

char	sdelim, pdelim
int	i, nobjects, npolygons, oshape, novertices, nsvertices, sshape, noscan
int	nopolygons, nspolygons, opolygon, spolygon
pointer	stptr, plyptr, symbol, psymbol, sp, name, geometry, apertures
pointer	oxver, oyver, sxver, syver
real	x, y, oratio, otheta, oxshift, oyshift, xv, yv, xs, ys, rsin, rsout
real	sratio, stheta, sxshift, syshift
bool	streq()
int	fscan(), nscan(), strdic(), stnsymbols(), ctor()
pointer	xp_statp(), stenter(), stfind(), stnext(), sthead()
real	asumr()

begin
	# Check for a null object list descriptor.
	if (ol == NULL)
	    return (-1)

	# Rewind the coordinate list if the mode of creating the input object
	# lists is new. Delete any existing symbol table and create a new one.
	if (mode == RLIST_NEW) {
	    call seek (ol, BOF)
	    call xp_openobjects (xp, stptr, plyptr)
	} else if (xp_statp (xp, OBJLIST) == NULL) {
	    call xp_openobjects (xp, stptr, plyptr)
	} else {
	    stptr = xp_statp (xp, OBJLIST)
	    plyptr = xp_statp (xp, POLYGONLIST)
	}
	
	# Allocate some space.
	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (apertures, SZ_FNAME, TY_CHAR)
	call salloc (geometry, SZ_FNAME, TY_CHAR)
	call salloc (oxver, MAX_NOBJ_VERTICES + 1, TY_REAL)
	call salloc (oyver, MAX_NOBJ_VERTICES + 1, TY_REAL)
	call salloc (sxver, MAX_NOBJ_VERTICES + 1, TY_REAL)
	call salloc (syver, MAX_NOBJ_VERTICES + 1, TY_REAL)

	# Initialize the object list reading mode.
	if (mode == RLIST_TEMP) {
	    nobjects = 0
	    npolygons = stnsymbols (plyptr, 0)
	    nopolygons = 0
	    nspolygons = 0
	} else {
	    nobjects = stnsymbols (stptr, 0)
	    npolygons = stnsymbols (plyptr, 0)
	    nopolygons = 0
	    nspolygons = 0
	}

	# Count the number of object and sky polygons.
	psymbol = sthead (plyptr)
	do i = 1, npolygons {
	    if (psymbol == NULL)
	        break
	    if (XP_ONVERTICES(psymbol) > 0)
	        nopolygons = i
	    if (XP_SNVERTICES(psymbol) > 0)
		nspolygons = i
	    psymbol = stnext (plyptr, psymbol)
	}

	# Read the coordinates into memory.
	while (fscan (ol) != EOF) {

	    # Get the x and y position.
	    call gargr (x)
	    call gargr (y)
	    if (nscan() < 2)
		next

	    # Get the object geometry.
	    call gargwrd (Memc[geometry], SZ_FNAME)
	    if (Memc[geometry] == ';') {
		sdelim = ';'
		oshape = 0
	    } else {
		sdelim = '.'
	        oshape = strdic (Memc[geometry], Memc[geometry], SZ_FNAME,
	            OGEOMETRIES)
	    }
	    opolygon = 0

	    # Decode the object geometry.
	    switch (oshape) {

	    # Get the circular aperture list.
	    case XP_OCIRCLE:
	        call gargwrd (Memc[apertures], SZ_FNAME)
		if (Memc[apertures] == ';') {
		    sdelim = ';'
		    call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		} else if (nscan() < 4) {
		    call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		}
		if (streq (Memc[apertures], "INDEF"))
		    oshape = XP_OINDEF
		oratio = 1.0
		otheta = 0.0
		oxshift = 0.0
		oyshift = 0.0

	    # Decode the elliptical or ractangular aperture list.
	    case XP_OELLIPSE, XP_ORECTANGLE, XP_OINDEF:
		i = 1
	        call gargwrd (Memc[apertures], SZ_FNAME)
		call gargwrd (Memc[geometry], SZ_FNAME)
		if (Memc[apertures] == ';' || nscan() < 4) {
		    if (Memc[apertures] == ';')
		        sdelim = ';'
		    call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		    oshape = XP_OINDEF
		    oratio = 1.0
		    otheta = 0.0
		} else if (Memc[geometry] == ';') {
		    sdelim = ';'
		    oratio = 1.0
		    otheta = 0.0
		} else if (ctor (Memc[geometry], i, oratio) <= 0) {
		    oratio = 1.0
		    otheta = 0.0
		} else {
		   call gargwrd (Memc[geometry], SZ_FNAME)
		   i = 1
		   if (Memc[geometry] == ';')
		        sdelim = ';'
		    else if (ctor (Memc[geometry], i, otheta) <= 0)
			otheta = 0.0
		}
		if (streq (Memc[apertures], "INDEF"))
		    oshape = XP_OINDEF
		if (! IS_INDEFR(oratio))
		    oratio = max (0.0, min (oratio, 1.0))
		if (! IS_INDEFR(otheta))
		    otheta = max (0.0, min (otheta, 360.0))
		oxshift = 0.0
		oyshift = 0.0

	    # Decode the polygonal apertures.
	    case XP_OPOLYGON:
	        call gargwrd (Memc[apertures], SZ_FNAME)
		if (Memc[apertures] == ';' || nscan() < 4) {
		    if (Memc[apertures] == ';')
			sdelim = ';'
		    if (nopolygons > 0) {
			opolygon = nopolygons
		        call strcpy ("0.0", Memc[apertures], SZ_FNAME)
		    } else {
			opolygon = 0
		        call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		    }
		} else if (Memc[apertures] == '{') {
		    opolygon = nopolygons + 1
		    call strcpy ("0.0", Memc[apertures], SZ_FNAME)
		} else {
		    call gargc (pdelim)
		    if (pdelim == ';')
			sdelim = ';'
		    if (pdelim == '{' || npolygons > 0) {
			opolygon = nopolygons
			if (pdelim == '{')
			    opolygon = opolygon + 1
		        i = 1
		        if (ctor (Memc[apertures], i, rsin) <= 0)
		            call strcpy ("0.0", Memc[apertures], SZ_FNAME)
		    } else {
			opolygon = 0
		        call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		    }
		}

		# Decode the object polygon vertices.
		if (opolygon > nopolygons) {
		    novertices = 0
		    while (fscan(ol) != EOF) {
		    	call gargr (xv)
		    	call gargr (yv)
		    	if (nscan() < 2)
			    break
		    	Memr[oxver+novertices] = xv
		    	Memr[oyver+novertices] = yv
		    	novertices = novertices + 1
		    }
		    call reset_scan()
		    call gargc (pdelim)
		    if (novertices < 3 || pdelim != '}') {
			opolygon = 0
		        call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		    } else {
		        Memr[oxver+novertices] = Memr[oxver]
		        Memr[oyver+novertices] = Memr[oyver]
		    }
		} else if (opolygon > 0) {
	            call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
		        call pargi (nopolygons)
		    psymbol = stfind (plyptr, Memc[name])
		    novertices = XP_ONVERTICES(psymbol)
		    call amovr (XP_XVERTICES(psymbol), Memr[oxver),
			XP_ONVERTICES(psymbol) + 1)
		    call amovr (XP_YVERTICES(psymbol), Memr[oyver),
			XP_ONVERTICES(psymbol) + 1)
		} else {
		    oshape = XP_OINDEF
		    novertices = 0
		}

		# Compute the shift for the object polygon.
		if (opolygon > 0) {
		    if (IS_INDEFR(x)) {
		    	x = asumr (Memr[oxver], novertices) / novertices
		    	oxshift = 0.0
		    } else
		    	oxshift = x - asumr (Memr[oxver], novertices) /
		            novertices
		    if (IS_INDEFR(y)) {
		    	y = asumr (Memr[oyver], novertices) / novertices
		    	oyshift = 0.0
		    } else
		    	oyshift = y - asumr (Memr[oyver], novertices) /
		            novertices
		} else {
		    oxshift = 0.0
		    oyshift = 0.0
		}

		oratio = 1.0
		otheta = 0.0

	    default:
		oshape = XP_OINDEF
		call strcpy ("INDEF", Memc[apertures], SZ_FNAME)
		oratio = 1.0
		otheta = 0.0
		oxshift = 0.0
		oyshift = 0.0
	    }

	    # Check for the object geometry delimiter.
	    if (sdelim != ';') {
		#repeat {
	            call gargc (sdelim)
		#} until (sdelim == ';' || sdelim == '\n') 
	    }

	    # Get the sky geometry.
	    if (sdelim != ';') {
		xs = INDEF
		ys = INDEF
		sshape = XP_OINDEF
	    } else {
		call gargwrd (Memc[geometry], SZ_FNAME)
		i = 1
		if (ctor (Memc[geometry], i, xs) > 0) {
		    call gargwrd (Memc[geometry], SZ_FNAME)
		    i = 1
		    if (ctor (Memc[geometry], i, ys) > 0) {
	                call gargwrd (Memc[geometry], SZ_FNAME)
	                sshape = strdic (Memc[geometry], Memc[geometry],
			    SZ_FNAME, OSGEOMETRIES)
		    } else {
			xs = INDEFR
			ys = INDEFR
	                sshape = strdic (Memc[geometry], Memc[geometry],
			    SZ_FNAME, OSGEOMETRIES)
		    }
		} else {
		    xs = INDEFR
		    ys = INDEFR
	            sshape = strdic (Memc[geometry], Memc[geometry], SZ_FNAME,
	                OSGEOMETRIES)
		}
		if (sshape <= 0)
		    sshape = XP_OINDEF
	    }
	    rsin = INDEFR
	    rsout = INDEFR
	    pdelim = '.'
	    spolygon = 0

	    # Decode the sky geometry.
	    switch (sshape) {

	    # Decode a circular sky region.
	    case XP_OCIRCLE:
		noscan = nscan()
		call gargr (rsin)
		call gargr (rsout)
		if ((nscan() - noscan) < 2) {
		    sshape = XP_OINDEF
		    rsin = INDEFR
		    rsout = INDEFR
		}
		sratio = 1.0
		stheta = 0.0
		sxshift = 0.0
		syshift = 0.0

	    # Decode an elliptical or rectangular sky region.
	    case XP_OELLIPSE, XP_ORECTANGLE:
		noscan = nscan()
		call gargr (rsin)
		call gargr (rsout)
		call gargr (sratio)
		call gargr (stheta)
		if ((nscan() - noscan) < 2) {
		    rsin = INDEFR
		    rsout = INDEFR
		    sratio = 1.0
		    stheta = 0.0
		} else if ((nscan() - noscan) < 3) {
		    #sshape = XP_OINDEF
		    sratio = 1.0
		    stheta = 0.0
		} else if ((nscan() - noscan) < 4) {
		    stheta = 0.0
		}
		if (! IS_INDEFR(sratio))
		    sratio = max (0.0, min (sratio, 1.0))
		if (! IS_INDEFR(stheta))
		    stheta = max (0.0, min (stheta, 360.0))
		sxshift = 0.0
		syshift = 0.0

	    # Decode a polygonal sky region.
	    case XP_OPOLYGON:
		noscan = nscan()
		call gargr (rsin)
		call gargr (rsout)
		call gargc (pdelim)
		if ((nscan() - noscan) >= 3 && pdelim == '{') {
		    nsvertices = 0
		    while (fscan(ol) != EOF) {
		        call gargr (xv)
		        call gargr (yv)
		        if (nscan() < 2)
			    break
		        Memr[sxver+nsvertices] = xv
		        Memr[syver+nsvertices] = yv
		        nsvertices = nsvertices + 1
		    }
		    if (nsvertices < 3)
			spolygon = 0
		    else if (opolygon > nopolygons)
			spolygon = opolygon + 1
		    else 
			spolygon = nspolygons + 1
		} else if ((nscan() - noscan) >= 2 && nspolygons > 0) {
		    spolygon = nspolygons
		    call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
                        call pargi (nspolygons)
                    psymbol = stfind (plyptr, Memc[name])
                    nsvertices = XP_SNVERTICES(psymbol)
                    call amovr (XP_XVERTICES(psymbol), Memr[sxver),
                        XP_SNVERTICES(psymbol) + 1)
                    call amovr (XP_YVERTICES(psymbol), Memr[syver),
                        XP_SNVERTICES(psymbol) + 1)
		} else {
		    sshape = XP_OINDEF
		    spolygon = 0
		    nsvertices = 0
		    rsin = INDEFR
		    rsout = INDEFR
		}
		if (nsvertices >= 3) {
		    Memr[sxver+nsvertices] = Memr[sxver]
		    Memr[syver+nsvertices] = Memr[syver]
		    if (IS_INDEFR(xs))
		        sxshift = x - asumr (Memr[sxver], nsvertices) /
			    nsvertices
		    else
		        sxshift = xs - asumr (Memr[sxver], nsvertices) /
			    nsvertices
		    if (IS_INDEFR(ys))
		        syshift = y - asumr (Memr[syver], nsvertices) /
			    nsvertices
		    else
		        syshift = ys - asumr (Memr[syver], nsvertices) /
		            nsvertices
		} else {
		    rsin = INDEFR
		    rsout = INDEFR
		    sxshift = 0.0
		    syshift = 0.0
		}

	    case XP_OOBJECT:
		noscan = nscan()
		call gargr (rsin)
		call gargr (rsout)
		if ((nscan() - noscan) < 2) {
		    sshape = oshape
		    rsin = INDEFR
		    rsout = INDEFR
		    sratio = 1.0
		    stheta = 0.0
		    sxshift = 0.0
		    syshift = 0.0
		} else {
		    sshape = oshape
		    if (sshape == XP_OPOLYGON) {
			spolygon = opolygon
			nsvertices = novertices
			call amovr (Memr[oxver], Memr[sxver], novertices + 1)
			call amovr (Memr[oyver], Memr[syver], novertices + 1)
			if (IS_INDEFR(xs))
		            sxshift = x - asumr (Memr[sxver], nsvertices) /
			        nsvertices
			else
		            sxshift = xs - asumr (Memr[sxver], nsvertices) /
			        nsvertices
			if (IS_INDEFR(ys))
		            syshift = y - asumr (Memr[syver], nsvertices) /
			        nsvertices
			else
		            syshift = ys - asumr (Memr[syver], nsvertices) /
			        nsvertices
		        sratio = 1.0
		        stheta = 0.0
		    } else {
		        sratio = oratio
		        stheta = otheta
		        sxshift = 0.0
		        syshift = 0.0
		    }
		}

	    default:
		rsin = INDEFR
		rsout = INDEFR
		sratio = 1.0
		stheta = 0.0
		sxshift = 0.0
		syshift = 0.0
	    }

	    # Check the object description.
	    if (IS_INDEFR(x) || IS_INDEFR(y))
		next
	    #if (streq ("INDEF", Memc[apertures]))
		#next

	    # Store the object geometry in the object symbol table.
	    nobjects = nobjects + 1
	    call sprintf (Memc[name], SZ_FNAME, "objlist%d")
		call pargi (nobjects)
	    if (mode == RLIST_TEMP) {
		if (stfind (stptr, Memc[name]) == NULL)
	            symbol = stenter (stptr, Memc[name], LEN_OBJLIST_STRUCT)
	    } else
	        symbol = stenter (stptr, Memc[name], LEN_OBJLIST_STRUCT)

	    XP_ODELETED(symbol) = NO
	    XP_OXINIT(symbol) = x
	    XP_OYINIT(symbol) = y
	    XP_OGEOMETRY(symbol) = oshape
	    call strcpy (Memc[apertures], XP_OAPERTURES(symbol),
	        MAX_SZAPERTURES)
	    XP_OAXRATIO(symbol) = oratio
	    XP_OPOSANG(symbol) = otheta
	    if (oshape == XP_OPOLYGON) {
		if (opolygon > nopolygons) {
	            if (mode == RLIST_TEMP) {
			if (nopolygons == 0) {
		            nopolygons = npolygons + 1
		            npolygons = npolygons + 1
			} 
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
		            call pargi (nopolygons)
		        psymbol = stfind (plyptr, Memc[name])
			if (psymbol == NULL)
	                    psymbol = stenter (plyptr, Memc[name],
		                LEN_POLYGONLIST_STRUCT)
		        XP_ONPOLYGON(symbol) = nopolygons
		    } else {
		        nopolygons = npolygons + 1
		        npolygons = npolygons + 1
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
		            call pargi (npolygons)
	                psymbol = stenter (plyptr, Memc[name],
		            LEN_POLYGONLIST_STRUCT)
		        XP_ONPOLYGON(symbol) = nopolygons
		    }
		    XP_ONVERTICES(psymbol) = novertices
		    do i = 1, novertices + 1 {
		        XP_XVERTICES(psymbol+i-1) = Memr[oxver+i-1]
		        XP_YVERTICES(psymbol+i-1) = Memr[oyver+i-1]
		    }
		    XP_SNVERTICES(psymbol) = 0
		    XP_POLYWRITTEN(psymbol) = NO
		} else
		    XP_ONPOLYGON(symbol) = opolygon
	    } else
		XP_ONPOLYGON(symbol) = 0
	    XP_OXSHIFT(symbol) = oxshift
	    XP_OYSHIFT(symbol) = oyshift

	    # Store the sky geometry in the object symbol table.
	    XP_OSXINIT(symbol) = xs
	    XP_OSYINIT(symbol) = ys
	    XP_OSRIN(symbol) = rsin
	    XP_OSROUT(symbol) = rsout
	    XP_OSGEOMETRY(symbol) = sshape
	    XP_OSAXRATIO(symbol) = sratio
	    XP_OSPOSANG(symbol) = stheta
	    if (sshape == XP_OPOLYGON) {
		if (spolygon > nspolygons) {
	            if (mode == RLIST_TEMP) {
			if (nspolygons == 0) {
		            nspolygons = npolygons + 1
		            npolygons = npolygons + 1
			}
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
		            call pargi (nspolygons)
		        psymbol = stfind (plyptr, Memc[name])
			if (psymbol == NULL)
	                    psymbol = stenter (plyptr, Memc[name],
		                LEN_POLYGONLIST_STRUCT)
		        XP_OSNPOLYGON(symbol) = spolygon
		    } else {
		        nspolygons = npolygons + 1
		        npolygons = npolygons + 1
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
		            call pargi (npolygons)
	                psymbol = stenter (plyptr, Memc[name],
		            LEN_POLYGONLIST_STRUCT)
		        XP_OSNPOLYGON(symbol) = nspolygons
		    }
		    XP_ONVERTICES(psymbol) = 0
		    XP_SNVERTICES(psymbol) = nsvertices
		    do i = 1, nsvertices + 1 {
		        XP_XVERTICES(psymbol+i-1) = Memr[sxver+i-1]
		        XP_YVERTICES(psymbol+i-1) = Memr[syver+i-1]
		    }
		    XP_POLYWRITTEN(psymbol) = NO
		} else
		    XP_OSNPOLYGON(symbol) = spolygon
	    } else
		XP_OSNPOLYGON(symbol) = 0
	    XP_OSXSHIFT(symbol) = sxshift
	    XP_OSYSHIFT(symbol) = syshift

	    if (mode == RLIST_APPENDONE || mode == RLIST_TEMP)
		break
	}

	call sfree (sp)

	return (nobjects)
end


# XP_SOBJECTS -- Save the object list in a single disk file.

int procedure xp_sobjects (xp, extstr, newobjects, maxch)

pointer	xp			#I pointer to the main xapphot descriptor
char	extstr[ARB]		#I the extension string
char	newobjects[ARB]		#O the new output objects file name
int	maxch			#I the size of the output file name

int	len_dir, fd, nwritten
pointer	sp, image, results, dirname
bool	streq()
int	fnldir(), open(), access(), xp_wobjects()
errchk	open()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (image, SZ_FNAME, TY_CHAR)
	call salloc (results, SZ_FNAME, TY_CHAR)
	call salloc (dirname, SZ_FNAME, TY_CHAR)

	# Determine the default output file name. Put the results in
	# the same directory as the other results files.
	call xp_stats (xp, IMAGE, Memc[image], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[results], SZ_FNAME)
	len_dir = fnldir (Memc[results], Memc[dirname], SZ_FNAME)
	if (Memc[image] == EOS)
	    call xp_outname ("image", Memc[dirname], extstr, newobjects,
		SZ_FNAME)
	else
	    call xp_outname (Memc[image], Memc[dirname], extstr, newobjects,
	        SZ_FNAME)

	# Check for conflicts.
	if (streq (newobjects, Memc[results])) {
	    if (access (Memc[results], 0, TEXT_FILE) == YES) {
		call sfree (sp)
		return (0)
	    }
	    #iferr {
	        #fd = open (Memc[results], NEW_FILE, TEXT_FILE)
	    #} then {
		#call sfree (sp)
		#return (0)
	    #} else {
	        #call close (fd)
	        #if (Memc[image] == EOS)
	            #call xp_outname ("image", Memc[dirname], extstr,
		        #newobjects, SZ_FNAME)
	        #else
	            #call xp_outname (Memc[image], Memc[dirname], extstr,
	                #newobjects, SZ_FNAME)
	    #}
	}

	# Open the file.
	iferr {
	    fd = open (newobjects, NEW_FILE, TEXT_FILE)
	} then {
	    call sfree (sp)
	    return (0)
	}

	# Save the list.
	nwritten = xp_wobjects (fd, xp, NO, NO)

	# Close the file.
	call close (fd)

	call sfree (sp)

	return (nwritten)
end


# XP_WOBJECTS -- Write the objects list to a file which has already been opened.

int procedure xp_wobjects (fd, xp, listfmt, number)

int	fd		#I the output file descriptor
pointer	xp		#I pointer to the main xapphot data structure
int	listfmt		#I output the results in list format
int	number		#I number the output objects ?

int	i, nobjects, nwritten
pointer	sp, sym, stptr, plyptr, symbol
int	stnsymbols(), xp_w1object()
pointer	xp_statp(), sthead(), stnext()

begin
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (0)

	nobjects = stnsymbols (stptr, 0)
	if (nobjects <= 0)
	    return (0)

	# Get the symbols.
	call smark (sp)
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	# Zero the polygon written flags.
	plyptr = xp_statp (xp, POLYGONLIST)
	if (plyptr != NULL) {
	    symbol = sthead (plyptr)
	    while (symbol != NULL) {
		XP_POLYWRITTEN(symbol) = NO
		symbol = stnext (plyptr, symbol)
	    }
	}

	# Write the file.
	nwritten = 0
	do i = nobjects, 1, -1 {
	    symbol = Memi[sym+i-1]
	    nwritten = nwritten + xp_w1object (fd, xp, symbol, listfmt,
		number, nobjects - i + 1)
	}

	call sfree (sp)

	return (nwritten)
end


# XP_W1OBJECT -- Write a single object to the output file.

int procedure xp_w1object (fd, xp, symbol, listfmt, number, object)

int	fd			#I the output file descriptor
pointer	xp			#I pointer to the main xapphot structure
int	symbol			#I the object symbol
int	listfmt			#I list format on output
int	number			#I number the output objects
int	object			#I the object number

int	j, ishape, npolygon, sshape
pointer	sp, objects, psymbol
real	x, y
pointer	stfind(), xp_statp()

begin
	# Check for rejected objects if numbering is turned off.
	x = XP_OXINIT(symbol)
	y = XP_OYINIT(symbol)
	if (number == NO && XP_ODELETED(symbol) == YES)
	    return (0)

	call smark (sp)
	call salloc (objects, SZ_FNAME, TY_CHAR) 

	# Determine the list format.
	if (listfmt == YES)
	    call fprintf (fd, "{ ")
	if (number == YES) {
	    if (XP_ODELETED(symbol) == NO) {
		call fprintf (fd, "[%03d] ")
		    call pargi (object)
	    } else
		call fprintf (fd, "[DEL] ")
	}

	# Write the record.
	ishape = XP_OGEOMETRY(symbol)
	switch (ishape) {
	case XP_OCIRCLE:
	    call fprintf (fd, "%0.3f %0.3f circle %s")
	        call pargr (x)
	        call pargr (y)
	        call pargstr (XP_OAPERTURES(symbol))

	case XP_OELLIPSE:
	    call fprintf (fd, "%0.3f %0.3f ellipse %s %0.4f %0.3f")
	        call pargr (x)
	        call pargr (y)
	        call pargstr (XP_OAPERTURES(symbol))
	        call pargr (XP_OAXRATIO(symbol))
	        call pargr (XP_OPOSANG(symbol))

	case XP_ORECTANGLE:
	    call fprintf (fd, "%0.3f %0.3f rectangle %s %0.4f %0.3f")
	        call pargr (x)
	        call pargr (y)
	        call pargstr (XP_OAPERTURES(symbol))
	        call pargr (XP_OAXRATIO(symbol))
	        call pargr (XP_OPOSANG(symbol))

	case XP_OPOLYGON:
	    npolygon = XP_ONPOLYGON(symbol)
	    call sprintf (Memc[objects], SZ_FNAME, "polygonlist%d")
	        call pargi (npolygon)
	    psymbol = stfind (xp_statp (xp, POLYGONLIST), Memc[objects])
	    if (psymbol == NULL) {
		call sfree (sp)
	        return (0)
	    }
	    call fprintf (fd, "%0.3f %0.3f polygon %s")
	        call pargr (x)
	        call pargr (y)
	        call pargstr (XP_OAPERTURES(symbol))
	    if (XP_POLYWRITTEN(psymbol) == NO) {
		if (listfmt == YES) {
		    call fprintf (fd, " vertices%d")
			call pargi (npolygon)
		} else {
		    call fprintf (fd, " {\n")
		    do j = 1, XP_ONVERTICES(psymbol) {
	                call fprintf (fd, "%0.3f %0.3f\n")
		            call pargr (XP_XVERTICES(psymbol+j-1))
		            call pargr (XP_YVERTICES(psymbol+j-1))
		    }
		    call fprintf (fd, "}")
		}
		XP_POLYWRITTEN(psymbol) = YES
	    }

	default:
	    if (XP_OAXRATIO(symbol) == 1.0 && XP_OPOSANG(symbol) == 0.0) {
	        call fprintf (fd, "%0.3f %0.3f INDEF")
	            call pargr (x)
	            call pargr (y)
	    } else {
	        call fprintf (fd, "%0.3f %0.3f INDEF %s %0.4f %0.3f")
	            call pargr (x)
	            call pargr (y)
	            call pargstr (XP_OAPERTURES(symbol))
	            call pargr (XP_OAXRATIO(symbol))
	            call pargr (XP_OPOSANG(symbol))
	    }
	}


	# Print the sky region definition.
	if (! IS_INDEFR(XP_OSXINIT(symbol)) &&
	    ! IS_INDEFR(XP_OSYINIT(symbol))) {

	    call fprintf (fd, " ; %0.3f %0.3f ")
	        call pargr (XP_OSXINIT(symbol))
	        call pargr (XP_OSYINIT(symbol))

	    if (IS_INDEFR(XP_OSRIN(symbol)) || IS_INDEFR(XP_OSROUT(symbol)) ||
	        XP_OSGEOMETRY(symbol) == XP_OINDEF) {
	        if (listfmt == YES)
	            call fprintf (fd, "INDEF }\n")
	        else
	            call fprintf (fd, "INDEF\n")
	        call sfree (sp)
	        return (1)
	    }

	} else if (IS_INDEFR(XP_OSRIN(symbol)) ||
	    IS_INDEFR(XP_OSROUT(symbol)) || XP_OSGEOMETRY(symbol) ==
	    XP_OINDEF) {

	        if (listfmt == YES)
	            call fprintf (fd, " }\n")
	        else
	            call fprintf (fd, "\n")
	        call sfree (sp)
	        return (1)
	} else
	    call fprintf (fd, " ; ")

	sshape = XP_OSGEOMETRY(symbol)
	switch (sshape) {

	case XP_OCIRCLE:
	    call fprintf (fd, " circle %0.2f %0.2f")
	    call pargr (XP_OSRIN(symbol))
	    call pargr (XP_OSROUT(symbol))

	case XP_OELLIPSE:
	    call fprintf (fd, " ellipse %0.2f %0.2f %0.4f %0.3f")
	        call pargr (XP_OSRIN(symbol))
	        call pargr (XP_OSROUT(symbol))
	        call pargr (XP_OSAXRATIO(symbol))
	        call pargr (XP_OSPOSANG(symbol))

	case XP_ORECTANGLE:
	    call fprintf (fd, " rectangle %0.2f %0.2f %0.4f %0.3f")
	        call pargr (XP_OSRIN(symbol))
	        call pargr (XP_OSROUT(symbol))
	        call pargr (XP_OSAXRATIO(symbol))
	        call pargr (XP_OSPOSANG(symbol))

	case XP_OPOLYGON:
	    npolygon = XP_OSNPOLYGON(symbol)
	    call sprintf (Memc[objects], SZ_FNAME, "polygonlist%d")
		call pargi (npolygon)
	    psymbol = stfind (xp_statp (xp, POLYGONLIST), Memc[objects])
	    if (psymbol != NULL) {
		if (XP_POLYWRITTEN(psymbol) == NO) {
		    call fprintf (fd, " polygon %0.2f %0.2f")
		        call pargr (XP_OSRIN(symbol))
		        call pargr (XP_OSROUT(symbol))
		    if (listfmt == YES) {
			call fprintf (fd, " vertices%d")
			    call pargi (npolygon)
		    } else {
		        call fprintf (fd, "  {\n")
		        do j = 1, XP_SNVERTICES(psymbol) {
	                    call fprintf (fd, "%0.3f %0.3f\n")
		                call pargr (XP_XVERTICES(psymbol+j-1))
		                call pargr (XP_YVERTICES(psymbol+j-1))
		        }
		        call fprintf (fd, "}")
		    }
		    XP_POLYWRITTEN(psymbol) = YES
		} else if (XP_OSNPOLYGON(symbol) == XP_ONPOLYGON(symbol)) {
		    call fprintf (fd, " object %0.2f %0.2f")
		        call pargr (XP_OSRIN(symbol))
		        call pargr (XP_OSROUT(symbol))
		} else {
		    call fprintf (fd, " polygon %0.2f %0.2f")
		        call pargr (XP_OSRIN(symbol))
		        call pargr (XP_OSROUT(symbol))
		}
	    } 

	default:
	    ;
	}

	if (listfmt == YES)
	    call fprintf (fd, " }\n")
	else
	    call fprintf (fd, "\n")


	call sfree (sp)

	return (1)
end


# XP_MKOBJECTS -- Mark the objects on the image display.

procedure xp_mkobjects (gd, xp, raster, wcs)

pointer	gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
int	raster		#I the raster coordinate system to be used
int	wcs		#I the the current wcs

int	i, omarktype, optcolor, omkcolor, otxcolor, markchar, nobjects
pointer	sp, text, format, sym, stptr, plyptr, symbol, opsymbol, spsymbol
real	mksize, x, y, xs, ys
int	xp_stati(), gstati(), itoc(), stnsymbols(), xp_opcolor(), xp_oscolor()
pointer	xp_statp(), sthead(), stnext(), stfind()
real	xp_statr()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, OBJMARK) == NO)
	    return

	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return
	nobjects = stnsymbols (stptr, 0)
	if (nobjects <= 0)
	    return
	plyptr = xp_statp (xp, POLYGONLIST)

	call smark (sp)
	call salloc (text, SZ_FNAME, TY_CHAR)
	call salloc (format, SZ_FNAME, TY_CHAR)

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Save the mark type.
	omarktype = gstati (gd, G_PMLTYPE)
	optcolor = gstati (gd, G_PMCOLOR)
	omkcolor = gstati (gd, G_PLCOLOR)
	otxcolor = gstati (gd, G_TXCOLOR)

	# Set the mark character.
	switch (xp_stati (xp, OCHARMARK)) {
	case XP_OMARK_POINT:
	    markchar = GM_POINT
	case XP_OMARK_BOX:
	    markchar = GM_BOX
	case XP_OMARK_CROSS:
	    markchar = GM_CROSS
	case XP_OMARK_PLUS:
	    markchar = GM_PLUS
	case XP_OMARK_CIRCLE:
	    markchar = GM_CIRCLE
	case XP_OMARK_DIAMOND:
	    markchar = GM_DIAMOND
	default:
	    markchar = GM_PLUS
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)

	# Set the marker size.
	if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
	    mksize = - 2.0 * xp_statr (xp,IHWHMPSF) * xp_statr(xp,ISCALE) 
	else
	    mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr(xp,ISCALE)

	# Get the symbols.
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	# Mark the points.
	do i = nobjects, 1, -1 {

	    # Get the object description from the symbol table.
	    symbol = Memi[sym+i-1]
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)

	    # If the object has been deleted mark it with a cross, number it
	    # if appropriate and move to the next object.
	    if (XP_ODELETED(symbol) == YES) {
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
	        call gmark (gd, x, y, GM_CROSS, mksize, mksize)
	        if (xp_stati (xp, ONUMBER) == YES) {
		    Memc[text] = 'O'
		    if (itoc (nobjects - i + 1, Memc[text+1], SZ_FNAME) <= 0)
		        call strcpy ("", Memc[text], SZ_FNAME)
		    Memc[format] = EOS
		    call gtext (gd, x + 2.0, y + 2.0, Memc[text], Memc[format])
		}
		next
	    }

	    xs = XP_OSXINIT(symbol)
	    ys = XP_OSYINIT(symbol)
	    if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
		call sprintf (Memc[text], SZ_FNAME, "polygonlist%d")
		    call pargi (XP_ONPOLYGON(symbol))
		opsymbol = stfind (plyptr, Memc[text])
	    } else 
		opsymbol = NULL
	    if (XP_OSGEOMETRY(symbol) == XP_OPOLYGON) {
		call sprintf (Memc[text], SZ_FNAME, "polygonlist%d")
		    call pargi (XP_OSNPOLYGON(symbol))
		spsymbol = stfind (plyptr, Memc[text])
	    } else
		spsymbol = NULL

	    # Mark the objects.
	    if (xp_stati (xp, OCHARMARK) == XP_OMARK_SHAPE) {
	        call gseti (gd, G_PMCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
	        call xp_omkshape (gd, symbol, opsymbol, spsymbol, 0.0, 0.0,
		    1.0, YES, NO, mksize)
	        call gseti (gd, G_PMCOLOR, xp_oscolor (xp))
	        call gseti (gd, G_PLCOLOR, xp_oscolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_oscolor (xp))
	        call xp_omkshape (gd, symbol, opsymbol, spsymbol, 0.0, 0.0,
		    1.0, NO, YES, mksize)
	    } else {
	        call gseti (gd, G_PMCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
	        call gmark (gd, x, y, markchar, mksize, mksize)
		if (! IS_INDEFR(xs) && ! IS_INDEFR(ys)) {
	            call gseti (gd, G_PMCOLOR, xp_oscolor (xp))
	            call gseti (gd, G_PLCOLOR, xp_oscolor (xp))
	            call gseti (gd, G_TXCOLOR, xp_oscolor (xp))
	            call gmark (gd, xs, ys, markchar, mksize, mksize)
		}
	    }

	    # Number the marked objects.
	    if (xp_stati (xp, ONUMBER) == YES) {
		Memc[text] = 'O'
		if (itoc (nobjects - i + 1, Memc[text+1], SZ_FNAME) <= 0)
		    call strcpy ("", Memc[text], SZ_FNAME)
		Memc[format] = EOS
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
		call gtext (gd, x + 2.0, y + 2.0, Memc[text], Memc[format])
		if (! IS_INDEFR(xs) && ! IS_INDEFR(ys)) {
		    Memc[text] = 'S'
		    if (itoc (nobjects - i + 1, Memc[text+1], SZ_FNAME) <= 0)
		        call strcpy ("", Memc[text], SZ_FNAME)
		    Memc[format] = EOS
	            call gseti (gd, G_PLCOLOR, xp_oscolor (xp))
	            call gseti (gd, G_TXCOLOR, xp_oscolor (xp))
		    call gtext (gd, xs + 2.0, ys + 2.0, Memc[text],
		        Memc[format])
		}
	    }
	}

	# Restore the mark type.
	call gseti (gd, G_PMLTYPE, omarktype)
	call gseti (gd, G_PMCOLOR, optcolor)
	call gseti (gd, G_PLCOLOR, omkcolor)
	call gseti (gd, G_TXCOLOR, otxcolor)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)

	call sfree (sp)
end


# XP_EOBJECTS -- Erase the marked objects by refreshing the whole screen.

procedure xp_eobjects (gd, raster)

pointer	gd			#I the pointer to the graphics stream
int	raster			#I the the raster number

#int	ctype, width, height, depth
#int	gim_queryraster()

begin
	# This works now, not quite in the manner desired but it
	# does work.
	call gim_refreshpix (gd, raster, CT_NDC, 0.0, 0.0, 1.0, 1.0)

	# This does work quite nicely.
	#call gim_refreshmapping (gd, raster)
end


# XP_NEXTOBJECT -- Given the current object in the coordinate list 
# find the next object in the list.

int procedure xp_nextobject (xp, object)

pointer	xp			#I the pointer to the xapphot data structure
int	object			#I the current object

int	i, nobjects, first
pointer	stptr, sp, name, symbol
real	xlist, ylist
int	stnsymbols()
pointer	xp_statp(), stfind()

begin
	if (object == EOF)
	    return (EOF)
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (BOF)

	nobjects = stnsymbols (stptr, 0)
	if (object == BOF)
	    object = 1
	else
	    object = object + 1
	if (object < 1 || object > nobjects)
	    object = EOF
	if (object == EOF)
	    return (EOF)

	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)

	first = object
	do i = first, nobjects {
	    call sprintf (Memc[name], SZ_FNAME, "objlist%d")
		call pargi (i)
	    symbol = stfind (stptr, Memc[name]) 
	    if (symbol != NULL) {
	        xlist = XP_OXINIT(symbol)
	        ylist = XP_OYINIT(symbol)
	        if (XP_ODELETED(symbol) == NO)
		    break
	    }
	    object = object + 1
	}
	if (object > nobjects)
	    object = EOF

	call sfree (sp)

	return (object)
end


# XP_PREVOBJECT -- Given the current object in the coordinate list 
# find the previous object in the list.

int procedure xp_prevobject (xp, object)

pointer	xp			#I the pointer to the xapphot data structure
int	object			#I the current object

int	i, first
pointer	stptr, sp, name, symbol
real	xlist, ylist
int	stnsymbols()
pointer	xp_statp(), stfind()

begin
	if (object == BOF)
	    return (BOF)
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (BOF)

	if (object == EOF)
	    object = stnsymbols (stptr, 0)
	else
	    object = object - 1
	if (object < 1)
	    object = BOF
	if (object == BOF)
	    return (BOF)

	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)

	first = object
	do i = first, 1, -1 {
	    call sprintf (Memc[name], SZ_FNAME, "objlist%d")
		call pargi (i)
	    symbol = stfind (stptr, Memc[name])
	    if (symbol != NULL) {
	        xlist = XP_OXINIT(symbol)
	        ylist = XP_OYINIT(symbol)
	        if (XP_ODELETED(symbol) == NO)
		    break
	    }
	    object = object - 1
	}

	if (object < 1)
	    object = BOF

	call sfree (sp)

	return (object)
end


# XP_FOBJECT -- Find the object in the list nearst the cursor position
# excluding deleted objects.

int procedure xp_fobject (xp, xcursor, ycursor, xlist, ylist)

pointer	xp			#I the pointer to the xapphot data structure
real	xcursor			#I the x position of the cursor
real	ycursor			#I the y position of the cursor
real	xlist			#I the x position of the object in the list
real	ylist			#I the y position of the object in the list

int	i, nobjects, object
pointer	stptr, sp, sym, symbol
real	maxdist, x, y, dist
int	stnsymbols()
pointer	xp_statp(), sthead(), stnext()
real	xp_statr()

begin
	# Initialize.
	object = 0
	xlist = INDEFR
	ylist = INDEFR
	maxdist = xp_statr (xp, OTOLERANCE) ** 2 / xp_statr(xp, ISCALE) ** 2

	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (object)

	nobjects = stnsymbols (stptr, 0)
	call smark (sp)
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	do i = nobjects, 1, -1 {
	    symbol = Memi[sym+i-1]
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    if (XP_ODELETED(symbol) == YES)
		next
	    dist = (x - xcursor) ** 2 + (y - ycursor) ** 2
	    if (dist > maxdist)
		next
	    object = nobjects - i + 1
	    xlist = x
	    ylist = y
	    maxdist = dist
	}

	call sfree (sp)

	return (object)
end


# XP_NOBJECT -- Find the object in the list nearest the cursor position
# whether it has been deleted or not.

int procedure xp_nobject (xp, xcursor, ycursor, xlist, ylist)

pointer	xp			#I the pointer to the xapphot data structure
real	xcursor			#I the x position of the cursor
real	ycursor			#I the y position of the cursor
real	xlist			#I the x position of the object in the list
real	ylist			#I the y position of the object in the list

int	i, nobjects, object
pointer	stptr, sp, sym, symbol
real	maxdist, x, y, dist
int	stnsymbols()
pointer	xp_statp(), sthead(), stnext()
real	xp_statr()

begin
	# Initialize.
	object = 0
	xlist = INDEFR
	ylist = INDEFR
	maxdist = xp_statr (xp, OTOLERANCE) ** 2 / xp_statr(xp,ISCALE) ** 2

	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (object)

	nobjects = stnsymbols (stptr, 0)
	call smark (sp)
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	do i = nobjects, 1, -1 {
	    symbol = Memi[sym+i-1]
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    dist = (x - xcursor) ** 2 + (y - ycursor) ** 2
	    if (dist > maxdist)
		next
	    object = nobjects - i + 1
	    xlist = x
	    ylist = y
	    maxdist = dist
	}

	call sfree (sp)

	return (object)
end


# XP_NFOBJECT -- Find the specified object in the list whether deleted or not.

pointer procedure xp_nfobject (gd, xp, object)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	object			#I the object to be deleted

int	nobjects
pointer	sp, str, stptr, symbol
int	stnsymbols()
pointer	xp_statp(), stfind

begin
	# Check symbol table.
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (NULL)
	nobjects = stnsymbols (stptr, 0)
	if (object <= 0 || object > nobjects)
	    return (NULL)

	# Find symbol.
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call sprintf (Memc[str], SZ_FNAME, "objlist%d")
	    call pargi (object)
	symbol = stfind (stptr, Memc[str])
	call sfree (sp)

	return (symbol)
end


# XP_NDOBJECT -- Find the specified object in the list and delete it.

pointer procedure xp_ndobject (gd, xp, object, raster, wcs)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	object			#I the object to be deleted
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster

int	nobjects
pointer	sp, str, stptr, symbol
int	stnsymbols()
pointer	xp_statp(), stfind

begin
	# Check symbol table.
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (NULL)
	nobjects = stnsymbols (stptr, 0)
	if (object <= 0 || object > nobjects)
	    return (NULL)

	# Find symbol.
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call sprintf (Memc[str], SZ_FNAME, "objlist%d")
	    call pargi (object)
	symbol = stfind (stptr, Memc[str])
	call sfree (sp)

	if (XP_ODELETED(symbol) == YES)
	    return (NULL)
	call xp_dsymbol (gd, xp, raster, wcs, symbol)

	return (symbol)
end


# XP_NUDOBJECT -- Find the specified object in the list and delete it.

pointer procedure xp_nudobject (gd, xp, object, raster, wcs)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	object			#I the object to be deleted
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster

int	nobjects
pointer	sp, str, stptr, symbol
int	stnsymbols()
pointer	xp_statp(), stfind

begin
	# Check symbol table.
	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (NULL)
	nobjects = stnsymbols (stptr, 0)
	if (object <= 0 || object > nobjects)
	    return (NULL)

	# Find symbol.
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call sprintf (Memc[str], SZ_FNAME, "objlist%d")
	    call pargi (object)
	symbol = stfind (stptr, Memc[str])
	call sfree (sp)

	if (XP_ODELETED(symbol) == NO)
	    return (NULL)
	call xp_udsymbol (gd, xp, raster, wcs, symbol)

	return (symbol)
end


# XP_DOBJECT -- Delete the nearest undeleted object from the objects list.

int procedure xp_dobject (gd, xp, raster, wcs, xcursor, ycursor)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster
real	xcursor			#I the x position of the cursor
real	ycursor			#I the y position of the cursor

int	i, nobjects, object
pointer	stptr, sp, sym, symbol
real	maxdist, dist, x, y
int	stnsymbols()
pointer	xp_statp(), sthead(), stnext()
real	xp_statr()

begin
	object = 0

	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (object)
	nobjects = stnsymbols (stptr, 0)
	if (nobjects <= 0)
	    return (object)

	call smark (sp)
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	# Find the object to be deleted in the list.
	maxdist = xp_statr (xp, OTOLERANCE) ** 2 / xp_statr(xp,ISCALE) ** 2
	do i = nobjects, 1, -1 {
	    symbol = Memi[sym+i-1]
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    if (XP_ODELETED(symbol) == YES)
		next
	    dist = (x - xcursor) ** 2 + (y - ycursor) ** 2
	    if (dist > maxdist)
		next
	    object = i
	    maxdist = dist
	}

	# Object not found.
	if (object <= 0) {
	    call sfree (sp)
	    return (0)
	}

	# Delete the object.
	symbol = Memi[sym+object-1]
	call xp_dsymbol (gd, xp, raster, wcs, symbol)

	call sfree (sp)

	return (nobjects - object + 1)
end


# XP_UDOBJECT -- Undelete an object from the objects list.

int procedure xp_udobject (gd, xp, raster, wcs, xcursor, ycursor)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster
real	xcursor			#I the x position of the cursor
real	ycursor			#I the y position of the cursor

int	i, object, nobjects
pointer	stptr, sp, sym, symbol
real	maxdist, x, y, dist
int	stnsymbols()
pointer	xp_statp(), sthead(), stnext()
real	xp_statr()

begin
	object = 0

	stptr = xp_statp (xp, OBJLIST)
	if (stptr == NULL)
	    return (object)
	nobjects = stnsymbols (stptr, 0)
	if (nobjects <= 0)
	    return (object)

	call smark (sp)
	call salloc (sym, nobjects, TY_INT)
	symbol = sthead (stptr)
	do i = 1, nobjects {
	    Memi[sym+i-1] = symbol
	    symbol = stnext (stptr, symbol)
	}

	# Find the object to be deleted in the list.
	maxdist = xp_statr (xp, OTOLERANCE) ** 2 / xp_statr(xp,ISCALE) ** 2
	do i = nobjects, 1, -1 {
	    symbol = Memi[sym+i-1]
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    if (XP_ODELETED(symbol) == NO)
		next
	    dist = (x - xcursor) ** 2 + (y - ycursor) ** 2
	    if (dist > maxdist)
		next
	    object = i
	    maxdist = dist
	}

	# Object not found.
	if (object <= 0) {
	    call sfree (sp)
	    return (0)
	}

	# Undelete the object.
	symbol = Memi[sym+object-1]
	call xp_udsymbol (gd, xp, raster, wcs, symbol)

	call sfree (sp)

	return (nobjects - object + 1)
end


# XP_DSYMBOL -- Delete an object symbol from the object list.

procedure xp_dsymbol (gd, xp, raster, wcs, symbol)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster
pointer	symbol			#I the symbol to be deleted

int	omarktype, omkcolor
real	x, y, mksize
int	xp_stati(), gstati()
real	xp_statr()

begin
	# Return if the symbol is undefined.
	if (symbol == NULL)
	    return

	if (xp_stati (xp, OBJMARK) == YES) {
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    call gseti (gd, G_WCS, wcs)
	    call gim_setraster (gd, raster)
	    omarktype = gstati (gd, G_PMLTYPE)
	    omkcolor = gstati (gd, G_PLCOLOR)
	    switch (xp_stati (xp, OPCOLORMARK)) {
	    case XP_OMARK_RED:
	        call gseti (gd, G_PLCOLOR, RED)
	    case XP_OMARK_BLUE:
	        call gseti (gd, G_PLCOLOR, BLUE)
	    case XP_OMARK_GREEN:
	        call gseti (gd, G_PLCOLOR, GREEN)
	    case XP_OMARK_YELLOW:
	        call gseti (gd, G_PLCOLOR, YELLOW)
	    default:
	        call gseti (gd, G_PLCOLOR, RED)
	    }
	    call gseti (gd, G_PMLTYPE, GL_SOLID)
	    if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
	        mksize = - 2.0 * xp_statr(xp,IHWHMPSF) * xp_statr (xp,ISCALE) 
	    else
	        mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr (xp,
		    ISCALE)
	    call gmark (gd, x, y, GM_CROSS, mksize, mksize)
	    call gseti (gd, G_PMLTYPE, omarktype)
	    call gseti (gd, G_PLCOLOR, omkcolor)
	    call gim_setraster (gd, 0)
	}

	# Delete the object.
	XP_ODELETED(symbol) = YES
end


# XP_UDSYMBOL -- Undelete an object symbol from the object list.

procedure xp_udsymbol (gd, xp, raster, wcs, symbol)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster
pointer	symbol			#I the symbol to be deleted

int	omarktype, omkcolor
real	x, y, mksize
int	xp_stati(), gstati()
real	xp_statr()

begin
	# Return if the symbol is undefined.
	if (symbol == NULL)
	    return

	if (xp_stati (xp, OBJMARK) == YES) {
	    x = XP_OXINIT(symbol)
	    y = XP_OYINIT(symbol)
	    call gseti (gd, G_WCS, wcs)
	    call gim_setraster (gd, raster)
	    omarktype = gstati (gd, G_PMLTYPE)
	    omkcolor = gstati (gd, G_PLCOLOR)
	    switch (xp_stati (xp, OPCOLORMARK)) {
	    case XP_OMARK_RED:
	        call gseti (gd, G_PLCOLOR, RED)
	    case XP_OMARK_BLUE:
	        call gseti (gd, G_PLCOLOR, BLUE)
	    case XP_OMARK_GREEN:
	        call gseti (gd, G_PLCOLOR, GREEN)
	    case XP_OMARK_YELLOW:
	        call gseti (gd, G_PLCOLOR, YELLOW)
	    default:
	        call gseti (gd, G_PLCOLOR, RED)
	    }
	    call gseti (gd, G_PMLTYPE, GL_CLEAR)
	    if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
	        mksize = - 2.0 * xp_statr(xp,IHWHMPSF) * xp_statr(xp,ISCALE) 
	    else
	        mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr(xp,
		    ISCALE)
	    call gmark (gd, x, y, GM_CROSS, mksize, mksize)
	    call gseti (gd, G_PMLTYPE, omarktype)
	    call gseti (gd, G_PLCOLOR, omkcolor)
	    call gim_setraster (gd, 0)
	}

	# Undelete the object.
	XP_ODELETED(symbol) = NO
end


define	XP_ATYPE_OBJ		1
define	XP_ATYPE_SKY		2
define	XP_ATYPE_OBJASKY	3
define	XP_ATYPE_OBJOSKY	4

# XP_AOBJECTS -- Add objects to the coordinate list using the image display
# cursor and graphics.

procedure xp_aobjects (gd, xp, raster, wcs)

pointer	gd			#I the pointer to the graphics stream
pointer	xp			#I the pointer to the xapphot data structure
int	raster			#I the raster number
int	wcs			#I the wcs number of the raster

int	i, omarktype, otxcolor, omkcolor, olinetype, markchar
int	nobjects, npolygons
int	gwcs, gkey, ishape, npolygon, nvertices, ip, atype, ntimes
int	nopolygons, nspolygons
pointer	stptr, plyptr, sp, cmd, name, format, osymbol, symbol, psymbol
pointer xver, yver
real	mksize, xc, yc, x1, y1, x2, y2, xs, ys
real	radius, ratio, theta, xshift, yshift, srin, srout
int	xp_stati(), gstati(), stnsymbols(), clgcur(), itoc(), xp_trpoly()
int	ctor(), xp_opcolor(), xp_oscolor()
pointer	xp_statp(), sthead(), stnext(), stenter(), stfind()
real	xp_statr(), asumr()

define	OPSTR "Add object (.=point,geometry=[c,e,r,p],a=again,?=help,q=quit):"
define	SPSTR "Add sky (.=point,geometry=[c,e,r,p],a=again,?=help,q=quit):"
define	prompt_ 99

begin
	# Allocate working space.
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (format, SZ_FNAME, TY_CHAR)
	call salloc (xver, MAX_NOBJ_VERTICES + 1, TY_REAL)
	call salloc (yver, MAX_NOBJ_VERTICES + 1, TY_REAL)

	# Set the object type.
	atype = XP_ATYPE_OBJ
	call printf (
        "Object type (o=obj,s=sky,a=obj+annuluar sky,b=obj+offset sky,q=quit):")
	if (clgcur ("gcommands", xc, yc, gwcs, gkey, Memc[cmd], SZ_LINE) !=
	    EOF) {
	    switch (gkey) {
	    case 'o':
		atype = XP_ATYPE_OBJ
	    case 's':
		atype = XP_ATYPE_SKY
	    case 'a':
		atype = XP_ATYPE_OBJASKY
	    case 'b':
		atype = XP_ATYPE_OBJOSKY
	    case 'q':
		call printf ("\n")
		call sfree (sp)
		return
	    default:
		atype = XP_ATYPE_OBJ
	    }
	}

	# Get the symbol tables.
	stptr = xp_statp (xp, OBJLIST)
	plyptr = xp_statp (xp, POLYGONLIST)
	if (stptr == NULL || plyptr == NULL)
	    call xp_openobjects (xp, stptr, plyptr)

	 # Set the raster and wcs.
	 call gseti (gd, G_WCS, wcs)
	 call gim_setraster (gd, raster)

	 # Store the old graphics parameters.
	 omarktype = gstati (gd, G_PMLTYPE)
	 olinetype = gstati (gd, G_PLTYPE)
	 otxcolor = gstati (gd, G_TXCOLOR)
	 omkcolor = gstati (gd, G_PLCOLOR)

	# Set the graphics marking character.
	switch (xp_stati (xp, OCHARMARK)) {
	case XP_OMARK_POINT:
	    markchar = GM_POINT
	case XP_OMARK_BOX:
	    markchar = GM_BOX
	case XP_OMARK_CROSS:
	    markchar = GM_CROSS
	case XP_OMARK_PLUS:
	    markchar = GM_PLUS
	case XP_OMARK_CIRCLE:
	    markchar = GM_CIRCLE
	case XP_OMARK_DIAMOND:
	    markchar = GM_DIAMOND
	default:
	    markchar = GM_PLUS
	}

	# Set the graphics marker size.
	call gseti (gd, G_PLTYPE, GL_SOLID)
	call gseti (gd, G_PMLTYPE, GL_SOLID)
	if (IS_INDEFR(xp_statr (xp, OSIZEMARK)))
	    mksize = - 2.0 * xp_statr(xp,IHWHMPSF) * xp_statr(xp,ISCALE) 
	else
	    mksize = - 2.0 * xp_statr (xp, OSIZEMARK) * xp_statr(xp,ISCALE)

	# Initialize.
	nobjects = stnsymbols (stptr, 0)
	npolygons = stnsymbols (plyptr, 0)
	nopolygons = 0
	nspolygons = 0
	psymbol = sthead (plyptr)
	do i = 1, npolygons {
	    if (psymbol == NULL)
		break
	    if (XP_ONVERTICES(psymbol) > 0)
		nopolygons = i
	    if (XP_SNVERTICES(psymbol) > 0)
		nspolygons = i
	    psymbol = stnext (plyptr, psymbol)
	}
	ishape = INDEFI

	# Issue the initial prompt.
	switch (atype) {
	case XP_ATYPE_SKY:
	    call printf (SPSTR)
	default:
	    call printf (OPSTR)
	}

	# Enter the cursor loop for adding objects.
	ntimes = 0
	osymbol = NULL
	symbol = NULL
	psymbol = NULL
	while (clgcur ("gcommands", xc, yc, gwcs, gkey, Memc[cmd], SZ_LINE) !=
	    EOF) {

	    switch (gkey) {

	    # Quit add objects menu.
	    case 'q':
		call printf ("\n")
		break

	    # Reprint prompt string.
	    case '?':
		switch (atype) {
		case XP_ATYPE_SKY:
	    	    call printf (SPSTR)
		case XP_ATYPE_OBJASKY:
		    if (mod (ntimes,2) == 0) {
		        call printf (OPSTR)
		    } else {
		        call printf (SPSTR)
		    }
		case XP_ATYPE_OBJOSKY:
		    if (mod (ntimes,2) == 0) {
		        call printf (OPSTR)
		    } else {
		        call printf (SPSTR)
		    }
		default:
		    call printf (OPSTR)
		}

	    # Repeat the previous object/sky region.
	    case 'a':
		if (IS_INDEFI(ishape))
		    goto prompt_
		if (osymbol == NULL)
		    goto prompt_
		switch (atype) {
		case XP_ATYPE_SKY:
		    ;
		default:
		    if (atype == XP_ATYPE_OBJ || mod (ntimes,2) == 0) {
		        ishape = XP_OGEOMETRY(osymbol)
		        ip = 1
		        if (ctor (XP_OAPERTURES(osymbol), ip, radius) <= 0)
		            radius = INDEFR
		        ratio = XP_OAXRATIO(osymbol)
		        theta = XP_OPOSANG(osymbol)
		        if (XP_OGEOMETRY(osymbol) == XP_OPOLYGON) {
			    npolygon = XP_ONPOLYGON(osymbol)
			    call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
				call pargi (npolygon)
			    psymbol = stfind (plyptr, Memc[name]) 
			    nvertices = XP_ONVERTICES(psymbol)
			    xshift = xc - asumr (XP_XVERTICES(psymbol),
			        nvertices) / nvertices
			    yshift = yc - asumr (XP_YVERTICES(psymbol),
			        nvertices) / nvertices
		        } else {
				psymbol = NULL
			        npolygon = 0
			        nvertices = 0
			        xshift = 0.0
			        yshift = 0.0
		       } 
		    }
		}
		switch (atype) {
		case XP_ATYPE_OBJ:
		    ;
		default:
		    if (atype == XP_ATYPE_SKY || mod (ntimes,2) == 1) {
		    	if (atype == XP_ATYPE_OBJOSKY) {
			    xc = XP_OSXINIT(osymbol)
			    yc = XP_OSYINIT(osymbol)
			}
		        if (atype == XP_ATYPE_OBJASKY) {
			    radius = INDEFR
			    srin = XP_OSRIN(osymbol)
			    srout = XP_OSROUT(osymbol)
			} else {
			    radius = XP_OSROUT(osymbol)
			    srin = INDEFR
			    srout = INDEFR
			}
			ishape = XP_OSGEOMETRY(osymbol)
			ratio = XP_OSAXRATIO(osymbol)
			theta = XP_OSPOSANG(osymbol)
		        if (XP_OSGEOMETRY(osymbol) == XP_OPOLYGON) {
			    npolygon = XP_OSNPOLYGON(osymbol)
			    call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
			        call pargi (npolygon)
			    psymbol = stfind (plyptr, Memc[name]) 
			    if (XP_SNVERTICES(psymbol) > 0) {
			        nvertices = XP_SNVERTICES(psymbol)
			        xshift = xc - asumr (XP_XVERTICES(psymbol),
			            nvertices) / nvertices
			        yshift = yc - asumr (XP_YVERTICES(psymbol),
			            nvertices) / nvertices
			    } else {
			        nvertices = XP_ONVERTICES(psymbol)
			        xshift = xc - asumr (XP_XVERTICES(psymbol),
			            nvertices) / nvertices
			        yshift = yc - asumr (XP_YVERTICES(psymbol),
			            nvertices) / nvertices
			    }
			} else {
			    psymbol = NULL
			    npolygon = 0
			    nvertices = 0
			    xshift = 0.0
			    yshift = 0.0
			}
		    }
		}

	    # Add a point.
	    case '.':
		if (atype == XP_ATYPE_OBJASKY && mod (ntimes,2) == 1) {
		    xc = XP_OXINIT(symbol)
		    yc = XP_OYINIT(symbol)
		    call gscur (gd, xc, yc)
		}
		call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		ishape = XP_OINDEF
		radius = INDEFR
		srin = INDEFR
		srout = INDEFR
		ratio = 1.0
		theta = 0.0
		npolygon = 0
		nvertices = 0
		xshift = 0.0
		yshift = 0.0

	    # Add a circle.
	    case 'c':
		if (atype == XP_ATYPE_OBJASKY && mod (ntimes,2) == 1) {
		    xc = XP_OXINIT(symbol)
		    yc = XP_OYINIT(symbol)
		    call gscur (gd, xc, yc)
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf ("Mark inner radius of circle (c=mark,q=quit):")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'c')
		        goto prompt_
		    srin = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (srin <= 0.0)
		        goto prompt_
		    call printf ("Mark outer radius of circle (c=mark,q=quit):")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'c')
		        goto prompt_
		    srout = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (srout <= 0.0)
		        goto prompt_
		    srin = sqrt (srin)
		    srout= sqrt (srout)
		} else {
		    switch (atype) {
		    case XP_ATYPE_OBJ:
	                call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
		    case XP_ATYPE_SKY:
	                call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
		    default:
			if (mod (ntimes, 2) == 0) {
	                    call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
			} else {
	                    call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
			}
		    }
		    #call printf (
		    #"Mark center of circle (c=mark,q=quit:")
		    #if (clgcur ("gcommands", xc, yc, gwcs, gkey, Memc[cmd],
		        #SZ_LINE) == EOF) 
		        #goto prompt_
		    #if (gkey == 'q' || gkey != 'c')
		        #goto prompt_
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf ("Mark radius of circle (c=mark,q=quit):")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'c')
		        goto prompt_
		    radius = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (radius <= 0.0)
		        goto prompt_
		    radius = sqrt (radius)
		    call gamove (gd, xc, yc)
		    call gadraw (gd, x1, y1)
		}
		ishape = XP_OCIRCLE
		ratio = 1.0
		theta = 0.0
		npolygon = 0
		nvertices = 0
		xshift = 0.0
		yshift = 0.0

	    # Add an elliptical object.
	    case 'e':
		if (atype == XP_ATYPE_OBJASKY && mod (ntimes,2) == 1) {
		    xc = XP_OXINIT(symbol)
		    yc = XP_OYINIT(symbol)
		    call gscur (gd, xc, yc)
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf (
		        "Mark inner semi-major axis of annulus (e=mark,q=quit:")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'e')
		        goto prompt_
		    srin = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (srin <= 0.0)
		        goto prompt_
		    srin = sqrt (srin)
		    if (XP_OGEOMETRY(symbol) == XP_OELLIPSE)
			theta = XP_OPOSANG(symbol)
		    else
		        theta = RADTODEG (atan2 (y1 - yc, x1 - xc))
		    if (theta < 0.0)
		        theta = 360.0 + theta
		    call printf (
		        "Mark outer semi-major axis of annulus (e=mark,q=quit:")
		    if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'e')
		        goto prompt_
		    srout = (x2 - xc) ** 2 + (y2 - yc) ** 2
		    if (srout <= 0.0)
			goto prompt_
		    srout = sqrt (srout)
		    if (XP_OGEOMETRY(symbol) == XP_OELLIPSE) {
			ratio = XP_OAXRATIO(symbol)
		    } else {
		        call printf (
		            "Mark semi-minor axis of annulus (e=mark,q=quit:")
		        if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		            SZ_LINE) == EOF) 
		            goto prompt_
		        if (gkey == 'q' || gkey != 'e')
		            goto prompt_
		        ratio = (x2 - xc) ** 2 + (y2 - yc) ** 2
		        if (ratio <= 0.0)
		            goto prompt_
		        ratio = min (sqrt (ratio) / srin, 1.0)
		    }
		    ishape = XP_OELLIPSE
		} else {
		    switch (atype) {
		    case XP_ATYPE_OBJ:
	                call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
		    case XP_ATYPE_SKY:
	                call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
		    default:
			if (mod (ntimes, 2) == 0) {
	                    call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
			} else {
	                    call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
			}
		    }
		    #call printf (
		       #"Mark center of ellipse (e=mark,q=quit):")
		    #if (clgcur ("gcommands", xc, yc, gwcs, gkey, Memc[cmd],
		        #SZ_LINE) == EOF) 
		        #goto prompt_
		    #if (gkey == 'q' || gkey != 'e')
		        #goto prompt_
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf (
		        "Mark semi-major axis of ellipse (e=mark,q=quit:")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'e')
		        goto prompt_
		    call gamove (gd, xc, yc)
		    call gadraw (gd, x1, y1)
		    radius = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (radius <= 0.0)
		        goto prompt_
		    radius = sqrt (radius)
		    theta = RADTODEG (atan2 (y1 - yc, x1 - xc))
		    if (theta < 0.0)
		        theta = 360.0 + theta
		    call printf (
		        "Mark semi-minor axis of ellipse (e=mark,q=quit:")
		    if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'e')
		        goto prompt_
		    ratio = (x2 - xc) ** 2 + (y2 - yc) ** 2
		    if (ratio <= 0.0)
		        goto prompt_
		    ratio = min (sqrt (ratio) / radius, 1.0)
		    ishape = XP_OELLIPSE
		    call gamove (gd, xc, yc)
		    call gadraw (gd, xc - ratio * (y1 - yc),
		        yc + ratio * (x1 - xc))
		}
		npolygon = 0
		nvertices = 0
		xshift = 0.0
		yshift = 0.0

	    case 'r':
		if (atype == XP_ATYPE_OBJASKY && mod (ntimes,2) == 1) {
		    xc = XP_OXINIT(symbol)
		    yc = XP_OYINIT(symbol)
		    call gscur (gd, xc, yc)
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf (
		        "Mark inner semi-major axis of annulus (r=mark,q=quit:")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'r')
		        goto prompt_
		    srin = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (srin <= 0.0)
		        goto prompt_
		    srin = sqrt (srin)
		    if (XP_OGEOMETRY(symbol) == XP_OELLIPSE)
			theta = XP_OPOSANG(symbol)
		    else
		        theta = RADTODEG (atan2 (y1 - yc, x1 - xc))
		    if (theta < 0.0)
		        theta = 360.0 + theta
		    call printf (
		    "Mark outer semi-major axis of annulus (r=mark,q=quit:")
		    if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'r')
		        goto prompt_
		    srout = (x2 - xc) ** 2 + (y2 - yc) ** 2
		    if (srout <= 0.0)
			goto prompt_
		    srout = sqrt (srout)
		    if (XP_OGEOMETRY(symbol) == XP_ORECTANGLE) {
			ratio = XP_OAXRATIO(symbol)
		    } else {
		        call printf (
		        "Mark semi-minor axis of annulus (r=mark,q=quit:")
		        if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		            SZ_LINE) == EOF) 
		            goto prompt_
		        if (gkey == 'q' || gkey != 'r')
		            goto prompt_
		        ratio = (x2 - xc) ** 2 + (y2 - yc) ** 2
		        if (ratio <= 0.0)
		            goto prompt_
		        ratio = min (sqrt (ratio) / srin, 1.0)
		    }
		    ishape = XP_ORECTANGLE
		} else {
		    switch (atype) {
		    case XP_ATYPE_OBJ:
	                call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
		    case XP_ATYPE_SKY:
	                call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
		    default:
			if (mod (ntimes, 2) == 0) {
	                    call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
			} else {
	                    call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
			}
		    }
		    #call printf (
		    #"Mark center of rectangle (r=mark,q=quit):")
		    #if (clgcur ("gcommands", xc, yc, gwcs, gkey, Memc[cmd],
		        #SZ_LINE) == EOF) 
		        #goto prompt_
		    #if (gkey == 'q' || gkey != 'r')
		        #goto prompt_
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    call printf (
		    "Mark semi-major axis of rectangle (r=mark,q=quit:")
		    if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'r')
		        goto prompt_
		    call gamove (gd, xc, yc)
		    call gadraw (gd, x1, y1)
		    radius = (x1 - xc) ** 2 + (y1 - yc) ** 2
		    if (radius <= 0.0)
		        goto prompt_
		    radius = sqrt (radius)
		    theta = RADTODEG (atan2 (y1 - yc, x1 - xc))
		    if (theta < 0.0)
		        theta = 360.0 + theta
		    call printf (
		    "Mark semi-minor axis of rectangle (r=mark,q=quit:")
		    if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		        SZ_LINE) == EOF) 
		        goto prompt_
		    if (gkey == 'q' || gkey != 'r')
		        goto prompt_
		    ratio = (x2 - xc) ** 2 + (y2 - yc) ** 2
		    if (ratio <= 0.0)
		        goto prompt_
		    ishape = XP_ORECTANGLE
		    ratio = min (sqrt (ratio) / radius, 1.0)
		    call gamove (gd, xc, yc)
		    call gadraw (gd, xc - ratio * (y1 - yc),
		        yc + ratio * (x1 - xc))
		}
		npolygon = 0
		nvertices = 0
		xshift = 0.0
		yshift = 0.0

	    case 'p':
		if (atype == XP_ATYPE_OBJASKY && mod (ntimes,2) == 1) {
		    xc = XP_OXINIT(symbol)
		    yc = XP_OYINIT(symbol)
		    call gscur (gd, xc, yc)
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    if (XP_OGEOMETRY(symbol) == XP_OPOLYGON) {
			xs = (Memr[xver] + Memr[xver+1]) / 2.0
			ys = (Memr[yver] + Memr[yver+1]) / 2.0
			call gscur (gd, xs, ys)
		        call printf (
		"Mark inner boundary of polygonal annulus (p=mark,q=quit:")
		        if (clgcur ("gcommands", x1, y1, gwcs, gkey, Memc[cmd],
		            SZ_LINE) == EOF) 
		            goto prompt_
		        if (gkey == 'q' || gkey != 'p')
		            goto prompt_
			if (((x1 - xc) ** 2 + (y1 - yc) ** 2) <
			    ((xs - xc) ** 2 + (ys - yc) ** 2))
			    goto prompt_
			srin = (x1 - xs) ** 2 + (y1 - ys) ** 2
			if (srin <= 0.0)
		            goto prompt_
			srin = sqrt (srin)
		        call printf (
		"Mark outer boundary of polygonal annulus (p=mark,q=quit:")
		        if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		            SZ_LINE) == EOF) 
		            goto prompt_
		        if (gkey == 'q' || gkey != 'p')
		            goto prompt_
			if (((x2 - xc) ** 2 + (y2 - yc) ** 2) <
			    ((x1 - xc) ** 2 + (y1 - yc) ** 2))
			    goto prompt_
			srout = (x2 - x1) ** 2 + (y2 - y1) ** 2
			if (srout <= 0.0)
		            goto prompt_
			srout = sqrt (srout)
			ishape = XP_OPOLYGON
			npolygon = XP_ONPOLYGON(symbol)
			xshift = XP_OXSHIFT(symbol)
			yshift = XP_OYSHIFT(symbol)
		    } else {
	                call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
		        nvertices = xp_trpoly (gd, Memr[xver], Memr[yver],
		            MAX_NOBJ_VERTICES, NO)
		        if (nvertices < 3)
		            goto prompt_
			xs = asumr (Memr[xver], nvertices) / nvertices
			ys = asumr (Memr[yver], nvertices) / nvertices
			x1 = (Memr[xver] + Memr[xver+1]) / 2.0
			y1 = (Memr[yver] + Memr[yver+1]) / 2.0
			call gscur (gd, x1, y1)
		        call printf (
		"Mark outer boundary of polygonal annulus (p=mark,q=quit:")
		        if (clgcur ("gcommands", x2, y2, gwcs, gkey, Memc[cmd],
		            SZ_LINE) == EOF) 
		            goto prompt_
		        if (gkey == 'q' || gkey != 'p')
		            goto prompt_
			if (((x2 - xs) ** 2 + (y2 - ys) ** 2) <
			    ((x1 - xs) ** 2 + (y1 - ys) ** 2))
			    goto prompt_
			srout = (x2 - x1) ** 2 + (y2 - y1) ** 2
			if (srout <= 0.0)
		            goto prompt_
			srout = sqrt (srout)
			srin = 0.0
			npolygon = npolygons + 1
		        xshift = xc - xs
		        yshift = yc - ys
		        ishape = XP_OPOLYGON
		    }
		} else {
		    switch (atype) {
		    case XP_ATYPE_OBJ:
	                call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
		    case XP_ATYPE_SKY:
	                call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	        call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
		    default:
			if (mod (ntimes, 2) == 0) {
	                    call gseti (gd, G_PLCOLOR, xp_opcolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_opcolor(xp))
			} else {
	                    call gseti (gd, G_PLCOLOR, xp_oscolor(xp))
	    	            call gseti (gd, G_TXCOLOR, xp_oscolor(xp))
			}
		    }
		    call gmark (gd, xc, yc, GM_PLUS, 0.005, 0.005)
		    nvertices = xp_trpoly (gd, Memr[xver], Memr[yver],
		        MAX_NOBJ_VERTICES, YES)
		    if (nvertices < 3)
		        goto prompt_
		    xc = asumr (Memr[xver], nvertices) / nvertices
		    yc = asumr (Memr[yver], nvertices) / nvertices
		    ishape = XP_OPOLYGON
		    radius = 0.0
		    npolygon = npolygons + 1
		    xshift = 0.0
		    yshift = 0.0
		}
		ratio = 1.0
		theta = 0.0

	    default:
		goto prompt_
	    }

	    # Store the object in the objects list.
	    switch (atype) {

	    case XP_ATYPE_SKY:
	        nobjects = nobjects + 1
	        call sprintf (Memc[name], SZ_FNAME, "objlist%d")
	            call pargi (nobjects)
	        symbol = stenter (stptr, Memc[name], LEN_OBJLIST_STRUCT) 
	        XP_OXINIT(symbol) =  xc
	        XP_OYINIT(symbol) =  yc
	        XP_OGEOMETRY(symbol) = XP_OINDEF
	        call sprintf (XP_OAPERTURES(symbol), MAX_SZAPERTURES, "%0.2f")
	            call pargr (0.0)
	        XP_OAXRATIO(symbol) = 1.0
	        XP_OPOSANG(symbol) = 0.0
	        XP_ONPOLYGON(symbol) = 0
	        XP_OXSHIFT(symbol) = 0.0
	        XP_OYSHIFT(symbol) = 0.0

	    default:
		if (atype == XP_ATYPE_OBJ || mod (ntimes,2) == 0) {
	            nobjects = nobjects + 1
	            call sprintf (Memc[name], SZ_FNAME, "objlist%d")
	                call pargi (nobjects)
	            symbol = stenter (stptr, Memc[name], LEN_OBJLIST_STRUCT) 
	            XP_OXINIT(symbol) =  xc
	            XP_OYINIT(symbol) =  yc
	            XP_OGEOMETRY(symbol) = ishape
	            call sprintf (XP_OAPERTURES(symbol), MAX_SZAPERTURES,
		        "%0.2f")
	                call pargr (radius)
	            XP_OAXRATIO(symbol) = ratio
	            XP_OPOSANG(symbol) = theta
	            XP_ONPOLYGON(symbol) = npolygon
	            XP_OXSHIFT(symbol) = xshift
	            XP_OYSHIFT(symbol) = yshift
	            if (npolygon > npolygons) {
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
	                    call pargi (npolygon)
	                psymbol = stenter (plyptr, Memc[name],
		            LEN_POLYGONLIST_STRUCT) 
		        npolygons = npolygons + 1
		        XP_ONVERTICES(psymbol) = nvertices
		        call amovr (Memr[xver], XP_XVERTICES(psymbol),
		            nvertices + 1)
		        call amovr (Memr[yver], XP_YVERTICES(psymbol),
		            nvertices + 1)
		        XP_SNVERTICES(psymbol) = 0
			XP_POLYWRITTEN(psymbol) = NO
		    } else if (npolygon > 0) {
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
	                    call pargi (npolygon)
		        psymbol = stfind (plyptr, Memc[name])
	            } else
		        psymbol = NULL
		}
	    }

	    switch (atype) {
	    case XP_ATYPE_OBJ:
		XP_OSXINIT(symbol) = INDEFR
		XP_OSYINIT(symbol) = INDEFR
		XP_OSGEOMETRY(symbol) = XP_OINDEF
		XP_OSRIN(symbol) = INDEFR
		XP_OSROUT(symbol) = INDEFR
	        XP_OSAXRATIO(symbol) = 1.0
	        XP_OSPOSANG(symbol) = 0.0
	        XP_OSNPOLYGON(symbol) = 0
	        XP_OSXSHIFT(symbol) = 0.0
	        XP_OSYSHIFT(symbol) = 0.0
	    default:
		if (atype == XP_ATYPE_SKY || mod (ntimes,2) == 1) {
		    if (atype == XP_ATYPE_OBJOSKY) {
		        XP_OSXINIT(symbol) = xc
		        XP_OSYINIT(symbol) = yc
		    } else {
		        XP_OSXINIT(symbol) = INDEFR
		        XP_OSYINIT(symbol) = INDEFR
		    }
		    if (atype == XP_ATYPE_OBJASKY) {
			XP_OSRIN(symbol) = srin
			XP_OSROUT(symbol) = srout
		    } else {
			XP_OSRIN(symbol) = 0.0
			XP_OSROUT(symbol) = radius
		    }
	            XP_OSGEOMETRY(symbol) = ishape
	            XP_OSAXRATIO(symbol) = ratio
	            XP_OSPOSANG(symbol) = theta
	            XP_OSNPOLYGON(symbol) = npolygon
	            XP_OSXSHIFT(symbol) = xshift
	            XP_OSYSHIFT(symbol) = yshift
	            if (npolygon > npolygons) {
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
	                    call pargi (npolygon)
	                psymbol = stenter (plyptr, Memc[name],
		            LEN_POLYGONLIST_STRUCT) 
		        npolygons = npolygons + 1
			XP_ONVERTICES(psymbol) = 0
		        XP_SNVERTICES(psymbol) = nvertices
		        call amovr (Memr[xver], XP_XVERTICES(psymbol),
		            nvertices + 1)
		        call amovr (Memr[yver], XP_YVERTICES(psymbol),
		            nvertices + 1)
			XP_POLYWRITTEN(psymbol) = NO
	            } else if (npolygon > 0) {
	                call sprintf (Memc[name], SZ_FNAME, "polygonlist%d")
	                    call pargi (npolygon)
			psymbol = stfind (plyptr, Memc[name])
		    } else
		        psymbol = NULL
		}
	    }
	    XP_ODELETED(symbol) = NO

	    # Mark the object on the image display.
	    switch (atype) {

	    case XP_ATYPE_OBJ:
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
                call xp_omkshape (gd, symbol, psymbol, psymbol, 0.0, 0.0,
		    1.0, YES, NO, mksize)

	    case XP_ATYPE_SKY:
	        call gseti (gd, G_PLCOLOR, xp_oscolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_oscolor (xp))
                call xp_omkshape (gd, symbol, psymbol, psymbol, 0.0, 0.0,
		    1.0, NO, YES, mksize)

	    default:
		if (mod (ntimes, 2) == 0) {
	            call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	            call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
                    call xp_omkshape (gd, symbol, psymbol, psymbol, 0.0, 0.0,
		        1.0, YES, NO, mksize)
		} else if (mod (ntimes,2) == 1) {
	            call gseti (gd, G_PLCOLOR, xp_oscolor (xp))
	            call gseti (gd, G_TXCOLOR, xp_oscolor (xp))
                    call xp_omkshape (gd, symbol, psymbol, psymbol, 0.0, 0.0,
		        1.0, NO, YES, mksize)
		}
	    }

	    # Label the new object with the object/sky number if appropriate.
            if (xp_stati (xp, ONUMBER) == YES) {
	        call gseti (gd, G_PLCOLOR, xp_opcolor (xp))
	        call gseti (gd, G_TXCOLOR, xp_opcolor (xp))
                if (itoc (nobjects, Memc[name], SZ_FNAME) <= 0)
                    call strcpy ("", Memc[name], SZ_FNAME)
                Memc[format] = EOS
                call gtext (gd, xc + 2.0, yc + 2.0, Memc[name], Memc[format])
	    }

	    ntimes = ntimes + 1
	    switch (atype) {
            case XP_ATYPE_SKY:
	        osymbol = symbol
                call printf (SPSTR)
            case XP_ATYPE_OBJASKY:
                if (mod (ntimes,2) == 0) {
	            osymbol = symbol
                    call printf (OPSTR)
                } else {
                   call printf (SPSTR)
                }
            case XP_ATYPE_OBJOSKY:
                if (mod (ntimes,2) == 0) {
	            osymbol = symbol
                    call printf (OPSTR)
                } else {
                    call printf (SPSTR)
                }
            default:
	        osymbol = symbol
                call printf (OPSTR)
            }
	    next
prompt_
	    if (mod (ntimes,2) == 1)
		ntimes = ntimes + 1
	    switch (atype) {
	    case XP_ATYPE_SKY:
	        call printf (SPSTR)
	    default:
	        call printf (OPSTR)
	    }
	}

	call gseti (gd, G_PLTYPE, olinetype)
	call gseti (gd, G_PMLTYPE, omarktype)
	call gseti (gd, G_PLCOLOR, omkcolor)
	call gseti (gd, G_TXCOLOR, otxcolor)
	call gim_setraster (gd, 0)

	call sfree (sp)
end


# XP_ZOBJECTS -- Clear the objects list.

procedure xp_zobjects (xp)

pointer	xp			#I the pointer to the xapphot data structure

pointer	stptr, polyptr

begin
	call xp_openobjects (xp, stptr, polyptr)
end
