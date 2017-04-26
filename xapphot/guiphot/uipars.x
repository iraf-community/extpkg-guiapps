include <fset.h>
include <imhdr.h>
include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "../lib/contour.h"
include "../lib/surface.h"
include "uipars.h"

# XP_UIINIT -- Initialize the ui parameters structure.

procedure xp_uiinit (ui)

pointer	ui			#I the ui parameters structure

begin
	call calloc (ui, LEN_UI_STRUCT, TY_STRUCT)

	call strcpy ("ustartdir", UI_STARTDIRSTR(ui), SZ_UIPARAM)
	call strcpy ("ucurdir", UI_CURDIRSTR(ui), SZ_UIPARAM)
	call strcpy ("udirliststr", UI_DIRLISTSTR(ui), SZ_UIPARAM)

	call strcpy ("uimtemplatestr", UI_IMTEMPLATESTR(ui), SZ_UIPARAM)
	call strcpy ("uimliststr", UI_IMLISTSTR(ui), SZ_UIPARAM)
	call strcpy ("uimno", UI_IMNO(ui), SZ_UIPARAM)

	call strcpy ("uoftemplatestr", UI_OFTEMPLATESTR(ui), SZ_UIPARAM)
	call strcpy ("uolliststr", UI_OLLISTSTR(ui), SZ_UIPARAM)
	call strcpy ("uofno", UI_OFNO(ui), SZ_UIPARAM)

	call strcpy ("urftemplatestr", UI_RFTEMPLATESTR(ui), SZ_UIPARAM)
	call strcpy ("urffile", UI_RFFILE(ui), SZ_UIPARAM)
	call strcpy ("urfno", UI_RFNO(ui), SZ_UIPARAM)

	call strcpy ("ugftemplatestr", UI_GFTEMPLATESTR(ui), SZ_UIPARAM)
	call strcpy ("ugffile", UI_GFFILE(ui), SZ_UIPARAM)
	call strcpy ("ugfno", UI_GFNO(ui), SZ_UIPARAM)

	call strcpy ("ufiles", UI_FILES(ui), SZ_UIPARAM)
	call strcpy ("uheader", UI_HEADER(ui), SZ_UIPARAM)
	call strcpy ("uhdrlist", UI_HDRLIST(ui), SZ_UIPARAM)

	call strcpy ("uobjno", UI_OBJNO(ui), SZ_UIPARAM)
	call strcpy ("uobjects", UI_OBJECTS(ui), SZ_UIPARAM)
	call strcpy ("uobjlist", UI_OBJLIST(ui), SZ_UIPARAM)
	call strcpy ("uobjmarker", UI_OBJMARKER(ui), SZ_UIPARAM)

	call strcpy ("uimpars", UI_IMPARS(ui), SZ_UIPARAM)
	call strcpy ("udispars", UI_DISPARS(ui), SZ_UIPARAM)
	call strcpy ("ufindpars", UI_FINDPARS(ui), SZ_UIPARAM)
	call strcpy ("uomarkpars", UI_OMARKPARS(ui), SZ_UIPARAM)
	call strcpy ("ucenpars", UI_CENPARS(ui), SZ_UIPARAM)
	call strcpy ("uskypars", UI_SKYPARS(ui), SZ_UIPARAM)
	call strcpy ("uphotpars", UI_PHOTPARS(ui), SZ_UIPARAM)
	call strcpy ("ueplotpars", UI_EPLOTPARS(ui), SZ_UIPARAM)
	call strcpy ("uaplotpars", UI_APLOTPARS(ui), SZ_UIPARAM)

	call strcpy ("ulogresults", UI_LOGRESULTS(ui), SZ_UIPARAM)
	call strcpy ("uresults", UI_RESULTS(ui), SZ_UIPARAM)
	call strcpy ("upbanner", UI_PBANNER(ui), SZ_UIPARAM)
	call strcpy ("uptable", UI_PTABLE(ui), SZ_UIPARAM)
	call strcpy ("upobject", UI_POBJECT(ui), SZ_UIPARAM)

	call strcpy ("uppolygon", UI_PPOLYGON(ui), SZ_UIPARAM)
	call strcpy ("us1polygon", UI_S1POLYGON(ui), SZ_UIPARAM)
	call strcpy ("us2polygon", UI_S2POLYGON(ui), SZ_UIPARAM)

	call strcpy ("uplots", UI_PLOTS(ui), SZ_UIPARAM)
	call strcpy ("umplots", UI_MPLOTS(ui), SZ_UIPARAM)
	call strcpy ("ugterm", UI_GTERM(ui), SZ_UIPARAM)
	call strcpy ("ucursor", UI_CURSOR(ui), SZ_UIPARAM)

	call strcpy ("uhelp", UI_HELP(ui), SZ_UIPARAM)
	call strcpy ("uhelplist", UI_HELPLIST(ui), SZ_UIPARAM)

	call strcpy ("ututor", UI_TUTOR(ui), SZ_UIPARAM)
	call strcpy ("ututorlist", UI_TUTORLIST(ui), SZ_UIPARAM)

	call strcpy ("umredraw", UI_MREDRAW(ui), SZ_UIPARAM)
	call strcpy ("uredisplay", UI_REDISPLAY(ui), SZ_UIPARAM)
end


# XP_GUISET -- Initialize the GUI state.

procedure xp_guiset (gd, ui, xp, dirlist, imlist, objlist, reslist, greslist)

