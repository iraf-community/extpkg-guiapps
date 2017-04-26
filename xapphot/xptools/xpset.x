include "../lib/xphotdef.h"
include "../lib/xphot.h"
include "../lib/imparsdef.h"
include "../lib/impars.h"
include "../lib/displaydef.h"
include "../lib/display.h"
include "../lib/finddef.h"
include "../lib/find.h"
include "../lib/objectsdef.h"
include "../lib/objects.h"
include "../lib/centerdef.h"
include "../lib/center.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"
include "../lib/photdef.h"
include "../lib/phot.h"
include "../lib/contourdef.h"
include "../lib/contour.h"
include "../lib/surfacedef.h"
include "../lib/surface.h"


# XP_SETI -- Set the value of an xapphot integer parameter.

procedure xp_seti (xp, parameter, value)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set
int	value			#I the value of the parameter to be set

pointer	ip, cp, sp, pp, dp, ep, op, ap

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
        dp = XP_PIMDISPLAY(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)
        ep = XP_PCONTOUR(xp)
        op = XP_POBJECTS(xp)
	ap = XP_PSURFACE(xp)

	switch (parameter) {

	case IMNUMBER:
	    XP_IMNUMBER(xp) = value
	case OFNUMBER:
	    XP_OFNUMBER(xp) = value
	case RFNUMBER:
	    XP_RFNUMBER(xp) = value
	case GFNUMBER:
	    XP_GFNUMBER(xp) = value

	case IEMISSION:
	    XP_IEMISSION(ip) = value
	case INOISEMODEL:
	    XP_INOISEMODEL(ip) = value

	case CALGORITHM:
	    XP_CALGORITHM(cp) = value
	case CMAXITER:
	    XP_CMAXITER(cp) = value
	case CTRMARK:
	    XP_CTRMARK(cp) = value
	case CCHARMARK:
	    XP_CCHARMARK(cp) = value
	case CCOLORMARK:
	    XP_CCOLORMARK(cp) = value

	case SUNVER:
            XP_SUNVER(sp) = value
        case SMODE:
            XP_SMODE(sp) = value
        case SOMODE:
            XP_SOMODE(sp) = value
        case SALGORITHM:
            XP_SALGORITHM(sp) = value
        case SGEOMETRY:
            XP_SGEOMETRY(sp) = value
        case SOGEOMETRY:
            XP_SOGEOMETRY(sp) = value
        case SHSMOOTH:
            XP_SHSMOOTH(sp) = value
        case SMAXITER:
            XP_SMAXITER(sp) = value
        case SNREJECT:
            XP_SNREJECT(sp) = value
        case NSKYPIX:
            XP_NSKYPIX(sp) = value
        case SILO:
            XP_SILO(sp) = value
        case SNX:
            XP_SNX(sp) = value
        case SNY:
            XP_SNY(sp) = value
        case NSKY:
            XP_NSKY(sp) = value
        case NSKY_REJECT:
            XP_NSKY_REJECT(sp) = value
        case SKYMARK:
            XP_SKYMARK(sp) = value
        case SCOLORMARK:
            XP_SCOLORMARK(sp) = value

	case PUNVER:
            XP_PUNVER(pp) = value
        case PGEOMETRY:
            XP_PGEOMETRY(pp) = value
        case POGEOMETRY:
            XP_POGEOMETRY(pp) = value
        case NAPERTS:
            XP_NAPERTS(pp) = value
        case NAPIX:
            XP_NAPIX(pp) = value
        case ANX:
            XP_ANX(pp) = value
        case ANY:
            XP_ANY(pp) = value
        case NMAXAP:
            XP_NMAXAP(pp) = value
        case NMINAP:
            XP_NMINAP(pp) = value
        case PHOTMARK:
            XP_PHOTMARK(pp) = value
        case PCOLORMARK:
            XP_PCOLORMARK(pp) = value

        case DERASE:
            XP_DERASE(dp) = value
        case DREPEAT:
            XP_DREPEAT(dp) = value
        case DFILL:
            XP_DFILL(dp) = value
        case DZTRANS:
            XP_DZTRANS(dp) = value
        case DZLIMITS:
            XP_DZLIMITS(dp) = value
        case DZNSAMPLE:
            XP_DZNSAMPLE(dp) = value

        case OBJMARK:
            XP_OBJMARK(op) = value
        case OCHARMARK:
            XP_OCHARMARK(op) = value
        case ONUMBER:
            XP_ONUMBER(op) = value
        case OPCOLORMARK:
            XP_OPCOLORMARK(op) = value
        case OSCOLORMARK:
            XP_OSCOLORMARK(op) = value

        case ENX:
            XP_ENX(ep) = value
        case ENY:
            XP_ENY(ep) = value
        case ENCONTOURS:
            XP_ENCONTOURS(ep) = value
        case EHILOMARK:
            XP_EHILOMARK(ep) = value
        case EDASHPAT:
            XP_EDASHPAT(ep) = value
        case ELABEL:
            XP_ELABEL(ep) = value
        case EBOX:
            XP_EBOX(ep) = value
        case ETICKLABEL:
            XP_ETICKLABEL(ep) = value
        case EXMAJOR:
            XP_EXMAJOR(ep) = value
        case EXMINOR:
            XP_EXMINOR(ep) = value
        case EYMAJOR:
            XP_EYMAJOR(ep) = value
        case EYMINOR:
            XP_EYMINOR(ep) = value
        case EROUND:
            XP_EROUND(ep) = value
        case EFILL:
            XP_EFILL(ep) = value

        case ASNX:
            XP_ASNX(ap) = value
        case ASNY:
            XP_ASNY(ap) = value
        case ALABEL:
            XP_ALABEL(ap) = value

	default:
	    call error (0, "XP_SETI: Unknown integer parameter")
	}
