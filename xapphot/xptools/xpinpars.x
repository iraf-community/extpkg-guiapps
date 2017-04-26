include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "../lib/contour.h"
include "../lib/surface.h"


# XP_GXPARS -- Initialize the xapphot task structures and read in the xphot task
# parameters.

procedure xp_gxpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_xpinit (xp)
	call xp_gipset ("impars", xp)
	call xp_gdpset ("dispars", xp)
	call xp_gfpset ("findpars", xp)
	call xp_gopset ("omarkpars", xp)
	call xp_gcpset ("cenpars", xp)
	call xp_gspset ("skypars", xp)
	call xp_gppset ("photpars", xp)
	call xp_gepset ("cplotpars", xp)
	call xp_gapset ("splotpars", xp)
end


# XP_GXDPARS -- Initialize the xdisplay task structures and read in the
# xfind task parameters.

procedure xp_gxdpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_xdinit (xp)
	call xp_gipset ("impars", xp)
	call xp_gdpset ("dispars", xp)
	call xp_gfpset ("findpars", xp)
	call xp_gopset ("omarkpars", xp)
	call xp_gepset ("cplotpars", xp)
	call xp_gapset ("splotpars", xp)
end


# XP_GXCPARS -- Initialize the xcenter task structures and read in the
# xcenter task parameters.

procedure xp_gxcpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_xcinit (xp)
	call xp_gipset ("impars", xp)
	call xp_gdpset ("dispars", xp)
	call xp_gfpset ("findpars", xp)
	call xp_gopset ("omarkpars", xp)
	call xp_gcpset ("cenpars", xp)
	call xp_gepset ("cplotpars", xp)
	call xp_gapset ("splotpars", xp)
end


# XP_GXSPARS -- Initialize the xfitsky task structures and read in the
# xfitsky task parameters.

procedure xp_gxspars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_xsinit (xp)
	call xp_gipset ("impars", xp)
	call xp_gdpset ("dispars", xp)
	call xp_gfpset ("findpars", xp)
	call xp_gopset ("omarkpars", xp)
	call xp_gspset ("skypars", xp)
	call xp_gepset ("cplotpars", xp)
	call xp_gapset ("splotpars", xp)
end


# XP_GDPSET -- Read in the parameters from the image display parameter set.

procedure xp_gdpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	clgpsetb()
int	btoi(), strdic(), clgpseti()
pointer	clopset()
real	clgpsetr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	pp = clopset (psetname)

	call xp_seti (xp, DERASE, btoi (clgpsetb (pp, "derase")))
	call xp_seti (xp, DFILL, btoi (clgpsetb (pp, "dfill")))
	#call xp_setr (xp, DXORIGIN, clgpsetr (pp, "dxorigin"))
	#call xp_setr (xp, DYORIGIN, clgpsetr (pp, "dyorigin"))
	call xp_setr (xp, DXVIEWPORT, clgpsetr (pp, "dxviewport"))
	call xp_setr (xp, DYVIEWPORT, clgpsetr (pp, "dyviewport"))
	call xp_setr (xp, DXMAG, clgpsetr (pp, "dxmag"))
	call xp_setr (xp, DYMAG, clgpsetr (pp, "dymag"))

	call clgpset (pp, "dztransform", Memc[str], SZ_FNAME)
	ival = strdic (Memc[str], Memc[str], SZ_FNAME, DZTRANS_OPTIONS)
	if (ival <= 0)
	    call xp_seti (xp, DZTRANS, XP_DZLINEAR)
	else
	    call xp_seti (xp, DZTRANS, ival)
	call clgpset (pp, "dzlimits", Memc[str], SZ_FNAME)
	ival = strdic (Memc[str], Memc[str], SZ_FNAME, DZLIMITS_OPTIONS)
	if (ival <= 0)
	    call xp_seti (xp, DZLIMITS, XP_DZMEDIAN)
	else
	    call xp_seti (xp, DZLIMITS, ival)
	call xp_seti (xp, DZNSAMPLE, clgpseti (pp, "dznsample"))
	call xp_setr (xp, DZCONTRAST, clgpsetr (pp, "dzcontrast"))
	call xp_setr (xp, DZ1, clgpsetr (pp, "dz1"))
	call xp_setr (xp, DZ2, clgpsetr (pp, "dz2"))
	call clgpset (pp, "dlutfile", Memc[str], SZ_FNAME)
	call xp_sets (xp, DLUTFILE, Memc[str])
	call xp_seti (xp, DREPEAT, btoi (clgpsetb (pp, "drepeat")))

	call clcpset (pp)

	call sfree (sp)
end


# XP_GIPSET -- Read in the parameters from the image charactersitics parameter
# set.

