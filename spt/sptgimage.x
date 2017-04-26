include	<mach.h>
include	<error.h>
include	<imhdr.h>
include	<smw.h>
include	<units.h>
include	<funits.h>
include	"spectool.h"


bool procedure spt_gimage (spt, image, regid, reg)

pointer	spt			#I SPECTOOL pointer
char	image[ARB]		#I Image name to check
int	regid			#I Excluding this register number
pointer	reg			#O Register

int	i
bool	streq()

begin
	for (i=1; i<=SPT_NREG(spt); i=i+1) {
	    reg = REG(spt,i)
	    if (streq (image, REG_IMAGE(reg)) && regid != REG_ID(reg))
		return (true)
	}
	reg = NULL
	return (false)
end


procedure spt_gdata (spt, im, mw, ap, band, daxis, nsum, sh)

pointer	spt		#I Spectool pointer
pointer	im		#I IMIO pointer
pointer	mw		#I SMW pointer
int	ap		#I Aperture
int	band		#I Band
int	daxis		#I Dispersion axis
int	nsum 		#I Summing factor
pointer	sh		#U Spectrum structure

int	line, bnd
real	cmin, cmax
errchk	shdr_open, spt_iccontinuum

begin
	# Set the default image line.
	# For ND spectra set the dispersion axis and summing if needed.

	switch (SMW_FORMAT(mw)) {
	case SMW_ND:
	    if (!(IS_INDEFI(daxis) && IS_INDEFI(nsum))) {
		if ((!IS_INDEFI(daxis) && daxis != SMW_PAXIS(mw,1)) ||
		    (!IS_INDEFI(nsum) && nsum != SMW_NSUM(mw,1))) {
		    call smw_daxis (mw, im, daxis, nsum, INDEFI)
		    call smw_saxes (mw, NULL, im)
		    call shdr_close (sh)
		} else
		    call smw_daxis (mw, im, daxis, nsum, INDEFI)
	    }
	    line = (SMW_LLEN(mw,2) + 1) / 2
	    bnd = band
	    if (IS_INDEFI(band))
		bnd = 1
	    call shdr_open (im, mw, line, bnd, ap, SHDATA, sh)
	    if (SC(sh) == NULL) {
		call malloc (SC(sh), SN(sh), TY_REAL)
		if (SID(sh,SHCONT) == NULL)
		    call malloc (SID(sh,SHCONT), LEN_SHDRS, TY_CHAR)
		STYPE(sh,SHCONT) = SHCONT
		call strcpy ("continuum", Memc[SID(sh,SHCONT)], LEN_SHDRS)
	    }
	    call spt_iccontinuum (Memr[SX(sh)], Memr[SY(sh)],
		Memr[SC(sh)], SN(sh))
	default:
	    line = 1
	    bnd = band
	    if (IS_INDEFI(band))
		bnd = 1
	    call shdr_open (im, mw, line, bnd, ap, SHDATA, sh)
	    if (bnd == 1) {
		if (line == LINDEX(sh,1) && bnd == LINDEX(sh,2)) {
		    call mfree (SPEC(sh,SHRAW), TY_REAL)
		    call mfree (SPEC(sh,SHSKY), TY_REAL)
		    call mfree (SPEC(sh,SHSIG), TY_REAL)
		    call mfree (SPEC(sh,SHCONT), TY_REAL)
		}
		call shdr_open (im, mw, line, bnd, ap, SHRAW, sh)
		call shdr_open (im, mw, line, bnd, ap, SHSKY, sh)
		call shdr_open (im, mw, line, bnd, ap, SHSIG, sh)
		call shdr_open (im, mw, line, bnd, ap, SHCONT, sh)
		if (SC(sh) == NULL) {
		    call malloc (SC(sh), SN(sh), TY_REAL)
		    if (SID(sh,SHCONT) == NULL)
			call malloc (SID(sh,SHCONT), LEN_SHDRS, TY_CHAR)
		    call strcpy ("continuum", Memc[SID(sh,SHCONT)], LEN_SHDRS)
		    STYPE(sh,SHCONT) = SHCONT
		    call spt_iccontinuum (Memr[SX(sh)], Memr[SY(sh)],
			Memr[SC(sh)], SN(sh))
		} else {
		    call alimr (Memr[SC(sh)], SN(sh), cmin, cmax)
		    if (cmin == cmax && cmin == -1.)
			call spt_iccontinuum (Memr[SX(sh)], Memr[SY(sh)],
			    Memr[SC(sh)], SN(sh))
		}
	    }
	}

	if ((!IS_INDEFI(ap) && ap != AP(sh)) ||
	    (!IS_INDEFI(band) && band != LINDEX(sh,2)))
	    call error (1, "Spectrum not found")
end


procedure spt_current (spt, reg)

pointer	spt			#I SPECTOOL structure
pointer	reg			#I Current register

int	rgitem, spitem, imitem

