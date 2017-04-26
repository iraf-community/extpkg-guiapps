include "../lib/impars.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

define	FND_NSTR "#N%4tXINIT%14tYINIT%24tMAG%33tAREA%41tHWIDTH%49tELL\
%56tTHETA%64tSHARPRAT%73tID%80t\\\n"
define	FND_USTR "#U%4tpixels%14tpixels%24t##%33tpixels%41tpixels%49t##\
%56tdegrees%64t##%73t##%80t\\\n"
define	FND_FSTR "#F%4t%%-13.3f%14t%%-10.3f%24t%%-9.3f%33t%%-8d%41t%%-8.2f\
%49t%%-7.2f%56t%%-8.2f%64t%%-9.2f%73t%%-6d%80t \n"

# XP_FBNR -- Write out the banner for the XFIND task.

procedure xp_xfbnr(xp, fd)

pointer	xp		#I the xapphot descriptor (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call fprintf (fd, FND_NSTR)
	call fprintf (fd, FND_USTR)
	call fprintf (fd, FND_FSTR)
	call fprintf (fd, "#\n")
end


# XP_XCBNR -- Write out the banner for the XCENTER task.

procedure xp_xcbnr (xp, fd)

pointer	xp		#I the xapphot descriptor (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call xp_widbnr (xp, fd)
	call xp_wcbnr (xp, fd)
end


# XP_XSBNR -- Write out the banner for the XFITSKY task.

procedure xp_xsbnr (xp, fd)

pointer	xp		#I the xapphot descriptor (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call xp_widbnr (xp, fd)
	call xp_wsbnr (xp, fd)
end


# XP_XPBNR -- Write out the banner for the XPHOT task.

procedure xp_xpbnr (xp, fd)

pointer	xp		#I the xapphot descriptor (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call xp_widbnr (xp, fd)
	call xp_wcbnr (xp, fd)
	call xp_wmbnr (xp, fd)
	call xp_wsbnr (xp, fd)
	call xp_wpbnr (xp, fd)
end


define	ID_NSTR	"#N%4tXINIT%15tYINIT%26tID%32tOBJECTS%55tLID%80t\\\n"
define	ID_USTR	"#U%4tpixels%15tpixels%26t##%32tfilename%55t##%80t\\\n"
define	ID_FSTR	"#F%4t%%-11.3f%15t%%-14.3f%26t%%-6d%32t%%-23s%55t%%-6d%80t \n"
define	ID_WSTR "%-11.3f%12t%-14.3f%26t%-6d%32t%-23.23s%55t%-6d%80t%c\n"


# XP_WIDBNR -- Write the id column header strings.

procedure xp_widbnr (xp, fd)

pointer	xp		#I the xapphot descriptor (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call fprintf (fd, ID_NSTR)
	call fprintf (fd, ID_USTR)
	call fprintf (fd, ID_FSTR)
	call fprintf (fd, "#\n")
end


# XP_WID -- Write the id record.

procedure xp_wid (xp, fd, xpos, ypos, id, objects, lid, lastchar)

pointer	xp		#I the xapphot structure (currently unused)
int	fd		#I the output file descriptor
real	xpos		#I the initial x position
real	ypos		#I the initial y position
int	id		#I the id of the object
char	objects[ARB]	#I the objects file name
int	lid		#I the list id of the object
int	lastchar	#I the last character in record

begin
	if (fd == NULL)
	    return

	# Print description of object.
	if (objects[1] == EOS)
	    call strcpy ("nullfile", objects, SZ_FNAME)
	call fprintf (fd, ID_WSTR)
	    call pargr (xpos)
	    call pargr (ypos)
	    call pargi (id)
	    call pargstr (objects)
	    call pargi (lid)
	    call pargi (lastchar)

end



define	CTR_NSTR  "#N%4tXCENTER%15tYCENTER%26tXSHIFT%34tYSHIFT%42tXERR%50t\
YERR%66tCIER%71tCERROR%80t\\\n"
define	CTR_USTR  "#U%4tpixels%15tpixels%26tpixels%34tpixels%42tpixels%50t\
pixels%66t##%71tcerrors%80t\\\n"
define	CTR_FSTR  "#F%4t%%-14.3f%15t%%-11.3f%26t%%-8.3f%34t%%-8.3f%42t\
%%-8.3f%50t%%-16.3f%66t%%-4d%71t%%-9s%80t \n"
define  CTR_WSTR   "%4t%-11.3f%-11.3f%-8.3f%-8.3f%-8.3f%-16.3f%-4d%-9.9s\
%80t%c\n"


# XP_WCBNR - Print the center algorithm column header strings.

procedure xp_wcbnr (xp, fd)

