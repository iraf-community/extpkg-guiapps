include	<error.h>
include	<units.h>
include	<smw.h>
include	<mach.h>
include	"spectool.h"
include	"lids.h"
include	"rv.h"

# List of colon commands.
define	CMDS	"|open|close|linelist|match|units|set|mark|"


define	OPEN		1	# Open/allocate/initialize
define	CLOSE		2	# Close/free
define	LINELIST	3	# Line list
define	MATCH		4	# Matching distance
define	UNIT		5	# Units
define	SET		6	# Set reference and label from line list
define	MARK		7	# Mark line


# LL_COLON -- Interpret line list colon commands.

procedure ll_colon (spt, reg, wx, wy, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register
double	wx, wy			#I GIO coordinate
char	cmd[ARB]		#I GIO command

int	ncmd, item, llindex
double	ref, delta
pointer	ll, sh, lid, label
pointer	sp, str 

bool	streq()
double	clgetd(), shdr_lw(), shdr_wl()
int	strdic(), nowhite(), nscan()
errchk	lid_mapll, lid_unmapll, lid_find, lid_find1

define	err_	10
define	done_	20

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	ncmd = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    call clgstr ("linelist", SPT_LINELIST(spt), LID_SZLINE)
	    SPT_LLSEP(spt) = clgetd ("linematch")
	    if (nowhite (SPT_LINELIST(spt), SPT_LINELIST(spt), SZ_LINE) > 0) {
		iferr (call lid_mapll (spt, SPT_LINELIST(spt), SPT_LL(spt))) {
		    SPT_LINELIST(spt) = EOS
		    SPT_LL(spt) = NULL
		    call erract (EA_WARN)
		}
	    } else
		SPT_LL(spt) = NULL

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" %g")
		call pargstr (SPT_LINELIST(spt))
		call pargd (SPT_LLSEP(spt))
	    call gmsg (SPT_GP(spt), "llpars", SPT_STRING(spt))

	    call ll_list (spt)

	case CLOSE: # close
	    call lid_unmapll (spt)
	    call clpstr ("linelist", SPT_LINELIST(spt))

	case LINELIST: # linelist file
	    call gargwrd (Memc[str], SZ_LINE)
	    if (nscan() < 2)
		goto err_
	    if (nowhite (Memc[str], Memc[str], SZ_LINE) == 0) {
		call lid_unmapll (spt)
		SPT_LINELIST(spt) = EOS
	    } else if (!streq (Memc[str], SPT_LINELIST(spt))) {
		iferr (call lid_mapll (spt, Memc[str], ll)) {
		    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" %g")
			call pargstr (SPT_LINELIST(spt))
			call pargd (SPT_LLSEP(spt))
		    call gmsg (SPT_GP(spt), "llpars", SPT_STRING(spt))
		    call erract (EA_ERROR)
		}
		call lid_unmapll (spt)
		SPT_LL(spt) = ll
		call strcpy (Memc[str], SPT_LINELIST(spt), LID_SZLINE)
	    }
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" %g")
		call pargstr (SPT_LINELIST(spt))
		call pargd (SPT_LLSEP(spt))
	    call gmsg (SPT_GP(spt), "llpars", SPT_STRING(spt))

	    call ll_list (spt)

	case MATCH: # match match
	    call gargd (delta)
	    if (nscan() < 2)
		goto err_
	    SPT_LLSEP(spt) = delta
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "\"%s\" %g")
		call pargstr (SPT_LINELIST(spt))
		call pargd (SPT_LLSEP(spt))
	    call gmsg (SPT_GP(spt), "llpars", SPT_STRING(spt))
	    call ll_list (spt)

	case UNIT:
	    call gargwrd (Memc[str], SZ_LINE)
	    if (nscan() != 2)
		goto err_

	    if (SPT_LL(spt) == NULL || reg == NULL)
		goto done_
	    sh = REG_SH(reg)
	    if (sh == NULL)
		goto done_

	    if (streq (Memc[str], "logical")) {
		for (ll=Memi[SPT_LL(spt)]; !IS_INDEFD(Memd[ll]); ll=ll+1)
		    Memd[ll] = shdr_wl (sh, Memd[ll])
	    } else {
		for (ll=Memi[SPT_LL(spt)]; !IS_INDEFD(Memd[ll]); ll=ll+1)
		    Memd[ll] = shdr_lw (sh, Memd[ll])
		call ll_sort (SPT_LL(spt))
		Memi[SPT_LL(spt)+2] = UN(sh)
		call ll_list (spt)
	    }

	case SET: # set item llindex
	    call gargi (item)
	    call gargi (llindex)
	    if (nscan() < 3 || item == 0 || llindex == 0 || SPT_LL(spt) == NULL)
		goto done_

	    call lid_item (spt, reg, item, lid)
	    ll = SPT_LL(spt)
	    ref = Memd[Memi[ll]+llindex-1]
	    label = Memi[Memi[ll+1]+llindex-1]
	    call lid_erase (spt, reg, lid)
	    LID_LLINDEX(lid) = llindex
	    LID_REF(lid) = ref
	    if (label != NULL)
		call strcpy (Memc[label], LID_LABEL(lid), LID_SZLINE)
	    call lid_mark1 (spt, reg, lid)
	    call lid_list (spt, reg, lid)

	case MARK: # mark llindex
	    call gargi (llindex)
	    if (nscan() == 1)
		llindex = -1

	    ll = SPT_LL(spt)
	    if (ll == NULL || reg == NULL || llindex == 0)
		goto done_
	    sh = REG_SH(reg)
	    if (sh == NULL)
		goto done_

	    call amulkr (Memr[SPEC(sh,SPT_CTYPE(spt))], REG_SSCALE(reg),
		SPECT(spt), SN(sh))
	    call aaddkr (SPECT(spt), REG_STEP(reg), SPECT(spt), SN(sh))

	    if (llindex == -1) {
		call lid_find (spt, reg, lid)
		call lid_list (spt, reg, NULL)
	    } else if (llindex > 0) {
		ref = Memd[Memi[ll]+llindex-1]
		label = Memi[Memi[ll+1]+llindex-1]
		call lid_find1 (spt, reg, lid, ref, label, Memi[ll+2])
		if (lid != NULL) {
		    LID_LLINDEX(lid) = llindex
		    call lid_list (spt, reg, lid)
		}
	    }

	default: # error or unknown command
