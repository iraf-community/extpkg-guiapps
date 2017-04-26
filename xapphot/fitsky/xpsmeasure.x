include "../lib/xphot.h"
include "../lib/objects.h"
include "../lib/fitsky.h"

# XP_SLMEAS -- Procedure to execute the sky fitting task measuring commands.

pointer procedure xp_slmeas (gd, xp, im, ol, rl, gl, key, wx, wy, xver,
	yver, nver)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	ol			# the input object list descriptor
int	rl			# the results list descriptor
int	gl			# the output object list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
real	xver[ARB]		# the current polygon x vertices
real	yver[ARB]		# the current polygon y vertices
int	nver			# the number of vertices

int	nobjs, object, nextobject, ier
pointer	sp, imname, olname, rlname, str, symbol, pstatus
real	wxlist, wylist
int	xp_robjects(), stnsymbols(), xp_nextobject(), xp_prevobject()
int	xp_fobject(), xp_ofitsky()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
	pstatus = xp_statp(xp,PSTATUS)
	object = OBJNO(pstatus)

	# Read the objects file.
	if (Memc[olname] == EOS) {
	    #call printf ("Warning: The objects file is undefined\n")
	} else if (ol == NULL) {
	    #call printf ("Warning: Cannot open objects file (%s)\n")
		#call pargstr (Memc[olname])
	} else if (xp_statp (xp, OBJLIST) == NULL) {
	    nobjs = xp_robjects (ol, xp, RLIST_NEW)
	    if (nobjs <= 0) {
		call printf (
		    "Warning: The objects file (%s) is empty\n")
		    call pargstr (Memc[olname])
	    } else {
		call printf ("Read %d objects from objects file %s\n")
		    call pargi (nobjs)
		    call pargstr (Memc[olname])
	    }
	}

	switch (key) {

	# Move around the objects lists measuring objects.
	case 'o', '-', '.':
	    if (im == NULL) {
		call printf ("Warning: Cannot open image (%s)\n")
		    call pargstr (Memc[imname])
		nextobject = 0
	    } else if (xp_statp (xp, OBJLIST) == NULL) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else if (key == 'o') {
		if (xp_nextobject (xp, object) == EOF) {
		    call printf (
			"Warning: The objects list is at EOF\n")
		    nextobject = 0
		} else
		    nextobject = object
	    } else if (key == '-') {
		if (xp_prevobject (xp, object) == BOF) {
		    call printf (
			"Warning: The objects list is at BOF\n")
		    nextobject = 0
		 } else
		    nextobject = object
	    } else if (key == '.') {
	        nextobject = xp_fobject (xp, wx, wy, wxlist, wylist)
		if (nextobject <= 0) {
		    call printf (
		        "Warning: Marked object not in object list\n")
	        } else
		    object = nextobject
	    }

	    if (nextobject > 0) {
		call gim_setraster (gd, 1)
		call sprintf (Memc[str], SZ_FNAME, "objlist%d")
                    call pargi (nextobject)
                symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])
		if (IS_INDEFR(XP_OSXINIT(symbol)) ||
		    IS_INDEFR(XP_OSYINIT(symbol)))
		    call gscur (gd, XP_OXINIT(symbol), XP_OYINIT(symbol))
		else
		    call gscur (gd, XP_OSXINIT(symbol), XP_OSYINIT(symbol))
		call gim_setraster (gd, 0)
                ier = xp_ofitsky (xp, im, symbol, 0.0, 0.0, xver, yver, nver,
		    NULL, gd)
                call xp_osmark (gd, xp, symbol, xver, yver, nver, 1, 1)
		call gdeactivate (gd, 0)
                call xp_sqprint (xp, Memc[imname], ier, LOGRESULTS(pstatus))
		call greactivate (gd, 0)
		if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		    SEQNO(pstatus) = SEQNO(pstatus) + 1
		    call xp_swrite (xp, rl, SEQNO(pstatus), Memc[olname],
		        nextobject, ier)
		}
                wx = xp_statr (xp, SXCUR)
		wy = xp_statr (xp, SYCUR)
                NEWSBUF(pstatus) = NO; NEWSKY(pstatus) = NO
	    } else
		symbol = NULL

	# Fit sky for the current and all remaining objects
	case '+', '#':
	    symbol = NULL
            if (im == NULL) {
                call printf ("Warning: Cannot open image (%s)\n")
                    call pargstr (Memc[imname])
	    } else if (xp_statp (xp, OBJLIST) == NULL) {
                call printf ("Warning: The objects list is empty\n")
            } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
                call printf ("Warning: The objects list is empty\n")
            } else if (object == EOF) {
                call printf ("Warning: The objects list is at EOF\n")
            } else {
	        call flush (STDOUT)
                if (object == BOF || key == '#')
                    nextobject = 0
                else
                    nextobject = object
		nobjs = 0
		while (xp_nextobject (xp, nextobject) != EOF) {
		    call sprintf (Memc[str], SZ_FNAME, "objlist%d")
                        call pargi (nextobject)
                    symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])
                    ier = xp_ofitsky (xp, im, symbol, 0.0, 0.0, xver, yver,
		        nver, NULL, gd)
                    call xp_osmark (gd, xp, symbol, xver, yver, nver, 1, 1)
		    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		        SEQNO(pstatus) = SEQNO(pstatus) + 1
		        call xp_swrite (xp, rl, SEQNO(pstatus), Memc[olname],
			    nextobject, ier)
		    }
                    wx = xp_statr (xp, SXCUR)
		    wy = xp_statr (xp, SYCUR)
		    nobjs = nobjs + 1
                }
                object = EOF
		NEWSBUF(pstatus) = NO
		NEWSKY(pstatus) = NO
                if (rl != NULL && LOGRESULTS(pstatus) == YES) {
                    call printf ("Wrote %d measured list objects to file %s\n")
                        call pargi (nobjs)
                        call pargstr (Memc[rlname])
                } else {
                    call printf ("Measured %d list objects\n")
                        call pargi (nobjs)
                }
            }


	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}
	OBJNO(pstatus) = object

	call sfree (sp)

	return (symbol)
