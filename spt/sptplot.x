include	<imhdr.h>
include	<gset.h>
include	<mach.h>
include	<smw.h>
include	<units.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"rv.h"

# List of colon commands.
define	CMDS "|open|close|redraw|pan|overplot|stack|xflip|yflip|zero\
		|spectrum|continuum|raw|sky|sigma|labels|lines|models|units|"

define	OPEN	1	# Open/allocate/initialize
define	CLOSE	2	# Close/free
define	REDRAW	3	# Redraw
define	PAN	4	# Pan window
define	OVRPLT	5	# Overplot
define	STCK	6	# Stack
define	XFLIP	7	# Flip plot
define	YFLIP	8	# Flip plot
define	ZERO	9	# Flip plot
define	PSPEC	10	# Plot spectrum
define	PCONT	11	# Plot continuum
define	PRAW	12	# Plot raw
define	PSKY	13	# Plot sky
define	PSIG	14	# Plot sigma
define	LABELS	15	# Plot labels
define	LINES	16	# Plot lines
define	MODELS	17	# Plot models
define	UNIT	18	# Change units

# SPT_PLOTCOLON -- Interpret plot colon commands.

procedure spt_plotcolon (spt, reg, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
char	cmd[ARB]		#I GIO command

int	ncmd, type
real	rmin, rmax
bool	bval1, bval2
pointer	gp, gt

bool	clgetb(), streq()
int	strdic(), nscan(), btoi(), gt_geti()
real	gt_getr()
double	shdr_lw(), shdr_wl()

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	gp = SPT_GP(spt)
	gt = SPT_GT(spt)

	switch (ncmd) {
	case OPEN:
	    SPT_PLOT(spt,SHDATA) = btoi (clgetb ("plotspec"))
	    SPT_PLOT(spt,SHCONT) = btoi (clgetb ("plotcont"))
	    SPT_PLOT(spt,SHRAW) = btoi (clgetb ("plotraw"))
	    SPT_PLOT(spt,SHSKY) = btoi (clgetb ("plotsky"))
	    SPT_PLOT(spt,SHSIG) = btoi (clgetb ("plotsig"))

	    if (SPT_PLOT(spt,SHSIG) == YES)
		SPT_CTYPE(spt) = SHSIG
	    if (SPT_PLOT(spt,SHCONT) == YES)
		SPT_CTYPE(spt) = SHCONT
	    if (SPT_PLOT(spt,SHSKY) == YES)
		SPT_CTYPE(spt) = SHSKY
	    if (SPT_PLOT(spt,SHRAW) == YES)
		SPT_CTYPE(spt) = SHRAW
	    if (SPT_PLOT(spt,SHDATA) == YES)
		SPT_CTYPE(spt) = SHDATA

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"stypes %d %d %d %d %d")
		call pargi (SPT_PLOT(spt,SHDATA))
		call pargi (SPT_PLOT(spt,SHRAW))
		call pargi (SPT_PLOT(spt,SHSKY))
		call pargi (SPT_PLOT(spt,SHCONT))
		call pargi (SPT_PLOT(spt,SHSIG))
	    call gmsg (gp, "setGui", SPT_STRING(spt))

	    SPT_ZERO(spt) = NO
	    call gmsg (gp, "setGui", "zero 0")

	case CLOSE:
	    call clputb ("plotspec", SPT_PLOT(spt,SHDATA)==YES)
	    call clputb ("plotcont", SPT_PLOT(spt,SHCONT)==YES)
	    call clputb ("plotraw", SPT_PLOT(spt,SHRAW)==YES)
	    call clputb ("plotsky", SPT_PLOT(spt,SHSKY)==YES)
	    call clputb ("plotsig", SPT_PLOT(spt,SHSIG)==YES)
#	    call clputb ("viewntrl", SPT_VIEWCNTRL(spt)==YES)
	    call clputb ("pan", SPT_FINDER(spt)==YES)

	case REDRAW: # redraw [both|finder]
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    switch (SPT_STRING(spt)) {
	    case 'b':
		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES
	    case 'f':
		SPT_REDRAW(spt,2) = YES
	    default:
		SPT_REDRAW(spt,1) = YES
	    }

	case PAN:
	    bval1 = (SPT_FINDER(spt) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		# Need to redraw both to get the timing right for updating the
		# WCS marker.
		SPT_FINDER(spt) = btoi (bval2)
		SPT_REDRAW(spt,1) = btoi (bval2)
		SPT_REDRAW(spt,2) = btoi (bval2)
		if (bval2)
		    call gmsg (gp, "setGui", "finder 1")
		else
		    call gmsg (gp, "setGui", "finder 0")
	    }

	case OVRPLT: # overplot [yes|no]
	    bval1 = (SPT_PMODE(spt) == OPLOT)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_PMODE1(spt) = SPT_PMODE(spt)
		if (bval2) {
		    SPT_PMODE(spt) = OPLOT
		    call gmsg (gp, "setGui", "overplot 1")
		} else {
		    SPT_PMODE(spt) = PLOT1
		    call gmsg (gp, "setGui", "overplot 0")
		}
		call gmsg (gp, "setGui", "stack 0")
		call spt_reg (spt, reg, "plot")
	    }

	case STCK: # stack [yes|no]
	    bval1 = (SPT_PMODE(spt) == STACK)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_PMODE1(spt) = SPT_PMODE(spt)
		if (bval2) {
		    SPT_PMODE(spt) = STACK
		    call gmsg (gp, "setGui", "stack 1")
		} else {
		    SPT_PMODE(spt) = PLOT1
		    call gmsg (gp, "setGui", "stack 0")
		}
		call gmsg (gp, "setGui", "overplot 0")
		call spt_reg (spt, reg, "plot")
	    }

	case XFLIP: # xflip [yes|no]
	    bval1 = (gt_geti (gt, GTXFLIP) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		call gt_seti (gt, GTXFLIP, btoi (bval2))
		if (bval2)
		    call gmsg (gp, "setGui", "xflip 1")
		else
		    call gmsg (gp, "setGui", "xflip 0")
		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES
	    }

	case YFLIP: # yflip [yes|no]
	    bval1 = (gt_geti (gt, GTYFLIP) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		call gt_seti (gt, GTYFLIP, btoi (bval2))
		if (bval2)
		    call gmsg (gp, "setGui", "yflip 1")
		else
		    call gmsg (gp, "setGui", "yflip 0")
		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES
	    }

	case ZERO: # zero [yes|no]
	    bval1 = (SPT_ZERO(spt) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_ZERO(spt) = btoi (bval2)
		if (bval2)
		    call gmsg (gp, "setGui", "zero 1")
		else
		    call gmsg (gp, "setGui", "zero 0")
		SPT_REDRAW(spt,1) = YES
	    }

	case PSPEC, PCONT, PRAW, PSKY, PSIG: # <type> [yes|no]
	    switch (ncmd) {
	    case PSPEC:
		type = SHDATA
	    case PCONT:
		type = SHCONT
	    case PRAW:
		type = SHRAW
	    case PSKY:
		type = SHSKY
	    case PSIG:
		type = SHSIG
	    }
	    bval1 = (SPT_PLOT(spt,type) == YES)

	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_PLOT(spt,type) = btoi (bval2)
		if (SPT_PLOT(spt,SHSIG) == YES)
		    SPT_CTYPE(spt) = SHSIG
		if (SPT_PLOT(spt,SHCONT) == YES)
		    SPT_CTYPE(spt) = SHCONT
		if (SPT_PLOT(spt,SHSKY) == YES)
		    SPT_CTYPE(spt) = SHSKY
		if (SPT_PLOT(spt,SHRAW) == YES)
		    SPT_CTYPE(spt) = SHRAW
		if (SPT_PLOT(spt,SHDATA) == YES)
		    SPT_CTYPE(spt) = SHDATA
		call spt_scale (spt, reg)
		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "stypes %d %d %d %d %d")
		    call pargi (SPT_PLOT(spt,SHDATA))
		    call pargi (SPT_PLOT(spt,SHRAW))
		    call pargi (SPT_PLOT(spt,SHSKY))
		    call pargi (SPT_PLOT(spt,SHCONT))
		    call pargi (SPT_PLOT(spt,SHSIG))
		call gmsg (gp, "setGui", SPT_STRING(spt))
	    }

	case LABELS:
	    bval1 = (SPT_LABEL(spt) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_LABEL(spt) = btoi (bval2)
		SPT_REDRAW(spt,1) = YES
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "labels %d")
		    call pargi (SPT_LABEL(spt))
		call gmsg (gp, "setGui", SPT_STRING(spt))
	    }

	case LINES:
	    bval1 = (SPT_LINES(spt) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_LINES(spt) = btoi (bval2)
		SPT_REDRAW(spt,1) = YES
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "lines %d")
		    call pargi (SPT_LINES(spt))
		call gmsg (gp, "setGui", SPT_STRING(spt))
	    }

	case MODELS:
	    bval1 = (SPT_MODPLOT(spt) == YES)
	    call gargb (bval2)
	    if (nscan() == 1)
		bval2 = !bval1

	    if (bval2 != bval1) {
		SPT_MODPLOT(spt) = btoi (bval2)
		SPT_REDRAW(spt,1) = YES
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "models %d")
		    call pargi (SPT_MODPLOT(spt))
		call gmsg (gp, "setGui", SPT_STRING(spt))
	    }

	case UNIT:
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    if (nscan() != 2)
		goto err_

	    if (reg == NULL)
		return
	    if (REG_SH(reg) == NULL)
		return

	    if (streq (SPT_STRING(spt), "logical")) {
		rmin = gt_getr (gt, GTXMIN)
		if (!IS_INDEF(rmin)) {
		    rmin = shdr_wl (REG_SH(reg), double(rmin))
		    call gt_setr (gt, GTXMIN, rmin)
		}
		rmax = gt_getr (gt, GTXMAX)
		if (!IS_INDEF(rmax)) {
		    rmax = shdr_wl (REG_SH(reg), double(rmax))
		    if (!IS_INDEF(rmin) &&
			((gt_geti (gt, GTXFLIP) == NO && rmin > rmax) ||
			(gt_geti (gt, GTXFLIP) == YES && rmax > rmin))) {
			call gt_setr (gt, GTXMIN, rmax)
			call gt_setr (gt, GTXMAX, rmin)
		    } else
			call gt_setr (gt, GTXMAX, rmax)
		}
	    } else {
		rmin = gt_getr (gt, GTXMIN)
		if (!IS_INDEF(rmin)) {
		    rmin = shdr_lw (REG_SH(reg), double(rmin))
		    call gt_setr (gt, GTXMIN, rmin)
		}
		rmax = gt_getr (gt, GTXMAX)
		if (!IS_INDEF(rmax)) {
		    rmax = shdr_lw (REG_SH(reg), double(rmax))
		    if (!IS_INDEF(rmin) &&
			((gt_geti (gt, GTXFLIP) == NO && rmin > rmax) ||
			(gt_geti (gt, GTXFLIP) == YES && rmax > rmin))) {
			call gt_setr (gt, GTXMIN, rmax)
			call gt_setr (gt, GTXMAX, rmin)
		    } else
			call gt_setr (gt, GTXMAX, rmax)
		}
	    }

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: plot %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


