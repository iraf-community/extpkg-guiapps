include	<error.h>
include	<gset.h>
include	<smw.h>
include	<mach.h>
include	<math/iminterp.h>
include	"spectool.h"
include	"lids.h"


# SPT_DEBLEND -- Deblend lines in a spectral region.

procedure spt_deblend (spt, reg, models, ng, option)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
pointer	models[ARB]		#I Model pointers
int	ng			#I Number of models
int	option			#I Fitting option

int	ngfit, fit[5], nsub, mc_n, mc_p, mc_sig
int	i, j, i1, i2, n, npts
long	seed
real	wx1, wx2, w, wy, dw, v, u
real	wyc, slope, flux, cont, eqw, peak, gfwhm, lfwhm, scale, sscale, chisq
real	wyc1, slope1, flux1, cont1, eqw1, width
double	d1, d2, dmin, dmax
pointer	lid, sh, sx, sy, se, sc
pointer	mods, pg, xg, yg, sg, lg, xg1, yg1, sg1, lg1
pointer	sp, cmd, x, y, s, z, ym, conte, xge, yge, sge, lge, fluxe, eqwe

long	clktime()
real	model(), asumr(), gasdev()
double	shdr_wl(), shdr_lw()
errchk	lid_colon, dofit, dorefit

begin
	if (ng == 0)
	    return

	call smark (sp)
	call salloc (cmd, SZ_FNAME, TY_CHAR)
	call salloc (mods, ng, TY_POINTER)
	call salloc (pg, ng, TY_INT)
	call salloc (xg, ng, TY_REAL)
	call salloc (yg, ng, TY_REAL)
	call salloc (sg, ng, TY_REAL)
	call salloc (lg, ng, TY_REAL)

	# Exclude subtracted lines.
	ngfit = 0
	do i = 1, ng {
	    lid = models[i]
	    if (MOD_SUB(lid) == YES)
		next

	    Memi[mods+ngfit] = lid
	    ngfit = ngfit + 1
	}

	if (ngfit == 0) {
	    call sfree (sp)
	    return
	}

	sh = REG_SH(reg)
	sx = SX(sh)
	sy = SPEC(sh,SPT_CTYPE(spt))
	se = SE(sh)
	sc = SC(sh)
	n = SN(sh)

	iferr {
	    # Set fitting region.
	    do i = 1, ngfit {
		lid = Memi[mods+i-1]
		d1 = MOD_X1(lid)
		d2 = MOD_X2(lid)
		if (IS_INDEFD(d1) || IS_INDEFD(d2))
		    call error (1, "Fitting region undefined")
		if (i == 1) {
		    dmin = min (d1, d2)
		    dmax = max (d1, d2)
		} else {
		    dmin = min (dmin, d1, d2)
		    dmax = max (dmax, d1, d2)
		}
	    }
	    dmin = max (0.5D0, min (double (SN(sh)+.499), shdr_wl(sh, dmin)))
	    dmax = max (0.5D0, min (double (SN(sh)+.499), shdr_wl(sh, dmax)))
	    i1 = nint (min (dmin, dmax))
	    i2 = nint (max (dmin, dmax))
	    dmin = shdr_lw (sh, double(i1))
	    dmax = shdr_lw (sh, double(i2))
	    wx1 = dmin
	    wx2 = dmax
	    npts = i2 - i1 + 1
	    if (npts < 3)
		call error (1, "At least 3 points are required")

	    # Set continuum.
	    lid = Memi[mods]
	    if (IS_INDEFD(MOD_A(lid)) || IS_INDEFD(MOD_B(lid))) {
		if (sc == NULL) {
		    wyc = Memr[sy+i1-1]
		    wy = Memr[sy+i2-1]
		} else {
		    wyc = Memr[sc+i1-1]
		    wy = Memr[sc+i2-1]
		}
		slope = (wy-wyc) / (wx2-wx1)
		wyc = wyc - slope * wx1
	    } else {
		slope = MOD_B(lid)
		wyc = MOD_A(lid) - MOD_B(lid) * MOD_X(lid)
	    }

	    # Allocate space for the points to be fit.
	    call salloc (x, npts, TY_REAL)
	    call salloc (y, npts, TY_REAL)
	    call salloc (s, npts, TY_REAL)
	    call salloc (z, npts, TY_REAL)

	    # Scale the data.
	    scale = 0.
	    do i = 1, npts {
		Memr[x+i-1] = Memr[sx+i1+i-2]
		Memr[y+i-1] = Memr[sy+i1+i-2]
		if (se == NULL)
		    Memr[s+i-1] = 1
		else
		    Memr[s+i-1] = Memr[se+i1+i-2]
		scale = max (scale, abs (Memr[y+i-1]))
	    }
	    sscale = asumr (Memr[s], npts) / npts
	    call adivkr (Memr[y], scale, Memr[y], npts)
	    call adivkr (Memr[s], sscale, Memr[s], npts)
	    slope = slope / scale
	    wyc = wyc / scale

	    # Set the initial profile parameters.
	    gfwhm = abs (Memr[x+npts-1] - Memr[x]) / ngfit
	    do i = 1, ngfit {
		lid = Memi[mods+i-1]
		if (IS_INDEFI(MOD_TYPE(lid)))
		    Memi[pg+i-1] = GAUSS
		else
		    Memi[pg+i-1] = MOD_TYPE(lid)
		if (IS_INDEFD(MOD_X(lid)))
		    Memr[xg+i-1] = (Memr[x+npts-1] + Memr[x]) / 2.
		else
		    Memr[xg+i-1] = MOD_X(lid)
		if (IS_INDEFD(MOD_Y(lid))) {
		    j = max (1,
			min (n, nint (shdr_wl (sh, double(Memr[xg+i-1])))))
		    Memr[yg+i-1] = Memr[sy+j-1]
		    Memr[yg+i-1] = Memr[yg+i-1] / scale -
			wyc - slope * Memr[xg+i-1]
		} else
		    Memr[yg+i-1] = MOD_Y(lid) / scale
		switch (Memi[pg+i-1]) {
		case GAUSS:
		    if (IS_INDEFD(MOD_G(lid)))
			Memr[sg+i-1] = 0.5 * gfwhm
		    else
			Memr[sg+i-1] = MOD_G(lid)
		    Memr[lg+i-1] = 0.
		case LORENTZ:
		    Memr[sg+i-1] = 0.
		    if (IS_INDEFD(MOD_L(lid)))
			Memr[lg+i-1] = 0.5 * gfwhm
		    else
			Memr[lg+i-1] = MOD_L(lid)
		case VOIGT:
		    if (IS_INDEFD(MOD_G(lid)))
			Memr[sg+i-1] = 0.5 * gfwhm
		    else
			Memr[sg+i-1] = MOD_G(lid)
		    if (IS_INDEFD(MOD_L(lid)))
			Memr[lg+i-1] = 0.5 * gfwhm
		    else
			Memr[lg+i-1] = MOD_L(lid)
		}
	    }

	    # Scale relative peak intensities and equal widths.
	    if (ngfit > 1 && SPT_MODPARS(spt,2) == 1) {
		peak = 0.
		do i = 0, ngfit-1 {
		    j = max (1,
			min (n, nint (shdr_wl (sh, double(Memr[xg+i])))))
		    peak = peak +  Memr[sy+j-1] / scale - wyc-slope*Memr[xg+i]
		}
		w = asumr (Memr[yg], ngfit)
		w = peak / w
		call amulkr (Memr[yg], w, Memr[yg], ngfit)
	    }
	    if (ngfit > 1 && SPT_MODPARS(spt,10) == 1) {
		w = asumr (Memr[sg], ngfit) / ngfit
		call amovkr (w, Memr[sg], ngfit)
	    }
	    if (ngfit > 1 && SPT_MODPARS(spt,11) == 1) {
		w = asumr (Memr[lg], ngfit) / ngfit
		call amovkr (w, Memr[lg], ngfit)
	    }

	    # Do fits.
	    switch (option) {
	    case 1:
		fit[BKG] = 1 + SPT_MODPARS(spt,5)
		fit[POS] = 2
		fit[INT] = 2
		fit[GAU] = 2
		fit[LOR] = 2
	    case 2:
		fit[BKG] = 1 + SPT_MODPARS(spt,5)
		fit[POS] = 1 + SPT_MODPARS(spt,1) *
		    (SPT_MODPARS(spt,1)+1-SPT_MODPARS(spt,6))
		fit[INT] = 1 + SPT_MODPARS(spt,2) *
		    (SPT_MODPARS(spt,2)+1-SPT_MODPARS(spt,7))
		fit[GAU] = 1 + SPT_MODPARS(spt,3) * (SPT_MODPARS(spt,3) + 1 -
		    (SPT_MODPARS(spt,8) + SPT_MODPARS(spt,10)))
		fit[LOR] = 1 + SPT_MODPARS(spt,4) * (SPT_MODPARS(spt,4) + 1 -
		    (SPT_MODPARS(spt,9) + SPT_MODPARS(spt,11)))
	    }
	    nsub = SPT_MODNSUB(spt)
	    dw = WP(sh)
	    call dofit (fit, Memr[x], Memr[y], Memr[s], npts,
		dw, nsub, wyc, slope,
		Memr[xg], Memr[yg], Memr[sg], Memr[lg], Memi[pg], ngfit, chisq)

	    # Compute Monte-Carlo errors.
	    if (SPT_ERRORS(spt) == YES && SPT_ERRMCN(spt) >= 10 && se != NULL) {
		mc_n = SPT_ERRMCN(spt)
		mc_p = nint (mc_n * SPT_ERRMCP(spt) / 100.)
		mc_sig = nint (mc_n * SPT_ERRMCSIG(spt) / 100.)

		call salloc (ym, npts, TY_REAL)
		call salloc (xg1, ngfit, TY_REAL)
		call salloc (yg1, ngfit, TY_REAL)
		call salloc (sg1, ngfit, TY_REAL)
		call salloc (lg1, ngfit, TY_REAL)
		call salloc (conte, mc_n*ngfit, TY_REAL)
		call salloc (xge, mc_n*ngfit, TY_REAL)
		call salloc (yge, mc_n*ngfit, TY_REAL)
		call salloc (sge, mc_n*ngfit, TY_REAL)
		call salloc (lge, mc_n*ngfit, TY_REAL)
		call salloc (fluxe, mc_n*ngfit, TY_REAL)
		call salloc (eqwe, mc_n*ngfit, TY_REAL)
		do i = 1, npts {
		    w = Memr[x+i-1]
		    Memr[ym+i-1] = model (w, dw, nsub, Memr[xg], Memr[yg],
			Memr[sg], Memr[lg], Memi[pg], ngfit) + wyc + slope * w
		}
		if (!IS_INDEFI(SPT_ERRMCSEED(spt)))
		    seed = SPT_ERRMCSEED(spt)
		else
		    seed = clktime (0)
		do i = 0, mc_n-1 {
#		   if (i > 0 && mod (i, mc_p) == 0) {
#			call printf ("%2d ")
#			    call pargi (100 * i / mc_n)
#			call flush (STDOUT)
#		    }
		    do j = 1, npts
			Memr[y+j-1] = Memr[ym+j-1] +
			    sscale / scale * Memr[s+j-1] * gasdev (seed)
		    wyc1 = wyc
		    slope1 = slope
		    call amovr (Memr[xg], Memr[xg1], ngfit)
		    call amovr (Memr[yg], Memr[yg1], ngfit)
		    call amovr (Memr[sg], Memr[sg1], ngfit)
		    call amovr (Memr[lg], Memr[lg1], ngfit)
		    call dorefit (fit, Memr[x], Memr[y], Memr[s], npts,
			dw, nsub, wyc1, slope1, Memr[xg1], Memr[yg1],
			Memr[sg1], Memr[lg1], Memi[pg], ngfit, chisq)

		    do j = 0, ngfit-1 {
			cont = wyc + slope * Memr[xg+j]
			cont1 = wyc1 + slope1 * Memr[xg+j]
			switch (Memi[pg+j]) {
			case GAUSS:
			    flux = 1.064467 * Memr[yg+j] * Memr[sg+j]
			    flux1 = 1.064467 * Memr[yg1+j] * Memr[sg1+j]
			case LORENTZ:
			    flux = 1.570795 * Memr[yg+j] * Memr[lg+j]
			    flux1 = 1.570795 * Memr[yg1+j] * Memr[lg1+j]
			case VOIGT:
			    call voigt (0., 0.832555*Memr[lg+j]/Memr[sg+j],
				v, u)
			    flux = 1.064467 * Memr[yg+j] * Memr[sg+j] / v
			    call voigt (0., 0.832555*Memr[lg1+j]/Memr[sg1+j],
				v, u)
			    flux1 = 1.064467 * Memr[yg1+j] * Memr[sg1+j] / v
			}
			if (cont > 0. && cont1 > 0.) {
			    eqw = -flux / cont
			    eqw1 = -flux1 / cont1
			} else {
			    eqw = 0.
			    eqw1 = 0.
			}
			Memr[conte+j*mc_n+i] = abs (cont1 - cont)
			Memr[xge+j*mc_n+i] = abs (Memr[xg1+j] - Memr[xg+j])
			Memr[yge+j*mc_n+i] = abs (Memr[yg1+j] - Memr[yg+j])
			Memr[sge+j*mc_n+i] = abs (Memr[sg1+j] - Memr[sg+j])
			Memr[lge+j*mc_n+i] = abs (Memr[lg1+j] - Memr[lg+j])
			Memr[fluxe+j*mc_n+i] = abs (flux1 - flux)
			Memr[eqwe+j*mc_n+i] = abs (eqw1 - eqw)
		    }
		}
		do j = 0, ngfit-1 {
		    call asrtr (Memr[conte+j*mc_n], Memr[conte+j*mc_n], mc_n)
		    call asrtr (Memr[xge+j*mc_n], Memr[xge+j*mc_n], mc_n)
		    call asrtr (Memr[yge+j*mc_n], Memr[yge+j*mc_n], mc_n)
		    call asrtr (Memr[sge+j*mc_n], Memr[sge+j*mc_n], mc_n)
		    call asrtr (Memr[lge+j*mc_n], Memr[lge+j*mc_n], mc_n)
		    call asrtr (Memr[fluxe+j*mc_n], Memr[fluxe+j*mc_n], mc_n)
		    call asrtr (Memr[eqwe+j*mc_n], Memr[eqwe+j*mc_n], mc_n)
		}
		call amulkr (Memr[conte], scale, Memr[conte], mc_n*ngfit)
		call amulkr (Memr[yge], scale, Memr[yge], mc_n*ngfit)
		call amulkr (Memr[fluxe], scale, Memr[fluxe], mc_n*ngfit)
	    }

	    call amulkr (Memr[yg], scale, Memr[yg], ngfit)
	    wyc = (wyc + slope * wx1) * scale
	    slope = slope * scale

	    # Log computed values
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "# %s\n")
		call pargstr (REG_TITLE(reg))
	    call spt_log (spt, reg, "title", SPT_STRING(spt))

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"# %8s%10s%10s%10s%10s%10s%10s\n")
		call pargstr ("center")
		call pargstr ("cont")
		call pargstr ("flux")
		call pargstr ("eqw")
		call pargstr ("core")
		call pargstr ("gfwhm")
		call pargstr ("lfwhm")
	    call spt_log (spt, reg, "header", SPT_STRING(spt))

	    do i = 1, ngfit {
		w = Memr[xg+i-1]
		j = max (1, min (n, nint (shdr_wl (sh, double(w)))))
		cont = wyc + slope * (w - wx1)
		peak = Memr[yg+i-1]
		gfwhm = Memr[sg+i-1]
		lfwhm = Memr[lg+i-1]
		switch (Memi[pg+i-1]) {
		case GAUSS:
		    flux = 1.064467 * peak * gfwhm
		    width = 2.6 * gfwhm
		case LORENTZ:
		    flux = 1.570795 * peak * lfwhm
		    width = 10 * lfwhm
		case VOIGT:
		    call voigt (0., 0.832555*lfwhm/gfwhm, v, u)
		    flux = 1.064467 * peak * gfwhm / v
		    width = max (2.6 * gfwhm, 10 * lfwhm)
		}
  
		if (cont > 0.)
		    eqw = -flux / cont
		else
		    eqw = INDEF

		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    " %9.7g %9.7g %9.6g %9.4g %9.6g %9.4g %9.4g\n")
		    call pargr (w)
		    call pargr (cont)
		    call pargr (flux)
		    call pargr (eqw)
		    call pargr (peak)
		    call pargr (gfwhm)
		    call pargr (lfwhm)
		call spt_log (spt, reg, "add", SPT_STRING(spt))

		if (ngfit == 1)
		    call printf (SPT_STRING(spt))

		if (SPT_ERRORS(spt)==YES && SPT_ERRMCN(spt)>=10 && se!=NULL) {
		    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		   " (%7.7g) (%7.7g) (%7.6g) (%7.4g) (%7.6g) (%7.4g) (%7.4g)\n")
			call pargr (Memr[xge+(i-1)*mc_n+mc_sig])
			call pargr (Memr[conte+(i-1)*mc_n+mc_sig])
			call pargr (Memr[fluxe+(i-1)*mc_n+mc_sig])
			call pargr (Memr[eqwe+(i-1)*mc_n+mc_sig])
			call pargr (Memr[yge+(i-1)*mc_n+mc_sig])
			call pargr (Memr[sge+(i-1)*mc_n+mc_sig])
			call pargr (Memr[lge+(i-1)*mc_n+mc_sig])
		    call spt_log (spt, reg, "add", SPT_STRING(spt))
		}

		# Update model.
		lid = Memi[mods+i-1]
		MOD_FIT(lid) = YES
		MOD_A(lid) = wyc + slope * (w - wx1)
		MOD_B(lid) = slope
		MOD_X(lid) = Memr[xg+i-1]
		MOD_Y(lid) = Memr[yg+i-1]
		MOD_G(lid) = Memr[sg+i-1]
		MOD_L(lid) = Memr[lg+i-1]
		MOD_F(lid) = flux
		MOD_E(lid) = eqw

		# Mark and label features.
		#call lid_nearest (spt, reg, double(w), INDEFD, lid)
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "line %d %g INDEF INDEF INDEF INDEF INDEF")
		    call pargi (LID_ITEM(lid))
		    call pargr (w)
		call lid_colon (spt, reg, double (w), double (cont+2*peak),
		    SPT_STRING(spt))
	    }
	} then
	    call erract (EA_WARN)

	call sfree (sp)
