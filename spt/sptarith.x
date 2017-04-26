include	<error.h>
include	<evvexpr.h>
include	<smw.h>
include	<math/iminterp.h>
include	"spectool.h"

# List of commands.
define	CMDS	"|open|close|arith|sarith|registers|stypes|"

define	OPEN		1	# Open
define	CLOSE		2	# Close
define	ARITH		3	# Evaluate expression with defaults
define	SARITH		4	# Evaluate expression with register
define	REGISTERS	5	# Set registers
define	TYPES		6	# Set types to evaluate


# SPT_ARITH -- Spectrum arithmetic.
# Spectrum, continuum, and error vectors can be individually referenced.

procedure spt_arith (spt, reg, cmd)

pointer	spt		#I Spectool pointer
pointer	reg		#I Default register
char	cmd[ARB]	#I Arithmetic command

bool	newreg
int	i, ncmd, sn, stype, regid, regtype
real	val
pointer	template, output, expr, stypes, vals, str1, str2, str3
pointer	ref, o, sh, shout, sy

int	strdic(), nscan()
pointer	evvexpr(), locpr()
extern	spt_arithop()
errchk	spt_gregstr, reg_alloc, reg_copy, evvexpr

pointer	out
int	arithop_flag
common	/arith/ out, arithop_flag

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (ncmd) {
	case OPEN:
	    call malloc (template, SZ_LINE, TY_CHAR)
	    call malloc (output, SZ_LINE, TY_CHAR)
	    call malloc (expr, SZ_LINE, TY_CHAR)
	    call malloc (stypes, SH_NTYPES, TY_INT)
	    call malloc (vals, SH_NTYPES, TY_INT)
	    call malloc (str1, SZ_LINE, TY_CHAR)
	    call malloc (str2, SZ_LINE, TY_CHAR)
	    call malloc (str3, SZ_LINE, TY_CHAR)

	    call strcpy ("current", Memc[template], SZ_LINE)
	    call strcpy ("new", Memc[output], SZ_LINE)
	    Memc[expr] = EOS
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" \"%s\"")
		call pargstr (Memc[template])
		call pargstr (Memc[output])
	    call gmsg (SPT_GP(spt), "arithreg", SPT_STRING(spt))
	    call gmsg (SPT_GP(spt), "arithexpr", Memc[expr])

	    Memi[stypes+SHDATA-1] = YES
	    Memi[stypes+SHCONT-1] = YES
	    Memi[stypes+SHRAW-1] = YES
	    Memi[stypes+SHSKY-1] = YES
	    Memi[stypes+SHSIG-1] = NO
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%d %d %d %d %d")
		call pargi (Memi[stypes+SHDATA-1])
		call pargi (Memi[stypes+SHCONT-1])
		call pargi (Memi[stypes+SHRAW-1])
		call pargi (Memi[stypes+SHSKY-1])
		call pargi (Memi[stypes+SHSIG-1])
	    call gmsg (SPT_GP(spt), "arithtypes", SPT_STRING(spt))


	case CLOSE:
	    call mfree (template, TY_CHAR)
	    call mfree (output, TY_CHAR)
	    call mfree (expr, TY_CHAR)
	    call mfree (stypes, TY_INT)
	    call mfree (vals, TY_INT)
	    call mfree (str1, TY_CHAR)
	    call mfree (str1, TY_CHAR)
	    call mfree (str3, TY_CHAR)

	case ARITH, SARITH:
	    iferr {
		call strcpy (Memc[template], Memc[str1], SZ_LINE)
		call strcpy (Memc[output], Memc[str2], SZ_LINE)
		call strcpy (Memc[expr], Memc[str3], SZ_LINE)

		if (ncmd == SARITH) {
		    call gargwrd (Memc[template], SZ_LINE)
		    call gargwrd (Memc[output], SZ_LINE)

		    if (nscan() <3)
			call error (1, "Syntax error")
		}
		call gargstr (Memc[expr], SZ_LINE)
		if (Memc[expr] == ' ')
		    call strcpy (Memc[expr+1], Memc[expr], SZ_LINE)

		o = NULL
		out = NULL

		# Get template register.
		call spt_gregstr (spt, reg, Memc[template], ref, sh, sy,
		    stype, regid, regtype)
		if (ref == NULL)
		    call error (1, "Template register not found")

		# Get output register.
		call spt_gregstr (spt, reg, Memc[output], out, shout, sy,
		    stype, regid, regtype)
		if (out == NULL) {
		    call reg_alloc (spt, INDEFI, out)
		    call reg_copy (spt, ref, out)
		    newreg = true
		} else {
		    call spt_shcopy (REG_SH(out), REG_SHBAK(out), YES)
		    newreg = false
		}

		# Evaluate expression.
		stype = SPT_CTYPE(spt)
		do i = SHDATA, SHCONT {
#		    if (Memi[stypes+i-1] == NO || SPEC(sh,i) == NULL)
#			next
		    if (Memi[stypes+i-1] == NO)
			next
		    SPT_CTYPE(spt) = i

		    arithop_flag = OK
		    o = evvexpr (Memc[expr], locpr(spt_arithop), spt, NULL,
			NULL, 0)
		    if (arithop_flag == ERR) {
			if (SPEC(sh,i) == NULL)
			    next
			call error (1, "Data for spectrum arithmetic not found")
		    }
		    if (O_TYPE(o) == TY_CHAR)
			call error (1, "invalid arithmetic result")

		    # Set result in output register.
		    sh = REG_SH(out)
		    sn = SN(sh)
		    if (SPEC(sh,SPT_CTYPE(spt)) == NULL)
			call malloc (SPEC(sh,SPT_CTYPE(spt)), sn, TY_REAL)
		    sy = SPEC(sh,SPT_CTYPE(spt))

		    if (O_LEN(o) == 0) {
			switch (O_TYPE(o)) {
			case TY_SHORT:
			    val = O_VALS(o)
			case TY_INT:
			    val = O_VALI(o)
			case TY_LONG:
			    val = O_VALL(o)
			case TY_REAL:
			    val = O_VALR(o)
			case TY_DOUBLE:
			    val = O_VALD(o)
			}
			call amovkr (val, Memr[sy], sn)
		    } else {
			if (O_LEN(o) < sn)
			    call aclrr (Memr[sy], sn)
			switch (O_TYPE(o)) {
			case TY_SHORT:
			    call achtsr (Mems[O_VALP(o)], Memr[sy], sn)
			case TY_INT:
			    call achtir (Memi[O_VALP(o)], Memr[sy], sn)
			case TY_LONG:
			    call achtlr (Meml[O_VALP(o)], Memr[sy], sn)
			case TY_REAL:
			    call amovr (Memr[O_VALP(o)], Memr[sy], sn)
			case TY_DOUBLE:
			    call achtdr (Memd[O_VALP(o)], Memr[sy], sn)
			}
		    }
		}
		SPT_CTYPE(spt) = stype

		# Make new spectrum the current spectrum.
		reg = out
		call spt_current (spt, reg)

		# Reset title.
		call strcpy ("NONE", REG_IMAGE(reg), SPT_SZLINE)
		call sprintf (REG_TITLE(reg), SZ_LINE,
		    "[%s]: %s %.2s ap:%d beam:%d")
		    call pargstr (Memc[expr])
		    call pargstr (TITLE(sh))
		    call pargr (IT(sh))
		    call pargi (AP(sh))
		    call pargi (BEAM(sh))

		call spt_scale (spt, reg)
		call spt_reg (spt, reg, "plot") 
		SPT_REDRAW(spt,1) = YES
		SPT_REDRAW(spt,2) = YES

		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" \"%s\"")
		    call pargstr (Memc[template])
		    call pargstr (Memc[output])
		call gmsg (SPT_GP(spt), "arithreg", SPT_STRING(spt))
		call gmsg (SPT_GP(spt), "arithexpr", Memc[expr])
	    } then {
		call strcpy (Memc[str1], Memc[template], SZ_LINE)
		call strcpy (Memc[str2], Memc[output], SZ_LINE)
		call strcpy (Memc[str3], Memc[expr], SZ_LINE)
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" \"%s\"")
		    call pargstr (Memc[template])
		    call pargstr (Memc[output])
		call gmsg (SPT_GP(spt), "arithreg", SPT_STRING(spt))
		call gmsg (SPT_GP(spt), "arithexpr", Memc[expr])

		if (newreg && out != NULL)
		    call reg_free (spt, out)
		call erract (EA_ERROR)
	    }

