include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/find.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"
include <time.h>

# XP_WHFIND -- Procedure to write the header for the XDISPLAY task.

procedure xp_whfind (xp, out, task)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output file descriptor
char	task[ARB]	#I the task name

begin
	if (out == NULL)
	    return

	# Write out the logistics parameters.
	call xp_whid (xp, out, task)

	# Write out the image parameters.
	call xp_whimpars (xp, out)

	# Write out the object detection parameters.
	call xp_whfindpars (xp, out)
end


# XP_WHCTR -- Procedure to write the header for the XCENTER task.

procedure xp_whctr (xp, out, task)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output file descriptor
char	task[ARB]	#I the task name

begin
	if (out == NULL)
	    return

	# Write out the logistics parameters.
	call xp_whid (xp, out, task)

	# Write out the image parameters.
	call xp_whimpars (xp, out)

	# Write out the centering algorithm parameters.
	call xp_whctrpars (xp, out)
end


# XP_WHSKY -- Procedure to write the header for the XFITSKY task.

procedure xp_whsky (xp, out, task)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output file descriptor
char	task[ARB]	#I the task name

begin
	if (out == NULL)
	    return

	# Write out the logistics parameters.
	call xp_whid (xp, out, task)

	# Write out the image parameters.
	call xp_whimpars (xp, out)

	# Write out the sky fitting algorithm parameters.
	call xp_whskypars (xp, out)
end


# XP_WHPHOT -- Procedure to write te header of the XPHOT task.

procedure xp_whphot (xp, out, task)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output file descriptor
char	task[ARB]	#I the task name

begin
	if (out == NULL)
	    return

	# Write out the logistics parameters.
	call xp_whid (xp, out, task)

	# Write out the image parameters.
	call xp_whimpars (xp, out)

	# Write out the centering algorithm parameters.
	call xp_whctrpars (xp, out)

	# Write out the sky fitting algorithm parameters.
	call xp_whskypars (xp, out)

	# Write out the photometry algorithm parameters.
	call xp_whphotpars (xp, out)
end



# XP_WHID -- Procedure to write the xapphot parameters to a text file.

procedure xp_whid (xp, out, task)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output file descriptor
char	task[ARB]	#I the task name

int	nchars
pointer	sp, str, date, time
int	envfind(), gstrcpy()

begin
	if (out == NULL)
	    return
	 
	# Allocate working space.
	call smark (sp)
	call salloc (date, SZ_DATE, TY_CHAR)
	call salloc (time, SZ_DATE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Write the IRAF version.
	nchars = envfind ("version", Memc[str], SZ_LINE)
	if (nchars <= 0)
	    nchars = gstrcpy ("NOAO/IRAF", Memc[str], SZ_LINE)
	call xp_rmwhite (Memc[str], Memc[str], SZ_LINE)
	call xp_sparam (out, "IRAF", Memc[str], "version", "")

	# Write the user id.
	nchars = envfind ("userid", Memc[str], SZ_LINE)
	call xp_sparam (out, "USER", Memc[str], "name", "")

	# Write the host computer.
	call gethost (Memc[str], SZ_LINE)
	call xp_sparam (out, "HOST", Memc[str], "computer", "")

	# Write the date and time.
	call xp_date (Memc[date], Memc[time], SZ_DATE)
	call xp_sparam (out, "DATE", Memc[date], "mm-dd-yr", "")
	call xp_sparam (out, "TIME", Memc[time], "hh:mm:ss", "")

	# Write the package and task.
	call xp_sparam (out, "PACKAGE", "xapphot", "name", "")
	call xp_sparam (out, "TASK", task, "name", "")
	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHIMPARS -- Procedure to write out the image parameters.

procedure xp_whimpars (xp, out)

pointer	xp		#I the xapphot structure pointer
int	out		#I the output file descriptor

int	i, param, punits
pointer	sp, str, keyword, units
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (out == NULL)
	    return
	if (xp_statp (xp,PIMPARS) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)


	do i = 1, 19 {

	    param = xp_strwrd (i, Memc[keyword], SZ_FNAME, ICMDS)
	    punits = xp_strwrd (i, Memc[units], SZ_FNAME, HICMDS)

	    switch (i) {

	    case ICMD_ISCALE:
	        call xp_rparam (out, Memc[keyword], 1.0 / xp_statr (xp, ISCALE),
	            Memc[units], "")
	    case ICMD_IHWHMPSF:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, IHWHMPSF),
	            Memc[units], "")
	    case ICMD_ISKYSIGMA:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, ISKYSIGMA),
	            Memc[units], "")
	    case ICMD_IEMISSION:
	        call xp_bparam (out, Memc[keyword], itob (xp_stati (xp,
		    IEMISSION)), Memc[units], "")
	    case ICMD_IMINDATA:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, IMINDATA),
	            Memc[units], "")
	    case ICMD_IMAXDATA:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, IMAXDATA),
	            Memc[units], "")

	    case ICMD_INOISEMODEL:
	        call xp_stats (xp, INSTRING, Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case ICMD_IKGAIN:
	        call xp_stats (xp, IKGAIN, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case ICMD_IKREADNOISE:
	        call xp_stats (xp, IKREADNOISE, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")

	    case ICMD_IKEXPTIME:
	        call xp_stats (xp, IKEXPTIME, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case ICMD_IKAIRMASS:
	        call xp_stats (xp, IKAIRMASS, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case ICMD_IKFILTER:
	        call xp_stats (xp, IKFILTER, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case ICMD_IKOBSTIME:
	        call xp_stats (xp, IKOBSTIME, Memc[str], SZ_FNAME)
	        if (Memc[str] == EOS)
	            call strcpy ("\"\"", Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    default:
		;
	    }
	}

	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHFINDPARS -- Procedure to write out the object detection parameters.

procedure xp_whfindpars (xp, out)

pointer	xp		#I the xapphot structure pointer
int	out		#I the output file descriptor

int	i, param, punits
pointer	sp, keyword, units, str
int	xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (out == NULL)
	    return
	if (xp_statp (xp,PFIND) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	do i = 1, 7 {

	    param = xp_strwrd (i, Memc[keyword], SZ_FNAME, LCMDS)
	    punits = xp_strwrd (i, Memc[units], SZ_FNAME, HLCMDS)

	    switch (i) {
	    case LCMD_FTHRESHOLD:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FTHRESHOLD),
		    Memc[units], "")
	    case LCMD_FRADIUS:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FRADIUS),
		    Memc[units], "")
	    case LCMD_FSEPMIN:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FSEPMIN),
		    Memc[units], "")
	    case LCMD_FROUNDLO:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FROUNDLO),
		    Memc[units], "")
	    case LCMD_FROUNDHI:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FROUNDHI),
		    Memc[units], "")
	    case LCMD_FSHARPLO:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FSHARPLO),
		    Memc[units], "")
	    case LCMD_FSHARPHI:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, FSHARPHI),
		    Memc[units], "")
	    default:
		;
	    }
	}

	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHIMINFO -- Procedure to write out the image parameters.

