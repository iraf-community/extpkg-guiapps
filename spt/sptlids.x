include	<ctype.h>
include	<gset.h>
include	<units.h>
include	<smw.h>
include	<error.h>
include	<mach.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"lids.h"
include	"rv.h"

# Routines to manage line identifications.
# LID_COLON   -- Interpret line identification colon commands.
# LID_NEAREST -- Find the nearest line to the cursor.
#
# LID_ALLOC   -- Allocate line ID structures.
# LID_FREE    -- Free spectrum line ID structure.
# LID_LIST    -- Send (update) line ID list to GUI.
# LID_MARK    -- Mark lines in spectrum.
# LID_MARK1   -- Mark a single line in spectrum.
# LID_ERASE   -- Erase a single line ID label.
# LID_POS     -- Determine label and tick position in current graph.
# LID_ADD     -- Add a line ID.
# LID_NEW     -- Add or replace a new line ID.
# LID_Y       -- Compute the NDC label offset.
# LID_NEAR    -- Find the nearest line to the cursor.
# LID_ITEM    -- Get the line ID pointer given the item number.


# List of colon commands.
define	CMDS	"|open|close|free|read|write|line|label|labpars\
		 |delete|select|list|plot|units\
		 |query|sep|reference|identification|bandpass|"


define	OPEN		1	# Open/allocate/initialize
define	CLOSE		2	# Close/free
define	FREE 		3	# Free register line list
define	READ		4	# Read a file of labels
define	WRITE		5	# Save a file of labels

define	LINE		6	# Define line
define	LABEL		7	# Label line?
define	LABPARS		8	# Set line label parameters
define	DELETE		9	# Delete a label with cursor
define	SELECT		10	# Select label by list item number
define	LIST 		11	# Send line IDs to GUI
define	PLOT 		12	# Plot the line IDs
define	UNIT		13	# Change units
define	QUERY 		14	# Query?
define	SEP 		15	# Minimum separation (pixels)

define	REFERENCE	16	# Set reference
define	ID		17	# Set line identification
define	BANDPASS	18	# Bandpass


# LID_COLON -- Interpret line identification colon commands.

