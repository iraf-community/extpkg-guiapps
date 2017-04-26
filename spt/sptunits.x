include	<smw.h>
include	<units.h>
include	<funits.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"lids.h"

# SPT_UNITS -- Change dispersion units.

procedure spt_units (spt, reg, units)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
char	units[ARB]		#I Units

int	i
pointer	gt, sh, ptr

bool	streq()
errchk	shdr_units, shdr_system

begin
	if (reg == NULL || units[1] == EOS || streq (units, SPT_UNITS(spt)))
	    return

	gt = SPT_GT(spt)
	sh = REG_SH(reg)

	call lab_colon (spt, reg, INDEFD, INDEFD, "units logical")
	call lid_colon (spt, reg, INDEFD, INDEFD, "units logical yes")
	call ll_colon (spt, reg, INDEFD, INDEFD, "units logical")
	call mod_colon (spt, reg, INDEFD, INDEFD, "units logical")
	call spt_plotcolon (spt, reg, "units logical")
	call spt_eqwidth (spt, reg, INDEFR, INDEFR, "units logical")
	call spt_stat (spt, reg, "units logical",
	    INDEFR, INDEFR, INDEFR, INDEFR)

	# Change spectrum to new units.
	if (streq (units, "pixels")) {
	    do i = 1, SPT_NREG(spt) {
		ptr = REG(spt,i)
		sh = REG_SH(ptr)
		call shdr_system (sh, "physical")
	    }
	} else {
	    if (streq (SPT_UNITS(spt), "pixels")) {
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    sh = REG_SH(ptr)
		    call shdr_system (sh, "world")
		}
	    }
	    do i = 1, SPT_NREG(spt) {
		ptr = REG(spt,i)
		sh = REG_SH(ptr)
		call shdr_units (sh, units)
	    }
	}
	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    sh = REG_SH(ptr)
	    call alimr (Memr[SX(sh)], SN(sh), REG_X1(ptr), REG_X2(ptr))
	}

	call lab_colon (spt, reg, INDEFD, INDEFD, "units world")
	call lid_colon (spt, reg, INDEFD, INDEFD, "units world yes")
	call ll_colon (spt, reg, INDEFD, INDEFD, "units world")
	call mod_colon (spt, reg, INDEFD, INDEFD, "units world")
	call spt_plotcolon (spt, reg, "units world")
	call spt_eqwidth (spt, reg, INDEFR, INDEFR, "units world")
	call spt_stat (spt, reg, "units world", INDEFR, INDEFR, INDEFR, INDEFR)

	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    call mod_colon (spt, ptr, INDEFD, INDEFD, "remeasure")
	}

	call lid_list (spt, reg, NULL)

	call strcpy (units, SPT_UNITS(spt), SPT_SZLINE)
	SPT_REDRAW(spt,1) = YES
	SPT_REDRAW(spt,2) = YES
end


# SPT_FUNITS -- Change flux units.

procedure spt_funits (spt, reg, funits)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
char	funits[ARB]		#I Flux units

int	i, j, k
pointer	gt, sh, ptr

int	btoi()
bool	streq()
errchk	fun_changer