procedure spt_replot (spt)

pointer	spt		#I SPECTOOL pointer

int	i
pointer	gp, spt_gp()
errchk	spt_finder, spt_plot, spt_gp

begin
	i = SPT_WCS(spt)

	# The panner window must be drawn first because when the main
	# plot is drawn the WCS information is used to overlay the region
	# marker.

	if (SPT_REDRAW(spt,2) != NO && SPT_FINDER(spt) == YES) {
	    gp = spt_gp (spt, 2)
	    call gmsg (gp, "output", "gterm2")
	    call spt_plot (spt, 2)
	    SPT_REDRAW(spt,2) = NO
	}
	if (SPT_REDRAW(spt,1) != NO) {
	    gp = spt_gp (spt, 1)
	    call gmsg (gp, "output", "gterm1")
	    call spt_plot (spt, 1)
	    SPT_REDRAW(spt,1) = NO
	}

	if (i != SPT_WCS(spt)) {
	    gp = spt_gp (spt, i)
	    switch (i) {
	    case 1:
		call gmsg (gp, "output", "gterm1")
	    case 2:
		call gmsg (gp, "output", "gterm2")
	    }
	}
end


# SPT_PLOT -- Plot spectra.
# The GTOOLS procedures are used to allow user adjustment.

procedure spt_plot (spt, type)

