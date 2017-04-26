include	<ctype.h>
include	<gset.h>
include	<smw.h>
include	<error.h>
include	<mach.h>
include	<pkg/gtools.h>
include	"spectool.h"
include	"labels.h"

# Routines to manage labels.
# LAB_COLON   -- Interpret label colon commands.
#
# LAB_ALLOC   -- Allocate label structure.
# LAB_FREE    -- Free label structure.
# LAB_LIST    -- Send (update) label list to GUI.
# LAB_PLOT    -- Plot labels.
# LAB_PLOT1   -- Plot a single line in spectrum.
# LAB_ERASE   -- Erase a single line ID label.
# LAB_SET     -- Set a label and allocate if need.
# LAB_ITEM    -- Get the label pointer given the item number.
# LAB_TYPE    -- Set coordinate type.


# List of colon commands.
define	CMDS	"|open|close|free|read|write|label|labpars|glabel|slabel|type\
		 |delete|select|list|plot|units|funits|"


define	OPEN		1	# Open/allocate/initialize
define	CLOSE		2	# Close/free
define	FREE		3	# Free register
define	READ		4	# Read a file of labels
define	WRITE		5	# Save a file of labels
define	LABEL		6	# Draw labels
define	LABPARS		7	# Set label parameters
define	GLABEL		8	# Add a new label with the cursor
define	SLABEL		9	# Add a new label with the cursor
define	TYPE		10	# Set WCS type
define	DELETE		11	# Delete a label with cursor
define	SELECT		12	# Select label by list item number
define	LIST 		13	# Send labels to GUI
define	PLOT 		14	# Plot the labels
define	UNIT		15	# Change units
define	FUNIT		16	# Change units

define	TYPES	"|spectrum|graph|"
define	LABSPEC		1
define	LABGRAPH	2



# LAB_COLON -- Interpret label colon commands.

