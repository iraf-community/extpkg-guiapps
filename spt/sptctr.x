include	<smw.h>
include	"spectool.h"
include	"lids.h"


# List of commands.
define  CMDS     "|open|close|set|center|coordinate|"

define  OPEN    	1       # Open
define  CLOSE		2       # Close
define  SET		3       # Set parameters
define	CENTER		4	# Center line
define	COORD		5	# Center coordinate

# SPT_CTR -- Interpret CTR colon commands.

procedure spt_ctr (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
double	wx, wy			#U Coordinates
char	cmd[ARB]		#I Command

int	i, j, item, strdic(), nscan()
real	pix, pix1, clgetr(), spt_center1d()
double	x, shdr_lw(), shdr_wl()
pointer	sh, lids, lid
errchk	lid_item, spt_center1d

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	i = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (i) {
	case OPEN: # open
	    call clgstr ("ctype", SPT_CTR_CTYPE(spt), 11)
	    call clgstr ("cprofile", SPT_CTR_PTYPE(spt), 11)
	    SPT_CTR_WIDTH(spt) = clgetr ("cwidth")
	    SPT_CTR_RADIUS(spt) = clgetr ("cradius")
	    SPT_CTR_THRESH(spt) = 0.

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%s %s %g %g")
		call pargstr (SPT_CTR_CTYPE(spt))
		call pargstr (SPT_CTR_PTYPE(spt))
		call pargr (SPT_CTR_WIDTH(spt))
		call pargr (SPT_CTR_RADIUS(spt))
	    call gmsg (SPT_GP(spt), "ctrpars", SPT_STRING(spt))

	case CLOSE: # close
	    call clpstr ("ctype", SPT_CTR_CTYPE(spt))
	    call clpstr ("cprofile", SPT_CTR_PTYPE(spt))
	    call clputr ("cwidth", SPT_CTR_WIDTH(spt))
	    call clputr ("cradius", SPT_CTR_RADIUS(spt))

	case SET: # set ctype ptype width radius
	    call gargwrd (SPT_CTR_CTYPE(spt), 11)
	    call gargwrd (SPT_CTR_PTYPE(spt), 11)
	    call gargr (SPT_CTR_WIDTH(spt))
	    call gargr (SPT_CTR_RADIUS(spt))

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%s %s %g %g")
		call pargstr (SPT_CTR_CTYPE(spt))
		call pargstr (SPT_CTR_PTYPE(spt))
		call pargr (SPT_CTR_WIDTH(spt))
		call pargr (SPT_CTR_RADIUS(spt))
	    call gmsg (SPT_GP(spt), "ctrpars", SPT_STRING(spt))

	case CENTER: # center [item]
	    call gargi (item)
	    if (nscan() == 1)
		item = -1

	    x = wx
	    wx = INDEFD
	    if (item == 0 || reg == NULL)
		return

	    lids = REG_LIDS(reg)
	    sh = REG_SH(reg)
	    if (lids == NULL || sh == NULL)
		return

	    if (item == -1) {
		do i = 1, LID_NLINES(lids) {
		    lid = LID_LINES(lids,i)
		    pix = shdr_wl (sh, LID_X(lid))
		    pix = spt_center1d (pix, Memr[SPEC(sh,SPT_CTYPE(spt))],
			SN(sh), SPT_CTR_CTYPE(spt), SPT_CTR_PTYPE(spt),
			SPT_CTR_WIDTH(spt), SPT_CTR_RADIUS(spt),
			SPT_CTR_THRESH(spt))
		    if (IS_INDEF(pix))
			next
		    do j = 1, LID_NLINES(lids) {
			if (lid == LID_LINES(lids,j))
			    next
			pix1 = shdr_wl (sh, LID_X(LID_LINES(lids,j)))
			if (abs (pix - pix1) < 2) {
			    pix = INDEF
			    break
			}
		    }
		    if (IS_INDEF(pix))
			next
		    call lid_erase (spt, reg, lid)
		    LID_X(lid) = shdr_lw (sh, double(pix))
		    call lid_mark1 (spt, reg, lid)
		}
		call lid_list (spt, reg, NULL)
	    } else {
		call lid_item (spt, reg, item, lid)
		pix = shdr_wl (sh, LID_X(lid))
		pix = spt_center1d (pix, Memr[SPEC(sh,SPT_CTYPE(spt))], SN(sh),
		    SPT_CTR_CTYPE(spt), SPT_CTR_PTYPE(spt), SPT_CTR_WIDTH(spt),
		    SPT_CTR_RADIUS(spt), SPT_CTR_THRESH(spt))
		if (IS_INDEF(pix))
		    call error (1, "Centering failed")
		do j = 1, LID_NLINES(lids) {
		    if (lid == LID_LINES(lids,j))
			next
		    pix1 = shdr_wl (sh, LID_X(LID_LINES(lids,j)))
		    if (abs (pix - pix1) < 2)
		        call error (1, "Centering failed: found existing line")
		}
		call lid_erase (spt, reg, lid)
		LID_X(lid) = shdr_lw (sh, double(pix))
		call lid_mark1 (spt, reg, lid)
		call lid_list (spt, reg, lid)
	    }

	case COORD: # coordinate
	    x = wx
	    wx = INDEFD
	    if (reg == NULL)
		return

	    sh = REG_SH(reg)
	    if (sh == NULL)
		return

	    pix = shdr_wl (sh, x)
	    pix = spt_center1d (pix, Memr[SPEC(sh,SPT_CTYPE(spt))],
		SN(sh), SPT_CTR_CTYPE(spt), SPT_CTR_PTYPE(spt),
		SPT_CTR_WIDTH(spt), SPT_CTR_RADIUS(spt),
		SPT_CTR_THRESH(spt))
	    if (IS_INDEF(pix))
		wx = INDEFD
	    else
		wx = shdr_lw (sh, double(pix))

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: center %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end
