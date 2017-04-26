include	<smw.h>
include	"spectool.h"

# Commands
define	CMDS	"|open|close|deredden|"
define	OPEN		1
define	CLOSE		2
define	DEREDDEN	3	# Deredden spectrum

define	DEREDTYPES	"|A(V)|E(B-V)|c|"

# SPT_DERED -- Deredden spectrum.

procedure spt_deredden (spt, reg, cmd)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
char	cmd			#I Command

real	av, rv
int	type
bool	uncorrect, override

real	avold, rvold
int	i, j, n
pointer	sp, str, sh, sx
int	strdic(), nscan(), ctor(), strncmp()
long	clktime()
errchk	deredden

define	err_	10

begin
	if (reg == NULL)
	    return
	sh = REG_SH(reg)
	if (sh == NULL)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	n = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (n) {
	case OPEN: # open
	    ;
	case CLOSE: # close
	    ;
	case DEREDDEN: # deredden rv av type uncorrect override
	    call gargr (rv)
	    call gargr (av)
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargb (uncorrect)
	    call gargb (override)
	    type = strdic (Memc[str], Memc[str], SZ_LINE, DEREDTYPES)
	    if (nscan() <6 || type == 0)
		#goto err_
		call error (1, "Missing dereddening parameters")

	    n = SN(sh)
	    call salloc (sx, n, TY_REAL)
	    call amovr (Memr[SX(sh)], Memr[sx], n)
	    iferr (call un_changer (UN(sh), "angstroms", Memr[sx], n, NO)) {
		call sfree (sp)
		call error (1, "Unknown dispersion units")
	    }

	    call spt_shcopy (REG_SH(reg), REG_SHBAK(reg), YES)

	    rvold = rv
	    avold = 0.
	    if (RC(sh) != EOS) {
		if (override) {
		    if (uncorrect) {
			call sscan (RC(sh))
			for (i=1;; i=i+1) {
			    call gargwrd (Memc[str], SZ_LINE)
			    if (nscan() < i)
				break
			    if (strncmp (Memc[str], "A(V)=", 5) == 0) {
				j = 6
				j = ctor (Memc[str], j, avold)
			    } else if (strncmp (Memc[str], "R=", 2) == 0) {
				j = 3
				j = ctor (Memc[str], j, rvold)
			    }
			}
		    }
		} else {
		    call sfree (sp)
		    call error (1, "Spectrum has already been dereddened")
		}
	    }

	    call cnvdate (clktime(0), Memc[str], SZ_LINE)
	    switch (type) {
	    case 1:
		call sprintf (RC(sh), SZ_LINE, "%s A(V)=%g R=%g")
		    call pargstr (Memc[str])
		    call pargr (av)
		    call pargr (rv)
	    case 2:
		call sprintf (RC(sh), SZ_LINE, "%s E(B-V)=%g A(V)=%g R=%g")
		    call pargstr (Memc[str])
		    call pargr (av)
		    call pargr (rv * av)
		    call pargr (rv)
		av = rv * av
	    case  3:
		call sprintf (RC(sh), SZ_LINE, "%s c=%g A(V)=%g R=%g")
		    call pargstr (Memc[str])
		    call pargr (av)
		    call pargr (rv * av * (0.61 + 0.024 * av))
		    call pargr (rv)
		av = rv * av * (0.61 + 0.024 * av)
	    }

	    # Deredden data.
	    call deredden (Memr[sx], Memr[SY(sh)], Memr[SY(sh)], n,
		av, rv, avold, rvold)
	    if (SC(sh) != NULL)
		call deredden (Memr[sx], Memr[SC(sh)], Memr[SC(sh)], n,
		    av, rv, avold, rvold)
	    if (SR(sh) != NULL)
		call deredden (Memr[sx], Memr[SR(sh)], Memr[SR(sh)], n,
		    av, rv, avold, rvold)

	    if (REG_MODIFIED(reg) != 'M') {
		REG_MODIFIED(reg) = 'M'
		call spt_rglist (spt, reg)
	    }
	    call spt_scale (spt, reg)
	    SPT_REDRAW(spt,1) = YES
	    SPT_REDRAW(spt,2) = YES

	    # Log operation.
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "# %s\n")
		call pargstr (REG_TITLE(reg))
	    call spt_log (spt, reg, "title", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "# deredden: %s\n")
		call pargstr (RC(sh))
	    call spt_log (spt, reg, "add", SPT_STRING(spt))

	default: # error or unknown command
err_	    call sfree (sp)
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in deredden command: deredden %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}

	call sfree (sp)
end
