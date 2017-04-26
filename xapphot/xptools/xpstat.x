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


# XP_STATI -- Get the value of an xapphot integer parameter.

int procedure xp_stati (xp, parameter)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set

pointer	ip, cp, dp, sp, pp, op, ep, ap

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)
        dp = XP_PIMDISPLAY(xp)
        op = XP_POBJECTS(xp)
        ep = XP_PCONTOUR(xp)
	ap = XP_PSURFACE(xp)

	switch (parameter) {

	case IMNUMBER:
	    return (XP_IMNUMBER(xp))
	case OFNUMBER:
	    return (XP_OFNUMBER(xp))
	case RFNUMBER:
	    return (XP_RFNUMBER(xp))
	case GFNUMBER:
	    return (XP_GFNUMBER(xp))

	case IEMISSION:
	    return (XP_IEMISSION(ip))
	case INOISEMODEL:
	    return (XP_INOISEMODEL(ip))

	case CALGORITHM:
	    return (XP_CALGORITHM(cp))
	case CMAXITER:
	    return (XP_CMAXITER(cp))
	case CTRMARK:
	    return (XP_CTRMARK(cp))
	case CCHARMARK:
	    return (XP_CCHARMARK(cp))
	case CCOLORMARK:
	    return (XP_CCOLORMARK(cp))

	case SUNVER:
            return (XP_SUNVER(sp))
        case SMODE:
            return (XP_SMODE(sp))
        case SOMODE:
            return (XP_SOMODE(sp))
        case SALGORITHM:
            return (XP_SALGORITHM(sp))
        case SGEOMETRY:
            return (XP_SGEOMETRY(sp))
        case SOGEOMETRY:
            return (XP_SOGEOMETRY(sp))
        case SHSMOOTH:
            return (XP_SHSMOOTH(sp))
        case SMAXITER:
            return (XP_SMAXITER(sp))
        case SNREJECT:
            return (XP_SNREJECT(sp))
        case NSKYPIX:
            return (XP_NSKYPIX(sp))
        case SILO:
            return (XP_SILO(sp))
        case SNX:
            return (XP_SNX(sp))
        case SNY:
            return (XP_SNY(sp))
        case NSKY:
            return (XP_NSKY(sp))
        case NSKY_REJECT:
            return (XP_NSKY_REJECT(sp))
        case SKYMARK:
            return (XP_SKYMARK(sp))
        case SCOLORMARK:
            return (XP_SCOLORMARK(sp))

	case PUNVER:
            return (XP_PUNVER(pp))
        case PGEOMETRY:
            return (XP_PGEOMETRY(pp))
        case POGEOMETRY:
            return (XP_POGEOMETRY(pp))
        case NAPERTS:
            return (XP_NAPERTS(pp))
        case NAPIX:
            return (XP_NAPIX(pp))
        case ANX:
            return (XP_ANX(pp))
        case ANY:
            return (XP_ANY(pp))
        case NMAXAP:
            return (XP_NMAXAP(pp))
        case NMINAP:
            return (XP_NMINAP(pp))
        case PHOTMARK:
            return (XP_PHOTMARK(pp))
        case PCOLORMARK:
            return (XP_PCOLORMARK(pp))

        case DERASE:
            return (XP_DERASE(dp))
        case DREPEAT:
            return (XP_DREPEAT(dp))
        case DFILL:
            return (XP_DFILL(dp))
        case DZTRANS:
            return (XP_DZTRANS(dp))
        case DZLIMITS:
            return (XP_DZLIMITS(dp))
        case DZNSAMPLE:
            return (XP_DZNSAMPLE(dp))

        case OBJMARK:
            return (XP_OBJMARK(op))
        case OCHARMARK:
            return (XP_OCHARMARK(op))
        case ONUMBER:
            return (XP_ONUMBER(op))
        case OPCOLORMARK:
            return (XP_OPCOLORMARK(op))
        case OSCOLORMARK:
            return (XP_OSCOLORMARK(op))

        case ENX:
            return (XP_ENX(ep))
        case ENY:
            return (XP_ENY(ep))
        case ENCONTOURS:
            return (XP_ENCONTOURS(ep))
        case EHILOMARK:
            return (XP_EHILOMARK(ep))
        case EDASHPAT:
            return (XP_EDASHPAT(ep))
        case ELABEL:
            return (XP_ELABEL(ep))
        case EBOX:
            return (XP_EBOX(ep))
        case ETICKLABEL:
            return (XP_ETICKLABEL(ep))
        case EXMAJOR:
            return (XP_EXMAJOR(ep))
        case EXMINOR:
            return (XP_EXMINOR(ep))
        case EYMAJOR:
            return (XP_EYMAJOR(ep))
        case EYMINOR:
            return (XP_EYMINOR(ep))
        case EROUND:
            return (XP_EROUND(ep))
        case EFILL:
            return (XP_EFILL(ep))

        case ASNX:
            return (XP_ASNX(ap))
        case ASNY:
            return (XP_ASNY(ap))
        case ALABEL:
            return (XP_ALABEL(ap))

	default:
	    call error (0, "XP_STATI: Unknown integer parameter")
	}