end


# XP_SMEAS -- Procedure to execute the sky fitting task measuring commands.

pointer procedure xp_smeas (gd, xp, im, rl, gl, key, wx, wy, xver, yver,
	nver)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	rl			# the results list descriptor
int	gl			# the output object list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
real	xver[ARB]		# the current polygon x vertices
real	yver[ARB]		# the current polygon y vertices
int	nver			# the number of vertices

int	ier, nobjs
pointer	sp, imname, rlname, pstatus
int	xp_stati(), xp_fitsky(), xp_refitsky(), xp_asky()
pointer	xp_statp()

begin
	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
	pstatus = xp_statp(xp,PSTATUS)

	switch (key) {

	# Measure an object near the cursor.
	case ' ':
            if (im != NULL) {
		if (xp_stati(xp,SGEOMETRY) == XP_SPOLYGON && nver < 3)
		    call printf ("The polygonal sky aperture is undefined\n")
		else {
                    if (NEWSBUF(pstatus) == YES)
                        ier = xp_fitsky (xp, im, wx, wy, xver, yver,
		            nver, NULL, gd)
                    else if (NEWSKY(pstatus) == YES)
                        ier = xp_refitsky (xp, gd)
                    call xp_smark (gd, xp, xver, yver, nver, 1, 1)
		    call gdeactivate (gd, 0)
                    call xp_sqprint (xp, Memc[imname], ier, LOGRESULTS(pstatus))
		    call greactivate (gd, 0)
		    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		        SEQNO(pstatus) = SEQNO(pstatus) + 1
		        call xp_swrite (xp, rl, SEQNO(pstatus), "none", 0, ier)
		    }
                    NEWSBUF(pstatus) = NO
                    NEWSKY(pstatus) = NO
		}
            } else {
                call printf ("Warning: Cannot open image (%s)\n")
                    call pargstr (Memc[imname])
            }

        # Automatically detect the objects in an image and compute their sky
        # values.
        case '*':
            if (rl != NULL && LOGRESULTS(pstatus) == YES) {
                nobjs = xp_asky (gd, im, rl, xp, NO)
                call printf ("Wrote %d measured objects to file %s\n")
                    call pargi (nobjs)
                    call pargstr (Memc[rlname])
            } else {
                nobjs = xp_asky (gd, im, NULL, xp, NO)
                call printf ("Detected and measured %d objects\n")
                    call pargi (nobjs)
            }

	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}

	call sfree (sp)

	return (NULL)
end
