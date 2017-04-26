include	<ctype.h>
include	<error.h>
include	<imhdr.h>
include	<smw.h>
include	<units.h>
include	<gset.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"lids.h"

# List of colon commands.
define	COLONCMDS "|help|open|register|read|images|errclear|region\
		   |pan|display|color|scale|offset|stck|clip|xflip|yflip\
		   |icfit|coord|units|funits|title|xlabel|ylabel|xunits|yunits\
		   |gtuivalues|redraw|slabel|glabel|label|lids|log|save|restore\
		   |smooth|arith|sarith|xxx|plot|wcs|model|roam|clist|yyyy\
		   |stat|write|deredden|rv|center|eqwidth|overplot|stack\
		   |spectrum|continuum|raw|sky|sigma|labels|lines|undo\
		   |Continuum|reference|lower|upper|profile|identification\
		   |ll|ctr|sigclip|line|files|velocity|zero|errors|screen|"

define	HELP		1	# Help
define	OPEN		2	# Open image
define	REGISTER	3	# Register command
define	READ		4	# Read a spectrum
define	IMAGES		5	# Image list
define	ERRCLEAR	6	# Clear errors?
define	REGION		7	# Region to expand
define	PAN		8	# Use panner?
define	DISPLAY		9	# Display imges?
define	STCK		13	# Stacking command
define	CLIP		14	# Clipping factors
define	XFLIP		15	# X flip
define	YFLIP		16	# Y flip
define	ICFIT		17	# Fit spectrum with ICFIT
define	COORD		18	# Adjust coordinates
define	UNIT		19	# Units
define	FUNIT		20	# Flux units
define	TITLE		21	# Title
define	XLABEL		22	# X label
define	YLABEL		23	# Y label
define	XUNITS		24	# X label
define	YUNITS		25	# Y label
define	GTUIVALUES	26	# Set graph UI values
define	REDRAW		27	# Redraw
define	SLABEL		28	# Spectrum label
define	GLABEL		29	# Graph label
define	LABEL		30	# Label command
define	LIDS		31	# Line IDs command
define	LOG		32	# Log
define	SAVE		33	# Save current spectrum
define	RESTORE		34	# Restore original spectrum
define	SMOOTH		35	# Smooth spectrum
define	ARITH		36	# Spectrum arithmetic
define	SARITH		37	# Spectrum arithmetic
#define	XXX		38	# Unused
define	PLOT		39	# Plot commands
define	WCS		40	# Set WCS
define	MODEL		41	# Model command
define	ROAM		42	# Roam
define	CLIST		43	# Color list
define	STAT		45	# Spectrum statistics
define	WRITE		46	# Write spectrum
define	DEREDDEN	47	# Deredden spectrum
define	RV		48	# Radial velocities
define	CENTER		49	# Centering
define	EQWIDTH		50	# Equivalent widths
define	OVRPLT		51	# Overplot?
define	STACK		52	# Stack?
define	PSPEC		53	# Plot spectrum
define	PCONT		54	# Plot continuum
define	PRAW		55	# Plot raw
define	PSKY		56	# Plot sky
define	PSIG		57	# Plot sigma
define	LABELS		58	# Plot labels
define	LINES		59	# Plot lines
define	UNDO		60	# Undo last change
define	CONT		61	# Continuum commands
define	REFERENCE	62	# Set line reference
define	LOW		63	# Lower bandpass limit
define	UP		64	# Upper bandpass limit
define	PROF		65	# Line profile
define	ID		66	# Line identification
define	LL		67	# Line list
define	CTR		68	# Center commands
define	SIGCLIP		69	# Sigma clip
define	LINE		70	# Define a line
define	FILES		71	# Get list of files
define	VELOCITY	72	# Compute velocity
define	ZERO		73	# Force zero level
define	ERRORS		74	# Error parameters

# SPT_COLON -- Interpret colon commands.

