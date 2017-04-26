include	<smw.h>
include	<funits.h>
include	"spectool.h"

# Commands
define	CMDS	"|open|close|set|measure|remeasure|units|funits|"
define	OPEN		1
define	CLOSE		2
define	SET		3	# Set parameters to measure
define	MEASURE		4	# Measure statistics
define	REMEASURE	5	# Remeasure statistics
define	UNITS		6	# Change coordinate units
define	FUNITS		7	# Change flux units

# Statistics
# stat1		 x     = Mean dispersion coordinate
# stat2		 n     = Number of pixels
# stat3		 S     = Mean of spectrum
# stat4		 N1    = Standard deviation about mean
# stat5		 N2    = Standard deviation about linear
# stat6		 N3    = Standard deviation about continuum
# stat7		 N4    = Standard deviation from poisson statistics
# stat8		 N5    = Mean of sigma spectrum
# stat9		 S/N1  = Signal to noise ratio
# stat10	 S/N2  = Signal to noise ratio
# stat11	 S/N3  = Signal to noise ratio
# stat12	 S/N4  = Signal to noise ratio
# stat13	 S/N5  = Signal to noise ratio
# stat14	 <S/N> = Mean of S/N from data and sigma spectra
define	NSTAT	14

# SPT_STAT -- Compute statistics of spectrum

procedure spt_stat (spt, reg, cmd, wx1, wy1, wx2, wy2)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
char	cmd			#I Command
real	wx1, wy1		#I First cursor position
real	wx2, wy2		#I Second cursor position

