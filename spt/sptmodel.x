include	<error.h>
include	<gset.h>
include	"spectool.h"
include	"lids.h"


# List of colon commands.
define	COLONCMDS "|open|close|modpars|plotpars|model|fit|plot|draw|subtract\
		   |profile|units|remeasure|"

define	OPEN		1
define	CLOSE		2
define	MODPARS		3	# Set parameters
define	PLOTPARS	4	# Set plot parameters
define	MODEL		5	# Set model
define	FIT		6	# Fit model
define	PLOT		7	# Plot models
define	DRAW		8	# Plot models
define	SUB		9	# Add/subtract from spectrum
define	PROF		10	# Set profile type
define	UNIT		11	# Units
define	REMEASURE	12	# Remeasure


# MOD_COLON -- Model colon command interpreter.

procedure mod_colon (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
double	wx, wy			#I Cursor coordinate
char	cmd[ARB]		#I Command

int	i, j, k, n, ncmd, nscn, item, subtract
int	draw, pdraw, pcol, sdraw, scol, cdraw, ccol
real	x1, x2, wr, wi
double	low, up, x, y, a, b, g, l
pointer	sp, str, lids, lid, sh

bool	clgetb(), streq()
int	clgeti(), clgwrd(), btoi(), strdic(), nscan()
double	clgetd(), shdr_lw(), shdr_wl()
errchk	spt_deblend, spt_subblend, spt_plotblend

define	err_		10
define	done_		20

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	if (reg != NULL)
	    lids = REG_LIDS(reg)
	else
	    lids = NULL

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, COLONCMDS)

	switch (ncmd) {
	case OPEN:
	    call clgstr ("profile", SPT_DPROF(spt), LID_SZPROF)
	    SPT_DLOW(spt) = clgetd ("lower")
	    SPT_DUP(spt) = clgetd ("upper")

	    SPT_MODPARS(spt,1) = btoi (clgetb ("fitpos"))
	    SPT_MODPARS(spt,2) = btoi (clgetb ("fitint"))
	    SPT_MODPARS(spt,3) = btoi (clgetb ("fitgfwhm"))
	    SPT_MODPARS(spt,4) = btoi (clgetb ("fitlfwhm"))
	    SPT_MODPARS(spt,5) = btoi (clgetb ("fitback"))
	    SPT_MODPARS(spt,6) = btoi (clgetb ("relpos"))
	    SPT_MODPARS(spt,7) = btoi (clgetb ("relint"))
	    SPT_MODPARS(spt,8) = btoi (clgetb ("relgfwhm"))
	    SPT_MODPARS(spt,9) = btoi (clgetb ("rellfwhm"))
	    SPT_MODPARS(spt,10) = btoi (clgetb ("eqgfwhm"))
	    SPT_MODPARS(spt,11) = btoi (clgetb ("eqlfwhm"))

	    SPT_MODPLOT(spt) = btoi (clgetb ("modplot"))
	    SPT_MODPDRAW(spt) = btoi (clgetb ("modpdraw"))
	    SPT_MODPCOL(spt) = clgwrd ("modpcolor",Memc[str],SZ_LINE,COLORS) - 1
	    SPT_MODSDRAW(spt) = btoi (clgetb ("modsdraw"))
	    SPT_MODSCOL(spt) = clgwrd ("modscolor",Memc[str],SZ_LINE,COLORS) - 1
	    SPT_MODCDRAW(spt) = btoi (clgetb ("modcdraw"))
	    SPT_MODCCOL(spt) = clgwrd ("modccolor",Memc[str],SZ_LINE,COLORS) - 1

	    #SPT_MODNSUB(spt) = 3
	    SPT_MODNSUB(spt) = clgeti ("modnsub")

	    # Send fitting parameters.
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %d %d %d %d %d %d %d %d %d %d")
		do i = 1, 11
		    call pargi (SPT_MODPARS(spt,i))
	    call gmsg (SPT_GP(spt), "modpars", SPT_STRING(spt))

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "models %d")
		call pargi (SPT_MODPLOT(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))

	    call mod_values (spt, reg, NULL)

	case CLOSE:
	    call clpstr ("profile", SPT_DPROF(spt))
	    call clputd ("lower", SPT_DLOW(spt))
	    call clputd ("upper", SPT_DUP(spt))

	    call clputb ("fitpos", SPT_MODPARS(spt,1)==YES)
	    call clputb ("fitint", SPT_MODPARS(spt,2)==YES)
	    call clputb ("fitgfwhm", SPT_MODPARS(spt,3)==YES)
	    call clputb ("fitlfwhm", SPT_MODPARS(spt,4)==YES)
	    call clputb ("fitback", SPT_MODPARS(spt,5)==YES)
	    call clputb ("relpos", SPT_MODPARS(spt,6)==YES)
	    call clputb ("relint", SPT_MODPARS(spt,7)==YES)
	    call clputb ("relgfwhm", SPT_MODPARS(spt,8)==YES)
	    call clputb ("rellfwhm", SPT_MODPARS(spt,9)==YES)
	    call clputb ("eqgfwhm", SPT_MODPARS(spt,10)==YES)
	    call clputb ("eqlfwhm", SPT_MODPARS(spt,11)==YES)
	    call clputb ("modplot", SPT_MODPLOT(spt)==YES)
	    call clputb ("modpdraw", SPT_MODPDRAW(spt)==YES)
	    call clputb ("modsdraw", SPT_MODSDRAW(spt)==YES)
	    call clputb ("modcdraw", SPT_MODCDRAW(spt)==YES)
	    call spt_dic (COLORS, SPT_MODPCOL(spt)+1, Memc[str], SZ_LINE)
	    call clpstr ("modpcolor", Memc[str])
	    call spt_dic (COLORS, SPT_MODSCOL(spt)+1, Memc[str], SZ_LINE)
	    call clpstr ("modscolor", Memc[str])
	    call spt_dic (COLORS, SPT_MODCCOL(spt)+1, Memc[str], SZ_LINE)
	    call clpstr ("modccolor", Memc[str])

	    call clputi ("modnsub", SPT_MODNSUB(spt))

	case MODPARS:
	    call gargi (SPT_MODPARS(spt,1))
	    call gargi (SPT_MODPARS(spt,2))
	    call gargi (SPT_MODPARS(spt,3))
	    call gargi (SPT_MODPARS(spt,4))
	    call gargi (SPT_MODPARS(spt,5))
	    call gargi (SPT_MODPARS(spt,6))
	    call gargi (SPT_MODPARS(spt,7))
	    call gargi (SPT_MODPARS(spt,8))
	    call gargi (SPT_MODPARS(spt,9))
	    call gargi (SPT_MODPARS(spt,10))
	    call gargi (SPT_MODPARS(spt,11))

	    # Send fitting parameters.
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %d %d %d %d %d %d %d %d %d %d")
		do i = 1, 11
		    call pargi (SPT_MODPARS(spt,i))
	    call gmsg (SPT_GP(spt), "modpars", SPT_STRING(spt))

	case MODEL: # model item prof x y g l a b
	    call gargi (item)
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargd (x)
	    call gargd (y)
	    call gargd (g)
	    call gargd (l)
	    call gargd (a)
	    call gargd (b)

	    # Set defaults.
	    nscn = nscan()
	    if (nscn > 2)
		call strcpy (Memc[str], SPT_DPROF(spt), LID_SZPROF)

	    call lid_item (spt, reg, item, lid)
	    if (lid == NULL) {
		call lid_list (spt, reg, NULL)
		goto err_
	    }

	    call strcpy (Memc[str], MOD_PROF(lid), LID_SZPROF)
	    if (nscn < 9) {
		call lid_list (spt, reg, lid)
		goto done_
	    }

	    call mod_erase1 (spt, reg, lid)

	    call strcpy (Memc[str], MOD_PROF(lid), LID_SZPROF)
	    MOD_TYPE(lid) = strdic (Memc[str], Memc[str], SZ_LINE, PTYPES)
	    MOD_A(lid) = a
	    MOD_B(lid) = b
	    MOD_X(lid) = x
	    MOD_Y(lid) = y
	    MOD_G(lid) = g
	    MOD_L(lid) = l
	    switch (MOD_TYPE(lid)) {
	    case GAUSS:
		if (MOD_G(lid) <= 0.)
		    MOD_G(lid) = MOD_L(lid)
		MOD_L(lid) = 0.
		MOD_F(lid) = 1.064467 * MOD_Y(lid) * MOD_G(lid)
	    case LORENTZ:
		if (MOD_L(lid) <= 0.)
		    MOD_L(lid) = MOD_G(lid)
		MOD_G(lid) = 0.
		MOD_F(lid) = 1.570796 * MOD_Y(lid) * MOD_L(lid)
	    case VOIGT:
		if (MOD_G(lid) <= 0.)
		    MOD_G(lid) = 0.1 * MOD_L(lid)
		if (MOD_L(lid) <= 0.)
		    MOD_L(lid) = 0.1 * MOD_G(lid)
		if (MOD_G(lid) > 0.) {
		    call voigt (0., real(0.832555*MOD_L(lid)/MOD_G(lid)),
			wr, wi)
		    if (wr == 0.)
			call error (1, "Voigt fit failed")
		    MOD_F(lid) = 1.064467 * MOD_Y(lid) * MOD_G(lid) / wr
		}
	    }
	    if (MOD_A(lid) > 0.)
		MOD_E(lid) = -MOD_F(lid) / MOD_A(lid)
	    else
		MOD_E(lid) = INDEFD

	    if (MOD_G(lid) > 0. || MOD_L(lid) > 0.)
		call mod_plot1 (spt, reg, lid)
	    call lid_list (spt, reg, lid)

	case PLOTPARS: # plotpars item draw pdraw pcol sdraw scol cdraw ccol
	    call gargi (item)
	    call gargi (draw)
	    call gargi (pdraw)
	    call gargi (pcol)
	    call gargi (sdraw)
	    call gargi (scol)
	    call gargi (cdraw)
	    call gargi (ccol)

	    nscn = nscan()
	    if (nscn < 2)
		item = -1
	    if (nscn < 3)
		draw = 2
	    if (nscn < 4)
		pdraw = SPT_MODPDRAW(spt)
	    if (nscn < 5)
		pcol = SPT_MODPCOL(spt)
	    if (nscn < 6)
		sdraw = SPT_MODSDRAW(spt)
	    if (nscn < 7)
		scol = SPT_MODSCOL(spt)
	    if (nscn < 8)
		cdraw = SPT_MODCDRAW(spt)
	    if (nscn < 9)
		ccol = SPT_MODCCOL(spt)

	    SPT_MODPDRAW(spt) = pdraw
	    SPT_MODPCOL(spt) = pcol
	    SPT_MODSDRAW(spt) = sdraw
	    SPT_MODSCOL(spt) = scol
	    SPT_MODCDRAW(spt) = cdraw
	    SPT_MODCCOL(spt) = ccol

	    if (item > 0) { 
		call lid_item (spt, reg, item, lid)
		if (lid != NULL) {
		    call mod_erase1 (spt, reg, lid)

		    MOD_PDRAW(lid) = pdraw
		    MOD_PCOL(lid) = pcol
		    MOD_SDRAW(lid) = sdraw
		    MOD_SCOL(lid) = scol
		    MOD_CDRAW(lid) = cdraw
		    MOD_CCOL(lid) = ccol

		    call mod_plot1 (spt, reg, lid)
		}
		call lid_list (spt, reg, lid)
	    } else if (item == -1 && lids != NULL) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call mod_erase1 (spt, reg, lid)

		    MOD_PDRAW(lid) = pdraw
		    MOD_PCOL(lid) = pcol
		    MOD_SDRAW(lid) = sdraw
		    MOD_SCOL(lid) = scol
		    MOD_CDRAW(lid) = cdraw
		    MOD_CCOL(lid) = ccol

		    call mod_plot1 (spt, reg, lid)
		}
		call lid_list (spt, reg, NULL)
	    }


	case FIT: # fit item
	    call gargi (item)
	    if (nscan() == 1)
		item = -1

	    if (lids == NULL)
		goto done_
	    if (LID_NLINES(lids) < 1 || item == 0)
		goto done_

	    if (item == -1) {
		for (i=1; i<=LID_NLINES(lids); i=i+1) {
		    lid = LID_LINES(lids,i)
		    if (MOD_SUB(lid) == NO)
			call mod_erase1 (spt, reg, lid)
		}
		for (i=1; i<=LID_NLINES(lids); i=i+1) {
		    do j = i, LID_NLINES(lids) {
			lid = LID_LINES(lids,j)
			x1 = LID_X(lid) + LID_LOW(lid)
			x2 = LID_X(lid) + LID_UP(lid)
			if (MOD_SUB(lid) == NO) {
			    MOD_X1(lid) = x1
			    MOD_X2(lid) = x2
			    MOD_TYPE(lid) = strdic (MOD_PROF(lid), Memc[str],
				SZ_LINE, PTYPES)
			    if (MOD_FIT(lid) == NO) {
				MOD_X(lid) = LID_X(lid)
				MOD_Y(lid) = INDEFD
				MOD_G(lid) = INDEFD
				MOD_L(lid) = INDEFD
				MOD_A(lid) = INDEFD
				MOD_B(lid) = INDEFD
			    }
			}

			if (j == LID_NLINES(lids))
			    break
			lid = LID_LINES(lids,j+1)
			x1 = LID_X(lid) + LID_LOW(lid)
			if (x2 < x1)
			    break
		    }
		    call spt_deblend (spt, reg, LID_LINES(lids,i), j-i+1, 2)
		    do k = i, j {
			lid = LID_LINES(lids,k)
			if (MOD_SUB(lid) == NO)
			    call mod_plot1 (spt, reg, lid)
		    }
		    i = j
		}
	    } else {
		call lid_item (spt, reg, item, lid)
		if (lid == NULL)
		    goto err_
		if (MOD_SUB(lid) == YES)
		    goto done_

		do i = item, 1, -1 {
		    lid = LID_LINES(lids,i)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (i == 1)
			break
		    lid = LID_LINES(lids,i-1)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (x2 < x1)
			break
		}
		do j = item, LID_NLINES(lids) {
		    lid = LID_LINES(lids,j)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (j == LID_NLINES(lids))
			break
		    lid = LID_LINES(lids,j+1)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    if (x2 < x1)
			break
		}
		do k = i, j {
		    lid = LID_LINES(lids,k)
		    if (MOD_SUB(lid) == NO)
			call mod_erase1 (spt, reg, lid)
		}

		do i = item, 1, -1 {
		    lid = LID_LINES(lids,i)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (MOD_SUB(lid) == NO) {
			MOD_X1(lid) = x1
			MOD_X2(lid) = x2
			MOD_TYPE(lid) = strdic (MOD_PROF(lid), Memc[str],
			    SZ_LINE, PTYPES)
			if (MOD_FIT(lid) == NO) {
			    MOD_X(lid) = LID_X(lid)
			    MOD_Y(lid) = INDEFD
			    MOD_G(lid) = INDEFD
			    MOD_L(lid) = INDEFD
			    MOD_A(lid) = INDEFD
			    MOD_B(lid) = INDEFD
			}
		    }

		    if (i == 1)
			break
		    lid = LID_LINES(lids,i-1)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (x2 < x1)
			break
		}
		do j = item, LID_NLINES(lids) {
		    lid = LID_LINES(lids,j)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (MOD_SUB(lid) == NO) {
			MOD_X1(lid) = x1
			MOD_X2(lid) = x2
			MOD_TYPE(lid) = strdic (MOD_PROF(lid), Memc[str],
			    SZ_LINE, PTYPES)
			if (MOD_FIT(lid) == NO) {
			    MOD_X(lid) = LID_X(lid)
			    MOD_Y(lid) = INDEFD
			    MOD_G(lid) = INDEFD
			    MOD_L(lid) = INDEFD
			    MOD_A(lid) = INDEFD
			    MOD_B(lid) = INDEFD
			}
		    }

		    if (j == LID_NLINES(lids))
			break
		    lid = LID_LINES(lids,j+1)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    if (x2 < x1)
			break
		}
		call spt_deblend (spt, reg, LID_LINES(lids,i), j-i+1, 2)
		do k = i, j {
		    lid = LID_LINES(lids,k)
		    if (MOD_SUB(lid) == NO)
			call mod_plot1 (spt, reg, lid)
		}
	    }

	    call lid_list (spt, reg, lid)

	case REMEASURE: # remeasure
	    if (lids == NULL)
		goto done_
	    if (LID_NLINES(lids) < 1)
		goto done_

	    for (i=1; i<=LID_NLINES(lids); i=i+1) {
		lid = LID_LINES(lids,i)
		if (MOD_SUB(lid) == NO)
		    call mod_erase1 (spt, reg, lid)
	    }
	    for (i=1; i<=LID_NLINES(lids); i=j+1) {
		n = 0
		do j = i, LID_NLINES(lids) {
		    lid = LID_LINES(lids,j)
		    if (MOD_FIT(lid) == NO) {
			if (j == i || j == LID_NLINES(lids))
			    break
			next
		    }
		    x1 = LID_X(lid) + LID_LOW(lid)
		    x2 = LID_X(lid) + LID_UP(lid)
		    if (MOD_SUB(lid) == NO) {
			MOD_X1(lid) = x1
			MOD_X2(lid) = x2
			MOD_TYPE(lid) = strdic (MOD_PROF(lid), Memc[str],
			    SZ_LINE, PTYPES)
			if (MOD_FIT(lid) == NO) {
			    MOD_X(lid) = LID_X(lid)
			    MOD_Y(lid) = INDEFD
			    MOD_G(lid) = INDEFD
			    MOD_L(lid) = INDEFD
			    MOD_A(lid) = INDEFD
			    MOD_B(lid) = INDEFD
			}
		    }
		    n = n + 1

		    if (j == LID_NLINES(lids))
			break
		    lid = LID_LINES(lids,j+1)
		    x1 = LID_X(lid) + LID_LOW(lid)
		    if (x2 < x1)
			break
		}
		if (n > 0)
		    call spt_deblend (spt, reg, LID_LINES(lids,i), j-i+1, 2)
	    }

	case PLOT: # plot
	    call mod_plot (spt, reg)

	case DRAW: # draw [item draw]
	    call gargi (item)
	    call gargi (draw)

	    nscn = nscan()
	    if (nscn < 2)
		item = -1
	    if (nscn < 3)
		draw = 2

	    if (item > 0) {
		call lid_item (spt, reg, item, lid)
		call mod_erase1 (spt, reg, lid)
		if (draw == 2)
		    MOD_DRAW(lid) = btoi (MOD_DRAW(lid)==NO)
		else
		    MOD_DRAW(lid) = draw
		call mod_plot1 (spt, reg, lid)
		call lid_list (spt, reg, lid)
	    } else if (item == -1 && lids != NULL) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call mod_erase1 (spt, reg, lid)
		    if (draw == 2)
			MOD_DRAW(lid) = btoi (MOD_DRAW(lid)==NO)
		    else
			MOD_DRAW(lid) = draw
		    call mod_plot1 (spt, reg, lid)
		}
		call lid_list (spt, reg, NULL)
	    }

	case SUB: # subtract [item subtract]
	    call gargi (item)
	    call gargi (subtract)

	    nscn = nscan()
	    if (nscn < 2)
		item = -1
	    if (nscn < 3)
		subtract = 2

	    if (item > 0) {
		call lid_item (spt, reg, item, lid)
		if (subtract == 2)
		    j = btoi (MOD_SUB(lid)==NO)
		else
		    j = subtract
		call spt_subblend (spt, reg, lid, j)
		call lid_list (spt, reg, lid)
	    } else if (item == -1 && lids != NULL) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    if (subtract == 2)
			j = btoi (MOD_SUB(lid)==NO)
		    else
			j = subtract
		    call spt_subblend (spt, reg, lid, j)
		}
		call lid_list (spt, reg, NULL)
	    }

	case PROF: # profile <value>
	    call gargwrd (Memc[str], SZ_LINE)
	    if (nscan() == 2) {
		call lid_nearest (spt, reg, wx, wy, lid)
		if (lid != NULL) {
		    call strcpy (Memc[str], MOD_PROF(lid), LID_SZPROF)
		    call lid_list (spt, reg, lid)
		}
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
		    if (MOD_FIT(lid) == NO)
			next

		    low = MOD_X1(lid)
		    up = MOD_X2(lid)
		    MOD_X(lid) = shdr_wl (sh, MOD_X(lid))
		    MOD_X1(lid) = shdr_wl (sh, MOD_X1(lid))
		    MOD_X2(lid) = shdr_wl (sh, MOD_X2(lid))
		    a = (up - low) / (MOD_X2(lid) - MOD_X1(lid))
		    MOD_B(lid) = MOD_B(lid) * a
		    MOD_G(lid) = MOD_G(lid) / abs(a)
		    MOD_L(lid) = MOD_L(lid) / abs(a)
		    MOD_F(lid) = MOD_F(lid) / abs(a)
		    if (!IS_INDEFD(MOD_E(lid)))
			MOD_E(lid) = MOD_E(lid) / abs(a)
		}
	    } else {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    if (MOD_FIT(lid) == NO)
			next

		    low = MOD_X1(lid)
		    up = MOD_X2(lid)
		    MOD_X(lid) = shdr_lw (sh, MOD_X(lid))
		    MOD_X1(lid) = shdr_lw (sh, MOD_X1(lid))
		    MOD_X2(lid) = shdr_lw (sh, MOD_X2(lid))
		    a = (MOD_X2(lid) - MOD_X1(lid)) / (up - low)
		    MOD_B(lid) = MOD_B(lid) / a
		    MOD_G(lid) = MOD_G(lid) * abs(a)
		    MOD_L(lid) = MOD_L(lid) * abs(a)
		    MOD_F(lid) = MOD_F(lid) * abs(a)
		    if (!IS_INDEFD(MOD_E(lid)))
			MOD_E(lid) = MOD_E(lid) * abs(a)
		}
	    }

	default: # error or unknown command