procedure lid_colon (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
double	wx, wy			#I GIO coordinate
char	cmd[ARB]		#I GIO command

int	i, ncmd, nscn, item, draw, fd, flags[6], color
bool	doref
double	x, y, ref, low, up
pointer	sh, lids, lid
pointer	sp, str, prof, id, refmatch, idmatch, format

bool	clgetb(), streq(), strne()
double	clgetd(), shdr_lw(), shdr_wl()
int	clgwrd(),  strdic(), open(), fscan(), nscan(), btoi(), lid_match()
errchk	lid_mapll, lid_nearest, lid_add

define	err_	10
define	done_	20

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (prof, SZ_LINE, TY_CHAR)
	call salloc (id, SZ_LINE, TY_CHAR)
	call salloc (refmatch, SZ_LINE, TY_CHAR)
	call salloc (idmatch, SZ_LINE, TY_CHAR)
	call salloc (format, SZ_LINE, TY_CHAR)

	if (reg != NULL) {
	    lids = REG_LIDS(reg)
	    sh = REG_SH(reg)
	    if (sh != NULL) {
		call amulkr (Memr[SPEC(sh,SPT_CTYPE(spt))], REG_SSCALE(reg),
		    SPECT(spt), SN(sh))
		call aaddkr (SPECT(spt), REG_STEP(reg), SPECT(spt), SN(sh))
	    }
	} else
	    lids = NULL

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[id], SZ_LINE)
	ncmd = strdic (Memc[id], Memc[id], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    SPT_LINES(spt) = btoi (clgetb ("lidshow"))
	    SPT_DLABY(spt) = clgetd ("lidpos")
	    call clgstr ("lidformat", SPT_DLABFMT(spt), LID_SZLINE)
	    SPT_DLABCOL(spt) = clgwrd ("lidcolor", SPT_STRING(spt),
		SPT_SZSTRING, COLORS) - 1

	    SPT_DLABTICK(spt) = btoi (clgetb ("lidtick"))
	    SPT_DLABARROW(spt) = btoi (clgetb ("lidarrow"))
	    SPT_DLABBAND(spt) = btoi (clgetb ("lidband"))
	    SPT_DLABX(spt) = btoi (clgetb ("lidmeasured"))
	    SPT_DLABREF(spt) = btoi (clgetb ("lidreference"))
	    SPT_DLABID(spt) = btoi (clgetb ("lidlabel"))

	    SPT_SEP(spt) = clgetd ("linesep")
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "lines %d")
		call pargi (SPT_LABEL(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"set %g %g %d %d %d %d %d %d \"%s\" %d")
		call pargd (SPT_SEP(spt))
		call pargd (SPT_DLABY(spt))
		call pargi (SPT_DLABX(spt))
		call pargi (SPT_DLABREF(spt))
		call pargi (SPT_DLABID(spt))
		call pargi (SPT_DLABTICK(spt))
		call pargi (SPT_DLABARROW(spt))
		call pargi (SPT_DLABBAND(spt))
		call pargstr (SPT_DLABFMT(spt))
		call pargi (SPT_DLABCOL(spt))
	    call gmsg (SPT_GP(spt), "lidspars", SPT_STRING(spt))

	    SPT_LIDSALL(spt) = NO
	    call gmsg (SPT_GP(spt), "setGui", "lidsall 0")

	    call gmsg (SPT_GP(spt), "lidslist", "")
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"0 INDEF INDEF %.8g %.8g \"\" 0")
		call pargd (SPT_DLOW(spt))
		call pargd (SPT_DUP(spt))
	    call gmsg (SPT_GP(spt), "line", SPT_STRING(spt))

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "lines %d")
		call pargi (SPT_LINES(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))


	case CLOSE: # close
	    call clputb ("lidshow", (SPT_LINES(spt)==YES))
	    call clputd ("lidpos", SPT_DLABY(spt))
	    call clpstr ("lidformat", SPT_DLABFMT(spt))
	    call spt_dic (COLORS, SPT_DLABCOL(spt)+1, SPT_STRING(spt),
		SPT_SZSTRING)
	    call clpstr ("lidcolor", SPT_STRING(spt))

	    call clputb ("lidtick", (SPT_DLABTICK(spt)==YES))
	    call clputb ("lidarrow", (SPT_DLABARROW(spt)==YES))
	    call clputb ("lidband", (SPT_DLABBAND(spt)==YES))
	    call clputb ("lidmeasured", (SPT_DLABX(spt)==YES))
	    call clputb ("lidreference", (SPT_DLABREF(spt)==YES))
	    call clputb ("lidlabel", (SPT_DLABID(spt)==YES))

	    call clputd ("linesep", SPT_SEP(spt))
	    call clputd ("linematch", SPT_LLSEP(spt))
	    call clpstr ("linelist", SPT_LINELIST(spt))

	    call lid_unmapll (spt)

	case FREE: # free
	    call lid_free (spt, reg)

	case READ: # read file
	    call gargwrd (Memc[id], SZ_LINE)
	    nscn = nscan()

	    if (nscn != 2)
		goto done_
	    iferr (fd = open (Memc[id], READ_ONLY, TEXT_FILE))
		goto err_
	    while (fscan (fd) != EOF) {
		call gargd (x)
		call gargd (ref)
		call gargd (low)
		call gargd (up)
		call gargwrd (Memc[prof], SZ_LINE)
		call gargstr (Memc[id], SZ_LINE)
		nscn = nscan()
		if (nscn == 0)
		    next
		if (nscn < 2)
		    low = SPT_DLOW(spt)
		if (nscn < 3)
		    up = SPT_DUP(spt)
		if (nscn < 4)
		    call strcpy (SPT_DPROF(spt), Memc[prof], SZ_LINE)
		if (nscn < 5)
		    ref = INDEFD
		if (nscn < 6)
		    Memc[id] = EOS
		lid = NULL
		call lid_alloc (spt, reg, lid, YES, x, low, up,
		    Memc[prof], ref, SPT_DLABY(spt), Memc[id],
		    SPT_DLABTICK(spt), SPT_DLABFMT(spt),
		    SPT_DLABCOL(spt))
		SPT_REDRAW(spt,1) = YES
	    }
	    call close (fd)
	    call lid_list (spt, reg, NULL)

	case WRITE: # write file
	    call gargwrd (Memc[id], SZ_LINE)
	    nscn = nscan()
	    if (LID_NLINES(lids) == 0 || nscn != 2)
		goto done_
	    iferr (fd = open (Memc[id], NEW_FILE, TEXT_FILE))
		goto err_
	    do i = 1, LID_NLINES(lids) {
		lid = LID_LINES(lids,i)
		call fprintf (fd, "%10.8g %10.8g %10.8g %s %10.8g %s\n")
		    call pargd (LID_X(lid))
		    call pargd (LID_REF(lid))
		    call pargd (LID_LOW(lid))
		    call pargd (LID_UP(lid))
		    call pargstr (MOD_PROF(lid))
		    call pargstr (LID_LABEL(lid))
	    }
	    call close (fd)

	case LINE: # line [item x ref low up id]
	    # Get arguments.
	    call gargi (item)
	    call gargd (x)
	    call gargd (ref)
	    call gargd (low)
	    call gargd (up)
	    call gargwrd (Memc[id], SZ_LINE)
	    nscn = nscan()

	    # Provide defaults.
	    if (nscn < 2)
		item = 0
	    if (nscn < 3)
		x = wx
	    if (nscn < 4)
		ref = INDEFD
	    if (nscn < 5)
		low = INDEFD
	    if (nscn < 6)
		up = INDEFD
	    if (nscn < 7)
		call strcpy ("INDEF", Memc[id], SZ_LINE)

	    # Update defaults.
	    if (!IS_INDEFD(low))
		SPT_DLOW(spt) = low
	    if (!IS_INDEFD(up))
		SPT_DUP(spt) = up

	    # Add/replace line.
	    if (item != 0) {
		call lid_item (spt, reg, item, lid)
		call lid_erase (spt, reg, lid)
		if (!IS_INDEFD(x))
		    LID_X(lid) = x
		if (!IS_INDEFD(ref)) {
		    LID_LLINDEX(lid) = lid_match (spt, reg, YES, ref,
			LID_REF(lid), Memc[idmatch], SZ_LINE)
		    if (LID_LLINDEX(lid) == 0)
			LID_REF(lid) = ref
		}
		if (!IS_INDEFD(low))
		    LID_LOW(lid) = low
		if (!IS_INDEFD(up))
		    LID_UP(lid) = up
		if (strne(Memc[id],"INDEF") && strne(Memc[id],LID_LABEL(lid)))
		    call strcpy (Memc[id], LID_LABEL(lid), LID_SZLINE)
		call lid_mark1 (spt, reg, lid)
	    } else if (!IS_INDEFD(x)) {
		call lid_y (spt, reg, x, wy, SPT_DLABY(spt), y)
		call lid_add (spt, reg, lid, YES, YES, x, low,
		    up, "INDEF", ref, y, Memc[id])
	    } else
		lid = NULL

	    # Update list.
	    call lid_list (spt, reg, lid)

	case LABEL: # label [item draw]
	    call gargi (item)
	    call gargi (draw)
	    nscn = nscan()

	    if (nscn < 2)
		item = -1
	    if (nscn < 3)
		draw = 2

	    if (item > 0) {
		call lid_item (spt, reg, item, lid)
		call lid_erase (spt, reg, lid)
		if (draw == 2)
		    LID_DRAW(lid) = btoi (LID_DRAW(lid)==NO)
		else
		    LID_DRAW(lid) = draw
		call lid_mark1 (spt, reg, lid)
		call lid_list (spt, reg, lid)
	    } else if (item == -1 && lids != NULL) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call lid_erase (spt, reg, lid)
		    if (draw == 2)
			LID_DRAW(lid) = btoi (LID_DRAW(lid)==NO)
		    else
			LID_DRAW(lid) = draw
		    call lid_mark1 (spt, reg, lid)
		}
		call lid_list (spt, reg, NULL)
	    }

	case LABPARS: # labpars item y obs ref id tick arrow band fmt color
	    call gargi (item)
	    call gargd (y)
	    call gargi (flags[4])
	    call gargi (flags[5])
	    call gargi (flags[6])
	    call gargi (flags[1])
	    call gargi (flags[2])
	    call gargi (flags[3])
	    call gargwrd (Memc[format], SZ_LINE)
	    call gargi (color)
	    nscn = nscan()

	    if (nscn < 11)
		goto err_

	    # Set defaults.
	    SPT_DLABY(spt) = y
	    SPT_DLABTICK(spt) = flags[1]
	    SPT_DLABARROW(spt) = flags[2]
	    SPT_DLABBAND(spt) = flags[3]
	    SPT_DLABX(spt) = flags[4]
	    SPT_DLABREF(spt) = flags[5]
	    SPT_DLABID(spt) = flags[6]
	    call strcpy (Memc[format], SPT_DLABFMT(spt), LID_SZLINE)
	    SPT_DLABCOL(spt) = color

	    # Modify line or lines.
	    if (item > 0) {
		call lid_item (spt, reg, item, lid)
		call lid_erase (spt, reg, lid)
		LID_LABY(lid) = y
		LID_LABTICK(lid) = flags[1]
		LID_LABARROW(lid) = flags[2]
		LID_LABBAND(lid) = flags[3]
		LID_LABX(lid) = flags[4]
		LID_LABREF(lid) = flags[5]
		LID_LABID(lid) = flags[6]
		call strcpy (Memc[format], LID_LABFMT(lid), LID_SZLINE)
		LID_LABCOL(lid) = color
		call lid_mark1 (spt, reg, lid)
	    } else if (item == -1 && lids != NULL) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call lid_erase (spt, reg, lid)
		    LID_LABY(lid) = y
		    LID_LABTICK(lid) = flags[1]
		    LID_LABARROW(lid) = flags[2]
		    LID_LABBAND(lid) = flags[3]
		    LID_LABX(lid) = flags[4]
		    LID_LABREF(lid) = flags[5]
		    LID_LABID(lid) = flags[6]
		    LID_LABCOL(lid) = color
		    call strcpy (Memc[format], LID_LABFMT(lid), LID_SZLINE)
		    call lid_mark1 (spt, reg, lid)
		}
	    }

	case DELETE: # delete item
	    call gargi (item)
	    nscn = nscan()

	    if (nscn == 1)
		item = -1
	    if (item == 0)
		goto done_

	    call lid_delete (spt, reg, item)
	    call lid_list (spt, reg, NULL)

	case SELECT: # select item
	    call gargi (item)
	    nscn = nscan()

	    if (nscn == 1)
		goto done_
	    if (item == 0) {
		call lid_list (spt, reg, NULL)
		goto done_
	    }

	    call lid_item (spt, reg, item, lid)
	    if (lid == NULL)
		goto done_

	    SPT_DLOW(spt) = LID_LOW(lid)
	    SPT_DUP(spt) = LID_UP(lid)
	    call strcpy (MOD_PROF(lid),SPT_DPROF(spt),LID_SZPROF)
	    SPT_DLABY(spt) = LID_LABY(lid)
	    SPT_DLABTICK(spt) = LID_LABTICK(lid)
	    SPT_DLABARROW(spt) = LID_LABARROW(lid)
	    SPT_DLABBAND(spt) = LID_LABBAND(lid)
	    SPT_DLABX(spt) = LID_LABX(lid)
	    SPT_DLABREF(spt) = LID_LABREF(lid)
	    SPT_DLABID(spt) = LID_LABID(lid)
	    call strcpy (LID_LABFMT(lid),SPT_DLABFMT(spt),LID_SZLINE)
	    call lid_list (spt, reg, lid)

	case LIST: # list
	    call lid_list (spt, reg, NULL)

	case PLOT: # plot
	    call lid_mark (spt, reg)

	case UNIT: # units [logical|world]
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargb (doref)
	    if (nscan() != 3)
		goto err_

	    if (lids == NULL)
		goto done_
	    if (REG_SH(reg) == NULL)
		goto done_

	    if (streq (Memc[str], "logical")) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    low = shdr_wl (sh, LID_X(lid) + LID_LOW(lid))
		    up = shdr_wl (sh, LID_X(lid) + LID_UP(lid))
		    LID_X(lid) = shdr_wl (sh, LID_X(lid))
		    if (doref && !IS_INDEFD(LID_REF(lid)))
			LID_REF(lid) = shdr_wl (sh, LID_REF(lid))
		    LID_LOW(lid) = min (low, up) - LID_X(lid)
		    LID_UP(lid) = max (low, up) - LID_X(lid)
		}
	    } else {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    low = shdr_lw (sh, LID_X(lid) + LID_LOW(lid))
		    up = shdr_lw (sh, LID_X(lid) + LID_UP(lid))
		    LID_X(lid) = shdr_lw (sh, LID_X(lid))
		    if (doref && !IS_INDEFD(LID_REF(lid)))
			LID_REF(lid) = shdr_lw (sh, LID_REF(lid))
		    LID_LOW(lid) = min (low, up) - LID_X(lid)
		    LID_UP(lid) = max (low, up) - LID_X(lid)
		}
		lid = LID_LID(lids)
		if (lid != NULL) {
		    SPT_DLOW(spt) = LID_LOW(lid)
		    SPT_DUP(spt) = LID_UP(lid)
		}
	    }

	case SEP: # sep <value>
	    call gargd (SPT_SEP(spt))

	case REFERENCE: # reference <value>
	    call gargd (ref)
	    nscn = nscan()

	    if (nscn == 2) {
		call lid_nearest (spt, reg, wx, wy, lid)
		if (lid != NULL) {
		    LID_LLINDEX(lid) = lid_match (spt, reg, YES, ref,
			LID_REF(lid), Memc[id], SZ_LINE)
		    if (LID_LLINDEX(lid) == 0)
			LID_REF(lid) = ref
		    else
			call strcpy (Memc[id], LID_LABEL(lid), LID_SZLINE) 
		    call lid_list (spt, reg, lid)
		}
	    }

	case ID: # identification <value>
	    call gargstr (Memc[id], SZ_LINE)
	    for (i=id; IS_WHITE(Memc[i]); i=i+1)
		;
	    call lid_nearest (spt, reg, wx, wy, lid)
	    if (lid != NULL) {
		call strcpy (Memc[id], LID_LABEL(lid), LID_SZLINE)
		call lid_list (spt, reg, lid)
		call lid_mark1 (spt, reg, lid)
	    }

	case BANDPASS: # bandpass item value1 [value2]
	    call gargi (item)
	    call gargd (low)
	    call gargd (up)
	    nscn = nscan()

	    if (item == 0 || lids == NULL || nscn < 3)
		goto done_

	    if (item == -1) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    call lid_erase (spt, reg, lid)
		    if (nscn == 3) {
			if (low < LID_LOW(lid))
			    LID_LOW(lid) = low
			else if (low > LID_UP(lid))
			    LID_UP(lid) = low
			else if (low <= 0.)
			    LID_LOW(lid) = low
			else
			    LID_UP(lid) = low
		    } else {
			if (!IS_INDEFD(low) && !IS_INDEFD(up)) {
			    LID_LOW(lid) = min (low, up)
			    LID_UP(lid) = max (low, up)
			} else if (!IS_INDEFD(low)) {
			    x = LID_UP(lid)
			    LID_LOW(lid) = min (low, x)
			    LID_UP(lid) = max (low, x)
			} else if (!IS_INDEFD(up)) {
			    x = LID_LOW(lid)
			    LID_LOW(lid) = min (x, up)
			    LID_UP(lid) = max (x, up)
			}
		    }
		    call lid_mark1 (spt, reg, lid)
		}
		SPT_DLOW(spt) = LID_LOW(lid)
		SPT_DUP(spt) = LID_UP(lid)
		call lid_list (spt, reg, lid)
	    } else {
		call lid_item (spt, reg, item, lid)
		if (lid == NULL)
		    goto err_
		call lid_erase (spt, reg, lid)
		if (nscn == 3) {
		    if (low < LID_LOW(lid))
			LID_LOW(lid) = low
		    else if (low > LID_UP(lid))
			LID_UP(lid) = low
		    else if (low <= 0.)
			LID_LOW(lid) = low
		    else
			LID_UP(lid) = low
		} else {
		    if (!IS_INDEFD(low) && !IS_INDEFD(up)) {
			LID_LOW(lid) = min (low, up)
			LID_UP(lid) = max (low, up)
		    } else if (!IS_INDEFD(low)) {
			x = LID_UP(lid)
			LID_LOW(lid) = min (low, x)
			LID_UP(lid) = max (low, x)
		    } else if (!IS_INDEFD(up)) {
			x = LID_LOW(lid)
			LID_LOW(lid) = min (x, up)
			LID_UP(lid) = max (x, up)
		    }
		}
		SPT_DLOW(spt) = LID_LOW(lid)
		SPT_DUP(spt) = LID_UP(lid)
		call lid_mark1 (spt, reg, lid)
		call lid_list (spt, reg, lid)
	    }

	default: # error or unknown command