end


# XP_SETP -- Set the value of an xapphot pointer parameter.

procedure xp_setp (xp, parameter, value)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set
pointer	value			#I the value of the parameter to be set

pointer	ip, cp, sp, pp, dp, op

begin
	ip = XP_PIMPARS(xp)
        dp = XP_PIMDISPLAY(xp)
        op = XP_POBJECTS(xp)
	cp = XP_PCENTER(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)

	switch (parameter) {

	case PIMPARS:
	    XP_PIMPARS(xp) = value
	case PIMDISPLAY:
	    XP_PIMDISPLAY(xp) = value
	case PCONTOUR:
	    XP_PCONTOUR(xp) = value
	case PCENTER:
	    XP_PCENTER(xp) = value
	case PSKY:
	    XP_PSKY(xp) = value
	case PPHOT:
	    XP_PPHOT(xp) = value
	case POBJECTS:
	    XP_POBJECTS(xp) = value
	case PFIND:
	    XP_PFIND(xp) = value
	case PSURFACE:
	    XP_PSURFACE(xp) = value
	case SEQNOLIST:
	    XP_SEQNOLIST(xp) = value
	case PSTATUS:
	    XP_PSTATUS(xp) = value

	case CTRPIX:
	    XP_CTRPIX(cp) = value

	case SUXVER:
            XP_SUXVER(sp) = value
	case SUYVER:
            XP_SUYVER(sp) = value
        case SKYPIX:
            XP_SKYPIX(sp) = value
        case SCOORDS:
            XP_SCOORDS(sp) = value
        case SINDEX:
            XP_SINDEX(sp) = value
        case SWEIGHTS:
            XP_SWEIGHTS(sp) = value

	case PUXVER:
            XP_PUXVER(pp) = value
	case PUYVER:
            XP_PUYVER(pp) = value
        case PAPERTURES:
            XP_PAPERTURES(pp) = value
        case APIX:
            XP_APIX(pp) = value
        case XAPIX:
            XP_XAPIX(pp) = value
        case YAPIX:
            XP_YAPIX(pp) = value
        case AREAS:
            XP_AREAS(pp) = value
        case SUMS:
            XP_SUMS(pp) = value
        case FLUX:
            XP_FLUX(pp) = value
        case SUMXSQ:
            XP_SUMXSQ(pp) = value
        case SUMYSQ:
            XP_SUMYSQ(pp) = value
        case SUMXY:
            XP_SUMXY(pp) = value

        case MAGS:
            XP_MAGS(pp) = value
        case MAGERRS:
            XP_MAGERRS(pp) = value
        case MPOSANGLES:
            XP_MPOSANGLES(pp) = value
        case MAXRATIOS:
            XP_MAXRATIOS(pp) = value
        case MHWIDTHS:
            XP_MHWIDTHS(pp) = value

        case DLUT:
            XP_DLUT(dp) = value

        case OBJLIST:
            XP_OBJLIST(op) = value
        case POLYGONLIST:
            XP_POLYGONLIST(op) = value

	default:
	    call error (0, "XP_SETP: Unknown pointer parameter")
	}
