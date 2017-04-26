include <ctype.h>
include <fset.h>
include "rvgui.h"
include "rvpackage.h"
include "rvplots.h"
include "rvflags.h"
include "rvfilter.h"
include "rvsample.h"
include "rvkeywords.h"
include "rvcont.h"


# UI_COLON - Procedure to process the colon commands defined below.

int procedure ui_colon (rv, cmdstr)

pointer	rv				#I pointer to the RV structure
char	cmdstr[SZ_LINE]			#I command string

pointer	sp, cmd
int	map_flag, strdic()

begin
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)

	# Unpack the keyword from the string and look it up in the
	# dictionary.  Switch on command and call the appropriate routines.

	switch (strdic(Memc[cmd], Memc[cmd], SZ_FNAME, UI_KEYWORDS)) {
	case UI_UPDATE:
	    # Update the whole thing.
	    call ui_update (rv)

	case UI_AUTOWRITE:
	    # Process a :autowrite UI request
	    call ui_autowrite (rv)

	case UI_FXCSET:
	    # Update the FXCOR task params.
	    call ui_fxcset (rv)

	case UI_KEYWSET:
	    # Update the KEYWPARS pset params.
	    call ui_keywset (rv)

	case UI_FILTSET:
	    # Update the FILTPARS pset params.
	    call ui_filtset (rv)

	case UI_FMOPSET:
	    # Update the FFT mode options.
	    call ui_fmopset (rv)

	case UI_CONTSET:
	    # Update the CONTINPARS pset params.
	    call ui_contset (rv)

	case UI_FXCSTAT:
	    # Update the FXCOR task params.
	    call rv_gui_stat (rv, "fxcor")

	case UI_KEYWSTAT:
	    # Update the KEYWPARS pset params.
	    call rv_gui_stat (rv, "keywpars")

	case UI_FILTSTAT:
	    # Update the FILTPARS pset params.
	    call rv_gui_stat (rv, "filtpars")

	case UI_CONTSTAT:
	    # Update the CONTINPARS pset params.
	    call rv_gui_stat (rv, "contpars")

	case UI_LISTOPEN:
	    # Update the image and aperture lists.
	    call ui_listopen (rv)

	#case UI_APLIST:
	#    # Update the aperture list.
	#    call ui_aplist (rv)

	case UI_IMGLIST:
	    # Update the image list.
	    call ui_imglist (rv)

	case UI_OUTPUT:
	    # Set an output filename and then move up/down the list
	    call ui_output (rv)

	case UI_IMLOAD:
	    # Load the requested image and aperture.
	    call ui_imload (rv)

	case UI_SHOWV:
	    # Show the verbose fit information in the dialog window.
	    call gargi (map_flag)
	    if (map_flag > 0)
	        call gmsg (RV_GP(rv), "dialogText", " ")
	    call ui_showv (rv)

	case UI_QUIT:
	    # Quit the task
	    call ui_quit (rv)
	    call sfree (sp)
	    return (QUIT)

	default:
	    ;# No-op
	}

	call sfree (sp)
	return (OK)
end


# UI_UPDATE - Send all of the UI object a message telling them the state
# of the application.

procedure ui_update (rv)

pointer	rv					#i RV struct parameter

int	status

begin
	# Call all of the status procedures.
	call rv_gui_stat (rv, "fxcor")
	call rv_gui_stat (rv, "keywpars")
	call rv_gui_stat (rv, "filtpars")
	call rv_gui_stat (rv, "contpars")

	# Send the help text.
	call rv_helpopen (rv)

	# Set the list movement sensitivity.
	if (RV_NOBJS(rv) > 1 || RV_NUMAPS(rv) > 1 || RV_NTEMPS(rv) > 1)
	    call gmsgi (RV_GP(rv), "listStat", -1)
	else
	    call gmsgi (RV_GP(rv), "listStat", 0)

	# Let the GUI know whether we have any data.
	status = 0
	if (RV_OBJECTS(rv) == NULL)    status = status + 1
	if (RV_TEMPLATES(rv) == NULL)  status = status + 1
	if (status > 0) {
	    call gmsg (RV_GP(rv), "alert", "browser")
	    call gmsg (RV_GP(rv), "alert", 
	     "No images loaded!\nSelect data using file browser")
	}
