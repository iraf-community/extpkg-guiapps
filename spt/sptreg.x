include	<ctype.h>
include	<error.h>
include	<smw.h>
include <pkg/gtools.h>
include	"spectool.h"

# List of colon commands.
define	CMDS	"|load|pload|plot|select|delete|type|color|write|"

define	LOAD		1	# Load, no plot
define	PLOAD		2	# Load, plot
define	PLOT		3	# Plot
define	SELECT		4	# Select current register
define	DELETE		5	# Delete register
define	PTYPE		6	# Plot type
define	COLOR		7	# Plot color
define	WRITE		8	# Write register


# List of register types.
define	REGTYPE	"|current|reference|new|all|anynew|anycur|"

define	CUR		1	# Current register
define	REF		2	# Reference register
define	NEW		3	# New register
define	ALL		4	# All registers
define	ANYNEW		5	# Check registers (use new if not found)
define	ANYCUR		6	# Check registers (use current if not found)


# SPT_REG -- Interpret register colon commands.

procedure spt_reg (spt, reg, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#U Current register pointer
char	cmd[ARB]		#I Command

int	i, ncmd, stype, regid, regtype, ap, band, daxis, nsum, ival
pointer	sp, str1, gp, gt, new, ptr

bool	strne(), spt_getitem()
int	strdic(), nscan()
errchk	reg_load, reg_alloc

define	err_	10

begin
	call smark (sp)
	call salloc (str1, SZ_LINE, TY_CHAR)

	gp = SPT_GP(spt)
	gt = SPT_GT(spt)

	# Scan the command string and get command ID.
	call sscan (cmd)
	call gargwrd (Memc[str1], SZ_LINE)
	if (nscan() != 1)
	    goto err_
	ncmd = strdic (Memc[str1], Memc[str1], SZ_LINE, CMDS)
	if (ncmd == 0)
	    goto err_

	# Scan the command string and get the register.
	call gargwrd (Memc[str1], SZ_LINE)
	if (nscan() == 2)
	    call spt_gregstr (spt, reg, Memc[str1], new, ptr, ptr, stype, regid,
		regtype)
	else {
	    new = NULL
	    regtype = ALL
	}
	    
	# Execute the command.
	switch (ncmd) {
	case LOAD, PLOAD:
	    iferr {
		if (regtype == ALL) {
		    for (i=1; spt_getitem(SPLIST(spt),i,Memc[str1],SZ_LINE);
			i=i+1) {
			call sscan (Memc[str1])
			call gargwrd (Memc[str1], SZ_LINE)
			call gargi (ap)
			call gargi (band)
			if (nscan() != 3)
			    call error (1, "Error in list of spectra to load")

			call xt_imroot (Memc[str1], Memc[str1], SZ_LINE)
			call spt_greg (spt, Memc[str1], ap, band, ptr)

			if (ptr == NULL) {
			    call reg_alloc (spt, INDEFI, ptr)
			    iferr (call reg_load (spt, ptr, Memc[str1], ap,
				band, daxis, nsum)) {
				call reg_free (spt, ptr)
				call erract (EA_ERROR) 
			    }
			} else
			    call reg_load (spt, ptr, Memc[str1], ap, band,
				daxis, nsum)
			if (i==1)
			    new = ptr
		    }
		} else {
		    call gargwrd (Memc[str1], SZ_LINE)
		    call gargi (ap)
		    call gargi (band)
		    call gargi (daxis)
		    call gargi (nsum)

		    switch (nscan()) {
		    case 2:
			goto err_
		    case 3:
			ap = INDEFI
			band = INDEFI
			daxis = INDEFI
			nsum = INDEFI
		    case 4:
			band = INDEFI
			daxis = INDEFI
			nsum = INDEFI
		    case 5:
			daxis = INDEFI
			nsum = INDEFI
		    case 6:
			nsum = INDEFI
		    }

		    call xt_imroot (Memc[str1], Memc[str1], SZ_LINE)

		    switch (regtype) {
		    case CUR:
			call spt_greg (spt, Memc[str1], ap, band, new)
			if (new!=NULL || SPT_PMODE(spt) != PLOT1) {
			    if (new == NULL) {
				regid = INDEFI
				call reg_alloc (spt, regid, new)
			    }
			}
		    case NEW:
			call spt_gregid (spt, regid, new)
		    case ANYNEW:
			call spt_greg (spt, Memc[str1], ap, band, new)
		    case ANYCUR:
			call spt_greg (spt, Memc[str1], ap, band, new)
			if (new == NULL)
			    new = reg
		    }
		    if (new == NULL) {
			call reg_alloc (spt, regid, new)
			iferr (call reg_load (spt, new, Memc[str1], ap, band,
			    daxis, nsum)) {
			    call reg_free (spt, new)
			    call erract (EA_ERROR)
			}
		    } else
			call reg_load (spt, new, Memc[str1], ap, band, daxis,
			    nsum)
		}
	    } then {
		new = reg
		call spt_current (spt, reg)
		call erract (EA_ERROR)
	    }

	    if (ncmd == PLOAD) {
		reg = new
		if (reg != SPT_CREG(spt))
		    SPT_REDRAW(spt,1) = YES
		switch (SPT_PMODE(spt)) {
		case PLOT1:
		    do i = 1, SPT_NREG(spt) {
			ptr = REG(spt,i)
			if (ptr == reg) {
			    if (REG_PLOT(ptr) != PLOT1) {
				REG_PLOT(ptr) = PLOT1
				SPT_REDRAW(spt,1) = YES
			    }
			} else {
			    if (REG_PLOT(ptr) != NOPLOT) {
				REG_PLOT(ptr) = NOPLOT
				SPT_REDRAW(spt,1) = YES
			    }
			}
		    }
		case OPLOT:
		    do i = 1, SPT_NREG(spt) {
			ptr = REG(spt,i)
			if (REG_PLOT(ptr) != OPLOT) {
			    REG_PLOT(ptr) = OPLOT
			    SPT_REDRAW(spt,1) = YES
			}
		    }
		case STACK:
		    do i = 1, SPT_NREG(spt) {
			ptr = REG(spt,i)
			if (REG_PLOT(ptr) != STACK) {
			    REG_PLOT(ptr) = STACK
			    SPT_REDRAW(spt,1) = YES
			}
		    }
		}
	    }
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)

	case PLOT:
	    if (new != NULL) {
		reg = new
		if (reg != SPT_CREG(spt))
		    SPT_REDRAW(spt,1) = YES
	    }
	    switch (SPT_PMODE(spt)) {
	    case PLOT1:
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    if (ptr == reg) {
			if (REG_PLOT(ptr) != SPT_PMODE(spt)) {
			    REG_PLOT(ptr) = SPT_PMODE(spt)
			    SPT_REDRAW(spt,1) = YES
			}
		    } else {
			if (REG_PLOT(ptr) != NOPLOT) {
			    REG_PLOT(ptr) = NOPLOT
			    SPT_REDRAW(spt,1) = YES
			}
		    }
		}
	    case OPLOT, STACK:
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    if (REG_PLOT(ptr) != SPT_PMODE(spt)) {
			REG_PLOT(ptr) = SPT_PMODE(spt)
			SPT_REDRAW(spt,1) = YES
		    }
		}
	    }
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)

	case SELECT: # select reg
	    reg = new
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)
#	    call mod_colon (spt, reg, INDEF, INDEF, "list")

	case DELETE: # delete reg
	    if (regtype == ALL) {
		while (SPT_NREG(spt) > 0) {
		    if (REG_PLOT(REG(spt,1)) != NOPLOT)
			SPT_REDRAW(spt,1) = YES
		    call reg_free (spt, REG(spt,1))
		}
		reg = NULL
	    } else if (new != NULL) {
		if (new == reg) {
		    if (REG_PLOT(new) != NOPLOT)
			SPT_REDRAW(spt,1) = YES
		    call reg_free (spt, new)

		    if (SPT_NREG(spt) > 0) {
			reg = REG(spt,1)
			if (REG_PLOT(reg) != SPT_PMODE(spt)) {
			    REG_PLOT(reg) = SPT_PMODE(spt)
			    SPT_REDRAW(spt,1) = YES
			}
#			call mod_colon (spt, reg, INDEF, INDEF, "list")
		    } else
			reg = NULL
		} else {
		    if (REG_PLOT(new) != NOPLOT)
			SPT_REDRAW(spt,1) = YES
		    call reg_free (spt, new)
		}
	    }
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)

	case PTYPE: # type reg [string]
	    call gargwrd (Memc[str1], SZ_LINE)
	    if (regtype == ALL) {
		if (stype == SHSIG)
		    call strcpy (Memc[str1], SPT_ETYPE(spt), SPT_SZTYPE)
		else
		    call strcpy (Memc[str1], SPT_TYPE(spt), SPT_SZTYPE)
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    if (strne (Memc[str1], REG_TYPE(ptr,stype))) {
			call strcpy (Memc[str1], REG_TYPE(ptr,stype),
			    SPT_SZTYPE)
			#if (REG_FLAG(ptr) > 0)
			#    SPT_REDRAW(spt,1) = YES
		    }
		}
	    } else {
		if (strne (Memc[str1], REG_TYPE(new,stype))) {
		    call strcpy (Memc[str1], REG_TYPE(new,stype),
			SPT_SZTYPE)
		    if (REG_FLAG(new) > 0)
			SPT_REDRAW(spt,1) = YES
		}
	    }
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)
	    
	case COLOR: # Plot color
	    call gargi (ival)
	    if (regtype == ALL) {
		SPT_COLOR(spt) = ival
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    if (REG_COLOR(ptr,stype) != ival) {
			REG_COLOR(ptr,stype) = ival
			SPT_REDRAW(spt,1) = YES
		    }
		}
	    } else {
		if (REG_COLOR(new,stype) != ival) {
		    REG_COLOR(new,stype) = ival
		    SPT_REDRAW(spt,1) = YES
		}
	    }
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)
	    call spt_rglist (spt, reg)
	    call spt_current (spt, reg)

	case WRITE: # write reg cmd
	    call gargstr (Memc[str1], SZ_LINE)
	    call spt_wrspect (spt, new, Memc[str1])

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: register %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}

	#if (SPT_NREG(spt) == 0)
	#    reg = NULL
	#else
	#    reg = REG(spt,1)
	#SPT_CREG(spt) = reg
	call sfree (sp)