end


# XP_STATP -- Get the value of an xapphot pointer parameter.

pointer procedure xp_statp (xp, parameter)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set

pointer	cp, sp, pp, dp, op

begin
	cp = XP_PCENTER(xp)
        dp = XP_PIMDISPLAY(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)
        op = XP_POBJECTS(xp)

	switch (parameter) {

	case PIMPARS:
	    return (XP_PIMPARS(xp))
	case PIMDISPLAY:
	    return (XP_PIMDISPLAY(xp))
	case PCONTOUR:
	    return (XP_PCONTOUR(xp))
	case POBJECTS:
	    return (XP_POBJECTS(xp))
	case PCENTER:
	    return (XP_PCENTER(xp))
	case PSKY:
	    return (XP_PSKY(xp))
	case PPHOT:
	    return (XP_PPHOT(xp))
	case PFIND:
	    return (XP_PFIND(xp))
	case PSURFACE:
	    return (XP_PSURFACE(xp))
	case SEQNOLIST:
	    return (XP_SEQNOLIST(xp))
	case PSTATUS:
	    return (XP_PSTATUS(xp))

	case CTRPIX:
	    return (XP_CTRPIX(cp))

	case SUXVER:
            return (XP_SUXVER(sp))
	case SUYVER:
            return (XP_SUYVER(sp))
        case SKYPIX:
            return (XP_SKYPIX(sp))
        case SCOORDS:
            return (XP_SCOORDS(sp))
        case SINDEX:
            return (XP_SINDEX(sp))
        case SWEIGHTS:
            return (XP_SWEIGHTS(sp))

	case PUXVER:
            return (XP_PUXVER(pp))
	case PUYVER:
            return (XP_PUYVER(pp))
        case PAPERTURES:
            return (XP_PAPERTURES(pp))
        case APIX:
            return (XP_APIX(pp))
        case XAPIX:
            return (XP_XAPIX(pp))
        case YAPIX:
            return (XP_YAPIX(pp))
        case AREAS:
            return (XP_AREAS(pp))
        case SUMS:
            return (XP_SUMS(pp))
        case FLUX:
            return (XP_FLUX(pp))
        case SUMXSQ:
            return (XP_SUMXSQ(pp))
        case SUMYSQ:
            return (XP_SUMYSQ(pp))
        case SUMXY:
            return (XP_SUMXY(pp))

        case MAGS:
            return (XP_MAGS(pp))
        case MAGERRS:
            return (XP_MAGERRS(pp))
        case MPOSANGLES:
            return (XP_MPOSANGLES(pp))
        case MAXRATIOS:
            return (XP_MAXRATIOS(pp))
        case MHWIDTHS:
            return (XP_MHWIDTHS(pp))

        case DLUT:
            return (XP_DLUT(dp))

        case OBJLIST:
            return (XP_OBJLIST(op))
        case POLYGONLIST:
            return (XP_POLYGONLIST(op))

	default:
	    call error (0, "XP_STATP: Unknown pointer parameter")
	}
end


# XP_STATR -- Get the value of an xapphot real parameter.

real procedure xp_statr (xp, parameter)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set