end


# XP_SETR -- Set the value of an xapphot real parameter.

procedure xp_setr (xp, parameter, value)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set
real	value			#I the value of the parameter to be set

pointer	ip, cp, sp, pp, dp, op, ep, fp, ap

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)
        dp = XP_PIMDISPLAY(xp)
        ep = XP_PCONTOUR(xp)
        op = XP_POBJECTS(xp)
	fp = XP_PFIND(xp)
	ap = XP_PSURFACE(xp)

	switch (parameter) {

	case ISCALE:
	    XP_ISCALE(ip) = value
	case IHWHMPSF:
	    XP_IHWHMPSF(ip) = value
	case ISKYSIGMA:
	    XP_ISKYSIGMA(ip) = value
	case IMINDATA:
	    XP_IMINDATA(ip) = value
	case IMAXDATA:
	    XP_IMAXDATA(ip) = value
	case IETIME:
	    XP_IETIME(ip) = value
	case IAIRMASS:
	    XP_IAIRMASS(ip) = value
	case IGAIN:
	    XP_IGAIN(ip) = value
	case IREADNOISE:
	    XP_IREADNOISE(ip) = value
	
	case CRADIUS:
	    XP_CRADIUS(cp) = value
	case CTHRESHOLD:
	    XP_CTHRESHOLD(cp) = value
	case CMINSNRATIO:
	    XP_CMINSNRATIO(cp) = value
	case CXYSHIFT:
	    XP_CXYSHIFT(cp) = value
	case CXCUR:
	    XP_CXCUR(cp) = value
	case CYCUR:
	    XP_CYCUR(cp) = value
	case XCENTER:
	    XP_XCENTER(cp) = value
	case YCENTER:
	    XP_YCENTER(cp) = value
	case XERR:
	    XP_XERR(cp) = value
	case YERR:
	    XP_YERR(cp) = value
	case XSHIFT:
	    XP_XSHIFT(cp) = value
	case YSHIFT:
	    XP_YSHIFT(cp) = value
	case CDATALIMIT:
	    XP_CDATALIMIT(cp) = value
	case CSIZEMARK:
	    XP_CSIZEMARK(cp) = value

        case SRANNULUS:
            XP_SRANNULUS(sp) = value
        case SORANNULUS:
            XP_SORANNULUS(sp) = value
        case SWANNULUS:
            XP_SWANNULUS(sp) = value
        case SOWANNULUS:
            XP_SOWANNULUS(sp) = value
        case SAXRATIO:
            XP_SAXRATIO(sp) = value
        case SOAXRATIO:
            XP_SOAXRATIO(sp) = value
        case SPOSANGLE:
            XP_SPOSANGLE(sp) = value
        case SOPOSANGLE:
            XP_SOPOSANGLE(sp) = value
        case SCONSTANT:
            XP_SCONSTANT(sp) = value
        case SLOCLIP:
            XP_SLOCLIP(sp) = value
        case SHICLIP:
            XP_SHICLIP(sp) = value
        case SHWIDTH:
            XP_SHWIDTH(sp) = value
        case SHBINSIZE:
            XP_SHBINSIZE(sp) = value
        case SLOREJECT:
            XP_SLOREJECT(sp) = value
        case SHIREJECT:
            XP_SHIREJECT(sp) = value
        case SRGROW:
            XP_SRGROW(sp) = value
        case SXCUR:
            XP_SXCUR(sp) = value
        case SYCUR:
            XP_SYCUR(sp) = value
        case SXC:
            XP_SXC(sp) = value
        case SYC:
            XP_SYC(sp) = value
        case SKY_MEAN:
            XP_SKY_MEAN(sp) = value
        case SKY_MEDIAN:
            XP_SKY_MEDIAN(sp) = value
        case SKY_MODE:
            XP_SKY_MODE(sp) = value
        case SKY_STDEV:
            XP_SKY_STDEV(sp) = value
        case SKY_SKEW:
            XP_SKY_SKEW(sp) = value

        case PAXRATIO:
            XP_PAXRATIO(pp) = value
        case POAXRATIO:
            XP_POAXRATIO(pp) = value
        case PPOSANGLE:
            XP_PPOSANGLE(pp) = value
        case POPOSANGLE:
            XP_POPOSANGLE(pp) = value
        case ADATAMIN:
            XP_ADATAMIN(pp) = value
        case ADATAMAX:
            XP_ADATAMAX(pp) = value
        case PZMAG:
            XP_PZMAG(pp) = value
        case PXCUR:
            XP_PXCUR(pp) = value
        case PYCUR:
            XP_PYCUR(pp) = value
        case AXC:
            XP_AXC(pp) = value
        case AYC:
            XP_AYC(pp) = value

        case DXORIGIN:
            XP_DXORIGIN(dp) = value
        case DYORIGIN:
            XP_DYORIGIN(dp) = value
        case DXMAG:
            XP_DXMAG(dp) = value
        case DYMAG:
            XP_DYMAG(dp) = value
        case DXVIEWPORT:
            XP_DXVIEWPORT(dp) = value
        case DYVIEWPORT:
            XP_DYVIEWPORT(dp) = value
        case DZCONTRAST:
            XP_DZCONTRAST(dp) = value
        case DZ1:
            XP_DZ1(dp) = value
        case DZ2:
            XP_DZ2(dp) = value
        case DIMZ1:
            XP_DIMZ1(dp) = value
        case DIMZ2:
            XP_DIMZ2(dp) = value

        case OSIZEMARK:
            XP_OSIZEMARK(op) = value
        case OTOLERANCE:
            XP_OTOLERANCE(op) = value

        case EZ1:
            XP_EZ1(ep) = value
        case EZ2:
            XP_EZ2(ep) = value
        case EZ0:
            XP_EZ0(ep) = value
        case EDZ:
            XP_EDZ(ep) = value

        case AZ1:
            XP_AZ1(ap) = value
        case AZ2:
            XP_AZ2(ap) = value
        case ANGH:
            XP_ANGH(ap) = value
        case ANGV:
            XP_ANGV(ap) = value

	case FTHRESHOLD:
	    XP_FTHRESHOLD(fp) = value
	case FRADIUS:
	    XP_FRADIUS(fp) = value
	case FSEPMIN:
	    XP_FSEPMIN(fp) = value
	case FROUNDLO:
	    XP_FROUNDLO(fp) = value
	case FROUNDHI:
	    XP_FROUNDHI(fp) = value
	case FSHARPLO:
	    XP_FSHARPLO(fp) = value
	case FSHARPHI:
	    XP_FSHARPHI(fp) = value
	
	default:
	    call error (0, "XP_SETR: Unknown real parameter")
	}
