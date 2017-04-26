include "../lib/impars.h"
include "../lib/display.h"
include "../lib/find.h"
include "../lib/objects.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include "../lib/contour.h"
include "../lib/surface.h"


# XP_LDPARS -- Print a list of the image display parameters on the standard
# output.

procedure xp_ldpars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call printf ("%s\t\t%b\n")
	    call pargstr ("derase")
	    call pargb (itob (xp_stati (xp, DERASE)))
	call printf ("%s\t\t%b\n")
	    call pargstr ("dfill")
	    call pargb (itob (xp_stati (xp, DFILL)))
	call printf ("%s\t%g\n")
	    call pargstr ("dxviewport")
	    call pargr (xp_statr (xp, DXVIEWPORT))
	call printf ("%s\t%g\n")
	    call pargstr ("dyviewport")
	    call pargr (xp_statr (xp, DYVIEWPORT))
	call printf ("%s\t\t%g\n")
	    call pargstr ("dxmag")
	    call pargr (xp_statr (xp, DXMAG))
	call printf ("%s\t\t%g\n")
	    call pargstr ("dymag")
	    call pargr (xp_statr (xp, DYMAG))
	if (xp_strwrd (xp_stati (xp, DZTRANS), Memc[str], SZ_FNAME,
	    DZTRANS_OPTIONS) <= 0)
	    call strcpy ("linear", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("dztransform")
	    call pargstr (Memc[str])
	if (xp_strwrd (xp_stati (xp, DZLIMITS), Memc[str], SZ_FNAME,
	    DZLIMITS_OPTIONS) <= 0)
	    call strcpy ("median", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("dzlimits")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("dzcontrast")
	    call pargr (xp_statr (xp, DZCONTRAST))
	call printf ("%s\t%d\n")
	    call pargstr ("dznsample")
	    call pargi (xp_stati (xp, DZNSAMPLE))
	call printf ("%s\t\t%g\n")
	    call pargstr ("dz1")
	    call pargr (xp_statr (xp, DZ1))
	call printf ("%s\t\t%g\n")
	    call pargstr ("dz2")
	    call pargr (xp_statr (xp, DZ2))
	call xp_stats (xp, DLUTFILE, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("dlutfile")
	    call pargstr (Memc[str])
	call printf ("%s\t\t%b\n")
	    call pargstr ("drepeat")
	    call pargb (itob (xp_stati (xp, DREPEAT)))
	call printf ("\n")

	call sfree (sp)
end


# XP_LIPARS -- Print a list of image parameters on the standard output.

procedure xp_lipars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call printf ("%s\t\t%g\n")
	    call pargstr ("iscale")
	    call pargr (1.0 / xp_statr (xp, ISCALE))
	call printf ("%s\t%g\n")
	    call pargstr ("ihwhmpsf")
	    call pargr (xp_statr (xp, IHWHMPSF))
	call printf ("%s\t%b\n")
	    call pargstr ("iemission")
	    call pargb (itob (xp_stati (xp, IEMISSION)))
	call printf ("%s\t%g\n")
	    call pargstr ("iskysigma")
	    call pargr (xp_statr (xp, ISKYSIGMA))
	call printf ("%s\t%g\n")
	    call pargstr ("imindata")
	    call pargr (xp_statr (xp, IMINDATA))
	call printf ("%s\t%g\n")
	    call pargstr ("imaxdata")
	    call pargr (xp_statr (xp, IMAXDATA))

	call xp_stats (xp, INSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("inoisemodel")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKREADNOISE, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ikreadnoise")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKGAIN, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t\t%s\n")
	    call pargstr ("ikgain")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("ireadnoise")
	    call pargr (xp_statr (xp, IREADNOISE))
	call printf ("%s\t\t%g\n")
	    call pargstr ("igain")
	    call pargr (xp_statr (xp, IGAIN))

	call xp_stats (xp, IKEXPTIME, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ikexptime")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKAIRMASS, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ikairmass")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKFILTER, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ikfilter")
	    call pargstr (Memc[str])
	call xp_stats (xp, IKOBSTIME, Memc[str], SZ_FNAME)
	if (Memc[str] == EOS)
	    call strcpy ("\"\"", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ikobstime")
	    call pargstr (Memc[str])

	call printf ("%s\t\t%g\n")
	    call pargstr ("ietime")
	    call pargr (xp_statr (xp, IETIME))
	call printf ("%s\t%g\n")
	    call pargstr ("iairmass")
	    call pargr (xp_statr (xp, IAIRMASS))
	call xp_stats (xp, IFILTER, Memc[str], SZ_FNAME)
	call printf ("%s\t\t%s\n")
	    call pargstr ("ifilter")
	    call pargstr (Memc[str])
	call xp_stats (xp, IOTIME, Memc[str], SZ_FNAME)
	call printf ("%s\t\t%s\n")
	    call pargstr ("iotime")
	    call pargstr (Memc[str])
	call printf ("\n")

	call sfree (sp)
end


# XP_LEPARS -- Print a list of contour plotting parameters on the standard
# output.

procedure xp_lepars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call printf ("%s\t\t%d\n")
	    call pargstr ("enx")
	    call pargi (xp_stati (xp, ENX))
	call printf ("%s\t\t%d\n")
	    call pargstr ("eny")
	    call pargi (xp_stati (xp, ENY))
	call printf ("%s\t\t%g\n")
	    call pargstr ("ez1")
	    call pargr (xp_statr (xp, EZ1))
	call printf ("%s\t\t%g\n")
	    call pargstr ("ez2")
	    call pargr (xp_statr (xp, EZ2))
	call printf ("%s\t\t%g\n")
	    call pargstr ("ez0")
	    call pargr (xp_statr (xp, EZ0))
	call printf ("%s\t%d\n")
	    call pargstr ("encontours")
	    call pargi (xp_stati (xp, ENCONTOURS))
	call printf ("%s\t\t%g\n")
	    call pargstr ("edz")
	    call pargr (xp_statr (xp, EDZ))
	if (xp_strwrd (xp_stati (xp, EHILOMARK), Memc[str], SZ_FNAME,
	    EHILOMARK_OPTIONS) <= 0)
	    call strcpy ("none", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ehilomark")
	    call pargstr (Memc[str])
	call printf ("%s\t%d\n")
	    call pargstr ("edashpat")
	    call pargi (xp_stati (xp, EDASHPAT))
	call printf ("%s\t\t%b\n")
	    call pargstr ("elabel")
	    call pargb (itob (xp_stati (xp, ELABEL)))
	call printf ("%s\t\t%b\n")
	    call pargstr ("ebox")
	    call pargb (itob (xp_stati (xp, EBOX)))
	call printf ("%s\t%b\n")
	    call pargstr ("eticklabel")
	    call pargb (itob (xp_stati (xp, ETICKLABEL)))
	call printf ("%s\t\t%d\n")
	    call pargstr ("exmajor")
	    call pargi (xp_stati (xp, EXMAJOR))
	call printf ("%s\t\t%d\n")
	    call pargstr ("exminor")
	    call pargi (xp_stati (xp, EXMINOR))
	call printf ("%s\t\t%d\n")
	    call pargstr ("eymajor")
	    call pargi (xp_stati (xp, EYMAJOR))
	call printf ("%s\t\t%d\n")
	    call pargstr ("eyminor")
	    call pargi (xp_stati (xp, EYMINOR))
	call printf ("%s\t\t%b\n")
	    call pargstr ("eround")
	    call pargb (itob (xp_stati (xp, EROUND)))
	call printf ("%s\t\t%b\n")
	    call pargstr ("efill")
	    call pargb (itob (xp_stati (xp, EFILL)))
	call printf ("\n")

	call sfree (sp)
end


# XP_LAPARS -- Print a list of surface plotting parameters on the standard
# output.

procedure xp_lapars (xp)

pointer	xp		#I the pointer to the main xapphot structure

bool	itob()
int	xp_stati()
real	xp_statr()

begin
	call printf ("\n")
	call printf ("%s\t\t%d\n")
	    call pargstr ("anx")
	    call pargi (xp_stati (xp, ASNX))
	call printf ("%s\t\t%d\n")
	    call pargstr ("any")
	    call pargi (xp_stati (xp, ASNY))
	call printf ("%s\t\t%b\n")
	    call pargstr ("alabel")
	    call pargb (itob (xp_stati (xp, ALABEL)))
	call printf ("%s\t\t%g\n")
	    call pargstr ("az1")
	    call pargr (xp_statr (xp, AZ1))
	call printf ("%s\t\t%g\n")
	    call pargstr ("az2")
	    call pargr (xp_statr (xp, AZ2))
	call printf ("%s\t\t%g\n")
	    call pargstr ("angh")
	    call pargr (xp_statr (xp, ANGH))
	call printf ("%s\t\t%g\n")
	    call pargstr ("angv")
	    call pargr (xp_statr (xp, ANGV))
	call printf ("\n")
end


# XP_LOPARS -- Print a list of the objects list parameters on the standard
# output.

procedure xp_lopars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call printf ("%s\t\t%b\n")
            call pargstr ("objmark")
            call pargb (itob (xp_stati (xp, OBJMARK)))
        call printf ("%s\t%g\n")
            call pargstr ("otolerance")
            call pargr (xp_statr (xp, OTOLERANCE))
        if (xp_strwrd (xp_stati (xp, OCHARMARK), Memc[str], SZ_FNAME,
            OMARKERS) <= 0)
            call strcpy ("plus", Memc[str], SZ_FNAME)
        call printf ("%s\t%s\n")
            call pargstr ("ocharmark")
            call pargstr (Memc[str])
	call printf ("%s\t\t%b\n")
            call pargstr ("onumber")
            call pargb (itob (xp_stati (xp, ONUMBER)))
        if (xp_strwrd (xp_stati (xp, OPCOLORMARK), Memc[str], SZ_FNAME,
            OCOLORS) <= 0)
            call strcpy ("green", Memc[str], SZ_FNAME)
        call printf ("%s\t%s\n")
            call pargstr ("opcolormark")
            call pargstr (Memc[str])
        if (xp_strwrd (xp_stati (xp, OSCOLORMARK), Memc[str], SZ_FNAME,
            OCOLORS) <= 0)
            call strcpy ("blue", Memc[str], SZ_FNAME)
        call printf ("%s\t%s\n")
            call pargstr ("oscolormark")
            call pargstr (Memc[str])
        call printf ("%s\t%g\n")
            call pargstr ("osizemark")
            call pargr (xp_statr (xp, OSIZEMARK))
        call printf ("\n")

	call sfree (sp)
end


# XP_LCPARS -- Print a list of the centering parameters on the standard
# output.

procedure xp_lcpars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call xp_stats (xp, CSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("calgorithm")
	    call pargstr (Memc[str])
	call printf ("%s\t\t%g\n")
	    call pargstr ("cradius")
	    call pargr (xp_statr (xp, CRADIUS))
	call printf ("%s\t%g\n")
	    call pargstr ("cthreshold")
	    call pargr (xp_statr (xp, CTHRESHOLD))
	call printf ("%s\t%g\n")
	    call pargstr ("cminsnratio")
	    call pargr (xp_statr (xp, CMINSNRATIO))
	call printf ("%s\t%d\n")
	    call pargstr ("cmaxiter")
	    call pargi (xp_stati (xp, CMAXITER))
	call printf ("%s\t%g\n")
	    call pargstr ("cxyshift")
	    call pargr (xp_statr (xp, CXYSHIFT))

	call printf ("%s\t\t%b\n")
	    call pargstr ("ctrmark")
	    call pargb (itob (xp_stati (xp, CTRMARK)))
	if (xp_strwrd (xp_stati (xp, CCHARMARK), Memc[str], SZ_FNAME,
	    CMARKERS) <= 0)
	    call strcpy ("plus", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ccharmark")
	    call pargstr (Memc[str])
	if (xp_strwrd (xp_stati (xp, CCOLORMARK), Memc[str], SZ_FNAME,
	    CCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("ccolormark")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("csizemark")
	    call pargr (xp_statr (xp, CSIZEMARK))
	call printf ("\n")

	call sfree (sp)
end


# XP_LSPARS -- Print a list of the sky fitting parameters on the standard
# output.

procedure xp_lspars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_strwrd(), xp_stati()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call xp_stats (xp, SMSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t\t%s\n")
	    call pargstr ("smode")
	    call pargstr (Memc[str])
	call xp_stats (xp, SGEOSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("sgeometry")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("srannulus")
	    call pargr (xp_statr (xp, SRANNULUS))
	call printf ("%s\t%g\n")
	    call pargstr ("swannulus")
	    call pargr (xp_statr (xp, SWANNULUS))
	call printf ("%s\t%g\n")
	    call pargstr ("saxratio")
	    call pargr (xp_statr (xp, SAXRATIO))
	call printf ("%s\t%g\n")
	    call pargstr ("sposangle")
	    call pargr (xp_statr (xp, SPOSANGLE))

	call xp_stats (xp, SSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("salgorithm")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("sconstant")
	    call pargr (xp_statr (xp, SCONSTANT))
	call printf ("%s\t\t%g\n")
	    call pargstr ("shwidth")
	    call pargr (xp_statr (xp, SHWIDTH))
	call printf ("%s\t%g\n")
	    call pargstr ("shbinsize")
	    call pargr (xp_statr (xp, SHBINSIZE))
	call printf ("%s\t%b\n")
	    call pargstr ("shsmooth")
	    call pargb (itob (xp_stati (xp, SHSMOOTH)))
	call printf ("%s\t%d\n")
	    call pargstr ("smaxiter")
	    call pargi (xp_stati (xp, SMAXITER))

	call printf ("%s\t\t%g\n")
	    call pargstr ("sloclip")
	    call pargr (xp_statr (xp, SLOCLIP))
	call printf ("%s\t\t%g\n")
	    call pargstr ("shiclip")
	    call pargr (xp_statr (xp, SHICLIP))
	call printf ("%s\t%d\n")
	    call pargstr ("snreject")
	    call pargi (xp_stati (xp, SNREJECT))
	call printf ("%s\t%g\n")
	    call pargstr ("sloreject")
	    call pargr (xp_statr (xp, SLOREJECT))
	call printf ("%s\t%g\n")
	    call pargstr ("shireject")
	    call pargr (xp_statr (xp, SHIREJECT))
	call printf ("%s\t\t%g\n")
	    call pargstr ("srgrow")
	    call pargr (xp_statr (xp, SRGROW))

	call printf ("%s\t\t%b\n")
	    call pargstr ("skymark")
	    call pargb (itob (xp_stati (xp, SKYMARK)))
	if (xp_strwrd (xp_stati (xp, SCOLORMARK), Memc[str], SZ_FNAME,
	    SCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("scolormark")
	    call pargstr (Memc[str])
	call printf ("\n")

	call sfree (sp)
end


# XP_LPPARS -- Print a list of the sky fitting parameters on the standard
# output.

procedure xp_lppars (xp)

pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, str
bool	itob()
int	xp_stati(), xp_strwrd()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str, SZ_FNAME, TY_CHAR)

	call printf ("\n")
	call xp_stats (xp, PGEOSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("pgeometry")
	    call pargstr (Memc[str])
	call xp_stats (xp, PAPSTRING, Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("papertures")
	    call pargstr (Memc[str])
	call printf ("%s\t%g\n")
	    call pargstr ("paxratio")
	    call pargr (xp_statr (xp, PAXRATIO))
	call printf ("%s\t%g\n")
	    call pargstr ("pposangle")
	    call pargr (xp_statr (xp, PPOSANGLE))
	call printf ("%s\t\t%g\n")
	    call pargstr ("pzmag")
	    call pargr (xp_statr (xp, PZMAG))
	call printf ("%s\t%b\n")
	    call pargstr ("photmark")
	    call pargb (itob (xp_stati (xp, PHOTMARK)))
	if (xp_strwrd (xp_stati (xp, PCOLORMARK), Memc[str], SZ_FNAME,
	    PCOLORS) <= 0)
	    call strcpy ("red", Memc[str], SZ_FNAME)
	call printf ("%s\t%s\n")
	    call pargstr ("pcolormark")
	    call pargstr (Memc[str])
	call printf ("\n")

	call sfree (sp)
end


# XP_LFPARS -- Print a list of the object detection parameters on the standard
# output.

procedure xp_lfpars (xp)

pointer	xp		#I the pointer to the main xapphot structure

real	xp_statr()

begin
	call printf ("\n")
	call printf ("%s\t%g\n")
	    call pargstr ("fthreshold")
	    call pargr (xp_statr (xp, FTHRESHOLD))
	call printf ("%s\t\t%g\n")
	    call pargstr ("fradius")
	    call pargr (xp_statr (xp, FRADIUS))
	call printf ("%s\t\t%g\n")
	    call pargstr ("fsepmin")
	    call pargr (xp_statr (xp, FSEPMIN))
	call printf ("%s\t%g\n")
	    call pargstr ("froundlo")
	    call pargr (xp_statr (xp, FROUNDLO))
	call printf ("%s\t%g\n")
	    call pargstr ("froundhi")
	    call pargr (xp_statr (xp, FROUNDHI))
	call printf ("%s\t%g\n")
	    call pargstr ("fsharplo")
	    call pargr (xp_statr (xp, FSHARPLO))
	call printf ("%s\t%g\n")
	    call pargstr ("fsharphi")
	    call pargr (xp_statr (xp, FSHARPHI))
	call printf ("\n")
end