#	    if (o != NULL)
#		call evvfree (o)

	case REGISTERS: # registers template output
	    call gargwrd (Memc[str1], SZ_LINE)
	    call gargwrd (Memc[str2], SZ_LINE)
	    if (nscan() != 3)
		goto err_

	    call strcpy (Memc[str1], Memc[template], SZ_LINE)
	    call strcpy (Memc[str2], Memc[output], SZ_LINE)
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" \"%s\"")
		call pargstr (Memc[template])
		call pargstr (Memc[output])
	    call gmsg (SPT_GP(spt), "arithreg", SPT_STRING(spt))

	case TYPES: # stypes data raw sky sig cont
	    call gargi (Memi[vals-1+SHDATA])
	    call gargi (Memi[vals-1+SHCONT])
	    call gargi (Memi[vals-1+SHRAW])
	    call gargi (Memi[vals-1+SHSKY])
	    call gargi (Memi[vals-1+SHSIG])
	    if (nscan() != 6)
		goto err_

	    Memi[stypes+SHDATA-1] = Memi[vals-1+SHDATA]
	    Memi[stypes+SHCONT-1] = Memi[vals-1+SHCONT]
	    Memi[stypes+SHRAW-1] = Memi[vals-1+SHRAW]
	    Memi[stypes+SHSKY-1] = Memi[vals-1+SHSKY]
	    Memi[stypes+SHSIG-1] = Memi[vals-1+SHSIG]

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%d %d %d %d %d")
		call pargi (Memi[stypes+SHDATA-1])
		call pargi (Memi[stypes+SHCONT-1])
		call pargi (Memi[stypes+SHRAW-1])
		call pargi (Memi[stypes+SHSKY-1])
		call pargi (Memi[stypes+SHSIG-1])
	    call gmsg (SPT_GP(spt), "arithtypes", SPT_STRING(spt))

	default:
