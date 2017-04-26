include	<error.h>
include	<smw.h>
include	<units.h>
include	<funits.h>
include	"spectool.h"
include	"lids.h"

#	0	Initialize
#	:	Colon commands
#	q	Quit
#	?	Help
#	i       Cursor info
#	<space>	Screen print
#	r	Redraw
#	u	Undo
#
#	a	All toggle
#	b	Bandpass limit
#	c	Continuum (draw)
#	d	Delete line
#	e	Equivalent width
#	f	Fit line
#	l	Label line
#	m	Mark a line
#	p	Subtract line profile
#
#	j	Previous spectrum
#	k	Next spectrum
#	s	Statistics
#	t	Draw continuum
#	u	Undo
#	v	Velocity units
#	x	Interpolate
#	y	Draw spectrum
#	z	Zap cosmic ray

# Unused:
#	g
#	h
#	n
#	o
#	w


procedure spt_key (spt, reg, gp, wx, wy, wcs, key, cmd)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Current register pointer
pointer	gp			#I GIO pointer
real	wx, wy			#U Cursor coordinate
int	wcs			#U WCS
int	key			#U Cursor key
char	cmd[SZ_LINE]		#U Command

char	str[SZ_LINE]
int	i, j, k, rgitem, spitem, imitem, ap
double	dwx, dwy
real	x, y
pointer	sh, lid, ptr

bool	clgetb(), spt_getitem(), streq()
int	clgeti(), ctowrd(), ctoi(), clgcur(), btoi()
double	shdr_wl()
errchk	spt_imlist, spt_flist, spt_getitem, spt_colon, spt_edit
errchk	spt_reg, spt_eqwidth, spt_ctr, mod_colon, lid_colon, lid_nearest

define	newkey_ 10

begin

newkey_
	dwx = wx
	dwy = wy
	if (IS_INDEF(wx))
	    dwx = INDEFD
	if (IS_INDEF(wy))
	    dwy = INDEFD
	switch (key) {
	case 0: # Initialize
	    if (clgeti ("$nargs") > 0) {
		call clgstr ("spectrum", str, SZ_LINE)
		call spt_imlist (spt, str, SPT_IMTMP(spt))
		call sprintf (cmd, SZ_LINE, "read %s")
		    call pargstr (str)
		iferr (call spt_colon (spt, reg, wx, wy, cmd)) {
		    call gmsg (gp, "setGui", "read")
		    call erract (EA_ERROR)
		}
	    } else
		call gmsg (gp, "setGui", "read")

	case 'q': # Quit
	    if (SPT_GUI(spt) == YES)
		if (!clgetb ("qkey"))
		    key = 0

	case ':': # Colon commands.
	    if  (streq (cmd, "q") || streq (cmd, "quit"))
		key = 'q'
	    else
		call spt_colon (spt, reg, wx, wy, cmd)

	case '?': # Page help summary
	    call spt_help (spt, "show keys")

	case 'a': # All flag
	    SPT_LIDSALL(spt) = btoi (SPT_LIDSALL(spt)==NO)
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "lidsall %d")
		call pargi (SPT_LIDSALL(spt))
	    call gmsg (gp, "setGui", SPT_STRING(spt))

	case 'b': # bandpass limit
	    call lid_nearest (spt, reg, dwx, dwy, lid)
	    if (lid == NULL)
		return

	    x = dwx - LID_X(lid)
	    if (SPT_LIDSALL(spt) == YES) {
		call sprintf (cmd, SZ_LINE, "bandpass -1 %g")
		    call pargr (x)
	    } else {
		call sprintf (cmd, SZ_LINE, "bandpass %d %g")
		    call pargi (LID_ITEM(lid))
		    call pargr (x)
	    }
	    call lid_colon (spt, reg, dwx, dwy, cmd)

	case 'd': # delete label
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd, SZ_LINE, "delete")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd, SZ_LINE, "delete %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call lid_colon (spt, reg, dwx, dwy, cmd)

	case 'e': # equivalent width
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd, SZ_LINE, "eqwidth")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd, SZ_LINE, "eqwidth %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call spt_eqwidth (spt, reg, wx, wy, cmd)

	case 'f': # fit profile
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd, SZ_LINE, "fit")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd, SZ_LINE, "fit %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call mod_colon (spt, reg, dwx, dwy, cmd)

	case 'j', 'k': # Next/Previous

	    ptr = reg
	    call spt_gitems (spt, ptr, rgitem, spitem, imitem)
	    if (spitem >= 0) {
		if (key == 'j')
		    spitem = spitem + 1
		else
		    spitem = spitem - 1
		if (spt_getitem (SPLIST(spt), spitem, cmd, SZ_LINE)) {
		    i = 1
		    j = ctowrd (cmd, i, str, SZ_LINE)
		    j = ctoi (cmd, i, ap)
		    call sprintf (cmd, SZ_LINE,
			"pload anynew %s %d INDEF INDEF INDEF")
			call pargstr (str)
			call pargi (ap)
		    call spt_reg (spt, reg, cmd)
		}
	    }

