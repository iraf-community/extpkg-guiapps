include <gset.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "uipars.h"

# XP_UPLMEAS -- Procedure to execute the sky fitting task measuring commands.

pointer procedure xp_uplmeas (gd, ui, xp, im, ol, rl, gl, key, wx, wy,
	oxver, oyver, nover, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	ol			# the input object list descriptor
int	rl			# the results list descriptor
int	gl			# the output objects list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
real	oxver[ARB]		# the current object polygon x vertices
real	oyver[ARB]		# the current object polygon y vertices
int	nover			# the number of object vertices
real	sxver[ARB]		# the current sky polygon x vertices
real	syver[ARB]		# the current sky polygon y vertices
int	nsver			# the number of sky vertices

int	nobjs, object, nextobject, cier, sier, pier
pointer	sp, imname, olname, rlname, geomstr, str, symbol, pstatus
real	wxlist, wylist
int	xp_robjects(), stnsymbols(), xp_nextobject(), xp_prevobject()
int	xp_fobject(), xp_fitcenter(), xp_ofitsky(), xp_magp(), xp_stati()
pointer	stfind(), xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call salloc (geomstr, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
	pstatus = xp_statp(xp,PSTATUS)
	symbol = NULL
	object = OBJNO(pstatus)

	# Read the objects file.
	if (Memc[olname] == EOS) {
	    #call printf ("Warning: The current objects file is undefined\n")
	} else if (ol == NULL) {
	    #call printf ("Warning: Cannot open current objects file (%s)\n")
		#call pargstr (Memc[olname])
	} else if (xp_statp (xp, OBJLIST) == NULL) {
	    nobjs = xp_robjects (ol, xp, RLIST_NEW)
	    if (nobjs <= 0) {
		call printf (
		    "Warning: The current objects file (%s) is empty\n")
		    call pargstr (Memc[olname])
	    } else {
		call printf ("Read %d objects from current objects file %s\n")
		    call pargi (nobjs)
		    call pargstr (Memc[olname])
	    }
            if (UI_SHOWOBJLIST(ui) == YES) 
                call xp_mkslist (gd, ui, xp)
	    call gmsgi (gd, UI_OBJNO(ui), object)
	    call gmsg (gd, UI_OBJMARKER(ui), "INDEF")

	}

	switch (key) {

	# Move around the objects lists measuring objects.
	case 'o', '-', '.':
	    if (im == NULL) {
		call printf ("Warning: Cannot open current image (%s)\n")
		    call pargstr (Memc[imname])
		nextobject = 0
	    } else if (xp_statp (xp, OBJLIST) == NULL) {
		call printf ("Warning: The current object list is empty\n")
		nextobject = 0
	    } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		call printf ("Warning: The current object list is empty\n")
		nextobject = 0
	    } else if (key == 'o') {
		if (xp_nextobject (xp, object) == EOF) {
		    call printf (
			"Warning: The current objects list is at EOF\n")
		    nextobject = 0
		} else
		    nextobject = object
	    } else if (key == '-') {
		if (xp_prevobject (xp, object) == BOF) {
		    call printf (
			"Warning: The current objects list is at BOF\n")
		    nextobject = 0
		 } else
		    nextobject = object
	    } else if (key == '.') {
	        nextobject = xp_fobject (xp, wx, wy, wxlist, wylist)
		if (nextobject <= 0) {
		    call printf (
		        "Warning: Marked object not in current object list\n")
	        } else
		    object = nextobject
	    }


	    if (nextobject > 0) {

		# Find the object.
		call sprintf (Memc[str], SZ_FNAME, "objlist%d")
                    call pargi (nextobject)
                symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])
                wxlist = XP_OXINIT(symbol)
                wylist = XP_OYINIT(symbol)

		# Do the photometry and mark the object.
                cier = xp_fitcenter (xp, im, wxlist, wylist)
                sier = xp_ofitsky (xp, im, symbol, xp_statr (xp, XSHIFT),
		    xp_statr (xp, YSHIFT), sxver, syver, nsver, NULL, NULL)
                pier = xp_magp (xp, im, symbol, xp_statr (xp, XSHIFT),
		    xp_statr (xp, YSHIFT), oxver, oyver, nover,
		    xp_statr(xp, SKY_MODE), xp_statr(xp, SKY_STDEV),
		    xp_stati (xp, NSKY))
                call xp_oamark (gd, xp, symbol, oxver, oyver, nover, sxver,
		    syver, nsver, 1, 1)

		# Write the results to the status line.
		call xp_upqprint (xp, cier, sier, pier, LOGRESULTS(pstatus))

		# Write the results to a file.
		if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		    SEQNO(pstatus) = SEQNO(pstatus) + 1
		    call xp_pwrite (xp, rl, SEQNO(pstatus), Memc[olname],
		        nextobject, cier, sier, pier)
		}

		# Write the results to the GUI table.
		if (UI_SHOWPTABLE(ui) == YES)
                    call xp_tmkresults (gd, ui, xp)

                # Move the cursor and draw the object marker.
                call gim_setraster (gd, 1)
                call gscur (gd, wxlist, wylist)
                call gim_setraster (gd, 0)
                call xp_ogeometry (xp, symbol, oxver, oyver, nover, sxver,
		    syver, nsver, Memc[geomstr], SZ_LINE)
                call gmsgi (gd, UI_OBJNO(ui), nextobject)
                call gmsg (gd, UI_OBJMARKER(ui), Memc[geomstr])

		# Draw the plot panel.
                if (UI_SHOWPLOTS(ui) == YES) {

		    # Write the results to the GUI object.
		    if (rl != NULL && LOGRESULTS(pstatus) == YES)
                        call xp_omkresults (gd, ui, xp, nextobject,
			    SEQNO(pstatus))
		    else
                        call xp_omkresults (gd, ui, xp, nextobject, INDEFI)

		    # Make the plots.
		    call xp_udoplots (gd, ui, xp, im, symbol, oxver, oyver,
			nover, sxver, syver, nsver)
                }

		# Update pstatus.
                NEWCBUF(pstatus) = NO; NEWCENTER(pstatus) = NO
                NEWSBUF(pstatus) = NO; NEWSKY(pstatus) = NO
                NEWMBUF(pstatus) = NO; NEWMAG(pstatus) = NO
                wx = wxlist; wy = wylist

	    } else {
		symbol = NULL
                #call gmsg (gd, UI_OBJMARKER(ui), "INDEF")
	    }


	# Do photometry for the current and all remaining objects
	case '+', '#':
            if (im == NULL) {
                call printf ("Warning: Cannot open image (%s)\n")
                    call pargstr (Memc[imname])
            } else if (xp_statp (xp, OBJLIST) == NULL) {
                call printf ("Warning: The current objects list is empty\n")
            } else if (stnsymbols (xp_statp(xp,OBJLIST),0) <= 0) {
                call printf ("Warning: The current objects list is empty\n")
            } else if (key == '+' && object == EOF) {
                call printf ("Warning: The current objects list is at EOF\n")
            } else {
                call flush (STDOUT)
                if (object == BOF || key == '#')
                    nextobject = 0
                else
                    nextobject = object
                call gmsg (gd, UI_OBJMARKER(ui), "INDEF")

		symbol = NULL
                while (xp_nextobject (xp, nextobject) != EOF) {
                    call sprintf (Memc[str], SZ_FNAME, "objlist%d")
                        call pargi (nextobject)
                    symbol = stfind (xp_statp(xp,OBJLIST), Memc[str])
                    wxlist = XP_OXINIT(symbol)
                    wylist = XP_OYINIT(symbol)
                    cier = xp_fitcenter (xp, im, wxlist, wylist)
                    sier = xp_ofitsky (xp, im, symbol, xp_statr (xp, XSHIFT),
		        xp_statr (xp, YSHIFT), sxver, syver, nsver, NULL, NULL)
                    pier = xp_magp (xp, im, symbol, xp_statr (xp, XSHIFT),
		        xp_statr (xp, YSHIFT), oxver, oyver, nover,
			xp_statr(xp, SKY_MODE), xp_statr(xp, SKY_STDEV),
			xp_stati (xp, NSKY))
		    if (UI_SHOWPTABLE(ui) == YES)
		        call xp_tmkresults (gd, ui, xp)
                    call xp_oamark (gd, xp, symbol, oxver, oyver, nover,
		        sxver, syver, nsver, 1, 1)
		    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		        SEQNO(pstatus) = SEQNO(pstatus) + 1
		        call xp_pwrite (xp, rl, SEQNO(pstatus), Memc[olname],
			    nextobject, cier, sier, pier)
		    }
                    wx = wxlist; wy = wylist
                }

		# Display the last object measured.
		if (symbol != NULL) {

                    call gmsgi (gd, UI_OBJNO(ui), stnsymbols(xp_statp(xp,
			OBJLIST), 0))

		    # Write to the status line.
		    #call xp_pqstatus (xp, xp_stati(xp,NAPERTS), cier,
		        #sier, pier)
		    call xp_upqprint (xp, cier, sier, pier, LOGRESULTS(pstatus))

                    # Move the cursor and draw the marker.
                    call gim_setraster (gd, 1)
                    call gscur (gd, XP_OXINIT(symbol), XP_OYINIT(symbol))
                    call gim_setraster (gd, 0)
                    call xp_ogeometry (xp, symbol, oxver, oyver, nover,
		        sxver, syver, nsver, Memc[geomstr], SZ_LINE)
                    call gmsg (gd, UI_OBJMARKER(ui), Memc[geomstr])

		    # Do the plots.
                    if (UI_SHOWPLOTS(ui) == YES) {

                        # Send the results to the object tables.
		        if (rl != NULL && LOGRESULTS(pstatus) == YES)
                            call xp_omkresults (gd, ui, xp, nextobject,
			        SEQNO(pstatus))
			else
                            call xp_omkresults (gd, ui, xp, nextobject, INDEFI)

		        call xp_udoplots (gd, ui, xp, im, symbol, oxver, oyver,
			    nover, sxver, syver, nsver)
		    }
		}

                object = EOF
                NEWCBUF(pstatus) = NO; NEWCENTER(pstatus) = NO
                NEWSBUF(pstatus) = NO; NEWSKY(pstatus) = NO
                NEWMBUF(pstatus) = NO; NEWMAG(pstatus) = NO
                #call greactivate (gd, 0)
            }

	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}
	OBJNO(pstatus) = object

	call sfree (sp)

	return (symbol)
