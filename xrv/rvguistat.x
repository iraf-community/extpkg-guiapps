include "rvflags.h"
include "rvpackage.h"
include "rvkeywords.h"
include "rvfilter.h"
include "rvplots.h"
include "rvcont.h"


define	SZ_PARLIST	1024


# RV_GUI_STAT - Send the GUI the current status of the requested parameters.

procedure rv_gui_stat (rv, pname)

pointer rv              		#I RV struct pointer
char    pname[ARB]     			#I Parameter set name

pointer	gp
pointer sp, guipar, parlist, str
int     strfd

bool    streq()
int     stropen()

begin
	gp = RV_GP(rv)
        if (gp == NULL)
            return

        call smark (sp)
        call salloc (parlist, SZ_PARLIST, TY_CHAR)
        call salloc (guipar, SZ_LINE, TY_CHAR)
        call salloc (str, SZ_LINE, TY_CHAR)

        strfd = stropen (Memc[parlist], SZ_PARLIST, NEW_FILE) 

	# Now construct the parameter list for the requested set.
	if (streq (pname, "fxcor")) {
	    call rv_task_stat (rv, strfd)
	    call strcpy ("fxcorPars", Memc[guipar], SZ_LINE)
	} else if (streq (pname, "keywpars")) {
	    call rv_keyw_stat (rv, strfd)
	    call strcpy ("keywPars", Memc[guipar], SZ_LINE)
	} else if (streq (pname, "filtpars")) {
	    call rv_filt_stat (rv, strfd)
	    call strcpy ("filtPars", Memc[guipar], SZ_LINE)
	} else if (streq (pname, "fmodepars")) {
	    call rv_fmode_stat (rv, strfd)
	    call strcpy ("fmodePars", Memc[guipar], SZ_LINE)
	} else if (streq (pname, "contpars")) {
	    call rv_cont_stat (rv)
	    call strclose (strfd)
	    call sfree (sp)
	    return
	}

        call fprintf (strfd, " ")
        call strclose (strfd)

        call gmsg (gp, Memc[guipar], Memc[parlist])

        call sfree (sp)
end


# RV_TASK_STAT - Construct a list of task parameters to be sent to the GUI.

procedure rv_task_stat (rv, fd)

pointer rv                              #I RV struct pointer
int    fd                    		#I file descriptor of parameter list