pointer	gd			#I pointer to the graphics stream
pointer ui			#I pointer to the UI parameters
pointer xp			#I pointer to the xapphot structure
int	dirlist			#I the current directory list
int	imlist			#I the current image list
int	objlist			#I the current input object file list
int	reslist			#I the current output results file list
int	greslist		#I the current output object file list

pointer	sp, str1, str2
int	access()
pointer	xp_statp()

begin
	call smark (sp)
	call salloc (str1, SZ_FNAME, TY_CHAR)
	call salloc (str2, SZ_FNAME, TY_CHAR)

	# Pass the help text to the gui.
	call clgstr ("helpfile", Memc[str1], SZ_LINE)
	call xp_mkhelp (gd, ui, Memc[str1])

	# Initialize the tutorial option.
	call clgstr ("tutorial", Memc[str1], SZ_LINE)
	if (access (Memc[str1], READ_ONLY, TEXT_FILE) == YES) {
	    call xp_mktutor (gd, ui, Memc[str1])
	    call gmsg (gd, UI_TUTOR(ui), "yes")
	} else
	    call gmsg (gd, UI_TUTOR(ui), "no")

	# Pass the directory template and the directory list, to the gui.
	call xp_stats (xp, CURDIR, Memc[str1], SZ_FNAME)
	call xp_stats (xp, STARTDIR, Memc[str2], SZ_FNAME)
	call xp_mkdlist (gd, ui, Memc[str2], Memc[str1], dirlist)

	# Pass the image template and the image list, to the gui.
	call xp_stats (xp, IMTEMPLATE, Memc[str1], SZ_FNAME)
	call xp_mkilist (gd, ui, Memc[str1], imlist)

	# Create an objects file list string and pass it to the gui.
	call xp_stats (xp, OFTEMPLATE, Memc[str1], SZ_FNAME)
	call xp_mkclist (gd, ui, Memc[str1], objlist) 

	# Create results file strings and pass them to the gui.
	call xp_stats (xp, RFTEMPLATE, Memc[str1], SZ_FNAME)
	call xp_stats (xp, GFTEMPLATE, Memc[str2], SZ_FNAME)
	call xp_mkmlist (gd, ui, Memc[str1], reslist, 1, Memc[str2],
	    greslist, 1) 

	# Pass the current algorithm parameter values to the gui.
	call xp_mkplist (gd, ui, xp)

	# Pass the results banner to the GUI
	call xp_mkbanner (gd, ui, xp)

	# Pass the log results pstatus to the GUI.
	if (LOGRESULTS(xp_statp(xp,PSTATUS)) == YES)
	    call gmsg (gd, UI_LOGRESULTS(ui), "yes")
	else
	    call gmsg (gd, UI_LOGRESULTS(ui), "no")

	# Initialize the help facility.
	call gmsg (gd, UI_HELP(ui), "no")
	UI_SHOWHELP(ui) = NO

	# Intialize the files display facility.
	UI_SHOWFILES(ui) = NO
	call gmsg (gd, UI_FILES(ui), "no")

	# Initialize the image header display pstatus.
	UI_SHOWHEADER(ui) = NO
	call gmsg (gd, UI_HEADER(ui), "no")

	# Initialize the model plotting option.
	UI_SHOWMPLOTS(ui) = NO
	call gmsg (gd, UI_MPLOTS(ui), "no")

	# Initialize the object list and marker display pstatus.
	UI_SHOWOBJLIST(ui) = NO
	call gmsg (gd, UI_OBJECTS(ui), "no")
	call gmsg (gd, UI_OBJMARKER(ui), "INDEF")

	# Initialize table.
	UI_SHOWPTABLE(ui) = NO
	call gmsg (gd, UI_RESULTS(ui), "no")

	# Initialize the plots.
	UI_SHOWPLOTS(ui) = NO
	call gmsg (gd, UI_PLOTS(ui), "no")
	UI_OBJDISPLAY(ui) = OBJPLOT_APERTURE
	UI_OBJPLOTS(ui) = OBJPLOT_RADIUS
	UI_SKYDISPLAY(ui) = SKYPLOT_APERTURE
	UI_SKYPLOTS(ui) = SKYPLOT_HISTOGRAM

	call xp_gsapoly (gd, ui, xp)

	call gmsg (gd, UI_REDISPLAY(ui), "no")

	call sfree (sp)
end


# XP_MKHELP -- Send the help document to the GUI

procedure xp_mkhelp (gd, ui, helpfile)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char	helpfile[ARB]		#I the input help file

int	fd, strfd, maxch
pointer	sp, line, helpstr
int	open(), stropen(), getline()
long	fstatl()

begin
        if (gd == NULL)
            return

	fd = open (helpfile, READ_ONLY, TEXT_FILE)
	maxch = fstatl (fd, F_FILESIZE)

	call smark (sp)
	call salloc (line, SZ_LINE, TY_CHAR)
	call salloc (helpstr, maxch, TY_CHAR)
	strfd = stropen (Memc[helpstr], maxch, NEW_FILE)
	while (getline (fd, Memc[line]) != EOF)
	    call putline (strfd, Memc[line])
	call strclose (strfd)

	call close (fd)

        call gmsg (gd, UI_HELPLIST(ui), Memc[helpstr])
	call sfree (sp)
end


# XP_MKTUTOR -- Send the help document to the GUI

procedure xp_mktutor (gd, ui, tutorfile)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char	tutorfile[ARB]		#I the input tutorial file