pointer	spt		#I SPECTOOL pointer
int	type		#I Plot type

int	i, j, k, nx, ny, nx1, ny1, gstati(), gt_geti()
bool	auto
real	wx1, wx2, wy1, wy2, vx1, vx2, vy1, vy2, ux1, ux2, uy1, uy2
real	z1, z2, step, gt_getr()
double	z
pointer	gp, gt, reg, ptr, sh, rv, un1, un2, spt_gp()
errchk	spt_gp

begin
	reg = SPT_CREG(spt)
	gp = spt_gp (spt, type)
	gt = SPT_GT(spt)

	vx1 = gt_getr (gt, GTXMIN)
	vx2 = gt_getr (gt, GTXMAX)
	vy1 = gt_getr (gt, GTYMIN)
	vy2 = gt_getr (gt, GTYMAX)
	wx1 = MAX_REAL
	wx2 = -MAX_REAL
	wy1 = MAX_REAL
	wy2 = -MAX_REAL
	nx = 0
	ny = 0
	step = 0.
	z = INDEFD

	j = 0
	do k = 1, SPT_NREG(spt) {
	    i = mod (REG_NUM(reg)+k-2,SPT_NREG(spt)) + 1
	    ptr = REG(spt,i)
	    sh = REG_SH(ptr)
	    REG_FLAG(ptr) = 0
	    if (REG_PLOT(ptr) == NOPLOT || sh == NULL)
		next
	    j = j + 1

	    if (type == 1 && ptr == reg) {
		call spt_title (spt, ptr, 1)
		rv = REG_RV(ptr)
		z = REG_REDSHIFT(ptr)
		un1 = UN(sh)
		un2 = RV_UN(rv)
	    }

	    switch (REG_PLOT(ptr)) {
	    case PLOT1, OPLOT:
		call spt_scale1 (spt, ptr, vx1, vx2, vy1, vy2, z1, z2, nx1, ny1)
		nx = nx + nx1
		ny = ny + ny1

		REG_SSCALE(ptr) = 1.
		REG_STEP(ptr) = 0.

		switch (SPT_STACKTYPE(spt)) {
		case STACK_RANGE:
		    if (j == 1)
			ux2 = (z2 - z1)
		case STACK_RANGES:
		    if (j == 1)
			ux2 = z2
		}

	    case STACK:
		call spt_scale1 (spt, ptr, vx1, vx2, vy1, vy2, z1, z2, nx1, ny1)
		nx = nx + nx1
		ny = ny + ny1

		uy1 = REG_SCALE(ptr) / REG_SCALE(reg)
		uy2 = (REG_OFFSET(ptr)-REG_OFFSET(reg)) / REG_SCALE(reg)
		z1 = uy1 * z1 + uy2
		z2 = uy1 * z2 + uy2

		switch (SPT_STACKTYPE(spt)) {
		case STACK_ABS:
		    step = step + SPT_STACKSTEP(spt)
		case STACK_RANGE:
		    if (j == 1)
			ux2 = (z2 - z1)
		    else
			step = step + SPT_STACKSTEP(spt) * ux2
		case STACK_RANGES:
		    if (j > 1)
			step = step + SPT_STACKSTEP(spt) * (ux2 - z1)
		    ux2 = z2
		}

		REG_SSCALE(ptr) = uy1
		REG_STEP(ptr) = uy2 + step
		z1 = z1 + step
		z2 = z2 + step
	    }

	    wx1 = min (wx1, REG_X1(ptr))
	    wx2 = max (wx2, REG_X2(ptr))
	    if (type == 1) {
		wy1 = min (wy1, z1)
		wy2 = max (wy2, z2)
	    } else {
		wy1 = min (wy1, REG_SSCALE(ptr) * REG_Y1(ptr) + REG_STEP(ptr))
		wy2 = max (wy2, REG_SSCALE(ptr) * REG_Y2(ptr) + REG_STEP(ptr))
	    }
	}

	call gclear (gp)

	if (j > 0) {
	    if (type == 1) {
		call gt_reset (gp, gt)
		if (!IS_INDEFD(z) && gstati (gp, G_XDRAWAXES) == 3) {
		    if (IS_INDEFD(SPT_ZHELIO(rv))) {
			call sprintf (SPT_STRING(spt), SPT_SZSTRING,
			    "Vobs (km/s) = %.5g,  Zobs = %.5g\n\n\n")
			    call pargd (z * VLIGHT)
			    call pargd (z)
		    } else {
			call sprintf (SPT_STRING(spt), SPT_SZSTRING,
			    "Vhelio (km/s) = %.5g,  Zhelio = %.5g\n\n\n")
			call pargd ((z + SPT_ZHELIO(rv)) * VLIGHT)
			call pargd (z + SPT_ZHELIO(rv))
		    }
		    call gt_sets (gt, GTCOMMENTS, SPT_STRING(spt))
		}
		vx1 = gt_getr (gt, GTVXMIN); ux1 = vx1
		vx2 = gt_getr (gt, GTVXMAX); ux2 = vx2
		vy1 = gt_getr (gt, GTVYMIN); uy1 = vy1
		vy2 = gt_getr (gt, GTVYMAX); uy2 = vy2

		if (SPT_ZERO(spt) == YES) {
		    wy1 = 0
		    call gt_setr (gt, GTYMIN, INDEF)
		}
		call gseti (gp, G_WCS, 1)
		call gswind (gp, wx1, wx2, wy1, wy2)
		if (nx == 0) {
		    call gt_setr (gt, GTXMIN, INDEF)
		    call gt_setr (gt, GTXMAX, INDEF)
		}
		if (ny == 0) {
		    call gt_setr (gt, GTYMIN, INDEF)
		    call gt_setr (gt, GTYMAX, INDEF)
		}
		call gt_swind (gp, gt)
		if (IS_INDEFD(z) || gstati (gp, G_XDRAWAXES) != 3)
		    call gt_labax (gp, gt)
		else {
		    if (IS_INDEF(vy2))
			call gt_setr (gt, GTVYMAX, 0.80)
		    else
			call gt_setr (gt, GTVYMAX, min (0.80, vy2))
		    call gt_colon ("/drawaxes bottom unchanged", gp, gt, k)
		    call gt_labax (gp, gt)
		    call gt_colon ("/drawaxes both unchanged", gp, gt, k)
		    call ggwind (gp, wx1, wx2, wy1, wy2)
		    call un_ctranr (un1, un2, wx1, vx1, 1)
		    call un_ctranr (un1, un2, wx2, vx2, 1)
		    vx1 = vx1 / (1 + z)
		    vx2 = vx2 / (1 + z)
		    call un_ctranr (un2, un1, vx1, vx1, 1)
		    call un_ctranr (un2, un1, vx2, vx2, 1)
		    call gswind (gp, vx1, vx2, wy1, wy2)
		    call gseti (gp, G_XDRAWAXES, 2)
		    call gseti (gp, G_YDRAWAXES, 0)
		    call gseti (gp, G_DRAWGRID, NO)
		    call glabax (gp, "", "", "")
		    call gswind (gp, wx1, wx2, wy1, wy2)
		    call gctran (gp, wx1, wy1, wx1, wy1, 1, 0)
		    call gctran (gp, wx1, wy1, wx1, wy1, 0, 1)
		}
		call gt_sets (gt, GTCOMMENTS, "")
		call gt_setr (gt, GTVXMIN, ux1)
		call gt_setr (gt, GTVXMAX, ux2)
		call gt_setr (gt, GTVYMIN, uy1)
		call gt_setr (gt, GTVYMAX, uy2)

		# Send GUI information.
		wx1 = gt_getr (gt, GTXMIN)
		wx2 = gt_getr (gt, GTXMAX)
		wy1 = gt_getr (gt, GTYMIN)
		wy2 = gt_getr (gt, GTYMAX)
		auto = IS_INDEF(wx1) && IS_INDEF(wx2) &&
		    IS_INDEF(wy1) && IS_INDEF(wy2)
		call ggview (gp, vx1, vx2, vy1, vy2)
		call ggwind (gp, wx1, wx2, wy1, wy2)
		call gt_sets (gt, GTTYPE, SPT_TYPE(spt))
		call gt_seti (gt, GTCOLOR, SPT_COLOR(spt))
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "%g %g %g %g %g %g %g %g %g %g %g %b")
		    call pargr (vx1)
		    call pargr (vx2)
		    call pargr (vy1)
		    call pargr (vy2)
		    call pargr (wx1)
		    call pargr (wx2)
		    call pargr (wy1)
		    call pargr (wy2)
		    call pargr (SPT_LCLIP(spt))
		    call pargr (SPT_HCLIP(spt))
		    call pargr (gt_getr (gt, GTYBUF))
		    call pargb (auto)
		call gmsg (gp, "wcs", SPT_STRING(spt))
		call spt_colon (spt, ptr, 0., 0., "gtuivalues no")
	    } else {
		if (gt_geti (gt, GTXFLIP) == NO)
		    call gswind (gp, wx1, wx2, INDEF, INDEF)
		else
		    call gswind (gp, wx2, wx1, INDEF, INDEF)
		if (gt_geti (gt, GTYFLIP) == NO)
		    call gswind (gp, INDEF, INDEF, wy1, wy2)
		else
		    call gswind (gp, INDEF, INDEF, wy2, wy1)
		call gseti (gp, G_DRAWTICKS, NO)
		call gsview (gp, 0.05, 0.95, 0.05, 0.95)

		# Send WCS transformation to GUI.
		call ggview (gp, vx1, vx2, vy1, vy2)
		call ggwind (gp, wx1, wx2, wy1, wy2)
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "%g %g %g %g %g %g %g %g")
		    call pargr (vx1)
		    call pargr (vx2)
		    call pargr (vy1)
		    call pargr (vy2)
		    call pargr (wx1)
		    call pargr (wx2)
		    call pargr (wy1)
		    call pargr (wy2)
		call gmsg (gp, "finder_wcs", SPT_STRING(spt))
	    }
	}

	j = 0
	do k = 1, SPT_NREG(spt) {
	    i = mod (REG_NUM(reg)+k-2,SPT_NREG(spt)) + 1
	    ptr = REG(spt,i)
	    sh = REG_SH(ptr)
	    if (REG_PLOT(ptr) == NOPLOT || sh == NULL)
		next
	    j = j + 1
	    if (REG_FLAG(ptr) > 0)
		next
	    REG_FLAG(ptr) = j

	    if (type == 1) {
		call spt_plotreg (spt, ptr)
		call lab_colon (spt, ptr, INDEFD, INDEFD, "plot")
		call mod_colon (spt, ptr, INDEFD, INDEFD, "plot")
	    } else {
		uy1 = REG_SSCALE(ptr)
		uy2 = REG_STEP(ptr)
		call amulkr (Memr[SY(sh)], uy1, SPECT(spt), SN(sh))
		call aaddkr (SPECT(spt), uy2, SPECT(spt), SN(sh))

		call spt_type (spt, ptr, SHDATA)
		call gt_plot (gp, gt, Memr[SX(sh)], SPECT(spt), SN(sh))
	    }
	}
	if (type == 1)
	    call lid_colon (spt, reg, INDEFD, INDEFD, "plot")
	call gflush (gp)