err_	    call sprintf (Memc[str], SZ_LINE,
		"Error in colon command: %g %g ll %s")
		call pargd (wx)
		call pargd (wy)
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

done_	call sfree (sp)
end


# LID_MAPLL -- Read the line list into memory.

procedure lid_mapll (spt, list, ll)

pointer	spt		#I SPECTOOL pointer
char	list[ARB]	#I Line list filename
pointer	ll		#U Line list pointer

double	value
int	fd, nalloc, nlines
pointer	sp, str, un1, un2, ll1, ll2

bool	streq()
int	open(), fscan(), nscan()
pointer	un_open()

errchk	open, fscan, malloc, realloc, un_open

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	ll = NULL
	fd = open (list, READ_ONLY, TEXT_FILE)

	iferr {
	    un1 = NULL
	    un2 = NULL
	    ll1 = NULL
	    ll2 = NULL
	    nalloc = 0
	    nlines = 0
	    while (fscan (fd) != EOF) {
		call gargd (value)
		if (nscan() != 1) {
		    call reset_scan()
		    call gargwrd (Memc[str], SZ_LINE)
		    call gargwrd (Memc[str], SZ_LINE)
		    if (streq (Memc[str], "units")) {
			call gargwrd (Memc[str], SZ_LINE)
			un1 = un_open (Memc[str])
			if (UN_TYPE(un1) == UN_UNKNOWN)
			    call error (1, "Unknown line list units")
		    }
		    next
		}

		if (ll1 == NULL) {
		    call malloc (ll1, 100, TY_DOUBLE)
		    call calloc (ll2, 100, TY_POINTER)
		} else if (mod (nlines,100) == 0) {
		    call realloc (ll1, nlines+100, TY_DOUBLE)
		    call realloc (ll2, nlines+100, TY_POINTER)
		    call aclri (Memi[ll2+nlines], 100)
		}

		Memd[ll1+nlines] = value
		call gargstr (Memc[str], SZ_LINE)
		call lid_lllabel (Memc[str], Memi[ll2+nlines])

		nlines = nlines + 1
	    }
	    call close (fd)
	    fd = NULL

	    if (nlines == 0) {
		call sfree (sp)
		return
	    }

	    call realloc (ll1, nlines + 1, TY_DOUBLE)
	    call realloc (ll2, nlines + 1, TY_POINTER)
	    Memd[ll1+nlines] = INDEFD

	    if (un1 == NULL) {
		un1 = un_open (SPT_UNITS(spt))
		if (UN_TYPE(un1) == UN_UNKNOWN)
		    call un_decode (un1, SPT_UNKNOWN(spt))
	    }
	    un2 = un_open (SPT_UNITS(spt))
	    if (UN_TYPE(un2) == UN_UNKNOWN)
		call un_decode (un2, SPT_UNKNOWN(spt))
	    call un_ctrand (un1, un2, Memd[ll1], Memd[ll1], nlines)
	    call un_close (un1)

	    call malloc (ll, 3, TY_POINTER)
	    Memi[ll] = ll1
	    Memi[ll+1] = ll2
	    Memi[ll+2] = un2

	    call ll_sort (ll)
	} then {
	    if (fd != NULL)
		call close (fd)
	    call un_close (un1)
	    call un_close (un2)
	    call mfree (ll1, TY_DOUBLE)
	    call mfree (ll2, TY_POINTER)
	    call sfree (sp)
	    call erract (EA_ERROR)
	}