end


procedure reg_load (spt, reg, image, ap1, band1, daxis, nsum)

pointer	spt			#I SPECTOOL structure
pointer	reg			#O Register pointer
char	image[ARB]		#I Image name
int	ap1			#I Aperture
int	band1			#I Band
int	daxis			#I Dispersion axis
int	nsum			#I Summing factor

int	i, j, ap, band, new, btoi()
pointer	im, mw, sh, ptr, immap(), smw_openim()
bool	streq(), spt_gimage()
errchk	spt_gdata, spt_splist, spt_scale
errchk	immap, smw_openim, shdr_system, shdr_units

begin
	ap = ap1
	band = band1

	if (streq(image,REG_IMAGE(reg)) && ap==REG_AP(reg) &&
	    (IS_INDEFI(band)  || band==REG_BAND(reg)) &&
	    (IS_INDEFI(daxis) || daxis==REG_DAXIS(reg)) &&
	    (IS_INDEFI(nsum)  || nsum==REG_NSUM(reg))) {
	    new = NO
	} else if (streq (image, REG_IMAGE(reg))) {
	    iferr {
		sh = REG_SH(reg)
		im = IM(sh)
		mw = MW(sh)
		iferr (call spt_gdata (spt, im, mw, ap, band, daxis, nsum,
		    sh)) {
		    call spt_gdata (spt, im, mw, REG_AP(reg), REG_BAND(reg),
			daxis, nsum, sh)
		    REG_SH(reg) = sh
		    call erract (EA_ERROR)
		}

		new = YES
	    } then {
		call erract (EA_ERROR)
		new = ERR
	    }
	} else if (spt_gimage (spt, image, REG_ID(reg), ptr)) {
	    iferr {
		sh = NULL
		call spt_shcopy (REG_SH(ptr), sh, YES)
		im = IM(sh)
		mw = MW(sh)
		iferr (call spt_gdata (spt, im, mw, ap, band, daxis, nsum,
		    sh)) {
		    call shdr_close (sh)
		    call erract (EA_ERROR)
		}

		call reg_close (spt, reg)
		new = YES
	    } then {
		call erract (EA_ERROR)
		new = ERR
	    }
	} else {
	    iferr {
		im = NULL
		mw = NULL
		sh = NULL
		if (REG_NUM(reg) == 1)
		    call spt_splist (spt, image, im, mw, sh)
		if (im == NULL) {
		    call smw_daxis (NULL, NULL, 0, INDEFI, INDEFI)
		    ptr = immap (image, READ_ONLY, 0); im = ptr
		    ptr = smw_openim (im); mw = ptr
		}
		if (!IS_INDEFI(ap))
		    iferr (call spt_gdata (spt,im,mw,ap,band,daxis,nsum,sh))
			ap = INDEFI
		if (IS_INDEFI(ap))
		    call spt_gdata (spt, im, mw, ap, band, daxis, nsum, sh)

		call reg_close (spt, reg)
		new = YES
	    } then {
		if (sh != NULL)
		    call shdr_close (sh)
		if (mw != NULL)
		    call smw_close (mw)
		if (im != NULL)
		    call imunmap (im)
		call erract (EA_ERROR)
		new = ERR
	    }
	}

	if (new == YES) {
	    if (!streq (SPT_UNITS(spt), "default")) {
		if (streq (SPT_UNITS(spt), "pixels"))
		    call shdr_system (sh, "physical")
		else
		    iferr (call shdr_units (sh, SPT_UNITS(spt)))
			;
	    }
	    if (!streq (SPT_FUNITS(spt), "default")) {
		do i = SHDATA, SHCONT
		   if (SPEC(sh,i) != NULL)
		       j = i
		do i = SHDATA, SHCONT
		    if (SPEC(sh,i) != NULL)
			iferr (call fun_changer (FUN(sh), SPT_FUNITS(spt),
			    UN(sh), Memr[SX(sh)], Memr[SPEC(sh,i)], SN(sh),
			    btoi(i==j)))
			    ;
	    }

	    call strcpy (image, REG_IMAGE(reg), SPT_SZLINE)
	    call sprintf (REG_TITLE(reg), SZ_LINE,
		"[%s%s]: %s %.2s ap:%d beam:%d")
		call pargstr (IMNAME(sh))
		call pargstr (IMSEC(sh))
		call pargstr (TITLE(sh))
		call pargr (IT(sh))
		call pargi (AP(sh))
		call pargi (BEAM(sh))
	    REG_SH(reg) = sh
	    REG_AP(reg) = AP(sh)
	    REG_BAND(reg) = LINDEX(sh,2)
	    call strcpy (SPT_TYPE(spt), REG_TYPE(reg,SHDATA), SPT_SZTYPE)
	    call strcpy (SPT_ETYPE(spt), REG_TYPE(reg,SHSIG), SPT_SZTYPE)
	    REG_COLOR(reg,SHDATA) = SPT_COLOR(spt)
	    call spt_scale (spt, reg)
	    REG_PLOT(reg) = NOPLOT
	    REG_FLAG(reg) = 0
	    if (REG_SHSAVE(reg) != NULL)
		call shdr_close (REG_SHSAVE(reg))
	    call spt_shcopy (REG_SH(reg), REG_SHSAVE(reg), YES)
	    call spt_shcopy (REG_SH(reg), REG_SHBAK(reg), YES)
	    REG_MODIFIED(reg) = '+'

	    REG_FORMAT(reg) = SMW_FORMAT(mw)
	    if (REG_FORMAT(reg) == SMW_ND) {
		REG_DAXIS(reg) = SMW_PAXIS(mw,1)
		REG_NSUM(reg) = SMW_NSUM(mw,1)
	    } else {
		REG_DAXIS(reg) = INDEFI
		REG_NSUM(reg) = INDEFI
	    }

	    if (SN(sh) > SPT_SN(spt)) {
		if (SPT_SN(spt) == 0)
		    call malloc (SPT_SPEC(spt), SN(sh), TY_REAL)
		else
		    call realloc (SPT_SPEC(spt), SN(sh), TY_REAL)
		SPT_SN(spt) = SN(sh)
	    }
	    #if (REG_ID(reg) > 0)
	#	call spt_rglist (spt, reg)
#	    call lab_copy (spt, SPT_CREG(spt), reg)
#	    call lid_copy (spt, SPT_CREG(spt), reg)
	    call spt_rv (spt, reg, "allocate")
	}
	if (new != ERR && REG_ID(reg) > 0) {
	    #SPT_REDRAW(spt,1) = new
	    #SPT_REDRAW(spt,2) = new
	    #call spt_current (spt, reg)
	}