end


procedure spt_plotreg (spt, reg)

pointer	spt			# SPECTOOL pointer
pointer	reg			# Register pointer

pointer	sh

begin
	sh = REG_SH(reg)
	if (sh == NULL || REG_PLOT(reg) == NOPLOT)
	    return

	call spt_plotreg1 (spt, reg, 1, SN(sh), SHSIG, NO)
	call spt_plotreg1 (spt, reg, 1, SN(sh), SHCONT, NO)
	call spt_plotreg1 (spt, reg, 1, SN(sh), SHSKY, NO)
	call spt_plotreg1 (spt, reg, 1, SN(sh), SHRAW, NO)
	call spt_plotreg1 (spt, reg, 1, SN(sh), SHDATA, NO)
end


procedure spt_plotreg1 (spt, reg, x1, x2, spectype, erase)

pointer	spt			# SPECTOOL pointer
pointer	reg			# Register pointer
int	x1, x2			# Pixels to plot
int	spectype		# Spectrum type
int	erase			# Erase?

int	i, j, k, i1, npix, color
real	scale, offset
pointer	gp, gt, sh, sx, sy
bool	streq()

int	types[5]
data	types/SHDATA,SHRAW,SHSKY,SHCONT,SHSIG/

begin
	gp = SPT_GP(spt)
	gt = SPT_GT(spt)
	sh = REG_SH(reg)

	if (sh==NULL || REG_PLOT(reg)==NOPLOT || SPT_PLOT(spt,spectype)==NO)
	    return
	if (SPEC(sh,spectype) == NULL)
	    return

	k = 0
	do i = 1, 5 {
	    j = types[i]
	    if (SPT_PLOT(spt,j)==YES && SPEC(sh,j)!=NULL)
		k = k + 1
	    if (j == spectype)
		break
	}

	i1 = max (1, x1)
	sx = SX(sh) + i1 - 1
	sy = SPEC(sh,spectype) + i1 - 1
	npix = min(SN(sh),x2) - i1 + 1
	if (erase == YES) {
	    color = REG_COLOR(reg,types[k])
	    REG_COLOR(reg,types[k]) = 0
	}

	scale = REG_SSCALE(reg)
	offset = REG_STEP(reg)

	if (spectype == SHSIG && SPT_CTYPE(spt) != SHSIG) {
	    if (streq (REG_TYPE(reg,SHSIG), "vline") ||
		streq (REG_TYPE(reg,SHSIG), "vebar")) {
		call amulkr (Memr[SY(sh)+i1-1], scale, SPECT(spt), npix)
		call aaddkr (SPECT(spt), offset, SPECT(spt), npix)
		call gseti (gp, G_PLCOLOR, REG_COLOR(reg,types[k]))
		if (streq (REG_TYPE(reg,SHSIG), "vline"))
		    j = GM_VLINE
		else
		    j = GM_VEBAR
		    
		do i = 0, npix-1
		    call gmark (gp, Memr[sx+i], Memr[SPT_SPEC(spt)+i],
			j, 1., -2*scale*Memr[sy+i])
	    } else {
		call spt_type (spt, reg, types[k])
		call aaddr (Memr[SY(sh)+i1-1], Memr[sy], SPECT(spt), npix)
		call amulkr (SPECT(spt), scale, SPECT(spt), npix)
		call aaddkr (SPECT(spt), offset, SPECT(spt), npix)
		call gt_plot (gp, gt, Memr[sx], SPECT(spt), npix)
		call asubr (Memr[SY(sh)+i1-1], Memr[sy], SPECT(spt), npix)
		call amulkr (SPECT(spt), scale, SPECT(spt), npix)
		call aaddkr (SPECT(spt), offset, SPECT(spt), npix)
		call gt_plot (gp, gt, Memr[sx], SPECT(spt), npix)
	    }
	} else {
	    call amulkr (Memr[sy], scale, SPECT(spt), npix)
	    call aaddkr (SPECT(spt), offset, SPECT(spt), npix)
	    call spt_type (spt, reg, types[k])
	    call gt_plot (gp, gt, Memr[sx], SPECT(spt), npix)
	}

	if (erase == YES) {
	    REG_COLOR(reg,types[k]) = color
	    call spt_type (spt, reg, types[k])
	}