err_	    call sprintf (Memc[id], SZ_LINE,
		"Error in colon command: %g %g lids %s")
		call pargd (wx)
		call pargd (wy)
		call pargstr (cmd)
	    call error (1, Memc[id])
	}

done_	call sfree (sp)
end
		    

# LID_NEAREST -- Find nearest line to given position.

procedure lid_nearest (spt, reg, wx, wy, lid)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
double	wx, wy			#I GIO coordinate
pointer	lid			#O Line identification (NULL if not found)

pointer	sh
errchk	lid_near

begin
	lid = NULL
	sh = NULL
	if (reg != NULL)
	    sh = REG_SH(reg)
	else
	    sh = NULL

	if (sh != NULL) {
	    sh = REG_SH(reg)
	    call amulkr (Memr[SPEC(sh,SPT_CTYPE(spt))], REG_SSCALE(reg),
		SPECT(spt), SN(sh))
	    call aaddkr (SPECT(spt), REG_STEP(reg), SPECT(spt), SN(sh))

	    call lid_near (spt, reg, wx, wy, lid)
	}

	if (lid == NULL)
	    call error (1, "Line not found")
end


# SPT_DELETE -- Delete line.

procedure lid_delete (spt, reg, item)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
int	item		#I Item to delete

int	i, nlines
pointer	lids, lid

