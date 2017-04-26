include	<error.h>
include	<smw.h>
include	<pkg/gtools.h>
include	"spectool.h"

define	TYPES		"|fit|reject|clean|"
define	FIT		1
define	REJECT		2
define	CLEAN		3


# SPT_ICFIT -- Call ICFIT for various functions.
# Syntax: type [outreg] [inreg]
#    where type is one of the fitting types and inreg and outreg are
#    register designations.  The defaults for the registers are the current
#    register.

procedure spt_icfit (spt, inreg, instype, outreg, outstype, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	inreg			#I Input register
int	instype			#I Input spectrum type
pointer	outreg			#I Output register
int	outstype		#I Output spectrum type
char	cmd[ARB]		#I ICFIT command

int	sn, type
pointer	sp, str, gp, gt, sx, sy1, sy2, sw

int	nscan(), strdic()
errchk	spt_icfit1

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	iferr {
	    call sscan (cmd)

	    # Fitting type.
	    call gargwrd (Memc[str], SZ_LINE)
	    if (nscan() != 1)
		call error (1, "icfit: no fit type")
	    type = strdic (Memc[str], Memc[str], SZ_LINE, TYPES)
	    if (type == 0)
		call error (1, "icfit: unknown fit type")

	    # Do the fit.
	    gp = SPT_GP(spt)
	    gt = SPT_GT(spt)
	    sx = SX(REG_SH(inreg))
	    sy1 = SPEC(REG_SH(inreg),instype)
	    sy2 = SPEC(REG_SH(outreg),outstype)
	    if (sy2 == NULL) {
		call malloc (SPEC(REG_SH(outreg),outstype), SN(REG_SH(outreg)),
		    TY_REAL)
		sy2 = SPEC(REG_SH(outreg),outstype)
	    }
	    sn = min (SN(REG_SH(inreg)), SN(REG_SH(outreg))) 
	    call salloc (sw, sn, TY_REAL)
	    call amovkr (1., Memr[sw], sn)

	    call spt_shcopy (REG_SH(outreg), REG_SHBAK(outreg), YES)
	    call spt_icfit1 (type, gp, gt, Memr[sx], Memr[sy1], Memr[sw],
		Memr[sy2], sn)

	} then
	    call erract (EA_ERROR)

	SPT_PLOT(spt,outstype) = YES
	call spt_scale (spt, outreg)
	SPT_REDRAW(spt,1) = YES
	call sfree (sp)
end


# SPT_ICFIT1 -- Call ICFIT to fit data.

procedure spt_icfit1 (type, gp, gt, x, y, w, fit, n)

int	type		#I Final fit type
pointer	gp		#I GIO pointer
pointer	gt		#I GTOOL pointer
real	x[n]		#I X coordinates
real	y[n]		#I Y values to fit
real	w[n]		#I Weights
real	fit[n]		#I Array for fit results.
int	n		#I Number of points

int	i
bool	b
real	r
pointer	sp, str, gt2, ic, cv

bool	clgetb()
real 	clgetr(), ic_getr(), cveval(), gt_getr()
int	clgeti(), ic_geti(), btoi()
errchk	icg_fit

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	call ic_open (ic)
	call clgstr ("function", Memc[str], SZ_FNAME)
	call ic_pstr (ic, "function", Memc[str])
	call ic_puti (ic, "order", clgeti ("order"))
	call ic_putr (ic, "low", clgetr ("low_reject"))
	call ic_putr (ic, "high", clgetr ("high_reject"))
	call ic_puti (ic, "niterate", clgeti ("niterate"))
	call ic_putr (ic, "grow", clgetr ("grow"))
	call ic_puti (ic, "markrej", btoi (clgetb ("markrej")))
	call ic_putr (ic, "xmin", min (x[1], x[n]))
	call ic_putr (ic, "xmax", max (x[1], x[n]))
	call ic_puti (ic, "key", 1)

	call gt_copy (gt, gt2)
	r = gt_getr (gt2, GTVYMAX)
	if (!IS_INDEFR(r))
	    call gt_setr (gt2, GTVYMAX, min (r, 0.85))
	call gt_gets (gt2, GTXLABEL, Memc[str], SZ_FNAME)
	call ic_pstr (ic, "xlabel", Memc[str])
	call gt_gets (gt2, GTYLABEL, Memc[str], SZ_FNAME)
	call ic_pstr (ic, "ylabel", Memc[str])
	call gt_gets (gt2, GTXUNITS, Memc[str], SZ_FNAME)
	call ic_pstr (ic, "xunits", Memc[str])
	call gt_gets (gt2, GTYUNITS, Memc[str], SZ_FNAME)
	call ic_pstr (ic, "yunits", Memc[str])

	call gmsg (gp, "output", "icfit")
	call icg_fit (ic, gp, "cursor", gt2, cv, x, y, w, n)
	call gmsg (gp, "output", "icfitDone")

	switch (type) {
	case FIT, REJECT:
	    do i = 1, n
		fit[i] = cveval (cv, x[i])
	case CLEAN:
	    call amovr (y, fit, n)
	    call ic_clean (ic, cv, x, fit, w, n)
	}

	# Save curfit parameters.
	call ic_gstr (ic, "function", Memc[str], SZ_FNAME)
	call clpstr ("function", Memc[str])
	call clputi ("order", ic_geti (ic, "order"))
	call clputr ("low_reject", ic_getr (ic, "low"))
	call clputr ("high_reject", ic_getr (ic, "high"))
	call clputi ("niterate", ic_geti (ic, "niterate"))
	call clputr ("grow", ic_getr (ic, "grow"))
	b = (ic_geti (ic, "markrej") == YES)
	call clputb ("markrej", b)

	call cv_free (cv)
	call gt_free (gt2)
	call ic_closer (ic)
	call sfree (sp)
end


# SPT_ICCONTINUUM -- Fit continuum non-interactively.

procedure spt_iccontinuum (x, y, fit, n)

real	x[n]		#I X coordinates
real	y[n]		#I Y values to fit
real	fit[n]		#I Array for fit results.
int	n		#I Number of points

int	i
pointer	ic, cv
real 	cveval()
errchk	ic_fit

begin
	call ic_open (ic)
	call ic_pstr (ic, "function", "spline3")
	call ic_puti (ic, "order", max (1,n/100))
	call ic_putr (ic, "low", 2.)
	call ic_putr (ic, "high", 2.)
	call ic_puti (ic, "niterate", 3)
	call ic_putr (ic, "grow", 1.)
	call ic_putr (ic, "xmin", min (x[1], x[n]))
	call ic_putr (ic, "xmax", max (x[1], x[n]))

	call amovkr (1., fit, n)
	call ic_fit (ic, cv, x, y, fit, n, YES, YES, YES, YES)
	do i = 1, n
	    fit[i] = cveval (cv, x[i])

	call ic_closer (ic)
end