int	fd, strfd, maxch
pointer	sp, line, tutorstr
int	open(), stropen(), getline()
long	fstatl()

begin
        if (gd == NULL)
            return

	fd = open (tutorfile, READ_ONLY, TEXT_FILE)
	maxch = fstatl (fd, F_FILESIZE)

	call smark (sp)
	call salloc (line, SZ_LINE, TY_CHAR)
	call salloc (tutorstr, maxch, TY_CHAR)
	strfd = stropen (Memc[tutorstr], maxch, NEW_FILE)
	while (getline (fd, Memc[line]) != EOF)
	    call putline (strfd, Memc[line])
	call strclose (strfd)

	call close (fd)

        call gmsg (gd, UI_TUTORLIST(ui), Memc[tutorstr])
	call sfree (sp)
end


# XP_MKDLIST -- Create a directory list string that can be passed to the
# server.

procedure xp_mkdlist (gd, ui, startdir, curdir, dirlist)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char    startdir[ARB]           #I the starting directory
char    curdir[ARB]             #I the current directory
int     dirlist                 #I the directory list descriptor

int	i, len_dirliststr, strfd
pointer	sp, dirliststr, dir
int	fntlenb(), stropen(), fntrfnb()

begin
        if (gd == NULL)
            return

        call gmsg (gd, UI_STARTDIRSTR(ui), startdir)
        call gmsg (gd, UI_CURDIRSTR(ui), curdir)

        len_dirliststr = fntlenb (dirlist) * SZ_FNAME + 1
        call smark (sp)
        call salloc (dirliststr, len_dirliststr, TY_CHAR)
        call salloc (dir, SZ_FNAME, TY_CHAR)

        Memc[dirliststr] = EOS
        strfd = stropen (Memc[dirliststr], len_dirliststr, NEW_FILE)
        do i = 1, fntlenb (dirlist) {
            if (fntrfnb (dirlist, i, Memc[dir], SZ_FNAME) != EOF) {
                call fprintf (strfd, "%s\n")
                    call pargstr (Memc[dir])
	    }
        }
        call close (strfd)

        call gmsg (gd, UI_DIRLISTSTR(ui), Memc[dirliststr])

	call sfree (sp)
end


# XP_MKILIST -- Create an image list string that can be passed to the
# server.

procedure xp_mkilist (gd, ui, images, imlist)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char    images[ARB]             #I the image template
int     imlist                  #I the image list descriptor

int     i, len_imliststr, strfd
pointer sp, image, imliststr
int     imtlen(), stropen(), imtrgetim()

begin
        if (gd == NULL)
            return

        call gmsg (gd, UI_IMTEMPLATESTR(ui), images)

        len_imliststr = imtlen (imlist) * SZ_FNAME + 1
        call smark (sp)
        call salloc (imliststr, len_imliststr, TY_CHAR)
        call salloc (image, SZ_FNAME, TY_CHAR)

        Memc[imliststr] = EOS
        strfd = stropen (Memc[imliststr], len_imliststr, NEW_FILE)
        do i = 1, imtlen (imlist) {
            if (imtrgetim (imlist, i, Memc[image], SZ_FNAME) != EOF) {
                call fprintf (strfd, "%s\n")
                    call pargstr (Memc[image])
            }
        }
        call close (strfd)

        call gmsg (gd, UI_IMLISTSTR(ui), Memc[imliststr])

        call sfree (sp)
end


# XP_MKCLIST -- Create an objects files list string that can be passed to the
# server.

procedure xp_mkclist (gd, ui, objects, objlist)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char    objects[ARB]            #I the objects lists template
int     objlist                 #I the objects list descriptor

int     i, len_oliststr, strfd
pointer sp, oliststr, objfile
int     fntlenb(), stropen(), fntrfnb()

begin
        if (gd == NULL)
            return

        call gmsg (gd, UI_OFTEMPLATESTR(ui), objects)

        len_oliststr = fntlenb (objlist) * SZ_FNAME + 1
        call smark (sp)
        call salloc (oliststr, len_oliststr, TY_CHAR)
        call salloc (objfile, SZ_FNAME, TY_CHAR)

        Memc[oliststr] = EOS
        strfd = stropen (Memc[oliststr], len_oliststr, NEW_FILE)
        do i = 1, fntlenb (objlist) {
            if (fntrfnb (objlist, i, Memc[objfile], SZ_FNAME) != EOF) {
                call fprintf (strfd, "%s\n")
                    call pargstr (Memc[objfile])
            }
        }
        call close (strfd)

        call gmsg (gd, UI_OLLISTSTR(ui), Memc[oliststr])
        call sfree (sp)
end


# XP_MKMLIST -- Sends the results file templates and the current file
# names to the GUI.

procedure xp_mkmlist (gd, ui, results, reslist, rlno, gresults, greslist, glno)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
char    results[ARB]            #I the results lists template
int     reslist                 #I the results list descriptor
int	rlno			#I the current results file number
char    gresults[ARB]           #I the output objects lists template
int     greslist                #I the output objects list descriptor
int	glno			#I the current output objects file number

pointer sp, str
int     fntrfnb()