procedure lab_colon (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
double	wx, wy			#I GIO coordinate
char	cmd[ARB]		#I GIO command

int	i, j, item, draw, ncmd, fd, color
double	x, y
pointer	labs, lab
pointer	sp, id, format

int	clgwrd(), strdic(), open(), fscan(), nscan(), btoi()
bool	clgetb(), streq()
double	shdr_lw(), shdr_wl()
errchk	lab_item, fun_changed()

define	err_	10
define	done_	20

begin
	call smark (sp)
	call salloc (id, SZ_LINE, TY_CHAR)
	call salloc (format, SZ_LINE, TY_CHAR)

	if (reg != NULL)
	    labs = REG_LABS(reg)
	else
	    labs = NULL

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[id], SZ_LINE)
	ncmd = strdic (Memc[id], Memc[id], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    SPT_LABEL(spt) = btoi (clgetb ("labshow"))
	    SPT_LABTYPE(spt) = clgwrd ("labtype", SPT_STRING(spt), SPT_SZLINE,
		TYPES)
	    call clgstr ("labformat", SPT_LABFMT(spt), LAB_SZLINE)
	    SPT_LABCOL(spt) = clgwrd ("labcolor", SPT_STRING(spt),
		SPT_SZSTRING, COLORS) - 1

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "labels %d")
		call pargi (SPT_LABEL(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call gmsg (SPT_GP(spt), "setGui", "labelall 0")

	    call lab_list (spt, NULL, NULL)

	case CLOSE: # close
	    call clputb ("labshow", SPT_LABEL(spt)==YES)
	    call clpstr ("labformat", SPT_LABFMT(spt))
	    call spt_dic (COLORS, SPT_LABCOL(spt)+1, SPT_STRING(spt),
		SPT_SZSTRING)
	    call clpstr ("labcolor", SPT_STRING(spt))

	case FREE: # free
	    call lab_free (spt, reg)

	case READ: # read file
	    call gargwrd (Memc[id], SZ_LINE)
	    if (nscan() != 2)
		goto done_
	    iferr (fd = open (Memc[id], READ_ONLY, TEXT_FILE))
		goto err_
	    while (fscan (fd) != EOF) {
		call gargd (x)
		call gargd (y)
		call gargwrd (Memc[id], SZ_LINE)
		if (nscan() < 3)
		    next
		lab = NULL
		call lab_set (spt, reg, lab, x, y, LABSPEC, Memc[id],
		    SPT_LABTYPE(spt), Memc[format], color)
		SPT_REDRAW(spt,1) = YES
	    }
	    call close (fd)
	    call lab_list (spt, reg, NULL)

	case WRITE: # write file
	    call gargwrd (Memc[id], SZ_LINE)
	    if (LAB_NLABELS(labs) == 0 || nscan() != 2)
		goto done_
	    iferr (fd = open (Memc[id], NEW_FILE, TEXT_FILE))
		goto err_
	    do i = 1, LAB_NLABELS(labs) {
		lab = LAB_LABELS(labs,i)
		if (lab == NULL)
		    next
		call fprintf (fd, "%10.8g %10.8f \"%s\" %d\n")
		    call pargd (LAB_X(lab))
		    call pargd (LAB_Y(lab))
		    call pargstr (LAB_LABEL(lab))
		    call pargi (LAB_TYPE(lab))
	    }
	    call close (fd)

	case LABEL: # label [item draw]
	    call gargi (item)
	    call gargi (draw)

	    if (nscan() < 2)
		item = -1
	    if (nscan() < 3)
		draw = 2

	    if (item > 0) {
		call lab_item (spt, reg, item, lab)
		if (lab != NULL) {
		    call lab_erase (spt, reg, lab)
		    if (draw == 2)
			LAB_DRAW(lab) = btoi (LAB_DRAW(lab)==NO)
		    else
			LAB_DRAW(lab) = draw
		    call lab_plot1 (spt, reg, lab)
		    call lab_list (spt, reg, lab)
		}
	    } else if (item == -1 && labs != NULL) {
		do i = 1, LAB_NLABELS(labs) {
		    lab = LAB_LABELS(labs,i)
		    call lab_erase (spt, reg, lab)
		    if (draw == 2)
			LAB_DRAW(lab) = btoi (LAB_DRAW(lab)==NO)
		    else
			LAB_DRAW(lab) = draw
		    call lab_plot1 (spt, reg, lab)
		}
		call lab_list (spt, reg, NULL)
	    }

	case LABPARS: # labpars item type format color label x y
	    call gargi (item)
	    call gargi (i)
	    call gargwrd (Memc[format], SZ_LINE)
	    call gargi (color)
	    call gargwrd (Memc[id], SZ_LINE)
	    call gargd (x)
	    call gargd (y)

	    # Set defaults.
	    if (nscan() >4) {
		SPT_LABTYPE(spt) = i
		call strcpy (Memc[format], SPT_LABFMT(spt), LAB_SZLINE)
		SPT_LABCOL(spt) = color
	    }
	    if (nscan() < 8)
		goto done_

	    if (item == -1) {
		do i = 1, LAB_NLABELS(labs) {
		    lab = LAB_LABELS(labs,i)
		    call lab_erase (spt, reg, lab)
		    call strcpy (Memc[format], LAB_FMT(lab), LAB_SZLINE)
		    LAB_COL(lab) = color
		    call lab_plot1 (spt, reg, lab)
		}
	    } else if (item == 0) {
		lab = NULL
		call lab_set (spt, reg, lab, x, y, SPT_LABTYPE(spt), Memc[id],
		    SPT_LABTYPE(spt), SPT_LABFMT(spt), SPT_LABCOL(spt))
		if (lab != NULL) {
		    call lab_plot1 (spt, reg, lab)
		    call lab_list (spt, reg, lab)
		}
	    } else {
		call lab_item (spt, reg, item, lab)
		if (lab != NULL) {
		    call lab_erase (spt, reg, lab)
		    LAB_X(lab) = x
		    LAB_Y(lab) = y
		    call strcpy (Memc[id], LAB_LABEL(lab), LAB_SZLINE)
		    LAB_TYPE(lab) = i
		    call strcpy (Memc[format], LAB_FMT(lab), LAB_SZLINE)
		    LAB_COL(lab) = color
		    call lab_plot1 (spt, reg, lab)
		    call lab_list (spt, reg, lab)
		}
	    }

	case SLABEL: # slabel label
	    x = wx
	    y = wy
	    call gargstr (Memc[id], SZ_LINE)
	    for (i=id; IS_WHITE(Memc[i]); i=i+1)
		;
	    call strcpy (Memc[i], Memc[id], SZ_LINE)
	    lab = NULL
	    call lab_set (spt, reg, lab, x, y, LABSPEC, Memc[id],
		LABSPEC, SPT_LABFMT(spt), SPT_LABCOL(spt))
	    if (lab != NULL) {
		call lab_plot1 (spt, reg, lab)
		call lab_list (spt, reg, lab)
	    }

	case GLABEL: # glabel label
	    x = wx
	    y = wy
	    call gargstr (Memc[id], SZ_LINE)
	    for (i=id; IS_WHITE(Memc[i]); i=i+1)
		;
	    call strcpy (Memc[i], Memc[id], SZ_LINE)
	    lab = NULL
	    call lab_set (spt, reg, lab, x, y, LABSPEC, Memc[id],
		LABGRAPH, SPT_LABFMT(spt), SPT_LABCOL(spt))
	    if (lab != NULL) {
		call lab_plot1 (spt, reg, lab)
		call lab_list (spt, reg, lab)
	    }

	case TYPE: # type item type
	    call gargi (item)
	    call gargi (j)
	    if (nscan() < 3)
		goto err_

	    SPT_LABTYPE(spt) = j

	    if (!IS_INDEFI(item)) {
		call lab_item (spt, reg, item, lab)
		call lab_type (spt, reg, lab, j, LAB_X(lab), LAB_Y(lab))
		LAB_TYPE(lab) = j
		call lab_list (spt, reg, lab)
	    } else if (labs != NULL) {
		do i = 1, LAB_NLABELS(labs) {
		    lab = LAB_LABELS(labs,i)
		    call lab_type (spt, reg, lab, j, LAB_X(lab), LAB_Y(lab))
		    LAB_TYPE(lab) = j
		}
		call lab_list (spt, reg, lab)
	    }

	case DELETE: # delete item
	    call gargi (item)

	    if (nscan() == 1)
		call lab_delete (spt, reg, INDEFI)
	    else
		call lab_delete (spt, reg, item)
	    call lab_list (spt, reg, NULL)

	case SELECT: # select item
	    call gargi (item)

	    if (nscan() == 2) {
		call lab_item (spt, reg, item, lab)
		call strcpy (LAB_FMT(lab), SPT_LABFMT(spt), LAB_SZLINE)
		call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		    "%d %d %10.8g %10.8g \"%s\" %d \"%s\" %d")
		    call pargi (LAB_DRAW(lab))
		    call pargi (j)
		    call pargd (LAB_X(lab))
		    call pargd (LAB_Y(lab))
		    call pargstr (LAB_LABEL(lab))
		    call pargi (LAB_TYPE(lab))
		    call pargstr (LAB_FMT(lab))
		    call pargi (LAB_COL(lab))
		call gmsg (SPT_GP(spt), "labelset", SPT_STRING(spt))
	    } else
		call lab_list (spt, reg, NULL)

	case LIST: # list
	    call lab_list (spt, reg, NULL)

	case PLOT: # plot
	    call lab_plot (spt, reg)

	case UNIT: # units
	    call gargwrd (Memc[id], SZ_LINE)
	    if (nscan() != 2)
		goto err_

	    if (labs == NULL || REG_SH(reg) == NULL)
		goto done_

	    if (streq (Memc[id], "logical")) {
		do i = 1, LAB_NLABELS(labs) {
		    lab = LAB_LABELS(labs,i)
		    if (LAB_TYPE(lab) == LABSPEC)
			LAB_X(lab) = shdr_wl (REG_SH(reg), LAB_X(lab))
		}
	    } else {
		do i = 1, LAB_NLABELS(labs) {
		    lab = LAB_LABELS(labs,i)
		    if (LAB_TYPE(lab) == LABSPEC)
			LAB_X(lab) = shdr_lw (REG_SH(reg), LAB_X(lab))
		}
		call lab_list (spt, reg, NULL)
	    }

	case FUNIT: # funits
	    call gargwrd (Memc[id], SZ_LINE)
	    if (nscan() != 2)
		goto err_

	    if (labs == NULL || REG_SH(reg) == NULL)
		goto done_

	    do i = 1, LAB_NLABELS(labs) {
		lab = LAB_LABELS(labs,i)
		if (LAB_TYPE(lab) == LABSPEC)
		    call fun_changed (FUN(REG_SH(reg)), Memc[id],
			UN(REG_SH(reg)), LAB_X(lab), LAB_Y(lab), 1, NO)
	    }
	    call lab_list (spt, reg, NULL)

	default: # error or unknown command
err_	    call sprintf (Memc[id], SZ_LINE,
		"Error in colon command: %g %g label %s")
		call pargd (wx)
		call pargd (wy)
		call pargstr (cmd)
	    call error (1, Memc[id])
	}