procedure xp_gipset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	noise
pointer	sp, str, pp
bool	clgpsetb()
int	strdic(), btoi()
pointer	clopset()
real	clgpsetr()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Get the data dependent parameters.
	call xp_setr (xp, ISCALE, 1.0 / clgpsetr (pp, "iscale"))
	call xp_setr (xp, IHWHMPSF, clgpsetr (pp, "ihwhmpsf"))
	call xp_seti (xp, IEMISSION, btoi (clgpsetb (pp, "iemission")))
	call xp_setr (xp, ISKYSIGMA, clgpsetr (pp, "iskysigma"))
	call xp_setr (xp, IMINDATA, clgpsetr (pp, "imindata"))
	call xp_setr (xp, IMAXDATA, clgpsetr (pp, "imaxdata"))

	# Get the noise model parameters.
	call clgpset (pp, "inoisemodel", Memc[str], SZ_LINE)
	noise = strdic (Memc[str], Memc[str], SZ_LINE, NFUNCS)
	call xp_sets (xp, INSTRING, Memc[str])
	call xp_seti (xp, INOISEMODEL, noise)
	call clgpset (pp, "ikgain", Memc[str], SZ_LINE)
	call xp_sets (xp, IKGAIN, Memc[str])
	call xp_setr (xp, IGAIN, clgpsetr (pp, "igain"))
	call clgpset (pp, "ikreadnoise", Memc[str], SZ_LINE)
	call xp_sets (xp, IKREADNOISE, Memc[str])
	call xp_setr (xp, IREADNOISE, clgpsetr (pp, "ireadnoise"))

	# Get the observing parameters.
	call clgpset (pp, "ikexptime", Memc[str], SZ_LINE)
	call xp_sets (xp, IKEXPTIME, Memc[str])
	call xp_setr (xp, IETIME, clgpsetr (pp, "ietime"))
	call clgpset (pp, "ikairmass", Memc[str], SZ_LINE)
	call xp_sets (xp, IKAIRMASS, Memc[str])
	call xp_setr (xp, IAIRMASS, clgpsetr (pp, "iairmass"))
	call clgpset (pp, "ikfilter", Memc[str], SZ_LINE)
	call xp_sets (xp, IKFILTER, Memc[str])
	call clgpset (pp, "ifilter", Memc[str], SZ_LINE)
	call xp_sets (xp, IFILTER, Memc[str])
	call clgpset (pp, "ikobstime", Memc[str], SZ_LINE)
	call xp_sets (xp, IKOBSTIME, Memc[str])
	call clgpset (pp, "iotime", Memc[str], SZ_LINE)
	call xp_sets (xp, IOTIME, Memc[str])

	# Close the parameter set files.
	call clcpset (pp)

	call sfree (sp)
end


# XP_GOPSET -- Read in the parameters from the objects parameter set.

procedure xp_gopset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	function
pointer	sp, str, pp
bool	clgpsetb()
int	strdic(), btoi()
pointer	clopset()
real	clgpsetr()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Get the parameters.
	call xp_seti (xp, OBJMARK, btoi (clgpsetb (pp, "objmark")))
	call xp_setr (xp, OTOLERANCE, clgpsetr (pp, "otolerance"))
	call clgpset (pp, "ocharmark", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, OMARKERS)
	if (function > 0)
	    call xp_seti (xp, OCHARMARK, function)
	else
	    call xp_seti (xp, OCHARMARK, XP_OMARK_PLUS)
	call xp_seti (xp, ONUMBER, btoi (clgpsetb (pp, "onumber")))
	call clgpset (pp, "opcolormark", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, OCOLORS)
	if (function > 0)
	    call xp_seti (xp, OPCOLORMARK, function)
	else
	    call xp_seti (xp, OPCOLORMARK, XP_OMARK_GREEN)
	call clgpset (pp, "oscolormark", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, OCOLORS)
	if (function > 0)
	    call xp_seti (xp, OSCOLORMARK, function)
	else
	    call xp_seti (xp, OSCOLORMARK, XP_OMARK_BLUE)
	call xp_setr (xp, OSIZEMARK, clgpsetr (pp, "osizemark"))

	# Close the pset parameter file.
	call clcpset (pp)

	call sfree (sp)
end


# XP_GCPSET -- Read in the parameters from the centering algorithm parameter
# set.

