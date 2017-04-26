include	<error.h>
include	<smw.h>
include <units.h>
include	<math/curfit.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"lids.h"

# List of colon commands.
define	CMDS "|open|close|first|last|step|shift|lineshift|fitlines\
	      |redshift|deredshift|"
define	OPEN		1
define	CLOSE		2
define	FIRST		3	# Coordinate of first pixel
define	LAST		4	# coordinate of last pixel
define	STEP		5	# Coordinate step
define	SHIFT		6	# Shift by specified amount
define	LINESHIFT	7	# Shift by average of lines
define	FITLINES	8	# Fit dispersion function to lines
define	REDSHIFT	9	# Redshift by specified amount
define	DEREDSHIFT	10	# Deredshift by specified amount


# SPT_COORD -- Modify coordinates.

procedure spt_coord (spt, reg, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
char	cmd[ARB]		#I GIO command

int	i, n, ncmd, format, ap, beam, dtype, nw
real	aplow[2], aphigh[2]
double	w0, w1, dw, z, shift
pointer	gt, sh, lids, lid, rv, coeff, smw, mw

int	strdic(), nscan()
double	clgetd(), shdr_lw()
pointer	un_open()
errchk	un_open, shdr_system, spt_fit, smw_swattrs()

define	err_	10

begin
	iferr {
	    # Scan the command string and get the first word.
	    call sscan (cmd)
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	    coeff = NULL
	    if (reg != NULL) {
		gt = SPT_GT(spt)
		sh = REG_SH(reg)
		lids = REG_LIDS(reg)
		rv = REG_RV(reg)
		coeff = NULL
		smw = MW(sh)
		mw = SMW_MW(smw,0)
		format = SMW_FORMAT(smw)
		call smw_gwattrs (MW(sh), APINDEX(sh), LINDEX(sh,2),
		    ap, beam, dtype, w0, dw, nw, z, aplow, aphigh, coeff)
	    }

	    switch (ncmd) {
	    case OPEN:
		;
	    case CLOSE:
		;
	    case FIRST, LAST, STEP:
		switch (ncmd) {
		case FIRST:
		    call gargd (w0)
		    if (nscan() == 1)
			w0 = clgetd ("sptqueries.first")
		    call un_ctrand (UN(sh), MWUN(sh), w0, w0, 1)
		    w1 = shdr_lw (sh, double(nw))
		    call un_ctrand (UN(sh), MWUN(sh), w1, w1, 1)
		    dw = (w1 - w0) / (nw - 1)
		case LAST:
		    call gargd (w1)
		    if (nscan() == 1)
			w1 = clgetd ("sptqueries.last")
		    call un_ctrand (UN(sh), MWUN(sh), w1, w1, 1)
		    dw = (w1 - w0) / (nw - 1)
		case STEP:
		    call gargd (dw)
		    if (nscan() == 1)
			dw = clgetd ("sptqueries.step")
		    w1 = shdr_lw (sh, 1D0) + dw
		    call un_ctrand (UN(sh), MWUN(sh), w1, w1, 1)
		    dw = w1 - w0 
		}

		z = 0.
		dtype = DCLINEAR
		if (UNITS(sh) == EOS) {
		    call un_close (UN(sh))
		    UN(sh) = un_open (SPT_UNITS(spt))
		    if (UN_TYPE(UN(sh)) == UN_UNKNOWN)
			call un_decode (UN(sh), SPT_UNKNOWN(spt))
		    call mw_swattrs (mw, SMW_PAXIS(smw,1), "label",
			UN_LABEL(UN(sh)))
		    call mw_swattrs (mw, SMW_PAXIS(smw,1),
			"units", UN_UNITS(UN(sh)))
		}
	    case SHIFT, LINESHIFT:
		switch (ncmd) {
		case SHIFT:
		    call gargd (shift)
		    if (nscan() == 1)
			shift = clgetd ("sptqueries.shift")
		case LINESHIFT:
		    if (lids == NULL)
			call error (1, "No lines defined")
		    shift = 0.
		    n = 0
		    do i = 1, LID_NLINES(lids) {
			lid = LID_LINES(lids,i)
			if (IS_INDEFD(LID_REF(lid)))
			    next
			shift = shift + LID_REF(lid) - LID_X(lid)
			n = n + 1
		    }
		    if (n == 0)
			call error (1, "No lines defined")
		    shift = shift / n
		}

		call un_ctrand (MWUN(sh), UN(sh), w0, w1, 1)
		call un_ctrand (UN(sh), MWUN(sh), w1+shift, w1, 1)
		shift = w1 - w0
		w0 = w0 + shift
		if (dtype == DCFUNC)
		    call sshift1 (shift, coeff)
	    case FITLINES:
		call spt_fit (spt, reg, dtype, w0, dw, nw, z, coeff)
		if (UNITS(sh) == EOS) {
		    call un_close (UN(sh))
		    UN(sh) = un_open (SPT_UNITS(spt))
		    if (UN_TYPE(UN(sh)) == UN_UNKNOWN)
			call un_decode (UN(sh), SPT_UNKNOWN(spt))
		    call mw_swattrs (mw, SMW_PAXIS(smw,1), "label",
			UN_LABEL(UN(sh)))
		    call mw_swattrs (mw, SMW_PAXIS(smw,1),
			"units", UN_UNITS(UN(sh)))
		}
	    case REDSHIFT:
		call gargd (shift)
		if (nscan() == 1)
		    shift = clgetd ("sptqueries.redshift")
		z = (1 + z) / (1 + shift) - 1
	    case DEREDSHIFT:
		call gargd (shift)
		if (nscan() == 1)
		    shift = clgetd ("sptqueries.redshift")
		z = (1 + z) * (1 + shift) - 1

	    default: # error or unknown command
err_	
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		   "Error: coord %s")
		    call pargstr (cmd)
		call error (1, SPT_STRING(spt))
	    }

	    if (reg != NULL) {
		gt = SPT_GT(spt)


		# Convert to new dispersion.
		call spt_runits (spt, reg, 1, NO)
		call spt_shcopy (sh, REG_SHBAK(reg), YES)
		call smw_swattrs (smw, LINDEX(sh,1), 1, ap, beam, dtype, w0,
		    dw, nw, z, aplow, aphigh, Memc[coeff])
		call mfree (coeff, TY_CHAR)
		if (smw != MW(sh)) {
		    CTLW1(sh) = NULL
		    CTWL1(sh) = NULL
		    MW(sh) = smw
		}
		DC(sh) = dtype
		call shdr_system (sh, "world")
		call alimr (Memr[SX(sh)], SN(sh), REG_X1(reg), REG_X2(reg))
		call spt_runits (spt, reg, 2, NO)
		call spt_rv (spt, reg, "set")

		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES
	    }
	} then {
	    call mfree (coeff, TY_CHAR)
	    call erract (EA_ERROR)
	}