procedure xp_whiminfo (xp, out)

pointer	xp		#I the xapphot structure pointer
int	out		#I the output file descriptor

int	param, punits
pointer	sp, keyword, units, str
int	xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (out == NULL)
	    return
	if (xp_statp (xp,PIMPARS) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	# Write out the image name using IMAGE instead of IMNAME to conform
	# to the other digiphot packages.
	param = xp_strwrd (FCMD_IMAGE, Memc[keyword], SZ_FNAME, FCMDS)
	#punits = xp_strwrd (FCMD_IMAGE, Memc[units], SZ_FNAME, HFCMDS)
	call strcpy ("name", Memc[units], SZ_FNAME)
	call xp_stats (xp, IMAGE, Memc[str], SZ_FNAME)
	#call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	call xp_sparam (out, "IMAGE", Memc[str], Memc[units], "")

	# Write out the gain in electrons / ADU.
	param = xp_strwrd (ICMD_IGAIN, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IGAIN, Memc[units], SZ_FNAME, HICMDS)
	call xp_rparam (out, Memc[keyword], xp_statr (xp,IGAIN),
	    Memc[units], "")

	# Write out the readout noise in electrons.
	param = xp_strwrd (ICMD_IREADNOISE, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IREADNOISE, Memc[units], SZ_FNAME, HICMDS)
	call xp_rparam (out, Memc[keyword], xp_statr (xp,IREADNOISE),
	    Memc[units], "")

	# Write out the filter id.
	param = xp_strwrd (ICMD_IFILTER, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IFILTER, Memc[units], SZ_FNAME, HICMDS)
	call xp_stats (xp, IFILTER, Memc[str], SZ_FNAME)
	call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")

	# Write out the exposure time using ITIME instead of IETIME to conform
	# to the other digiphot packages.
	param = xp_strwrd (ICMD_IETIME, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IETIME, Memc[units], SZ_FNAME, HICMDS)
	#call xp_rparam (out, Memc[keyword], xp_statr (xp,IETIME),
	    #Memc[units], "")
	call xp_rparam (out, "ITIME", xp_statr (xp,IETIME),
	    Memc[units], "")

	# Write out the airmass using XAIRMASS instead of IAIRMASS  to conform
	# to the other digiphot packages.
	param = xp_strwrd (ICMD_IAIRMASS, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IAIRMASS, Memc[units], SZ_FNAME, HICMDS)
	#call xp_rparam (out, Memc[keyword], xp_statr (xp,IAIRMASS),
	    #Memc[units], "")
	call xp_rparam (out, "XAIRMASS", xp_statr (xp,IAIRMASS),
	    Memc[units], "")

	# Write out the airmass using OTIME instead of IOTIME to conform to
	# the other digiphot packages.
	param = xp_strwrd (ICMD_IOTIME, Memc[keyword], SZ_FNAME, ICMDS)
	punits = xp_strwrd (ICMD_IOTIME, Memc[units], SZ_FNAME, HICMDS)
	call xp_stats (xp, IOTIME, Memc[str], SZ_FNAME)
	#call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	call xp_sparam (out, "OTIME", Memc[str], Memc[units], "")

	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHCTRPARS -- Procedure to write out the centering parameters.

procedure xp_whctrpars (xp, out)

pointer	xp		#I the xapphot structure descriptor
int	out		#I the output file descriptor

int	i, param, punits, str
pointer	sp, keyword, units
int	xp_stati(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (out == NULL)
	    return
	if (xp_statp(xp,PCENTER) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	do i = 1, 6 {
	    param = xp_strwrd (i, Memc[keyword], SZ_FNAME, CCMDS)
	    punits = xp_strwrd (i, Memc[units], SZ_FNAME, HCCMDS)
	    switch (i) {
	    case CCMD_CALGORITHM:
	        call xp_stats (xp, CSTRING, Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case CCMD_CRADIUS:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, CRADIUS),
	            Memc[units], "")
	    case CCMD_CTHRESHOLD:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, CTHRESHOLD),
	        Memc[units], "")
	    case CCMD_CMINSNRATIO:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, CMINSNRATIO),
		    Memc[units], "")
	    case CCMD_CMAXITER:
	        call xp_iparam (out, Memc[keyword], xp_stati (xp, CMAXITER),
	            Memc[units], "")
	    case CCMD_CXYSHIFT:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, CXYSHIFT),
	            Memc[units], "")
	    default:
		;
	    }
	}
	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHSKYPARS -- Procedure to write out the sky fitting  parameters.