end


# LID_UNMAPLL -- Unmap the linelist.

procedure lid_unmapll (spt)

pointer	spt		#I Spectool pointer

pointer	ll, ll1, ll2

begin
	ll = SPT_LL(spt)
	if (ll == NULL)
	    return

	ll1 = Memi[ll]
	ll2 = Memi[ll+1]
	while (!IS_INDEFD(Memd[ll1])) {
	    call mfree (Memi[ll2], TY_CHAR)
	    ll1 = ll1 + 1
	    ll2 = ll2 + 1
	}

	call mfree (Memi[ll], TY_DOUBLE)
	call mfree (Memi[ll+1], TY_POINTER)
	call un_close (Memi[ll+2])
	call mfree (ll, TY_POINTER)
	SPT_LL(spt) = ll
end


define	SKIP	($1==' '||$1=='\t'||$1=='"'||$1=='\'')

# SPT_LLLABEL -- Allocate memory and enter line list ID.

procedure lid_lllabel (str, label)

char	str[ARB]		# String to be set
pointer	label			# Line ID label pointer to be set

int	i, j, strlen()
pointer	cp

begin
	call mfree (label, TY_CHAR)

	for (i=1; str[i]!=EOS && SKIP(str[i]); i=i+1)
	    ;
	for (j=strlen(str); j>=i && SKIP(str[j]); j=j-1) 
	    ;

	if (i <= j) {
	    call malloc (label, j-i+1, TY_CHAR)
	    cp = label
	    for (; i<=j; i=i+1) {
		Memc[cp] = str[i]
		cp = cp + 1
	    }
	    Memc[cp] = EOS
	}
end


# LID_MATCH -- Match coordinate against line list.

int procedure lid_match (spt, reg, redshift, in, out, label, maxchars)

pointer	spt			#I Spectool pointer
pointer	reg			#I Register pointer
int	redshift		#I Apply spectrum redshift?
double	in			#I Coordinate to be matched
double	out			#O Matched coordinate
char	label[maxchars]		#O Label
int	maxchars		#I Maximum size of label

int	index
double	zin, diff, delta, deltamin, shdr_wl(), shdr_lw()
pointer	sh, ll, ll1, ll2, un1, un2, tmp

begin
	index = 0
	out = INDEFD
	label[1] = EOS
	if (IS_INDEFD(in))
	    return (index)

	ll = SPT_LL(spt)
	if (ll == NULL)
	    return (index)

	sh = REG_SH(reg)
	un1 = UN(sh)
	un2 = Memi[ll+2]

	zin = shdr_wl (sh, in)
	diff = shdr_lw (sh, zin-SPT_LLSEP(spt))
	delta = shdr_lw (sh, zin+SPT_LLSEP(spt))
	iferr {
	    call un_ctrand (un1, un2, diff, diff, 1)
	    call un_ctrand (un1, un2, delta, delta, 1)
	} then
	    ;
	diff = abs (diff - delta) / 2.

	ifnoerr (call un_ctrand (un1, un2, in, zin, 1)) {
	    if (redshift == YES && !IS_INDEFD(REG_REDSHIFT(reg)))
		zin = zin / (1 + REG_REDSHIFT(reg))
	} else
	    zin = in

	ll1 = Memi[ll]
	ll2 = Memi[ll+1]
	tmp = NULL
	deltamin = MAX_REAL
	while (!IS_INDEFD(Memd[ll1])) {
	    delta = abs (zin - Memd[ll1])
	    if (delta < deltamin) {
		deltamin = delta
	        if (deltamin <= diff) {
		    index = ll1 - Memi[ll] + 1
		    out = Memd[ll1]
		    tmp = Memi[ll2]
		}
	    }
	    ll1 = ll1 + 1
	    ll2 = ll2 + 1
	}

	if (!IS_INDEFD(out))
	    iferr (call un_ctrand (un2, un1, out, out, 1))
		;
	if (tmp != NULL)
	    call strcpy (Memc[tmp], label, maxchars)

	return (index)