end


# XP_SETS -- Set the value of an xapphot string parameter.

procedure xp_sets (xp, parameter, value)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set
char	value[ARB]		#I the value of the parameter to be set

int     naperts
pointer	ip, cp, sp, pp, dp
pointer mp, aperts
int     xp_getaperts(), xp_decaperts()

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)
        dp = XP_PIMDISPLAY(xp)

	switch (parameter) {

	case STARTDIR:
	    call strcpy (value, XP_STARTDIR(xp), SZ_PATHNAME)
	case CURDIR:
	    call strcpy (value, XP_CURDIR(xp), SZ_PATHNAME)
	case IMTEMPLATE:
	    call strcpy (value, XP_IMTEMPLATE(xp), SZ_FNAME)
	case IMAGE:
	    call strcpy (value, XP_IMAGE(xp), SZ_FNAME)
	case OFTEMPLATE:
	    call strcpy (value, XP_OFTEMPLATE(xp), SZ_FNAME)
	case OBJECTS:
	    call strcpy (value, XP_OBJECTS(xp), SZ_FNAME)
	case RFTEMPLATE:
	    call strcpy (value, XP_RFTEMPLATE(xp), SZ_FNAME)
	case RESULTS:
	    call strcpy (value, XP_RESULTS(xp), SZ_FNAME)
	case GFTEMPLATE:
	    call strcpy (value, XP_GFTEMPLATE(xp), SZ_FNAME)
	case GRESULTS:
	    call strcpy (value, XP_GRESULTS(xp), SZ_FNAME)

	case IKEXPTIME:
	    call strcpy (value, XP_IKEXPTIME(ip), SZ_FNAME)
	case IKAIRMASS:
	    call strcpy (value, XP_IKAIRMASS(ip), SZ_FNAME)
	case IKFILTER:
	    call strcpy (value, XP_IKFILTER(ip), SZ_FNAME)
	case IKOBSTIME:
	    call strcpy (value, XP_IKOBSTIME(ip), SZ_FNAME)
	case IFILTER:
	    call strcpy (value, XP_IFILTER(ip), SZ_FNAME)
	case IOTIME:
	    call strcpy (value, XP_IOTIME(ip), SZ_FNAME)
	case IKREADNOISE:
	    call strcpy (value, XP_IKREADNOISE(ip), SZ_FNAME)
	case IKGAIN:
	    call strcpy (value, XP_IKGAIN(ip), SZ_FNAME)
	case INSTRING:
	    call strcpy (value, XP_INSTRING(ip), SZ_FNAME)

	case CSTRING:
	    call strcpy (value, XP_CSTRING(cp), SZ_FNAME)

        case SSTRING:
            call strcpy (value, XP_SSTRING(sp), SZ_FNAME)
        case SMSTRING:
            call strcpy (value, XP_SMSTRING(sp), SZ_FNAME)
        case SOMSTRING:
            call strcpy (value, XP_SOMSTRING(sp), SZ_FNAME)
        case SGEOSTRING:
            call strcpy (value, XP_SGEOSTRING(sp), SZ_LINE)
        case SOGEOSTRING:
            call strcpy (value, XP_SOGEOSTRING(sp), SZ_LINE)

        case PAPSTRING:
            call smark (mp)
            call salloc (aperts, MAX_NAPERTS, TY_REAL)
            naperts = xp_getaperts (value, Memr[aperts], MAX_NAPERTS)
            if (naperts > 0) {
                call strcpy (value, XP_PAPSTRING(pp), SZ_LINE)
                call strcpy (value, XP_POAPSTRING(pp), SZ_LINE)
                XP_NAPERTS(pp) = naperts
                call calloc (XP_PAPERTURES(pp), XP_NAPERTS(pp), TY_REAL)
                call calloc (XP_AREAS(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMS(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_FLUX(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMXSQ(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMYSQ(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMXY(pp), XP_NAPERTS(pp), TY_DOUBLE)

                call calloc (XP_MAGS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAGS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MAGERRS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAGERRS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MHWIDTHS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MHWIDTHS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MAXRATIOS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAXRATIOS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MPOSANGLES(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MPOSANGLES(pp)], XP_NAPERTS(pp))
                call amovr (Memr[aperts], Memr[XP_PAPERTURES(pp)],
                    XP_NAPERTS(pp))
                call asrtr (Memr[XP_PAPERTURES(pp)], Memr[XP_PAPERTURES(pp)],
                    XP_NAPERTS(pp))
            }
            call sfree (mp)

        case POAPSTRING:
            call smark (mp)
            call salloc (aperts, MAX_NAPERTS, TY_REAL)
            naperts = xp_decaperts (value, Memr[aperts], MAX_NAPERTS)
            if (naperts > 0) {
                call strcpy (value, XP_POAPSTRING(pp), SZ_LINE)
                XP_NAPERTS(pp) = naperts
                call calloc (XP_PAPERTURES(pp), XP_NAPERTS(pp), TY_REAL)
                call calloc (XP_AREAS(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMS(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_FLUX(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMXSQ(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMYSQ(pp), XP_NAPERTS(pp), TY_DOUBLE)
                call calloc (XP_SUMXY(pp), XP_NAPERTS(pp), TY_DOUBLE)

                call calloc (XP_MAGS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAGS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MAGERRS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAGERRS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MHWIDTHS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MHWIDTHS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MAXRATIOS(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MAXRATIOS(pp)], XP_NAPERTS(pp))
                call calloc (XP_MPOSANGLES(pp), XP_NAPERTS(pp), TY_REAL)
		call amovkr (INDEFR, Memr[XP_MPOSANGLES(pp)], XP_NAPERTS(pp))

                call amovr (Memr[aperts], Memr[XP_PAPERTURES(pp)],
                    XP_NAPERTS(pp))
                call asrtr (Memr[XP_PAPERTURES(pp)], Memr[XP_PAPERTURES(pp)],
                    XP_NAPERTS(pp))
            }
            call sfree (mp)

        case PGEOSTRING:
            call strcpy (value, XP_PGEOSTRING(pp), SZ_LINE)

        case POGEOSTRING:
            call strcpy (value, XP_POGEOSTRING(pp), SZ_LINE)

        case DLUTFILE:
            call strcpy (value, XP_DLUTFILE(dp), SZ_FNAME)

	default:
	    call error (0, "XP_SETS: Unknown string parameter")
	}
end