done_	call sfree (sp)
end


# LAB_ALLOC -- Allocate label structures.

procedure lab_alloc (spt, reg, lab)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lab		#O Line ID

pointer	labs

begin
	if (reg == NULL)
	    return

	labs = REG_LABS(reg)
	if (labs == NULL) {
	    call malloc (labs, 10, TY_POINTER)
	    LAB_NLABELS(labs) = 0
	} else if (mod (LAB_NLABELS(labs), 10) == 0)
	    call realloc (labs, LAB_NLABELS(labs)+10, TY_POINTER)

	call calloc (lab, LAB_LEN, TY_STRUCT)

	LAB_NLABELS(labs) = LAB_NLABELS(labs) + 1
	LAB_ITEM(lab) = LAB_NLABELS(labs)
	LAB_LABELS(labs,LAB_NLABELS(labs)) = lab
	REG_LABS(reg) = labs
end


# LAB_FREE -- Free spectrum label structure.

procedure lab_free (spt, reg)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register

int	i
pointer	labs

begin
	if (reg == NULL)
	    return
	if (REG_LABS(reg) == NULL)
	    return

	labs = REG_LABS(reg)
	do i = 1, LAB_NLABELS(labs)
	    call mfree (LAB_LABELS(labs,i), TY_STRUCT)
	call mfree (REG_LABS(reg), TY_POINTER)