int	i, i1, i2, n, ncmd, stat[NSTAT]
double	x1, x2, di1, di2, w, z, sigma, sum[10], statval[NSTAT+2]
pointer	sp, str, gp, sh, x, y, c, e
bool	clgetb(), streq()
int	btoi(), strdic(), ctoi(), nscan()
double	shdr_wl(), shdr_lw()
errchk	fun_changed()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN:
	    stat[1] = btoi (clgetb ("x_stat"))
	    stat[2] = btoi (clgetb ("n_stat"))
	    stat[3] = btoi (clgetb ("S"))
	    stat[4] = btoi (clgetb ("N1"))
	    stat[5] = btoi (clgetb ("N2"))
	    stat[6] = btoi (clgetb ("N3"))
	    stat[7] = btoi (clgetb ("N4"))
	    stat[8] = btoi (clgetb ("N5"))
	    stat[9] = btoi (clgetb ("SN1"))
	    stat[10] = btoi (clgetb ("SN2"))
	    stat[11] = btoi (clgetb ("SN3"))
	    stat[12] = btoi (clgetb ("SN4"))
	    stat[13] = btoi (clgetb ("SN5"))
	    stat[14] = btoi (clgetb ("SN"))

	    do i = 1, 14 {
		call sprintf (Memc[str], SZ_LINE, "set stat%d %d")
		    call pargi (i)
		    call pargi (stat[i])
		call gmsg (SPT_GP(spt), "statSet", Memc[str])
	    }
	    call gmsg (SPT_GP(spt), "statval", "clear")
	    call amovkd (INDEFD, statval, NSTAT+2)

	case CLOSE:
	    call clputb ("x_stat", stat[1]==YES)
	    call clputb ("n_stat", stat[2]==YES)
	    call clputb ("S", stat[3]==YES)
	    call clputb ("N1", stat[4]==YES)
	    call clputb ("N2", stat[5]==YES)
	    call clputb ("N3", stat[6]==YES)
	    call clputb ("N4", stat[7]==YES)
	    call clputb ("N5", stat[8]==YES)
	    call clputb ("SN1", stat[9]==YES)
	    call clputb ("SN2", stat[10]==YES)
	    call clputb ("SN3", stat[11]==YES)
	    call clputb ("SN4", stat[12]==YES)
	    call clputb ("SN5", stat[13]==YES)
	    call clputb ("SN", stat[14]==YES)
	    
	case SET:
	    call gargwrd (Memc[str], SZ_LINE)
	    i = 5
	    if (ctoi (Memc[str], i, i1) == 0) {
		call sfree (sp)
		return
	    }
	    call gargi (i2)
	    stat[i1] = i2
	    call gmsg (SPT_GP(spt), "statSet", cmd)

	case MEASURE, REMEASURE:
	    if (ncmd == MEASURE) {
		call gargd (x1)
		call gargd (x2)
		if (nscan() < 3) {
		    if (IS_INDEFR(wx1))
			x1 = INDEFD
		    else
			x1 = wx1
		    if (IS_INDEFR(wx2))
			x2 = INDEFD
		    else
			x2 = wx2
		}
	    } else {
		x1 = statval[NSTAT+1]
		x2 = statval[NSTAT+2]
		if (IS_INDEFD(x1)) {
		    call sfree (sp)
		    return
		}
	    }
		
	    if (IS_INDEFD(x1) || IS_INDEFD(x2) || x1 == x2) {
		call sfree (sp)
		call error (1, "Statistics region is not defined")
	    }

	    gp = SPT_GP(spt)
	    sh = REG_SH(reg)
	    x = SX(sh)
	    y = SPEC(sh,SPT_CTYPE(spt))
	    c = SC(sh)
	    e = SE(sh)
	    n = SN(sh)

	    di1 = shdr_wl (sh, x1)
	    di2 = shdr_wl (sh, x2)
	    call sprintf (Memc[str], SZ_LINE, "%g %g %g %g")
		call pargd (x1)
		call pargd (x2)
		call pargd (di1)
		call pargd (di2)
	    i1 = max (1, nint (min (di1,di2) + 0.5))
	    i2 = min (n, nint (max (di1,di2) - 0.5))
	    if (i1 >= i2) {
		call sfree (sp)
		call error (1, "Statistics region outside data")
		return
	    }

	    call aclrd (sum, 10)
	    do i = i1, i2 {
		w = Memr[x+i-1]
		z = Memr[y+i-1]
		sum[1] = sum[1] + 1
		sum[2] = sum[2] + z
		sum[3] = sum[3] + z * z
		sum[4] = sum[4] + w
		sum[5] = sum[5] + w * w
		sum[6] = sum[6] + w * z
		sum[7] = sum[7] + max (0D0, z)
		if (c != NULL)
		    sum[8] = sum[8] + (z - Memr[c+i-1]) ** 2
		if (e != NULL) {
		    sigma = Memr[e+i-1]
		    sum[9] = sum[9] + sigma ** 2
		    if (sigma > 0.)
			sum[10] = sum[10] + z / sigma
		}
	    }
	    call adivkd (sum[2], sum[1], sum[2], 9)

	    call amovkd (INDEFD, statval, NSTAT+2)
	    if (stat[1] == YES)
		statval[1] = sum[4]
	    if (stat[2] == YES)
		statval[2] = sum[1]
	    if (stat[3] == YES)
		statval[3] = sum[2]
	    if (stat[4] == YES) {
		z = sum[3] - sum[2] * sum[2]
		if (z > 0.)
		    z = sqrt (z)
		else
		    z = INDEF
		statval[4] = z
	    }
	    if (stat[5] == YES) {
		z = (sum[6] - sum[4] * sum[2]) / (sum[5] - sum[4] * sum[4])
		z = sum[3] - sum[2] * sum[2] - z * (sum[6] - sum[4] * sum[2])
		if (z > 0.)
		    z = sqrt (z)
		else
		    z = INDEF
		statval[5] = z
	    }
	    if (stat[6] == YES) {
		z = sum[8]
		if (z > 0.)
		    z = sqrt (z)
		else
		    z = INDEF
		statval[6] = z
	    }
	    if (stat[7] == YES) {
		z = sum[7]
		if (z > 0.)
		    z = sqrt (z)
		else
		    z = INDEF
		statval[7] = z
	    }
	    if (stat[8] == YES) {
		z = sum[9]
		if (z > 0.)
		    z = sqrt (z)
		else
		    z = INDEF
		statval[8] = z
	    }
	    if (stat[9] == YES) {
		z = sum[3] - sum[2] * sum[2]
		if (z > 0.)
		    z = sum[2] / sqrt (z)
		else
		    z = INDEF
		statval[9] = z
	    }
	    if (stat[10] == YES) {
		z = (sum[6] - sum[4] * sum[2]) / (sum[5] - sum[4] * sum[4])
		z = sum[3] - sum[2] * sum[2] - z * (sum[6] - sum[4] * sum[2])
		if (z > 0.)
		    z = sum[2] / sqrt (z)
		else
		    z = INDEF
		statval[10] = z
	    }
	    if (stat[11] == YES) {
		z = sum[8]
		if (z > 0.)
		    z = sum[2] / sqrt (z)
		else
		    z = INDEF
		statval[11] = z
	    }
	    if (stat[12] == YES) {
		z = sum[7]
		if (z > 0.)
		    z = sum[2] / sqrt (z)
		else
		    z = INDEF
		statval[12] = z
	    }
	    if (stat[13] == YES) {
		z = sum[9]
		if (z > 0.)
		    z = sum[2] / sqrt (z)
		else
		    z = INDEF
		statval[13] = z
	    }
	    if (stat[14] == YES) {
		z = sum[10]
		if (z > 0.)
		    z = sum[10]
		else
		    z = INDEF
		statval[14] = z
	    }
	    statval[NSTAT+1] = x1
	    statval[NSTAT+2] = x2

	    call statlog (spt, reg, statval)
	case UNITS: # units [logical|world]
	    call gargwrd (Memc[str], SZ_LINE)

	    if (IS_INDEFD (statval[NSTAT+1]) || reg == NULL)
		return
	    sh = REG_SH(reg)
	    if (sh == NULL)
		return

	    if (streq (Memc[str], "logical")) {
		if (!IS_INDEFD (statval[1]))
		    statval[1] = shdr_wl (sh, statval[1])
		if (!IS_INDEFD (statval[NSTAT+1]))
		    statval[NSTAT+1] = shdr_wl (sh, statval[NSTAT+1])
		if (!IS_INDEFD (statval[NSTAT+2]))
		    statval[NSTAT+2] = shdr_wl (sh, statval[NSTAT+2])
	    } else if (streq (Memc[str], "world")) {
		if (!IS_INDEFD (statval[1]))
		    statval[1] = shdr_lw (sh, statval[1])
		if (!IS_INDEFD (statval[NSTAT+1]))
		    statval[NSTAT+1] = shdr_lw (sh, statval[NSTAT+1])
		if (!IS_INDEFD (statval[NSTAT+2]))
		    statval[NSTAT+2] = shdr_lw (sh, statval[NSTAT+2])
	    }
	case FUNITS: # funits [units]
	    call gargstr (Memc[str], SZ_LINE)

	    if (IS_INDEFD (statval[NSTAT+1]) || reg == NULL)
		return
	    sh = REG_SH(reg)
	    if (sh == NULL)
		return

	    if (streq (Memc[str], "default"))
		call strcpy (FUN_USER(FUNIM(sh)), Memc[str], SZ_LINE)

	    w = (statval[NSTAT+1] + statval[NSTAT+2]) / 2.
	    do i = 3, 8 {
		if (!IS_INDEFD(statval[i]))
		    call fun_changed (FUN(sh), Memc[str], UN(sh), w,
			statval[i], 1, NO)
	    }
	    call statlog (spt, reg, statval)
	}

	call sfree (sp)