begin
	if (reg == NULL)
	    return
	if (REG_LIDS(reg) == NULL)
	    return

	lids = REG_LIDS(reg)
	nlines = LID_NLINES(lids)
	if (item == -1) {
	    do i = 1, nlines {
		lid = LID_LINES(lids,i)
		call lid_erase (spt, reg, lid)
		call mfree (lid, TY_STRUCT)
	    }
	    nlines = 0
	} else {
	    if (item < 1 || item > nlines)
		return
	    lid = LID_LINES(lids,item)
	    call lid_erase (spt, reg, lid)
	    call mfree (lid, TY_STRUCT)
	    nlines = nlines - 1

	    do i = item, nlines {
		lid = LID_LINES(lids,i+1)
		LID_LINES(lids,i) = lid
		LID_ITEM(lid) = i
	    }
	}
	LID_NLINES(lids) = nlines

	if (nlines == 0)
	    call mfree (REG_LIDS(reg), TY_POINTER)
end


# LID_FREE -- Free line.

procedure lid_free (spt, reg)

pointer	spt		# Spectool pointer
pointer	reg		# Register

int	i
pointer	lids

begin
	if (reg == NULL)
	    return
	if (REG_LIDS(reg) == NULL)
	    return

	lids = REG_LIDS(reg)
	do i = 1, LID_NLINES(lids)
	    call mfree (LID_LINES(lids,i), TY_STRUCT)
	call mfree (REG_LIDS(reg), TY_POINTER)
end


# LID_MARK -- Mark lines in spectrum.
# This routine assumes the scaled spectrum is in SPT_SPEC.

procedure lid_mark (spt, reg)

pointer	spt		#I Spectool
pointer	reg		#I Spectrum register

