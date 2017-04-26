include "../lib/xphot.h"
include "../lib/objects.h"

# XP_OCOLON -- Process the objects algorithm colon commands.

int procedure xp_ocolon (gd, xp, cmdstr, symbol)

pointer gd		#I the pointer to the graphics stream
pointer	xp		#I the pointer to the main xapphot structure
char	cmdstr[ARB]	#I the input command string
int	symbol		#U the current object symbol

bool	bval
int	ncmd, stat, update, nvertices, ival, strfd, nobjs, nchars
pointer	sp, keyword, units, cmd, str, xver, yver, osymbol, psymbol
real	rval
bool	itob()
int	strdic(), nscan(), xp_stati(), btoi(), xp_strwrd(), fnldir(), strncmp()
int	stnsymbols(), stropen(), open(), xp_robjects(), xp_wobjects(), strlen()
pointer	xp_statp(), stfind(), stenter(), xp_ndobject(), xp_nudobject()
pointer	xp_nfobject()
real	xp_statr(), asumr()
errchk	open

begin
	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}

	# Process the command.
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_LINE, OCMDS)
	if (ncmd > 0) {
	    if (xp_strwrd (ncmd, Memc[units], SZ_FNAME, UOCMDS) <= 0)
		Memc[units] = EOS
	} else
	    Memc[units] = EOS 

	switch (ncmd) {

	case OCMD_OX:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OXINIT(symbol))
	    } else {
		XP_OXINIT(symbol) = rval
		update = YES
	    }

	case OCMD_OY:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OYINIT(symbol))
	    } else {
		XP_OYINIT(symbol) = rval
		update = YES
	    }

	case OCMD_OGEOMETRY:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (symbol == NULL)
		call printf ("The current object is undefined\n")
	    else if (Memc[cmd] == EOS) {
	        if (xp_strwrd (XP_OGEOMETRY(symbol), Memc[str], SZ_FNAME,
		    OGEOMETRIES) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, OGEOMETRIES)
		if (stat > 0) {
		    update = YES
		    XP_OGEOMETRY(symbol) = stat
		}
	    }

	case OCMD_OAPERTURES:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (symbol == NULL)
		call printf ("The current object is undefined\n")
	    else if (Memc[cmd] == EOS) {
		call printf ("%s = %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (XP_OAPERTURES(symbol))
	    } else {
		call strcpy (Memc[cmd], XP_OAPERTURES(symbol), MAX_SZAPERTURES)
		update = YES
	    }

	case OCMD_OAXRATIO:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OAXRATIO(symbol))
	    } else {
		XP_OAXRATIO(symbol) = rval
		update = YES
	    }

	case OCMD_OPOSANG:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OPOSANG(symbol))
		    call pargstr (Memc[units])
	    } else {
		XP_OPOSANG(symbol) = rval
		update = YES
	    }

	case OCMD_OVERTICES:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		if (XP_OGEOMETRY(symbol) != XP_OPOLYGON) {
		    call printf ("The object is not a polygon\n")
		} else if (XP_ONPOLYGON(symbol) <= 0) {
		    call printf ("The object polygon is undefined\n")
		} else {
		    call printf ("The object is  polygon %d\n")
			call pargi (XP_ONPOLYGON(symbol))
		}
	    } else {
		if (XP_OGEOMETRY(symbol) != XP_OPOLYGON) {
		    call printf ("The object is not a polygon\n")
		} else {
		    call salloc (xver, MAX_NOBJ_VERTICES, TY_REAL)
		    call salloc (yver, MAX_NOBJ_VERTICES, TY_REAL)
		    call sscan (Memc[cmd])
		    nvertices = 0
		    repeat {
			call gargr (Memr[xver+nvertices])
			call gargr (Memr[yver+nvertices])
			if (IS_INDEFR(Memr[xver+nvertices]) ||
			    IS_INDEFR(Memr[yver+nvertices]))
			    break
			nvertices = nvertices + 1
		    }
		    if (nvertices <= 2)
			call printf (
			    "The input polygon has too few vertices\n")
		    else {
			if (XP_ONPOLYGON(symbol) > 0) {
			    call sprintf (Memc[cmd], SZ_LINE, "polygonlist%d")
				call pargi (XP_ONPOLYGON(symbol))
			    psymbol = stfind (xp_statp(xp, POLYGONLIST),
			        Memc[cmd])
			} else {
			    XP_ONPOLYGON(symbol) = stnsymbols (xp_statp(xp,
			        POLYGONLIST), 0) + 1
			    call sprintf (Memc[cmd], SZ_LINE, "polygonlist%d")
				call pargi (stnsymbols(xp_statp(xp,
				POLYGONLIST), 0)+1)
			    psymbol = stenter (xp_statp(xp, POLYGONLIST),
			        Memc[cmd], LEN_OBJLIST_STRUCT)
			}
			XP_OXSHIFT(symbol) = XP_OXINIT(symbol) -
			    asumr(Memr[xver], nvertices) / nvertices
			XP_OYSHIFT(symbol) = XP_OYINIT(symbol) -
			    asumr(Memr[yver], nvertices) / nvertices
			XP_ONVERTICES(psymbol) = nvertices
			call amovr (Memr[xver], XP_XVERTICES(psymbol),
			    nvertices)
			call amovr (Memr[yver], XP_YVERTICES(psymbol),
			    nvertices)
			update = YES
		    }
		}
	    }

	case OCMD_OSX:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSXINIT(symbol))
	    } else {
		XP_OSXINIT(symbol) = rval
		update = YES
	    }

	case OCMD_OSY:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSYINIT(symbol))
	    } else {
		XP_OSYINIT(symbol) = rval
		update = YES
	    }

	case OCMD_OSGEOMETRY:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (symbol == NULL)
		call printf ("The current object is undefined\n")
	    else if (Memc[cmd] == EOS) {
	        if (xp_strwrd (XP_OSGEOMETRY(symbol), Memc[str], SZ_FNAME,
		    OSGEOMETRIES) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, OSGEOMETRIES)
		if (stat > 0) {
		    XP_OGEOMETRY(symbol) = stat
		    update = YES
		}
	    }

	case OCMD_OSRIN:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSRIN(symbol))
		    call pargstr (Memc[units])
	    } else {
		XP_OSRIN(symbol) = rval
		update = YES
	    }

	case OCMD_OSROUT:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSROUT(symbol))
		    call pargstr (Memc[units])
	    } else {
		XP_OSROUT(symbol) = rval
		update = YES
	    }

	case OCMD_OSAXRATIO:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSAXRATIO(symbol))
	    } else {
		XP_OSAXRATIO(symbol) = rval
		update = YES
	    }

	case OCMD_OSPOSANG:
	    call gargr (rval)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (XP_OSPOSANG(symbol))
		    call pargstr (Memc[units])
	    } else {
		XP_OSPOSANG(symbol) = rval
		update = YES
	    }

	case OCMD_OSVERTICES:
	    call gargstr (Memc[cmd], SZ_LINE)
	    if (symbol == NULL) {
		call printf ("The current object is undefined\n")
	    } else if (nscan() == 1) {
		if ((XP_OGEOMETRY(symbol) != XP_OPOLYGON &&
		    XP_OSGEOMETRY(symbol) == XP_OOBJECT) ||
		    XP_OSGEOMETRY(symbol) != XP_OPOLYGON) {
		    call printf ("The sky is not a polygon\n")
		} else if (XP_OSNPOLYGON(symbol) <= 0) {
		    call printf ("The sky polygon is undefined\n")
		} else {
		    call printf ("The sky polygon is %d\n")
			call pargi (XP_OSNPOLYGON(symbol))
		}
	    } else {
		if ((XP_OGEOMETRY(symbol) != XP_OPOLYGON &&
		    XP_OSGEOMETRY(symbol) == XP_OOBJECT) ||
		    XP_OSGEOMETRY(symbol) != XP_OPOLYGON) {
		    call printf ("The object is not a polygon\n")
		} else {
		    call salloc (xver, MAX_NOBJ_VERTICES, TY_REAL)
		    call salloc (yver, MAX_NOBJ_VERTICES, TY_REAL)
		    call sscan (Memc[cmd])
		    nvertices = 0
		    repeat {
			call gargr (Memr[xver+nvertices])
			call gargr (Memr[yver+nvertices])
			if (IS_INDEFR(Memr[xver+nvertices]) ||
			    IS_INDEFR(Memr[yver+nvertices]))
			    break
			nvertices = nvertices + 1
		    }
		    if (nvertices <= 2) {
			call printf (
			    "The input polygon has too few vertices\n")
		    } else {
			if (XP_OSNPOLYGON(symbol) > 0 &&
			    XP_OSNPOLYGON(symbol) != XP_ONPOLYGON(symbol)) {
			    call sprintf (Memc[cmd], SZ_LINE, "polygonlist%d")
				call pargi (XP_OSNPOLYGON(symbol))
			    psymbol = stfind (xp_statp(xp, POLYGONLIST),
			        Memc[cmd])
			} else {
			    XP_OSNPOLYGON(symbol) = stnsymbols (xp_statp(xp,
			        POLYGONLIST), 0) + 1
			    call sprintf (Memc[cmd], SZ_LINE, "polygonlist%d")
				call pargi (stnsymbols(xp_statp(xp,
				POLYGONLIST), 0)+1)
			    psymbol = stenter (xp_statp(xp, POLYGONLIST),
			        Memc[cmd], LEN_OBJLIST_STRUCT)
			}
			if (IS_INDEFR(XP_OSXINIT(symbol)))
			    XP_OSXSHIFT(symbol) = XP_OXINIT(symbol) -
			        asumr(Memr[xver], nvertices) / nvertices
			else
			    XP_OSXSHIFT(symbol) = XP_OSXINIT(symbol) -
			        asumr(Memr[xver], nvertices) / nvertices
			if (IS_INDEFR(XP_OSYINIT(symbol)))
			    XP_OSYSHIFT(symbol) = XP_OYINIT(symbol) -
			        asumr(Memr[yver], nvertices) / nvertices
			else
			    XP_OSYSHIFT(symbol) = XP_OSYINIT(symbol) -
			        asumr(Memr[xver], nvertices) / nvertices
			XP_ONVERTICES(psymbol) = nvertices
			call amovr (Memr[xver], XP_XVERTICES(psymbol),
			    nvertices)
			call amovr (Memr[yver], XP_YVERTICES(psymbol),
			    nvertices)
		        update = YES
		    }
		}
	    }

	case OCMD_OBJMARK:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, OBJMARK)))
	    } else {
		call xp_seti (xp, OBJMARK, btoi (bval))
		update = YES
	    }

	case OCMD_OCHARMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, OCHARMARK), Memc[str], SZ_FNAME,
		    OMARKERS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, OMARKERS)
		if (stat > 0) {
		    call xp_seti (xp, OCHARMARK, stat)
		    update = YES
		}
	    }

	case OCMD_ONUMBER:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob (xp_stati (xp, ONUMBER)))
	    } else {
		call xp_seti (xp, ONUMBER, btoi (bval))
		update = YES
	    }

	case OCMD_OPCOLORMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, OPCOLORMARK), Memc[str], SZ_FNAME,
		    OCOLORS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, OCOLORS)
		if (stat > 0) {
		    call xp_seti (xp, OPCOLORMARK, stat)
		    update = YES
		}
	    }

	case OCMD_OSCOLORMARK:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    if (Memc[cmd] == EOS) {
	        if (xp_strwrd (xp_stati (xp, OSCOLORMARK), Memc[str], SZ_FNAME,
		    OCOLORS) > 0) {
		    call printf ("%s = %s\n")
		        call pargstr (Memc[keyword])
		        call pargstr (Memc[str])
		}
	    } else {
		stat = strdic (Memc[cmd], Memc[cmd], SZ_LINE, OCOLORS)
		if (stat > 0) {
		    call xp_seti (xp, OSCOLORMARK, stat)
		    update = YES
		}
	    }

	case OCMD_OSIZEMARK:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, OSIZEMARK))
	    } else {
		call xp_setr (xp, OSIZEMARK, rval)
		update = YES
	    }

	case OCMD_OTOLERANCE:
	    call gargr (rval)
	    if (nscan() == 1) {
		call printf ("%s = %g %s\n")
		    call pargstr (Memc[keyword])
		    call pargr (xp_statr (xp, OTOLERANCE))
		    call pargstr (Memc[units])
	    } else {
		call xp_setr (xp, OTOLERANCE, rval)
		update = YES
	    }

	case OCMD_OSELECT, OCMD_ODELETE, OCMD_OUNDELETE:
	    call gargi (ival)
	    if (nscan() == 1)
		ival = OBJNO(xp_statp(xp,PSTATUS))
	    switch (ncmd) {
	    case OCMD_OSELECT:
		osymbol = xp_nfobject (gd, xp, ival)
	        if (osymbol != NULL) {
		    OBJNO(xp_statp(xp,PSTATUS)) = ival
		    symbol = osymbol
	        } #else 
		    #symbol = NULL
	    case OCMD_ODELETE:
		osymbol = xp_ndobject (gd, xp, ival, 1, 1)
	        if (osymbol != NULL) {
		    OBJNO(xp_statp(xp,PSTATUS)) = ival
		    symbol = osymbol
		    update = YES
	        } #else 
		    #symbol = NULL
	    case OCMD_OUNDELETE:
		osymbol = xp_nudobject (gd, xp, ival, 1, 1)
	        if (osymbol != NULL) {
		    OBJNO(xp_statp(xp,PSTATUS)) = ival
		    symbol = osymbol
		    update = YES
	        } #else 
		    #symbol = NULL
	    }

	case OCMD_OADD:
	    call gargstr (Memc[str], SZ_FNAME)
	    if (nscan() == 1 || Memc[str] == EOS)
		;
	    else {
		strfd = stropen (Memc[str], SZ_FNAME, READ_ONLY)
		if (xp_statp(xp,OBJLIST) == NULL)
		    nobjs = 0
		else 
		    nobjs = stnsymbols (xp_statp(xp, OBJLIST), 0)
		if (xp_robjects (strfd, xp, RLIST_APPENDONE) > nobjs)
		    update = YES
		call close (strfd)
	    }

	case OCMD_OSAVE:
	    call gargwrd (Memc[str], SZ_FNAME)
            if (xp_statp (xp, OBJLIST) == NULL) {
                call printf ("Warning: The object list is empty\n")
            } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
                call printf ("Warning: The object list is empty\n")
	    } else {
		nchars = fnldir (Memc[str], Memc[cmd], SZ_FNAME)
    		if (strncmp ("default", Memc[str+nchars], 7) == 0 || 
		    nchars == strlen(Memc[str])) {
		    call xp_stats (xp, IMAGE, Memc[str], SZ_FNAME)
		    if (Memc[str] == EOS)
		        call strcpy ("image", Memc[str], SZ_FNAME)
		    call xp_outname (Memc[str], Memc[cmd], "obj", Memc[cmd],
		        SZ_FNAME)
		} else
		    call strcpy (Memc[str], Memc[cmd], SZ_FNAME)
		iferr {
		    strfd = open (Memc[cmd], NEW_FILE, TEXT_FILE)  
		} then {
		    call printf (
		        "Warning: Unable to open file %s for writing\n")
			call pargstr (Memc[cmd])
		} else {
		    nobjs = xp_wobjects (strfd, xp, NO, NO)
		    call printf ("%d objects written to file %s\n")
			call pargi (nobjs)
			call pargstr (Memc[cmd])
		    call close (strfd)
		}
	    }


	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end
