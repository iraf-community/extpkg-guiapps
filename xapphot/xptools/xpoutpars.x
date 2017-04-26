include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "../lib/contour.h"
include "../lib/surface.h"


# XP_PXPARS -- Update the xphot task parameters.

procedure xp_pxpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_pipset ("impars", xp)
	call xp_pdpset ("dispars", xp)
	call xp_pfpset ("findpars", xp)
	call xp_popset ("omarkpars", xp)
	call xp_pcpset ("cenpars", xp)
	call xp_pspset ("skypars", xp)
	call xp_pppset ("photpars", xp)
	call xp_pepset ("cplotpars", xp)
	call xp_papset ("splotpars", xp)
end


# XP_PXDPARS -- Update the xdisplay task parameters.

procedure xp_pxdpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_pipset ("impars", xp)
	call xp_pdpset ("dispars", xp)
	call xp_pfpset ("findpars", xp)
	call xp_popset ("omarkpars", xp)
	call xp_pepset ("cplotpars", xp)
	call xp_papset ("splotpars", xp)
end


# XP_PXCPARS -- Update the xcenter task parameters.

procedure xp_pxcpars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_pipset ("impars", xp)
	call xp_pdpset ("dispars", xp)
	call xp_pfpset ("findpars", xp)
	call xp_popset ("omarkpars", xp)
	call xp_pcpset ("cenpars", xp)
	call xp_pepset ("cplotpars", xp)
	call xp_papset ("splotpars", xp)
end


# XP_PXSPARS -- Update the xfitsky task parameters.