end


# SPT_SUBBLEND -- Subtract/add component.

procedure spt_subblend (spt, reg, lid, flag)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
pointer	lid			#I Model pointer
int	flag			#I Subtract?

int	i, i1, i2, n, nsub, p
real	a, b, x, y, g, l
real	dw, wx1, wy1, wx2, wy2
pointer	sh, gp, gt, sx, sy

real	model()

begin
	if (MOD_FIT(lid) == NO || flag == MOD_SUB(lid))
	    return

	gp = SPT_GP(spt)
	gt = SPT_GT(spt)
	sh = REG_SH(reg)
	dw = WP(sh)
	nsub = 3

	p = MOD_TYPE(lid)
	a = MOD_A(lid)
	b = MOD_B(lid)
	x = MOD_X(lid)
	y = MOD_Y(lid)
	g = MOD_G(lid)
	l = MOD_L(lid)

	if (MOD_SUB(lid) == NO) {
	    MOD_SUB(lid) = YES
	} else {
	    y = -y
	    MOD_SUB(lid) = NO
	}

	wx2 = max (1.6 * g, 8 * l)
	wx1 = x - wx2
	wx2 = x + wx2
	wy1 = 0.
	wy2 = 0.
	call fixx (sh, wx1, wx2, wy1, wy2, i1, i2)
	sx = SX(sh) + i1 - 1
	sy = SPEC(sh,SPT_CTYPE(spt)) + i1 - 1
	n = i2 - i1 + 1

	# Erase current data.
	call spt_plotreg1 (spt, reg, i1, i2, SPT_CTYPE(spt), YES)

	# Subtract model.
	do i = 0, n-1
	    Memr[sy+i] = Memr[sy+i] -
		model (Memr[sx+i], dw, nsub, x, y, g, l, p, 1)

	# Plot subtracted data.
	call spt_plotreg1 (spt, reg, i1, i2, SPT_CTYPE(spt), NO)
	call gflush (gp)