#	case 'i': # identify lines from a line list
#	    if (SPT_LIDSALL(spt) == YES)
#		call sprintf (cmd, SZ_LINE, "identify")
#	    else {
#		call lid_nearest (spt, reg, dwx, dwy, lid)
#		call sprintf (cmd, SZ_LINE, "identify %d")
#		    call pargi (LID_ITEM(lid))
#	    }
#	    call ll_colon (spt, reg, dwx, dwy, cmd)

	case 'l': # label lines
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd, SZ_LINE, "label")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd, SZ_LINE, "label %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call lid_colon (spt, reg, dwx, dwy, cmd)

	case 'm': # mark a feature
	    call spt_colon (spt, reg, wx, wy, "line")

	case 'p': # subtract/add profile
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd, SZ_LINE, "subtract")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd, SZ_LINE, "subtract %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call mod_colon (spt, reg, dwx, dwy, cmd)

	case 'r': # Redraw the current graph
	    SPT_REDRAW(spt,1) = YES
	    SPT_REDRAW(spt,2) = YES

	case 's': # statistics
	    call printf ("use s for second limit or any other key to cancel")
	    i = clgcur ("cursor", x, y, j, k, cmd, SZ_LINE)
	    call gctran (gp, x, y, x, y, j, 1)
	    if (k == key) {
		call printf ("\n")
		call spt_stat (spt, reg, "measure", wx, wy, x, y)
	    } else {
		call printf ("s: canceled")
	    }

	case 'c', 'x', 'y', 'z':
	    if (key == 'c')
		i = SHCONT
	    else
		i = SPT_CTYPE(spt)
	    call spt_edit (spt, reg, i, gp, wx, wy, wcs, key, cmd)
	    goto newkey_

	case 'u': # undo
	    call spt_colon (spt, reg, wx, wy, "undo")

	case 'v': # velocity
	    if (reg != NULL) {
		sh = REG_SH(reg)
		if (UN_CLASS(UN(sh)) == UN_VEL) {
		    call un_changer (UN(sh), "angstroms", wx, 1, NO)
		    call sprintf (cmd, SZ_LINE, "km/s %g %s")
			call pargr (wx)
			call pargstr ("angstroms")
		} else {
		    call sprintf (cmd, SZ_LINE, "km/s %g %s")
			call pargr (wx)
			call pargstr (UN_UNITS(UN(REG_SH(reg))))
		}
		call spt_units (spt, reg, cmd)
	    }

	case '.': # Screen print.
	    call gmsg (gp, "output", "screen")

	case 'i': # Report cursor info
	    if (reg != NULL) {
		sh = REG_SH(reg)
		i = max (1, min (SN(sh), nint(shdr_wl(sh, dwx))))
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "%10.6g %s %10.6g %s %10d %10.6g")
		    call pargr (wx)
		    call pargstr (UN_UNITS(UN(sh)))
		    call pargr (wy)
		    call pargstr (FUN_UNITS(FUN(sh)))
		    call pargi (i)
		    call pargr (Memr[SPEC(sh,SPT_CTYPE(spt))+i-1])
	    } else {
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "%10.6g %10.6g")
		    call pargr (wx)
		    call pargr (wy)
	    }
	    call gmsg (gp, "coord", SPT_STRING(spt))
	    call printf (SPT_STRING(spt))

	default: # Unrecognized key.
	    call sprintf (cmd, SZ_LINE,
		"(1) Unrecognized key: %g %g %d %c")
		call pargr (wx)
		call pargr (wy)
		call pargi (wcs)
		call pargi (key)
	    call error (1, cmd)
	}
end