end


procedure spt_fit (spt, reg, dtype, w0, dw, nw, z, coeff)

pointer	spt		#I SPECTOOL pointer
pointer	reg		#I Register pointer
int	dtype		#O Dispersion type
double	w0		#O Starting coordinate
double	dw		#O Dispersion per pixel
int	nw		#O Number of pixels
double	z		#O Redshift
pointer	coeff		#O Dispersion function

int	i, n, nfit, fd, dcvstati(), stropen()
double	shdr_wl(), dcveval()
pointer	sp, xfit, yfit, wfit, lids, sh, lid, gp, gt, ic, cv, coeffs, gt_init1()

begin
	if (reg == NULL)
	    return
	lids = REG_LIDS(reg)
	if (lids == NULL)
	    call error (1, "No lines defined")

	nfit = 0
	do i = 1, LID_NLINES(lids) {
	    lid = LID_LINES(lids,i)
	    if (IS_INDEFD(LID_REF(lid)))
		next
	    nfit = nfit + 1
	}
	if (nfit < 2)
	    call error (1,
		"At least two lines with reference coordinates must be defined")

	call smark (sp)
	call salloc (xfit, nfit, TY_DOUBLE)
	call salloc (yfit, nfit, TY_DOUBLE)
	call salloc (wfit, nfit, TY_DOUBLE)

	sh = REG_SH(reg)

	nfit = 0
	do i = 1, LID_NLINES(lids) {
	    lid = LID_LINES(lids,i)
	    if (IS_INDEFD(LID_REF(lid)))
		next
	    Memd[xfit+nfit] = shdr_wl (sh, LID_X(lid))
	    Memd[yfit+nfit] = LID_REF(lid)
	    Memd[wfit+nfit] = 1.
	    nfit = nfit + 1
	}
	call xt_sort3d (Memd[xfit], Memd[yfit], Memd[wfit], nfit)

        call ic_open (ic)
        call ic_pstr (ic, "function", "legendre")
        call ic_puti (ic, "order", 2)
        call ic_putr (ic, "low", 3.)
        call ic_putr (ic, "high", 3.)
        call ic_puti (ic, "niterate", 0)
        call ic_putr (ic, "grow", 0.)
        call ic_puti (ic, "markrej", YES)
        call ic_putr (ic, "xmin", 1.)
        call ic_putr (ic, "xmax", real(nw))
        call ic_puti (ic, "key", 1)

        call ic_open (ic)
        call ic_pstr (ic, "function", "legendre")
        call ic_puti (ic, "order", 2)
        call ic_pstr (ic, "sample", "*")
        call ic_puti (ic, "naverage", 1)
        call ic_puti (ic, "niterate", 0)
        call ic_putr (ic, "low", 3.)
        call ic_putr (ic, "high", 3.)
        call ic_putr (ic, "grow", 0.)
        call ic_pstr (ic, "xlabel", "Feature positions")
        call ic_pstr (ic, "xunits", "pixels")
        call ic_pstr (ic, "ylabel", "")
        call ic_pkey (ic, 1, 'y', 'x')
        call ic_pkey (ic, 2, 'y', 'v')
        call ic_pkey (ic, 3, 'y', 'r')
        call ic_pkey (ic, 4, 'y', 'd')
        call ic_pkey (ic, 5, 'y', 'n')
        call ic_puti (ic, "key", 3)

	gp = SPT_GP(spt)
	gt = gt_init1(gp)
	call gmsg (gp, "output", "icfit")
	call icg_fitd (ic, gp, "cursor", gt, cv,
	    Memd[xfit], Memd[yfit], Memd[wfit], nfit)
	call gmsg (gp, "output", "icfitDone")

	w0 = dcveval (cv, 1D0)
	dw = (dcveval (cv, double(nw)) - w0) / (nw - 1)
	z = 0.
	i = dcvstati (cv, CVTYPE)
	n = dcvstati (cv, CVORDER)
	if ((i == CHEBYSHEV || i == LEGENDRE) && n == 2) {
	    dtype = DCLINEAR
	    Memc[coeff] = EOS
	} else {
	    dtype = DCFUNC
	    n = dcvstati (cv, CVNSAVE)
	    call salloc (coeffs, n, TY_DOUBLE)
	    call dcvsave (cv, Memd[coeffs])
	    call realloc (coeff, 20*(n+2), TY_CHAR)
	    fd = stropen (Memc[coeff], 20*(n+2), NEW_FILE)
	    call fprintf (fd, "1 0 %d %d")
	    call pargi (nint (Memd[coeffs]))
	    call pargi (nint (Memd[coeffs+1]))
	    do i = 2, n-1 {
		call fprintf (fd, " %g")
		    call pargd (Memd[coeffs+i])
	    }
	    call close (fd)
	}

	call dcvfree (cv)
	call ic_closed (ic)
	call gt_free (gt)
	call sfree (sp)
end