int	i
pointer	lids

begin
	if (SPT_LINES(spt) == NO || reg == NULL)
	    return
	if (REG_LINES(reg) == NO || REG_LIDS(reg) == NULL)
	    return

	lids = REG_LIDS(reg)
	do i = 1, LID_NLINES(lids)
	    call lid_mark1 (spt, reg, LID_LINES(lids,i))
end


# LID_MARK1 -- Mark a single line in spectrum.
# This routine assumes the scaled spectrum is in SPT_SPEC.

procedure lid_mark1 (spt, reg, lid)

pointer	spt		#I Spectool
pointer	reg		#I Register
pointer	lid		#I Line ID

bool	above, tick
real	x, y, ticks[2,7]
int	i, gstati()
pointer	sp, str, gp

real	xarrw[3], yarrwu[3], yarrwd[3]
data	xarrw/.25,.5,.75/, yarrwu/0.,.5,0./, yarrwd/1.,.5,1./

begin
	if (SPT_LINES(spt) == NO || reg == NULL || lid == NULL)
	    return
	if (REG_LINES(reg) == NO || LID_DRAW(lid) == NO)
	    return

	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	SPT_STRING(spt) = EOS
	if (LID_LABX(lid) == YES) {
	    if (SPT_STRING(spt) == EOS)
		call sprintf (Memc[str], SZ_LINE, "%.6g")
	    else
		call sprintf (Memc[str], SZ_LINE, " %.6g")
		call pargd (LID_X(lid))
	    call strcat (Memc[str], SPT_STRING(spt), SPT_SZSTRING)
	}
	if (LID_LABREF(lid) == YES && !IS_INDEFD(LID_REF(lid))) {
	    if (SPT_STRING(spt) == EOS)
		call sprintf (Memc[str], SZ_LINE, "%.6g")
	    else
		call sprintf (Memc[str], SZ_LINE, " %.6g")
		call pargd (LID_REF(lid))
	    call strcat (Memc[str], SPT_STRING(spt), SPT_SZSTRING)
	}
	if (LID_LABID(lid) == YES && LID_LABEL(lid) != EOS) {
	    if (SPT_STRING(spt) == EOS)
		call sprintf (Memc[str], SZ_LINE, "%s")
	    else
		call sprintf (Memc[str], SZ_LINE, " %s")
		call pargstr (LID_LABEL(lid))
	    call strcat (Memc[str], SPT_STRING(spt), SPT_SZSTRING)
	}

	call lid_pos (spt, reg, lid, above, tick, x, y, ticks)

	gp = SPT_GP(spt)
	i = gstati (gp, G_TXCOLOR)
	call gseti (gp, G_TXCOLOR, LID_LABCOL(lid))
	switch (LID_LABFMT(lid)) {
	case 'H':
	    if (above)
		call gtext (gp, ticks[1,1], ticks[2,1], SPT_STRING(spt),
		    "h=c;v=b")
	    else
		call gtext (gp, ticks[1,1], ticks[2,1], SPT_STRING(spt),
		    "h=c;v=t")
	case 'V':
	    if (above)
		call gtext (gp, ticks[1,1], ticks[2,1], SPT_STRING(spt),
		    "h=c;v=b;u=180")
	    else
		call gtext (gp, ticks[1,1], ticks[2,1], SPT_STRING(spt),
		    "h=c;v=t;u=0")
	default:
	    call gtext (gp, ticks[1,1], ticks[2,1], SPT_STRING(spt),
		LID_LABFMT(lid))
	}
	call gseti (gp, G_TXCOLOR, i)
	if (tick) {
	    i = gstati (gp, G_PLCOLOR)
	    call gseti (gp, G_PLCOLOR, LID_LABCOL(lid))
	    if (LID_LABTICK(lid) == YES)
		call gline (gp, ticks[1,2], ticks[2,2], ticks[1,3], ticks[2,3])
	    if (LID_LABBAND(lid) == YES) {
		call gline (gp, ticks[1,4], ticks[2,4], ticks[1,5], ticks[2,5])
		call gline (gp, ticks[1,6], ticks[2,6], ticks[1,7], ticks[2,7])
		call gline (gp, ticks[1,4], ticks[2,4], ticks[1,6], ticks[2,6])
	    }
	    if (LID_LABARROW(lid) == YES) {
		if (above)
		    call gumark (gp, xarrw, yarrwd, 3, ticks[1,3], ticks[2,3],
			3., 3., NO)
		else
		    call gumark (gp, xarrw, yarrwu, 3, ticks[1,3], ticks[2,3],
			3., 3., NO)
	    }
	    call gseti (gp, G_PLCOLOR, i)
	}

	call gflush (gp)
	call sfree (sp)
end


# LID_ERASE -- Erase a single line ID label.
# This will fail if the color is specified in the label format.

procedure lid_erase (spt, reg, lid)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lid		#I Line ID label to erase

int	i

begin
	if (SPT_LINES(spt) == NO || reg == NULL || lid == NULL)
	    return
	if (REG_LINES(reg) == NO || LID_DRAW(lid) == NO)
	    return

	i = LID_LABCOL(lid)
	LID_LABCOL(lid) = 0
	call lid_mark1 (spt, reg, lid)
	LID_LABCOL(lid) = i
end


# LID_POS -- Determine label and tick position in current graph.
# This routine assumes the scaled spectrum is in SPT_SPEC.

procedure lid_pos (spt, reg, lid, above, tick, x, y, ticks)

pointer	spt		#I Spectool
pointer	reg		#I Register
pointer	lid		#I Line ID
bool	above		#O Above spectrum?
bool	tick		#O Draw tick?
real	x		#O X line position
real	y		#O Y line position
real	ticks[2,7]	#O Tick vertices

int	i
bool	yflip
real	mxc, mxl, mxh, my1, my2, dm1, dm2
double	shdr_wl()
pointer	gp, sh, sy

