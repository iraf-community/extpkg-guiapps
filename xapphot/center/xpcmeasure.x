include "../lib/xphot.h"
include "../lib/objects.h"
include "../lib/center.h"

# XP_CLMEAS -- Procedure to execute the centering task list measuring commands.

pointer procedure xp_clmeas (gd, xp, im, ol, rl, gl, key, wx, wy)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	ol			# the input object list descriptor
int	rl			# the results list descriptor
int	gl			# the ouput objects list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates

int	nobjs, object, nextobject, ier
pointer	sp, imname, olname, rlname, str, symbol, pstatus
real	wxlist, wylist
int	xp_robjects(), stnsymbols(), xp_nextobject(), xp_prevobject()
int	xp_fobject(), xp_fitcenter
pointer	stfind(), xp_statp()

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
		call gscur (gd, XP_OXINIT(symbol), XP_OYINIT(symbol))
		call gim_setraster (gd, 0)
                wxlist = XP_OXINIT(symbol)
                wylist = XP_OYINIT(symbol)
                ier = xp_fitcenter (xp, im, wxlist, wylist)
                call xp_ocmark (gd, xp, symbol, 1, 1)
		call gdeactivate (gd, 0)
                call xp_cqprint (xp, Memc[imname], ier, LOGRESULTS(pstatus))
		call greactivate (gd, 0)
		if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		    SEQNO(pstatus) = SEQNO(pstatus) + 1
		    call xp_cwrite (xp, rl, SEQNO(pstatus), Memc[olname],
		        nextobject, ier)
		}
                wx = wxlist; wy = wylist
                NEWCBUF(pstatus) = NO; NEWCENTER(pstatus) = NO

	    } else
		symbol = NULL

	# Measure all the remaining objects in the list.
	case '+', '#':
	    symbol = NULL
	    if (im == NULL) {
                call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                call printf ("Warning: Cannot open image (%s)\n")
                    call pargstr (Memc[imname])
            } else if (xp_statp (xp, OBJLIST) == NULL) {
                call printf ("Warning: The object list is empty\n")
            } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
                call printf ("Warning: The object list is empty\n")
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
                    wxlist = XP_OXINIT(symbol)
                    wylist = XP_OYINIT(symbol)
                    ier = xp_fitcenter (xp, im, wxlist, wylist)
                    call xp_ocmark (gd, xp, symbol, 1, 1)
		    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		        SEQNO(pstatus) = SEQNO(pstatus) + 1
		        call xp_cwrite (xp, rl, SEQNO(pstatus), Memc[olname],
			    nextobject, ier)
		    }
                    wx = wxlist; wy = wylist
		    nobjs = nobjs + 1
                }
	        if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		    call printf ("Wrote %d measured list objects to file %s\n")
		        call pargi (nobjs)
		        call pargstr (Memc[rlname])
	        } else {
	            call printf ("Measured %d list objects\n")
		        call pargi (nobjs)
	        }
                object = EOF
                NEWCBUF(pstatus) = NO
                NEWCENTER(pstatus) = NO
            }


	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}

	OBJNO(pstatus) = object

	call sfree (sp)

	return (symbol)
end


# XP_CMEAS -- Procedure to execute the centering task measuring commands.

pointer procedure xp_cmeas (gd, xp, im, rl, gl, key, wx, wy)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	rl			# the results list descriptor
int	gl			# the ouput objects list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates

int	nobjs, ier
pointer	sp, imname, rlname, pstatus
int	xp_fitcenter(), xp_refitcenter(), xp_acenter()
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
                if (NEWCBUF(pstatus) == YES)
                    ier = xp_fitcenter (xp, im, wx, wy)
                else if (NEWCENTER(pstatus) == YES)
                    ier = xp_refitcenter (xp, ier)
                call xp_cmark (gd, xp, 1, 1)
		call gdeactivate (gd, 0)
                call xp_cqprint (xp, Memc[imname], ier, LOGRESULTS(pstatus))
		call greactivate (gd, 0)
		if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		    SEQNO(pstatus) = SEQNO(pstatus) + 1
		    call xp_cwrite (xp, rl, SEQNO(pstatus), "none", 0, ier)
		}
                NEWCBUF(pstatus) = NO
                NEWCENTER(pstatus) = NO
            } else {
                call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                call printf ("Warning: Cannot open image (%s)\n")
                    call pargstr (Memc[imname])
            }


	# Automatically detect the objects in an image and center up on
	# them.
	case '*':
	    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		nobjs = xp_acenter (gd, im, rl, xp, NO)
		call printf ("Wrote %d measured objects to file %s\n")
		    call pargi (nobjs)
		    call pargstr (Memc[rlname])
	    } else {
		nobjs = xp_acenter (gd, im, NULL, xp, NO)
	        call printf ("Detected and measured %d objects\n")
		    call pargi (nobjs)
	    }


	default:
	    call printf ("Ambiguous or undefined keystroke command\n")

	}

	call sfree (sp)

	return (NULL)
end