err_	    call sprintf (Memc[str], SZ_LINE,
		"Error in colon command: %g %g model %s")
		call pargd (wx)
		call pargd (wy)
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

done_
	call sfree (sp)
end


procedure mod_plot (spt, reg)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum register

int	i
pointer	lids

begin
	if (SPT_MODPLOT(spt) == NO || reg == NULL)
	    return
	if (REG_MODPLOT(reg) == NO || REG_LIDS(reg) == NULL)
	    return

	lids = REG_LIDS(reg)
	do i = 1, LID_NLINES(lids)
	    call mod_plot1 (spt, reg, LID_LINES(lids,i))
end


procedure mod_plot1 (spt, reg, lid)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum
pointer	lid		#I Line

begin
	if (SPT_MODPLOT(spt) == NO || reg == NULL || lid == NULL)
	    return
	if (REG_MODPLOT(reg) == NO || MOD_DRAW(lid) == NO || MOD_FIT(lid) == NO)
	    return

	call spt_plotblend (spt, reg, lid)
end


procedure mod_erase1 (spt, reg, lid)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum
pointer	lid		#I Line

int	i, j, k

begin
	if (SPT_MODPLOT(spt) == NO || reg == NULL || lid == NULL)
	    return
	if (REG_MODPLOT(reg) == NO || MOD_DRAW(lid) == NO || MOD_FIT(lid) == NO)
	    return

	i = MOD_PCOL(lid)
	j = MOD_SCOL(lid)
	k = MOD_CCOL(lid)
	MOD_PCOL(lid) = 0
	MOD_SCOL(lid) = 0
	MOD_CCOL(lid) = 0
	call spt_plotblend (spt, reg, lid)
	MOD_PCOL(lid) = i
	MOD_SCOL(lid) = j
	MOD_CCOL(lid) = k