end


# LID_FIND -- Find features from a line list.

procedure lid_find (spt, reg, lid)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lid		#O Line ID

int	llindex, llindexlast
double	user, pix, fit, ref, y, userlast, pixlast, fitlast, ylast
double	pixuser, sep, match, fit1, fit2, z, diff, difflast, shdr_wl()
pointer	ll, sh, ll1, ll2, un1, un2, label, labellast

begin
	lid = NULL
	ll = SPT_LL(spt)
	if (reg == NULL || ll == NULL)
	    return

	ll1 = Memi[ll]
	ll2 = Memi[ll+1]
	un2 = Memi[ll+2]
	sep = SPT_SEP(spt)
	match = SPT_LLSEP(spt)
	fit1 = REG_X1(reg)
	fit2 = REG_X2(reg)
	sh = REG_SH(reg)
	un1 = UN(sh)

	if (IS_INDEFD(REG_REDSHIFT(reg)))
	    z = 0.
	else
	    z = REG_REDSHIFT(reg)

	pixlast = 0.
	while (!IS_INDEFD(Memd[ll1])) {
	    user = Memd[ll1]
	    label = Memi[ll2]
	    iferr (call un_ctrand (un2, un1, user*(1+z), fit, 1))
		fit = user
	    iferr (call un_ctrand (un2, un1, user, user, 1))
		;
	    ll1 = ll1 + 1
	    ll2 = ll2 + 1
	    if (user < fit1)
		next
	    if (user > fit2)
		break
	
	    pixuser = shdr_wl (sh, fit)
	    call spt_ctr (spt, reg, fit, INDEFD, "coordinate")
	    if (!IS_INDEFD(fit)) {
		pix = shdr_wl (sh, fit)
		diff = abs (pix - pixuser)
		if (diff > match)
		    next
		llindex = ll1 - Memi[ll]
		call lid_y (spt, reg, fit, INDEFD, SPT_DLABY(spt), y)
		if (pixlast > 0.) {
		    if (abs (pix - pixlast) < sep) {
			if (diff < difflast) {
			    difflast= diff
			    pixlast = pix
			    ylast = y
			    fitlast = fit
			    userlast = user
			    labellast = label
			    llindexlast = llindex
			    ref = userlast
			}
			next
		    }
		    if (labellast == NULL) {
			iferr (call lid_add (spt, reg, lid, YES, YES, fitlast,
			    INDEFD, INDEFD, "INDEF", ref, ylast, "INDEF"))
			    ;
		    } else {
			iferr (call lid_add (spt, reg, lid, YES, YES, fitlast,
			    INDEFD, INDEFD, "INDEF", ref, ylast,
			    Memc[labellast]))
			    ;
		    }
		    if (lid != NULL)
			LID_LLINDEX(lid) = llindexlast
		}
			
		difflast = diff
		pixlast = pix
		ylast = y
		fitlast = fit
		userlast = user
		labellast = label
		ref = userlast
		llindexlast = llindex
	    }
	}

	if (pixlast > 0.) {
	    if (labellast == NULL) {
		iferr (call lid_add (spt, reg, lid, YES, YES, fitlast,
		    INDEFD, INDEFD, "INDEF", ref, ylast, "INDEF"))
		    ;
	    } else {
		iferr (call lid_add (spt, reg, lid, YES, YES, fitlast,
		    INDEFD, INDEFD, "INDEF", ref, ylast, Memc[labellast]))
		    ;
	    }
	    if (lid != NULL)
		LID_LLINDEX(lid) = llindexlast
	}
end


# LID_FIND1 -- Find specified reference feature.

procedure lid_find1 (spt, reg, lid, coord, label, un2)

pointer	spt		#I Spectool pointer
pointer	reg		#I Register
pointer	lid		#O Line ID
double	coord		#I User coordinate
pointer	label		#I Label pointer
pointer	un2		#I Units of user coordinate

double	user, pix, fit, y, pixuser, z, diff, shdr_wl()
pointer	sh, un1