pointer sp, str
bool	itob()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	if (RV_OBJECTS(rv) != NULL) {
            call fprintf (fd, " { objects  %s }")
                call pargstr (IMAGE(rv))
	}
	if (RV_TEMPLATES(rv) != NULL) {
            call fprintf (fd, " { templates  %s }")
                call pargstr (RIMAGE(rv))
	}
	if (RV_APPARAM(rv) != NULL) {
            call fprintf (fd, " { apertures  %s }")
                call pargstr (APPARAM(rv))
	}

        call fprintf (fd, " { continuum  %s }")
	    call nam_which (RV_CONTINUUM(rv), Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { filter  %s }")
	    call nam_which (RV_FILTER(rv), Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { rebin  %s }")
	    call nam_rebin (rv, Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { pixcorr  %b }")
            call pargb (itob(RV_PIXCORR(rv)))
        call fprintf (fd, " { osample  %s }")
	    call rv_make_range_string (RV_OSAMPLE(rv), Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { rsample  %s }")
	    call rv_make_range_string (RV_RSAMPLE(rv), Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { apodize  %g }")
            call pargr (RV_APODIZE(rv))
        call fprintf (fd, " { function  %s }")
	    call nam_fitfunc (rv, Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { width  %g }")
            call pargr (RV_FITWIDTH(rv))
        call fprintf (fd, " { height  %g }")
            call pargr (RV_FITHGHT(rv))
        call fprintf (fd, " { peak  %b }")
            call pargb (itob(RV_PEAK(rv)))
        call fprintf (fd, " { minwidth  %g }")
            call pargr (RV_MINWIDTH(rv))
        call fprintf (fd, " { maxwidth  %g }")
            call pargr (RV_MAXWIDTH(rv))
        call fprintf (fd, " { weights  %g }")
            call pargr (RV_WEIGHTS(rv))
        call fprintf (fd, " { background  %g }")
            call pargr (RV_BACKGROUND(rv))
        call fprintf (fd, " { window  %g }")
            call pargr (RV_WINPAR(rv))
        call fprintf (fd, " { wincenter  %g }")
            call pargr (RV_WINCENPAR(rv))
        call fprintf (fd, " { output  %s }")
            call pargstr (SPOOL(rv))
        call fprintf (fd, " { verbose  %s }")
	    call nam_verbose (rv, Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { imupdate  %b }")
            call pargb (itob(RV_IMUPDATE(rv)))
        call fprintf (fd, " { autowrite  %b }")
            call pargb (itob(RV_AUTOWRITE(rv)))
        call fprintf (fd, " { autodraw  %b }")
            call pargb (itob(RV_AUTODRAW(rv)))
        call fprintf (fd, " { ccftype  %s }")
	    if (RV_CCFTYPE(rv) == OUTPUT_IMAGE)
                call pargstr ("image")
	    else
                call pargstr ("text")

	call sfree (sp)
end


# RV_KEYW_STAT - Construct a list of KEYWPARS parameters to be sent to the GUI.

procedure rv_keyw_stat (rv, fd)

pointer rv                              #I RV struct pointer
int    fd                    		#I file descriptor of parameter list

begin
        # Print the keyword translation info
        call fprintf (fd, " { ra  %s }")
            call pargstr (KW_RA(rv))
        call fprintf (fd, " { dec  %s }")
            call pargstr (KW_DEC(rv))
        call fprintf (fd, " { ut  %s }")
            call pargstr (KW_UT(rv))
        call fprintf (fd, " { utmiddle  %s }")
            call pargstr (KW_UTMID(rv))
        call fprintf (fd, " { exptime  %s }")
            call pargstr (KW_EXPTIME(rv))
        call fprintf (fd, " { epoch  %s }")
            call pargstr (KW_EPOCH(rv))
        call fprintf (fd, " { date_obs  %s }")
            call pargstr (KW_DATE_OBS(rv))
        call fprintf (fd, " { hjd  %s }")
            call pargstr (KW_HJD(rv))
        call fprintf (fd, " { mjd_obs  %s }")
            call pargstr (KW_MJD_OBS(rv))
        call fprintf (fd, " { vobs  %s }")
            call pargstr (KW_VOBS(rv))
        call fprintf (fd, " { vrel  %s }")
            call pargstr (KW_VREL(rv))
        call fprintf (fd, " { vhelio  %s }")
            call pargstr (KW_VHELIO(rv))
        call fprintf (fd, " { vlsr  %s }")
            call pargstr (KW_VLSR(rv))
        call fprintf (fd, " { vsun  %s }")
            call pargstr (KW_VSUN(rv))
end


# RV_FILT_STAT - Construct a list of FILTPARS parameters to be sent to the GUI.

procedure rv_filt_stat (rv, fd)

pointer rv                              #I RV struct pointer
int    fd                               #I file descriptor of parameter list

pointer sp, str

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

        call fprintf (fd, " { filter  %s }")
	    call nam_which (RV_FILTER(rv), Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { filtfunc  %s }")
	    call nam_filttype (rv, Memc[str])
            call pargstr (Memc[str])
        call fprintf (fd, " { cuton  %d }")
            call pargi (RVF_CUTON(rv))
        call fprintf (fd, " { cutoff  %d }")
            call pargi (RVF_CUTOFF(rv))
        call fprintf (fd, " { fullon  %d }")
            call pargi (RVF_FULLON(rv))
        call fprintf (fd, " { fulloff  %d }")
            call pargi (RVF_FULLOFF(rv))

	call sfree (sp)
end


# RV_CONT_STAT - Construct a list of CONTPARS parameters to be sent to the GUI.

procedure rv_cont_stat (rv)

pointer rv                              #I RV struct ponter

pointer	sp, msg

begin
        call smark (sp)
        call salloc (msg, 2*SZ_LINE, TY_CHAR)

        call sprintf (Memc[msg], 2*SZ_LINE,
            "params %s %d \"%s\" %d %d %g %g %g %b")
                call pargstr (Memc[CON_FUNC(rv)])
                call pargi (CON_ORDER(rv))
                call pargstr (Memc[CON_SAMPLE(rv)])
                call pargi (CON_NAVERAGE(rv))
                call pargi (CON_NITERATE(rv))
                call pargr (CON_LOWREJECT(rv))
                call pargr (CON_HIGHREJECT(rv))
                call pargr (CON_GROW(rv))
                call pargi (CON_MARKREJ(rv))
        call gmsg (RV_GP(rv), "icfit", Memc[msg])

	call sfree (sp)
end


# RV_FMODE_STAT - Construct a list of FILTPARS parameters to be sent to the GUI.

procedure rv_fmode_stat (rv, fd)

pointer rv                              #I RV struct pointer
int    fd                               #I file descriptor of parameter list

begin
        call fprintf (fd, " { which  %d }")
            if (RVP_SPLIT_PLOT(rv) == SPLIT_PLOT)
                call pargstr ("split")
	    else if (RVP_ONE_IMAGE(rv) == OBJECT_SPECTRUM)
                call pargstr ("object")
	    else
                call pargstr ("template")
        call fprintf (fd, " { logscale  %s }")
            if (RVP_LOG_SCALE(rv) == YES)
                call pargstr ("log")
	    else
                call pargstr ("linear")
        call fprintf (fd, " { overlay  %s }")
            if (RVP_OVERLAY(rv) == YES)
                call pargstr ("on")
	    else
                call pargstr ("off")
        call fprintf (fd, " { zoom  %g }")
            call pargr (RVP_FFT_ZOOM(rv))
end


# RV_PPSTR - Set a GUI parameter with an string variable.

procedure rv_ppstr (gp, param, str, guipar)

pointer	gp					#I graphics descriptor
char	param[ARB]				#I parameter name
char	str[ARB]				#I value to set
char	guipar[ARB]				#I UI parameter to notify

char	buf[SZ_LINE]

begin
	call sprintf (buf, SZ_LINE, " { %s %s } ")
	    call pargstr (param)
	    call pargstr (str)
	call gmsg (gp, guipar, buf)
end


# RV_PPARI - Set a GUI parameter with an integer variable.

procedure rv_ppari (gp, param, ival, guipar)

pointer gp                                      #I graphics descriptor
char    param[ARB]                              #I parameter name
int     ival                                    #I value to set
char    guipar[ARB]                             #I UI parameter to notify

char    buf[SZ_LINE]

begin
        call sprintf (buf, SZ_LINE, " { %s %d } ")
            call pargstr (param)
            call pargi (ival)
        call gmsg (gp, guipar, buf)
end


# RV_PPARR - Set a GUI parameter with a real variable.

procedure rv_pparr (gp, param, rval, guipar)

pointer gp                                      #I graphics descriptor
char    param[ARB]                              #I parameter name
real    rval                                    #I value to set
char    guipar[ARB]                             #I UI parameter to notify

char    buf[SZ_LINE]

begin
        call sprintf (buf, SZ_LINE, " { %s %g } ")
            call pargstr (param)
            call pargr (rval)
        call gmsg (gp, guipar, buf)
end


# RV_PPARB - Set a GUI parameter with a boolean variable.

procedure rv_pparb (gp, param, bval, guipar)

pointer gp                                      #I graphics descriptor
char    param[ARB]                              #I parameter name
int     bval                                    #I value to set
char    guipar[ARB]                             #I UI parameter to notify

bool	itob()
char    buf[SZ_LINE]

begin
        call sprintf (buf, SZ_LINE, " { %s %b } ")
            call pargstr (param)
            call pargb (itob(bval))
        call gmsg (gp, guipar, buf)
end
