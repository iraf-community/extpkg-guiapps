include <fset.h>
include <imhdr.h>
include <gset.h>
include "../lib/xphot.h"
include "../lib/display.h"
include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "uipars.h"

define	IHELPFILE	"xapphot$doc/xguiphot.keys"
define	GHELPFILE	"xapphot$doc/xguiphot.html"    # default help (not used)

procedure t_xguiphot()

pointer	images			# pointer to the input image list
pointer	objects			# pointer to the input objects lists
pointer	results			# pointer to the output results lists
pointer	gresults		# pointer to the output objects lists
pointer	graphics		# the default graphics device
pointer	guifile			# the user interface file

int	dirlist, imlist, objlist, reslist, greslist, ol, rl, gl, imno, olno
int	rlno, glno, wcs, key, nver, nobjs, update, verbose, tmpobjno, iupdate
pointer	xp, im, gd, ui, lsymbol, symbol, psymbol, pstatus
pointer	sp, imname, olname, rlname, glname, cmd, str
real	owx, owy, wx, wy, rwx, rwy

bool	fp_equalr(), clgetb()
int	xp_stati(), imtrgetim(), clgcur(), xp_imlist(), imtlen(), xp_mkolist()
int	fntlenb(), fntrfnb(), access(), btoi(), xp_mkrlist(), xp_robjects()
int	xp_mkpoly(), xp_acolor(), xp_scolor(), fstati(), xp_bphot(), xp_aphot()
int	xp_fobject(), xp_pmodfit(), xp_dirlist()
pointer	xp_dmeas(), xp_udmeas(), xp_pmeas(), xp_upmeas(), xp_plmeas()
pointer	gopenui(), gopen(), immap(), open(), xp_statp(), stfind(), stenter()
pointer	xp_uplmeas(), xp_xpcolon(), xp_gxpcolon()
errchk	immap(), open()

define	noninteractive_	99