end


# LAB_DELETE -- Delete label.

procedure lab_delete (spt, reg, item)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
int	item		#I Item to delete (INDEFI = all)

int	i, nlabels
pointer	labs, lab

begin
	if (reg == NULL)
	    return
	if (REG_LABS(reg) == NULL)
	    return

	labs = REG_LABS(reg)
	nlabels = LAB_NLABELS(labs)
	if (!IS_INDEFI(item)) {
	    if (item < 1 || item > nlabels)
		return
	    lab = LAB_LABELS(labs,item)
	    call lab_erase (spt, reg, lab)
	    call mfree (lab, TY_STRUCT)
	    nlabels = nlabels - 1

	    do i = item, nlabels {
		lab = LAB_LABELS(labs,i+1)
		LAB_LABELS(labs,i) = lab
		LAB_ITEM(lab) = i
	    }
	} else {
	    do i = 1, nlabels {
		lab = LAB_LABELS(labs,i)
		call lab_erase (spt, reg, lab)
		call mfree (lab, TY_STRUCT)
	    }
	    nlabels = 0
	}
	LAB_NLABELS(labs) = nlabels

	if (nlabels == 0)
	    call mfree (REG_LABS(reg), TY_POINTER)
end


# LAB_PLOT -- Plot labels.

procedure lab_plot (spt, reg)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register