end


procedure reg_alloc (spt, regid, reg)

pointer	spt			#I Spectool pointer
int	regid			#I Register ID
pointer	reg			#O Register structure

int	i, nreg, regidnew
pointer	ptr

begin
	regidnew = regid
	call spt_gregid (spt, regidnew, reg)
	if (reg != NULL)
	    return

	nreg = SPT_NREG(spt)

	# For now enforce a maximum number of registers.  Once can choose
	# either to not allocate a register and warn the user or overwrite
	# an existing register.  For now we do the latter.

	if (nreg == SPT_MAXREG(spt)) {
	    #call error (1, "No more registers are available")
	    reg = SPT_CREG(spt)
	    regid = mod (REG_ID(reg), SPT_MAXREG(spt)) + 1
	    call spt_gregid (spt, regid, reg)
	    if (reg == NULL)
		call error (1, "Can't allocate new register")
	    return
	}

	if (nreg == 0)
	    call malloc (SPT_REGS(spt), SPT_REGALLOC, TY_POINTER)
	else if (mod (nreg, SPT_REGALLOC) == 0)
		call realloc (SPT_REGS(spt), nreg+SPT_REGALLOC, TY_POINTER)

	call calloc (reg, REG_LEN, TY_STRUCT)
	REG_ID(reg) = regidnew
	if (regidnew <= 26) {
	    call sprintf (REG_IDSTR(reg), SPT_SZTYPE, "%c")
		call pargi (regidnew + 'a' - 1)
	} else if (regidnew <= 52) {
	    call sprintf (REG_IDSTR(reg), SPT_SZTYPE, "%c")
		call pargi (regidnew + 'A' - 27)
	} else {
	    call sprintf (REG_IDSTR(reg), SPT_SZTYPE, "#%d")
		call pargi (regidnew)
	}
	REG_IMAGE(reg) = EOS
	REG_AP(reg) = INDEFI
	REG_BAND(reg) = 1
	call sprintf (REG_TYPE(reg,SHDATA), SPT_SZTYPE, "line%d")
	    call pargi (mod (regidnew-1,4)+1)
	REG_COLOR(reg,SHDATA) = mod (regidnew-1, 9) + 1
	do i = 3, SH_NTYPES {
	    call sprintf (REG_TYPE(reg,i), SPT_SZTYPE, "line%d")
		call pargi (i-1)
	    REG_COLOR(reg,i) = i-1
	}
	REG_SCALE(reg) = 1.
	REG_OFFSET(reg) = 0.
	REG_SH(reg) = NULL
	REG_SHSAVE(reg) = NULL
	REG_SHBAK(reg) = NULL
	REG_PLOT(reg) = NOPLOT
	REG_LABEL(reg) = YES
	REG_LINES(reg) = YES
	REG_MODPLOT(reg) = YES
	REG_FLAG(reg) = 0
	REG_RV(reg) = NULL

	nreg = nreg + 1
	SPT_NREG(spt) = nreg
	for (i=nreg; i>1; i=i-1) {
	    ptr = REG(spt,i-1)
	    if (REG_ID(ptr) < regidnew)
		break
	    REG(spt,i) = ptr
	    REG_NUM(ptr) = i
	}
	REG(spt,i) = reg
	REG_NUM(reg) = i
