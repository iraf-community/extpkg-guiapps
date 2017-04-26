include <fset.h>
include <imhdr.h>
include <gset.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

define  IHELPFILE       "xapphot$doc/xguiphot.keys"

procedure t_xphot()

int	dirlist, imlist, objlist, reslist, greslist, ol, rl, gl, imno, olno
int	rlno, glno, wcs, key,  nver, update, verbose, nobjs, iupdate
pointer	sp, images, objects, results, gresults, graphics, imname, olname, rlname
pointer	glname, cmd, str, gd, im, xp
pointer	symbol, lsymbol, pstatus
real	wx, wy, owx, owy

bool	fp_equalr(), clgetb()
int	xp_mkolist(), xp_mkrlist(), fntlenb(), fntrfnb(), open()
int	xp_dirlist(), xp_imlist, imtrgetim(), clgcur(), xp_stati(), fstati()
int	xp_mkpoly(), xp_scolor(), xp_acolor(), imtlen(), btoi()
int	access(), xp_bphot(), xp_aphot(), xp_pmodfit()
pointer	gopen(), immap(), stfind(), stenter(), xp_statp(), xp_dmeas()
pointer	xp_pmeas(), xp_plmeas(), xp_xpcolon()
errchk	immap(), open()

define	noninteractive_ 99