int	i
pointer	labs

begin
	if (SPT_LABEL(spt) == NO || reg == NULL)
	    return
	if (REG_LABEL(reg) == NO || REG_LABS(reg) == NULL)
	    return

	labs = REG_LABS(reg)
	do i = 1, LAB_NLABELS(labs)
	    call lab_plot1 (spt, reg, LAB_LABELS(labs,i))
end


# LAB_PLOT1 -- Plot a single label.

procedure lab_plot1 (spt, reg, lab)

pointer	spt		#I Spectool
pointer	reg		#I Register
pointer	lab		#I Label

double	x, y
int	i, gstati()
pointer	gp

begin
	if (SPT_LABEL(spt) == NO || reg == NULL || lab == NULL)
	    return
	if (REG_LABEL(reg) == NO || LAB_DRAW(lab) == NO)
	    return

	call lab_type (spt, reg, lab, LABSPEC, x, y)

	gp = SPT_GP(spt)
	i = gstati (gp, G_TXCOLOR)
	call gseti (gp, G_TXCOLOR, LAB_COL(lab))
	switch (LAB_FMT(lab)) {
	case 'H':
	    call gtext (gp, real(x), real(y), LAB_LABEL(lab), "h=c;v=c")
	case 'V':
	    call gtext (gp, real(x), real(y), LAB_LABEL(lab), "h=c;v=c;u=0")
	default:
	    call gtext (gp, real(x), real(y), LAB_LABEL(lab), LAB_FMT(lab))
	}
	call gseti (gp, G_TXCOLOR, i)

	call gflush (gp)
end


# LAB_ERASE -- Erase a single label.
# This will fail if the color is specified in the label format.

procedure lab_erase (spt, reg, lab)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lab		#I Line ID label to erase

int	i

begin
	if (SPT_LABEL(spt) == NO || reg == NULL || lab == NULL)
	    return
	if (REG_LABEL(reg) == NO || LAB_DRAW(lab) == NO)
	    return

	i = LAB_COL(lab)
	LAB_COL(lab) = 0
	call lab_plot1 (spt, reg, lab)
	LAB_COL(lab) = i
end


# LAB_SET -- Set a label.  Allocate if needed.

procedure lab_set (spt, reg, lab, x, y, itype, label, ptype, format, color)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lab		#O Line ID pointer
double	x, y		#I X, Y position for label
int	itype		#I Input WCS type
char	label[ARB]	#I Label string
int	ptype		#I Plot WCS type
char	format[ARB]	#I Label format
int	color		#I Color

bool	streq()

begin
	if (reg == NULL)
	    return
	if (lab == NULL)
	    call lab_alloc (spt, reg, lab)

	LAB_DRAW(lab) = YES
	LAB_X(lab) = x
	LAB_Y(lab) = y
	LAB_TYPE(lab) = itype
	if (streq (label, "INDEF"))
	    call clgstr ("label", LAB_LABEL(lab), LAB_SZLINE)
	else
	    call strcpy (label, LAB_LABEL(lab), LAB_SZLINE)
	call strcpy (format, LAB_FMT(lab), LAB_SZLINE)
	LAB_COL(lab) = color

	call lab_type (spt, reg, lab, ptype, LAB_X(lab), LAB_Y(lab))
	LAB_TYPE(lab) = ptype
end


# LAB_ITEM -- Get the label pointer given the item number.

procedure lab_item (spt, reg, item, lab)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
int	item		#I Label item number
pointer	lab		#O Label pointer

pointer	labs

begin
	if (reg == NULL)
	    return

	labs = REG_LABS(reg)
	lab = NULL
	if (labs != NULL) {
	    if (item >= 1 && item <= LAB_NLABELS(labs))
		lab = LAB_LABELS(labs,item)
	}

	if (lab == NULL)
	    call error (1, "Label not found")
end