begin
        if (gd == NULL)
            return

        call gmsg (gd, UI_RFTEMPLATESTR(ui), results)
        call gmsg (gd, UI_GFTEMPLATESTR(ui), gresults)

        call smark (sp)
        call salloc (str, SZ_FNAME, TY_CHAR)

        if (fntrfnb (reslist, rlno, Memc[str], SZ_FNAME) == EOF)
	    Memc[str] = EOS
        call gmsg (gd, UI_RFFILE(ui), Memc[str])
        call gmsgi (gd, UI_RFNO(ui), rlno)
        if (fntrfnb (greslist, glno, Memc[str], SZ_FNAME) == EOF)
	    Memc[str] = EOS
        call gmsg (gd, UI_GFFILE(ui), Memc[str])
        call gmsgi (gd, UI_GFNO(ui), glno)

        call sfree (sp)
end


# XP_MKPLIST -- Pass the current parameter values to the gui.

procedure xp_mkplist (gd, ui, xp)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer xp                      #I pointer to the main xapphot structure

begin
        call xp_iguipars (gd, ui, xp)
        call xp_dguipars (gd, ui, xp)
        call xp_fguipars (gd, ui, xp)
        call xp_oguipars (gd, ui, xp)
        call xp_cguipars (gd, ui, xp)
        call xp_sguipars (gd, ui, xp)
        call xp_pguipars (gd, ui, xp)
        call xp_eguipars (gd, ui, xp)
        call xp_aguipars (gd, ui, xp)
end


# XP_DGUIPARS -- Construct a list of image display parameters to pass
# to the GUI.

