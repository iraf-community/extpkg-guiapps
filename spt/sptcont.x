include	<smw.h>
include	<funits.h>
include	<pkg/gtools.h>
include	"spectool.h"

define	CMDS	"|open|close|smooth|icfit|divide|subtract|"
define	OPEN		1
define	CLOSE		2
define	SMOOTH		3	# Smooth
define	ICFIT		4	# Curve fit
define	DIVIDE		5	# Divide by continuum
define	SUBTRACT	6	# Subtract continuum


# SPT_CONT -- Continuum operations.

procedure spt_cont (spt, reg1, stype1, reg2, stype2, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg1			#I Continuum register pointer
int	stype1			#I Continuum spectrum type
pointer	reg2			#I Input/output register pointer
int	stype2			#I Input/output spectrum type
char	cmd[ARB]		#I Command

int	ncmd, sn
pointer	sh, sc

int	strdic()
pointer	fun_open()
errchk	spt_smooth, spt_icfit, spt_edit, spt_scale
errchk	spt_shcopy, fun_open, fun_copy

real	errval, spt_errfcn()
common	/spectool/ errval
extern	spt_errfcn()

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    ;

	case CLOSE: # close
	    ;

	case SMOOTH:
	    call gargstr (SPT_STRING(spt), SPT_SZSTRING)
	    call spt_smooth (spt, reg2, stype2, reg1, stype1,
		SPT_STRING(spt))

	case ICFIT:
	    call gargstr (SPT_STRING(spt), SPT_SZSTRING)
	    call spt_icfit (spt, reg2, stype2, reg1, stype1,
		SPT_STRING(spt))

	case DIVIDE:
	    if (reg1 == NULL || reg2 == NULL)
		return
	    if (REG_SH(reg1) == NULL || REG_SH(reg2) == NULL)
		return
	    if (SPEC(REG_SH(reg1),stype1) == NULL)
		call error (1, "No continuum defined")

	    if (REG_SHSAVE(reg2) == NULL)
		call spt_shcopy (REG_SH(reg2), REG_SHSAVE(reg2), YES)
	    else
		call spt_shcopy (REG_SH(reg2), REG_SHBAK(reg2), YES)

	    sc = SPEC(REG_SH(reg1),stype1)
	    sh = REG_SH(reg2)
	    sn = min (SN(sh), SN(REG_SH(reg1)))
	    errval = 1.
	    if (SY(sh) != NULL && SY(sh) != sc)
		call advzr (Memr[SY(sh)], Memr[sc], Memr[SY(sh)], sn,
		    spt_errfcn)
	    if (SR(sh) != NULL && SR(sh) != sc)
		call advzr (Memr[SR(sh)], Memr[sc], Memr[SR(sh)], sn,
		    spt_errfcn)
	    if (SS(sh) != NULL && SS(sh) != sc)
		call advzr (Memr[SS(sh)], Memr[sc], Memr[SS(sh)], sn,
		    spt_errfcn)
	    if (SE(sh) != NULL && SE(sh) != sc)
		call advzr (Memr[SE(sh)], Memr[sc], Memr[SE(sh)], sn,
		    spt_errfcn)
	    if (SC(sh) != NULL && SC(sh) != sc)
		call advzr (Memr[SC(sh)], Memr[sc], Memr[SC(sh)], sn,
		    spt_errfcn)
	    if (SPEC(sh,stype1) == sc)
		call advzr (Memr[SPEC(sh,stype1)], Memr[sc],
		    Memr[SPEC(sh,stype1)], sn, spt_errfcn)

	    call fun_close (FUNIM(sh))
	    FUNIM(sh) = fun_open ("Normalized")
	    FC(sh) = FCNO
	    call fun_copy (FUNIM(sh), FUN(sh))
	    call strcpy (FUN_LABEL(FUN(sh)), FLABEL(sh), LEN_SHDRS)
	    call strcpy (FUN_UNITS(FUN(sh)), FUNITS(sh), LEN_SHDRS)
	    call spt_scale (spt, reg2)
	    call gt_setr (SPT_GT(spt), GTYMIN, INDEFR)
	    call gt_setr (SPT_GT(spt), GTYMAX, INDEFR)
	    SPT_REDRAW(spt,1) = YES

	case SUBTRACT:
	    if (reg1 == NULL || reg2 == NULL)
		return
	    if (REG_SH(reg1) == NULL || REG_SH(reg2) == NULL)
		return
	    if (SPEC(REG_SH(reg1),stype1) == NULL)
		call error (1, "No continuum defined")

	    if (REG_SHSAVE(reg2) == NULL)
		call spt_shcopy (REG_SH(reg2), REG_SHSAVE(reg2), YES)
	    else
		call spt_shcopy (REG_SH(reg2), REG_SHBAK(reg2), YES)

	    sc = SPEC(REG_SH(reg1),stype1)
	    sh = REG_SH(reg2)
	    sn = min (SN(sh), SN(REG_SH(reg1)))

	    if (SY(sh) != NULL && SY(sh) != sc)
		call asubr (Memr[SY(sh)], Memr[sc], Memr[SY(sh)], sn)
	    if (SR(sh) != NULL && SR(sh) != sc)
		call asubr (Memr[SR(sh)], Memr[sc], Memr[SR(sh)], sn)
	    if (SS(sh) != NULL && SS(sh) != sc)
		call asubr (Memr[SS(sh)], Memr[sc], Memr[SS(sh)], sn)
	    if (SC(sh) != NULL && SC(sh) != sc)
		call asubr (Memr[SC(sh)], Memr[sc], Memr[SC(sh)], sn)
	    if (SPEC(sh,stype1) == sc)
		call aclrr (Memr[sc], sn)
	    call spt_scale (spt, reg2)
	    call gt_setr (SPT_GT(spt), GTYMIN, INDEFR)
	    call gt_setr (SPT_GT(spt), GTYMAX, INDEFR)
	    SPT_REDRAW(spt,1) = YES

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: Continuum %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


real procedure spt_errfcn (x)

real	x, errval
common	/spectool/errval

begin
	return (errval)
end