end


# UI_MODECHANGE - Update the UI modeChange object with the new mode.

procedure ui_modechange (rv, mode)

pointer	rv					#i RV struct parameter
int	mode					#i mode

begin
	call gmsgi (RV_GP(rv), "modeChange", mode)
end


# UI_AUTOWRITE - Update the UI modeChange object with the new mode.

procedure ui_autowrite (rv)

pointer rv                                      #i RV struct parameter

begin
        call gmsgi (RV_GP(rv), "autowritePar", RV_AUTOWRITE(rv))
end


# UI_OUTPUT - Set and output filename and move up/down the lists.

procedure ui_output (rv)

pointer rv                                      #i RV struct parameter

pointer sp, fname
pointer	infile, rinfile
bool	written
int     code

pointer	gopen()
int	prev_spec(), prev_temp(), prev_ap()
int	next_spec(), next_temp(), next_ap()

begin
        call smark (sp)
        call salloc (fname, SZ_FNAME, TY_CHAR)

        call gargi (code)
        call gargstr (Memc[fname], SZ_FNAME)

	infile = RV_OBJECTS(rv)
	rinfile = RV_TEMPLATES(rv)
	written = false

	# Open the filename, we assume there isn't a previous one already
	# open to be closed.
        call init_files (rv, DEVICE(rv), Memc[fname], true)
        RV_MGP(rv) = gopen ("stdvdm", APPEND, RV_GRFD(rv))
        call strcpy (Memc[fname+1], SPOOL(rv), SZ_FNAME)

	# Save the results
	if (code < 999)
	    call cmd_write (rv, written)

	# Now move.
        if (code == 0) {
	    call sfree (sp)
	    return 

        } else if (code == -1) { 			# 'p' command
            # Now do the "previous" operation as specified.
            if (RV_TEMPNUM(rv) > 1 && RV_NTEMPS(rv) > 1) {
                if (prev_temp(rv, rinfile, written) == ERR_READ)
                    call rv_errmsg (rv, "Error reading previous template.")
                else
                    RV_NEWXCOR(rv) = YES
            } else {
                # Do previous aperture
                if (CURAPNUM(rv) > 1 && NUMAPS(rv) > 1) {
                    if (RV_NTEMPS(rv) > 1 && RV_TEMPNUM(rv) > 1) {
                        RV_TEMPNUM(rv) = RV_NTEMPS(rv) + 1 # Reset templates
                        if (prev_temp(rv, rinfile, written) == ERR_READ)
                            call rv_errmsg (rv,
				"Error reading previous template.")
                    }
                    if (prev_ap(rv, written) == ERR_READ)
                        call rv_errmsg (rv, "Errror reading previous aperture.")
                    else
                        RV_NEWXCOR(rv) = YES
                } else {
                    # Do previous object image
                    if (RV_NOBJS(rv) > 1 && RV_IMNUM(rv) > 1) {
                        if (NUMAPS(rv) > 1) {
                            CURAPNUM(rv) = NUMAPS(rv) + 1
                            if (prev_ap(rv, written) == ERR_READ)
                                call rv_errmsg (rv,
				    "Errror reading prev aperture.")
                        }
                        if (RV_NTEMPS(rv) > 1) {
                            RV_TEMPNUM(rv) = RV_NTEMPS(rv) + 1
                            if (prev_temp(rv, rinfile, written) ==ERR_READ)
                                call rv_errmsg (rv,
				    "Error reading prev template.")
                        }
                        if (prev_spec(rv, infile, written) == ERR_READ)
                            call rv_errmsg (rv,
				    "Error reading previous object.")
                        else
                            RV_NEWXCOR(rv) = YES
                    } else
                        call rv_errmsg (rv, "At the start of the input list.")
                }
            }

        } else if (code == 1) { 		# 'n' command
            # Now do the "next" operation as specified.
            if (RV_TEMPNUM(rv) < RV_NTEMPS(rv)) {
                if (next_temp(rv, rinfile, written) == ERR_READ)
                    call rv_errmsg (rv, "Error reading next template.")
                else
                    RV_NEWXCOR(rv) = YES
            } else {
                # Get the next aperture
                if (CURAPNUM(rv) < NUMAPS(rv)) {
                    if (RV_NTEMPS(rv) > 1) {        # Reset templates
                        RV_TEMPNUM(rv) = 0
                        if (next_temp(rv, rinfile, written) == ERR_READ)
                            call rv_errmsg (rv, "Error reading next template.")
                    }
                    if (next_ap(rv, written) == ERR_READ)
                        call rv_errmsg (rv, "Errror reading next aperture.")
                    else
                        RV_NEWXCOR(rv) = YES
                } else {
                    # Get the next object.
                    if (RV_IMNUM(rv) < RV_NOBJS(rv)) {
                        if (NUMAPS(rv) > 1) {
                            CURAPNUM(rv) = 0        # Reset apertures
                            if (next_ap(rv, written) == ERR_READ)
                                call rv_errmsg (rv,
				    "Errror reading next aperture.")
                        }
                        if (RV_NTEMPS(rv) > 1) {
                            RV_TEMPNUM(rv) = 0      # Reset templates
                            if (next_temp(rv, rinfile, written) ==ERR_READ)
                                call rv_errmsg (rv,
				    "Error reading next template.")
                        }
                        if (next_spec(rv, infile, written) == ERR_READ)
                            call rv_errmsg (rv,
				    "Error reading next object.")
                       else
                            RV_NEWXCOR(rv) = YES
                    } else
                        call rv_errmsg (rv,
				    "No more spectra to process.")
                }
            }
        }
        call sfree (sp)
