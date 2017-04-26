include "../lib/xphotdef.h"
include "../lib/imparsdef.h"
include "../lib/displaydef.h"
include "../lib/finddef.h"
include "../lib/objectsdef.h"
include "../lib/centerdef.h"
include "../lib/fitskydef.h"
include "../lib/fitsky.h"
include "../lib/photdef.h"
include "../lib/phot.h"
include "../lib/contourdef.h"
include "../lib/surfacedef.h"


# XP_XDINIT -- Allocate the main xdisplay task structure

procedure xp_xdinit (xp)

pointer	xp			#O the pointer to the main xapphot structure

begin
	call malloc (xp, LEN_XPHOT, TY_STRUCT)
	call xp_xinit (xp)
	call xp_iinit (xp)
	call xp_dinit (xp)
	call xp_einit (xp)
	call xp_ainit (xp)
	call xp_finit (xp)
	call xp_oinit (xp)
end


# XP_XCINIT -- Allocate the main xcenter task structure

procedure xp_xcinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call malloc (xp, LEN_XPHOT, TY_STRUCT)
	call xp_xinit (xp)
	call xp_iinit (xp)
	call xp_dinit (xp)
	call xp_finit (xp)
	call xp_oinit (xp)
	call xp_cinit (xp)
	call xp_einit (xp)
	call xp_ainit (xp)
end


# XP_XSINIT -- Allocate the main xfitsky task structure.

procedure xp_xsinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call malloc (xp, LEN_XPHOT, TY_STRUCT)
	call xp_xinit (xp)
	call xp_iinit (xp)
	call xp_dinit (xp)
	call xp_finit (xp)
	call xp_oinit (xp)
	call xp_sinit (xp)
	call xp_einit (xp)
	call xp_ainit (xp)
end


# XP_XPINIT -- Allocate the main xphot task structure.

procedure xp_xpinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call malloc (xp, LEN_XPHOT, TY_STRUCT)
	call xp_xinit (xp)
	call xp_iinit (xp)
	call xp_dinit (xp)
	call xp_finit (xp)
	call xp_oinit (xp)
	call xp_cinit (xp)
	call xp_sinit (xp)
	call xp_pinit (xp)
	call xp_einit (xp)
	call xp_ainit (xp)
end


# XP_DINIT -- Initialize the image display parameters substructure.

procedure xp_dinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

pointer	dp

begin
	call malloc (XP_PIMDISPLAY(xp), LEN_PIMDISPLAY, TY_STRUCT)

	dp = XP_PIMDISPLAY(xp)
	XP_DERASE(dp) = DEF_DERASE
	XP_DFILL(dp) = DEF_DFILL
	XP_DXORIGIN(dp) = 0.5
	XP_DYORIGIN(dp) = 0.5
	XP_DXVIEWPORT(dp) = DEF_DXVIEWPORT
	XP_DYVIEWPORT(dp) = DEF_DYVIEWPORT
	XP_DXMAG(dp) = DEF_DXMAG
	XP_DYMAG(dp) = DEF_DYMAG
	XP_DZTRANS(dp) = DEF_DZTRANS
	XP_DZLIMITS(dp) = DEF_DZLIMITS
	XP_DZCONTRAST(dp) = DEF_DZCONTRAST
	XP_DZNSAMPLE(dp) = DEF_DZNSAMPLE
	XP_DZ1(dp) = DEF_DZ1
	XP_DZ2(dp) = DEF_DZ1
	XP_DIMZ1(dp) = DEF_DIMZ1
	XP_DIMZ2(dp) = DEF_DIMZ2
	call strcpy ("", XP_DLUTFILE(dp), SZ_FNAME)
	XP_DLUT(dp) = NULL
	XP_DREPEAT(dp) = NO
end


# XP_DFREE -- Free the image display substructure.

procedure xp_dfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	dp

begin
	dp = XP_PIMDISPLAY(xp)
	if (dp != NULL) {
	    if (XP_DLUT(dp) != NULL)
		call xp_ulutfree (XP_DLUT(dp))
	    call mfree (dp, TY_STRUCT)
	}
end


# XP_EINIT -- Allocate the contour plotting parameters substructure.