procedure xp_gcpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	function
pointer	sp, str, pp
bool	clgpsetb()
int	strdic(), clgpseti(), btoi()
pointer	clopset()
real	clgpsetr()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Get the centering parameters.
	call clgpset (pp, "calgorithm", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, CALGS)
	call xp_sets (xp, CSTRING, Memc[str])
	call xp_seti (xp, CALGORITHM, function)
	call xp_setr (xp, CRADIUS, clgpsetr (pp, "cradius"))
	call xp_setr (xp, CTHRESHOLD, clgpsetr (pp, "cthreshold"))
	call xp_setr (xp, CMINSNRATIO, clgpsetr (pp, "cminsnratio"))
	call xp_seti (xp, CMAXITER, clgpseti (pp, "cmaxiter"))
	call xp_setr (xp, CXYSHIFT, clgpsetr (pp, "cxyshift"))

	call xp_seti (xp, CTRMARK, btoi (clgpsetb (pp, "ctrmark")))
	call clgpset (pp, "ccharmark", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, CMARKERS)
	if (function > 0)
	    call xp_seti (xp, CCHARMARK, function)
	else
	    call xp_seti (xp, CCHARMARK, XP_CMARK_PLUS)
	call clgpset (pp, "ccolormark", Memc[str], SZ_LINE)
	function = strdic (Memc[str], Memc[str], SZ_LINE, CCOLORS)
	if (function > 0)
	    call xp_seti (xp, CCOLORMARK, function)
	else
	    call xp_seti (xp, CCOLORMARK, XP_CMARK_RED)
	call xp_setr (xp, CSIZEMARK, clgpsetr (pp, "csizemark"))

	# Close the parameter set file.
	call clcpset (pp)

	call sfree (sp)
end


# XP_GSPSET -- Read in the parameters from the sky fitting algorithm parameter
# set.

procedure xp_gspset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the  pointer to the main xapphot structure

int	function
pointer	sp, str, pp
bool	clgpsetb()
int	strdic(), clgpseti(), btoi()
pointer	clopset()
real	clgpsetr()

begin
	call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

        # Get the sky fitting algorithm parameters.
        call clgpset (pp, "smode", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, SMODES)
        call xp_sets (xp, SMSTRING, Memc[str])
        call xp_seti (xp, SMODE, function)
        call clgpset (pp, "salgorithm", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, SALGS)
        call xp_sets (xp, SSTRING, Memc[str])
        call xp_seti (xp, SALGORITHM, function)
        call clgpset (pp, "sgeometry", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, SGEOMS)
        call xp_sets (xp, SGEOSTRING, Memc[str])
        call xp_seti (xp, SGEOMETRY, function)
        call xp_setr (xp, SRANNULUS, clgpsetr (pp, "srannulus"))
        call xp_setr (xp, SWANNULUS, clgpsetr (pp, "swannulus"))
        call xp_setr (xp, SAXRATIO, clgpsetr (pp, "saxratio"))
        call xp_setr (xp, SPOSANGLE, clgpsetr (pp, "sposangle"))
        call xp_setr (xp, SCONSTANT, clgpsetr (pp, "sconstant"))
        call xp_setr (xp, SLOCLIP, clgpsetr (pp, "sloclip"))
        call xp_setr (xp, SHICLIP, clgpsetr (pp, "shiclip"))
        call xp_setr (xp, SHWIDTH, clgpsetr (pp, "shwidth"))
        call xp_setr (xp, SHBINSIZE, clgpsetr (pp, "shbinsize"))
        call xp_seti (xp, SHSMOOTH, btoi (clgpsetb (pp, "shsmooth")))
        call xp_seti (xp, SMAXITER, clgpseti (pp, "smaxiter"))
        call xp_seti (xp, SNREJECT, clgpseti (pp, "snreject"))
        call xp_setr (xp, SLOREJECT, clgpsetr (pp, "sloreject"))
        call xp_setr (xp, SHIREJECT, clgpsetr (pp, "shireject"))
        call xp_setr (xp, SRGROW, clgpsetr (pp, "srgrow"))

        # Get the marking parameter.
        call xp_seti (xp, SKYMARK, btoi (clgpsetb (pp, "skymark")))
        call clgpset (pp, "scolormark", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, SCOLORS)
        call xp_seti (xp, SCOLORMARK, function)

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_GPPSET -- Read in the parameters from the photometry algorithm parameter
# set.

procedure xp_gppset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	function
pointer sp, str, pp
bool    clgpsetb()
int     btoi(), strdic()
pointer clopset()
real    clgpsetr()