end


# SPT_PLOTBLEND -- Plot component.

procedure spt_plotblend (spt, reg, lid)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
pointer	lid			#I Component model

int	i, j, nlids, p, nsub, nw, pltype, plcolor, gstati()
real	a, b, x, y, g, l
real	wp, w, wlast, w1, w2, w3, dw, z, zlast, model()
pointer	lids, gp, sum, ptr

begin
	if (MOD_FIT(lid) == NO || MOD_DRAW(lid) == NO)
	    return

	gp = SPT_GP(spt)
	wp = WP(REG_SH(reg))
	nsub = 3

	p = MOD_TYPE(lid)
	a = MOD_A(lid)
	b = MOD_B(lid)
	x = MOD_X(lid)
	y = MOD_Y(lid)
	g = MOD_G(lid)
	l = MOD_L(lid)

	dw = max (1.8 * g, 8 * l)
	w1 = x - dw
	w2 = x + dw
	dw = wp / 10
	nw = (w2 - w1) / dw + 1


	if (MOD_CDRAW(lid) == YES) {
	    pltype = gstati (gp, G_PLTYPE)
	    plcolor = gstati (gp, G_PLCOLOR)
	    call gseti (gp, G_PLTYPE, 1)
	    call gseti (gp, G_PLCOLOR, MOD_CCOL(lid))
	    zlast = a + b * (w1 - x)
	    z = a + b * (w2 - x)
	    call gline (gp, w1, zlast, w2, z)
	    call gseti (gp, G_PLCOLOR, plcolor)
	    call gseti (gp, G_PLTYPE, pltype)
	}

	if (MOD_PDRAW(lid) == YES || MOD_SDRAW(lid) == YES) {
	    pltype = gstati (gp, G_PLTYPE)
	    plcolor = gstati (gp, G_PLCOLOR)
	    call gseti (gp, G_PLTYPE, 1)
	    call gseti (gp, G_PLCOLOR, MOD_PCOL(lid))
	    do i = 0, nw-1 {
		w = w1 + i * dw
		z = model (w, wp, nsub, x, y, g, l, p, 1) + a + b * (w - x)
		if (MOD_PDRAW(lid) == YES) {
		    if (i > 0)
			call gline (gp, wlast, zlast, w, z)
		    wlast = w
		    zlast = z
		}

		if (MOD_SDRAW(lid) == YES) {
		    if (i == 0) {
			call malloc (sum, nw, TY_REAL)
			lids = REG_LIDS(reg)
			nlids = LID_NLINES(lids)
		    }
		    do j = LID_ITEM(lid)-1, 1, -1 {
			ptr = LID_LINES(lids,j)
			w3 = MOD_X(ptr) + max (1.8 * MOD_G(ptr), 8 * MOD_L(ptr))
			if (w3 < w)
			    break
			z = z + model (w, wp, nsub, real(MOD_X(ptr)),
			    real(MOD_Y(ptr)), real(MOD_G(ptr)),
			    real(MOD_L(ptr)), MOD_TYPE(ptr), 1)
		    }
		    do j = LID_ITEM(lid)+1, nlids {
			ptr = LID_LINES(lids,j)
			w3 = MOD_X(ptr) - max (1.8 * MOD_G(ptr), 8 * MOD_L(ptr))
			if (w3 > w)
			    break
			z = z + model (w, wp, nsub, real(MOD_X(ptr)),
			    real(MOD_Y(ptr)), real(MOD_G(ptr)),
			    real(MOD_L(ptr)), MOD_TYPE(ptr), 1)
		    }
		    Memr[sum+i] = z
		}
	    }
	    call gseti (gp, G_PLCOLOR, plcolor)
	    call gseti (gp, G_PLTYPE, pltype)
	}

	if (MOD_SDRAW(lid) == YES) {
	    pltype = gstati (gp, G_PLTYPE)
	    plcolor = gstati (gp, G_PLCOLOR)
	    call gseti (gp, G_PLTYPE, 1)
	    call gseti (gp, G_PLCOLOR, MOD_SCOL(lid))
	    do i = 0, nw-1 {
		w = w1 + i * dw
		z = Memr[sum+i]
		if (i > 0)
		    call gline (gp, wlast, zlast, w, z)
		wlast = w
		zlast = z
	    }
	    call mfree (sum, TY_REAL)
	    call gseti (gp, G_PLCOLOR, plcolor)
	    call gseti (gp, G_PLTYPE, pltype)
	}

	call gflush (gp)
end


# GASDEV -- Return a normally distributed deviate with zero mean and unit
# variance.  The method computes two deviates simultaneously.
#
# Based on Numerical Recipes by Press, Flannery, Teukolsky, and Vetterling.
# Used by permission of the authors.
# Copyright(c) 1986 Numerical Recipes Software.

real procedure gasdev (seed)

long	seed		# Seed for random numbers

real	v1, v2, r, fac, urand()
int	iset
data	iset/0/

begin
	if (iset == 0) {
	    repeat {
	        v1 = 2 * urand (seed) - 1.
	        v2 = 2 * urand (seed) - 1.
	        r = v1 ** 2 + v2 ** 2
	    } until ((r > 0) && (r < 1))
	    fac = sqrt (-2. * log (r) / r)

	    iset = 1
	    return (v1 * fac)
	} else {
	    iset = 0
	    return (v2 * fac)
	}
end
