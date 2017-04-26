include "../lib/xphot.h"
include "../lib/objects.h"
include "uipars.h"

# XP_UDMEAS -- Procedure to execute the basic object list manipulation
# commands.

pointer procedure xp_udmeas (gd, ui, xp, im, ol, rl, key, wx, wy, oxver,
	oyver, nover, sxver, syver, nsver, skypos)

pointer	gd			# pointer to the graphics stream
pointer	ui			# pointer to the user interface
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	ol			# the input object list descriptor
int	rl			# the results list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
real	oxver[ARB]		# the object polygon vertices x coordinates
real	oyver[ARB]		# the object polygon vertices y coordinates
int	nover			# the number of object polygon vertices
real	sxver[ARB]		# the sky polygon vertices x coordinates
real	syver[ARB]		# the sky polygon vertices y coordinates
int	nsver			# the number of object polygon vertices
int	skypos			# sky positions ?

int	nobjs, object, nextobject
pointer	sp, imname, olname, rlname, str, geomstr, symbol
real	wxlist, wylist
int	xp_robjects(), stnsymbols(), xp_nextobject()
int	xp_prevobject(), xp_fobject(), xp_nobject()
int	xp_sfind()
pointer	stfind()
pointer	xp_statp()

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
	symbol = NULL
	object = OBJNO(xp_statp(xp,PSTATUS))

	# Generate the objects list automatically, otherwise read it in.
	if (key == '@') {
	    if (Memc[imname] == EOS) {
		call printf ("Warning: The image is undefined\n")
	    } else if (im == NULL) {
		call printf ("Warning: Cannot open image (%s)\n")
		    call pargstr (Memc[imname])
	    } else {
	        nobjs = xp_sfind (im, xp)
	        if (nobjs <= 0) {
		    call printf ("Warning: 0 objects detected in image %s\n")
	                call pargstr (Memc[imname])
	        } else {
	            call printf ("%d objects detected in image %s\n")
	                call pargi (nobjs)
	                call pargstr (Memc[imname])
		    call xp_mkobjects (gd, xp, 1, 1)
	        }
	    }
	} else if (Memc[olname] == EOS) {
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

	# Read the objects file into the objects list.
	case 'r':
	    if (Memc[olname] == EOS) {
		call printf ("Warning: The objects file is undefined\n")
	    } else if (ol == NULL) {
		call printf ("Warning: Cannot open objects file (%s)\n")
		    call pargstr (Memc[olname])
	    } else {
		nobjs = xp_robjects (ol, xp, RLIST_NEW)
		object = 0; nextobject = 0
		if (nobjs <= 0) {
		    call printf (
			"Warning: The objects file (%s) is empty\n")
			call pargstr (Memc[olname])
		} else {
		    call printf (
		        "Read %d objects from objects file %s\n")
		        call pargi (nobjs)
		        call pargstr (Memc[olname])
		}
		if (UI_SHOWOBJLIST(ui) == YES)
		    call xp_mkslist (gd, ui, xp)
		call gmsg (gd, UI_OBJNO(ui), 0)
		call gmsg (gd, UI_OBJMARKER(ui), "INDEF")
	    }

	# Display the objects list.
	case 'l':
            if (UI_SHOWOBJLIST(ui) == NO) {
                UI_SHOWOBJLIST(ui) = YES
                call gmsg (gd, UI_OBJECTS(ui), "yes")
                if (xp_statp (xp, OBJLIST) != NULL)
                    call xp_mkslist (gd, ui, xp)
                else {
                    call gmsg (gd, UI_OBJLIST(ui), "{}")
                    call printf ("The current object list is empty\n")
                }
		call gmsgi (gd, UI_OBJNO(ui), object)
            } else {
                UI_SHOWOBJLIST(ui) = NO
                call gmsg (gd, UI_OBJECTS(ui), "no")
            }


	# Write out the objects list to a file.
	case 'w':
	    #if (Memc[imname] == EOS) {
		#call printf ("Warning: The image is undefined\n")
	    #} else if (im == NULL) {
		#call printf ("Warning: Cannot open image (%s)\n")
		    #call pargstr (Memc[imname])
	    #} else if (xp_statp (xp, OBJLIST) == NULL) {
		#call printf ("Warning: The object list is empty\n")
	    #} else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		#call printf ("Warning: The object list is empty\n")
	    #} else if (rl != NULL) {
		#nobjs = xp_wobjects (rl, xp, NO, NO)
		#if (nobjs <= 0) {
		    #call printf (
		    #"Warning: Cannot write object list to file (%s)\n")
		        #call pargstr (Memc[rlname])
		#} else {
		    #call printf ("%d objects written to file %s\n")
			#call pargi (nobjs)
			#call pargstr (Memc[rlname])
		#}
	    #} else {
		#nobjs = xp_sobjects (xp, "obj", Memc[str], SZ_FNAME)
		#if (nobjs <= 0) {
		    #call printf (
		    #"Warning: Cannot write object list to file (%s)\n")
		        #call pargstr (Memc[str])
		#} else {
		    #call printf ("%d objects written to file %s\n")
			#call pargi (nobjs)
			#call pargstr (Memc[str])
		#}
	    #}

	# Move around the objects lists.
	case '^', 'f', 'b', '~':

	    # Find the object.
	    #if (Memc[imname] == EOS) {
		#call printf ("Warning: The image is undefined\n")
		#nextobject = 0
	    #} else if (im == NULL) {
		#call printf ("Warning: Cannot open image (%s)\n")
		    #call pargstr (Memc[imname])
		#nextobject = 0
	    #} else if (xp_statp (xp, OBJLIST) == NULL) {
	    if (xp_statp (xp, OBJLIST) == NULL) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else if (key == '^') {
	        object = 0
		nextobject = 0
	    } else if (key == 'f') {
		if (xp_nextobject (xp, object) == EOF) {
		    call printf (
			"Warning: The objects list is at EOF\n")
		    nextobject = 0
		} else
		    nextobject = object
	    } else if (key == 'b') {
		if (xp_prevobject (xp, object) == BOF) {
		    call printf (
			"Warning: The objects list is at BOF\n")
		    nextobject = 0
		 } else
		    nextobject = object
	    } else if (key == '~') {
	        nextobject = xp_fobject (xp, wx, wy, wxlist, wylist)
		if (nextobject <= 0) {
		    call printf (
		        "Warning: Marked object not in object list\n")
	        } else
		    object = nextobject
	    }
	    call gmsgi (gd, UI_OBJNO(ui), nextobject)

	    # Select the object.
	    if (nextobject > 0) {

		# Find the symbol.
		call sprintf (Memc[str], SZ_FNAME, "objlist%d")
		    call pargi (nextobject)
		symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])

		# Move the cursor.
		call gim_setraster (gd, 1)
		if (skypos == NO) {
		    wxlist = XP_OXINIT(symbol)
		    wylist = XP_OYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		} else if (IS_INDEFR(XP_OSXINIT(symbol)) ||
		    IS_INDEFR(XP_OSYINIT(symbol))) {
		    wxlist = XP_OXINIT(symbol)
		    wylist = XP_OYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		} else {
		    wxlist = XP_OSXINIT(symbol)
		    wylist = XP_OSYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		}
		call gim_setraster (gd, 0)

		# Move the marker.
		call xp_ogeometry (xp, symbol, oxver, oyver, nover, sxver,
		    syver, nsver, Memc[geomstr], SZ_LINE)
		call gmsg (gd, UI_OBJMARKER(ui), Memc[geomstr])

	    } else {
		symbol = NULL
		call gmsg (gd, UI_OBJMARKER(ui), "INDEF")
	    }

	# Mark the objects on the image display.
	case 'm':
	    if (xp_statp (xp, OBJLIST) == NULL) {
		call printf ("Warning: The object list is empty\n")
	    } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		call printf ("Warning: The object list is empty\n")
	    } else
		call xp_mkobjects (gd, xp, 1, 1)

	# Erase all graphics on the image display.
	case 'e':
	    call xp_eobjects (gd, 1)

	# Create the object list automatically.
	case '@':
	    object = 0; nextobject = 0
	    if (UI_SHOWOBJLIST(ui) == YES)
		call xp_mkslist (gd, ui, xp)
	    call gmsgi (gd, UI_OBJNO(ui), 0)
	    call gmsg (gd, UI_OBJMARKER(ui), "INDEF")

	# Add objects to the objects list interactively.
	case 'a':
	    if (xp_statp (xp, OBJLIST) == NULL) {
		object = 0
		nextobject = 0
	    }
	    call xp_aobjects (gd, xp, 1, 1)
	    if (UI_SHOWOBJLIST(ui) == YES)
		call xp_mkslist (gd, ui, xp)
	    call gmsgi (gd, UI_OBJNO(ui), object)

	# Delete an object from the object list.
	case 'd', 'u':

	    # Find the object.
	    if (xp_statp (xp, OBJLIST) == NULL) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else if (stnsymbols (xp_statp(xp, OBJLIST), 0) <= 0) {
		call printf ("Warning: The object list is empty\n")
		nextobject = 0
	    } else {
		nextobject = xp_nobject (xp, wx, wy, wxlist, wylist)
		if (nextobject <= 0)
		    call printf ("Warning: Marked object not in object list\n")
		else
		    object = nextobject
	    }

	    # Delete or undelete the object.
	    if (nextobject > 0) {

		# Find the symbol.
		call sprintf (Memc[str], SZ_FNAME, "objlist%d")
		    call pargi (nextobject)
		symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])

		# Delete or undelete the symbol.
		if (key == 'd')
		    call xp_dsymbol (gd, xp, 1, 1, symbol)
		else
		    call xp_udsymbol (gd, xp, 1, 1, symbol)
		if (UI_SHOWOBJLIST(ui) == YES)
		    call xp_mkslist (gd, ui, xp)
	        call gmsgi (gd, UI_OBJNO(ui), nextobject)

		# Move the cursor.
		call gim_setraster (gd, 1)
		if (skypos == NO) {
		    wxlist = XP_OXINIT(symbol)
		    wylist = XP_OYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		} else if (IS_INDEFR(XP_OSXINIT(symbol)) ||
		    IS_INDEFR(XP_OSYINIT(symbol))) {
		    wxlist = XP_OXINIT(symbol)
		    wylist = XP_OYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		} else {
		    wxlist = XP_OSXINIT(symbol)
		    wylist = XP_OSYINIT(symbol)
		    call gscur (gd, wxlist, wylist)
		}
		call gim_setraster (gd, 0)

		# Get the geometry and move the marker.
		call xp_ogeometry (xp, symbol, oxver, oyver, nover, sxver,
		    syver, nsver, Memc[geomstr], SZ_LINE)
		call gmsg (gd, UI_OBJMARKER(ui), Memc[geomstr])

	    } else {
		symbol = NULL
		#call gmsg (gd, UI_OBJMARKER(ui), "INDEF")
	    }

	# Delete all objects from the object list.
	case 'z':
	    object = 0
	    nextobject = 0
	    call xp_zobjects (xp)
	    call gmsgi (gd, UI_OBJNO(ui), 0)
	    call gmsg (gd, UI_OBJMARKER(ui), "INDEF")
	    if (UI_SHOWOBJLIST(ui) == YES)
		call xp_mkslist (gd, ui, xp)

	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}
	OBJNO(xp_statp(xp,PSTATUS)) = object

	call sfree (sp)

	return (symbol)
end