pointer	ip, cp, sp, pp, dp, ep, op, fp, ap

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
	    return (XP_ISCALE(ip))
	case IHWHMPSF:
	    return (XP_IHWHMPSF(ip))
	case ISKYSIGMA:
	    return (XP_ISKYSIGMA(ip))
	case IMINDATA:
	    return (XP_IMINDATA(ip))
	case IMAXDATA:
	    return (XP_IMAXDATA(ip))
	case IETIME:
	    return (XP_IETIME(ip))
	case IAIRMASS:
	    return (XP_IAIRMASS(ip))
	case IGAIN:
	    return (XP_IGAIN(ip))
	case IREADNOISE:
	    return (XP_IREADNOISE(ip))

	case CRADIUS:
	    return (XP_CRADIUS(cp))
	case CTHRESHOLD:
	    return (XP_CTHRESHOLD(cp))
	case CMINSNRATIO:
	    return (XP_CMINSNRATIO(cp))
	case CXYSHIFT:
	    return (XP_CXYSHIFT(cp))
	case CXCUR:
	    return (XP_CXCUR(cp))
	case CYCUR:
	    return (XP_CYCUR(cp))
	case XCENTER:
	    return (XP_XCENTER(cp))
	case YCENTER:
	    return (XP_YCENTER(cp))
	case XERR:
	    return (XP_XERR(cp))
	case YERR:
	    return (XP_YERR(cp))
	case XSHIFT:
	    return (XP_XSHIFT(cp))
	case YSHIFT:
	    return (XP_YSHIFT(cp))
	case CDATALIMIT:
	    return (XP_CDATALIMIT(cp))
	case CSIZEMARK:
	    return (XP_CSIZEMARK(cp))

        case SRANNULUS:
            return (XP_SRANNULUS(sp))
        case SORANNULUS:
            return (XP_SORANNULUS(sp))
        case SWANNULUS:
            return (XP_SWANNULUS(sp))
        case SOWANNULUS:
            return (XP_SOWANNULUS(sp))
        case SAXRATIO:
            return (XP_SAXRATIO(sp))
        case SOAXRATIO:
            return (XP_SOAXRATIO(sp))
        case SPOSANGLE:
            return (XP_SPOSANGLE(sp))
        case SOPOSANGLE:
            return (XP_SOPOSANGLE(sp))
        case SCONSTANT:
            return (XP_SCONSTANT(sp))
        case SLOCLIP:
            return (XP_SLOCLIP(sp))
        case SHICLIP:
            return (XP_SHICLIP(sp))
        case SHWIDTH:
            return (XP_SHWIDTH(sp))
        case SHBINSIZE:
            return (XP_SHBINSIZE(sp))
        case SLOREJECT:
            return (XP_SLOREJECT(sp))
        case SHIREJECT:
            return (XP_SHIREJECT(sp))
        case SRGROW:
            return (XP_SRGROW(sp))
        case SXCUR:
            return (XP_SXCUR(sp))
        case SYCUR:
            return (XP_SYCUR(sp))
        case SXC:
            return (XP_SXC(sp))
        case SYC:
            return (XP_SYC(sp))
        case SKY_MEAN:
            return (XP_SKY_MEAN(sp))
        case SKY_MEDIAN:
            return (XP_SKY_MEDIAN(sp))
        case SKY_MODE:
            return (XP_SKY_MODE(sp))
        case SKY_STDEV:
            return (XP_SKY_STDEV(sp))
        case SKY_SKEW:
            return (XP_SKY_SKEW(sp))

        case PAXRATIO:
            return (XP_PAXRATIO(pp))
        case POAXRATIO:
            return (XP_POAXRATIO(pp))
        case PPOSANGLE:
            return (XP_PPOSANGLE(pp))
        case POPOSANGLE:
            return (XP_POPOSANGLE(pp))
        case ADATAMIN:
            return (XP_ADATAMIN(pp))
        case ADATAMAX:
            return (XP_ADATAMAX(pp))
        case PZMAG:
            return (XP_PZMAG(pp))
        case PXCUR:
            return (XP_PXCUR(pp))
        case PYCUR:
            return (XP_PYCUR(pp))
        case AXC:
            return (XP_AXC(pp))
        case AYC:
            return (XP_AYC(pp))

        case DXORIGIN:
            return (XP_DXORIGIN(dp))
        case DYORIGIN:
            return (XP_DYORIGIN(dp))
        case DXMAG:
            return (XP_DXMAG(dp))
        case DYMAG:
            return (XP_DYMAG(dp))
        case DXVIEWPORT:
            return (XP_DXVIEWPORT(dp))
        case DYVIEWPORT:
            return (XP_DYVIEWPORT(dp))
        case DZCONTRAST:
            return (XP_DZCONTRAST(dp))
        case DZ1:
            return (XP_DZ1(dp))
        case DZ2:
            return (XP_DZ2(dp))
        case DIMZ1:
            return (XP_DIMZ1(dp))
        case DIMZ2:
            return (XP_DIMZ2(dp))

        case OTOLERANCE:
            return (XP_OTOLERANCE(op))
        case OSIZEMARK:
            return (XP_OSIZEMARK(op))

        case EZ1:
            return (XP_EZ1(ep))
        case EZ2:
            return (XP_EZ2(ep))
        case EZ0:
            return (XP_EZ0(ep))
        case EDZ:
            return (XP_EDZ(ep))

        case AZ1:
            return (XP_AZ1(ap))
        case AZ2:
            return (XP_AZ2(ap))
        case ANGH:
            return (XP_ANGH(ap))
        case ANGV:
            return (XP_ANGV(ap))

	case FTHRESHOLD:
	    return (XP_FTHRESHOLD(fp))
	case FRADIUS:
	    return (XP_FRADIUS(fp))
	case FSEPMIN:
	    return (XP_FSEPMIN(fp))
	case FROUNDLO:
	    return (XP_FROUNDLO(fp))
	case FROUNDHI:
	    return (XP_FROUNDHI(fp))
	case FSHARPLO:
	    return (XP_FSHARPLO(fp))
	case FSHARPHI:
	    return (XP_FSHARPHI(fp))

	default:
	    call error (0, "XP_STATR: Unknown real parameter")
	}