end


procedure reg_copy (spt, reg1, reg2)

pointer	spt			#I Spectool pointer
pointer	reg1			#I Register structure to copy
pointer	reg2			#U Register structure copy (must be allocated)

int	regnum, regid, regplot, reglabel, reglines, regmodplot

begin
	regnum = REG_NUM(reg2)
	regid = REG_ID(reg2)
	regplot = REG_PLOT(reg2)
	reglabel = REG_LABEL(reg2)
	reglines = REG_LINES(reg2)
	regmodplot = REG_MODPLOT(reg2)
	call strcpy (REG_IDSTR(reg2), SPT_STRING(spt), SPT_SZSTRING)

	call amovi (Memi[reg1], Memi[reg2], REG_LEN)

	REG_NUM(reg2) = regnum
	REG_ID(reg2) = regid
	REG_PLOT(reg2) = regplot
	REG_LABEL(reg2) = reglabel
	REG_LINES(reg2) = reglines
	REG_MODPLOT(reg2) = regmodplot
	call strcpy (SPT_STRING(spt), REG_IDSTR(reg2), SPT_SZTYPE)

	REG_SH(reg2) = NULL
	REG_SHSAVE(reg2) = NULL
	REG_SHBAK(reg2) = NULL
	call spt_shcopy (REG_SH(reg1), REG_SH(reg2), YES)
	call spt_shcopy (REG_SH(reg2), REG_SHSAVE(reg2), YES)

	call lab_copy (spt, reg1, reg2)
	call lid_copy (spt, reg1, reg2)
	REG_RV(reg2) = NULL
	call spt_rv (spt, reg2, "allocate")