end


# STATLOG - Print statistics results to gui, status line, and log file.

procedure statlog (spt, reg, statval)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
double	statval[ARB]		#I Statistics values

int	i, fd1, fd2, fd3, stropen()
pointer	sp, hdr, str, msg, gp

begin
	if (reg == NULL)
	    return

	do i = 1, NSTAT+2
	    if (!IS_INDEFD(statval[i]))
	       break
	if (i > NSTAT+2)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (hdr, SZ_LINE, TY_CHAR)
	call salloc (msg, SZ_LINE, TY_CHAR)

	gp = SPT_GP(spt)

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "# %s\n")
	    call pargstr (REG_TITLE(reg))
	call spt_log (spt, reg, "title", SPT_STRING(spt))

	fd1 = stropen (Memc[str], SZ_LINE, WRITE_ONLY)
	fd2 = stropen (Memc[hdr], SZ_LINE, WRITE_ONLY)
	fd3 = stropen (SPT_STRING(spt), SPT_SZSTRING, WRITE_ONLY)
	call fprintf (fd2, "# ")
	call fprintf (fd3, "  ")
	call gmsg (gp, "statval", "clear")
	if (!IS_INDEFD(statval[NSTAT+1])) {
	    call fprintf (fd2, "%11s ")
		call pargstr ("x1")
	    call fprintf (fd3, "%11.7g ")
		call pargd (statval[NSTAT+1])
	    call sprintf (Memc[msg], SZ_LINE, "statX1 %.8g")
		call pargd (statval[NSTAT+1])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[NSTAT+2])) {
	    call fprintf (fd2, "%11s ")
		call pargstr ("x2")
	    call fprintf (fd3, "%11.7g ")
		call pargd (statval[NSTAT+2])
	    call sprintf (Memc[msg], SZ_LINE, "statX2 %.8g")
		call pargd (statval[NSTAT+2])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[1])) {
	    call fprintf (fd1, "x=%.7g ")
		call pargd (statval[1])
	    call fprintf (fd2, "%11s ")
		call pargstr ("x")
	    call fprintf (fd3, "%11.7g ")
		call pargd (statval[1])
	    call sprintf (Memc[msg], SZ_LINE, "stat1val %.8g")
		call pargd (statval[1])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[2])) {
	    call fprintf (fd1, "n=%d ")
		call pargd (statval[2])
	    call fprintf (fd2, "%6s ")
		call pargstr ("n")
	    call fprintf (fd3, "%6d ")
		call pargd (statval[2])
	    call sprintf (Memc[msg], SZ_LINE, "stat2val %d")
		call pargd (statval[2])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[3])) {
	    call fprintf (fd1, "S=%.5g ")
		call pargd (statval[3])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[3])
	    call sprintf (Memc[msg], SZ_LINE, "stat3val %.8g")
		call pargd (statval[3])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[4])) {
	    call fprintf (fd1, "N1=%.5g ")
		call pargd (statval[4])
	    call fprintf (fd2, "%11s ")
		call pargstr ("N1")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[4])
	    call sprintf (Memc[msg], SZ_LINE, "stat4val %.8g")
		call pargd (statval[4])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[5])) {
	    call fprintf (fd1, "N2=%.5g ")
		call pargd (statval[5])
	    call fprintf (fd2, "%11s ")
		call pargstr ("N2")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[5])
	    call sprintf (Memc[msg], SZ_LINE, "stat5val %.8g")
		call pargd (statval[5])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[6])) {
	    call fprintf (fd1, "N3=%.5g ")
		call pargd (statval[6])
	    call fprintf (fd2, "%11s ")
		call pargstr ("N3")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[6])
	    call sprintf (Memc[msg], SZ_LINE, "stat6val %.8g")
		call pargd (statval[6])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[7])) {
	    call fprintf (fd1, "N4=%.5g ")
		call pargd (statval[7])
	    call fprintf (fd2, "%11s ")
		call pargstr ("N4")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[7])
	    call sprintf (Memc[msg], SZ_LINE, "stat7val %.8g")
		call pargd (statval[7])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[8])) {
	    call fprintf (fd1, "N5=%.5g ")
		call pargd (statval[8])
	    call fprintf (fd2, "%11s ")
		call pargstr ("N5")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[8])
	    call sprintf (Memc[msg], SZ_LINE, "stat8val %.8g")
		call pargd (statval[8])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[9])) {
	    call fprintf (fd1, "S/N1=%.5g ")
		call pargd (statval[9])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S/N1")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[9])
	    call sprintf (Memc[msg], SZ_LINE, "stat9val %.8g")
		call pargd (statval[9])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[10])) {
	    call fprintf (fd1, "S/N2=%.5g ")
		call pargd (statval[10])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S/N2")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[10])
	    call sprintf (Memc[msg], SZ_LINE, "stat10val %.8g")
		call pargd (statval[10])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[11])) {
	    call fprintf (fd1, "S/N3=%.5g ")
		call pargd (statval[11])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S/N3")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[11])
	    call sprintf (Memc[msg], SZ_LINE, "stat11val %.8g")
		call pargd (statval[11])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[12])) {
	    call fprintf (fd1, "S/N4=%.5g ")
		call pargd (statval[12])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S/N4")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[12])
	    call sprintf (Memc[msg], SZ_LINE, "stat12val %.8g")
		call pargd (statval[12])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[13])) {
	    call fprintf (fd1, "S/N5=%.5g ")
		call pargd (statval[13])
	    call fprintf (fd2, "%11s ")
		call pargstr ("S/N5")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[13])
	    call sprintf (Memc[msg], SZ_LINE, "stat13val %.8g")
		call pargd (statval[13])
	    call gmsg (gp, "statval", Memc[msg])
	}
	if (!IS_INDEFD(statval[14])) {
	    call fprintf (fd1, "<S/N>=%.5g ")
		call pargd (statval[14])
	    call fprintf (fd2, "%11s ")
		call pargstr ("<S/N>")
	    call fprintf (fd3, "%11.5g ")
		call pargd (statval[14])
	    call sprintf (Memc[msg], SZ_LINE, "stat14val %.8g")
		call pargd (statval[14])
	    call gmsg (gp, "statval", Memc[msg])
	}
	call fprintf (fd1, "\n")
	call fprintf (fd2, "\n")
	call fprintf (fd3, "\n")
	call close (fd1)
	call close (fd2)
	call close (fd3)

	call printf (Memc[str])
	call spt_log (spt, reg, "header", Memc[hdr])
	call spt_log (spt, reg, "add", SPT_STRING(spt))

	call sfree (sp)
end
