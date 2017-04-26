include	<mach.h>
include	<smw.h>
include	"spectool.h"

# List of colon commands.
define	CMDS	"|open|close|scale|type|plot|color|"
define	OPEN		1
define	CLOSE		2
define	SCALE		3	# Scaling type
define	TYPE		4	# Stack type
define	PLOT		5	# Stack plot type
define	COLOR		6	# Stack color

# List of scale types.
define	TYPES "|none|scale|offset|"


# SPT_STACK -- Interpret stack colon commands.

procedure spt_stack (spt, cmd)

pointer	spt			#I SPECTOOLS pointer
char	cmd[ARB]		#I Command

bool	clgetb()
int	i, redraw, clgwrd(), strdic(), nscan(), btoi()
real	rval, clgetr(), asumr()
pointer	sp, str1, ptr, sh, reg

define	err_	10

begin
	call smark (sp)
	call salloc (str1, SZ_LINE, TY_CHAR)

	# Scan the command string and get command ID.
	call sscan (cmd)
	call gargwrd (Memc[str1], SZ_LINE)
	i = strdic (Memc[str1], Memc[str1], SZ_LINE, CMDS)

	# Execute the command.
	reg = SPT_CREG(spt)
	redraw = NO
	switch (i) {
	case OPEN: # open
	    SPT_PMODE(spt) = PLOT1
	    SPT_PMODE1(spt) = PLOT1
	    call gmsg (SPT_GP(spt), "setGui", "stack 0")

	    switch (clgwrd ("stackscale", Memc[str1], SZ_LINE, TYPES)) {
	    case 1:
		SPT_SCALE(spt) = SCALE_NONE
		SPT_OFFSET(spt) = SCALE_NONE
	    case 2:
		SPT_SCALE(spt) = SCALE_MEAN
		SPT_OFFSET(spt) = SCALE_NONE
	    case 3:
		SPT_SCALE(spt) = SCALE_NONE
		SPT_OFFSET(spt) = SCALE_MEAN
	    }
	    SPT_STACKTYPE(spt) = clgwrd ("stacktype", Memc[str1], SZ_LINE,
		STACKTYPES)
	    SPT_STACKSTEP(spt) = clgetr ("stackstep")
	    SPT_STACKPLOT(spt) = btoi (clgetb ("stacklines"))
	    SPT_STACKCOL(spt) = btoi (clgetb ("stackcolors"))

	    call gmsg (SPT_GP(spt), "setGui", "overplot 0")

	case CLOSE: # close
	    if (SPT_OFFSET(spt) == SCALE_MEAN)
		call clpstr ("stackscale", "offset")
	    else if (SPT_SCALE(spt) == SCALE_MEAN)
		call clpstr ("stackscale", "scale")
	    else
		call clpstr ("stackscale", "none")
	    switch (SPT_STACKTYPE(spt)) {
	    case STACK_ABS:
		call clpstr ("stacktype", "absolute")
	    case STACK_RANGE:
		call clpstr ("stacktype", "first range")
	    case STACK_RANGES:
		call clpstr ("stacktype", "individual ranges")
	    }
	    call clputr ("stackstep", SPT_STACKSTEP(spt))
	    call clputb ("stacklines", (SPT_STACKPLOT(spt) == 1))
	    call clputb ("stackcolors", (SPT_STACKCOL(spt) == 1))

	case SCALE: # stack scale <type>
	    call gargwrd (Memc[str1], SZ_LINE)
	    i = strdic (Memc[str1], Memc[str1], SZ_LINE, TYPES)
	    switch (i) {
	    case 1:
		SPT_SCALE(spt) = SCALE_NONE
		SPT_OFFSET(spt) = SCALE_NONE
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    REG_SCALE(ptr) = 1.
		    REG_OFFSET(ptr) = 0.
		}
	    case 2:
		SPT_SCALE(spt) = SCALE_MEAN
		SPT_OFFSET(spt) = SCALE_NONE
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    sh = REG_SH(ptr)
		    rval = abs (asumr (Memr[SPEC(sh,SPT_CTYPE(spt))], SN(sh)) / SN(sh))
		    if (rval > EPSILONR * (REG_Y2(ptr) - REG_Y1(ptr)))
			REG_SCALE(ptr) = 1. / rval
		    else
			REG_SCALE(ptr) = 1.
		    REG_OFFSET(ptr) = 0.
		}
	    case 3:
		SPT_SCALE(spt) = SCALE_NONE
		SPT_OFFSET(spt) = SCALE_MEAN
		do i = 1, SPT_NREG(spt) {
		    ptr = REG(spt,i)
		    sh = REG_SH(ptr)
		    rval = -asumr (Memr[SPEC(sh,SPT_CTYPE(spt))], SN(sh)) / SN(sh)
		    REG_SCALE(ptr) = 1.
		    REG_OFFSET(ptr) = rval
		}
	    }
	    redraw = YES

	case TYPE: # stack type <type>
	    call gargwrd (Memc[str1], SZ_LINE)
	    i = strdic (Memc[str1], Memc[str1], SZ_LINE, STACKTYPES)
	    if (i == 0)
		goto err_
	    SPT_STACKTYPE(spt) = i
	    redraw = YES

	case PLOT: # stack plot [0|1]
	    call gargi (SPT_STACKPLOT(spt))
	    redraw = YES

	case COLOR: # stack color [0|1]
	    call gargi (SPT_STACKCOL(spt))
	    redraw = YES
	
	default: # stack <value>
            call sscan (cmd)
            call gargr (rval)
            if (nscan() == 1)
		SPT_STACKSTEP(spt) = rval
	    else {
err_            call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "Error in colon command: stack %s")
		    call pargstr (cmd)
		call error (1, SPT_STRING(spt))
	    }
	    redraw = YES
	}

	# Redraw plot.
	if (redraw == YES && SPT_NREG(spt) > 1) {
	    SPT_REDRAW(spt,1) = YES
	    SPT_REDRAW(spt,2) = YES
	}

	# Update GUI.
	call sprintf (SPT_STRING(spt), SPT_SZSTRING,
	    "stackpars %s \"%s\" %g %d %d")
	    if (SPT_OFFSET(spt) == SCALE_MEAN)
		call pargstr ("offset")
	    else if (SPT_SCALE(spt) == SCALE_MEAN)
		call pargstr ("scale")
	    else
		call pargstr ("none")
	    switch (SPT_STACKTYPE(spt)) {
	    case STACK_ABS:
		call pargstr ("absolute")
	    case STACK_RANGE:
		call pargstr ("first range")
	    case STACK_RANGES:
		call pargstr ("individual ranges")
	    default:
		call pargstr ("absolute")
	    }
	    call pargr (SPT_STACKSTEP(spt))
	    call pargi (SPT_STACKPLOT(spt))
	    call pargi (SPT_STACKCOL(spt))
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))

	call sfree (sp)
end
