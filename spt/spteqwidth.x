include	<smw.h>
include	"spectool.h"
include	"lids.h"


# List of colon commands.
define	CMDS	"|open|close|eqwidth|remeasure|units|"
define	OPEN		1
define	CLOSE		2
define	EQW		3	# Equivalent width
define	REMEASURE	4	# Remeasure
define	UNIT		5	# Units


# SPT_EQWIDTH -- Interpret equivalent width colon commands.

procedure spt_eqwidth (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
real	wx, wy			#I Cursor coordinate
char	cmd[ARB]		#I Command

int	i, item, ncmd
double	w1, w2, wpc
pointer	sp, str, lids, lid, sh

bool	streq()
int	strdic(), nscan()
double	shdr_lw(), shdr_wl
errchk	eqw_measure, eqw_log

define	err_	10
define	done_	20

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	if (reg != NULL)
	    lids = REG_LIDS(reg)
	else
	    lids = NULL

	switch (ncmd) {
	case OPEN: # open
	    ;
	case CLOSE: # close
	    ;

	case EQW: # eqwidth item
	    call gargi (item)
	    if (nscan() == 1)
		item = -1

	    if (lids == NULL || item == 0)
		goto done_

	    if (item == -1) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call eqw_measure (spt, reg, lid)
		    call eqw_log (spt, reg, lid)
		}
	    } else {
		call lid_item (spt, reg, item, lid)
		if (lid != NULL) {
		    call eqw_measure (spt, reg, lid)
		    call eqw_log (spt, reg, lid)
		    call eqw_values (spt, reg, lid)
		}
	    }

	case REMEASURE: # remeasure
	    if (lids == NULL)
		goto done_

	    do i = 1, LID_NLINES(lids) {
		lid = LID_LINES(lids,i)
		if (IS_INDEFD(EQW_E(lid,1)))
		    next
		call eqw_measure (spt, reg, lid)
		call eqw_log (spt, reg, lid)
	    }

	case UNIT: # unit [logical|world]
	    call gargwrd (Memc[str], SZ_LINE)
	    if (nscan() != 2)
		goto err_
	    
	    if (lids == NULL)
		goto done_
	    sh = REG_SH(reg)
	    if (sh == NULL)
		goto done_

	    if (streq (Memc[str], "logical")) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    if (IS_INDEFD(EQW_E(lid,1)))
			next

		    w1 = EQW_B(lid,1)
		    w2 = EQW_B(lid,2)
		    EQW_B(lid,1) = shdr_wl (sh, w1)
		    EQW_B(lid,2) = shdr_wl (sh, w2)
		    wpc = abs ((w2 - w1) / (EQW_B(lid,2) - EQW_B(lid,1)))
		    EQW_X(lid,1) = shdr_wl (sh, EQW_X(lid,1))
		    EQW_F(lid,1) = EQW_F(lid,1) / wpc
		    EQW_E(lid,1) = EQW_E(lid,1) / wpc
		    if (!IS_INDEFD(EQW_E(lid,2))) {
			EQW_X(lid,2) = EQW_X(lid,2) / wpc
			EQW_F(lid,2) = EQW_F(lid,2) / wpc
			EQW_E(lid,2) = EQW_E(lid,2) / wpc
		    }
		}
	    } else {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    if (IS_INDEFD(EQW_E(lid,1)))
			next

		    w1 = EQW_B(lid,1)
		    w2 = EQW_B(lid,2)
		    EQW_B(lid,1) = shdr_lw (sh, w1)
		    EQW_B(lid,2) = shdr_lw (sh, w2)
		    wpc = abs ((EQW_B(lid,2) - EQW_B(lid,1)) / (w2 - w1))
		    EQW_X(lid,1) = shdr_lw (sh, EQW_X(lid,1))
		    EQW_F(lid,1) = EQW_F(lid,1) * wpc
		    EQW_E(lid,1) = EQW_E(lid,1) * wpc
		    if (!IS_INDEFD(EQW_E(lid,2))) {
			EQW_X(lid,2) = EQW_X(lid,2) * wpc
			EQW_F(lid,2) = EQW_F(lid,2) * wpc
			EQW_E(lid,2) = EQW_E(lid,2) * wpc
		    }

		    call eqw_log (spt, reg, lid)
		}
	    }

	default: # error or unknown command