end


# UI_QUIT - Quit the task.

procedure ui_quit (rv)

pointer	rv					#i RV struct parameter

pointer	sp, fname
int	code
bool	written

pointer	gopen()

begin
	call gargi (code)
	if (code == 0) {
	    ;					# just exit
	} else if (code == 1) {
	    call smark (sp)
	    call salloc (fname, SZ_FNAME, TY_CHAR)

	    call gargstr (Memc[fname], SZ_FNAME)
            call init_files (rv, DEVICE(rv), Memc[fname], true)
            RV_MGP(rv) = gopen ("stdvdm", APPEND, RV_GRFD(rv))
            call strcpy (Memc[fname], SPOOL(rv), SZ_FNAME)
            written = false
	    call cmd_write (rv, written)

	    call sfree (sp)
	}
end


# UI_LISTOPEN - Update the current image and aperture lists in the GUI.

procedure ui_listopen (rv)

pointer	rv					#i RV struct parameter

begin
	if (RV_OBJECTS(rv) == NULL || RV_TEMPLATES(rv) == NULL)
	    return

	call ui_imglist (rv)
	#call ui_aplist (rv)
end


# UI_APLIST - Update the current aperture list in the GUI.

procedure ui_aplist (rv)

pointer	rv					#i RV struct parameter

pointer	sp, buf, ranges, list, num
int	i, naps, number

int	decode_ranges(), get_next_number()
bool	streq()

