include <fset.h>
include "../lib/xphot.h"

# XP_XCOLON -- Process the file management colon commands.

int procedure xp_xcolon (gd, xp, dirlist, imlist, im, objlist, ol, oextn,
	reslist, rl, rextn, greslist, gl, gextn, cmdstr)

pointer	gd			#I pointer to the graphics stream
pointer	xp			#I pointer to the main xphot structure
int	dirlist			#U the current directory listing
int	imlist			#U the image list descriptor
pointer	im			#U pointer to the input image
int	objlist			#U the object file list descriptor
int	ol			#U the object file descriptor
char	oextn[ARB]		#I the default object file extension
int	reslist			#U the results file list descriptor
int	rl			#U the results file descriptor
char	rextn[ARB]		#I the default results file extension
int	greslist		#U the geometry results file list descriptor
int	gl			#U the geometry results file descriptor
char	gextn[ARB]		#I the default geometry results file extension
char	cmdstr[ARB]		#I the input command string

bool	bval
int	ip, ncmd, update, imno, olno, rlno, glno
pointer	sp, oldpathname, pathname, keyword, cmd, str, tstr, pstatus
bool	streq(), itob()
int	strdic(), nscan(), imtrgetim(), imtlen(), fntrfnb(), fntlenb(), open()
int	xp_dirlist(), xp_stati(), strmatch(), btoi(), ctowrd()
pointer	xp_statp()
errchk	fchdir(), open()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (pathname, SZ_PATHNAME, TY_CHAR)
	call salloc (oldpathname, SZ_PATHNAME, TY_CHAR)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (tstr, SZ_LINE, TY_CHAR)

	# Get the command.
	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp, PSTATUS)

	# Process the command.
	update = NO
	ncmd = strdic (Memc[cmd], Memc[keyword], SZ_FNAME, FCMDS)

	switch (ncmd) {

	# Show the starting directory
	case FCMD_STARTDIR:
	    call gargwrd (Memc[pathname], SZ_LINE)
	    call xp_stats (xp, STARTDIR, Memc[oldpathname], SZ_FNAME)
	    call printf ("%s: %s\n")
	        call pargstr (Memc[keyword])
	        call pargstr (Memc[oldpathname])

	# Show or change the current directory.
	case FCMD_CHDIR:
	    call gargwrd (Memc[pathname], SZ_LINE)
	    call xp_stats (xp, CURDIR, Memc[oldpathname], SZ_FNAME)

	    if (Memc[pathname] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[oldpathname])

	    } else if (Memc[oldpathname] != EOS && streq (Memc[pathname],
	        Memc[oldpathname])) {
		;

	    } else {

		# Close all open input and output images and files.
		# Temporarily set all the input and output file lists
		# to empty lists.
		call xp_fclear (xp, imlist, im, objlist, ol, oextn, reslist,
		    rl, rextn, greslist, gl, gextn)
		NEWIMAGE(pstatus) = YES; NEWLIST(pstatus) = YES
		NEWRESULTS(pstatus) = YES

		# Change the current directory and update the directory
		# listing.
	        iferr (call fchdir (Memc[pathname])) {
		    call printf ("Cannot change directory to %s\n")
		        call pargstr (Memc[pathname])
	        } else {

		    # Update the current directory listing.
		    if (dirlist != NULL)
		        call fntclsb (dirlist)
		    dirlist = xp_dirlist ("..,*")
		    call fpathname ("", Memc[pathname], SZ_PATHNAME)
		    call xp_sets (xp, CURDIR, Memc[pathname])
	        }

		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		update = YES
	    }

	# Update the image and file lists using a new directory or
	# a current directory.
	case FCMD_SETDIR:

	    # Expand the image template
	    call xp_stats (xp, IMTEMPLATE, Memc[str], SZ_FNAME)
	    call xp_gimtemp (xp, Memc[str], imlist, im)
	    NEWIMAGE(pstatus) = YES

	    # Expand the input object list template.
	    call xp_stats (xp, OFTEMPLATE, Memc[str], SZ_FNAME)
	    call xp_goltemp (xp, Memc[str], imlist, objlist, ol, oextn)
	    NEWLIST(pstatus) = YES

	    # Expand the output files templates.
	    call xp_stats (xp, RFTEMPLATE, Memc[str], SZ_FNAME)
	    call xp_grltemp (xp, Memc[str], imlist, reslist, rl, rextn)
	    call xp_stats (xp, GFTEMPLATE, Memc[str], SZ_FNAME)
	    call xp_ggltemp (xp, Memc[str], imlist, greslist, gl, gextn)
	    NEWRESULTS(pstatus) = YES

	    # Update the analysis status
	    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
	    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
	    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
	    update = YES

	# List or change the image name template. This involves selecting
	# a new coordinate file for the already open list and a new output
	# file.

	case FCMD_IMTEMPLATE:

	    call gargstr (Memc[cmd], SZ_LINE)
	    call xp_stats (xp, IMTEMPLATE, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		if (ctowrd (Memc[cmd], ip, Memc[tstr], SZ_FNAME) <= 0)
		    Memc[tstr] = EOS
	        if (! streq (Memc[str], Memc[tstr])) {

		    # Expand the new image template
		    call xp_gimtemp (xp, Memc[tstr], imlist, im)
		    NEWIMAGE(pstatus) = YES

		    # Expand the input object list template.
		    call xp_stats (xp, OFTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_goltemp (xp, Memc[str], imlist, objlist, ol, oextn)
		    NEWLIST(pstatus) = YES

		    # Expand the output files templates.
		    call xp_stats (xp, RFTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_grltemp (xp, Memc[str], imlist, reslist, rl, rextn)
		    call xp_stats (xp, GFTEMPLATE, Memc[str], SZ_FNAME)
		    call xp_ggltemp (xp, Memc[str], imlist, greslist, gl, gextn)
		    NEWRESULTS(pstatus) = YES

		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    update =YES
		}
	    }

	# Show the current image or select a new image from the existing
	# image list by name. Automatically select the coordinate list
	# and output file as well.

	case FCMD_IMAGE:

	    call gargwrd (Memc[cmd+1], SZ_LINE)
	    call xp_stats (xp, IMAGE, Memc[str], SZ_FNAME)

	    if (Memc[cmd+1] == EOS) {

		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])

	    } else if (streq (Memc[cmd+1], Memc[str])) {
		;

	    } else {

		Memc[cmd] = '^'
		Memc[tstr] = EOS
		do imno = 1, imtlen (imlist) {
		    if (imtrgetim (imlist, imno, Memc[tstr], SZ_FNAME) == EOF)
			break
		    if (strmatch (Memc[tstr], Memc[cmd]) != 0)
			break
		}

		if (strmatch (Memc[tstr], Memc[cmd]) != 0) {

		    call xp_gnewim (xp, Memc[tstr], im, imno, objlist, ol,
		        oextn, reslist, rl, rextn, greslist, gl, gextn)

		    NEWIMAGE(pstatus) = YES
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    update = YES
		}
	    }

	# Show the current image or select a new image from the existing
	# image list by number. Automatically select the coordinate list
	# and output file as well.

	case FCMD_IMNUMBER:

	    call gargi (imno)
	    call xp_stats (xp, IMAGE, Memc[str], SZ_FNAME)

	    if (nscan() == 1) {

		call printf ("%s: %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, IMNUMBER))

	    } else if (imno <= 0 || imno == xp_stati (xp, IMNUMBER)) {
		;

	    } else if ((imno <= imtlen (imlist)) && (imtrgetim (imlist, imno,
	        Memc[tstr], SZ_FNAME) != EOF)) {

		call xp_gnewim (xp, Memc[tstr], im, imno, objlist, ol, oextn,
		    reslist, rl, rextn, greslist, gl, gextn)

		NEWIMAGE(pstatus) = YES
		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		update =YES
	    }

	# Show the existing coordinate file template or specify a new one.
	# Attempt to move the coordinate list corresponding to the current
	# image.

	case FCMD_OFTEMPLATE:

	    call gargstr (Memc[cmd], SZ_LINE)
	    call xp_stats (xp, OFTEMPLATE, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		if (ctowrd (Memc[cmd], ip, Memc[tstr], SZ_FNAME) <= 0)
		    Memc[tstr] = EOS
	        if (! streq (Memc[str], Memc[tstr])) {
		    call xp_goltemp (xp, Memc[tstr], imlist, objlist, ol, oextn)
		    NEWLIST(pstatus) = YES
		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    update =YES
	        }
	    }

	# Show the current coordinate file or select a new one from the
	# current list by name. 

	case FCMD_OBJECTS:

	    call gargwrd (Memc[cmd+1], SZ_LINE)
	    call xp_stats (xp, OBJECTS, Memc[str], SZ_FNAME)

	    if (Memc[cmd+1] == EOS) {

		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])

	    } else if (streq (Memc[cmd+1], Memc[str])) {
		;

	    } else {

		Memc[cmd] = '^'
		Memc[tstr] = EOS
		do olno = 1, fntlenb (objlist) {
		    if (fntrfnb (objlist, olno, Memc[tstr], SZ_FNAME) == EOF)
			break
		    if (strmatch (Memc[tstr], Memc[cmd]) != 0)
			break
		}

		if (strmatch (Memc[tstr], Memc[cmd]) != 0) {

		    if (ol != NULL) {
		        call close (ol)
		        ol = NULL
		    }
		    iferr (ol = open (Memc[tstr], READ_ONLY, TEXT_FILE)) {
			ol = NULL
			Memc[tstr] = EOS
		    }
		    call xp_sets (xp, OBJECTS, Memc[tstr])
		    call xp_seti (xp, OFNUMBER, olno)
		    call xp_clsobjects (xp)
		    NEWLIST(pstatus) = YES

		    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		    update = YES
		}
	    }

	# Show the current coordinate file or select a new one from the
	# current list by number. 

	case FCMD_OFNUMBER:

	    call gargi (olno)
	    call xp_stats (xp, OBJECTS, Memc[str], SZ_FNAME)

	    if (nscan() == 1) {

		call printf ("%s: %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, OFNUMBER))

	    } else if (olno <= 0) {
		;

	    } else if ((olno <= fntlenb (objlist)) && (fntrfnb (objlist, olno,
	        Memc[tstr], SZ_FNAME) != EOF)) {

		if (ol != NULL) {
		    call close (ol)
		    ol = NULL
		}
		iferr (ol = open (Memc[tstr], READ_ONLY, TEXT_FILE)) {
		    ol = NULL
		    Memc[tstr] = EOS
		}
		call xp_sets (xp, OBJECTS, Memc[tstr])
		call xp_seti (xp, OFNUMBER, olno)
		call xp_clsobjects (xp)
		NEWLIST(pstatus) = YES

		NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
		NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		update =YES
	    }

	# Show the current results file template or specify a new one.

	case FCMD_RFTEMPLATE:

	    call gargstr (Memc[cmd], SZ_LINE)
	    call xp_stats (xp, RFTEMPLATE, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		if (ctowrd (Memc[cmd], ip, Memc[tstr], SZ_FNAME) <= 0)
		    Memc[tstr] = EOS
	        if (! streq (Memc[str], Memc[tstr])) {
		    # Close the old results file list and results file. Delete
		    # the results file if it is empty.
		    call xp_grltemp (xp, Memc[tstr], imlist, reslist, rl, rextn)
		    NEWRESULTS(pstatus) = YES
		    update =YES
		}
	    }

	# Show the current results file name. Do not permit the user to select a
	# results file by name from the current list.

	case FCMD_RESULTS:
	    call gargwrd (Memc[cmd+1], SZ_LINE)
	    call xp_stats (xp, RESULTS, Memc[str], SZ_FNAME)
	    if (Memc[cmd+1] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    }

	# Show the current results file by number. This number should always
	# be the same as the image number. Do not permit the user to select
	# a results file by number.

	case FCMD_RFNUMBER:
	    call gargi (rlno)
	    call xp_stats (xp, RESULTS, Memc[str], SZ_FNAME)
	    if (nscan() == 1 || rlno <= 0) {
		call printf ("%s: %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, RFNUMBER))
	    }

	# Show the geometry file template or select a new one. The output
	# geometry file is not currently written to although it is opened.

	case FCMD_GFTEMPLATE:

	    call gargstr (Memc[cmd], SZ_LINE)
	    call xp_stats (xp, GFTEMPLATE, Memc[str], SZ_FNAME)
	    if (Memc[cmd] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    } else {
		ip = 1
		if (ctowrd (Memc[cmd], ip, Memc[tstr], SZ_FNAME) <= 0)
		    Memc[tstr] = EOS
	        if (! streq (Memc[str], Memc[tstr])) {
		    # Close up the old output geometry file list and geometry
		    # file. Delete the geometry file if it is empty.
		    call xp_ggltemp (xp, Memc[tstr], imlist, greslist, gl,
		        gextn)
		    NEWRESULTS(pstatus) = YES
		    update =YES
	        }
	    }

	# Show the current geometry results file by name. Do not permit
	# the user to select a results file by name from the current list.

	case FCMD_GRESULTS:

	    call gargwrd (Memc[cmd+1], SZ_LINE)
	    call xp_stats (xp, GRESULTS, Memc[str], SZ_FNAME)
	    if (Memc[cmd+1] == EOS) {
		call printf ("%s: %s\n")
		    call pargstr (Memc[keyword])
		    call pargstr (Memc[str])
	    }

	# Show the current geometry results file by number. This number should
	# always be the same as the image number. Do not permit the user to
	# select a geometry results file by number.

	case FCMD_GFNUMBER:
	    call gargi (glno)
	    call xp_stats (xp, GRESULTS, Memc[str], SZ_FNAME)
	    if (nscan() == 1 || glno <= 0) {
		call printf ("%s: %d\n")
		    call pargstr (Memc[keyword])
		    call pargi (xp_stati (xp, GFNUMBER))
	    }

	# Log  the results to the output file?

	case FCMD_LOGRESULTS:
	    call gargb (bval)
	    if (nscan() == 1) {
		call printf ("%s = %b\n")
		    call pargstr (Memc[keyword])
		    call pargb (itob(LOGRESULTS(pstatus)))
	    } else {
		LOGRESULTS(pstatus) = btoi (bval)
		update = YES
	    }

	default:
	    call printf ("Unknown or ambiguous colon command\7\n")
	}

	call sfree (sp)

	return (update)
end


# XP_GIMTEMP -- Given a new image template generate a new image list and
# current image.

procedure xp_gimtemp (xp, template, imlist, im)

pointer	xp			#I pointer to the xapphot structure
char	template[ARB]		#I the new image template
int	imlist			#U the image list descriptor
pointer	im			#U the current image descriptor

pointer	sp, tstr
int	xp_imlist(), imtlen(), imtgetim()
pointer	immap()
errchk	immap()

begin
	call smark (sp)
	call salloc (tstr, SZ_FNAME, TY_CHAR)

	if (imlist != NULL) {
	    if (im != NULL)
	        call imunmap (im)
	    im = NULL
	    call imtclose (imlist)
	    imlist = NULL
	}

	# Open a new image list and image.
	imlist = xp_imlist (template)
	if (imtgetim (imlist, Memc[tstr], SZ_FNAME) == EOF)
	    Memc[tstr] = EOS
	if (Memc[tstr] == EOS || imtlen (imlist) <= 0) {
	    im = NULL
	    call xp_sets (xp, IMAGE, "")
	    call xp_seti (xp, IMNUMBER, 0)
	} else {
	    iferr (im = immap (Memc[tstr], READ_ONLY, 0))
	        im = NULL
	    call xp_sets (xp, IMAGE, Memc[tstr])
	    call xp_seti (xp, IMNUMBER, 1)
	}
	#call xp_keyset (im, xp)
	call xp_sets (xp, IMTEMPLATE, template)

	call sfree (sp)
end


# XP_GOLTEMP -- Given a new input object list template and the current image
# list, generate a new input objects file list and current input objects file.

procedure xp_goltemp (xp, template, imlist, objlist, ol, oextn)

pointer	xp			#I pointer to the xapphot structure
char	template[ARB]		#I the new image template
int	imlist			#I the image list descriptor
int	objlist			#U the input object file list descriptor
int	ol			#U the current object file descriptor
char	oextn[ARB]		#I the default input object file extension

int	olno
pointer	sp, tstr
int	xp_mkolist(), fntlenb(), fntrfnb(), open()
errchk	open()

begin
	call smark (sp)
	call salloc (tstr, SZ_FNAME, TY_CHAR)

	# Close any open coordinates file.
	if (objlist != NULL) {
	    if (ol != NULL) {
	        call close (ol)
	        ol = NULL
	    }
	    call fntclsb (objlist)
	    objlist = NULL
	}

	# Reopen the coordinates file template.
	objlist = xp_mkolist (imlist, template, "default", oextn)
	if (fntlenb (objlist) <= 0) {
	    Memc[tstr] = EOS
	    ol = NULL
	    olno = 0
	} else if (fntrfnb (objlist, 1, Memc[tstr], SZ_FNAME) != EOF) {
	    iferr (ol = open (Memc[tstr], READ_ONLY, TEXT_FILE)) {
		ol = NULL
		Memc[tstr] = EOS
	    }
	    olno = 1
	} else {
	    Memc[tstr] = EOS
	    ol = NULL
	    olno = 0
	}
	call xp_sets (xp, OFTEMPLATE, template)
	call xp_sets (xp, OBJECTS, Memc[tstr])
	call xp_seti (xp, OFNUMBER, olno)
	call xp_clsobjects (xp)

	call sfree (sp)
end


# XP_GRLTEMP -- Given a new output results list template and the current image
# list, generate a new output results file list and current results file.

procedure xp_grltemp (xp, template, imlist, reslist, rl, rextn)

pointer	xp			#I pointer to the xapphot structure
char	template[ARB]		#I the new image template
int	imlist			#I the image list descriptor
int	reslist			#U the output results file list descriptor
int	rl			#U the current results file
char	rextn[ARB]		#I the default output results file extension

int	rlno
pointer	sp, str
int	fstati(), xp_mkrlist(), fntlenb(), fntrfnb(), open()
pointer	xp_statp()
errchk	open()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	if (reslist != NULL) {
	    if (rl != NULL) {
	        call flush (rl)
	        if (fstati(rl, F_FILESIZE) == 0 ||
	            SEQNO(xp_statp(xp,PSTATUS)) == 0) {
		    call fstats (rl, F_FILENAME, Memc[str], SZ_FNAME)
		    call close (rl)
		    call delete (Memc[str])
	        } else
		    call close (rl)
	        rl = NULL
	    }
	    call fntclsb (reslist)
	    reslist = NULL
	}

	reslist = xp_mkrlist (imlist, template, "default", rextn, NO)
	call xp_cseqlist (xp)
	call xp_oseqlist (xp)
	if (fntlenb (reslist) <= 0) {
	    Memc[str] = EOS
	    rl = NULL
	    rlno = 0
	} else if (fntrfnb (reslist, 1, Memc[str], SZ_FNAME) != EOF) {
	    iferr (rl = open (Memc[str], NEW_FILE, TEXT_FILE)) {
	        rl = NULL
		Memc[str] = EOS
	    }
	    rlno = 1
	} else {
	    Memc[str] = EOS
	    rl = NULL
	    rlno = 0
	}
	SEQNO(xp_statp(xp,PSTATUS)) = 0
	call xp_sets (xp, RFTEMPLATE, template)
	call xp_sets (xp, RESULTS, Memc[str])
	call xp_seti (xp, RFNUMBER, rlno)

	call sfree (sp)
end


# XP_GGLTEMP -- Given a new output objects file list template and the current
# image list, generate a new output objects file list and current output
# objects file.

procedure xp_ggltemp (xp, template, imlist, greslist, gl, gextn)

pointer	xp			#I pointer to the xapphot structure
char	template[ARB]		#I the new image template
int	imlist			#I the image list descriptor
int	greslist		#U the output objects file list descriptor
int	gl			#U the current output objects file
char	gextn[ARB]		#I the default output objects file extension

int	glno
pointer	sp, str
int	fstati(), xp_mkrlist(), fntlenb(), fntrfnb(), open()
pointer	xp_statp()
errchk	open()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	if (greslist != NULL) {
	    if (gl != NULL) {
	        call flush (gl)
	        if (fstati(gl, F_FILESIZE) == 0 ||
	            SEQNO(xp_statp(xp,PSTATUS)) == 0) {
		    call fstats (gl, F_FILENAME, Memc[str], SZ_FNAME)
		    call close (gl)
		    call delete (Memc[str])
	        } else
		    call close (gl)
	        gl = NULL
	    }
	    call fntclsb (greslist)
	    greslist = NULL
	}

	greslist = xp_mkrlist (imlist, template, "default", gextn, NO)
	if (fntlenb (greslist) <= 0) {
	    Memc[str] = EOS
	    gl = NULL
	    glno = 0
	} else if (fntrfnb (greslist, 1, Memc[str], SZ_FNAME) != EOF) {
	    iferr (gl = open (Memc[str], NEW_FILE, TEXT_FILE)) {
	        gl = NULL
		Memc[str] = EOS
	    }
	    glno = 1
	} else {
	    Memc[str] = EOS
	    gl = NULL
	    glno = 0
	}
	call xp_sets (xp, GFTEMPLATE, template)
	call xp_sets (xp, GRESULTS, Memc[str])
	call xp_seti (xp, GFNUMBER, glno)

	call sfree (sp)
end


# XP_GNEWIM -- Open a new image and its associated files.

procedure xp_gnewim (xp, image, im, imno, objlist, ol, oextn, reslist, rl,
	rextn, greslist, gl, gextn)

pointer	xp			#I pointer to the xapphot structure
char	image[ARB]		#I the new image name
int	im			#U the image descriptor
int	imno			#I the input image number
int	objlist			#I the input object file list descriptor
int	ol			#U the current object file descriptor
char	oextn[ARB]		#I the default input object file extension
int	reslist			#I the output results file list descriptor
int	rl			#U the current results file
char	rextn[ARB]		#I the default output results file extension
int	greslist		#I the output objects file list descriptor
int	gl			#U the current output objects file
char	gextn[ARB]		#I the default output objects file extension

int	olno, rlno, glno
pointer	sp, str, tstr, lsymbol
bool	streq()
int	fntrfnb(), open(), fntlenb(), xp_stati(), fstati(), access()
pointer	immap(), xp_statp(), stfind(), stenter()
errchk	immap(), open()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call salloc (tstr, SZ_FNAME, TY_CHAR)
	
	# Close existing image and open a new one,
        if (im != NULL) {
	    call imunmap (im)
	    im = NULL
	}
	iferr {
	    im = immap (image, READ_ONLY, 0)
	} then {
	    im = NULL
	}
	#call xp_keyset (xp, im)
	call xp_sets (xp, IMAGE, Memc[tstr])
	call xp_seti (xp, IMNUMBER, imno)

        # Close up the objects file and select a new one.
	call xp_stats (xp, OBJECTS, Memc[str], SZ_FNAME)
	if (ol != NULL) {
	    call close (ol)
	    ol = NULL
	}
        Memc[tstr] = EOS
	if (fntrfnb (objlist, imno, Memc[tstr], SZ_FNAME) != EOF) {
	    iferr (ol = open (Memc[tstr], READ_ONLY, TEXT_FILE)) {
		ol = NULL
		Memc[tstr] = EOS
	    }
	    olno = imno
	} else if (fntrfnb (objlist, fntlenb(objlist), Memc[tstr],
	    SZ_FNAME) != EOF) {
	    iferr (ol = open (Memc[tstr], READ_ONLY, TEXT_FILE)) {
		 ol = NULL
		Memc[tstr] = EOS
	    }
	    olno = fntlenb (objlist)
	} else {
	    ol = NULL
	    Memc[tstr] = EOS
	    olno = 0
	}
	if (! streq (Memc[tstr], Memc[str]) || olno != xp_stati (xp,
	    OFNUMBER)) {
	    call xp_sets (xp, OBJECTS, Memc[tstr])
	    call xp_seti (xp, OFNUMBER, olno)
	    call xp_clsobjects (xp)
	    NEWLIST(xp_statp(xp,PSTATUS)) = YES
	}

	# Close up the results files and select new ones.
	if (rl != NULL) {
	    call flush (rl)
	    if (fstati (rl, F_FILESIZE) == 0 || SEQNO(xp_statp(xp,
	        PSTATUS)) == 0) {
		call fstats (rl, F_FILENAME, Memc[str], SZ_FNAME)
		call close (rl)
		call delete (Memc[str])
	    } else {
		call xp_stats (xp, RESULTS, Memc[str], SZ_FNAME)
		call close (rl)
		lsymbol = stfind (xp_statp(xp,SEQNOLIST), Memc[str])
		if (lsymbol != NULL)
		    XP_MAXSEQNO(lsymbol) = SEQNO(xp_statp(xp,PSTATUS))
		else {
		    lsymbol = stenter (xp_statp(xp,SEQNOLIST),
		        Memc[str], LEN_SEQNOLIST_STRUCT)
		    XP_MAXSEQNO(lsymbol) = SEQNO(xp_statp(xp,PSTATUS))
		}
	    }
	    rl = NULL
	}
	Memc[tstr] = EOS
	if (fntrfnb (reslist, imno, Memc[tstr], SZ_FNAME) != EOF) {
	    if (access (Memc[tstr], 0, 0) == YES) {
		iferr (rl = open (Memc[tstr], APPEND, TEXT_FILE))
		    rl = NULL
		lsymbol = stfind (xp_statp(xp,SEQNOLIST), Memc[tstr])
		if (lsymbol == NULL)
		    SEQNO(xp_statp(xp,PSTATUS)) = 0
		else
		    SEQNO(xp_statp(xp,PSTATUS)) = XP_MAXSEQNO(lsymbol)
	    } else {
	        iferr (rl = open (Memc[tstr], NEW_FILE, TEXT_FILE))
	            rl = NULL
		SEQNO(xp_statp(xp,PSTATUS)) = 0
	    }
	    rlno = imno
	} else if (fntrfnb (reslist, fntlenb(reslist), Memc[tstr],
	    SZ_FNAME) != EOF) {
	    if (access (Memc[tstr], 0, 0) == YES) {
	        iferr (rl = open (Memc[tstr], APPEND, TEXT_FILE))
	            rl = NULL
		lsymbol = stfind (xp_statp(xp,SEQNOLIST), Memc[tstr])
		if (lsymbol == NULL)
		    SEQNO(xp_statp(xp,PSTATUS)) = 0
		else
		    SEQNO(xp_statp(xp,PSTATUS)) = XP_MAXSEQNO(lsymbol)
	    } else {
		iferr (rl = open (Memc[tstr], NEW_FILE, TEXT_FILE))
		    rl = NULL
		SEQNO(xp_statp(xp,PSTATUS)) = 0
	    }
	    rlno = fntlenb (reslist)
	} else {
	    rl = NULL
	    Memc[tstr] = EOS
	    rlno = 0
	}
	if (! streq (Memc[tstr], Memc[str]) || rlno != xp_stati (xp,
	    RFNUMBER)) {
	    call xp_sets (xp, RESULTS, Memc[tstr])
	    call xp_seti (xp, RFNUMBER, rlno)
	    NEWRESULTS(xp_statp(xp,PSTATUS)) = YES
	}

	if (gl != NULL) {
	    call flush (gl)
	    if (fstati (gl, F_FILESIZE) == 0 || SEQNO(xp_statp(xp,
	        PSTATUS)) == 0) {
		    call fstats (gl, F_FILENAME, Memc[str], SZ_FNAME)
		    call close (gl)
		    call delete (Memc[str])
	    } else
	        call close (gl)
	    gl = NULL
	}
	Memc[tstr] = EOS
	if (fntrfnb (greslist, imno, Memc[tstr], SZ_FNAME) != EOF) {
	    if (access (Memc[tstr], 0, 0) == YES) {
		iferr (gl = open (Memc[tstr], APPEND, TEXT_FILE))
		    gl = NULL
	    } else {
		iferr (gl = open (Memc[tstr], NEW_FILE, TEXT_FILE))
		    gl = NULL
	    }
	    glno = imno
	} else if (fntrfnb (greslist, fntlenb(greslist), Memc[tstr],
	    SZ_FNAME) != EOF) {
	    if (access (Memc[tstr], 0, 0) == YES) {
	        iferr (gl = open (Memc[tstr], APPEND, TEXT_FILE))
	            gl = NULL
	    } else {
		iferr (gl = open (Memc[tstr], NEW_FILE, TEXT_FILE))
		    gl = NULL
	    }
	    glno = fntlenb (greslist)
	} else {
	    gl = NULL
	    Memc[tstr] = EOS
	    glno = 0
	}
	if (! streq (Memc[tstr], Memc[str]) || glno != xp_stati (xp,
	    GFNUMBER)) {
	    call xp_sets (xp, GRESULTS, Memc[tstr])
	    call xp_seti (xp, GFNUMBER, glno)
	    NEWRESULTS(xp_statp(xp,PSTATUS)) = YES
	}

	call sfree (sp)
end


# XP_FCLEAR -- Close all input and output files and input and output
# file template lists. Reopen the lists as null lists.

procedure xp_fclear (xp, imlist, im, objlist, ol, oextn, reslist, rl, rextn,
	greslist, gl, gextn)

pointer	xp			#I pointer to the xapphot structure
int	imlist			#U the imlist list descriptor
int	im			#U the image descriptor
int	objlist			#U the input object file list descriptor
int	ol			#U the current object file descriptor
char	oextn[ARB]		#I the input object file extension
int	reslist			#U the output results file list descriptor
int	rl			#U the current results file
char	rextn[ARB]		#I the output results file extension
int	greslist		#U the output objects file list descriptor
int	gl			#U the current output objects file
char	gextn[ARB]		#I the output objects file extension

pointer	sp, str
int	xp_imlist(), xp_mkolist(), fstati(), xp_mkrlist()
pointer	xp_statp()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Close the existing image and image list.
	if (imlist != NULL) {
            if (im != NULL) {
	        call imunmap (im)
	        im = NULL
	    }
	    call imtclose (imlist)
	    imlist = NULL
	}
	call xp_sets (xp, IMAGE, "")
	call xp_seti (xp, IMNUMBER, 0)

	# Open a NULL image list.
	imlist = xp_imlist ("")

	# Close the existing input objects file nad input objects file list.
	if (objlist != NULL) {
            if (ol != NULL) {
	        call close (ol)
	        ol = NULL
	    }
	    call fntclsb (objlist)
	    objlist = NULL
	}
	call xp_clsobjects (xp)
	call xp_sets (xp, OBJECTS, "")
	call xp_seti (xp, OFNUMBER, 0)

	# Reopen the coordinates file template.
	objlist = xp_mkolist (imlist, "", "default", oextn)

	# Close the existing output results file and results file list.
	if (reslist != NULL) {
	    if (rl != NULL) {
	        call flush (rl)
	        if (fstati (rl, F_FILESIZE) == 0 || SEQNO(xp_statp(xp,
	            PSTATUS)) == 0) {
		    call fstats (rl, F_FILENAME, Memc[str], SZ_FNAME)
		    call close (rl)
		    call delete (Memc[str])
	        } else
		    call close (rl)
	        rl = NULL
	    }
	    call fntclsb (reslist)
	    reslist = NULL
	}
	call xp_sets (xp, RESULTS, "")
	call xp_seti (xp, RFNUMBER, 0)

	# Open a new results list.
	reslist = xp_mkrlist (imlist, "", "default", rextn, NO)
	call xp_cseqlist (xp)
	call xp_oseqlist (xp)

	# Close the existing output objects file and output results file list.
	if (greslist != NULL) {
	    if (gl != NULL) {
	        call flush (gl)
	        if (fstati (gl, F_FILESIZE) == 0 || SEQNO(xp_statp(xp,
	            PSTATUS)) == 0) {
		    call fstats (gl, F_FILENAME, Memc[str], SZ_FNAME)
		    call close (gl)
		    call delete (Memc[str])
	        } else
		    call close (gl)
	        gl = NULL
	    }
	    call fntclsb (greslist)
	    greslist = NULL
	}
	call xp_sets (xp, GRESULTS, "")
	call xp_seti (xp, GFNUMBER, 0)

	# Open a new output objects file list.
	greslist = xp_mkrlist (imlist, "", "default", gextn, NO)

	SEQNO(xp_statp(xp,PSTATUS)) = 0

	call sfree (sp)
end