procedure xp_whskypars (xp, out)

pointer	xp		#I the pointer to the xapphot structure
int	out		#I the output pointer

int	i, param, punits
pointer sp, keyword, units, str
bool	itob()
int	xp_stati(), xp_strwrd()
pointer	xp_statp()
real	xp_statr()


begin
	if (out == NULL)
	    return
	if (xp_statp(xp,PSKY) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_FNAME, TY_CHAR)
	call salloc (units, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	do i = 1, 18 {

	    param = xp_strwrd (i, Memc[keyword], SZ_FNAME, SCMDS)
	    punits = xp_strwrd (i, Memc[units], SZ_FNAME, HSCMDS)

	    switch (i) {

	    case SCMD_SMODE:
	        call xp_stats (xp, SMSTRING, Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case SCMD_SGEOMETRY:
	        call xp_stats (xp, SGEOSTRING, Memc[str], SZ_LINE)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case SCMD_SRANNULUS:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SRANNULUS),
	            Memc[units], "")
	    case SCMD_SWANNULUS:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SWANNULUS),
	            Memc[units], "")
	    case SCMD_SAXRATIO:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SAXRATIO),
	            Memc[units], "")
	    case SCMD_SPOSANGLE:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SPOSANGLE),
	            Memc[units], "")
	    case SCMD_SALGORITHM:
	        call xp_stats (xp, SSTRING, Memc[str], SZ_FNAME)
	        call xp_sparam (out, Memc[keyword], Memc[str],
		    Memc[units], "")
	    case SCMD_SCONSTANT:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SCONSTANT),
	            Memc[units], "")
	    case SCMD_SLOCLIP:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SLOCLIP),
	            Memc[units], "")
	    case SCMD_SHICLIP:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SHICLIP),
	            Memc[units], "")
	    case SCMD_SHWIDTH:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SHWIDTH),
	            Memc[units], "")
	    case SCMD_SHBINSIZE:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SHBINSIZE),
	            Memc[units], "")
	    case SCMD_SHSMOOTH:
	        call xp_bparam (out, Memc[keyword], itob (xp_stati (xp,
		    SHSMOOTH)), Memc[units], "")
	    case SCMD_SMAXITER:
	        call xp_iparam (out, Memc[keyword], xp_stati (xp, SMAXITER),
	            Memc[units], "")
	    case SCMD_SNREJECT:
	        call xp_iparam (out, Memc[keyword], xp_stati (xp, SNREJECT),
	            Memc[units], "")
	    case SCMD_SLOREJECT:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SLOREJECT),
	            Memc[units], "")
	    case SCMD_SHIREJECT:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SHIREJECT),
	            Memc[units], "")
	    case SCMD_SRGROW:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, SRGROW),
	            Memc[units], "")
	    default:
		;
	    }
	}

	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_WHPHOTPARS -- Procedure to write out the photometry header parameters.