end


procedure reg_free (spt, reg)

pointer	spt			#I SPECTOOL strucutre
pointer	reg			#I Register structure

int	i, j, nreg

begin
	if (reg == NULL)
	    return

	call reg_close (spt, reg)

	nreg = SPT_NREG(spt)
	for (i=1; i<nreg && REG(spt,i)!=reg; i=i+1)
	    ;

	call lab_colon (spt, reg, INDEFD, INDEFD, "free")
	call lid_colon (spt, reg, INDEFD, INDEFD, "free")
	call spt_rv (spt, reg, "free")
	call mfree (reg, TY_STRUCT)

	nreg = nreg - 1
	do j = i, nreg {
	    REG(spt,j) = REG(spt,j+1)
	    REG_NUM(REG(spt,j)) = j
	}
	REG(spt,nreg+1) = NULL
	if (nreg == 0)
	    call mfree (SPT_REGS(spt), TY_POINTER)
	else if (mod (nreg, SPT_REGALLOC) == 0)
	    call realloc (SPT_REGS(spt), nreg, TY_POINTER)
	SPT_NREG(spt) = nreg
end


procedure reg_close (spt, reg)

pointer	spt			#I SPECTOOL strucutre
pointer	reg			#I Register structure

int	i
pointer	im, mw, sh, ptr