procedure xp_dguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, dparlist, str
bool	itob()
int	stropen(), xp_stati(), xp_strwrd()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NDISPLAYPARS * MAX_SZDISPLAYPAR + 1
	call smark (sp)
	call salloc (dparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[dparlist], maxch, NEW_FILE) 

	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("derase")
	    call pargb (itob (xp_stati (xp, DERASE)))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("dfill")
	    call pargb (itob (xp_stati (xp, DFILL)))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dxviewport")
	    call pargr (xp_statr (xp, DXVIEWPORT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dyviewport")
	    call pargr (xp_statr (xp, DYVIEWPORT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dxmag")
	    call pargr (xp_statr (xp, DXMAG))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dymag")
	    call pargr (xp_statr (xp, DYMAG))
	if (xp_strwrd (xp_stati (xp, DZTRANS), Memc[str], SZ_FNAME,
	    DZTRANS_OPTIONS) <= 0)
	    call strcpy ("linear", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("dztransform")
	    call pargstr (Memc[str])
	if (xp_strwrd (xp_stati (xp, DZLIMITS), Memc[str], SZ_FNAME,
	    DZLIMITS_OPTIONS) <= 0)
	    call strcpy ("median", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("dzlimits")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dzcontrast")
	    call pargr (xp_statr (xp, DZCONTRAST))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("dznsample")
	    call pargi (xp_stati (xp, DZNSAMPLE))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dz1")
	    call pargr (xp_statr (xp, DZ1))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("dz2")
	    call pargr (xp_statr (xp, DZ2))
	call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("dlutfile")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("drepeat")
	    call pargb (itob (xp_stati (xp, DREPEAT)))

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_DISPARS(ui), Memc[dparlist])

	call sfree (sp)
end


# XP_IGUIPARS -- Construct a list of image parameters to pass to the GUI.

procedure xp_iguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, iparlist, str
bool	itob()
int	stropen(), xp_stati()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NIMPARS * MAX_SZIMPAR + 1
	call smark (sp)
	call salloc (iparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[iparlist], maxch, NEW_FILE) 

	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("iscale")
	    call pargr (1.0 / xp_statr (xp, ISCALE))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ihwhmpsf")
	    call pargr (xp_statr (xp, IHWHMPSF))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("iemission")
	    call pargb (itob (xp_stati (xp, IEMISSION)))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("iskysigma")
	    call pargr (xp_statr (xp, ISKYSIGMA))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("imindata")
	    call pargr (xp_statr (xp, IMINDATA))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("imaxdata")
	    call pargr (xp_statr (xp, IMAXDATA))

	call xp_stats (xp, INSTRING, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("inoisemodel")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKREADNOISE, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikreadnoise")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKGAIN, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikgain")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ireadnoise")
	    call pargr (xp_statr (xp, IREADNOISE))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("igain")
	    call pargr (xp_statr (xp, IGAIN))

	call xp_stats (xp, IKEXPTIME, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikexptime")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKAIRMASS, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikairmass")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKFILTER, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikfilter")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKOBSTIME, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ikobstime")
	    call pargstr (Memc[str])

	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ietime")
	    call pargr (xp_statr (xp, IETIME))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("iairmass")
	    call pargr (xp_statr (xp, IAIRMASS))
	call xp_stats (xp, IFILTER, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ifilter")
	    call pargstr (Memc[str])
	call xp_stats (xp, IOTIME, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("iotime")
	    call pargstr (Memc[str])

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_IMPARS(ui), Memc[iparlist])

	call sfree (sp)
end


# XP_EGUIPARS -- Construct a list of contour plotting parameters to pass
# to the GUI.

procedure xp_eguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, cpparlist, str
bool	itob()
int	stropen(), xp_stati(), xp_strwrd()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NCONTOURPARS * MAX_SZCONTOURPAR + 1
	call smark (sp)
	call salloc (cpparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[cpparlist], maxch, NEW_FILE) 

	call fprintf (strfd, "{ %s  %d }")
	    call pargstr ("enx")
	    call pargi (xp_stati (xp, ENX))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("eny")
	    call pargi (xp_stati (xp, ENY))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ez1")
	    call pargr (xp_statr (xp, EZ1))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ez2")
	    call pargr (xp_statr (xp, EZ2))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("ez0")
	    call pargr (xp_statr (xp, EZ0))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("encontours")
	    call pargi (xp_stati (xp, ENCONTOURS))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("edz")
	    call pargr (xp_statr (xp, EDZ))
	if (xp_strwrd (xp_stati (xp, EHILOMARK), Memc[str], SZ_FNAME,
	    EHILOMARK_OPTIONS) <= 0)
	    call strcpy ("none", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ehilomark")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("edashpat")
	    call pargi (xp_stati (xp, EDASHPAT))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("elabel")
	    call pargb (itob (xp_stati (xp, ELABEL)))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("ebox")
	    call pargb (itob (xp_stati (xp, EBOX)))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("eticklabel")
	    call pargb (itob (xp_stati (xp, ETICKLABEL)))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("exmajor")
	    call pargi (xp_stati (xp, EXMAJOR))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("exminor")
	    call pargi (xp_stati (xp, EXMINOR))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("eymajor")
	    call pargi (xp_stati (xp, EYMAJOR))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("eyminor")
	    call pargi (xp_stati (xp, EYMINOR))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("eround")
	    call pargb (itob (xp_stati (xp, EROUND)))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("efill")
	    call pargb (itob (xp_stati (xp, EFILL)))

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_EPLOTPARS(ui), Memc[cpparlist])

	call sfree (sp)
end


# XP_AGUIPARS -- Construct a list of surface plotting parameters to pass
# to the GUI.

procedure xp_aguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, apparlist, str
bool	itob()
int	stropen(), xp_stati()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NSURFACEPARS * MAX_SZSURFACEPAR + 1
	call smark (sp)
	call salloc (apparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[apparlist], maxch, NEW_FILE) 

	call fprintf (strfd, "{ %s  %d }")
	    call pargstr ("anx")
	    call pargi (xp_stati (xp, ASNX))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("any")
	    call pargi (xp_stati (xp, ASNY))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("az1")
	    call pargr (xp_statr (xp, AZ1))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("az2")
	    call pargr (xp_statr (xp, AZ2))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("alabel")
	    call pargb (itob (xp_stati (xp, ALABEL)))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("angv")
	    call pargr (xp_statr (xp, ANGV))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("angh")
	    call pargr (xp_statr (xp, ANGH))

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_APLOTPARS(ui), Memc[apparlist])

	call sfree (sp)
end


# XP_OGUIPARS -- Construct a list of the objects list parameters to pass to the
# GUI.

procedure xp_oguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, oparlist, str
bool	itob()
int	stropen(), xp_stati(), xp_strwrd()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NOBJECTPARS * MAX_SZOBJECTPAR + 1
	call smark (sp)
	call salloc (oparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[oparlist], maxch, NEW_FILE) 

	call fprintf (strfd, " { %s  %b }")
            call pargstr ("objmark")
            call pargb (itob (xp_stati (xp, OBJMARK)))
        call fprintf (strfd, " { %s  %g }")
            call pargstr ("otolerance")
            call pargr (xp_statr (xp, OTOLERANCE))
        if (xp_strwrd (xp_stati (xp, OCHARMARK), Memc[str], SZ_FNAME,
            OMARKERS) <= 0)
            call strcpy ("plus", Memc[str], SZ_FNAME)
        call fprintf (strfd, " { %s  %s }")
            call pargstr ("ocharmark")
            call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %b }")
            call pargstr ("onumber")
            call pargb (itob (xp_stati (xp, ONUMBER)))
        if (xp_strwrd (xp_stati (xp, OPCOLORMARK), Memc[str], SZ_FNAME,
            OCOLORS) <= 0)
            call strcpy ("green", Memc[str], SZ_FNAME)
        call fprintf (strfd, " { %s  %s }")
            call pargstr ("opcolormark")
            call pargstr (Memc[str])
        if (xp_strwrd (xp_stati (xp, OSCOLORMARK), Memc[str], SZ_FNAME,
            OCOLORS) <= 0)
            call strcpy ("blue", Memc[str], SZ_FNAME)
        call fprintf (strfd, " { %s  %s }")
            call pargstr ("oscolormark")
            call pargstr (Memc[str])
        call fprintf (strfd, " { %s  %g }")
            call pargstr ("osizemark")
            call pargr (xp_statr (xp, OSIZEMARK))
        call fprintf (strfd, " ")

	call strclose (strfd)

	call gmsg (gd, UI_OMARKPARS(ui), Memc[oparlist])

	call sfree (sp)
end


# XP_CGUIPARS -- Construct a list of the centering parameters to pass to the
# GUI.

procedure xp_cguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, cparlist, str
bool	itob()
int	stropen(), xp_stati(), xp_strwrd()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NCENTERPARS * MAX_SZCENTERPAR + 1
	call smark (sp)
	call salloc (cparlist, maxch, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	strfd = stropen (Memc[cparlist], maxch, NEW_FILE) 

	call xp_stats (xp, CSTRING, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("calgorithm")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("cradius")
	    call pargr (xp_statr (xp, CRADIUS))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("cthreshold")
	    call pargr (xp_statr (xp, CTHRESHOLD))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("cminsnratio")
	    call pargr (xp_statr (xp, CMINSNRATIO))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("cmaxiter")
	    call pargi (xp_stati (xp, CMAXITER))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("cxyshift")
	    call pargr (xp_statr (xp, CXYSHIFT))

	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("ctrmark")
	    call pargb (itob (xp_stati (xp, CTRMARK)))
	if (xp_strwrd (xp_stati (xp, CCHARMARK), Memc[str], SZ_FNAME,
	    CMARKERS) <= 0)
	    call strcpy ("plus", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ccharmark")
	    call pargstr (Memc[str])
	if (xp_strwrd (xp_stati (xp, CCOLORMARK), Memc[str], SZ_FNAME,
	    CCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("ccolormark")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("csizemark")
	    call pargr (xp_statr (xp, CSIZEMARK))

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_CENPARS(ui), Memc[cparlist])

	call sfree (sp)
end


# XP_SGUIPARS -- Construct a list of the sky fitting parameters to pass to the
# GUI.

procedure xp_sguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, sparlist, str
bool	itob()
int	stropen(), xp_strwrd(), xp_stati()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NSKYPARS * MAX_SZSKYPAR + 1
	call smark (sp)
	call salloc (sparlist, maxch, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	strfd = stropen (Memc[sparlist], maxch, NEW_FILE) 

	call xp_stats (xp, SMSTRING, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("smode")
	    call pargstr (Memc[str])
	call xp_stats (xp, SGEOSTRING, Memc[str], SZ_LINE)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("sgeometry")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("srannulus")
	    call pargr (xp_statr (xp, SRANNULUS))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("swannulus")
	    call pargr (xp_statr (xp, SWANNULUS))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("saxratio")
	    call pargr (xp_statr (xp, SAXRATIO))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("sposangle")
	    call pargr (xp_statr (xp, SPOSANGLE))

	call xp_stats (xp, SSTRING, Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("salgorithm")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("sconstant")
	    call pargr (xp_statr (xp, SCONSTANT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("shwidth")
	    call pargr (xp_statr (xp, SHWIDTH))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("shbinsize")
	    call pargr (xp_statr (xp, SHBINSIZE))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("shsmooth")
	    call pargb (itob (xp_stati (xp, SHSMOOTH)))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("smaxiter")
	    call pargi (xp_stati (xp, SMAXITER))

	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("sloclip")
	    call pargr (xp_statr (xp, SLOCLIP))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("shiclip")
	    call pargr (xp_statr (xp, SHICLIP))
	call fprintf (strfd, " { %s  %d }")
	    call pargstr ("snreject")
	    call pargi (xp_stati (xp, SNREJECT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("sloreject")
	    call pargr (xp_statr (xp, SLOREJECT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("shireject")
	    call pargr (xp_statr (xp, SHIREJECT))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("srgrow")
	    call pargr (xp_statr (xp, SRGROW))

	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("skymark")
	    call pargb (itob (xp_stati (xp, SKYMARK)))
	if (xp_strwrd (xp_stati (xp, SCOLORMARK), Memc[str], SZ_FNAME,
	    SCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("scolormark")
	    call pargstr (Memc[str])

	call fprintf (strfd, " ")
	call strclose (strfd)

	call gmsg (gd, UI_SKYPARS(ui), Memc[sparlist])

	call sfree (sp)
end


# XP_PGUIPARS -- Construct a list of the photometry parameters to pass to the
# GUI.

procedure xp_pguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd, nap
pointer	sp, aparlist, str
bool	itob()
int	stropen(), xp_stati(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NPHOTPARS * MAX_SZPHOTPAR + 1
	call smark (sp)
	call salloc (aparlist, maxch, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	strfd = stropen (Memc[aparlist], maxch, NEW_FILE) 

	call xp_stats (xp, PGEOSTRING, Memc[str], SZ_LINE)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("pgeometry")
	    call pargstr (Memc[str])
	call xp_stats (xp, PAPSTRING, Memc[str], SZ_LINE)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("papertures")
	    call pargstr (Memc[str])
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("paxratio")
	    call pargr (xp_statr (xp, PAXRATIO))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("pposangle")
	    call pargr (xp_statr (xp, PPOSANGLE))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("pzmag")
	    call pargr (xp_statr (xp, PZMAG))
	call fprintf (strfd, " { %s  %b }")
	    call pargstr ("photmark")
	    call pargb (itob (xp_stati (xp, PHOTMARK)))
	if (xp_strwrd (xp_stati (xp, PCOLORMARK), Memc[str], SZ_FNAME,
	    PCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call fprintf (strfd, " { %s  %s }")
	    call pargstr ("pcolormark")
	    call pargstr (Memc[str])
	nap = xp_stati (xp, NAPERTS)
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("papmax")
	    call pargr (Memr[xp_statp(xp,PAPERTURES)+nap-1])
	call fprintf (strfd, " ")

	call strclose (strfd)

	call gmsg (gd, UI_PHOTPARS(ui), Memc[aparlist])

	call sfree (sp)
end


# XP_FGUIPARS -- Construct a list of the object detecton parameters to pass
# to the GUI.

procedure xp_fguipars (gd, ui, xp)

pointer	gd		#I pointer to the graphics stream
pointer	ui		#I pointer to the user interface descriptor
pointer	xp		#I pointer to the main xapphot structure

int	maxch, strfd
pointer	sp, fparlist, str
int	stropen()
real	xp_statr()

begin
	if (gd == NULL)
	    return

	maxch = MAX_NFINDPARS * MAX_SZFINDPAR + 1
	call smark (sp)
	call salloc (fparlist, maxch, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	strfd = stropen (Memc[fparlist], maxch, NEW_FILE) 

	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("fthreshold")
	    call pargr (xp_statr (xp, FTHRESHOLD))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("fradius")
	    call pargr (xp_statr (xp, FRADIUS))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("fsepmin")
	    call pargr (xp_statr (xp, FSEPMIN))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("froundlo")
	    call pargr (xp_statr (xp, FROUNDLO))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("froundhi")
	    call pargr (xp_statr (xp, FROUNDHI))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("fsharplo")
	    call pargr (xp_statr (xp, FSHARPLO))
	call fprintf (strfd, " { %s  %g }")
	    call pargstr ("fsharphi")
	    call pargr (xp_statr (xp, FSHARPHI))
	call fprintf (strfd, " ")

	call strclose (strfd)

	call gmsg (gd, UI_FINDPARS(ui), Memc[fparlist])

	call sfree (sp)
end


# XP_MKBANNER -- Create a results banner and pass it to the GUI.

procedure xp_mkbanner (gd, ui, xp)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer xp                      #I pointer to the main xapphot structure

pointer sp, str

begin
        if (gd == NULL)
            return

        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        call xp_pbanner (xp, Memc[str], SZ_LINE)
        call gmsg (gd, UI_PBANNER(ui), Memc[str])

        call sfree (sp)
end


# XP_MKHEADER -- Create a header list string that can be passed to the
# server. Note that the fmtlist parameter is set to YES in this example.
# This is a temporary measure until the text widget can accept a resize
# command like the list widget can.

procedure xp_mkheader (gd, ui, im, listfmt)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer im                      #I pointer to the image descriptor
int     listfmt                 #I list output format

pointer sp, hdrstr
int     tmp, len_hdrstring
int     stropen()

begin
        if (gd == NULL)
            return
	if (im == NULL) {
            call gmsg (gd, UI_HDRLIST(ui), "{}")
	    return
	}

        len_hdrstring = IM_HDRLEN(im) * SZ_STRUCT
        call smark (sp)
        call salloc (hdrstr, len_hdrstring, TY_CHAR)

        tmp = stropen (Memc[hdrstr], len_hdrstring, NEW_FILE)
        call xp_imheader (im, tmp, listfmt)
        call close (tmp)
        call gmsg (gd, UI_HDRLIST(ui), Memc[hdrstr])

        call sfree (sp)
end


# XP_MKSLIST -- Create a list of objects that can be passed to the server.

procedure xp_mkslist (gd, ui, xp)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface desacriptor
pointer xp                      #I pointer to the main xapphot structure

int     len_solstring, tmp, nobjs
pointer sp, solstr
int     stnsymbols(), stropen(), xp_wobjects()
pointer xp_statp()

begin
        if (gd == NULL)
            return

        # Estimate the length of the required string assuming object
        # definitions are less than one line long and ignoring vertices
        # lists for now.
        len_solstring = max (SZ_LINE, stnsymbols (xp_statp (xp, OBJLIST), 0) *
	    SZ_LINE)
            #+ stnsymbols (xp_statp(xp,POLYGONLIST), 0) * MAX_NOBJ_VERTICES /
            #10 * SZ_LINE
        call smark (sp)
        call salloc (solstr, len_solstring, TY_CHAR)

        tmp = stropen (Memc[solstr], len_solstring, NEW_FILE)
        nobjs = xp_wobjects (tmp, xp, YES, YES)
        call close (tmp)

        call gmsg (gd, UI_OBJLIST(ui), Memc[solstr])

        call sfree (sp)
end


# XP_TMKRESULTS -- Create the photometry table results string and pass it to
# the GUI.

procedure xp_tmkresults (gd, ui, xp)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer xp                      #I pointer to the main xapphot structure

pointer sp, str

begin
        if (gd == NULL)
            return

        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        call xp_presults (xp, Memc[str], SZ_LINE)
        call gmsg (gd, UI_PTABLE(ui), Memc[str])

        call sfree (sp)
end


define	MY_SZLINE	161

# XP_OMKRESULTS -- Create the object table results string and pass it to
# the GUI.

procedure xp_omkresults (gd, ui, xp, lseqno, seqno)

pointer gd                      #I pointer to the graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer xp                      #I pointer to the main xapphot structure
int	lseqno			#I the input objects file seqno number
int	seqno			#I the output results file seqno number

int	naperts
pointer sp, str
int	xp_stati()

begin
        if (gd == NULL)
            return
	naperts = xp_stati(xp,NAPERTS)
	naperts = (naperts + 2) * MY_SZLINE

        call smark (sp)
        call salloc (str, naperts, TY_CHAR)

        call xp_oresults (xp, lseqno, seqno, Memc[str], naperts)

        call gmsg (gd, UI_POBJECT(ui), Memc[str])

        call sfree (sp)
end


# XP_GSAPOLY -- Write the current photometry and sky polygons to the 
# appropriate GUI parameters.

procedure xp_gsapoly (gd, ui, xp)

pointer	gd			#I pointer to the input graphics stream
pointer	ui			#I pointer to the user interface descriptor
pointer	xp			#I pointer to the xapphot structure

int	nover, nsver, i, strfd
pointer	sp, txver, tyver, str
real	rapert, srannulus, swannulus
int	xp_stati(), stropen()
pointer	xp_statp()
real	xp_statr()

begin
	# Allocate some working space.
	nover = xp_stati(xp,PUNVER)
	nsver = xp_stati(xp,SUNVER)

	call smark (sp)
	call salloc (txver, max (nover + 1, nsver + 1), TY_REAL)
	call salloc (tyver, max (nover + 1, nsver + 1), TY_REAL)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Compute the photometry polygon.
	if (nover > 0) {

	    # Compute the polygon.
	    if (xp_stati(xp,NAPERTS) == 1) {
	        call amovr (Memr[xp_statp(xp,PUXVER)], Memr[txver], nover)
	        call amovr (Memr[xp_statp(xp,PUYVER)], Memr[tyver], nover)
	    } else {
	        rapert = xp_statr (xp, ISCALE) * Memr[xp_statp(xp,
		    PAPERTURES)+i-1]
	        call xp_pyexpand (Memr[xp_statp(xp,PUXVER)],
		    Memr[xp_statp(xp,PUYVER)], Memr[txver], Memr[tyver], nover,
	            rapert)
	    }

	    # Output the photometry polygon.
	    Memc[str] = EOS
	    strfd = stropen (Memc[str], SZ_LINE, NEW_FILE)
	    do i = 1, nover {
	        if (i == 1)
	            call fprintf (strfd, "{ {%0.2f %0.2f} ")
		else if (i == nover)
	            call fprintf (strfd, "{%0.2f %0.2f} }")
	        else
	            call fprintf (strfd, "{%0.2f %0.2f} ")
	        call pargr (Memr[txver+i-1])
	        call pargr (Memr[tyver+i-1])
	    }
	    call close (strfd)
	    call gmsg (gd, UI_PPOLYGON(ui), Memc[str])

	} else
	    call gmsg (gd, UI_PPOLYGON(ui), "INDEF")

	# Set the sky annulus parameters.
	if (xp_stati(xp, SMODE) == XP_SCONCENTRIC) {
            srannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SRANNULUS)
            swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SWANNULUS)
        } else {
            if (xp_stati (xp,SGEOMETRY) == XP_SPOLYGON) {
                srannulus = 0.0
                swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SWANNULUS)
            } else {
                srannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SRANNULUS)
                swannulus = xp_statr (xp, ISCALE) * xp_statr (xp, SWANNULUS)
	    }
        }

	# Output the sky polygon.
	if ((srannulus + swannulus) <= 0.0) {

	    if (nsver > 0) {
                call amovr (Memr[xp_statp(xp,SUXVER)], Memr[txver], nsver)
                call amovr (Memr[xp_statp(xp,SUYVER)], Memr[tyver], nsver)
	        Memc[str] = EOS
	        strfd = stropen (Memc[str], SZ_LINE, NEW_FILE)
	        do i = 1, nsver {
	            if (i == 1)
	                call fprintf (strfd, "{ {%0.2f %0.2f} ")
		    else if (i == nsver)
	                call fprintf (strfd, "{%0.2f %0.2f} }")
	            else
	                call fprintf (strfd, "{%0.2f %0.2f} ")
	            call pargr (Memr[txver+i-1])
	            call pargr (Memr[tyver+i-1])
	        }
	        call close (strfd)
	        call gmsg (gd, UI_S1POLYGON(ui), Memc[str])
	        call gmsg (gd, UI_S2POLYGON(ui), Memc[str])
	    } else {
	        call gmsg (gd, UI_S1POLYGON(ui), "INDEF")
	        call gmsg (gd, UI_S2POLYGON(ui), "INDEF")
	    }

        } else {

	    if (nsver > 0) {

                call xp_pyexpand (Memr[xp_statp(xp,SUXVER)], Memr[xp_statp(xp,
		    SUYVER)], Memr[txver], Memr[tyver], nsver,  srannulus)
	        Memc[str] = EOS
	        strfd = stropen (Memc[str], SZ_LINE, NEW_FILE)
	        do i = 1, nsver {
	            if (i == 1)
	                call fprintf (strfd, "{ {%0.2f %0.2f} ")
		    else if (i == nsver) 
	                call fprintf (strfd, "{%0.2f %0.2f} }")
	            else
	                call fprintf (strfd, "{%0.2f %0.2f} ")
	            call pargr (Memr[txver+i-1])
	            call pargr (Memr[tyver+i-1])
	        }
	        call close (strfd)
	        call gmsg (gd, UI_S1POLYGON(ui), Memc[str])

                call xp_pyexpand (Memr[xp_statp(xp,SUXVER)],
		    Memr[xp_statp(xp,SUYVER)], Memr[txver], Memr[tyver],
                    nsver, srannulus + swannulus)
	        Memc[str] = EOS
	        strfd = stropen (Memc[str], SZ_LINE, NEW_FILE)
	        do i = 1, nsver {
	            if (i == 1)
	                call fprintf (strfd, "{ {%0.2f %0.2f} ")
		    else if (i == nsver)
	                call fprintf (strfd, "{%0.2f %0.2f} }")
	            else
	                call fprintf (strfd, "{%0.2f %0.2f} ")
	                call pargr (Memr[txver+i-1])
	                call pargr (Memr[tyver+i-1])
	        }
	        call close (strfd)
	        call gmsg (gd, UI_S2POLYGON(ui), Memc[str])
	    } else {
	        call gmsg (gd, UI_S1POLYGON(ui), "INDEF")
	        call gmsg (gd, UI_S2POLYGON(ui), "INDEF")
	    }
        }

	call sfree (sp)
end


# XP_UIFREE -- Free the ui parameter structure

procedure xp_uifree (ui)

pointer	ui			#I the ui parameters structure

begin
	call mfree (ui, TY_STRUCT)
end