begin
        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

        # Get the photometry parameters.
        call clgpset (pp, "pgeometry", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, AGEOMS)
        call xp_sets (xp, PGEOSTRING, Memc[str])
        call xp_seti (xp, PGEOMETRY, function)
        call clgpset (pp, "papertures", Memc[str], SZ_LINE)
        call xp_sets (xp, PAPSTRING, Memc[str])
        call xp_setr (xp, PAXRATIO, clgpsetr (pp, "paxratio"))
        call xp_setr (xp, PPOSANGLE, clgpsetr (pp, "pposangle"))
        call xp_setr (xp, PZMAG, clgpsetr (pp, "pzmag"))

	# Get the aperture marking parameters.
        call xp_seti (xp, PHOTMARK, btoi (clgpsetb (pp, "photmark")))
	call clgpset (pp, "pcolormark", Memc[str], SZ_LINE)
        function = strdic (Memc[str], Memc[str], SZ_LINE, PCOLORS)
        if (function > 0)
            call xp_seti (xp, PCOLORMARK, function)
        else
            call xp_seti (xp, PCOLORMARK, XP_AMARK_RED)

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_GEPSET -- Read in the parameters from the contour plotting parameter
# set.

procedure xp_gepset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	clgpsetb()
int	clgpseti(), btoi(), strdic()
pointer clopset()
real	clgpsetr()

begin
        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

        call xp_seti (xp, ENX, clgpseti (pp, "enx"))
        call xp_seti (xp, ENY, clgpseti (pp, "eny"))
        call xp_setr (xp, EZ1, clgpsetr (pp, "ez1"))
        call xp_setr (xp, EZ2, clgpsetr (pp, "ez2"))
        call xp_setr (xp, EZ0, clgpsetr (pp, "ez0"))
        call xp_seti (xp, ENCONTOURS, clgpseti (pp, "encontours"))
        call xp_setr (xp, EDZ, clgpsetr (pp, "edz"))
	call clgpset (pp, "ehilomark", Memc[str], SZ_FNAME)
	ival = strdic (Memc[str], Memc[str], SZ_FNAME, EHILOMARK_OPTIONS)
	if (ival <= 0)
	    call xp_seti (xp, EHILOMARK, XP_ENONE)
	else
	    call xp_seti (xp, EHILOMARK, ival)
        call xp_seti (xp, EDASHPAT, clgpseti (pp, "edashpat"))
        call xp_seti (xp, EBOX, btoi (clgpsetb (pp, "ebox")))
        call xp_seti (xp, ETICKLABEL, btoi (clgpsetb (pp, "eticklabel")))
        call xp_seti (xp, EXMAJOR, clgpseti (pp, "exmajor"))
        call xp_seti (xp, EXMINOR, clgpseti (pp, "exminor"))
        call xp_seti (xp, EYMAJOR, clgpseti (pp, "eymajor"))
        call xp_seti (xp, EYMINOR, clgpseti (pp, "eyminor"))
        call xp_seti (xp, EROUND, btoi (clgpsetb (pp, "eround")))
        call xp_seti (xp, EFILL, btoi (clgpsetb (pp, "efill")))

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_GAPSET -- Read in the parameters from the surface plotting parameter
# set.

procedure xp_gapset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

pointer	pp
bool	clgpsetb()
int	clgpseti(), btoi()
pointer clopset()
real	clgpsetr()

begin
        # Open the pset parameter file.
        pp = clopset (psetname)

        call xp_seti (xp, ASNX, clgpseti (pp, "anx"))
        call xp_seti (xp, ASNY, clgpseti (pp, "any"))
        call xp_seti (xp, ALABEL, btoi (clgpsetb (pp, "alabel")))
        call xp_setr (xp, AZ1, clgpsetr (pp, "az1"))
        call xp_setr (xp, AZ2, clgpsetr (pp, "az2"))
        call xp_setr (xp, ANGH, clgpsetr (pp, "angh"))
        call xp_setr (xp, ANGV, clgpsetr (pp, "angv"))

        # Close the parameter set file.
        call clcpset (pp)
end


# XP_GFPSET -- Read in the parameters from the object detection parameter
# set.

procedure xp_gfpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

pointer	pp
pointer	clopset()
real	clgpsetr()

begin
        # Open the pset parameter file.
        pp = clopset (psetname)

        call xp_setr (xp, FTHRESHOLD, clgpsetr (pp, "fthreshold"))
        call xp_setr (xp, FRADIUS, clgpsetr (pp, "fradius"))
        call xp_setr (xp, FSEPMIN, clgpsetr (pp, "fsepmin"))
        call xp_setr (xp, FROUNDLO, clgpsetr (pp, "froundlo"))
        call xp_setr (xp, FROUNDHI, clgpsetr (pp, "froundhi"))
        call xp_setr (xp, FSHARPLO, clgpsetr (pp, "fsharplo"))
        call xp_setr (xp, FSHARPHI, clgpsetr (pp, "fsharphi"))

        # Close the parameter set file.
        call clcpset (pp)
end