procedure xp_einit (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	ep

begin
	call malloc (XP_PCONTOUR(xp), LEN_PCONTOUR, TY_STRUCT) 
	ep = XP_PCONTOUR(xp)

	XP_ENX(ep) = DEF_ENX
	XP_ENY(ep) = DEF_ENY
	XP_EZ1(ep) = DEF_EZ1
	XP_EZ2(ep) = DEF_EZ2
	XP_EZ0(ep) = DEF_EZ0
	XP_ENCONTOURS(ep) = DEF_ENCONTOURS
	XP_EDZ(ep) = DEF_EDZ
	XP_EHILOMARK(ep) = DEF_EHILOMARK
	XP_EDASHPAT(ep) = DEF_EDASHPAT
	XP_ELABEL(ep) = DEF_ELABEL
	XP_EBOX(ep) = DEF_EBOX
	XP_ETICKLABEL(ep) = DEF_ETICKLABEL
	XP_EXMAJOR(ep) = DEF_EXMAJOR
	XP_EXMINOR(ep) = DEF_EXMINOR
	XP_EYMAJOR(ep) = DEF_EYMAJOR
	XP_EYMINOR(ep) = DEF_EYMINOR
	XP_EROUND(ep) = DEF_EROUND
	XP_EFILL(ep) = DEF_EFILL
end


# XP_EFREE -- Free the contour plotting substructure.

procedure xp_efree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	ep

begin
	ep = XP_PCONTOUR(xp)
	if (ep != NULL)
	    call mfree (ep, TY_STRUCT)
end


# XP_AINIT -- Allocate the surface area plotting parameters substructure.

procedure xp_ainit (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	ap

begin
	call malloc (XP_PSURFACE(xp), LEN_PSURFACE, TY_STRUCT) 
	ap = XP_PSURFACE(xp)

	XP_ASNX(ap) = DEF_ASNX
	XP_ASNY(ap) = DEF_ASNY
	XP_ALABEL(ap) = DEF_ALABEL
	XP_AZ1(ap) = DEF_AZ1
	XP_AZ2(ap) = DEF_AZ2
	XP_ANGH(ap) = DEF_ANGH
	XP_ANGV(ap) = DEF_ANGV
end


# XP_AFREE -- Free the surface area plotting substructure.

procedure xp_afree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	ap

begin
	ap = XP_PSURFACE(xp)
	if (ap != NULL)
	    call mfree (ap, TY_STRUCT)
end


# XP_XINIT -- Initialize all the top level XAPPHOT package data structure

procedure xp_xinit (xp)

pointer	xp			#I the pointer to the the main xapphot structure

begin
	call strcpy ("", XP_IMTEMPLATE(xp), SZ_FNAME)
	call strcpy ("", XP_IMAGE(xp), SZ_FNAME)
	XP_IMNUMBER(xp) = 0
	call strcpy ("", XP_OFTEMPLATE(xp), SZ_FNAME)
	call strcpy ("", XP_OBJECTS(xp), SZ_FNAME)
	XP_OFNUMBER(xp) = 0
	call strcpy ("", XP_RFTEMPLATE(xp), SZ_FNAME)
	call strcpy ("", XP_RESULTS(xp), SZ_FNAME)
	XP_RFNUMBER(xp) = 0
	call strcpy ("", XP_GFTEMPLATE(xp), SZ_FNAME)
	call strcpy ("", XP_GRESULTS(xp), SZ_FNAME)
	XP_GFNUMBER(xp) = 0

#	XP_MAXSEQNO(xp) = 0
	XP_SEQNOLIST(xp) = NULL
	call calloc (XP_PSTATUS(xp), XP_NSTATUS, TY_INT)

	XP_PIMPARS(xp) = NULL
	XP_PIMDISPLAY(xp) = NULL
	XP_PCONTOUR(xp) = NULL
	XP_PCENTER(xp) = NULL
	XP_PSKY(xp) = NULL
	XP_PPHOT(xp) = NULL
	XP_POBJECTS(xp) = NULL
	XP_PFIND(xp) = NULL
end


# XP_XFREE -- Free all the main XAPPHOT data structure

procedure xp_xfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

begin
	# Free the arrays.
	if (XP_SEQNOLIST(xp) != NULL)
	    call stclose (XP_SEQNOLIST(xp))
	call mfree (XP_PSTATUS(xp), TY_INT)

	call mfree (xp, TY_STRUCT)
end


# XP_IINIT -- Initialize the image parameters substructure

procedure xp_iinit (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	ip

begin
	call malloc (XP_PIMPARS(xp), LEN_PIMPARS, TY_STRUCT)
	ip = XP_PIMPARS(xp)

	XP_ISCALE(ip) = DEF_ISCALE
	XP_IHWHMPSF(ip) = DEF_IHWHMPSF
	XP_ISKYSIGMA(ip) = DEF_ISKYSIGMA
	XP_IEMISSION(ip) = DEF_IEMISSION
	XP_IMINDATA(ip) = DEF_IMINDATA
	XP_IMAXDATA(ip) = DEF_IMAXDATA

	call strcpy (DEF_IKEXPTIME, XP_IKEXPTIME(ip), SZ_FNAME)
	call strcpy (DEF_IKAIRMASS, XP_IKAIRMASS(ip), SZ_FNAME)
	call strcpy (DEF_IKFILTER, XP_IKFILTER(ip), SZ_FNAME)
	call strcpy (DEF_IKOBSTIME, XP_IKOBSTIME(ip), SZ_FNAME)
	XP_IETIME(ip) = DEF_IETIME
	XP_IAIRMASS(ip) = DEF_IAIRMASS
	call strcpy (DEF_IFILTER, XP_IFILTER(ip), SZ_FNAME)
	call strcpy (DEF_IOTIME, XP_IOTIME(ip), SZ_FNAME)

	XP_INOISEMODEL(ip) = DEF_INOISEMODEL
	call strcpy (DEF_INSTRING, XP_INSTRING(ip), SZ_FNAME)
	call strcpy (DEF_IKREADNOISE, XP_IKREADNOISE(ip), SZ_FNAME)
	call strcpy (DEF_IKGAIN, XP_IKGAIN(ip), SZ_FNAME)
	XP_IREADNOISE(ip) = DEF_IREADNOISE
	XP_IGAIN(ip) = DEF_IGAIN
end


# XP_IFREE -- Free the image parameters substructure

procedure xp_ifree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer ip

begin
	ip = XP_PIMPARS(xp)
	if (ip != NULL)
	    call mfree (ip, TY_STRUCT)
end


# XP_OINIT -- Initialize the objects list management substructure.

procedure xp_oinit (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	op

begin
	call malloc (XP_POBJECTS(xp), LEN_POBJECTS, TY_STRUCT)
	op = XP_POBJECTS(xp)

	XP_OBJLIST(op) = NULL
	XP_POLYGONLIST(op) = NULL

	XP_OBJMARK(op) = DEF_OBJMARK
	XP_OTOLERANCE(op) = DEF_OTOLERANCE
	XP_OCHARMARK(op) = DEF_OCHARMARK
	XP_ONUMBER(op) = DEF_ONUMBER
	XP_OPCOLORMARK(op) = DEF_OPCOLORMARK
	XP_OSCOLORMARK(op) = DEF_OSCOLORMARK
	XP_OSIZEMARK(op) = DEF_OSIZEMARK
end


# XP_OFREE -- Free the objects list management substructure.

procedure xp_ofree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	op

begin
	op = XP_POBJECTS(xp)
	if (XP_OBJLIST(op) != NULL)
	    call stclose (XP_OBJLIST(op))
	if (XP_POLYGONLIST(op) != NULL)
	    call stclose (XP_POLYGONLIST(op))
	if (op != NULL)
	    call mfree (op, TY_STRUCT)
end


# XP_CINIT -- Initialize the centering parameters substructure.

procedure xp_cinit (xp)

pointer	xp			#I pointer to the main xapphot structure

pointer	cp

begin
	call malloc (XP_PCENTER(xp), LEN_PCENTER, TY_STRUCT)
	cp = XP_PCENTER(xp)

	XP_CALGORITHM(cp) = DEF_CALGORITHM
	call strcpy (DEF_CSTRING, XP_CSTRING(cp), SZ_FNAME)
	XP_CRADIUS(cp) = DEF_CRADIUS
	XP_CTHRESHOLD(cp) = DEF_CTHRESHOLD
	XP_CMINSNRATIO(cp) = DEF_CMINSNRATIO
	XP_CMAXITER(cp) = DEF_CMAXITER
	XP_CXYSHIFT(cp) = DEF_CXYSHIFT

	XP_CTRPIX(cp) = NULL
	XP_CXCUR(cp) = INDEFR
	XP_CYCUR(cp) = INDEFR
	XP_CXC(cp) = INDEFR
	XP_CYC(cp) = INDEFR
	XP_CNX(cp) = 0
	XP_CNY(cp) = 0

	XP_XCTRPIX(cp) = NULL
	XP_YCTRPIX(cp) = NULL
	XP_NCTRPIX(cp) = 0
	XP_LENCTRBUF(cp) = 0

	XP_XCENTER(cp) = INDEFR
	XP_YCENTER(cp) = INDEFR
	XP_XSHIFT(cp) = INDEFR
	XP_YSHIFT(cp) = INDEFR
	XP_XERR(cp) = INDEFR
	XP_YERR(cp) = INDEFR
	XP_CDATALIMIT(cp) = INDEFR

	XP_CTRMARK(cp) = NO
	XP_CCHARMARK(cp) = DEF_CCHARMARK
	XP_CCOLORMARK(cp) = DEF_CCOLORMARK
	XP_CSIZEMARK(cp) = INDEFR
end


# XP_CFREE -- Free the centering parameters substructure.

procedure xp_cfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer cp

begin
	cp = XP_PCENTER(xp)
	if (XP_CTRPIX(cp) != NULL)
	    call mfree (XP_CTRPIX(cp), TY_REAL)
	if (XP_XCTRPIX(cp) != NULL)
	    call mfree (XP_XCTRPIX(cp), TY_INT)
	if (XP_YCTRPIX(cp) != NULL)
	    call mfree (XP_YCTRPIX(cp), TY_INT)
	if (cp != NULL)
	    call mfree (cp, TY_STRUCT)
end


# XP_SINIT -- Initialize the sky fitting parameters substructure.

procedure xp_sinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

pointer	sp

begin
	call malloc (XP_PSKY(xp), LEN_PSKY, TY_STRUCT)
	sp = XP_PSKY(xp)

	call strcpy (DEF_SMSTRING, XP_SMSTRING(sp), SZ_FNAME)
	call strcpy (DEF_SMSTRING, XP_SOMSTRING(sp), SZ_FNAME)
	XP_SMODE(sp) = DEF_SMODE
	XP_SOMODE(sp) = DEF_SMODE

	call strcpy (DEF_SGEOSTRING, XP_SGEOSTRING(sp), SZ_LINE)
	call strcpy (DEF_SGEOSTRING, XP_SOGEOSTRING(sp), SZ_LINE)
	XP_SGEOMETRY(sp) = DEF_SGEOMETRY
	XP_SOGEOMETRY(sp) = DEF_SGEOMETRY
	XP_SRANNULUS(sp) = DEF_SRANNULUS
	XP_SORANNULUS(sp) = DEF_SRANNULUS
	XP_SWANNULUS(sp) = DEF_SWANNULUS
	XP_SOWANNULUS(sp) = DEF_SWANNULUS
	XP_SAXRATIO(sp) = DEF_SAXRATIO
	XP_SOAXRATIO(sp) = DEF_SAXRATIO
	XP_SPOSANGLE(sp) = DEF_SPOSANGLE
	XP_SOPOSANGLE(sp) = DEF_SPOSANGLE

	call calloc (XP_SUXVER(sp), MAX_NSKY_VERTICES + 1, TY_REAL)
	call calloc (XP_SUYVER(sp), MAX_NSKY_VERTICES + 1, TY_REAL)
	XP_SUNVER(sp) = 0

	call strcpy (DEF_SSTRING, XP_SSTRING(sp), SZ_FNAME)
	XP_SALGORITHM(sp) = DEF_SALGORITHM
	XP_SCONSTANT(sp) = DEF_SCONSTANT
	XP_SLOCLIP(sp) = DEF_SLOCLIP
	XP_SHICLIP(sp) = DEF_SHICLIP
	XP_SHWIDTH(sp) = DEF_SHWIDTH
	XP_SHBINSIZE(sp) = DEF_SHBINSIZE
	XP_SHSMOOTH(sp) = DEF_SHSMOOTH
	XP_SMAXITER(sp) = DEF_SMAXITER
	XP_SNREJECT(sp) = DEF_SNREJECT
	XP_SLOREJECT(sp) = DEF_SLOREJECT
	XP_SHIREJECT(sp) = DEF_SHIREJECT
	XP_SRGROW(sp) = DEF_SRGROW

	XP_SKYPIX(sp) = NULL
	XP_SINDEX(sp) = NULL
	XP_SCOORDS(sp) = NULL
	XP_SWEIGHTS(sp) = NULL
	XP_NSKYPIX(sp) = 0
	XP_NBADSKYPIX(sp) = 0
	XP_LENSKYBUF(sp) = 0
	XP_SXCUR(sp) = INDEFR
	XP_SYCUR(sp) = INDEFR
	XP_SXC(sp) = INDEFR
	XP_SYC(sp) = INDEFR
	XP_SNX(sp) = 0
	XP_SNY(sp) = 0

	XP_SKYMARK(sp) = DEF_SKYMARK
	XP_SCOLORMARK(sp) = DEF_SCOLORMARK

	XP_SKY_MEAN(sp) = INDEFR
	XP_SKY_MEDIAN(sp) = INDEFR
	XP_SKY_MODE(sp) = INDEFR
	XP_SKY_STDEV(sp) = INDEFR
	XP_SKY_SKEW(sp) = INDEFR
	XP_NSKY(sp) = 0
	XP_NSKY_REJECT(sp) = 0
end


# XP_SFREE -- Free the sky fitting parameters substructure.

procedure xp_sfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	sp

begin
	sp = XP_PSKY(xp)
	if (XP_SKYPIX(sp) != NULL)
	    call mfree (XP_SKYPIX(sp), TY_REAL)
	if (XP_SINDEX(sp) != NULL)
	    call mfree (XP_SINDEX(sp), TY_INT)
	if (XP_SCOORDS(sp) != NULL)
	    call mfree (XP_SCOORDS(sp), TY_INT)
	if (XP_SWEIGHTS(sp) != NULL)
	    call mfree (XP_SWEIGHTS(sp), TY_REAL)
	call mfree (XP_SUXVER(sp), TY_REAL)
	call mfree (XP_SUYVER(sp), TY_REAL)
	if (sp != NULL)
	    call mfree (sp, TY_STRUCT)
end


# XP_PINIT -- Initialize the photometry parameters substructure.

procedure xp_pinit (xp)

pointer	xp			#I the pointer to the main xapphot structure

pointer	pp

begin
	call malloc (XP_PPHOT(xp), LEN_PPHOT, TY_STRUCT)
	pp = XP_PPHOT(xp)

	call strcpy (DEF_PGEOSTRING, XP_PGEOSTRING(pp), SZ_LINE)
	call strcpy (DEF_PGEOSTRING, XP_POGEOSTRING(pp), SZ_LINE)
	XP_PGEOMETRY(pp) = DEF_PGEOMETRY
	XP_POGEOMETRY(pp) = DEF_PGEOMETRY
	call strcpy (DEF_PAPSTRING, XP_PAPSTRING(pp), SZ_LINE)
	call strcpy (DEF_PAPSTRING, XP_POAPSTRING(pp), SZ_LINE)
	XP_NAPERTS(pp) = 1
	XP_PAXRATIO(pp) = DEF_PAXRATIO
	XP_POAXRATIO(pp) = DEF_PAXRATIO
	XP_PPOSANGLE(pp) = DEF_PPOSANGLE
	XP_POPOSANGLE(pp) = DEF_PPOSANGLE
	XP_PZMAG(pp) = DEF_PZMAG

	call calloc (XP_PUXVER(pp), MAX_NAP_VERTICES + 1, TY_REAL)
	call calloc (XP_PUYVER(pp), MAX_NAP_VERTICES + 1, TY_REAL)
	XP_PUNVER(pp) = 0

	XP_PXCUR(pp) = INDEFR
	XP_PYCUR(pp) = INDEFR
	XP_APIX(pp) = NULL
	XP_XAPIX(pp) = NULL
	XP_YAPIX(pp) = NULL
	XP_NAPIX(pp) = 0
	XP_LENABUF(pp) = 0
	XP_AXC(pp) = INDEFR
	XP_AYC(pp) = INDEFR
	XP_ANX(pp) = 0
	XP_ANY(pp) = 0

	call calloc (XP_PAPERTURES(pp), XP_NAPERTS(pp), TY_REAL)
	Memr[XP_PAPERTURES(pp)] = DEF_PAPERTURES
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
	call calloc (XP_MPOSANGLES(pp), XP_NAPERTS(pp), TY_REAL)
	call amovkr (INDEFR, Memr[XP_MPOSANGLES(pp)], XP_NAPERTS(pp)) 
	call calloc (XP_MAXRATIOS(pp), XP_NAPERTS(pp), TY_REAL)
	call amovkr (INDEFR, Memr[XP_MAXRATIOS(pp)], XP_NAPERTS(pp)) 
	call calloc (XP_MHWIDTHS(pp), XP_NAPERTS(pp), TY_REAL)
	call amovkr (INDEFR, Memr[XP_MHWIDTHS(pp)], XP_NAPERTS(pp)) 

	XP_PHOTMARK(pp) = DEF_PHOTMARK
	XP_PCOLORMARK(pp) = DEF_PCOLORMARK
end


# XP_PFREE -- Free the photometry parameters substructure.

procedure xp_pfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

pointer	pp

begin
	pp = XP_PPHOT(xp)
	if (XP_PAPERTURES(pp) != NULL)
	    call mfree (XP_PAPERTURES(pp), TY_REAL)

	if (XP_AREAS(pp) != NULL)
	    call mfree (XP_AREAS(pp), TY_DOUBLE)
	if (XP_SUMS(pp) != NULL)
	    call mfree (XP_SUMS(pp), TY_DOUBLE)
	if (XP_SUMXSQ(pp) != NULL)
	    call mfree (XP_SUMXSQ(pp), TY_DOUBLE)
	if (XP_SUMYSQ(pp) != NULL)
	    call mfree (XP_SUMYSQ(pp), TY_DOUBLE)
	if (XP_SUMXY(pp) != NULL)
	    call mfree (XP_SUMXY(pp), TY_DOUBLE)

	if (XP_MAGS(pp) != NULL)
	    call mfree (XP_MAGS(pp), TY_REAL)
	if (XP_MAGERRS(pp) != NULL)
	    call mfree (XP_MAGERRS(pp), TY_REAL)
	if (XP_MPOSANGLES(pp) != NULL)
	    call mfree (XP_MPOSANGLES(pp), TY_REAL)
	if (XP_MAXRATIOS(pp) != NULL)
	    call mfree (XP_MAXRATIOS(pp), TY_REAL)
	if (XP_MHWIDTHS(pp) != NULL)
	    call mfree (XP_MHWIDTHS(pp), TY_REAL)

	call mfree (XP_PUXVER(pp), TY_REAL)
	call mfree (XP_PUYVER(pp), TY_REAL)
end


# XP_FINIT -- Initialize the object detection parameters substructure.

procedure xp_finit (xp)

pointer	xp			#I the pointer to the main xapphot structure

pointer	fp

begin
	call malloc (XP_PFIND(xp), LEN_PFIND, TY_STRUCT)
	fp = XP_PFIND(xp)

	XP_FTHRESHOLD(fp) = DEF_FTHRESHOLD
	XP_FRADIUS(fp) = DEF_FRADIUS
	XP_FSEPMIN(fp) = DEF_FSEPMIN
	XP_FROUNDLO(fp) = DEF_FROUNDLO
	XP_FROUNDHI(fp) = DEF_FROUNDHI
	XP_FSHARPLO(fp) = DEF_FSHARPLO
	XP_FSHARPHI(fp) = DEF_FSHARPHI
end


# XP_FFREE -- Free the object detection parameters substructure.

procedure xp_ffree (xp)

pointer	xp			#U the pointer to the main xapphot structure

begin
	if (XP_PFIND(xp) != NULL)
	    call mfree (XP_PFIND(xp), TY_STRUCT)
	XP_PFIND(xp) = NULL
end


# XP_XDFREE - Free the main xdisplay task structure.

procedure xp_xdfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

begin
	call xp_ifree (xp)
	call xp_dfree (xp)
	call xp_ffree (xp)
	call xp_ofree (xp)
	call xp_efree (xp)
	call xp_afree (xp)
	call xp_xfree (xp)
end


# XP_XCFREE - Free the main xcenter task structure.

procedure xp_xcfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

begin
	call xp_ifree (xp)
	call xp_dfree (xp)
	call xp_ffree (xp)
	call xp_ofree (xp)
	call xp_cfree (xp)
	call xp_efree (xp)
	call xp_afree (xp)
	call xp_xfree (xp)
end


# XP_XSFREE - Free the main xfitsky task structure.

procedure xp_xsfree (xp)

pointer	xp			#U the pointer to the main xapphot structure

begin
	call xp_ifree (xp)
	call xp_dfree (xp)
	call xp_ffree (xp)
	call xp_ofree (xp)
	call xp_sfree (xp)
	call xp_efree (xp)
	call xp_afree (xp)
	call xp_xfree (xp)
end


# XP_XPFREE -- Free the main xphot task structure.

procedure xp_xpfree (xp)

pointer	xp			#U the  pointer to the main xapphot structure

begin
	call xp_ifree (xp)
	call xp_dfree (xp)
	call xp_ffree (xp)
	call xp_ofree (xp)
	call xp_cfree (xp)
	call xp_pfree (xp)
	call xp_efree (xp)
	call xp_afree (xp)
	call xp_xfree (xp)
end