begin
	call fseti (STDOUT, F_FLUSHNL, YES)

	# Allocate some working memory.
	call smark (sp)
	call salloc (images, SZ_FNAME, TY_CHAR)
	call salloc (objects, SZ_FNAME, TY_CHAR)
	call salloc (results, SZ_FNAME, TY_CHAR)
	call salloc (gresults, SZ_FNAME, TY_CHAR)
	call salloc (graphics, SZ_FNAME, TY_CHAR)
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

	# Initialize the algorithm parameters.
	call xp_gxpars (xp)
	pstatus = xp_statp(xp,PSTATUS)

	# Open the graphics stream.
	if (clgetb ("interactive")) {
	    if (xp_stati (xp, DERASE) == YES)
	        gd = gopen (Memc[graphics], NEW_FILE, STDGRAPH)
	    else
	        gd = gopen (Memc[graphics], APPEND, STDGRAPH)
	} else
	    gd = NULL
        update = btoi(clgetb ("update"))
	LOGRESULTS(pstatus) = btoi(clgetb("logresults"))
        verbose = btoi(clgetb ("verbose"))

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
        NEWRESULTS(pstatus) = YES

	# Open the SEQNO(pstatus) symbol table.
	call xp_oseqlist (xp)

	repeat {

	    # Open the first image and display it.
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
		        #call printf ("Warning: Cannot open image (%s)\n")
			    #call pargstr (Memc[imname])
		        im = NULL
		    } else {
			if (gd != NULL)
	    	            call xp_display (gd, xp, im, 1, IM_LEN(im,1), 1,
		                IM_LEN(im,2), IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS) 
		    }
	            call xp_seti (xp, IMNUMBER, imno)
	        }
	    	call xp_keyset (im, xp)
	        call xp_sets (xp, IMAGE, Memc[imname])
	    }

	    # Open the coordinate file if any.
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
                    #call printf (
                    #"Warning: Cannot open current objects file (%s)\n")
                        #call pargstr (Memc[olname])
                    ol = NULL
                }
                call xp_sets (xp, OBJECTS, Memc[olname])
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
                        call xp_whphot (xp, rl, "xphot")
                    call xp_whiminfo (xp, rl)
                    if (SEQNO(pstatus) == 0)
                        call xp_xpbnr (xp, rl)
                } then {
                    #call printf (
                    #"Warning: Cannot open current objects file (%s)\n")
                        #call pargstr (Memc[rlname])
                    rl = NULL
                }
                call xp_sets (xp, RESULTS, Memc[rlname])

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
                    #call printf (
                    #"Warning: Cannot open current objects file (%s)\n")
                        #call pargstr (Memc[glname])
                    gl = NULL
                }
                call xp_sets (xp, GRESULTS, Memc[glname])
            }

	    if (gd == NULL)
		goto noninteractive_

	    # Initialize the analysis.
	    NEWIMAGE(pstatus) = NO; NEWLIST(pstatus) = NO
	    NEWRESULTS(pstatus) = NO; OBJNO(pstatus) = 0; symbol = NULL
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

		# Print help.
		case '?':
		    call gpagefile (gd, IHELPFILE, "")

		# Print the file list.
		case '$':
		    call xp_pflist (gd, xp, dirlist, imlist, objlist, reslist,
		        greslist)

		# Process next image.
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
                        call printf ("Warning: Image list at EOF\n")
		    }

		# Process previous image.
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
                        call printf ("Warning: Image list at BOF\n")
		    }

		# Redisplay the image.
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
                    } else {
                        call xp_pimheader (gd, im)
                    }

		# Process the next coordinate list.
                case ']':
                    if (olno < fntlenb (objlist)) {
                        NEWLIST(pstatus) = YES
                        break
                    }

                # Process the previous coordinate list.
                case '[':
                    if (olno > 1) {
                        olno = olno - 2
                        NEWLIST(pstatus) = YES
                        break
                    }

		# Draw the default photometry and sky polygonal apertures
		# on the image display.
		case 'v':
		    nver = xp_mkpoly (gd, Memr[xp_statp(xp,PUXVER)],
		        Memr[xp_statp(xp,PUYVER)], MAX_NAP_VERTICES, GL_SOLID,
			xp_acolor(xp), 1, YES)
		    call xp_seti (xp, PUNVER, nver)
		    if (xp_stati (xp, SMODE) == XP_SCONCENTRIC && nver >= 3) {
			call amovr (Memr[xp_statp(xp,PUXVER)],
			    Memr[xp_statp(xp,SUXVER)], nver)
			call amovr (Memr[xp_statp(xp,PUYVER)],
			    Memr[xp_statp(xp,SUYVER)], nver)
			call xp_seti (xp, SUNVER, nver)
		    } else {
		        nver = xp_mkpoly (gd, Memr[xp_statp(xp,SUXVER)],
			    Memr[xp_statp(xp,SUYVER)], MAX_NAP_VERTICES,
			    GL_SOLID, xp_scolor(xp), 1, NO)
			call xp_seti (xp, SUNVER, nver)
		    }

                # Create, examine, and save the objects list.
                case '^', 'f', 'b', '~', 'm', 'e', 'a', '@', 'd', 'u', 'z',
                    'r', 'l', 'w':
                    symbol = xp_dmeas (gd, xp, im, ol, NULL, key, wx, wy, NO)

                # Measure the objects in the object list.
                case 'o', '-', '.', '+', '#':
                    symbol = xp_plmeas (gd, xp, im, ol, rl, gl, key, wx, wy,
                        Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,PUYVER)],
			xp_stati(xp,PUNVER), Memr[xp_statp(xp, SUXVER)],
			Memr[xp_statp(xp, SUYVER)], xp_stati(xp, SUNVER))

		# Measure the cursor or auto generated list objects.
		case ' ', '*':
                    symbol = xp_pmeas (gd, xp, im, rl, gl, key, wx, wy,
                        Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,PUYVER)],
			xp_stati(xp,PUNVER), Memr[xp_statp(xp, SUXVER)],
			Memr[xp_statp(xp,SUYVER)], xp_stati(xp, SUNVER))

		# Print the last results.
		case ';':
		    call xp_pqprint (xp, Memc[imname], INDEFI, INDEFI, INDEFI,
			LOGRESULTS(pstatus))

		# Do a quick model fit and print results.
		case 'x':
                    iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4, NO, NO)

		# Do a quick model fit and plot results.
		case 'y':
                    iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4, YES, NO)

		# Do a quick model fit, plot, and interact with results.
		case 'Y':
                    iupdate = xp_pmodfit (gd, xp, im, wx, wy, rl, 4, YES, YES)

		# Display a zoomed-up subraster around the measured star.
		case 'I':
		    if (im != NULL) {
			if (symbol == NULL) {
		            call xp_cpdisplay (gd, xp, im, wx, wy, INDEFR,
			        IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS, YES, NO)
			    call xp_apmark (gd, xp, Memr[xp_statp(xp,PUXVER)],
			        Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER),
				IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS)
			} else {
		            call xp_ocpdisplay (gd, xp, im, XP_OXINIT(symbol),
			        XP_OYINIT(symbol), INDEFR, IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS, YES, NO)
			    call xp_oapmark (gd, xp, symbol, Memr[xp_statp(xp,
			        PUXVER)], Memr[xp_statp(xp,PUYVER)],
				xp_stati(xp, PUNVER), IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
			}
		    } else {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
			call printf ("Warning: Cannot access image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Draw a contour plot of a subraster around the measured star.
		case 'c':
		    if (im != NULL) {
			if (symbol == NULL)
		            call xp_cpplot (gd, xp, im, wx, wy, INDEFR,
			        IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS)
			else
		            call xp_ocpplot (gd, xp, im, XP_OXINIT(symbol),
			        XP_OYINIT(symbol), INDEFR, IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
		    } else {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
			call printf ("Warning: Cannot access image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Draw a mesh plot of a subraster around the measured star.
		case 's':
		    if (im != NULL) {
			if (symbol == NULL)
		            call xp_asplot (gd, xp, im, wx, wy, INDEFR,
			        IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS)
			else
		            call xp_oasplot (gd, xp, im, XP_OXINIT(symbol),
			        XP_OYINIT(symbol), INDEFR, IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
		    } else {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
			call printf ("Warning: Cannot access image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Overlay a contour plot on a display of subraster around
		# the measured star.
		case 'O':
		    if (im != NULL) {
			if (symbol == NULL) {
		            call xp_cpdisplay (gd, xp, im, wx, wy, INDEFR,
			        IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS, YES, YES)
			    call xp_apmark (gd, xp, Memr[xp_statp(xp,PUXVER)],
			        Memr[xp_statp(xp,PUYVER)], xp_stati(xp,PUNVER),
				IMAGE_DISPLAY_WCS, IMAGE_DISPLAY_WCS)
			} else {
		            call xp_ocpdisplay (gd, xp, im, XP_OXINIT(symbol),
			        XP_OYINIT(symbol), INDEFR, IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS, YES, YES)
			    call xp_oapmark (gd, xp, symbol, Memr[xp_statp(xp,
			        PUXVER)], Memr[xp_statp(xp,PUYVER)],
				xp_stati(xp,PUNVER), IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
			}
		    } else {
			call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
			call printf ("Warning: Cannot access image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Plot the results of the photometry.
		case 'g':
		    if (im != NULL) {
			if (symbol == NULL)
		            call xp_aplot (gd, im, xp, Memr[xp_statp(xp,
			        PUXVER)], Memr[xp_statp(xp,PUYVER)],
			        xp_stati(xp,PUNVER), OBJPLOT_RADIUS_WCS,
				OBJPLOT_PA_WCS, OBJPLOT_COG_WCS)
			else
		            call xp_oaplot (gd, im, xp, symbol,
			    Memr[xp_statp(xp,PUXVER)], Memr[xp_statp(xp,
			    PUYVER)], xp_stati(xp,PUNVER), OBJPLOT_RADIUS_WCS,
			    OBJPLOT_PA_WCS, OBJPLOT_COG_WCS)
		    } else {
			call printf ("Warning: Cannot open image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Plot the results of the shape analysis.
		case 'G':
		    if (im != NULL) {
			if (symbol == NULL)
		            call xp_eplot (gd, xp, OBJPLOT_MHWIDTH_WCS,
			        OBJPLOT_MAXRATIO_WCS, OBJPLOT_MPOSANGLE_WCS)
			else
		            call xp_oeplot (gd, xp, symbol,
			        OBJPLOT_MHWIDTH_WCS, OBJPLOT_MAXRATIO_WCS,
				OBJPLOT_MPOSANGLE_WCS)
		    } else {
			call printf ("Warning: Cannot open image (%s)\n")
			    call pargstr (Memc[imname])
		    }

		# Plot the sky results.
		case 'S':
		    if (im != NULL) {
		        call xp_splot (gd, xp, SKYPLOT_RADIUS_WCS,
			    SKYPLOT_PA_WCS, SKYPLOT_HISTOGRAM_WCS)
		    } else {
			call printf ("Warning: Cannot open image (%s)\n")
			    call pargstr (Memc[imname])
		    }

	        # Process a colon command.
	        case ':':
		    symbol = xp_xpcolon (gd, xp, dirlist, imlist, im, objlist,
		        ol, reslist, rl, greslist, gl, Memc[cmd], symbol)

	        default:
		    call printf ("Ambiguous or undefined keystroke command\n")
	        }

		# Open a new image if requested.
                if (NEWIMAGE(pstatus) == YES || NEWLIST(pstatus) == YES ||
		    NEWRESULTS(pstatus) == YES) {
                    if (NEWIMAGE(pstatus) == YES) {
                        call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
                        imno = xp_stati (xp, IMNUMBER)
                        if (im != NULL) {
                            call xp_display (gd, xp, im, 1, IM_LEN(im,1), 1,
                                IM_LEN(im,2), IMAGE_DISPLAY_WCS,
				IMAGE_DISPLAY_WCS)
                        } else {
                            call gclear (gd)
                            call gflush (gd)
                            call printf ("Warning: Cannot open image (%s)\n")
                                call pargstr (Memc[imname])
                        }
                        call xp_keyset (im, xp)
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
                    }
                    if (NEWRESULTS(pstatus) == YES) {
                        call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)
                        rlno = xp_stati (xp, RFNUMBER)
                        if (rl != NULL) {
                            if (SEQNO(pstatus) == 0)
                                call xp_whphot (xp, rl, "xphot")
                            call xp_whiminfo (xp, rl)
                            if (SEQNO(pstatus) == 0)
                                call xp_xpbnr (xp, rl)
                        } else if (fntlenb (reslist) > 0) {
                            call printf (
                            "Warning: Cannot open current results list (%s)\n")
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

                    }
                    if (NEWIMAGE(pstatus) == YES) {
                        owx = INDEFR; owy = INDEFR
                    } else if (NEWLIST(pstatus) == YES) {
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
	    if (gd == NULL) {
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

            # Increment the results file list counter.
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

	    if (imno == EOF || NEWLIST(pstatus) == YES) {
                if (ol != NULL) {
                    call close (ol)
                    ol = NULL
                }
                if ((imno != EOF) && (olno < fntlenb (objlist)))
                    olno = olno + 1
            }

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
	call fntclsb(dirlist)
	if (gd != NULL)
	    call gclose (gd)

	call sfree (sp)
end