begin
	if (reg == NULL)
	    return

	sh = REG_SH(reg)
	if (sh != NULL) {
	    im = IM(sh)
	    mw = MW(sh)
	    for (i=1; i<=SPT_NREG(spt); i=i+1) {
		ptr = REG(spt,i)
		if (ptr != reg) {
		    ptr = REG_SH(ptr)
		    if (ptr != NULL) {
			if (mw == MW(ptr))
			    MW(sh) = NULL
			if (im == IM(ptr))
			    IM(sh) = NULL
		    }
		}
	    }
	    im = IM(sh)
	    mw = MW(sh)
	    MW(sh) = NULL
	    call shdr_close (sh)
	    if (mw != NULL)
		call smw_close (mw)
	    if (im != NULL)
		call imunmap (im)
	    REG_SH(reg) = sh

	    if (REG_SHSAVE(reg) != NULL)
		call shdr_close (REG_SHSAVE(reg))

	    if (REG_SHBAK(reg) != NULL)
		call shdr_close (REG_SHBAK(reg))
	}
end


procedure spt_greg (spt, image, ap, band, reg)

pointer	spt			#I Spectool pointer
char	image[ARB]		#I Image
int	ap			#I Aperture
int	band			#I Band
pointer	reg			#O Register pointer

int	i
bool	streq()

begin
	for (i=1; i<=SPT_NREG(spt); i=i+1) {
	    reg = REG(spt,i)
	    if (streq (image, REG_IMAGE(reg)) &&
		(IS_INDEFI(ap) || REG_AP(reg) == ap) &&
		(IS_INDEFI(band) || REG_BAND(reg) == band))
		return
	}
	reg = NULL
end


procedure spt_gregid (spt, regid, reg)