begin
	# Flush on a newline
	call fseti (STDOUT, F_FLUSHNL, YES)

	# Allocate some working memory.
	call smark (sp)
	call salloc (images, SZ_FNAME, TY_CHAR)
	call salloc (objects, SZ_FNAME, TY_CHAR)
	call salloc (results, SZ_FNAME, TY_CHAR)
	call salloc (gresults, SZ_FNAME, TY_CHAR)
	call salloc (graphics, SZ_FNAME, TY_CHAR)
	call salloc (guifile, SZ_FNAME, TY_CHAR)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call salloc (glname, SZ_FNAME, TY_CHAR)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get the task parameters.
	call clgstr ("images", Memc[images], SZ_FNAME)
	call clgstr ("objects", Memc[objects], SZ_FNAME)
	call clgstr ("results", Memc[results], SZ_FNAME)
	call clgstr ("robjects", Memc[gresults], SZ_FNAME)
	call clgstr ("graphics", Memc[graphics], SZ_FNAME)
	call clgstr ("guifile", Memc[guifile], SZ_FNAME)

	# Initialize the program structure and load the algorithm parameters
	# into memory.
	call xp_gxpars (xp)

	# Get the pointer to the status array.
	pstatus = xp_statp(xp,PSTATUS)

	# Open the graphics stream. The UI parameters are stored in string
	# variables to get around the too many strings problem in the
	# preprocessor.
	if (clgetb ("interactive")) {

	    # Open the GUI file if it exists otherwise default to the
	    # regular graphics stream.

	    if (access (Memc[guifile], READ_ONLY, TEXT_FILE) == YES) {
	        gd = gopenui (Memc[graphics], NEW_FILE, Memc[guifile],
		    STDGRAPH)
	        call xp_uiinit (ui)
	    } else {
	        gd = gopen (Memc[graphics], NEW_FILE, STDGRAPH)
		ui = NULL
	    }


	} else {
	    gd = NULL
	    ui = NULL
	}

	# Get various book-keeping parameters.
	update = btoi(clgetb("update"))
	LOGRESULTS(pstatus) = btoi(clgetb("logresults"))
	verbose = btoi(clgetb("verbose"))

        # Open the current directory list.
        dirlist = xp_dirlist ("..,*")
        call fpathname ("", Memc[cmd], SZ_LINE)
        call xp_sets (xp, STARTDIR, Memc[cmd])
        call xp_sets (xp, CURDIR, Memc[cmd])

	# Open a list of images.
	imlist = xp_imlist (Memc[images])
	call xp_sets (xp, IMTEMPLATE, Memc[images])
	imno = 1
	NEWIMAGE(pstatus) = YES

	# Open the objects lists.
	objlist = xp_mkolist (imlist, Memc[objects], "default", "obj")
	call xp_sets (xp, OFTEMPLATE, Memc[objects])
	olno = 1
	NEWLIST(pstatus) = YES

        # Open the results file list.
        reslist = xp_mkrlist (imlist, Memc[results], "default", "mag", NO)
        call xp_sets (xp, RFTEMPLATE, Memc[results])
        rlno = 1
        greslist = xp_mkrlist (imlist, Memc[gresults], "default", "geo", NO)
        call xp_sets (xp, GFTEMPLATE, Memc[gresults])
        glno = 1
	call xp_oseqlist (xp)
        NEWRESULTS(pstatus) = YES

	# Initialize the UI interaface.
	if (ui != NULL)
	    call xp_guiset (gd, ui, xp, dirlist, imlist, objlist, reslist,
	        greslist)

	# Loop over the image list.
	repeat {

	    # Get the name of and open the image. Read in the required
	    # image header keywords and pass their values to the GUI.
	    if (NEWIMAGE(pstatus) == YES) {

	        if (imtrgetim (imlist, imno, Memc[imname], SZ_FNAME) == EOF) {
		    im = NULL
		    Memc[imname] = EOS
		    call xp_seti (xp, IMNUMBER, 0)
	        } else {
		    iferr {
	    	        im = immap (Memc[imname], READ_ONLY, 0)
		    } then {
			if (gd != NULL) {
			    call gclear (gd)
			    call gflush (gd)
			}
		        im = NULL
		    } else if (gd != NULL) {
			call xp_display (gd, xp, im, 1, IM_LEN(im,1), 1,
			    IM_LEN(im,2), IMAGE_DISPLAY_WCS,
			    IMAGE_DISPLAY_WCS)
		    }
		    call xp_seti (xp, IMNUMBER, imno)
		}
		call xp_keyset (im, xp)
	        call xp_sets (xp, IMAGE, Memc[imname])

		if (ui != NULL) {
		    if (Memc[imname] == EOS)
		        call gmsgi (gd, UI_IMNO(ui), 0)
		    else
		        call gmsgi (gd, UI_IMNO(ui), imno)
		    if (im != NULL)
		        call gmsg (gd, UI_REDISPLAY(ui), "no")
		    call xp_iguipars (gd, ui, xp)
		    if (UI_SHOWHEADER(ui) == YES)
		        call xp_mkheader (gd, ui, im, YES)
		}
	    }

	    # Get the name of and open the coordinate file. Pass the file
	    # name and number to the GUI.
            if (NEWLIST(pstatus) == YES) {

                OBJNO(pstatus) = 0
		call xp_clsobjects (xp)
                if (im == NULL || fntlenb (objlist) <= 0) {
                    Memc[olname] = EOS
                    call xp_seti (xp, OFNUMBER, 0)
                } else if (NEWIMAGE(pstatus) == NO && fntrfnb (objlist, olno,
                    Memc[olname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, OFNUMBER, olno)
                } else if (fntrfnb (objlist, xp_stati(xp,IMNUMBER),
                    Memc[olname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, OFNUMBER, xp_stati (xp, IMNUMBER))
                } else if (fntrfnb (objlist, fntlenb (objlist),
                    Memc[olname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, OFNUMBER, fntlenb (objlist))
                }

                if (Memc[olname] == EOS) {
                    ol = NULL
                } else iferr {
                    ol = open (Memc[olname], READ_ONLY, TEXT_FILE)
                } then {
		    Memc[olname] = EOS
                    ol = NULL
                }
                call xp_sets (xp, OBJECTS, Memc[olname])

		if (ui != NULL) {
		    call gmsgi (gd, UI_OFNO(ui), xp_stati (xp, OFNUMBER))
		    call gmsgi (gd, UI_OBJNO(ui), 0)
		    if (UI_SHOWOBJLIST(ui) == YES) {
		        if (ol == NULL)
			    call gmsg (gd, UI_OBJLIST(ui), "{}")
		        else {
			    nobjs = xp_robjects (ol, xp, RLIST_NEW)
                            if (nobjs <= 0) {
                                call printf (
                            "Warning: The current objects file (%s) is empty\n")
                                    call pargstr (Memc[olname])
                            } else {
                                call printf (
                                "Read %d objects from current object file %s\n")
                                    call pargi (nobjs)
                                    call pargstr (Memc[olname])
                            }
		            call xp_mkslist (gd, ui, xp)
		        }
		    }
		}
	    }

            # Open the results file if any.
            if (NEWRESULTS(pstatus) == YES) {

                if (im == NULL || fntlenb (reslist) <= 0) {
                    Memc[rlname] = EOS
                    call xp_seti (xp, RFNUMBER, 0)
                } else if (NEWIMAGE(pstatus) == NO && fntrfnb (reslist, rlno,
                    Memc[rlname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, RFNUMBER, rlno)
                } else if (fntrfnb (reslist, xp_stati(xp,IMNUMBER),
                    Memc[rlname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, RFNUMBER, xp_stati (xp, IMNUMBER))
                } else if (fntrfnb (reslist, fntlenb (reslist),
                    Memc[rlname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, RFNUMBER, fntlenb (reslist))
                }
                if (Memc[rlname] == EOS) {
                    rl = NULL
                } else iferr {
		    if (access (Memc[rlname], 0, 0) == YES) {
                        rl = open (Memc[rlname], APPEND, TEXT_FILE)
                        lsymbol = stfind (xp_statp(xp, SEQNOLIST), Memc[rlname])
                        if (lsymbol == NULL)
                            SEQNO(pstatus) = 0
                        else
                            SEQNO(pstatus) = XP_MAXSEQNO(lsymbol)
		    } else {
                        rl = open (Memc[rlname], NEW_FILE, TEXT_FILE)
                        SEQNO(pstatus) = 0
		    }
                    if (SEQNO(pstatus) == 0)
                        call xp_whphot (xp, rl, "xguiphot")
                    call xp_whiminfo (xp, rl)
                    if (SEQNO(pstatus) == 0)
                        call xp_xpbnr (xp, rl)
                } then {
                    rl = NULL
		    Memc[rlname] = EOS
                }
                call xp_sets (xp, RESULTS, Memc[rlname])
		if (ui != NULL) {
		    call gmsg (gd, UI_RFFILE(ui), Memc[rlname])
		    call gmsgi (gd, UI_RFNO(ui), xp_stati(xp,RFNUMBER))
		}

                if (im == NULL || fntlenb (greslist) <= 0) {
                    Memc[glname] = EOS
                    call xp_seti (xp, GFNUMBER, 0)
                } else if (NEWIMAGE(pstatus) == NO && fntrfnb (greslist, glno,
                    Memc[glname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, GFNUMBER, glno)
                } else if (fntrfnb (greslist, xp_stati(xp,IMNUMBER),
                    Memc[glname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, GFNUMBER, xp_stati (xp, IMNUMBER))
                } else if (fntrfnb (greslist, fntlenb (greslist),
                    Memc[glname], SZ_FNAME) != EOF) {
                    call xp_seti (xp, GFNUMBER, fntlenb (greslist))
                }
                if (Memc[glname] == EOS) {
                    gl = NULL
                } else iferr {
		    if (access (Memc[glname], 0, 0) == YES)
                        gl = open (Memc[glname], APPEND, TEXT_FILE)
		    else
                        gl = open (Memc[glname], NEW_FILE, TEXT_FILE)
                } then {
                    gl = NULL
		    Memc[glname] = EOS
                }
                call xp_sets (xp, GRESULTS, Memc[glname])
		if (ui != NULL) {
		    call gmsg (gd, UI_GFFILE(ui), Memc[glname])
		    call gmsgi (gd, UI_GFNO(ui), xp_stati(xp,GFNUMBER))
		}
            }


	    if (gd == NULL)
		goto noninteractive_

	    # Initialize the analysis state.
	    NEWIMAGE(pstatus) = NO; NEWLIST(pstatus) = NO
	    NEWRESULTS(pstatus) = NO; symbol = NULL; psymbol = NULL
	    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
	    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
	    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
	    owx = INDEFR; owy = INDEFR

	    while (clgcur ("gcommands", wx, wy, wcs, key, Memc[cmd], SZ_LINE) !=
	        EOF) {

		# Has the cursor moved ?
		if (! fp_equalr (wx, owx) || ! fp_equalr (wy, owy)) {
	    	    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
	    	    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
	    	    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		}

	        switch (key) {

	        # Quit the program.
	        case 'Q':
		    imno = EOF
		    break

		# Erase the status line.
		case '\r':
		    call printf ("\n")

		# Redraw the markers if any. 
		case 'I':
		    if (ui != NULL)
		        call gmsg (gd, UI_MREDRAW(ui), "yes")

		# Display help ?
		case '?':
		    if (ui == NULL) {
			call gpagefile (gd, IHELPFILE, "")
		    } else if (UI_SHOWHELP(ui) == NO) {
			UI_SHOWHELP(ui) = YES
			call gmsg (gd, UI_HELP(ui), "yes")
		    } else {
			UI_SHOWHELP(ui) = NO
			call gmsg (gd, UI_HELP(ui), "no")
		    }

		# Display the files.
		case '$':
		    if (ui == NULL) {
			call xp_pflist (gd, xp, dirlist, imlist, objlist,
			    reslist, greslist)
		    } else if (UI_SHOWFILES(ui) == NO) {
			UI_SHOWFILES(ui) = YES
			call gmsg (gd, UI_FILES(ui), "yes")
		    } else {
			UI_SHOWFILES(ui) = NO
			call gmsg (gd, UI_FILES(ui), "no")
		    }

		# Move to next image.
		case 'n':
		    if (im == NULL) {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                            "Warning: The current image is undefined\n")
                        else
                            call printf (
                            "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
		    } else if (imno < imtlen (imlist)) {
			NEWIMAGE(pstatus) = YES
			if (olno < fntlenb (objlist))
			    NEWLIST(pstatus) = YES
			if (rlno < fntlenb (reslist))
			    NEWRESULTS(pstatus) = YES
			if (glno < fntlenb (greslist))
			    NEWRESULTS(pstatus) = YES
		        break
		    } else {
                        call printf ( "Warning: The image list is at EOF\n")
		    }

		# Move to previous image.
		case 'p':
		    if (im == NULL) {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                            "Warning: The current image is undefined\n")
                        else
                            call printf (
                            "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
		    } else if (imno > 1) {
		        imno = imno - 2
			NEWIMAGE(pstatus) = YES
			if (olno > 1) {
			    olno = olno - 2
			    NEWLIST(pstatus) = YES
			}
                        if (rlno > 1) {
                            rlno = rlno - 2
                            NEWRESULTS(pstatus) = YES
                        }
                        if (glno > 1) {
                            glno = glno - 2
                            NEWRESULTS(pstatus) = YES
                        }
		        break
		    } else {
                        call printf ( "Warning: The image list is at BOF\n")
		    }

		# Redisplay the current image.
		case 'i':
		    if (im == NULL) {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                            "Warning: The current image is undefined\n")
                        else
                            call printf (
                            "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
		    } else {
	    	        call xp_display (gd, xp, im, 1, IM_LEN(im,1), 1,
		            IM_LEN(im,2), IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS) 
			call xp_keyset (im, xp)
			if (ui != NULL)
			    call gmsg (gd, UI_REDISPLAY(ui), "no")
		    }

		# Display the image header.
		case 'h':
		    if (im == NULL) {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
		    } else if (ui == NULL) {
			call xp_pimheader (gd, im)
		    } else if (UI_SHOWHEADER(ui) == NO) {
			UI_SHOWHEADER(ui) = YES
			call gmsg (gd, UI_HEADER(ui), "yes")
	    	        call xp_mkheader (gd, ui, im, YES)
		    } else {
			UI_SHOWHEADER(ui) = NO
			call gmsg (gd, UI_HEADER(ui), "no")
		    }

		# Move to the next coordinate list.
                case ']':
                    if (olno < fntlenb (objlist)) {
                        NEWLIST(pstatus) = YES
                        break
                    }

                # Move to the previous coordinate list.
                case '[':
                    if (olno > 1) {
                        olno = olno - 2
                        NEWLIST(pstatus) = YES
                        break
                    }

		# Trace a polygonal aperture on the image display.
		case 'v':
                    nver = xp_mkpoly (gd, Memr[xp_statp(xp,PUXVER)],
		        Memr[xp_statp(xp,PUYVER)], MAX_NAP_VERTICES,
			GL_SOLID, xp_acolor(xp), 1, YES)
		    call xp_seti (xp, PUNVER, nver)
                    if (xp_stati (xp, SMODE) == XP_SCONCENTRIC && nver >= 3) {
                        call amovr (Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    SUXVER)], nver)
                        call amovr (Memr[xp_statp(xp,PUYVER)], Memr[xp_statp(xp,
			    SUYVER)], nver)
		        call xp_seti (xp, SUNVER, nver)
                    } else {
                        nver = xp_mkpoly (gd, Memr[xp_statp(xp,SUXVER)],
			    Memr[xp_statp(xp,SUYVER)], MAX_NSKY_VERTICES,
			    GL_SOLID, xp_scolor(xp), 1, NO)
		        call xp_seti (xp, SUNVER, nver)
		    }
		    if (ui != NULL)
	    	        call xp_gsapoly (gd, ui, xp)

		# Create, edit, display, and save object lists.
		case '^', 'f', 'b', '~', 'm', 'e', 'a', '@', 'd', 'u', 'z',
		    'r', 'l', 'w':
		    if (ui == NULL)
                        symbol = xp_dmeas (gd, xp, im, ol, NULL, key, wx,
			    wy, NO)
		    else
                        symbol = xp_udmeas (gd, ui, xp, im, ol, NULL, key, wx,
			    wy, Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    PUYVER)], xp_stati(xp,PUNVER), Memr[xp_statp(xp,
			    SUXVER)], Memr[xp_statp(xp,SUYVER)],
			    xp_stati(xp,SUNVER), NO)

		# Measure objects in the objects list.
                case 'o', '-',  '.', '+', '#':
		    if (ui == NULL)
                        psymbol = xp_plmeas (gd, xp, im, ol, rl, gl, key,
			    wx, wy, Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER),
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
		    else
                        psymbol = xp_uplmeas (gd, ui, xp, im, ol, rl, gl, key,
			    wx, wy, Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER),
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
		    symbol = psymbol

		# Measure object at cursor position.
		case ' ', '*':
		    if (ui == NULL)
                        psymbol = xp_pmeas (gd, xp, im, rl, gl, key, wx, wy,
                            Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    PUYVER)], xp_stati(xp,PUNVER), Memr[xp_statp(xp,
			    SUXVER)], Memr[xp_statp(xp,SUYVER)],
			    xp_stati(xp,SUNVER))
		    else
                        psymbol = xp_upmeas (gd, ui, xp, im, rl, gl, key,
			    wx, wy, Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER),
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
		    symbol = psymbol

		# Print the last set of results to the status line and the
		# photometry table, and update the plots panel.
		case ';':
		    if (ui == NULL)
			call xp_pqprint (xp, Memc[imname], INDEFI, INDEFI,
			    INDEFI, LOGRESULTS(pstatus))
		    else {
			call xp_upqprint (xp, INDEFI, INDEFI, INDEFI,
			    LOGRESULTS(pstatus))
			if (UI_SHOWPTABLE(ui) == YES)
			    call xp_tmkresults (gd, ui, xp)
			if (UI_SHOWPLOTS(ui) == YES) {
			    if (psymbol == NULL)
			        tmpobjno = INDEFI
			    else
			        tmpobjno = xp_fobject (xp, XP_OXINIT(psymbol),
			            XP_OYINIT(psymbol), owx, owy)
			    if (rl != NULL && LOGRESULTS(pstatus) == YES)
			        call xp_omkresults (gd, ui, xp, tmpobjno,
			            SEQNO(pstatus))
			    else
			        call xp_omkresults (gd, ui, xp, tmpobjno,
				INDEFI)
			    call xp_udoplots (gd, ui, xp, im, psymbol,
			        Memr[xp_statp(xp,PUXVER)],
				Memr[xp_statp(xp,PUYVER)],
				xp_stati(xp,PUNVER), Memr[xp_statp(xp,SUXVER)],
				Memr[xp_statp(xp,SUYVER)], xp_stati(xp,SUNVER))
			}
		    }

		# Display the photometry table
		case 't':
		    if (ui == NULL) {
			;
		    } else if (UI_SHOWPTABLE(ui) == NO) {
			UI_SHOWPTABLE(ui) = YES
			call gmsg (gd, UI_RESULTS(ui), "yes")
		    } else {
			UI_SHOWPTABLE(ui) = NO
			call gmsg (gd, UI_RESULTS(ui), "no")
		    }

		# Do quick model fit to determine object parameters using
		# either the current cursor position (x) or the last measured
		# cursor position (X).
		case 'x', 'X':
		    if (im == NULL) {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
			}
		    } else if (ui == NULL) {
			if (key == 'x')
		            iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4,
			        NO, NO)
			else
		            iupdate = xp_pmodfit (gd, xp, im, rwx, rwy, rl, 4,
			        NO, NO)
		    } else if (UI_SHOWMPLOTS(ui) == YES) {
			call gmsg (gd, UI_GTERM(ui), UI_VMODELPLOT)
			if (key == 'x') {
		            iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4,
			        YES, NO)
		            rwx = wx; rwy = wy 
			} else
		            iupdate = xp_pmodfit (gd, xp, im, rwx, rwy, rl, 4,
			        YES, NO)
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gflush (gd)
		    } else {
			if (key == 'x') {
		            iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4,
			        NO, NO)
		            rwx = wx; rwy = wy 
			} else
		            iupdate = xp_pmodfit (gd, xp, im, rwx, rwy, rl, 4,
			        NO, NO)

		    }
			
		# Do quick model fit and plot to determine object parameters.
		case 'y':
		    if (im == NULL) {
		        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                            "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
		        }
		    } else if (ui == NULL) {
		        iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4, YES,
			    NO)
		        rwx = wx; rwy = wy 
		    } else if (UI_SHOWMPLOTS(ui) == NO) {
			call printf ("\n")
			call gmsg (gd, UI_GTERM(ui), UI_VMODELPLOT)
		        iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4,
			    YES, NO)
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gflush (gd)
			UI_SHOWMPLOTS(ui) = YES
			call gmsg (gd, UI_MPLOTS(ui), "yes")
		        rwx = wx; rwy = wy 
		    } else {
			UI_SHOWMPLOTS(ui) = NO
			call gmsg (gd, UI_MPLOTS(ui), "no")
		    }

		# Do quick model fit and interact with plot to determine
		# object parameters.
		case 'Y':
		    if (im == NULL) {
		        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
			}
		    } else if (ui == NULL) {
		        iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4,
			    YES, YES)
		        rwx = wx; rwy = wy 
		    } else if (UI_SHOWMPLOTS(ui) == YES) {
			call gmsg (gd, UI_GTERM(ui), UI_VMODELPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VMODELPLOT)
		        iupdate = xp_pmodfit (gd, xp, im, rwx, rwy, rl, 4,
			    YES, YES)
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			if (iupdate == YES)
			    call xp_iguipars (gd, ui, xp)
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VIMAGEPLOT)
			call gflush (gd)
		    }

		# Toggle the results plotting switch.
		case 'g':
		    if (im == NULL) {
		        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
			}
		    } else if (ui == NULL) {
                        if (psymbol == NULL)
                            call xp_aplot (gd, im, xp, Memr[xp_statp(xp,
			        PUXVER)], Memr[xp_statp(xp,PUYVER)],
                                xp_stati(xp,PUNVER), OBJPLOT_RADIUS_WCS,
			        OBJPLOT_PA_WCS, OBJPLOT_COG_WCS)
                        else
                            call xp_oaplot (gd, im, xp, psymbol,
			        Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
				PUYVER)], xp_stati(xp,PUNVER),
				OBJPLOT_RADIUS_WCS, OBJPLOT_PA_WCS,
				OBJPLOT_COG_WCS)
		    } else if (UI_SHOWPLOTS(ui) == NO) {

			UI_SHOWPLOTS(ui) = YES
			call gmsg (gd, UI_PLOTS(ui), "yes")

		    } else {

			UI_SHOWPLOTS(ui) = NO
			call gmsg (gd, UI_PLOTS(ui), "no")
		    }

		# Replot.
		case 'G':

		    if (im == NULL) {
		        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
			}
		    } else if (ui == NULL) {
                        if (psymbol == NULL)
                            call xp_eplot (gd, xp, OBJPLOT_MHWIDTH_WCS,
			        OBJPLOT_MAXRATIO_WCS, OBJPLOT_MPOSANGLE_WCS)
                        else
                            call xp_oeplot (gd, xp, psymbol,
			        OBJPLOT_MHWIDTH_WCS, OBJPLOT_MAXRATIO_WCS,
				OBJPLOT_MPOSANGLE_WCS)
		    } else if (UI_SHOWPLOTS(ui) == YES) {
			# Do the plots.
			call xp_udoplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    PUYVER)], xp_stati(xp,PUNVER), Memr[xp_statp(xp,
			    SUXVER)], Memr[xp_statp(xp,SUYVER)], xp_stati(xp,
			    SUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
		    }

		# Plot the sky plots in non-gui mode.
		case ',':
		    if (im == NULL) {
		        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        if (Memc[imname] == EOS)
                            call printf (
                                "Warning: The current image is undefined\n")
                        else {
                            call printf (
                                "Warning: Cannot open current image (%s)\n")
                                call pargstr (Memc[imname])
			}
		    } else if (ui == NULL) {
                        call xp_splot (gd, xp, SKYPLOT_RADIUS_WCS,
                            SKYPLOT_PA_WCS, SKYPLOT_HISTOGRAM_WCS)
		    }

		# Plot the object region and object analysis results.
		case 'c', 'j', 'C', 'J':
		    if (ui == NULL) {
			if (key == 'j')
			    call xp_orbjplots (gd, xp, im, psymbol,
			        Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
				PUYVER)], xp_stati(xp,PUNVER))
			else if (key == 'c')
			    call xp_objplots (gd, xp, im, psymbol,
			        Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
				PUYVER)], xp_stati(xp,PUNVER))
		    } else if (key == 'c') {
			call gmsg (gd, UI_GTERM(ui), UI_VOBJECTPLOT)
			call xp_uobjplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    PUYVER)], xp_stati(xp,PUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		    } else if (key == 'j') {
			call gmsg (gd, UI_GTERM(ui), UI_VOBJREGIONPLOT)
			call xp_urobjplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		    } else if (key == 'C') {
			call gmsg (gd, UI_GTERM(ui), UI_VOBJECTPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VOBJECTPLOT)
			call xp_uobjplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VIMAGEPLOT)
		    } else if (key == 'J') {
			call gmsg (gd, UI_GTERM(ui), UI_VOBJREGIONPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VOBJREGIONPLOT)
			call xp_urobjplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VIMAGEPLOT)
		    }

		# Plot the sky region and sky analysis results.
		case 's', 'k', 'S', 'K':
		    if (ui == NULL) {
			if (key == 'k')
			    call xp_rskyplots (gd, xp, im, psymbol,
			        Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
				SUYVER)], xp_stati(xp,SUNVER))
			else if (key == 's')
			    call xp_skyplots (gd, xp, im, psymbol,
			        Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
				SUYVER)], xp_stati(xp,SUNVER))
		    } else if (key == 's') {
			call gmsg (gd, UI_GTERM(ui), UI_VSKYPLOT)
			call xp_uskyplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		    } else if (key == 'k') {
			call gmsg (gd, UI_GTERM(ui), UI_VSKYREGIONPLOT)
			call xp_urskyplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
		    } else if (key == 'S')  {
			call gmsg (gd, UI_GTERM(ui), UI_VSKYPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VSKYPLOT)
			call xp_uskyplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VIMAGEPLOT)
		    } else if (key == 'K') {
			call gmsg (gd, UI_GTERM(ui), UI_VSKYREGIONPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VSKYREGIONPLOT)
			call xp_urskyplots (gd, ui, xp, im, psymbol,
			    Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
			    SUYVER)], xp_stati(xp,SUNVER))
			call gmsg (gd, UI_REDISPLAY(ui), "yes")
			call gseti (gd, G_WCS, IMAGE_DISPLAY_WCS)
			call gmsg (gd, UI_GTERM(ui), UI_VIMAGEPLOT)
			call gmsg (gd, UI_CURSOR(ui), UI_VIMAGEPLOT)
		    }

	        # Process a colon command.
	        case ':':
		    if (ui != NULL)
		        symbol =  xp_gxpcolon (gd, ui, xp, dirlist, imlist, im,
			     objlist, ol, reslist, rl, greslist, gl,
			    Memc[cmd], symbol)
		    else
		        symbol = xp_xpcolon (gd, xp, dirlist, imlist, im,
			    objlist, ol, reslist, rl, greslist, gl, Memc[cmd],
			    symbol)

	        default:
		    ;
	        }


	        # Open a new image if requested.
                if (NEWIMAGE(pstatus) == YES || NEWLIST(pstatus) == YES ||
		    NEWRESULTS(pstatus) == YES) {
                    if (NEWIMAGE(pstatus) == YES) {
                        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        imno = xp_stati (xp, IMNUMBER)
			if (ui != NULL) {
			    call gmsgi (gd, UI_IMNO(ui), imno)
			    if (UI_SHOWHEADER(ui) == YES)
			        call xp_mkheader (gd, ui, im, YES)
			}
                        if (im != NULL) {
                            call xp_display (gd, xp, im, 1, IM_LEN(im,1), 1,
                                IM_LEN(im,2), IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
			    if (ui != NULL)
				call gmsg (gd, UI_REDISPLAY(ui), "no")
                        } else {
                            call gclear (gd)
                            call gflush (gd)
                        }
                        call xp_keyset (im, xp)
			if (ui != NULL)
			    call xp_iguipars (gd, ui, xp)
		    }
                    if (NEWLIST(pstatus) == YES) {
                        OBJNO(pstatus) = 0
                        call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)
                        olno = xp_stati (xp, OFNUMBER)
                        if (ol != NULL) {
			    ;
                        } else if (fntlenb (objlist) > 0) {
                            call printf (
                            "Warning: Cannot open current objects list (%s)\n")
                                call pargstr (Memc[olname])
                        }

			if (ui != NULL) {
			    call gmsgi (gd, UI_OFNO(ui), olno)
			    call gmsgi (gd, UI_OBJNO(ui), 0)
			    if (UI_SHOWOBJLIST(ui) == YES) {
		                if (ol == NULL)
			            call gmsg (gd, UI_OBJLIST(ui), "{}")
		    	        else {
				    nobjs = xp_robjects (ol, xp, RLIST_NEW)
                        	    if (nobjs <= 0) {
                            	        call printf (
                            "Warning: The current objects file (%s) is empty\n")
                                        call pargstr (Memc[olname])
                        	    } else {
                            	        call printf (
                                "Read %d objects from current object file %s\n")
                                	    call pargi (nobjs)
                                	    call pargstr (Memc[olname])
                                    }
		        	call xp_mkslist (gd, ui, xp)
		                }
			    }
			}
		    }
                    if (NEWRESULTS(pstatus) == YES) {
                        call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
                        rlno = xp_stati (xp, RFNUMBER)
                        if (rl != NULL) {
                            if (SEQNO(pstatus) == 0)
                                call xp_whphot (xp, rl, "xguiphot")
                            call xp_whiminfo (xp, rl)
                            if (SEQNO(pstatus) == 0)
                                call xp_xpbnr (xp, rl)
                        } else if (fntlenb (reslist) > 0) {
                            call printf (
                            "Warning: Cannot open current results file (%s)\n")
                                call pargstr (Memc[rlname])
                        }
                        call xp_stats (xp, GRESULTS, Memc[glname], SZ_FNAME)
                        glno = xp_stati (xp, GFNUMBER)
                        if (gl != NULL) {
                            ;
                        } else if (fntlenb (greslist) > 0) {
                            call printf (
                            "Warning: Cannot open current results list (%s)\n")
                                call pargstr (Memc[glname])
                        }
			if (ui != NULL) {
			    call gmsg (gd, UI_RFFILE(ui), Memc[rlname])
			    call gmsgi (gd, UI_RFNO(ui), rlno)
			    call gmsg (gd, UI_GFFILE(ui), Memc[glname])
			    call gmsgi (gd, UI_GFNO(ui), glno)
			}
                    }

                    if (NEWIMAGE(pstatus) == YES) {
                        owx = INDEFR; owy = INDEFR
                    } else { 
                        owx = wx; owy = wy
		    }
                    NEWIMAGE(pstatus) = NO; NEWLIST(pstatus) = NO
		    NEWRESULTS(pstatus) = NO
                    NEWCBUF(pstatus) = YES; NEWCENTER(pstatus) = YES
                    NEWSBUF(pstatus) = YES; NEWSKY(pstatus) = YES
                    NEWMBUF(pstatus) = YES; NEWMAG(pstatus) = YES
		} else {
                    owx = wx; owy = wy
                }

	    }