begin
	if (reg == NULL)
	    return

	if (reg != SPT_CREG(spt)) {
	    call lab_colon (spt, reg, INDEFD, INDEFD, "list")
	    call lid_colon (spt, reg, INDEFD, INDEFD, "list")
	}

	SPT_CREG(spt) = reg

	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "%s %s %d %d %s %d %d %d")
	    call pargstr (REG_IDSTR(reg))
	    call pargstr (REG_IMAGE(reg))
	    call pargi (REG_AP(reg))
	    if (SMW_NBANDS(MW(REG_SH(reg))) > 1)
		call pargi (REG_BAND(reg))
	    else
		call pargi (INDEFI)
	    call pargstr (REG_TYPE(reg,SHDATA))
	    call pargi (REG_COLOR(reg,SHDATA))
	    if (REG_FORMAT(reg) == SMW_ND) {
		call pargi (REG_DAXIS(reg))
		call pargi (REG_NSUM(reg))
	    } else {
		call pargi (INDEFI)
		call pargi (INDEFI)
	    }
	call gmsg (SPT_GP(spt), "spectrum", SPT_STRING(spt))

	call spt_gitems (spt, reg, rgitem, spitem, imitem)

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "regList %d")
	    call pargi (rgitem-1)
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "imList %d")
	    call pargi (imitem-1)
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "readList %d")
	    call pargi (spitem-1)
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
end


procedure spt_clip (y, n, y1, y2, lclip, hclip)

real	y[n]			#I Spectrum
int	n			#I Number of pixels
real	y1, y2			#O Limits
real	lclip, hclip		#I Clipping fraction/percentage

int	i, j
pointer	sorted

begin
	if (lclip <= 1./n && hclip <= 1./n) {
	    call alimr (y, n, y1, y2)
	    return
	}

	call malloc (sorted, n, TY_REAL)
	call asrtr (y, Memr[sorted], n)
	if (lclip > 1.)
	    i = lclip
	else
	    i = max (0., lclip * n)
	if (hclip > 1.)
	    j = hclip
	else
	    j = max (0., hclip * n)
	j = n - 1 - j
	if (i < j) {
	    y1 = Memr[sorted+i]
	    y2 = Memr[sorted+j]
	}
	call mfree (sorted, TY_REAL)
end


procedure spt_scale (spt, reg)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer

int	n
real	y1, y2, z, asumr()
pointer	sh, x, y
errchk	spt_clip()

begin
	if (reg == NULL)
	    return

	sh = REG_SH(reg)
	x = SX(sh)
	y = SPEC(sh,SPT_CTYPE(spt))
	n = SN(sh)

	call alimr (Memr[x], n, REG_X1(reg), REG_X2(reg))
	REG_Y1(reg) = MAX_REAL
	REG_Y2(reg) = -MAX_REAL

	if (SPT_PLOT(spt, SHDATA) == YES && SPEC(sh,SHDATA) != NULL) {
	    call spt_clip (Memr[SPEC(sh,SHDATA)], n, y1, y2,
		SPT_LCLIP(spt), SPT_HCLIP(spt))
	    REG_Y1(reg) = min (REG_Y1(reg), y1)
	    REG_Y2(reg) = max (REG_Y2(reg), y2)
	}
	if (SPT_PLOT(spt, SHRAW) == YES && SPEC(sh,SHRAW) != NULL) {
	    call spt_clip (Memr[SPEC(sh,SHRAW)], n, y1, y2,
		SPT_LCLIP(spt), SPT_HCLIP(spt))
	    REG_Y1(reg) = min (REG_Y1(reg), y1)
	    REG_Y2(reg) = max (REG_Y2(reg), y2)
	}
	if (SPT_PLOT(spt, SHSKY) == YES && SPEC(sh,SHSKY) != NULL) {
	    call spt_clip (Memr[SPEC(sh,SHSKY)], n, y1, y2,
		SPT_LCLIP(spt), SPT_HCLIP(spt))
	    REG_Y1(reg) = min (REG_Y1(reg), y1)
	    REG_Y2(reg) = max (REG_Y2(reg), y2)
	}
	if (SPT_PLOT(spt, SHCONT) == YES && SPEC(sh,SHCONT) != NULL) {
	    call spt_clip (Memr[SPEC(sh,SHCONT)], n, y1, y2,
		SPT_LCLIP(spt), SPT_HCLIP(spt))
	    REG_Y1(reg) = min (REG_Y1(reg), y1)
	    REG_Y2(reg) = max (REG_Y2(reg), y2)
	}
	if (SPT_CTYPE(spt) == SHSIG && SPT_PLOT(spt, SHSIG) == YES &&
	    SPEC(sh,SHSIG) != NULL) {
	    call spt_clip (Memr[SPEC(sh,SHSIG)], n, y1, y2,
		SPT_LCLIP(spt), SPT_HCLIP(spt))
	    REG_Y1(reg) = min (REG_Y1(reg), y1)
	    REG_Y2(reg) = max (REG_Y2(reg), y2)
	}

	if (SPT_SCALE(spt) == SCALE_MEAN && y != NULL) {
	    z = abs (asumr (Memr[y], n) / n)
	    if (z > EPSILONR * (REG_Y2(reg) - REG_Y1(reg))) {
		REG_OFFSET(reg) = REG_OFFSET(reg) / REG_SCALE(reg)
		REG_SCALE(reg) = 1. / z
		REG_OFFSET(reg) = REG_OFFSET(reg) * REG_SCALE(reg)
	    }
	}
	if (SPT_OFFSET(spt) == SCALE_MEAN && y != NULL) {
	    z = -asumr (Memr[y], n) / n
	    z = z * REG_SCALE(reg)
	    if (z != REG_OFFSET(reg))
		REG_OFFSET(reg) = z
	}