end


# XP_UPMEAS -- Procedure to execute the sky fitting task measuring commands.

pointer procedure xp_upmeas (gd, ui, xp, im, rl, gl, key, wx, wy, oxver,
	oyver, nover, sxver, syver, nsver)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface descriptor
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	rl			# the results list descriptor
int	gl			# the output objects list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
real	oxver[ARB]		# the current object polygon x vertices
real	oyver[ARB]		# the current object polygon y vertices
int	nover			# the number of object vertices
real	sxver[ARB]		# the current sky polygon x vertices
real	syver[ARB]		# the current sky polygon y vertices
int	nsver			# the number of sky vertices

int	wcs, cier, sier, pier, nobjs
real	swx, swy
pointer	sp, imname, rlname, str, pstatus
int	xp_stati(), clgcur(), xp_cfit1(), xp_sfit1(), xp_mag1(), xp_uaphot()
pointer	xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
	pstatus = xp_statp(xp,PSTATUS)

	switch (key) {

	# Measure and object near the cursor.
	case ' ':
            # Get the offset sky position.
            if (xp_stati(xp, SMODE) == XP_SOFFSET && xp_stati(xp,
		SALGORITHM) != XP_CONSTANT && xp_stati(xp, SALGORITHM) !=
		XP_ZERO && xp_stati(xp,SALGORITHM) != XP_SKYFILE) {
                call printf ("Again for sky:\n")
                if (clgcur ("gcommands", swx, swy, wcs, key, Memc[str],
                    SZ_LINE) == EOF)
                    ;
            }

	    # Measure.
            if (im != NULL) {
                if ((xp_stati (xp, PGEOMETRY) == XP_APOLYGON && nover < 3) ||
		    (xp_stati(xp,SGEOMETRY) == XP_SPOLYGON && nsver < 3)) {

                    call printf ("Sky or photometry polygon is undefined\n")

                } else {

                    cier = xp_cfit1 (xp, im, wx, wy, NEWCBUF(pstatus),
                        NEWCENTER(pstatus), cier)
                    if (xp_stati(xp, SMODE) == XP_SCONCENTRIC)
                        sier = xp_sfit1 (xp, im, xp_statr (xp, XCENTER),
                            xp_statr (xp, YCENTER), sxver, syver, nsver, NULL,
			    gd, NEWSBUF(pstatus), NEWSKY(pstatus))
                    else
                        sier = xp_sfit1 (xp, im, swx, swy, sxver, syver, nsver,
			    NULL, gd, NEWSBUF(pstatus), NEWSKY(pstatus))
                    pier = xp_mag1 (xp, im, xp_statr (xp, XCENTER),
                        xp_statr (xp, YCENTER), oxver, oyver, nover,
			xp_statr (xp, SKY_MODE), xp_statr (xp, SKY_STDEV),
			xp_stati (xp, NSKY), NEWMBUF(pstatus), NEWMAG(pstatus))
                    call xp_amark (gd, xp, oxver, oyver, nover, sxver, syver,
			nsver, 1, 1)

		    # Write to the status line.
		    call xp_upqprint (xp, cier, sier, pier, LOGRESULTS(pstatus))

		    # Write to the output file.
		    if (rl != NULL && LOGRESULTS(pstatus) == YES) {
		        SEQNO(pstatus) = SEQNO(pstatus) + 1
		        call xp_pwrite (xp, rl, SEQNO(pstatus), "none", 0,
			    cier, sier, pier)
		    }

		    # Write to the output table.
		    if (UI_SHOWPTABLE(ui) == YES)
                        call xp_tmkresults (gd, ui, xp)

		    # Do the plots.
                    if (UI_SHOWPLOTS(ui) == YES) {
		        if (rl != NULL && LOGRESULTS(pstatus) == YES)
                            call xp_omkresults (gd, ui, xp, INDEFI,
			        SEQNO(pstatus))
			else
                            call xp_omkresults (gd, ui, xp, INDEFI, INDEFI)
			call xp_udoplots (gd, ui, xp, im, NULL, oxver, oyver,
			    nover, sxver, syver, nsver)
                    }

                    NEWCBUF(pstatus) = NO; NEWCENTER(pstatus) = NO
                    NEWSBUF(pstatus) = NO; NEWSKY(pstatus) = NO
                    NEWMBUF(pstatus) = NO; NEWMAG(pstatus) = NO
               }
	   } else {
               call printf ("Warning: Cannot open image (%s)\n")
                   call pargstr (Memc[imname])
           }

	# Automatically detect and measure a list of objects.
	case '*':

            if (rl != NULL && LOGRESULTS(pstatus) == YES) {
                nobjs = xp_uaphot (gd, ui, im, rl, xp, NO)
                call printf (
		    "Wrote %d detected and measured objects to file %s\n")
                    call pargi (nobjs)
                    call pargstr (Memc[rlname])
            } else {
                nobjs = xp_uaphot (gd, ui, im, NULL, xp, NO)
                call printf ("Detected and measured %d objects\n")
                    call pargi (nobjs)
            }

	    # Print the results and do the plots for the last object.
            if (nobjs > 0) {
		#call xp_pqstatus (xp, xp_stati(xp,NAPERTS), cier, sier, pier)
		#call xp_pqprint (xp, "", cier, sier, pier)
	        if (UI_SHOWPLOTS(ui) == YES) {
		    if (rl != NULL && LOGRESULTS(pstatus) == YES)
                        call xp_omkresults (gd, ui, xp, INDEFI, SEQNO(pstatus))
	  	    else
                        call xp_omkresults (gd, ui, xp, INDEFI, INDEFI)
		    call xp_udoplots (gd, ui, xp, im, NULL, oxver, oyver,
		        nover, sxver, syver, nsver)
		}
            }

            NEWCBUF(pstatus) = NO; NEWCENTER(pstatus) = NO
            NEWSBUF(pstatus) = NO; NEWSKY(pstatus) = NO
            NEWMBUF(pstatus) = NO; NEWMAG(pstatus) = NO


	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}


	call sfree (sp)

	return (NULL)
end