err_	    call sprintf (Memc[str], SZ_LINE,
		"Error in colon command: %g %g eqwidth %s")
		call pargr (wx)
		call pargr (wy)
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

done_
	call sfree (sp)
end


# EQW_MEASURE -- Compute equivalent width, flux and center

procedure eqw_measure (spt, reg, lid)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register
pointer	lid			#I Line

int	i, n
pointer	gp, sh, x, y, c, e
double	shdr_wl()

begin
	EQW_B(lid,1) = LID_X(lid) + LID_LOW(lid)
	EQW_B(lid,2) = LID_X(lid) + LID_UP(lid)

	if (EQW_B(lid,1) == EQW_B(lid,2))
	    call error (1, "Band pass too small for equivalent width")

	gp = SPT_GP(spt)
	sh = REG_SH(reg)
	x = SX(sh)
	y = SPEC(sh,SPT_CTYPE(spt))
	c = SC(sh)
	if (SPT_ERRORS(spt) == YES)
	    e = SE(sh)
	else
	    e = NULL
	n = SN(sh)

	# Derive the needed values.
	call eqw_sumflux (sh, Memr[x], Memr[y], Memr[c], e, n, EQW_B(lid,1),
	    EQW_X(lid,1), EQW_F(lid,1), EQW_C(lid,1), EQW_E(lid,1))
	if (!IS_INDEFD(EQW_C(lid,1)))
	    EQW_C(lid,1) = EQW_C(lid,1) / abs (EQW_B(lid,2) - EQW_B(lid,1))
	if (!IS_INDEFD(EQW_C(lid,2)))
	    EQW_C(lid,2) = EQW_C(lid,2) / abs (EQW_B(lid,2) - EQW_B(lid,1))

	# Draw cursor position
	i = max (1, min (n, nint (shdr_wl (sh, EQW_X(lid,1)))))
	call gline (gp, real(EQW_X(lid,1)), real(EQW_C(lid,1)),
	    real(EQW_X(lid,1)), Memr[y+i-1])
end




# EQW_LOG -- Log equivalent width measurement.

procedure eqw_log (spt, reg, lid)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register
pointer	lid			#I Line

pointer	gp

begin
	if (IS_INDEFD(EQW_E(lid,1)))
	    return

	gp = SPT_GP(spt)

	call printf (
	    "center = %9.7g, eqw = %9.4f, continuum = %9.7g flux = %9.6g\n")
	    call pargd (EQW_X(lid,1))
	    call pargd (EQW_E(lid,1))
	    call pargd (EQW_C(lid,1))
	    call pargd (EQW_F(lid,1))

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "# %s\n")
	    call pargstr (REG_TITLE(reg))
	call spt_log (spt, reg, "title", SPT_STRING(spt))
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "# %8s%10s%10s%10s\n")
	    call pargstr ("center")
	    call pargstr ("cont")
	    call pargstr ("flux")
	    call pargstr ("eqw")
	call spt_log (spt, reg, "header", SPT_STRING(spt))

	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    " %9.7g %9.7g %9.6g %9.4g\n")
	    call pargd (EQW_X(lid,1))
	    call pargd (EQW_C(lid,1))
	    call pargd (EQW_F(lid,1))
	    call pargd (EQW_E(lid,1))
	call spt_log (spt, reg, "add", SPT_STRING(spt))

	if (!IS_INDEFD(EQW_E(lid,2))) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		" (%7.5g) (%7.5g) (%7.4g) (%7.2g)\n")
		call pargd (EQW_X(lid,2))
		call pargd (EQW_C(lid,2))
		call pargd (EQW_F(lid,2))
		call pargd (EQW_E(lid,2))
	    call spt_log (spt, reg, "add", SPT_STRING(spt))
	}
end


# EQW_SUMFLUX -- Sum up the flux in a specified bandpass