pointer	xp		#I the xapphot descriptor (unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return
	call fprintf (fd, CTR_NSTR)
	call fprintf (fd, CTR_USTR)
	call fprintf (fd, CTR_FSTR)
	call fprintf (fd, "#\n")
end


# XP_WCRES -- Write out the centering algorithm results to a file.

procedure xp_wcres (xp, fd, ier, lastchar)

pointer	xp		#I the pointer to apphot structure
int	fd		#I the output file descriptor
int	ier		#I the error code
int	lastchar	#I the last character to be written out

pointer	sp, str
real	xp_statr()

begin
	if (fd == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call xp_cserrors (ier, Memc[str], SZ_LINE)

	# Print the computed centers.
	call fprintf (fd, CTR_WSTR)
	    call pargr (xp_statr (xp, XCENTER))
	    call pargr (xp_statr (xp, YCENTER))
	    call pargr (xp_statr (xp, XSHIFT))
	    call pargr (xp_statr (xp, YSHIFT))
	    call pargr (xp_statr (xp, XERR))
	    call pargr (xp_statr (xp, YERR))
	    call pargi (ier)
	    call pargstr (Memc[str])
	    call pargi (lastchar)

	call sfree (sp)
end


# XP_CSERRORS -- Encode the centering task error messages into a string.

procedure xp_cserrors (ier, str, maxch)

int	ier		#I the error code
char	str[ARB]	#I the output string
int	maxch		#I the maximum number of characters

begin
	switch (ier) {
	case XP_CTR_NOIMAGE:
	    call strcpy ("NoImage", str, maxch)
	case XP_CTR_NOPIXELS:
	    call strcpy ("OffImage", str, maxch)
        case XP_CTR_OFFIMAGE:
	    call strcpy ("EdgeImage", str, maxch)
	case XP_CTR_TOOSMALL:
	    call strcpy ("TooFewPts", str, maxch)
	case XP_CTR_BADDATA:
	    call strcpy ("BadPixels", str, maxch)
	case XP_CTR_LOWSNRATIO:
	    call strcpy ("LowSnr", str, maxch)
	case XP_CTR_SINGULAR:
	    call strcpy ("Singular", str, maxch)
	case XP_CTR_NOCONVERGE:
	    call strcpy ("BadFit", str, maxch)
	case XP_CTR_BADSHIFT:
	    call strcpy ("BigShift", str, maxch)
	default:
	    call strcpy ("NoError", str, maxch)
	}
end


# define the #N, #U and #K fitsky strings

define	SKY_NSTR  "#N%4tXSKY%15tYSKY%26tMSKY%39tSTDEV%51tNSKY%59tNREJ%66tSIER\
%71tSERROR%80t\\\n"
define	SKY_USTR  "#U%4tpixels%15tpixels%26tcounts%39tcounts%51tnpix%59tnpix\
%66t##%71tserrors%80t\\\n"
define	SKY_FSTR  "#F%4t%%-14.3f%15t%%-11.3f%26t%%-13.7g%39t%%-12.7g%51t\
%%-8d%59t%%-7d%66t%%-4d%71t%%-9s%80t \n"
define  SKY_WSTR  "%4t%-11.3f%-11.3f%-13.7g%-12.7g%-8d%-7d%-4d%-9.9s%80t%c\n"

# XP_WSBNR -- Print the sky fitting column header strings.

procedure xp_wsbnr (xp, fd)

pointer	xp		#I the xapphot structure pointer (currently unused)
int	fd		#I the output file descriptor

begin
	if (fd == NULL)
	    return

	call fprintf (fd, SKY_NSTR)
	call fprintf (fd, SKY_USTR)
	call fprintf (fd, SKY_FSTR)
	call fprintf (fd, "#\n")
end


# XP_WSRES -- Write the results of the sky fitting algorithms to the output
# file.

procedure xp_wsres (xp, fd, ier, lastchar)

pointer xp		#I the pointer to the xapphot structure
int	fd		#I the output file descriptor
int	ier		#I the error code
int	lastchar	#I the last character

int	xp_stati()
real	xp_statr()

pointer	sp, str

begin
	if (fd == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call xp_sserrors (ier, Memc[str], SZ_LINE)

	# Print the computed sky value and statistics.
	call fprintf (fd, SKY_WSTR)
	    call pargr (xp_statr (xp, SXCUR))
	    call pargr (xp_statr (xp, SYCUR))
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (xp_statr (xp, SKY_STDEV))
	    call pargi (xp_stati (xp, NSKY))
	    call pargi (xp_stati (xp, NSKY_REJECT))
	    call pargi (ier)
	    call pargstr (Memc[str])
	    call pargi (lastchar)

	call sfree (sp)
end


# XP_SSERRORS -- Encode the sky fitting error messages in a string.

procedure xp_sserrors (ier, str, maxch)

int	ier		#I the error code
char	str[ARB]	#O the output string
int	maxch		#I the maximum number of characters

begin
	switch (ier) {
	case XP_SKY_NOIMAGE:
	    call strcpy ("NoImage", str, maxch)
	case XP_SKY_NOPIXELS:
	    call strcpy ("OffImage", str, maxch)
	case XP_SKY_OFFIMAGE:
	    call strcpy ("EdgeImage", str, maxch)
	case XP_SKY_NOHISTOGRAM:
	    call strcpy ("NoHist", str, maxch)
	case XP_SKY_FLATHISTOGRAM:
	    call strcpy ("FlatHist", str, maxch)
	case XP_SKY_TOOSMALL:
	    call strcpy ("TooFewPts", str, maxch)
	case XP_SKY_SINGULAR:
	    call strcpy ("Singular", str, maxch)
	case XP_SKY_NOCONVERGE:
	    call strcpy ("BadFit", str, maxch)
	case XP_SKY_NOGRAPHICS:
	    call strcpy ("NoGraph", str, maxch)
	case XP_SKY_NOFILE:
	    call strcpy ("NoFile", str, maxch)
	case XP_SKY_ATEOF:
	    call strcpy ("ShortFile", str, maxch)
	case XP_SKY_BADSCAN:
	    call strcpy ("BadRecord", str, maxch)
	case XP_SKY_BADPARS:
	    call strcpy ("BadParams", str, maxch)
	default:
	    call strcpy ("NoError", str, maxch)
	}
end


define  MAG_NSTR  "#N%4tRAPERT%13tSUM%26tAREA%38tFLUX%51tMAG%59tMERR%66t\
PIER%71tPERROR%80t\\\n"
define  MAG_USTR  "#U%4tscale%13tcounts%26tpixels%38tcounts%51tmag%59t\
mag%66t##%71tperrors%80t\\\n"
define  MAG_FSTR  "#F%4t%%-12.2f%13t%%-13.7g%26t%%-12.7g%38t%%-13.7g%51t\
%%-8.3f%59t%%-7.3f%66t%%-4d%71t%%-9s%80t \n"
define  MAG_WSTR  "%4t%-9.2f%-13.7g%-12.7g%-13.7g%-8.3f%-7.3f%-4d%-9.9s\
%79t%2s\n"


# XP_WPBNR -- Print the photometry column header strings.

procedure xp_wpbnr (xp, fd)

pointer xp              #I the xapphot descriptor (currently unused)
int     fd              #I the output file descriptor

begin
        if (fd == NULL)
            return

        call fprintf (fd, MAG_NSTR)
        call fprintf (fd, MAG_USTR)
        call fprintf (fd, MAG_FSTR)
        call fprintf (fd, "#\n")
end


# XP_WPRES -- Write the results of the XPHOT task to the output file.

procedure xp_wpres (xp, fd, i, pier, endstr)

pointer xp              #I the pointer to xapphot structure
int     fd              #I the output text file descriptor
int     i               #I the index of the variable length field
int     pier            #I the photometric error code
char    endstr[ARB]     #I the text termination string

int     ier
pointer sp, str
int	xp_stati()
pointer	xp_statp()

begin
        # Initialize.
        if (fd == NULL)
            return

        call smark (sp)
        call salloc (str, SZ_LINE, TY_CHAR)

        # Determine the error code and encode it.
        if (IS_INDEFR(Memr[xp_statp(xp,MAGS)+i-1])) {
            if (pier != XP_APERT_OUTOFBOUNDS)
                ier = pier
            else if (i > xp_stati(xp,NMAXAP))
                ier = XP_APERT_OUTOFBOUNDS
            else
                ier = XP_OK
        } else if (i >= xp_stati(xp,NMINAP))
            ier = XP_APERT_BADDATA
        else
            ier = XP_OK
        call xp_pserrors (ier, Memc[str], SZ_LINE)

        # Write out the photometry results.
        call fprintf (fd, MAG_WSTR)
        if (i == 0) {
            call pargr (0.0)
            call pargr (0.0)
            call pargr (0.0)
            call pargr (0.0)
            call pargr (INDEFR)
            call pargr (INDEFR)
            call pargi (ier)
            call pargstr (Memc[str])
            call pargstr (endstr)
        } else {
            call pargr (Memr[xp_statp(xp,PAPERTURES)+i-1])
            call pargd (Memd[xp_statp(xp,SUMS)+i-1])
            call pargd (Memd[xp_statp(xp,AREAS)+i-1])
            call pargd (Memd[xp_statp(xp,FLUX)+i-1])
            call pargr (Memr[xp_statp(xp,MAGS)+i-1])
            if (Memr[xp_statp(xp,MAGERRS)+i-1] > 99.999)
                call pargr (INDEFR)
            else
                call pargr (Memr[xp_statp(xp,MAGERRS)+i-1])
            call pargi (ier)
            call pargstr (Memc[str])
            call pargstr (endstr)
        }

        call sfree (sp)
end


# XP_PSERRORS -- Encode the photometric errors string.

procedure xp_pserrors (ier, str, maxch)

int     ier             #I the photometry error code
char    str[ARB]        #O the  output string
int     maxch           #I the maximum length of string

begin
        switch (ier) {
        case XP_APERT_NOAPERT:
            call strcpy ("OffImage", str, maxch)
        case XP_APERT_OUTOFBOUNDS:
            call strcpy ("EdgeImage", str, maxch)
        case XP_APERT_NOSKYMODE:
            call strcpy ("NoSky", str, maxch)
        case XP_APERT_TOOFAINT:
            call strcpy ("NoFlux", str, maxch)
        case XP_APERT_BADDATA:
            call strcpy ("BadPixels", str, maxch)
        default:
            call strcpy ("NoError", str, maxch)
        }
end


define  MOM_NSTR  "#N%4tHWIDTH%13tSHARPNESS%26tAXRATIO%39tELL%51tTHETA\
%66tRIER%71tRERROR%80t\\\n"
define  MOM_USTR  "#U%4tscale%13tnumber%26tnumber%39tnumber%51tdegrees\
%66t##%71trerrors%80t\\\n"
define  MOM_FSTR  "#F%4t%%-12.2f%13t%%-13.3f%26t%%-13.3f%39t%%-12.3f%51t\
%%-15.2f%66t%%-4d%71t%%-9s%80t \n"
define  MOM_WSTR  "%4t%-9.2f%-13.3f%-13.3f%-12.3f%-15.2f%-4d%-9.9s%79t%2s\n"


# XP_WMBNR -- Print the moments analysis column header strings.

procedure xp_wmbnr (xp, fd)

pointer xp              #I the xapphot descriptor (currently unused)
int     fd              #I the output file descriptor

begin
        if (fd == NULL)
            return

        call fprintf (fd, MOM_NSTR)
        call fprintf (fd, MOM_USTR)
        call fprintf (fd, MOM_FSTR)
        call fprintf (fd, "#\n")
end


# XP_WMRES -- Write the results of the XPHOT task to the output file.

procedure xp_wmres (xp, fd, i, pier, endstr)

pointer xp              #I the pointer to xapphot structure
int     fd              #I the output text file descriptor
int     i               #I the index of the variable length field
int     pier            #I the photometric error code (not currently used)
char    endstr[ARB]     #I the text termination string

int	ier
pointer	sp, str
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
        # Initialize.
        if (fd == NULL)
            return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

        # Determine the error code and encode it.
        if (IS_INDEFR(Memr[xp_statp(xp,MAGS)+i-1])) {
            if (pier != XP_APERT_OUTOFBOUNDS)
                ier = pier
            else if (i > xp_stati(xp,NMAXAP))
                ier = XP_APERT_OUTOFBOUNDS
            else
                ier = XP_OK
        } else if (i >= xp_stati(xp,NMINAP))
            ier = XP_APERT_BADDATA
        else
            ier = XP_OK
        call xp_pserrors (ier, Memc[str], SZ_LINE)

        # Write out the moments analysis results.
        call fprintf (fd, MOM_WSTR)
        if (i == 0) {
            call pargr (INDEFR)
            call pargr (INDEFR)
            call pargr (INDEFR)
            call pargr (INDEFR)
            call pargr (INDEFR)
	    call pargi (ier)
	    call pargstr (Memc[str])
            call pargstr (endstr)
        } else {
	    if (IS_INDEFR(Memr[xp_statp(xp,MHWIDTHS)+i-1])) {
		call pargr (INDEFR)
		call pargr (INDEFR)
	    } else {
                call pargr (Memr[xp_statp(xp,MHWIDTHS)+i-1] / xp_statr(xp,
		    ISCALE))
                call pargr (Memr[xp_statp(xp,MHWIDTHS)+i-1] / (xp_statr(xp,
		    IHWHMPSF) * xp_statr(xp,ISCALE)))
	    }
	    if (IS_INDEFR(Memr[xp_statp(xp,MAXRATIOS)+i-1])) {
		call pargr (INDEFR)
		call pargr (INDEFR)
	    } else {
                call pargr (Memr[xp_statp(xp,MAXRATIOS)+i-1])
                call pargr (1.0 - Memr[xp_statp(xp,MAXRATIOS)+i-1])
	    }
            call pargr (Memr[xp_statp(xp,MPOSANGLES)+i-1])
	    call pargi (ier)
	    call pargstr (Memc[str])
            call pargstr (endstr)
        }

	call sfree (sp)
end