begin
	call smark (sp)
	call salloc (buf, SZ_FNAME, TY_CHAR)
	call salloc (num, SZ_FNAME, TY_CHAR) 
	call salloc (list, SZ_COMMAND, TY_CHAR)
        call salloc (ranges, 3*SZ_APLIST, TY_INT)

	call aclrc (Memc[num], SZ_FNAME)
	call aclrc (Memc[num], SZ_FNAME)
        call aclrc (Memc[list], SZ_COMMAND)
        call aclri (Memi[ranges], 3*SZ_APLIST)

	# Get the pattern.
	call gargstr (Memc[buf], SZ_FNAME)
	if (Memc[buf] == EOS)
	    call clgstr ("apertures", Memc[buf], SZ_LINE)

	if (streq ("*", Memc[buf])) {
	    call strcpy ("", Memc[list], SZ_FNAME)
	} else {
            if (decode_ranges(Memc[buf],Memi[ranges],SZ_APLIST,naps) == ERR) {
                call sfree (sp)
                call rv_errmsg (rv, "Error decoding APNUM range string.")
            }

	    # Expand the pattern into a list
            for (i=0; get_next_number (Memi[ranges], number) != EOF; i=i+1) {
	        call sprintf (Memc[num], SZ_FNAME, "%s ")
		    call pargi (number)
	        call strcat (Memc[num], Memc[list], SZ_COMMAND)
            }
        }

	# Send it up to the GUI.
	call gmsg (RV_GP(rv), "apStr", Memc[buf])
	call gmsg (RV_GP(rv), "apList", Memc[list])

	call sfree (sp)
end


# UI_IMGLIST - Update the current image list in the GUI.

procedure ui_imglist (rv)

pointer	rv					#i RV struct parameter

pointer	sp, buf, pat, list
int	lptr
int	i, nfiles

int	fntopnb(), fntlenb(), fntrfnb()

begin
	call smark (sp)
	call salloc (buf, SZ_FNAME, TY_CHAR)
	call salloc (pat, SZ_LINE, TY_CHAR)
	call salloc (list, SZ_COMMAND, TY_CHAR)

	Memc[buf] = EOS ; Memc[pat] = EOS
	call gargwrd (Memc[buf], SZ_FNAME)
	call gargwrd (Memc[pat], SZ_FNAME)

	# If no pattern was specified get it from the CL.
	if (Memc[pat] == EOS) {
	    if (Memc[buf] == 'o')
	        call clgstr ("objects", Memc[pat], SZ_LINE)
	    else if (Memc[buf] == 't')
	        call clgstr ("templates", Memc[pat], SZ_LINE)
	    else 
	        call error (0, "Invalid ui_imglist option.")
	}

	# Build up the list.
	lptr = fntopnb (Memc[pat], NO)
	nfiles = fntlenb (lptr)
	call aclrc (Memc[list], SZ_COMMAND)
	do i = 1, nfiles {
	    if (fntrfnb (lptr, i, Memc[buf], SZ_FNAME) == EOF)
		break
	    call strcat (Memc[buf], Memc[list], SZ_COMMAND)
	    call strcat (" ", Memc[list], SZ_COMMAND)
	}

	# Send it up to the GUI.
	call gmsg (RV_GP(rv), "imgStr", Memc[pat])
	call gmsg (RV_GP(rv), "imgList", Memc[list])

	# Update the task parameter.
	if (Memc[buf+1] == 'o')
	    call clpstr ("objects", Memc[pat])
	else
	    call clpstr ("templates", Memc[pat])

	call fntclsb (lptr)
	call sfree (sp)
end


# UI_IMLOAD - Load the requested image and aperture.

procedure ui_imload (rv)

pointer	rv					#i RV struct parameter

pointer	sp, which, fname, img
int	imcode, imitem
bool	written

pointer	gopen()
int	get_spec()
bool	streq()