begin
	gp = SPT_GP(spt)
	sh = REG_SH(reg)
	sy = SPT_SPEC(spt)

	call ggwind (gp, mxl, mxh, my1, my2)
	yflip = (my1 > my2)

	# Determine position of line.
	i = max (1, min (SN(sh)-1, int(shdr_wl(sh,LID_X(lid)))))
	if (LID_LABY(lid) > 0.) {
	    above = true
	    if (yflip)
		above = !above
	    x = LID_X(lid)
	    y = max (Memr[sy+i-1], Memr[sy+i])
	} else {
	    above = false
	    if (yflip)
		above = !above
	    x = LID_X(lid)
	    y = min (Memr[sy+i-1], Memr[sy+i])
	}

	# Set ticks and label.
	# Do everything in NDC and convert back at the end.

	tick = (LID_LABTICK(lid) == YES || LID_LABARROW(lid) == YES ||
	    LID_LABBAND(lid) == YES)

	call gctran (gp, real(x+LID_LOW(lid)), y, mxl, my2, 1, 0)
	call gctran (gp, real(x+LID_UP(lid)), y, mxh, my2, 1, 0)
	call gctran (gp, x, y, mxc, my2, 1, 0)
	if (yflip)
	    my1 = my2 - LID_LABY(lid)
	else
	    my1 = my2 + LID_LABY(lid)

	if (above) {
	    dm1 = -0.02
	    dm2 = min (0., (my2 + 0.02) - my1)
	} else {
	    dm1 = 0.02
	    dm2 = max (0., (my2 - 0.02) - my1)
	}

	ticks[1,1] = mxc; ticks[2,1] = my1
	ticks[1,2] = mxc; ticks[2,2] = my1 + dm1
	ticks[1,3] = mxc; ticks[2,3] = my1 + dm2
	ticks[1,4] = mxl; ticks[2,4] = my1 + dm1
	ticks[1,5] = mxl; ticks[2,5] = my1 + dm2 / 2
	ticks[1,6] = mxh; ticks[2,6] = my1 + dm1
	ticks[1,7] = mxh; ticks[2,7] = my1 + dm2 / 2
	if (dm2 == 0.)
	    tick = false

	# Convert back to graph WCS.
	do i = 1, 7
	    call gctran (gp, ticks[1,i], ticks[2,i],
		ticks[1,i], ticks[2,i], 0, 1)
end


# LID_ALLOC -- Allocate a new line.
# This routine assumes the scaled spectrum is in SPT_SPEC.

procedure lid_alloc (spt, reg, lid, match, x, low, up, prof, ref, y,
	label, flags, format, color)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register pointer
pointer	lid		#U Line ID pointer
int	match		#I Match against line list
double	x, y		#I X, Y position for label
double	low, up		#I Limits
char	prof[ARB]	#I Profile type
double	ref		#I Reference
char	label[ARB]	#I Label string
int	flags[6]	#I Flags
char	format[ARB]	#I Label format
int	color		#I Color

int	i, lid_match()
pointer	sp, id, ptr, lids
bool	streq()

errchk	lid_match

begin
	if (reg == NULL)
	    return

	call smark (sp)
	call salloc (id, LID_SZLINE, TY_CHAR)
	Memc[id] = EOS

	# Allocate a line.
	call calloc (lid, LID_LEN, TY_STRUCT)

	# Query for values.
	if (match==YES && IS_INDEFD(ref))
	    LID_LLINDEX(lid) = lid_match (spt, reg, YES, x, LID_REF(lid),
		Memc[id], LID_SZLINE)
	else
	    LID_REF(lid) = ref
	if (IS_INDEFD(low))
	    LID_LOW(lid) = SPT_DLOW(spt)
	else
	    LID_LOW(lid) = low
	if (IS_INDEFD(up))
	    LID_UP(lid) = SPT_DUP(spt)
	else
	    LID_UP(lid) = up
	if (LID_LOW(lid) > LID_UP(lid)) {
	    up = LID_LOW(lid)
	    LID_LOW(lid) = LID_UP(lid)
	    LID_UP(lid) = up
	}
	if (SPT_DLOW(spt) > SPT_DUP(spt)) {
	    up = SPT_DLOW(spt)
	    SPT_DLOW(spt) = SPT_DUP(spt)
	    SPT_DUP(spt) = up
	}
	if (streq (prof, "INDEF"))
	    call strcpy (SPT_DPROF(spt), MOD_PROF(lid), LID_SZPROF)
	else
	    call strcpy (prof, MOD_PROF(lid), LID_SZPROF)
	if (streq (label, "INDEF"))
	    call strcpy (Memc[id], LID_LABEL(lid), LID_SZLINE)
	else
	    call strcpy (label, LID_LABEL(lid), LID_SZLINE)

	# Set values.
	LID_DRAW(lid) = YES
	LID_X(lid) = x
	LID_LABY(lid) = y
	LID_LABTICK(lid) = flags[1]
	LID_LABARROW(lid) = flags[2]
	LID_LABBAND(lid) = flags[3]
	LID_LABX(lid) = flags[4]
	LID_LABREF(lid) = flags[5]
	LID_LABID(lid) = flags[6]
	call strcpy (format, LID_LABFMT(lid), LID_SZLINE)
	LID_LABCOL(lid) = color

	MOD_DRAW(lid) = YES
	MOD_PDRAW(lid) = SPT_MODPDRAW(spt)
	MOD_PCOL(lid) = SPT_MODPCOL(spt)
	MOD_SDRAW(lid) = SPT_MODSDRAW(spt)
	MOD_SCOL(lid) = SPT_MODSCOL(spt)
	MOD_CDRAW(lid) = SPT_MODCDRAW(spt)
	MOD_CCOL(lid) = SPT_MODCCOL(spt)
	MOD_FIT(lid) = NO
	EQW_E(lid,1) = INDEFD

	# Allocate/reallocate register list of lines.
	lids = REG_LIDS(reg)
	if (lids == NULL) {
	    call malloc (lids, 2+10, TY_POINTER)
	    LID_NLINES(lids) = 0
	    LID_LID(lids) = NULL
	} else if (mod (LID_NLINES(lids), 10) == 0)
	    call realloc (lids, 2+LID_NLINES(lids)+10, TY_POINTER)

	# Add line to list sorted by X.
	LID_NLINES(lids) = LID_NLINES(lids) + 1
	do i = LID_NLINES(lids), 2, -1 {
	    ptr = LID_LINES(lids,i-1)
	    if (LID_X(lid) >= LID_X(ptr))
		break
	    LID_ITEM(ptr) = i
	    LID_LINES(lids,i) = ptr
	}
	LID_ITEM(lid) = i
	LID_LINES(lids,i) = lid
	REG_LIDS(reg) = lids

	call sfree (sp)