end


procedure spt_scale1 (spt, reg, x1, x2, y1, y2, z1, z2, nx, ny)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
real	x1, x2			#I X display range
real	y1, y2			#I Y display range
real	z1, z2			#O Y data range
int	nx, ny			#O Number pixels in range

int	i, j, k, n
real	xa, xb, ya, yb, y
pointer	sh
double	shdr_wl()

begin
	if (reg == NULL)
	    return

	sh = REG_SH(reg)
	n = SN(sh)
	z1 = REG_Y1(reg)
	z2 = REG_Y2(reg)
	nx = 0
	ny = 0

	if (IS_INDEF(x1) && IS_INDEF(x2) && IS_INDEF(y1) && IS_INDEF(y2)) {
	    nx = n
	    ny = n
	    return
	}

	if (IS_INDEF(x1))
	    xa = min (REG_X1(reg), REG_X2(reg))
	else
	    xa = x1
	if (IS_INDEF(x2))
	    xb = max (REG_X1(reg), REG_X2(reg))
	else
	    xb = x2
	if (IS_INDEF(y1))
	    ya = min (REG_Y1(reg), REG_Y2(reg))
	else
	    ya = y1
	if (IS_INDEF(y2))
	    yb = max (REG_Y1(reg), REG_Y2(reg))
	else
	    yb = y2
	y = ya
	ya = min (y, yb)
	yb = max (y, yb)

	k = nint (shdr_wl (sh, double(xa)))
	j = nint (shdr_wl (sh, double(xb)))
	i = max (1, min (j, k))
	j = min (n, max (j, k))
	if (j < i)
	    return

	if (SPT_PLOT(spt, SHDATA) == YES && SPEC(sh,SHDATA) != NULL)
	    call spt_scale2 (Memr[SPEC(sh,SHDATA)], i, j, ya, yb, z1, z2,
		nx, ny)
	if (SPT_PLOT(spt, SHRAW) == YES && SPEC(sh,SHRAW) != NULL)
	    call spt_scale2 (Memr[SPEC(sh,SHRAW)], i, j, ya, yb, z1, z2,
		nx, ny)
	if (SPT_PLOT(spt, SHSKY) == YES && SPEC(sh,SHSKY) != NULL)
	    call spt_scale2 (Memr[SPEC(sh,SHSKY)], i, j, ya, yb, z1, z2,
		nx, ny)
	if (SPT_PLOT(spt, SHCONT) == YES && SPEC(sh,SHCONT) != NULL)
	    call spt_scale2 (Memr[SPEC(sh,SHCONT)], i, j, ya, yb, z1, z2,
		nx, ny)
	if (SPT_CTYPE(spt) == SHSIG && SPT_PLOT(spt, SHSIG) == YES &&
	    SPEC(sh,SHSIG) != NULL)
	    call spt_scale2 (Memr[SPEC(sh,SHSIG)], i, j, ya, yb, z1, z2,
		nx, ny)
end


procedure spt_scale2 (data, i, j, y1, y2, z1, z2, nx, ny)

real	data[ARB]		#I Spectrum
int	i, j			#I Range of spectrum pixels
real	y1, y2			#I Y display range
real	z1, z2			#U Y data range
int	nx, ny			#U Number pixels in range

int	k
real	z

begin
	do k = i, j {
	    z = data[k]
	    if (nx == 0) {
		z1 = z
		z2 = z
	    }
	    if (ny == 0) {
		z1 = min (z, z1)
		z2 = max (z, z2)
	    }
	    nx = nx + 1
	    if (z < y1 || z > y2)
		next
	    if (ny == 0) {
		z1 = z
		z2 = z
	    }
	    z1 = min (z, z1)
	    z2 = max (z, z2)
	    ny = ny + 1
	}
end


# SPT_SHCOPY -- Copy SH structures.

procedure spt_shcopy (sh1, sh2, wcs)

pointer	sh1		# SHDR structure to copy
pointer	sh2		# SHDR structure copy
int	wcs		# Make copy of wcs?

begin
	call shdr_close (sh2)
	call shdr_copy (sh1, sh2, wcs)
end