procedure xp_whphotpars (xp, out)

pointer	xp		#I the xapphot structure pointer
int	out		#I the output file descriptor

int	i, param, punits
pointer	sp, keyword, units, str
int	xp_strwrd()
pointer	xp_statp()
real	xp_statr()

begin
	if (out == NULL)
	    return
	if (xp_statp (xp,PPHOT) == NULL)
	    return

	call smark (sp)
	call salloc (keyword, SZ_LINE, TY_CHAR)
	call salloc (units, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	do i = 1, 5 {

	    param = xp_strwrd (i, Memc[keyword], SZ_FNAME, PCMDS)
	    punits = xp_strwrd (i, Memc[units], SZ_FNAME, HPCMDS)

	    switch (i) {
	    case PCMD_PGEOMETRY:
	        call xp_stats (xp, PGEOSTRING, Memc[str], SZ_LINE)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case PCMD_PAPERTURES:
	        call xp_stats (xp, PAPSTRING, Memc[str], SZ_LINE)
	        call xp_sparam (out, Memc[keyword], Memc[str], Memc[units], "")
	    case PCMD_PAXRATIO:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, PAXRATIO),
	            Memc[units], "")
	    case PCMD_PPOSANGLE:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, PPOSANGLE),
	            Memc[units], "")
	    case PCMD_PZMAG:
	        call xp_rparam (out, Memc[keyword], xp_statr (xp, PZMAG),
		    Memc[units], "")
	    default:
		;
	    }
	}

	call fprintf (out, "#\n")

	call sfree (sp)
end


# XP_RPARAM -- Procedure to encode a real xapphot parameter.

procedure xp_rparam (out, keyword, value, units, comments)

int	out		#I the output file descriptor
char	keyword[ARB]	#I the keyword string
real	value		#I the parameter value
char	units[ARB]	#I the units string
char	comments[ARB]	#I the comment string

begin
	if (out == NULL)
	    return

	call strupr (keyword)
        call fprintf (out,
	    "#K%4t%-10.10s%14t = %17t%-23.7g%41t%-10.10s%52t%-10s\n")
	    call pargstr (keyword)
	    call pargr (value)
	    call pargstr (units)
	    call pargstr ("%-23.7g")
	    call pargstr (comments)
end


# XP_IPARAM -- Procedure to encode an integer xapphot parameter.

procedure xp_iparam (out, keyword, value, units, comments)

int	out		#I the output file descriptor
char	keyword[ARB]	#I the keyword string
int	value		#I the parameter value
char	units[ARB]	#I the units string
char	comments[ARB]	#I the comment string

begin
	if (out == NULL)
	    return

	call strupr (keyword)
        call fprintf (out,
	    "#K%4t%-10.10s%14t = %17t%-23d%41t%-10.10s%52t%-10s\n")
	    call pargstr (keyword)
	    call pargi (value)
	    call pargstr (units)
	    call pargstr ("%-23d")
	    call pargstr (comments)
end


# XP_BPARAM -- Procedure to encode a boolean xapphot parameter.

procedure xp_bparam (out, keyword, value, units, comments)

int	out		#I the output file descriptor
char	keyword[ARB]	#I the keyword string
bool	value		#I the parameter value
char	units[ARB]	#I the units string
char	comments[ARB]	#I the comment string

begin
	if (out == NULL)
	    return

	call strupr (keyword)
        call fprintf (out,
	    "#K%4t%-10.10s%14t = %17t%-23b%41t%-10.10s%52t%-10s\n")
	    call pargstr (keyword)
	    call pargb (value)
	    call pargstr (units)
	    call pargstr ("%-23b")
	    call pargstr (comments)
end


# XP_SPARAM -- Procedure to encode a string xapphot parameter.

procedure xp_sparam (out, keyword, value, units, comments)

int	out		# output file descriptor
char	keyword[ARB]	# keyword string
char	value[ARB]	# parameter value
char	units[ARB]	# units string
char	comments[ARB]	# comment string

begin
	if (out == NULL)
	    return

	call strupr (keyword)
        call fprintf (out,
    	    "#K%4t%-10.10s%14t = %17t%-23.23s%41t%-10.10s%52t%-10s\n")
	    call pargstr (keyword)
	    call pargstr (value)
	    call pargstr (units)
	    call pargstr ("%-23s")
	    call pargstr (comments)
end