err_
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: arith %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


# SPT_SARITHOP -- Return the operand vector for the specified register.

procedure spt_arithop (spt, regstr, o)

pointer	spt		#I SPECTOOL pointer
char	regstr		#I Register string
pointer	o		#U Output operand pointer

int	stype, regid, regtype
pointer	reg, sh, sy

pointer	out
int	arithop_flag
common	/arith/ out, arithop_flag

begin
	call malloc (o, LEN_OPERAND, TY_STRUCT)

	# Get register.
	call spt_gregstr (spt, SPT_CREG(spt), regstr, reg, sh, sy, stype,
	    regid, regtype)

	# Set operand structure.  We can't use O_FREEOP to free the
	# operand structure because of a bug in evvexpr.

	O_TYPE(o) = TY_REAL
	O_LEN(o) = SN(REG_SH(out))

	if (sy == NULL) {
	    arithop_flag = ERR
	    call calloc (O_VALP(o), O_LEN(o), TY_REAL)
	    O_FLAGS(o) = O_FREEVAL
	} else {
	    # Rebin to reference dispersion if necessary.
	    call spt_rebin (sh, REG_SH(out), stype, sy)
	    O_VALP(o) = sy
	    O_FLAGS(o) = 0
	    if (sy != SPEC(sh,stype))
		O_FLAGS(o) = O_FLAGS(o) + O_FREEVAL
	}
end


# SPT_REBIN -- Rebin spectrum to dispersion of reference spectrum.
# This is a modification of SHDR_REBIN.

procedure spt_rebin (sh, shref, type, spec)

pointer	sh		#I Spectrum to be rebinned
pointer	shref		#I Reference spectrum
int	type		#I Spectrum type
pointer	spec		#U Spectrum pointer

char	interp[10]
int	i, j, ia, ib, n, clgwrd()
real	a, b, sum, asieval(), asigrl()
double	x, w, xmin, xmax, shdr_lw(), shdr_wl()
pointer	unsave, asi
bool	fp_equalr()

begin
	# Check for input data.
	if (SPEC(sh,type) == NULL)
	    call error (1, "No spectrum to rebin")

	# Check if rebinning is needed
	if (DC(sh) == DC(shref) && DC(sh) != DCFUNC &&
	    fp_equalr (W0(sh), W0(shref)) && fp_equalr(WP(sh), WP(shref)) &&
	    SN(sh) == SN(shref))
	    return

	# Do everything in units of MWCS.
	unsave = UN(sh)
	UN(sh) = MWUN(sh)

	# Fit the interpolation function to the spectrum.
	# Extend the interpolation by one pixel at each end.

	call asiinit (asi, clgwrd ("interp", interp, 10, II_FUNCTIONS))
	n = SN(sh)
	call malloc (spec, n+2, TY_REAL)
	call amovr (Memr[SPEC(sh,type)], Memr[spec+1], n)
	Memr[spec] = Memr[SPEC(sh,type)]
	Memr[spec+n+1] = Memr[SPEC(sh,type)+n-1]
	call asifit (asi, Memr[spec], n+2)
	call mfree (spec, TY_REAL)

	xmin = 0.5
	xmax = n + 0.5

	# Allocate spectrum.
	call calloc (spec, SN(shref), TY_REAL)

	# Compute the average flux in each output pixel.
	x = 0.5
	w = shdr_lw (shref, x)
	x = shdr_wl (sh, w)
	b = max (xmin, min (xmax, x)) + 1
	do i = 1, n {
	    x = i + 0.5
	    w = shdr_lw (shref, x)
	    x = shdr_wl (sh, w)
	    a = b
	    b = max (xmin, min (xmax, x)) + 1
	    if (a <= b) {
		ia = nint (a + 0.5)
		ib = nint (b - 0.5)
		if (abs (a+0.5-ia) < .00001 && abs (b-0.5-ib) < .00001) {
		    sum = 0.
		    do j = ia, ib
			sum = sum + asieval (asi, real(j))
		    if (ib - ia > 0)
			sum = sum / (ib - ia)
		} else {
		    sum = asigrl (asi, a, b)
		    if (b - a > 0.)
			sum = sum / (b - a)
		}
	    } else {
		ib = nint (b + 0.5)
		ia = nint (a - 0.5)
		if (abs (a-0.5-ia) < .00001 && abs (b+0.5-ib) < .00001) {
		    sum = 0.
		    do j = ib, ia
			sum = sum + asieval (asi, real(j))
		    if (ia - ib > 0)
			sum = sum / (ia - ib)
		} else {
		    sum = asigrl (asi, b, a)
		    if (a - b > 0.)
			sum = sum / (a - b)
		}
	    }

	    Memr[spec] = sum
	    spec = spec + 1
	}
	call asifree (asi)

	UN(sh) = unsave
end