begin
	if (reg == NULL || funits[1] == EOS || streq (funits, SPT_FUNITS(spt)))
	    return

	gt = SPT_GT(spt)

	call sprintf (SPT_STRING(spt), SPT_SZLINE, "funits %s")
	    if (streq (funits, "default"))
		call pargstr (FUN_USER(FUNIM(REG_SH(reg))))
	    else
		call pargstr (funits)
	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    call lab_colon (spt, ptr, INDEFD, INDEFD, SPT_STRING(spt))
	}

	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    sh = REG_SH(ptr)
	    do j = SHDATA, SHCONT
		if (SPEC(sh,j) != NULL)
		    k = j
	    do j = SHDATA, SHCONT {
		if (SPEC(sh,j) == NULL)
		    next
		if (streq (funits, "default"))
		    call fun_changer (FUN(sh), FUN_USER(FUNIM(REG_SH(reg))),
			UN(sh), Memr[SX(sh)], Memr[SPEC(sh,j)], SN(sh),
			btoi(j==k))
		else
		    call fun_changer (FUN(sh), funits, UN(sh), Memr[SX(sh)],
			Memr[SPEC(sh,j)], SN(sh), btoi(j==k))
	    }
	    call spt_scale (spt, ptr)
	    call strcpy (FUN_LABEL(FUN(sh)), FLABEL(sh), LEN_SHDRS)
	    call strcpy (FUN_UNITS(FUN(sh)), FUNITS(sh), LEN_SHDRS)
	}
	call strcpy (funits, SPT_FUNITS(spt), SPT_SZLINE)
	call gt_setr (gt, GTYMIN, INDEF)
	call gt_setr (gt, GTYMAX, INDEF)
	if (FUN_MOD(FUN(sh)) == FUN_MAG)
	    call gt_seti (gt, GTYFLIP, YES)

	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    call mod_colon (spt, ptr, INDEFD, INDEFD, "remeasure")
	    call spt_eqwidth (spt, ptr, INDEFR, INDEFR, "remeasure")
	    if (ptr == reg)
		call spt_stat (spt, ptr, "remeasure",
		    INDEFR, INDEFR, INDEFR, INDEFR)
	}

	call lid_list (spt, reg, NULL)

	SPT_REDRAW(spt,1) = YES
	SPT_REDRAW(spt,2) = YES
end


# SPT_RUNITS -- Change units for plot limits and register data.
# This does not change the spectrum data.

procedure spt_runits (spt, reg, type, doref)

pointer	spt			# SPECTOOL pointer
pointer	reg			# REGISTER pointer
int	type			# (1=to pixel, 2=to world)
int	doref			# Change reference units?

pointer	gt, sh
real	rmin, rmax, gt_getr()
int	gt_geti()
double	shdr_lw(), shdr_wl()

begin
	if (reg == NULL)
	    return

	gt = SPT_GT(spt)
	sh = REG_SH(reg)

	if (sh == NULL)
	    return

	switch (type) {
	case 1:
	    rmin = gt_getr (gt, GTXMIN)
	    if (!IS_INDEF(rmin)) {
		rmin = shdr_wl (sh, double(rmin))
		call gt_setr (gt, GTXMIN, rmin)
	    }
	    rmax = gt_getr (gt, GTXMAX)
	    if (!IS_INDEF(rmax)) {
		rmax = shdr_wl (sh, double(rmax))
		if (!IS_INDEF(rmin) &&
		    ((gt_geti (gt, GTXFLIP) == NO && rmin > rmax) ||
		    (gt_geti (gt, GTXFLIP) == YES && rmax > rmin))) {
		    call gt_setr (gt, GTXMIN, rmax)
		    call gt_setr (gt, GTXMAX, rmin)
		} else
		    call gt_setr (gt, GTXMAX, rmax)
	    }

	    if (doref == NO)
		call lid_colon (spt, reg, INDEFD, INDEFD, "units logical no")
	    else
		call lid_colon (spt, reg, INDEFD, INDEFD, "units logical yes")

	case 2:
	    rmin = gt_getr (gt, GTXMIN)
	    if (!IS_INDEF(rmin)) {
		rmin = shdr_lw (sh, double(rmin))
		call gt_setr (gt, GTXMIN, rmin)
	    }
	    rmax = gt_getr (gt, GTXMAX)
	    if (!IS_INDEF(rmax)) {
		rmax = shdr_lw (sh, double(rmax))
		if (!IS_INDEF(rmin) &&
		    ((gt_geti (gt, GTXFLIP) == NO && rmin > rmax) ||
		    (gt_geti (gt, GTXFLIP) == YES && rmax > rmin))) {
		    call gt_setr (gt, GTXMIN, rmax)
		    call gt_setr (gt, GTXMAX, rmin)
		} else
		    call gt_setr (gt, GTXMAX, rmax)
	    }

	    if (doref == NO)
		call lid_colon (spt, reg, INDEFD, INDEFD, "units world no")
	    else
		call lid_colon (spt, reg, INDEFD, INDEFD, "units world yes")
	    call lid_list (spt, reg, NULL)
	}
end