end


# SPT_TITLE -- Make GTOOLS spectrum title.

procedure spt_title (spt, reg, type)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
int	type			#I Graph type

pointer	sp, str, sh, gt
bool	streq()

begin
	# Do nothing if the spectrum or GTOOLS pointers are NULL.
	sh = REG_SH(reg)
	gt = SPT_GT(spt)
	if (sh == NULL || gt == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	switch (type) {
	case 1:
	    if (streq (SPT_TITLE(spt), "default"))
		call gt_sets (gt, GTTITLE, REG_TITLE(reg))
	    else
		call gt_sets (gt, GTTITLE, SPT_TITLE(spt))

	    if (streq (SPT_XLABEL(spt), "default"))
		call gt_sets (gt, GTXLABEL, LABEL(sh))
	    else
		call gt_sets (gt, GTXLABEL, SPT_XLABEL(spt))
	    if (streq (SPT_YLABEL(spt), "default"))
		call gt_sets (gt, GTYLABEL, FLABEL(sh))
	    else
		call gt_sets (gt, GTYLABEL, SPT_YLABEL(spt))
	    if (streq (SPT_XUNITS(spt), "default"))
		call gt_sets (gt, GTXUNITS, UNITS(sh))
	    else
		call gt_sets (gt, GTXUNITS, SPT_XUNITS(spt))
	    if (streq (SPT_YUNITS(spt), "default"))
		call gt_sets (gt, GTYUNITS, FUNITS(sh))
	    else
		call gt_sets (gt, GTYUNITS, SPT_YUNITS(spt))
	case 3:
	    if (streq (SPT_TITLE(spt), "default")) {
		call sprintf (Memc[str], SZ_LINE, "[%s] %s")
		    call pargstr (IMNAME(sh)]
		    call pargstr (IM_TITLE(IM(sh)))
		call gt_sets (gt, GTTITLE, Memc[str])
	    } else
		call gt_sets (gt, GTTITLE, SPT_TITLE(spt))

	    if (streq (SPT_XLABEL(spt), "default"))
		call gt_sets (gt, GTXLABEL, LABEL(sh))
	    else
		call gt_sets (gt, GTXLABEL, SPT_XLABEL(spt))
	    if (streq (SPT_YLABEL(spt), "default"))
		call gt_sets (gt, GTYLABEL, FLABEL(sh))
	    else
		call gt_sets (gt, GTYLABEL, SPT_YLABEL(spt))
	    if (streq (SPT_XUNITS(spt), "default"))
		call gt_sets (gt, GTXUNITS, UNITS(sh))
	    else
		call gt_sets (gt, GTXUNITS, SPT_XUNITS(spt))
	    if (streq (SPT_YUNITS(spt), "default"))
		call gt_sets (gt, GTYUNITS, "")
	    else
		call gt_sets (gt, GTYUNITS, SPT_YUNITS(spt))
	}

	call sfree (sp)
end


# SPT_TYPE -- Convert SPT type string to GTOOLS parameters.

procedure spt_type (spt, reg, spectype)

pointer	spt			#I Spectool pointer
pointer	reg			# Register pointer
int	spectype		# Spectrum type

int	color
pointer	cur

begin
	cur = SPT_CREG(spt)
	call strcpy (REG_TYPE(reg,spectype), SPT_STRING(spt), SPT_SZSTRING)
	color = REG_COLOR(reg,spectype)

	if (reg != cur && color > 0) {
	    if (SPT_STACKPLOT(spt) == YES) {
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "line%d")
		    #call pargi (mod (REG_NUM(reg)-1,4)+1)
		    call pargi (mod (REG_FLAG(reg)-1,4)+1)
	    }
	    if (SPT_STACKCOL(spt) == YES)
		color = mod (REG_COLOR(cur,spectype)+REG_FLAG(reg)-2,9) + 1
	}

	call gt_sets (SPT_GT(spt), GTTYPE, SPT_STRING(spt))
	call gt_seti (SPT_GT(spt), GTCOLOR, color)
end