noninteractive_

	    # Do photometry.
	    if (gd == NULL) {

		# Using the object list.
		if (ol != NULL) {
		    nobjs = xp_bphot (im, ol, rl, xp, verbose)
                    if (verbose == YES) {
                        call printf ("\nImage: %s  Results: %s\n")
                            call pargstr (Memc[imname])
                            call pargstr (Memc[rlname])
                        call printf ("\tMeasured %d objects in %s\n")
                            call pargi (nobjs)
                            call pargstr (Memc[olname])
                    }

		# Or generating the object list automatically.
		} else {
                    nobjs = xp_aphot (NULL, im, rl, xp, verbose)
                    if (verbose == YES) {
                        call printf ("\nImage: %s  Results: %s\n")
                            call pargstr (Memc[imname])
                            call pargstr (Memc[rlname])
                        call printf ("\tDetected and measured %d objects\n")
                            call pargi (nobjs)
                    }
		}
	    }

            # Increment the results file list counter. If the results file
	    # is empty delete it, otherwise preserve the current sequence
	    # number close it and move on.
            if (imno == EOF || NEWRESULTS(pstatus) == YES) {
                if (rl != NULL) {
                    call flush (rl)
                    if (fstati (rl, F_FILESIZE) == 0 || SEQNO(pstatus) == 0) {
                        call fstats (rl, F_FILENAME, Memc[str], SZ_FNAME)
                        call close (rl)
                        call delete (Memc[str])
                    } else {
                        call close (rl)
                        lsymbol = stfind (xp_statp(xp, SEQNOLIST), Memc[rlname])
                        if (lsymbol != NULL)
                            XP_MAXSEQNO(lsymbol) = SEQNO(pstatus)
                        else {
                            lsymbol = stenter (xp_statp(xp, SEQNOLIST),
                                Memc[rlname], LEN_SEQNOLIST_STRUCT)
                            XP_MAXSEQNO(lsymbol) = SEQNO(pstatus)
			}
		    }
                    rl = NULL
                }
                if ((imno != EOF) && (rlno < fntlenb (reslist)))
                    rlno = rlno + 1
                if (gl != NULL) {
                    call flush (gl)
                    if (fstati (gl, F_FILESIZE) == 0 || SEQNO(pstatus) == 0) {
                        call fstats (gl, F_FILENAME, Memc[str], SZ_FNAME)
                        call close (gl)
                        call delete (Memc[str])
                    } else
                        call close (gl)
                    gl = NULL
                }
                if ((imno != EOF) && (glno < fntlenb (greslist)))
                    glno = glno + 1
            }

	    # Increment the objects file list counter.
 	    if (imno == EOF || NEWLIST(pstatus) == YES) {
                if (ol != NULL) {
                    call close (ol)
                    ol = NULL
                }
                if ((imno != EOF) && (olno < fntlenb (objlist)))
                    olno = olno + 1
            }

	    # Increment the image list counter.
	    if (imno == EOF || NEWIMAGE(pstatus) == YES) {
                if (im != NULL) {
                    call imunmap (im)
                    im = NULL
                }
                if ((imno != EOF) && (imno < imtlen (imlist)))
                    imno = imno + 1
		else if (gd == NULL)
		    imno = EOF
            }

	} until (imno == EOF) 

	# Update the algorithm parameters.
	if (update == YES)
	    call xp_pxpars (xp)

        # Reset the current directory
        call xp_stats (xp, STARTDIR, Memc[cmd], SZ_LINE)
        call fchdir (Memc[cmd])

	# Cleanup.
	call xp_xpfree (xp)
	call fntclsb (greslist)
	call fntclsb (reslist)
	call fntclsb (objlist)
	call imtclose (imlist)
	call fntclsb (dirlist)
	if (gd != NULL) {
	    if (ui != NULL)
	        call xp_uifree (ui)
	    call gclose (gd)
	}

	call sfree (sp)
end
