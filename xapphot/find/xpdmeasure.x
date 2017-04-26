include "../lib/xphot.h"
include "../lib/objects.h"

# XP_DMEAS -- Procedure to execute the basic object list manipulation
# commands.

pointer procedure xp_dmeas (gd, xp, im, ol, rl, key, wx, wy, skypos)

pointer	gd			# pointer to the graphics stream
pointer	xp			# pointer to the aperture photometry descriptor
pointer	im			# the image descriptor
int	ol			# the input object list descriptor
int	rl			# the results list descriptor
int	key			# the cursor keystroke
real	wx, wy			# the cursor coordinates
int	skypos			# sky positions ?

int	nobjs, object, nextobject
pointer	sp, imname, olname, rlname, str, symbol
real	wxlist, wylist
int	xp_robjects(), stnsymbols(), xp_nextobject()
int	xp_prevobject(), xp_fobject(), xp_udobject(), xp_dobject()
int	xp_sfind()
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
	object = OBJNO(xp_statp(xp,PSTATUS))

	# Generate the objects list.
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

	symbol = NULL
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
	    }

	# Display the objects list.
	case 'l':
	    if (xp_statp(xp,OBJLIST) != NULL) {
		if (stnsymbols (xp_statp(xp,OBJLIST), 0) > 0)
	    	    call xp_pobjlist (gd, xp)
		else
		    call printf ("The object list is empty\n")
	    } else
		call printf ("The objects list is undefined\n")

	# Write out the objects list to a file.
	#case 'w':
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
	case '^', 'f', 'b', '~', 'd', 'u':
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
	    } else if (key == 'd') {
	        nextobject = xp_dobject (gd, xp, 1, 1, wx, wy)
		if (nextobject <= 0) {
		    call printf (
		        "Warning: Marked object not in object list\n")
	        } else
		    object = nextobject
	    } else if (key == 'u') {
	        nextobject = xp_udobject (gd, xp, 1, 1, wx, wy)
		if (nextobject <= 0) {
		    call printf (
		        "Warning: Marked object not in object list\n")
	        } else
		    object = nextobject
	    }

	    if (nextobject > 0) {

		# Find the symbol.
		call sprintf (Memc[str], SZ_FNAME, "objlist%d")
		    call pargi (nextobject)
		symbol = stfind (xp_statp(xp, OBJLIST), Memc[str])

		# Move the cursor.
		call gim_setraster (gd, 1)
		if (skypos == NO)
		    call gscur (gd, XP_OXINIT(symbol), XP_OYINIT(symbol))
		else if (IS_INDEFR(XP_OSXINIT(symbol)) ||
		    IS_INDEFR(XP_OSYINIT(symbol)))
		    call gscur (gd, XP_OXINIT(symbol), XP_OYINIT(symbol))
		else
		    call gscur (gd, XP_OSXINIT(symbol), XP_OSYINIT(symbol))
		call gim_setraster (gd, 0)

		# Clear status line
		call printf ("\n")

	    } else
		symbol = NULL

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

	# Add objects to the objects list interactively.
	case 'a':
	    if (xp_statp (xp, OBJLIST) == NULL) {
	        object = 0
		nextobject = 0
	    }
	    call xp_aobjects (gd, xp, 1, 1)

	# Delete all objects from the object list.
	case 'z':
	    object = 0
	    nextobject = 0
	    call xp_zobjects (xp)
	    #call xp_eobjects (gd, 1)

	default:
	    call printf ("Ambiguous or undefined keystroke command\n")
	}
	OBJNO(xp_statp(xp,PSTATUS)) = object

	call sfree (sp)

	return (symbol)
end