begin
	call smark (sp)
	call salloc (which, SZ_FNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (img, SZ_LINE, TY_CHAR)

	# Get the arguments.
	call gargwrd (Memc[fname], SZ_FNAME)
	call gargwrd (Memc[which], SZ_FNAME)
	call gargi (imcode)
	call gargwrd (Memc[img], SZ_FNAME)
	call gargi (imitem)

	if (!streq(Memc[fname],"none")) {
            # Open the filename, we assume there isn't a previous one already
            # open to be closed.
            call init_files (rv, DEVICE(rv), Memc[fname], true)
            RV_MGP(rv) = gopen ("stdvdm", APPEND, RV_GRFD(rv))
            call strcpy (Memc[fname], SPOOL(rv), SZ_FNAME)
            written = false
            call cmd_write (rv, written) 		# save the results

	} else {
	    # No filename specified so assume either it's already been written
	    # or the user just didn't want to keep it.
	    written = true
	    RV_UPDATE(rv) = NO
	}

	if (Memc[which] == 'o') {
	    if (imcode != 0) {
	        if (imitem != 0)
		    RV_IMNUM(rv) = imitem
		call strcpy (Memc[img], IMAGE(rv), SZ_FNAME)
                if (get_spec(rv, Memc[img], OBJECT_SPECTRUM) == ERR_READ) {
                    call sfree (sp)
                    return
                }
            	RV_NEWXCOR(rv) = YES
            	RV_FITDONE(rv) = NO
            	written = false
            	call gmsgi (RV_GP(rv), "wasWritten", 0)
	    }
	} else if (Memc[which] == 't') {
	    if (imcode != 0) {
	        if (imitem != 0)
		    RV_TEMPNUM(rv) = imitem
		call strcpy (Memc[img], RIMAGE(rv), SZ_FNAME)
                if (get_spec(rv, Memc[img], REFER_SPECTRUM) == ERR_READ) {
                    call sfree (sp)
                    return
                }
            	RV_NEWXCOR(rv) = YES
            	RV_FITDONE(rv) = NO
            	written = false
            	call gmsgi (RV_GP(rv), "wasWritten", 0)
	    }
	}

	call sfree (sp)
end


# UI_SHOWV - Show verbose information about the fit.

procedure ui_showv (rv)

pointer	rv					#i RV struct pointer

int	fd, verbose
int	open()
pointer	sp, buf
errchk	open

begin
	call smark (sp)
	call salloc (buf, SZ_FNAME, TY_CHAR)

        call mktemp ("uparm$tmp", Memc[buf], SZ_FNAME)
	iferr (fd = open (Memc[buf], NEW_FILE, TEXT_FILE))
	    call error (0, "Error opening temp file for ui_showv.")
	verbose = RV_VERBOSE(rv)
	RV_VERBOSE(rv) = OF_LONG
	call rv_verbose_fit (rv, fd)
	RV_VERBOSE(rv) = verbose
	call close (fd)

	# Open the window and send the text.
	call ui_rvpagefile (RV_GP(rv), "verbResultStat", Memc[buf])

	call delete (Memc[buf])
	call sfree (sp)
end


# UI_RVPAGEFILE - Send one of the files created to the GUI popup.

procedure ui_rvpagefile (gp, param, fname)

pointer gp                                      #i graphics decriptor
char	param[ARB]				#i parameter to notify
pointer fname[ARB]                              #i file to page

pointer sp, buf, line, tp
long    fsize, fstatl()
int     fd
int     getline(), gstrcpy(), open()
errchk  open

begin
        call smark (sp)
        call salloc (line, SZ_LINE, TY_CHAR)

        # Read the the results back in and delete the dummy file.
        fd = open (fname, READ_ONLY, TEXT_FILE)
        fsize = fstatl (fd, F_FILESIZE) + 1
        call salloc (buf, fsize, TY_CHAR)
        tp = buf
        while (getline(fd, Memc[line]) != EOF)
            tp = tp + gstrcpy (Memc[line], Memc[tp], ARB)
        call close (fd)
        Memc[tp-1] = EOS

        call gmsg (gp, param, Memc[buf])

        call sfree (sp)
end


# UI_FXCSET - Set a task parameter without "doing" anything else.

procedure ui_fxcset (rv)

pointer rv                              #I RV struct pointer

pointer	sp, field, str
int	ival, npts
real	rval
bool	bval, written

int	cod_verbose(), cod_which()
int	cod_fitfunc(), cod_rebin(), btoi()
int	rv_apnum_range(), rv_load_sample()
int	cmd_objects(), cmd_refspec()
bool	streq()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (field, SZ_LINE, TY_CHAR)

	call gargwrd (Memc[field], SZ_LINE)

	if (streq (Memc[field], "obj")) {
	    written = true
	    if (cmd_objects (rv, RV_OBJECTS(rv), written) == ERR_READ)
		call rv_errmsg (rv, "Error reading new 'object' list.")
	    RV_NEWXCOR(rv) = NO			# reset
	    RV_FITDONE(rv) = YES
	} else if (streq (Memc[field], "temp")) {
	    written = true
	    if (cmd_refspec (rv, RV_TEMPLATES(rv), written) == ERR_READ)
		call rv_errmsg (rv, "Error reading new 'template' list.")
	    RV_NEWXCOR(rv) = NO			# reset
	    RV_FITDONE(rv) = YES
	} else if (streq (Memc[field], "aper")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
            if (rv_apnum_range (rv, Memc[str]) == ERR_READ)
		call rv_errmsg (rv, "Error reading new 'apertures' list.")
	} else if (streq (Memc[field], "height")) {
	    call gargr (RV_HEIGHT(rv))
	} else if (streq (Memc[field], "width")) {
	    call gargr (RV_FITWIDTH(rv))
	} else if (streq (Memc[field], "minw")) {
	    call gargr (RV_MINWIDTH(rv))
	} else if (streq (Memc[field], "maxw")) {
	    call gargr (RV_MAXWIDTH(rv))
	} else if (streq (Memc[field], "weight")) {
	    call gargr (RV_WEIGHTS(rv))
	} else if (streq (Memc[field], "back")) {
	    call gargr (RV_BACKGROUND(rv))
	} else if (streq (Memc[field], "wincenter")) {
	    call gargr (rval)
	    if (rval != RV_WINCENPAR(rv)) {
	    	RV_WINCENPAR(rv) = rval
	        call rv_gwindow (rv, NO, ival, npts)
	    }
	} else if (streq (Memc[field], "window")) {
	    call gargr (rval)
	    if (rval != RV_WINDOW(rv)) {
	    	RV_WINPAR(rv) = rval
	        call rv_gwindow (rv, NO, ival, ival)
	    }
	} else if (streq (Memc[field], "apodize")) {
	    call gargr (RV_APODIZE(rv))
       	} else if (streq (Memc[field], "osamp")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    if (streq (Memc[str], "*"))
		ORCOUNT(rv) = ALL_SPECTRUM
	    else
	        ival = rv_load_sample (RV_OSAMPLE(rv), Memc[str])
	} else if (streq (Memc[field], "tsamp")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    if (streq (Memc[str], "*"))
		RRCOUNT(rv) = ALL_SPECTRUM
	    else
	        ival = rv_load_sample (RV_RSAMPLE(rv), Memc[str])
       	} else if (streq (Memc[field], "log")) {
	    call cmd_output (rv)
	} else if (streq (Memc[field], "peak")) {
	    call gargb (bval)
	    RV_PEAK(rv) = btoi(bval)
       	} else if (streq (Memc[field], "pixcor")) {
	    call gargb (bval)
	    RV_PIXCORR(rv) = btoi(bval)
	} else if (streq (Memc[field], "awrite")) {
	    call gargb (bval)
	    RV_AUTOWRITE(rv) = btoi(bval)
       	} else if (streq (Memc[field], "adraw")) {
	    call gargb (bval)
	    RV_AUTODRAW(rv) = btoi(bval)
	} else if (streq (Memc[field], "imupdt")) {
	    call gargb (bval)
	    RV_IMUPDATE(rv) = btoi(bval)
       	} else if (streq (Memc[field], "func")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    RV_FITFUNC(rv) = cod_fitfunc (Memc[str])
	} else if (streq (Memc[field], "cont")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    RV_VERBOSE(rv) = cod_which (Memc[str])
       	} else if (streq (Memc[field], "filt")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    RV_VERBOSE(rv) = cod_which (Memc[str])
	} else if (streq (Memc[field], "rebin")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    RV_REBIN(rv) = cod_rebin (Memc[str])
	} else if (streq (Memc[field], "verb")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    RV_VERBOSE(rv) = cod_verbose (Memc[str])
	} else if (streq (Memc[field], "ccf")) {
	    call gargstr (Memc[str], SZ_LINE)
	    while (IS_WHITE(Memc[str]))
		str = str + 1
	    if (Memc[str] == 't')
		RV_CCFTYPE(rv) = OUTPUT_TEXT
	    else if (Memc[str] == 'i')
		RV_CCFTYPE(rv) = OUTPUT_IMAGE
	}

	call sfree (sp)
end


# UI_KEYWSET - Set a KEYWPARS pset parameter without "doing" anything else.

procedure ui_keywset (rv)

pointer rv                              #I RV struct pointer

pointer	sp, field, str
bool	streq()

begin
	call smark (sp)
	call salloc (str, LEN_KEYWEL, TY_CHAR)
	call salloc (field, SZ_LINE, TY_CHAR)

	call gargwrd (Memc[field], SZ_LINE)
	call gargstr (Memc[str], LEN_KEYWEL)

        if (streq(Memc[field], "ra")) {
	    call strcpy (Memc[str+1], KW_RA(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "dec")) {
	    call strcpy (Memc[str+1], KW_DEC(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "ut")) {
	    call strcpy (Memc[str+1], KW_UT(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "utmiddle")) {
	    call strcpy (Memc[str+1], KW_UTMID(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "exptime")) {
	    call strcpy (Memc[str+1], KW_EXPTIME(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "epoch")) {
	    call strcpy (Memc[str+1], KW_EPOCH(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "date_obs")) {
	    call strcpy (Memc[str+1], KW_DATE_OBS(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "hjd")) {
	    call strcpy (Memc[str+1], KW_HJD(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "mjd_obs")) {
	    call strcpy (Memc[str+1], KW_MJD_OBS(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "vobs")) {
	    call strcpy (Memc[str+1], KW_VOBS(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "vrel")) {
	    call strcpy (Memc[str+1], KW_VREL(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "vhelio")) {
	    call strcpy (Memc[str+1], KW_VHELIO(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "vlsr")) {
	    call strcpy (Memc[str+1], KW_VLSR(rv), LEN_KEYWEL)
        } else if (streq(Memc[field], "vsun")) {
	    call strcpy (Memc[str+1], KW_VSUN(rv), LEN_KEYWEL)
	}

	call sfree (sp)
end


# UI_FILTSET - Set a FILTPARS pset parameter without "doing" anything else.

procedure ui_filtset (rv)

pointer rv                              #I RV struct pointer

pointer	sp, field, str
int	cod_which(), cod_filttype()
bool	streq()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)
	call salloc (field, SZ_LINE, TY_CHAR)

	call gargwrd (Memc[field], SZ_LINE)

	if (streq(Memc[field], "option")) {
	    call gargstr (Memc[str], SZ_FNAME)
	    RV_FILTER(rv) = cod_which (Memc[str+1])
	} else if (streq(Memc[field], "type")) {
	    call gargstr (Memc[str], SZ_FNAME)
            RVF_FILTTYPE(rv) = cod_filttype (Memc[str+1])
	} else if (streq(Memc[field], "cuton")) {
	    call gargi (RVF_CUTON(rv))
	} else if (streq(Memc[field], "cutoff")) {
	    call gargi (RVF_CUTOFF(rv))
	} else if (streq(Memc[field], "fullon")) {
	    call gargi (RVF_FULLON(rv))
	} else if (streq(Memc[field], "fulloff")) {
	    call gargi (RVF_FULLOFF(rv))
	}

	call sfree (sp)
end


# UI_FMOPSET - Set the FFT mode plot options without "doing" anything else.

procedure ui_fmopset (rv)

pointer rv                              #I RV struct pointer

pointer sp, field, str
bool    streq()

begin
        call smark (sp)
        call salloc (str, SZ_FNAME, TY_CHAR)
        call salloc (field, SZ_LINE, TY_CHAR)

        call gargwrd (Memc[field], SZ_LINE)

        if (streq(Memc[field], "which")) {
            call gargstr (Memc[str], SZ_FNAME)
	    if (streq(Memc[str+1],"obj")) {
		RVP_ONE_IMAGE(rv) = OBJECT_SPECTRUM
		RVP_SPLIT_PLOT(rv) = SINGLE_PLOT
	    } else if (streq(Memc[str+1],"temp")) {
		RVP_ONE_IMAGE(rv) = REFER_SPECTRUM
		RVP_SPLIT_PLOT(rv) = SINGLE_PLOT
	    } else
		RVP_SPLIT_PLOT(rv) = SPLIT_PLOT
        } else if (streq(Memc[field], "overlay")) {
            call gargstr (Memc[str], SZ_FNAME)
	    if (streq(Memc[str+1],"on"))
                RVP_OVERLAY(rv) = YES
	    else
                RVP_OVERLAY(rv) = NO
        } else if (streq(Memc[field], "logscale")) {
            call gargstr (Memc[str], SZ_FNAME)
	    if (streq(Memc[str+1],"log"))
                RVP_LOG_SCALE(rv) = YES
	    else
                RVP_LOG_SCALE(rv) = NO
        } else if (streq(Memc[field], "zoom")) {
            call gargr (RVP_FFT_ZOOM(rv))
        }

        call sfree (sp)
end


# UI_CONTSET - Set a CONTINPARS pset parameter without "doing" anything else.

procedure ui_contset (rv)

pointer rv                              #I RV struct pointer

pointer sp, field, str
int	btoi(), cod_cninterp()
bool    bval, streq()

begin
        call smark (sp)
        call salloc (str, SZ_FNAME, TY_CHAR)
        call salloc (field, SZ_LINE, TY_CHAR)

        call gargwrd (Memc[field], SZ_LINE)

        if (streq(Memc[field], "fitfunc")) {
            call gargstr (Memc[str], SZ_FNAME)
	    CON_CNFUNC(rv) = cod_cninterp (Memc[str+1])
        } else if (streq(Memc[field], "order")) {
	    call gargi (CON_ORDER(rv))
        } else if (streq(Memc[field], "grow")) {
	    call gargr (CON_GROW(rv))
        } else if (streq(Memc[field], "markrej")) {
	    call gargb (bval)
	    CON_MARKREJ(rv) = btoi(bval)
        } else if (streq(Memc[field], "naverage")) {
	    call gargi (CON_NAVERAGE(rv))
        } else if (streq(Memc[field], "niter")) {
	    call gargi (CON_NITERATE(rv))
        } else if (streq(Memc[field], "lowrej")) {
	    call gargr (CON_LOWREJECT(rv))
        } else if (streq(Memc[field], "hirej")) {
	    call gargr (CON_HIGHREJECT(rv))
        } else if (streq(Memc[field], "samples")) {
            call gargstr (Memc[str], SZ_FNAME)
            call strcpy (Memc[str+1], Memc[CON_SAMPLE(rv)], SZ_LINE)
        }

        call sfree (sp)
end