# LAB_TYPE -- Set coordinate type.

procedure lab_type (spt, reg, lab, type, x, y)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lab		#I Label pointer
int	type		#I WCS type
double	x, y		#O Coordinates

real	wx1, wx2, wy1, wy2

begin
	if (reg == NULL || lab == NULL)
	    return

	x = LAB_X(lab)
	y = LAB_Y(lab)
	if (LAB_TYPE(lab) == LABSPEC)
	    y = y * REG_SSCALE(reg) + REG_STEP(reg)
	if (LAB_TYPE(lab) == type)
	    return

	call ggwind (SPT_GP(spt), wx1, wx2, wy1, wy2)
	switch (type) {
	case LABSPEC:
	    x = x * (wx2 - wx1) + wx1
	    y = y * (wy2 - wy1) + wy1
	case LABGRAPH:
	    x = (x - wx1) / (wx2 - wx1)
	    y = (y - wy1) / (wy2 - wy1)
	}
end


procedure lab_copy (spt, reg1, reg2)

pointer	spt		#I Spectool pointer
pointer	reg1		#I Source register
pointer	reg2		#I Target register

int	i
pointer	labs1, labs2, lab1, lab2

begin
	if (reg1 == NULL || reg2 == NULL)
	    return

	labs1 = REG_LABS(reg1)
	labs2 = REG_LABS(reg2)

	if (labs1 == NULL || labs2 != NULL)
	    return

	call calloc (labs2, int((LAB_NLABELS(labs1)+9)/10)*10, TY_POINTER)
	LAB_NLABELS(labs2) = LAB_NLABELS(labs1)
	do i = 1, LAB_NLABELS(labs1) {
	    lab1 = LAB_LABELS(labs1,i)
	    call malloc (lab2, LAB_LEN, TY_STRUCT)
	    call amovi (Memi[lab1], Memi[lab2], LAB_LEN)
	    LAB_LABELS(labs2,i) = lab2
	}

	REG_LABS(reg2) = labs2
end


# LAB_LIST -- Send label list to GUI.

procedure lab_list (spt, reg, lab)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
pointer	lab			#I Current label

int	i, n, len_list, fd, stropen()
pointer	sp, list, ptr, labs

begin
	if (reg == NULL)
	    labs = NULL
	else
	    labs = REG_LABS(reg)

	if (labs == NULL)
	    n = 0
	else
	    n = LAB_NLABELS(labs)
	len_list = max (1, n) * SZ_FNAME

	call smark (sp)
	call salloc (list, len_list, TY_CHAR)

	fd = stropen (Memc[list], len_list, WRITE_ONLY)
	do i = 1, n {
	    ptr = LAB_LABELS(labs,i)
	    call fprintf (fd, "\"%10.8g %10.8g %s\" ")
		call pargd (LAB_X(ptr))
		call pargd (LAB_Y(ptr))
		call pargstr (LAB_LABEL(ptr))
	}
	call close (fd)
	call gmsg (SPT_GP(spt), "labellist", Memc[list])

	ptr = lab
	if (ptr == NULL && n > 0)
	    ptr = LAB_LABELS(labs,1)

	if (ptr != NULL) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"%d %d %10.8g %10.8g \"%s\" %d \"%s\" %d")
		call pargi (LAB_DRAW(ptr))
		call pargi (LAB_ITEM(ptr))
		call pargd (LAB_X(ptr))
		call pargd (LAB_Y(ptr))
		call pargstr (LAB_LABEL(ptr))
		call pargi (LAB_TYPE(ptr))
		call pargstr (LAB_FMT(ptr))
		call pargi (LAB_COL(ptr))
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"1 0 \"\" \"\" \"\" %d \"%s\" %d")
		call pargi (SPT_LABTYPE(spt))
		call pargstr (SPT_LABFMT(spt))
		call pargi (SPT_LABCOL(spt))
	}
	call gmsg (SPT_GP(spt), "labelset", SPT_STRING(spt))

	call sfree (sp)
end