procedure xp_pxspars (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_pipset ("impars", xp)
	call xp_pdpset ("dispars", xp)
	call xp_pfpset ("findpars", xp)
	call xp_popset ("omarkpars", xp)
	call xp_pspset ("skypars", xp)
	call xp_pepset ("cplotpars", xp)
	call xp_papset ("splotpars", xp)
end


# XP_PDPSET -- Write the current parameter values out to the display parameter
# set.

procedure xp_pdpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	clopset()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	pp = clopset (psetname)

	# Update the display geometry parameters.
	call clppsetb (pp, "derase", itob (xp_stati (xp, DERASE)))
	call clppsetb (pp, "dfill", itob (xp_stati (xp, DFILL)))
	call clppsetr (pp, "dxviewport", xp_statr (xp, DXVIEWPORT))
	call clppsetr (pp, "dyviewport", xp_statr (xp, DYVIEWPORT))
	call clppsetr (pp, "dxmag", xp_statr (xp, DXMAG))
	call clppsetr (pp, "dymag", xp_statr (xp, DYMAG))

	# Update the look-up table parameters.
	ival = xp_strwrd (xp_stati (xp, DZTRANS), Memc[str], SZ_FNAME,
	    DZTRANS_OPTIONS)
	if (ival > 0)
	    call clppset (pp, "dztransform", Memc[str]) 
	else
	    call clppset (pp, "dztransform", "linear") 
	ival = xp_strwrd (xp_stati (xp, DZLIMITS), Memc[str], SZ_FNAME,
	    DZLIMITS_OPTIONS)
	if (ival > 0)
	    call clppset (pp, "dzlimits", Memc[str]) 
	else
	    call clppset (pp, "dzlimits", "median") 
	call clppseti (pp, "dznsample", xp_stati (xp, DZNSAMPLE))
	call clppsetr (pp, "dzcontrast", xp_statr (xp, DZCONTRAST))
	call clppsetr (pp, "dz1", xp_statr (xp, DZ1))
	call clppsetr (pp, "dz2", xp_statr (xp, DZ2))
	call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
	call clppset (pp, "dlutfile", Memc[str])
	call clppsetb (pp, "drepeat", itob (xp_stati (xp, DREPEAT)))

	call clcpset (pp)

	call sfree (sp)
end


# XP_PIPSET -- Write out the current values of the parameters to the image
# parameter set.

procedure xp_pipset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

pointer	sp, str, pp
bool	itob()
int	xp_stati()
pointer	clopset()
real	xp_statr()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Update the data dependent parameters.
	call clppsetr (pp, "iscale", 1.0 / xp_statr (xp, ISCALE))
	call clppsetr (pp, "ihwhmpsf", xp_statr (xp, IHWHMPSF))
	call clppsetb (pp, "iemission", itob (xp_stati (xp, IEMISSION)))
	call clppsetr (pp, "iskysigma", xp_statr (xp, ISKYSIGMA))
	call clppsetr (pp, "imindata", xp_statr (xp, IMINDATA))
	call clppsetr (pp, "imaxdata", xp_statr (xp, IMAXDATA))

	# Update the noise model parameters.
	call xp_stats (xp, INSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "inoisemodel", Memc[str])
	call xp_stats (xp, IKGAIN, Memc[str], SZ_LINE)
	call clppset (pp, "ikgain", Memc[str])
	call clppsetr (pp, "igain", xp_statr (xp, IGAIN))
	call xp_stats (xp, IKREADNOISE, Memc[str], SZ_LINE)
	call clppset (pp, "ikreadnoise", Memc[str])
	call clppsetr (pp, "ireadnoise", xp_statr (xp, IREADNOISE))

	# Update the observing parameters.
	call xp_stats (xp, IKEXPTIME, Memc[str], SZ_LINE)
	call clppset (pp, "ikexptime", Memc[str])
	call clppsetr (pp, "ietime", xp_statr (xp, IETIME))
	call xp_stats (xp, IKAIRMASS, Memc[str], SZ_LINE)
	call clppset (pp, "ikairmass", Memc[str])
	call clppsetr (pp, "iairmass", xp_statr (xp, IAIRMASS))
	call xp_stats (xp, IKFILTER, Memc[str], SZ_LINE)
	call clppset (pp, "ikfilter", Memc[str])
	call xp_stats (xp, IFILTER, Memc[str], SZ_LINE)
	call clppset (pp, "ifilter", Memc[str])
	call xp_stats (xp, IKOBSTIME, Memc[str], SZ_LINE)
	call clppset (pp, "ikobstime", Memc[str])
	call xp_stats (xp, IOTIME, Memc[str], SZ_LINE)
	call clppset (pp, "iotime", Memc[str])

	# Close the parameter set files.
	call clcpset (pp)

	call sfree (sp)
end


# XP_POPSET -- Write the current values of the objects algorithm
# parameters to the omarkpars parameter set.

procedure xp_popset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	clopset()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Update the object marking parameters.
	call clppsetb (pp, "objmark", itob (xp_stati (xp, OBJMARK)))
	call clppsetr (pp, "otolerance", xp_statr (xp, OTOLERANCE))
	ival = xp_strwrd (xp_stati (xp, OCHARMARK), Memc[str], SZ_LINE,
	    OMARKERS)
	if (ival > 0)
	    call clppset (pp, "ocharmark", Memc[str])
	else
	    call clppset (pp, "ocharmark", "plus")
	call clppsetb (pp, "onumber", itob (xp_stati (xp, ONUMBER)))

	ival = xp_strwrd (xp_stati (xp, OPCOLORMARK), Memc[str], SZ_LINE,
	    OCOLORS)
	if (ival > 0)
	    call clppset (pp, "opcolormark", Memc[str])
	else
	    call clppset (pp, "opcolormark", "green")
	ival = xp_strwrd (xp_stati (xp, OSCOLORMARK), Memc[str], SZ_LINE,
	    OCOLORS)
	if (ival > 0)
	    call clppset (pp, "oscolormark", Memc[str])
	else
	    call clppset (pp, "oscolormark", "blue")

	call clppsetr (pp, "osizemark", xp_statr (xp, OSIZEMARK))

	# Close the parameter set file.
	call clcpset (pp)

	call sfree (sp)
end


# XP_PCPSET -- Write the current values of the centering algorithm
# parameters to the cenpars parameter set.

procedure xp_pcpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	clopset()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Open the pset parameter file.
	pp = clopset (psetname)

	# Update the centering algorithm parameters.
	call xp_stats (xp, CSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "calgorithm", Memc[str])
	call clppsetr (pp, "cradius", xp_statr (xp, CRADIUS))
	call clppsetr (pp, "cthreshold", xp_statr (xp, CTHRESHOLD))
	call clppsetr (pp, "cminsnratio", xp_statr (xp, CMINSNRATIO))
	call clppseti (pp, "cmaxiter", xp_stati (xp, CMAXITER))
	call clppsetr (pp, "cxyshift", xp_statr (xp, CXYSHIFT))

	# Update the centering marking parameters.
	call clppsetb (pp, "ctrmark", itob (xp_stati (xp, CTRMARK)))
	ival = xp_strwrd (xp_stati (xp, CCHARMARK), Memc[str], SZ_LINE,
	    CMARKERS)
	if (ival > 0)
	    call clppset (pp, "ccharmark", Memc[str])
	else
	    call clppset (pp, "ccharmark", "plus")
	ival = xp_strwrd (xp_stati (xp, CCOLORMARK), Memc[str], SZ_LINE,
	    CCOLORS)
	if (ival > 0)
	    call clppset (pp, "ccolormark", Memc[str])
	else
	    call clppset (pp, "ccolormark", "red")
	call clppsetr (pp, "csizemark", xp_statr (xp, CSIZEMARK))

	# Close the parameter set file.
	call clcpset (pp)

	call sfree (sp)
end


# XP_PSPSET -- Write the current values of the sky fitting algorithm
# parameters to the skypars parameter set.

procedure xp_pspset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	clopset()
real	xp_statr()

begin
	call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

	# Update the sky aperture geometry parameters.
	call xp_stats (xp, SMSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "smode", Memc[str])
	call xp_stats (xp, SGEOSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "sgeometry", Memc[str])
	call clppsetr (pp, "srannulus", xp_statr (xp, SRANNULUS))
	call clppsetr (pp, "swannulus", xp_statr (xp, SWANNULUS))
	call clppsetr (pp, "saxratio", xp_statr (xp, SAXRATIO))
	call clppsetr (pp, "sposangle", xp_statr (xp, SPOSANGLE))

        # Update the sky fitting algorithm parameters.
	call xp_stats (xp, SSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "salgorithm", Memc[str])
	call clppsetr (pp, "sconstant", xp_statr (xp, SCONSTANT))
	call clppsetr (pp, "shwidth", xp_statr (xp, SHWIDTH))
	call clppsetr (pp, "shbinsize", xp_statr (xp, SHBINSIZE))
	call clppsetb (pp, "shsmooth", itob (xp_stati (xp, SHSMOOTH)))
	call clppseti (pp, "smaxiter", xp_stati (xp, SMAXITER))

	# Update the bad sky data rejection parameters.
	call clppsetr (pp, "sloclip", xp_statr (xp, SLOCLIP))
	call clppsetr (pp, "shiclip", xp_statr (xp, SHICLIP))
	call clppseti (pp, "snreject", xp_stati (xp, SNREJECT))
	call clppsetr (pp, "sloreject", xp_statr (xp, SLOREJECT))
	call clppsetr (pp, "shireject", xp_statr (xp, SHIREJECT))
	call clppsetr (pp, "srgrow", xp_statr (xp, SRGROW))

        # Update the sky marking parameters.
	call clppsetb (pp, "skymark", itob (xp_stati (xp, SKYMARK)))
	ival = xp_strwrd (xp_stati (xp, SCOLORMARK), Memc[str], SZ_LINE,
	    SCOLORS)
	if (ival > 0)
	    call clppset (pp, "scolormark", Memc[str])
	else
	    call clppset (pp, "scolormark", "red")

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_PPPSET -- Write the current values of the photometry parameters to
# the photpars parameter  set.

procedure xp_pppset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
pointer clopset()
real	xp_statr()

begin
        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

        # Set the photometry parameters.
	call xp_stats (xp, PGEOSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "pgeometry", Memc[str])
	call xp_stats (xp, PAPSTRING, Memc[str], SZ_LINE)
	call clppset (pp, "papertures", Memc[str])
	call clppsetr (pp, "paxratio", xp_statr (xp, PAXRATIO))
	call clppsetr (pp, "pposangle", xp_statr (xp, PPOSANGLE))
	call clppsetr (pp, "pzmag", xp_statr (xp, PZMAG))

	# Get the aperture marking parameters.
	call clppsetb (pp, "photmark", itob (xp_stati (xp, PHOTMARK)))
	ival = xp_strwrd (xp_stati (xp, PCOLORMARK), Memc[str], SZ_LINE,
	    PCOLORS)
	if (ival > 0)
	    call clppset (pp, "pcolormark", Memc[str])
	else
	    call clppset (pp, "pcolormark", "red")

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_PEPSET -- Write the current values of the contour plotting parameters
# to the pcontour parameter set.

procedure xp_pepset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

int	ival
pointer	sp, str, pp
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()
pointer	clopset()

begin
        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Open the pset parameter file.
        pp = clopset (psetname)

	call clppseti (pp, "enx", xp_stati (xp, ENX))
	call clppseti (pp, "eny", xp_stati (xp, ENY))
	call clppsetr (pp, "ez1", xp_statr (xp, EZ1))
	call clppsetr (pp, "ez2", xp_statr (xp, EZ2))
	call clppsetr (pp, "ez0", xp_statr (xp, EZ0))
	call clppseti (pp, "encontours", xp_stati (xp, ENCONTOURS))
	call clppsetr (pp, "edz", xp_statr (xp, EDZ))
	ival = xp_strwrd (xp_stati (xp, EHILOMARK), Memc[str], SZ_FNAME,
	   EHILOMARK_OPTIONS)
	if (ival > 0)
	    call clppset (pp, "ehilomark", Memc[str]) 
	else
	    call clppset (pp, "ehilomark", "none") 
	call clppseti (pp, "edashpat", xp_stati (xp, EDASHPAT))
	call clppsetb (pp, "elabel", itob (xp_stati (xp, ELABEL)))
	call clppsetb (pp, "ebox", itob (xp_stati (xp, EBOX)))
	call clppsetb (pp, "eticklabel", itob (xp_stati (xp, ETICKLABEL)))
	call clppseti (pp, "exmajor", xp_stati (xp, EXMAJOR))
	call clppseti (pp, "exminor", xp_stati (xp, EXMINOR))
	call clppseti (pp, "eymajor", xp_stati (xp, EYMAJOR))
	call clppseti (pp, "eyminor", xp_stati (xp, EYMINOR))
	call clppsetb (pp, "eround", itob (xp_stati (xp, EROUND)))
	call clppsetb (pp, "efill", itob (xp_stati (xp, EFILL)))

        # Close the parameter set file.
        call clcpset (pp)

        call sfree (sp)
end


# XP_PAPSET -- Write the current values of the surface plotting parameters
# to the pcontour parameter set.

procedure xp_papset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

pointer	pp
bool	itob()
int	xp_stati()
real	xp_statr()
pointer	clopset()

begin
        # Open the pset parameter file.
        pp = clopset (psetname)

	call clppseti (pp, "anx", xp_stati (xp, ASNX))
	call clppseti (pp, "any", xp_stati (xp, ASNY))
	call clppsetb (pp, "alabel", itob (xp_stati (xp, ALABEL)))
	call clppsetr (pp, "az1", xp_statr (xp, AZ1))
	call clppsetr (pp, "az2", xp_statr (xp, AZ2))
	call clppsetr (pp, "angh", xp_statr (xp, ANGH))
	call clppsetr (pp, "angv", xp_statr (xp, ANGV))

        # Close the parameter set file.
        call clcpset (pp)
end


# XP_PFPSET -- Write the current values of the object detection parameters
# to the findpars parameter set.

procedure xp_pfpset (psetname, xp)

char	psetname[ARB]		#I the parameter set name
pointer	xp			#I the pointer to the main xapphot structure

pointer	pp
pointer	clopset()
real	xp_statr()

begin
        # Open the pset parameter file.
        pp = clopset (psetname)

	call clppsetr (pp, "fthreshold", xp_statr (xp, FTHRESHOLD))
	call clppsetr (pp, "fradius", xp_statr (xp, FRADIUS))
	call clppsetr (pp, "fsepmin", xp_statr (xp, FSEPMIN))
	call clppsetr (pp, "froundlo", xp_statr (xp, FROUNDLO))
	call clppsetr (pp, "froundhi", xp_statr (xp, FROUNDHI))
	call clppsetr (pp, "fsharplo", xp_statr (xp, FSHARPLO))
	call clppsetr (pp, "fsharphi", xp_statr (xp, FSHARPHI))

        # Close the parameter set file.
        call clcpset (pp)
end