procedure spt_colon (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#U Register pointer
real	wx, wy			#I GIO coordinate
char	cmd[ARB]		#I GIO command

char	cmd1[SZ_LINE], cmd2[SZ_LINE]
bool	bval
int	i, ival, stype, stype1, stype2, ncmd
real	rval, scale, offset, x, y
double	dwx, dwy, dval
pointer	reg1, reg2, im, mw, sh, gp, gt, lid
pointer	sp, str1, str2

real	gt_getr()
int	strdic(), nscan(), btoi()
bool	clgetb()
pointer	spt_gp()
errchk	gt_colon, spt_splist, spt_coord
errchk	spt_units, spt_funits, spt_log, spt_smooth
errchk	spt_icfit, spt_arith, spt_smooth, spt_gp, spt_wrspect
errchk	spt_dered, spt_reg, spt_plotcolon
errchk	spt_flist, spt_imlist, spt_current, spt_regname, spt_cont
errchk	lid_nearest, lid_colon, spt_rv

define	err_	10

begin
	call smark (sp)
	call salloc (str1, SZ_LINE, TY_CHAR)
	call salloc (str2, SZ_LINE, TY_CHAR)

	dwx = wx
	dwy = wy

	gp = SPT_GP(spt)
	gt = SPT_GT(spt)
	
	# Check for special commands.
	if (cmd[1] == '/') {
	    call gt_colon (cmd, gp, gt, SPT_REDRAW(spt,1))
	    SPT_REDRAW(spt,2) = SPT_REDRAW(spt,1)
	    call sfree (sp)
	    return
	}

	# Determine input spectrum.
	stype = SPT_CTYPE(spt)
	call strcpy (cmd, cmd1, SZ_LINE)
	call sscan (cmd1)
	call gargwrd (cmd2, SZ_LINE)
	if (nscan() == 1 && cmd2[1] == '%') {
	    call gargstr (cmd1, SZ_LINE)
	    call spt_regname (spt, reg, stype, cmd2, reg1, stype1)
	} else
	    call spt_regname (spt, reg, stype, ".", reg1, stype1)

	# Determine output spectrum.
	call sscan (cmd1)
	call gargwrd (cmd2, SZ_LINE)
	if (nscan() == 1 && cmd2[1] == '%') {
	    call gargstr (cmd1, SZ_LINE)
	    call spt_regname (spt, reg1, stype1, cmd2, reg2, stype2)
	} else
	    call spt_regname (spt, reg1, stype1, ".", reg2, stype2)

	# Get command.
	call sscan (cmd1)
	call gargwrd (cmd2, SZ_LINE)
	ncmd = strdic (cmd2, cmd2, SZ_LINE, COLONCMDS)

	switch (ncmd) {
	case HELP: # help command
	    call gargstr (cmd2, SZ_LINE)
	    call spt_help (spt, cmd2)

	case OPEN: # open image
	    call gargwrd (Memc[str1], SZ_LINE)

	    im = NULL
	    mw = NULL
	    sh = NULL
	    call spt_splist (spt, Memc[str1], im, mw, sh)

	    if (sh != NULL)
		call shdr_close (sh)
	    if (mw != NULL)
		call smw_close (mw)
	    if (im != NULL)
		call imunmap (im)

	case REGISTER: # register cmd
	    call gargstr (cmd2, SZ_LINE)
	    call spt_reg (spt, reg, cmd2)

	case READ: # read image [ap] [band]
	    call gargstr (Memc[str2], SZ_LINE)

	    call sscan (Memc[str2])
	    call gargwrd (Memc[str1], SZ_LINE)

	    im = NULL
	    mw = NULL
	    sh = NULL
	    call spt_splist (spt, Memc[str1], im, mw, sh)

	    if (sh != NULL)
		call shdr_close (sh)
	    if (mw != NULL)
		call smw_close (mw)
	    if (im != NULL)
		call imunmap (im)

	    call sprintf (Memc[str1], SZ_LINE, "pload anynew %s")
		call pargstr (Memc[str2])
	    call spt_reg (spt, reg, Memc[str1])

	case IMAGES:	# images directory template
	    call gargwrd (Memc[str1], SZ_LINE)
	    call gargstr (Memc[str2], SZ_LINE)
	    call spt_imlist (spt, Memc[str1], Memc[str2])
	    call spt_flist (spt, SPT_DIR(spt), SPT_FTMP(spt))
	    call spt_current (spt, reg)

	case FILES:	# files directory template
	    call gargwrd (Memc[str1], SZ_LINE)
	    call gargstr (Memc[str2], SZ_LINE)
	    call spt_flist (spt, Memc[str1], Memc[str2])
	    call spt_imlist (spt, SPT_DIR(spt), SPT_IMTMP(spt))

	case ERRCLEAR:	# errclear y/n
	    call gargb (bval)
	    if (nscan() > 1)
		SPT_ERRCLEAR(spt) = btoi (bval)

	case REGION: # region wcs x1 x2 y1 y2
	    call gargi (ival)
	    call gargr (rval)
	    if (rval !=  gt_getr (gt, GTXMIN)) {
		call gt_setr (gt, GTXMIN, rval)
		SPT_REDRAW(spt,1) = YES
	    }
	    call gargr (rval)
	    if (rval !=  gt_getr (gt, GTXMAX)) {
		call gt_setr (gt, GTXMAX, rval)
		SPT_REDRAW(spt,1) = YES
	    }
	    call gargr (rval)
	    if (rval !=  gt_getr (gt, GTYMIN)) {
		call gt_setr (gt, GTYMIN, rval)
		SPT_REDRAW(spt,1) = YES
	    }
	    call gargr (rval)
	    if (rval !=  gt_getr (gt, GTYMAX)) {
		call gt_setr (gt, GTYMAX, rval)
		SPT_REDRAW(spt,1) = YES
	    }

	case ROAM: # roam wcs x y
	    call gargi (ival)
	    call gargr (rval)
	    x = gt_getr (gt, GTXMIN)
	    y = gt_getr (gt, GTXMAX)
	    if (!IS_INDEF(x) && !IS_INDEF(y)) {
		scale = y - x
		offset = rval - (x + y) / 2
		if (abs (offset / scale) > 0.001) {
		    call gt_setr (gt, GTXMIN, x + offset)
		    call gt_setr (gt, GTXMAX, y + offset)
		}
		SPT_REDRAW(spt,1) = YES
	    }
		
	    call gargr (rval)
	    x = gt_getr (gt, GTYMIN)
	    y = gt_getr (gt, GTYMAX)
	    if (IS_INDEF(rval)) {
		if (!IS_INDEF(x) || !IS_INDEF(y)) {
		    call gt_setr (gt, GTYMIN, INDEF)
		    call gt_setr (gt, GTYMAX, INDEF)
		    SPT_REDRAW(spt,1) = YES
		}
	    } else {
		if (!IS_INDEF(x) && !IS_INDEF(y)) {
		    scale = y - x
		    offset = rval - (x + y) / 2
		    if (abs (offset / scale) > 0.001) {
			call gt_setr (gt, GTYMIN, x + offset)
			call gt_setr (gt, GTYMAX, y + offset)
		    }
		    SPT_REDRAW(spt,1) = YES
		}
	    }

	case PAN: # pan [yes|no]
	    call spt_plotcolon (spt, reg, cmd1)

	case STCK: # stck cmd1
	    call gargstr (cmd2, SZ_LINE)
	    call spt_stack (spt, cmd2)
	    
	case CLIP: # Clipping factors
	    call gargr (scale)
	    call gargr (offset)
	    if (nscan() < 3) {
		call printf ("clip %g %g\n")
		    call pargr (SPT_LCLIP(spt))
		    call pargr (SPT_HCLIP(spt))
		return
	    }
	    if (scale == SPT_LCLIP(spt) && offset == SPT_HCLIP(spt))
		return

	    SPT_LCLIP(spt) = scale
	    SPT_HCLIP(spt) = offset

	    do i = 1, SPT_NREG(spt)
		call spt_scale (spt, REG(spt,i))

	    SPT_REDRAW(spt,1) = YES
	    SPT_REDRAW(spt,2) = YES

	case COORD:
	    call gargstr (cmd2, SZ_LINE)
	    call spt_coord (spt, reg, cmd2)

	case UNIT:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call spt_units (spt, reg, cmd2[ival])

	case FUNIT:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call spt_funits (spt, reg, cmd2[ival])

	case TITLE:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call strcpy (cmd2[ival], SPT_TITLE(spt), SPT_SZLINE)

	case XLABEL:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call strcpy (cmd2[ival], SPT_XLABEL(spt), SPT_SZLINE)

	case YLABEL:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call strcpy (cmd2[ival], SPT_YLABEL(spt), SPT_SZLINE)

	case XUNITS:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call strcpy (cmd2[ival], SPT_XUNITS(spt), SPT_SZLINE)

	case YUNITS:
	    call gargstr (cmd2, SZ_LINE)
	    for (ival=1; IS_WHITE(cmd2[ival]); ival=ival+1)
		;
	    call strcpy (cmd2[ival], SPT_YUNITS(spt), SPT_SZLINE)

	case GTUIVALUES:
	    call gargb (bval)
	    if (bval) {
		call greset (gp, GR_RESETALL)
		call gt_ireset (gp, gt)
		call gt_seti (gt, GTSYSID, btoi (clgetb ("sysid")))
		call clgstr ("title", SPT_TITLE(spt), SZ_LINE)
		call clgstr ("xlabel", SPT_XLABEL(spt), SZ_LINE)
		call clgstr ("ylabel", SPT_YLABEL(spt), SZ_LINE)
		call clgstr ("dunits", SPT_UNITS(spt), SPT_SZLINE)
		call clgstr ("funits", SPT_FUNITS(spt), SPT_SZLINE)
		call gt_sets (gt, GTTYPE, "line1")
		call gt_setr (gt, GTVXMIN, 0.15)
		call gt_setr (gt, GTVXMAX, 0.95)
		call gt_setr (gt, GTVYMIN, 0.15)
		call gt_setr (gt, GTVYMAX, 0.90)
		call gt_seti (gt, GTCOLOR, 1)
		call gt_sets (gt, GTTYPE, "line1")
		call gt_setr (gt, GTXSIZE, 2.)
		call gt_setr (gt, GTYSIZE, 2.)
	    }

	    call gt_uivalues (gp, gt)
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "title \"%s\"")
		call pargstr (SPT_TITLE(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "xlabel \"%s\"")
		call pargstr (SPT_XLABEL(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "xunits \"%s\"")
		call pargstr (SPT_XUNITS(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "ylabel \"%s\"")
		call pargstr (SPT_YLABEL(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "yunits \"%s\"")
		call pargstr (SPT_YUNITS(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "etype \"%s\"")
		call pargstr (SPT_ETYPE(spt)) 
	    call gmsg (gp, "setGui", SPT_STRING(spt))

	case LIDS:
	    call gargstr (cmd2, SZ_LINE)
	    if (reg != NULL)
		call lid_colon (spt, reg, dwx, dwy, cmd2)

	case REFERENCE, ID:
	    call lid_colon (spt, reg, dwx, dwy, cmd1)

	case LINE:
	    call gargd (dwx)
	    if (nscan() != 2)
		dwx = wx
	    call lid_colon (spt, reg, dwx, dwy, "line")
	
	case LOW, UP:
	    call gargd (dval)
	    if (nscan() != 2)
		goto err_
	    call lid_nearest (spt, reg, dwx, dwy, lid)
	    if (lid != NULL) {
		if (ncmd == LOW) {
		    call sprintf (cmd1, SZ_LINE, "bandpass %d %g INDEF")
			call pargi (LID_ITEM(lid))
			call pargd (dval)
		} else {
		    call sprintf (cmd1, SZ_LINE, "bandpass %d INDEF %g")
			call pargi (LID_ITEM(lid))
			call pargd (dval)
		}
		call lid_colon (spt, reg, dwx, dwy, cmd1)
	    }

	case PROF:
	    call mod_colon (spt, reg, dwx, dwy, cmd1)

	case LABEL:
	    call gargstr (cmd2, SZ_LINE)
	    call lab_colon (spt, reg, dwx, dwy, cmd2)

	case SLABEL, GLABEL:
	    call lab_colon (spt, reg, dwx, dwy, cmd1)

	case LOG: # log
	    call gargwrd (cmd2, SZ_LINE)
	    call gargstr (Memc[str1], SZ_LINE)
	    if (Memc[str1] == ' ')
		call spt_log (spt, reg, cmd2, Memc[str1+1])
	    else
		call spt_log (spt, reg, cmd2, Memc[str1])

	case SAVE:
	    if (reg1 != NULL)
		call spt_shcopy (REG_SH(reg1), REG_SHSAVE(reg1), YES)

	case RESTORE:
	    if (reg1 != NULL) {
		if (REG_SHSAVE(reg1) != NULL) {
		   call spt_shcopy (REG_SH(reg1), REG_SHBAK(reg1), YES)
		   call spt_runits (spt, reg1, 1, YES)
		   call spt_shcopy (REG_SHSAVE(reg1), REG_SH(reg1), YES)
		   call spt_runits (spt, reg1, 2, YES)
		   call spt_scale (spt, reg1)
		   SPT_REDRAW(spt,1) = YES
		   SPT_REDRAW(spt,2) = YES
		}
	    }

	case UNDO:
	    if (reg1 != NULL) {
	       if (REG_SHBAK(reg1) != NULL) {
		   sh = NULL
		   call spt_shcopy (REG_SH(reg1), sh, YES)
		   call spt_runits (spt, reg1, 1, YES)
		   call spt_shcopy (REG_SHBAK(reg1), REG_SH(reg1), YES)
		   call spt_runits (spt, reg1, 2, YES)
		   call shdr_close (REG_SHBAK(reg1))
		   REG_SHBAK(reg1) = sh
		   call spt_scale (spt, reg1)
		   SPT_REDRAW(spt,1) = YES
		   SPT_REDRAW(spt,2) = YES
		} else if (REG_SHSAVE(reg1) != NULL) {
		   call spt_shcopy (REG_SH(reg1), REG_SHBAK(reg1), YES)
		   call spt_runits (spt, reg1, 1, YES)
		   call spt_shcopy (REG_SHSAVE(reg1), REG_SH(reg1), YES)
		   call spt_runits (spt, reg1, 2, YES)
		   call spt_scale (spt, reg1)
		   SPT_REDRAW(spt,1) = YES
		   SPT_REDRAW(spt,2) = YES
		}
	    }

	case ICFIT:
	    call gargstr (cmd2, SZ_LINE)
	    call spt_icfit (spt, reg1, stype1, reg2, stype2, cmd2) 

	case SMOOTH: # Smooth spectrum
	    call gargstr (cmd2, SZ_LINE)
	    call spt_smooth (spt, reg1, stype1, reg2, stype2, cmd2)

	case ARITH: # arith cmd1
	    call spt_arith (spt, reg, cmd1)

	case SARITH: # sarith cmd1
	    call gargstr (cmd2, SZ_LINE)
	    call spt_arith (spt, reg, cmd2)

	case WCS: # wcs value
	    call gargi (ival)
	    if (nscan() == 2)
		gp = spt_gp (spt, ival)

	case MODEL:
	    call gargstr (cmd2, SZ_LINE)
	    call mod_colon (spt, reg, dwx, dwy, cmd2)

	case CLIST:
	    do i = 0, 9
		call gargwrd (SPT_COLORS(spt,i), SPT_SZTYPE)

	case STAT:
	    call gargstr (cmd2, SZ_LINE)
	    call spt_stat (spt, reg, cmd2, INDEFR, INDEFR, INDEFR, INDEFR)

	case WRITE:
	    call spt_wrspect (spt, reg1, cmd1)

	case DEREDDEN: # deredden cmd1
	    call gargstr (cmd2, SZ_LINE)
	    call spt_deredden (spt, reg, cmd2)

	case RV, VELOCITY: # rv cmd1
	    if (ncmd == RV) {
		call gargstr (cmd2, SZ_LINE)
		call spt_rv (spt, reg, cmd2)
	    } else
		call spt_rv (spt, reg, cmd1)

	case CENTER: # center
	    if (SPT_LIDSALL(spt) == YES)
		call sprintf (cmd1, SZ_LINE, "center")
	    else {
		call lid_nearest (spt, reg, dwx, dwy, lid)
		call sprintf (cmd1, SZ_LINE, "center %d")
		    call pargi (LID_ITEM(lid))
	    }
	    call spt_ctr (spt, reg, dwx, dwy, cmd1)

	case CTR: # ctr cmd
	    call gargstr (cmd2, SZ_LINE)
	    call spt_ctr (spt, reg, dwx, dwy, cmd2)

	case EQWIDTH: # eqwidth cmd1
	    call gargstr (cmd2, SZ_LINE)
	    call spt_eqwidth (spt, reg, wx, wy, cmd2)

	case PLOT: # plot [cmd1]
	    call gargstr (cmd2, SZ_LINE)
	    call spt_plotcolon (spt, reg, cmd2)

	case REDRAW,OVRPLT,STACK,XFLIP,YFLIP,ZERO,LABELS,LINES:
	    call spt_plotcolon (spt, reg, cmd1)

	case PSPEC, PCONT, PRAW, PSKY, PSIG:
	    call spt_plotcolon (spt, reg, cmd1)

	case CONT:
	    call gargstr (cmd2, SZ_LINE)
	    call spt_cont (spt, reg1, SHCONT, reg1, stype1, cmd2)

	case LL:
	    call gargstr (cmd2, SZ_LINE)
	    call ll_colon (spt, reg, dwx, dwy, cmd2)

	case SIGCLIP:
	    call sigclip (spt, reg, cmd1)

	case ERRORS:
	    call spt_errors (spt, cmd1)

	default: # unknown command
err_
	    call sfree (sp)
	    call sprintf (cmd2, SZ_LINE, "Error in colon command: %g %g %s")
		call pargr (wx)
		call pargr (wy)
		call pargstr (cmd)
	    call error (1, cmd2)
	}

	call sfree (sp)
end