end


# LID_ADD -- Add or replace a new line ID.

procedure lid_add (spt, reg, lid, replace, match, x, low, up, prof, ref, y, id)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register pointer
pointer	lid		#O New line
int	replace		#I Replace an existing line?
int	match		#I Match against line list?
double	x, y		#I X, Y position for label
double	low, up		#I Limits
char	prof[ARB]	#I Profile type
double	ref		#U Reference
char	id[ARB]		#U ID string

int	i
double	pix, shdr_wl()
pointer	sh
bool	strne()
errchk	lid_alloc, spt_ctr

begin
	if (reg == NULL)
	    return
	sh = REG_SH(reg)

	pix = shdr_wl (sh, x)
	i = INDEFI
	call lid_near (spt, reg, x, INDEFD, lid)
	if (lid != NULL)
	    if (abs (pix - shdr_wl (sh, LID_X(lid))) > SPT_SEP(spt))
		lid = NULL

	if (lid == NULL) {
	    call lid_alloc (spt, reg, lid, match, x, low, up, prof, ref,
		y, id, SPT_DLABTICK(spt), SPT_DLABFMT(spt),
		SPT_DLABCOL(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "center %d")
		call pargi (LID_ITEM(lid))
	    iferr (call spt_ctr (spt, reg, x, y, SPT_STRING(spt))) {
		call lid_delete (spt, reg, LID_ITEM(lid))
		call lid_list (spt, reg, NULL)
		lid = NULL
		call erract (EA_ERROR)
	    }
	} else if (replace == YES) {
	    call lid_erase (spt, reg, lid)
	    if (!IS_INDEFD(x))
		LID_X(lid) = x
#	    if (!IS_INDEFD(y))
#		LID_LABY(lid) = y
	    if (!IS_INDEFD(low))
		LID_LOW(lid) = low
	    if (!IS_INDEFD(up))
		LID_UP(lid) = up
	    if (LID_LOW(lid) > LID_UP(lid)) {
		up = LID_LOW(lid)
		LID_LOW(lid) = LID_UP(lid)
		LID_UP(lid) = up
	    }
	    if (strne (prof, "INDEF"))
		call strcpy (prof, MOD_PROF(lid), LID_SZPROF)
	    if (!IS_INDEFD (ref)) {
		if (ref != LID_REF(lid))
		    LID_LLINDEX(lid) = 0
		LID_REF(lid) = ref
	    }
	    if (strne (id, "INDEF"))
		call strcpy (id, LID_LABEL(lid), LID_SZLINE)
	}
	call lid_mark1 (spt, reg, lid)
end


# LID_Y -- Compute the NDC label offset.

procedure lid_y (spt, reg, wx, wy, ydef, y)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
double	wx, wy		#I Cursor position
double	ydef		#I Default y position
double	y		#O Y position of label

int	i
real	mx, my1, my2
pointer	gp, sh, sy
double	shdr_wl()

begin
	gp = SPT_GP(spt)
	sh = REG_SH(reg)
	sy = SPT_SPEC(spt) - 1

	i = max (2, min (SN(sh)-1, nint(shdr_wl(sh,wx))))
	if (IS_INDEFD(wy)) {
	    y = Memr[sy+i] - (Memr[sy+i-1] + Memr[sy+i+1]) / 2.
	    if (y < 0.)
		y = min (Memr[sy+i-1], Memr[sy+i], Memr[sy+i+1])
	    else
		y = max (Memr[sy+i-1], Memr[sy+i], Memr[sy+i+1])
	} else {
	    y = min (Memr[sy+i-1], Memr[sy+i], Memr[sy+i+1])
	    if (wy > y)
		y = max (Memr[sy+i-1], Memr[sy+i], Memr[sy+i+1])
	}

	if (IS_INDEFD(ydef)) {
	    call gctran (gp, real(wx), real(wy), mx, my1, 1, 0)
	    call gctran (gp, real(wx), real(y), mx, my2, 1, 0)
	    if (wy > y)
		y = abs (my1 - my2)
	    else
		y = -abs (my1 - my2)
	} else {
	    if (wy > y)
		y = abs (ydef)
	    else
		y = -abs (ydef)
	}
end


# LID_NEAR -- Find the nearest line identification to the cursor.
# This routine assumes the scaled spectrum is in SPT_SPEC.

procedure lid_near (spt, reg, wx, wy, lid)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
double	wx, wy		#I Cursor position
pointer	lid		#O Line ID pointer

int	i
real	r2, r2min
pointer	lids, ptr
#bool	above, tick
#real	x, y, ticks[2,7]
#real	mx1, my1, mx2, my2
#pointer	gp

begin
	lid = NULL
	if (IS_INDEFD(wx) || reg == NULL)
	    return
	if (REG_LIDS(reg) == NULL)
	    return
	if (LID_NLINES(REG_LIDS(reg)) == 0)
	    return

	lids = REG_LIDS(reg)

	r2min = MAX_REAL
#	if (IS_INDEFD(wy)) {
	    do i = 1, LID_NLINES(lids) {
		ptr = LID_LINES(lids,i)
		r2 = abs (wx - LID_X(ptr))
		if (r2 < r2min) {
		    lid = ptr
		    r2min = r2
		}
	    }
#	} else {
#	    gp = SPT_GP(spt)
#	    call gctran (gp, real(wx), real(wy), mx1, my1, 1, 0)
#	    do i = 1, LID_NLINES(lids) {
#		ptr = LID_LINES(lids,i)
#		call lid_pos (spt, reg, ptr, above, tick, x, y, ticks)
#		call gctran (gp, x, y, mx2, my2, 1, 0)
#		r2 = (mx1 - mx2) ** 2 + (my1 - my2) ** 2
#		if (r2 < r2min) {
#		    lid = ptr
#		    r2min = r2
#		}
#	    }
#	}
end


# LID_ITEM -- Get the line ID pointer given the item number.

procedure lid_item (spt, reg, item, lid)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register pointer
int	item		#I Line ID item number
pointer	lid		#O Line ID pointer

pointer	lids

begin
	lid = NULL
	if (reg == NULL || item == 0)
	    return

	lids = REG_LIDS(reg)
	if (lids != NULL) {
	    if (item >= 1 && item <= LID_NLINES(lids))
		lid = LID_LINES(lids,item)
	}

	if (lid == NULL)
	    call error (1, "Line not found")

end


procedure lid_copy (spt, reg1, reg2)

pointer	spt		#I Spectool pointer
pointer	reg1		#I Source register
pointer	reg2		#I Target register

int	i
pointer	lids1, lids2, lid1, lid2, un1, un2
bool	dounits

begin
	if (reg1 == NULL || reg2 == NULL)
	    return

	lids1 = REG_LIDS(reg1)
	lids2 = REG_LIDS(reg2)

	if (lids1 == NULL || lids2 != NULL)
	    return

	dounits = false
	if (REG_SH(reg1) != NULL && REG_SH(reg2) != NULL) {
	    un1 = UN(REG_SH(reg1))
	    un2 = UN(REG_SH(reg2))
	    if (un1 != NULL && un2 != NULL) {
		dounits = (UN_CLASS(un1)!=UN_UNKNOWN&&UN_CLASS(un2)!=UN_UNKNOWN)
		if (!dounits && UN_CLASS(un1)!=UN_CLASS(un2))
		    return
	    }
	}

	call calloc (lids2, int((LID_NLINES(lids1)+9)/10)*10, TY_POINTER)
	LID_NLINES(lids2) = LID_NLINES(lids1)
	do i = 1, LID_NLINES(lids1) {
	    lid1 = LID_LINES(lids1,i)
	    call malloc (lid2, LID_LEN, TY_STRUCT)
	    call amovi (Memi[lid1], Memi[lid2], LID_LEN)
	    if (dounits) {
		call un_ctrand (un1, un2, LID_X(lid1), LID_X(lid2), 1)
		if (!IS_INDEFD(LID_REF(lid1)))
		    call un_ctrand (un1, un2, LID_REF(lid1), LID_REF(lid2), 1)
	    }
	    MOD_FIT(lid2) = NO
	    EQW_E(lid2,1) = INDEFD
	    LID_LINES(lids2,i) = lid2
	}


	REG_LIDS(reg2) = lids2
end


# LID_LIST -- Send line ID list to GUI.

procedure lid_list (spt, reg, lid)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
pointer	lid			#I Active line ID pointer

int	i, n, len_list, fd, stropen()
pointer	sp, list, lids, ptr

begin
	if (reg == NULL)
	    lids = NULL
	else
	    lids = REG_LIDS(reg)

	if (lids == NULL)
	    n = 0
	else
	    n = LID_NLINES(lids)
	len_list = max (1, n) * SZ_FNAME

	call smark (sp)
	call salloc (list, len_list, TY_CHAR)

	fd = stropen (Memc[list], len_list, WRITE_ONLY)
	do i = 1, n {
	    ptr = LID_LINES(lids,i)
	    call fprintf (fd, "\"%c %10.8g %10.8g %10.8g %10.8g %s\" ")
		if (MOD_FIT(ptr) == YES) {
		    if (MOD_SUB(ptr) == NO)
			call pargi ('+')
		    else
			call pargi ('-')
		} else
		    call pargi (' ')
		call pargd (LID_X(ptr))
		call pargd (LID_REF(ptr))
		call pargd (LID_LOW(ptr))
		call pargd (LID_UP(ptr))
		call pargstr (LID_LABEL(ptr))
	}
	call close (fd)
	call gmsg (SPT_GP(spt), "lidslist", Memc[list])

	if (lids == NULL)
	    ptr = NULL
	else {
	    ptr = lid
	    if (lid != NULL)
		LID_LID(lids) = lid
	    #ptr = LID_LID(lids)
	}

	if (ptr != NULL) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %6.2f %d %d %d %d %d %d \"%s\" %d")
		call pargi (LID_DRAW(ptr))
		call pargd (LID_LABY(ptr))
		call pargi (LID_LABX(ptr))
		call pargi (LID_LABREF(ptr))
		call pargi (LID_LABID(ptr))
		call pargi (LID_LABTICK(ptr))
		call pargi (LID_LABARROW(ptr))
		call pargi (LID_LABBAND(ptr))
		call pargstr (LID_LABFMT(ptr))
		call pargi (LID_LABCOL(ptr))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"1 %6.2f %d %d %d %d %d %d \"%s\" %d")
		call pargd (SPT_DLABY(spt))
		call pargi (SPT_DLABX(spt))
		call pargi (SPT_DLABREF(spt))
		call pargi (SPT_DLABID(spt))
		call pargi (SPT_DLABTICK(spt))
		call pargi (SPT_DLABARROW(spt))
		call pargi (SPT_DLABBAND(spt))
		call pargstr (SPT_DLABFMT(spt))
		call pargi (SPT_DLABCOL(spt))
	}
	call gmsg (SPT_GP(spt), "lidsset", SPT_STRING(spt))

	if (ptr != NULL) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %.8g %.8g %.8g %.8g \"%s\" %d")
		call pargi (LID_ITEM(ptr))
		call pargd (LID_X(ptr))
		call pargd (LID_REF(ptr))
		call pargd (LID_LOW(ptr))
		call pargd (LID_UP(ptr))
		call pargstr (LID_LABEL(ptr))
		call pargi (LID_LLINDEX(ptr))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"0 INDEF INDEF %.8g %.8g \"\" 0")
		call pargd (SPT_DLOW(spt))
		call pargd (SPT_DUP(spt))
	}
	call gmsg (SPT_GP(spt), "line", SPT_STRING(spt))
	
	call mod_values (spt, reg, ptr)
	call eqw_values (spt, reg, ptr)

	call sfree (sp)
end