pointer	spt			#I Spectool pointer
int	regid			#U Register ID (INDEF to return new value)
pointer	reg			#O Register pointer (NULL = not found)

int	i, regidnew

begin
	regidnew = 1
	for (i=1; i<=SPT_NREG(spt); i=i+1) {
	    reg = REG(spt,i)
	    if (REG_ID(reg) == regid) {
		return
	    }
	    if (regidnew == REG_ID(reg))
		regidnew = regidnew + 1
	}
	if (IS_INDEFI(regid))
	    regid = regidnew
	reg = NULL
end


# SPT_GREGSTR -- Get specified register.
# The register syntax is one of:
#     current	current register
#     new       new register
#     anynew	any register or new
#     all	all registers
# 
#     reg[type]	a specific register with optional spectrum type
# 
# where the spectrum types are:
# 
#     s	primary spectrum
#     r	raw spectrum
#     b	background/sky spectrum
#     u	uncertainty spectrum
#     c	continuum spectrum
# 
# If the register is . or unspecified then the default register is used.  If
# no type is specified then the current spectrum type is used.

procedure spt_gregstr (spt, defreg, regstr, reg, sh, sy, stype, regid, regtype)

pointer	spt		#I SPECTOOL pointer
pointer	defreg		#I Default register
char	regstr[ARB]	#I Register selection string
pointer	reg		#O Register pointer
pointer	sh		#O Spectrum pointer
pointer	sy		#O Spectrum vector
int	stype		#O Spectrum type
int	regid		#O Spectrum register id	
int	regtype		#O Register type

char	ch
int	ip, strncmp(), ctoi()

define	err1_	10
define	err2_	20

begin
	reg = NULL
	sh = NULL
	sy = NULL
	stype = SPT_CTYPE(spt)
	regid = INDEFI
	regtype = 0

	# Check for special register names.
	for (ip=1; IS_WHITE(regstr[ip]); ip=ip+1)
	    ;
	if (strncmp (regstr[ip], "cur", 3) == 0) {
	    reg = SPT_CREG(spt)
	    if (reg != NULL)
		regid = REG_ID(reg)
	    regtype = CUR
	    if (strncmp (regstr[ip], "current", 7) == 0)
		ip = ip + 7
	    else
		ip = ip + 3
	} else if (strncmp (regstr[ip], "current", 7) == 0) {
	    reg = SPT_CREG(spt)
	    if (reg != NULL)
		regid = REG_ID(reg)
	    regtype = CUR
	    ip = ip + 7
	} else if (strncmp (regstr[ip], "ref", 3) == 0) {
	    reg = defreg
	    if (reg != NULL)
		regid = REG_ID(reg)
	    regtype = REF
	    if (strncmp (regstr[ip], "reference", 9) == 0)
		ip = ip + 9
	    else
		ip = ip + 3
	} else if (strncmp (regstr[ip], "reference", 9) == 0) {
	    reg = defreg
	    if (reg != NULL)
		regid = REG_ID(reg)
	    regtype = REF
	    ip = ip + 9
	} else if (strncmp (regstr[ip], "new", 3) == 0) {
	    regtype = NEW
	    ip = ip + 3
	} else if (strncmp (regstr[ip], "anynew", 6) == 0) {
	    regtype = ANYNEW
	    ip = ip + 6
	} else if (strncmp (regstr[ip], "all", 3) == 0) {
	    regtype = ALL
	    ip = ip + 3
	} else {
	    ch = regstr[ip]
	    if (IS_LOWER(ch)) {
		regid = ch - 'a' + 1
		ip = ip + 1
	    } else if (IS_UPPER(ch)) {
		regid = ch - 'A' + 27
		ip = ip + 1
	    } else if (ch == '#') {
		ip = ip + 1
		if (ctoi (regstr, ip, regid) == 0)
		    goto err1_
	    } else if (ch == '.') {
		if (defreg == NULL)
		    goto err2_
		regid = REG_ID(defreg)
		ip = ip + 1
	    } else if (ch == '[' || ch == EOS) {
		if (defreg == NULL)
		    goto err2_
		regid = REG_ID(defreg)
	    } else
		goto err1_

	    call spt_gregid (spt, regid, reg)
	}

	ch = regstr[ip]
	if (ch == '[') {
	    ip = ip + 1
	    ch = regstr[ip]
	    if (IS_UPPER(ch))
		ch = TO_LOWER(ch)
	    switch (ch) {
	    case 's':
		stype = SHDATA
	    case 'r':
		stype = SHRAW
	    case 'b':
		stype = SHSKY
	    case 'u':
		stype = SHSIG
	    case 'c':
		stype = SHCONT
	    default:
		goto err1_
	    }
	    ip = ip + 1
	    if (regstr[ip] != ']')
		goto err1_
	    for (ip=ip+1; IS_WHITE(regstr[ip]); ip=ip+1)
		;
	    if (regstr[ip] != EOS)
		goto err1_
	} else if (ch == EOS)
	    stype = SPT_CTYPE(spt)
	else
	    goto err1_

	if (reg != NULL) {
	    sh = REG_SH(reg)
	    if (sh != NULL)
		sy = SPEC(sh,stype)
	}

	return