end


# XP_STATS -- Get the value of an xapphot string parameter.

procedure xp_stats (xp, parameter, value, maxch)

pointer	xp			#I the pointer to the main xapphot structure
int	parameter		#I the parameter to be set
char	value[ARB]		#O the value of the parameter to be set
int	maxch			#I the maximum number of characters

pointer	ip, cp, sp, pp, dp

begin
	ip = XP_PIMPARS(xp)
	cp = XP_PCENTER(xp)
        dp = XP_PIMDISPLAY(xp)
        sp = XP_PSKY(xp)
        pp = XP_PPHOT(xp)

	switch (parameter) {

	case STARTDIR:
	    call strcpy (XP_STARTDIR(xp), value, maxch)

	case CURDIR:
	    call strcpy (XP_CURDIR(xp), value, maxch)

	case IMTEMPLATE:
	    call strcpy (XP_IMTEMPLATE(xp), value, maxch)
	case IMAGE:
	    call strcpy (XP_IMAGE(xp), value, maxch)
	case OFTEMPLATE:
	    call strcpy (XP_OFTEMPLATE(xp), value, maxch)
	case OBJECTS:
	    call strcpy (XP_OBJECTS(xp), value, maxch)
	case RFTEMPLATE:
	    call strcpy (XP_RFTEMPLATE(xp), value, maxch)
	case RESULTS:
	    call strcpy (XP_RESULTS(xp), value, maxch)
	case GFTEMPLATE:
	    call strcpy (XP_GFTEMPLATE(xp), value, maxch)
	case GRESULTS:
	    call strcpy (XP_GRESULTS(xp), value, maxch)

	case IKEXPTIME:
	    call strcpy (XP_IKEXPTIME(ip), value, maxch)
	case IKAIRMASS:
	    call strcpy (XP_IKAIRMASS(ip), value, maxch)
	case IKFILTER:
	    call strcpy (XP_IKFILTER(ip), value, maxch)
	case IKOBSTIME:
	    call strcpy (XP_IKOBSTIME(ip), value, maxch)
	case IFILTER:
	    call strcpy (XP_IFILTER(ip), value, maxch)
	case IOTIME:
	    call strcpy (XP_IOTIME(ip), value, maxch)
	case IKREADNOISE:
	    call strcpy (XP_IKREADNOISE(ip), value, maxch)
	case IKGAIN:
	    call strcpy (XP_IKGAIN(ip), value, maxch)
	case INSTRING:
	    call strcpy (XP_INSTRING(ip), value, maxch)

	case CSTRING:
	    call strcpy (XP_CSTRING(cp), value, maxch)

        case SSTRING:
            call strcpy (XP_SSTRING(sp), value, maxch)
        case SMSTRING:
            call strcpy (XP_SMSTRING(sp), value, maxch)
        case SOMSTRING:
            call strcpy (XP_SOMSTRING(sp), value, maxch)
        case SGEOSTRING:
            call strcpy (XP_SGEOSTRING(sp), value, maxch)
        case SOGEOSTRING:
            call strcpy (XP_SOGEOSTRING(sp), value, maxch)

        case PAPSTRING:
            call strcpy (XP_PAPSTRING(pp), value, maxch)
        case POAPSTRING:
            call strcpy (XP_POAPSTRING(pp), value, maxch)
        case PGEOSTRING:
            call strcpy (XP_PGEOSTRING(pp), value, maxch)
        case POGEOSTRING:
            call strcpy (XP_POGEOSTRING(pp), value, maxch)

        case DLUTFILE:
            call strcpy (XP_DLUTFILE(dp), value, maxch)

	default:
	    call error (0, "XP_STATS: Unknown string parameter")
	}
end