end


procedure mod_values (spt, reg, lid)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum
pointer	lid		#I Line

int	fit

begin
	fit = NO
	if (lid != NULL)
	    fit = MOD_FIT(lid)

	if (fit == YES) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %.8g %.8g %s %.8g %.8g %.8g %.8g %.8g %8g %.8g %.8g")
		call pargi (MOD_SUB(lid))
		call pargd (MOD_X1(lid))
		call pargd (MOD_X2(lid))
		call pargstr (MOD_PROF(lid))
		call pargd (MOD_X(lid))
		call pargd (MOD_Y(lid))
		call pargd (MOD_G(lid))
		call pargd (MOD_L(lid))
		call pargd (MOD_A(lid))
		call pargd (MOD_B(lid))
		call pargd (MOD_F(lid))
		call pargd (MOD_E(lid))
	} else if (lid != NULL) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"0 \"\" \"\" %s \"\" \"\" \"\" \"\" \"\" \"\" \"\" \"\"")
		call pargstr (MOD_PROF(lid))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"0 \"\" \"\" %s \"\" \"\" \"\" \"\" \"\" \"\" \"\" \"\"")
		call pargstr (SPT_DPROF(spt))
	}
	call gmsg (SPT_GP(spt), "modvalues", SPT_STRING(spt))

	if (lid != NULL) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %d %d %d %d %d %d")
		call pargi (MOD_DRAW(lid))
		call pargi (MOD_PDRAW(lid))
		call pargi (MOD_PCOL(lid))
		call pargi (MOD_SDRAW(lid))
		call pargi (MOD_SCOL(lid))
		call pargi (MOD_CDRAW(lid))
		call pargi (MOD_CCOL(lid))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %d %d %d %d %d %d")
		call pargi (SPT_MODPLOT(spt))
		call pargi (SPT_MODPDRAW(spt))
		call pargi (SPT_MODPCOL(spt))
		call pargi (SPT_MODSDRAW(spt))
		call pargi (SPT_MODSCOL(spt))
		call pargi (SPT_MODCDRAW(spt))
		call pargi (SPT_MODCCOL(spt))
	}
	call gmsg (SPT_GP(spt), "modplot", SPT_STRING(spt))
end