begin
	lid = NULL
	if (reg == NULL)
	    return

	sh = REG_SH(reg)
	un1 = UN(sh)

	# Redshift and match units.
	if (IS_INDEFD(REG_REDSHIFT(reg)))
	    z = 0.
	else
	    z = REG_REDSHIFT(reg)
	user = coord
	iferr (call un_ctrand (un2, un1, user*(1+z), fit, 1))
	    fit = user
	iferr (call un_ctrand (un2, un1, user, user, 1))
	    ;

	# Quick check that user coordinate is within spectrum.
	if (user < REG_X1(reg) || user > REG_X2(reg))
	    return
    
	# Attempt to find line based on whether a profile center is found.
	pixuser = shdr_wl (sh, fit)
	call spt_ctr (spt, reg, fit, INDEFD, "coordinate")
	if (IS_INDEFD(fit))
	    return

	# Check that the coordinate is within a specified distance.
	pix = shdr_wl (sh, fit)
	diff = abs (pix - pixuser)
	if (diff > SPT_LLSEP(spt))
	    return

	# Add line.  Note that this will replace an existing line if needed.
	call lid_y (spt, reg, fit, INDEFD, SPT_DLABY(spt), y)
	if (label == NULL) {
	    iferr (call lid_add (spt, reg, lid, YES, YES, fit, INDEFD, INDEFD,
		"INDEF", user, y, "INDEF"))
		;
	} else {
	    iferr (call lid_add (spt, reg, lid, YES, YES, fit, INDEFD, INDEFD,
		"INDEF", user, y, Memc[label]))
		;
	}
end


procedure ll_list (spt)

pointer	spt		#I Spectool pointer

int	len, strlen()
double	user
pointer	str, line, ll1, ll2, label
errchk	malloc, realloc

begin
	if (SPT_LL(spt) == NULL) {
	    call gmsg (SPT_GP(spt), "linelist", "")
	    return
	}

	len = 10 * SZ_LINE
	call malloc (str, len, TY_CHAR)
	line = str

	ll1 = Memi[SPT_LL(spt)]
	ll2 = Memi[SPT_LL(spt)+1]
	while (!IS_INDEFD(Memd[ll1])) {
	    user = Memd[ll1]
	    label = Memi[ll2]
	    if (label == NULL) {
		call sprintf (Memc[line], SZ_LINE, "\"%.8g\" ")
		    call pargd (user)
	    } else {
		call sprintf (Memc[line], SZ_LINE, "\"%.8g %s\" ")
		    call pargd (user)
		    call pargstr (Memc[label])
	    }
	    line = line + strlen (Memc[line])
	    if (line - str + SZ_LINE + 1 > len) {
		len = len + 10 * SZ_LINE
		call realloc (str, len, TY_CHAR)
		line = str + strlen (Memc[str])
	    }

	    ll1 = ll1 + 1
	    ll2 = ll2 + 1
	}

	call gmsg (SPT_GP(spt), "linelist", Memc[str])

	call mfree (str, TY_CHAR)
end


# LL_SORT -- Sort line list.

procedure ll_sort (ll)

pointer	ll		#I Linelist pointer

int	i, nll
pointer	, ll1, ll2
pointer	sp, index, vals, labs

int	ll_compare()
extern	ll_compare

begin
	if (ll == NULL)
	    return

	ll1 = Memi[ll]
	ll2 = Memi[ll+1]

	vals = ll1
	while (!IS_INDEFD(Memd[vals]))
	    vals = vals + 1
	nll = vals - ll1
	if (nll <= 1)
	    return

	call smark (sp)
	call salloc (index, nll, TY_INT)
	call salloc (vals, nll, TY_DOUBLE)
	call salloc (labs, nll, TY_POINTER)
	do i = 0, nll-1 {
	    Memi[index+i] = i
	    Memd[vals+i] = Memd[ll1+i]
	    Memi[labs+i] = Memi[ll2+i]
	}

	call gqsort (Memi[index], nll, ll_compare, vals)

	do i = 0, nll-1 {
	    Memd[ll1+i] = Memd[vals+Memi[index+i]]
	    Memi[ll2+i] = Memi[labs+Memi[index+i]]
	}

	call sfree (sp)
end


int procedure ll_compare (arg, x1, x2)

pointer	arg
int	x1, x2

begin
	if (Memd[arg+x1] < Memd[arg+x2])
	    return (-1)
	else if (Memd[arg+x1] > Memd[arg+x2])
	    return (1)
	else
	    return (0)
end