procedure eqw_sumflux (sh, x, y, c, e, n, bp, center, flux, cont, eqw)

pointer	sh		#I Spectrum header
real	x[n]		#I Coordinates
real	y[n]		#I Spectrum values
real	c[n]		#I Continuum values
pointer	e		#I Pointer to error values
int	n		#I Number of pixels
double	bp[2]		#I Bandpass
double	center[2]	#O Centroid
double	flux[2]		#O Bandpass flux
double	cont[2]		#O Continuum flux
double	eqw[2]		#O Equivalent width

int	i, i1, i2
double	a, b, sum1, sum2, dx, z, absz, shdr_wl(), shdr_lw()

begin
	do i = 1, 2 {
	    center[i] = INDEFD
	    flux[i] = INDEFD
	    cont[i] = INDEFD
	    eqw[i] = INDEFD
	}

	dx = shdr_wl (sh, bp[1])
	absz = shdr_wl (sh, bp[2])
	a = max (0.5D0, min (dx,absz))
	b = min (n+0.5D0, max (dx,absz))
	if (a > b)
	    return

	center[1] = 0.
	flux[1] = 0.
	cont[1] = 0.
	eqw[1] = 0.
	if (e != NULL) {
	    center[2] = 0.
	    flux[2] = 0.
	    cont[2] = 0.
	    eqw[2] = 0.
	}
	sum1 = 0.
	sum2 = 0.

	i1 = max (1, nint (a))
	i2 = min (n, nint (b))
	do i = i1, i2 {
	    if (i == i1)
		dx = shdr_lw (sh, double(i1+0.5)) - shdr_lw (sh, a)
	    else if (i == i2)
		dx = shdr_lw (sh, b) - shdr_lw (sh, double(i2-0.5))
	    else
		dx = shdr_lw (sh, double(i+0.5)) - shdr_lw (sh, double(i-0.5))
	    dx = abs (dx)
	    z = (y[i] - c[i]) * dx
	    absz = abs (z)
	    sum1 = sum1 + absz
	    center[1] = center[1] + absz * x[i]
	    flux[1] = flux[1] + z
	    cont[1] = cont[1] + c[i] * dx
	    if (!IS_INDEFD(eqw[1])) {
		if (c[i] > 0.)
		    eqw[1] = eqw[1] - z / c[i]
		else
		    eqw[1] = INDEFD
	    }
	    if (e != NULL) {
		z = Memr[e+i-1] * dx
		center[2] = center[2] + (x[i] * z) ** 2
		sum2 = sum2 + x[i] * z ** 2
		flux[2] = flux[2] + z ** 2
		if (!IS_INDEFD(eqw[1]))
		    eqw[2] = eqw[2] + (z / c[i]) ** 2
		else
		    eqw[2] = INDEFD
	    }
	}

	if (sum1 > 0.)
	    center[1] = center[1] / sum1
	if (e != NULL) {
	    if (sum1 > 0.) {
		z = center[1]
		center[2] = (center[2] - 2 * z * sum2 + z ** 2 * flux[2])
		if (center[2] > 0.)
		    center[2] = sqrt (center[2]) / sum1
		else
		    center[2] = INDEFD
	    } else
		center[2] = INDEFD
	    flux[2] = sqrt (flux[2])
	    if (eqw[2] != INDEFD)
		eqw[2] = sqrt (eqw[2])
	}
end


procedure eqw_values (spt, reg, lid)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum
pointer	lid		#I Line

bool	eqw

begin
	eqw = false
	if (lid != NULL)
	     eqw = !IS_INDEFD(EQW_E(lid,1))

	if (eqw) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%.8g %.8g %.8g %.8g %.8g %.8g")
		call pargd (EQW_B(lid,1))
		call pargd (EQW_B(lid,2))
		call pargd (EQW_X(lid,1))
		call pargd (EQW_C(lid,1))
		call pargd (EQW_F(lid,1))
		call pargd (EQW_E(lid,1))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"\"\" \"\" \"\" \"\" \"\" \"\"")
	}
	call gmsg (SPT_GP(spt), "eqwvalues", SPT_STRING(spt))
end