err1_
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "Invalid register specification %s")
	    call pargstr (regstr)
	call error (1, SPT_STRING(spt))

err2_
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "Register not available %s")
	    call pargstr (regstr)
	call error (2, SPT_STRING(spt))
end


# SPT_REGNAME -- Get specified register.
# The register syntax:
# 
#     %reg[type]
#
# where reg is a register name, currently a-z and #N, and the spectrum types are
# currently spectrum, continuum, raw, sky, and sigma.  Either field may be
# absent or given as '.' to select the default register or spectrum type.

procedure spt_regname (spt, reg, stype, regname, newreg, newstype)

pointer	spt		#I SPECTOOL pointer
pointer	reg		#I Default register
int	stype		#I Default spectrum type
char	regname[ARB]	#I Register selection string
pointer	newreg		#O Selected register
int	newstype	#O Selected spectrum type

int	i, j, regid, stridxs(), strdic(), nscan(), ctoi()
pointer	sp, name
errchk	reg_alloc

define	err1_	10
define	err2_	20

begin
	if (reg == NULL)
	    return

	call smark (sp)
	call salloc (name, SZ_LINE, TY_CHAR)

	# Default.
	newreg = reg
	regid = REG_ID(reg)
	newstype = stype

	# Scan name.
	if (regname[1] == '%')
	    call strcpy (regname[2], Memc[name], SZ_LINE)
	else
	    call strcpy (regname, Memc[name], SZ_LINE)
	i = stridxs ("[", Memc[name])
	if (i > 0)
	    Memc[name+i-1] = ' '
	j = stridxs ("]", Memc[name])
	if (j > 0)
	    Memc[name+j-1] = EOS
	call sscan (Memc[name])

	# Get register.
	if (i != 1) {
	    call gargwrd (Memc[name], SZ_LINE)
	    if (nscan() != 1)
		goto err1_
	    if (IS_LOWER(Memc[name])) {
		regid = Memc[name] - 'a' + 1
		call spt_gregid (spt, regid, newreg)
	    } else if (IS_UPPER(Memc[name])) {
		regid = Memc[name] - 'A' + 27
		call spt_gregid (spt, regid, newreg)
	    } else if (Memc[name] == '#') {
		j = 2
		if (ctoi (Memc[name], j, regid) == 0)
		    goto err1_
	    } else if (Memc[name] != '.')
		goto err1_
	}

	# Get spectrum type.
	call gargwrd (Memc[name], SZ_LINE)
	if ((i == 1 && nscan() == 1) || nscan() == 2) {
	    if (Memc[name] != '.')
		newstype = strdic (Memc[name], Memc[name], SZ_LINE, STYPES)
	    if (newstype == 0)
		goto err1_
	}

	if (newreg == NULL) {
	    call reg_alloc (spt, regid, newreg)
	    call reg_copy (spt, reg, newreg)
	}

	call sfree (sp)
	return

err1_
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "Invalid register name %s")
	    if (regname[1] == '%')
		call pargstr (regname[2])
	    else
		call pargstr (regname)
	call error (1, SPT_STRING(spt))

err2_
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "Register not available %s")
	    if (regname[1] == '%')
		call pargstr (regname[2])
	    else
		call pargstr (regname)
	call error (2, SPT_STRING(spt))
end
