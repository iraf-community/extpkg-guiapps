include	<error.h>
include	<finfo.h>
include	<imhdr.h>
include	<smw.h>
include	"spectool.h"


# SPT_FLIST -- Expand directory of files.

procedure spt_flist (spt, directory, template)

pointer	spt			#I SPECTOOL structure
char	directory[ARB]		#I Directory
char	template[ARB]		#I Image template

int	fnt, fnoff, len_list
long	ostruct[LEN_FINFO]
pointer	list, cp
int	nowhite(), strlen(), fnldir(), fntopnb(), fntgfnb(), finfo()
errchk	fnldir, fchdir, fpathname

begin
	# Set directory.  Any directory in the template string takes
	# precedence over the directory name.

	fnoff = fnldir (template, SPT_STRING(spt), SPT_SZSTRING) + 1
	if (fnoff == 1)
	    if (nowhite (directory,  SPT_STRING(spt), SPT_SZSTRING) == 0)
		call fpathname ("", SPT_STRING(spt), SPT_SZSTRING)
	iferr (call fchdir (SPT_STRING(spt))) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "directory %s")
		call pargstr (SPT_DIR(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "files %s")
		call pargstr (SPT_FTMP(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call erract (EA_ERROR)
	}

	# Allocate the list.
	len_list = SZ_LINE
	call calloc (list, SZ_LINE, TY_CHAR)
	cp = list

	# Expand the file template.
	if (SPT_FNT(spt) != NULL)
	    call fntclsb (SPT_FNT(spt))
	fnt = fntopnb (template[fnoff], YES)

	# Expand into a list.
	while (fntgfnb (fnt, Memc[cp], SZ_FNAME) != EOF) {
	    if (finfo (Memc[cp], ostruct) == ERR)
		next
	    if (FI_TYPE(ostruct) != FI_REGULAR) 
		next
	    cp = cp + strlen(Memc[cp]) + 2
	    Memc[cp-2] = ' '
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + SZ_LINE
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}

	# List directories.
	fnt = fntopnb ("..,*", YES)
	while (fntgfnb (fnt, Memc[cp], SZ_FNAME) != EOF) {
	    if (finfo (Memc[cp], ostruct) == ERR)
		next
	    if (FI_TYPE(ostruct) != FI_DIRECTORY) 
		next
	    cp = cp + strlen(Memc[cp]) + 3
	    Memc[cp-3] = '/'
	    Memc[cp-2] = ' '
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + SZ_LINE
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}
	call fntclsb (fnt)

	# Send list to GUI.
	SPT_FNT(spt) = fnt
	call strcpy (template[fnoff], SPT_FTMP(spt), SPT_SZLINE)

	call fpathname ("", SPT_DIR(spt), SPT_SZLINE)
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "directory %s")
	    call pargstr (SPT_DIR(spt))
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	call strcpy (template[fnoff], SPT_FTMP(spt), SPT_SZLINE)
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "files %s")
	    call pargstr (SPT_FTMP(spt))
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	call gmsg (SPT_GP(spt), "files", Memc[list])

	call mfree (list, TY_CHAR)
end


procedure spt_imlist (spt, directory, template)

pointer	spt			#I SPECTOOL structure
char	directory[ARB]		#I Directory
char	template[ARB]		#I Image template

int	len_list, fnt
long	ostruct[LEN_FINFO]
pointer	list, cp, imt, im

int	strlen(), imtgetim(), imaccess()
int	fnldir(), fntopnb(), fntgfnb(), finfo()
pointer	imtopen(), immap()
pointer	stp, sym, stopen(), stenter(), stfind(), stpstr(), strefsbuf()
errchk	fchdir
data	stp/NULL/

begin
	# Set directory.
	if (fnldir (directory, SPT_STRING(spt), SPT_SZSTRING) == 0)
	    call fpathname ("", SPT_STRING(spt), SPT_SZSTRING)
	#else if (finfo (SPT_STRING(spt), ostruct) == ERR)
	#    call fpathname ("", SPT_STRING(spt), SPT_SZSTRING)
	iferr (call fchdir (SPT_STRING(spt))) {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "directory %s")
		call pargstr (SPT_DIR(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "images %s")
		call pargstr (SPT_IMTMP(spt))
	    call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	    call erract (EA_ERROR)
	}

	# Initialize list.
	list = SPT_IMLIST(spt)
	len_list = SPT_IMLEN(spt)
	cp = list
	Memc[cp] = EOS

	# Expand the image template.
	if (SPT_IMIMT(spt) != NULL)
	    call imtclose (SPT_IMIMT(spt))
	imt = imtopen (template)

	# Use symbol table to cache information about images.
	if (stp == NULL)
	    stp = stopen ("spectool", 50, 10, 10*SZ_LINE)

	# Expand into a list.
	while (imtgetim (imt, SPT_STRING(spt), SPT_SZSTRING) != EOF) {
#	    call xt_imroot (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING)
	    if (imaccess (SPT_STRING(spt), READ_ONLY) == NO)
		next
	    sym = stfind (stp, SPT_STRING(spt))
	    if (sym == NULL) {
		sym = stenter (stp, SPT_STRING(spt), 1)
		Memi[sym] = NULL
		iferr (im = immap (SPT_STRING(spt), READ_ONLY, 0))
		    next
		switch (IM_NDIM(im)) {
		case 1:
		    call sprintf (Memc[cp], SZ_LINE, "\"%s %22t[%d] %s\"")
			call pargstr (SPT_STRING(spt))
			call pargi (IM_LEN(im,1))
			call pargstr (IM_TITLE(im))
		case 2:
		    call sprintf (Memc[cp], SZ_LINE, "\"%s %22t[%d,%d] %s\"")
			call pargstr (SPT_STRING(spt))
			call pargi (IM_LEN(im,1))
			call pargi (IM_LEN(im,2))
			call pargstr (IM_TITLE(im))
		case 3:
		    call sprintf (Memc[cp], SZ_LINE, "\"%s %22t[%d,%d,%d] %s\"")
			call pargstr (SPT_STRING(spt))
			call pargi (IM_LEN(im,1))
			call pargi (IM_LEN(im,2))
			call pargi (IM_LEN(im,3))
			call pargstr (IM_TITLE(im))
		default:
		    call imunmap (im)
		    next
		}
		call imunmap (im)

		Memi[sym] = stpstr (stp, Memc[cp], 0)
	    } else {
		if (Memi[sym] == NULL)
		    next
		call strcpy (Memc[strefsbuf(stp,Memi[sym])], Memc[cp], SZ_LINE)
	    }

	    cp = cp + strlen(Memc[cp]) + 1
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + 1000
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}
	call imtrew (imt)

	# List directories.
	if (cp != list) {
	    call sprintf (Memc[cp], SZ_LINE, "\"%60w\"")
	    cp = cp + strlen(Memc[cp]) + 1
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + SZ_LINE
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}

	fnt = fntopnb ("..,*", YES)
	while (fntgfnb (fnt, SPT_STRING(spt), SPT_SZSTRING) != EOF) {
	    if (finfo (SPT_STRING(spt), ostruct) == ERR)
		next
	    if (FI_TYPE(ostruct) != FI_DIRECTORY) 
		next
	    call sprintf (Memc[cp], SZ_FNAME, "%s/")
		call pargstr (SPT_STRING(spt))
	    cp = cp + strlen(Memc[cp]) + 1
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + SZ_LINE
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}
	call fntclsb (fnt)

	SPT_IMIMT(spt) = imt
	SPT_IMLIST(spt) = list
	SPT_IMLEN(spt) = len_list
	call gmsg (SPT_GP(spt), "images", IMLIST(spt))

	call fpathname ("", SPT_DIR(spt), SPT_SZLINE)
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "directory %s")
	    call pargstr (SPT_DIR(spt))
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
	call strcpy (template, SPT_IMTMP(spt), SPT_SZLINE)
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "images %s")
	    call pargstr (SPT_IMTMP(spt))
	call gmsg (SPT_GP(spt), "setGui", SPT_STRING(spt))
end


procedure spt_rglist (spt, reg)

pointer	spt			#I SPECTOOL structure
pointer	reg			#I Selected register

int	i, itemno, len_list, strlen()
pointer	list, cp, ptr, sh

begin
	list = SPT_RGLIST(spt)
	len_list = SPT_RGLEN(spt)
	cp = list
	Memc[cp] = EOS

	do i = 1, SPT_NREG(spt) {
	    ptr = REG(spt,i)
	    if (REG_ID(ptr) < 1)
		next
	    if (ptr == reg)
		itemno = i
	    sh = REG_SH(ptr)
	    switch (SMW_FORMAT(MW(sh))) {
	    case SMW_ND:
		call sprintf (Memc[cp], SZ_LINE,
		    "\"%s %20s %3d %3d %8s %8s %3d %s")
		    call pargstr (REG_IDSTR(ptr))
		    call pargstr (REG_IMAGE(ptr))
		    call pargi (REG_AP(ptr))
		    call pargi (REG_BAND(ptr))
		    call pargstr (REG_TYPE(ptr,SHDATA))
		    call pargstr (SPT_COLORS(spt,REG_COLOR(ptr,SHDATA)))
		    call pargi (nint(APHIGH(sh))-nint(APLOW(sh))+1)
		    call pargstr (REG_TITLE(ptr))
	    default:
		call sprintf (Memc[cp], SZ_LINE,
		    "\"%s %20s %3d %3d %8s %8s %s")
		    call pargstr (REG_IDSTR(ptr))
		    call pargstr (REG_IMAGE(ptr))
		    call pargi (REG_AP(ptr))
		    call pargi (REG_BAND(ptr))
		    call pargstr (REG_TYPE(ptr,SHDATA))
		    call pargstr (SPT_COLORS(spt,REG_COLOR(ptr,SHDATA)))
		    call pargstr (REG_TITLE(ptr))
	    }
	    cp = cp + strlen(Memc[cp]) + 2
	    Memc[cp-2] = '"'
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + 1000
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}

	SPT_RGLIST(spt) = list
	SPT_RGLEN(spt) = len_list
	call gmsg (SPT_GP(spt), "registers", RGLIST(spt))
end


procedure spt_splist (spt, image, im, mw, sh)

pointer	spt			#I Spectool pointer
char	image[ARB]		#I Image name
pointer	im			#I IMIO pointer
pointer	mw			#I SMW pointer
pointer	sh			#I SHDR pointer

int	i, nspec, len_list, strlen(), nowhite()
pointer	sp, imroot, str, list, cp, ptr, immap(), smw_openim()

errchk	immap, smw_openim

begin
	call smark (sp)
	call salloc (imroot, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	if (nowhite (image, SPT_STRING(spt), SPT_SZSTRING) == 0) {
	    call gmsg (SPT_GP(spt), "spectra", "")
	    call sfree (sp)
	    return
	}

	call xt_imroot (image, Memc[imroot], SZ_FNAME)
	if (im == NULL) {
	    ptr = immap (Memc[imroot], READ_ONLY, 0); im = ptr
	    ptr = smw_openim (im); mw = ptr
	}

	list = SPT_SPLIST(spt)
	len_list = SPT_SPLEN(spt)
	cp = list
	Memc[cp] = EOS

	nspec = SMW_NSPEC(mw)
	do i = 1, nspec {
	    if (SMW_FORMAT(mw) == SMW_ND) {
		call shdr_open (im, mw, i, 1, INDEFI, SHHDR, sh)
		call sprintf (Memc[cp], SZ_LINE, "\"%s %22t%3d \"")
		    call pargstr (Memc[imroot])
		    call pargi (i)
	    } else {
		call shdr_open (im, mw, i, 1, INDEFI, SHHDR, sh)
		call sprintf (Memc[cp], SZ_LINE, "\"%s %22t%3d %3d %s\"")
		    call pargstr (Memc[imroot])
		    call pargi (AP(sh))
		    call pargi (BEAM(sh))
		    call pargstr (TITLE(sh))
	    }

	    cp = cp + strlen(Memc[cp]) + 1
	    Memc[cp-1] = ' '
	    Memc[cp] = EOS
	    if (cp - list + SZ_LINE + 1 > len_list) {
		len_list = len_list + 1000
		call realloc (list, len_list, TY_CHAR)
		cp = list + strlen (Memc[list])
	    }
	}

	SPT_SPLIST(spt) = list
	SPT_SPLEN(spt) = len_list
	call gmsg (SPT_GP(spt), "spectra", SPLIST(spt))

	call sfree (sp)
end


# SPT_GETITEM -- Get the specified item from a list of words.
# If not found an empty string is returned and the function value is false.

bool procedure spt_getitem (list, itemno, item, max_char)

char	list[ARB]		#I List of items
int	itemno			#I Item number
char	item[max_char]		#O Item
int	max_char		#I Maximum size of item

bool	found
int	i, cp, ctowrd()

begin
	cp = 1
	for (i=0; i<itemno; i=i+1)
	    if (ctowrd (list, cp, item, max_char) == 0)
		break
	found = (i>0 && i==itemno)
	if (!found)
	    item[1] = EOS
	return (found)
end

# SPT_GETITEMNO -- Get the item matching a template in a list of words.
# If the item is not found the itemno is zero, the item string is empty,
# and the function returns false.  The template and item strings may
# be the same and if max_char is 0 then no item string is returned.
#
# The template need only match the beginning of a list word to allow getting
# the first item when several have the same initial string.

bool procedure spt_getitemno (list, template, itemno, item, max_char)

char	list[ARB]		#I List of items
char	template[ARB]		#I Template
int	itemno			#O Item number
char	item[ARB]		#O Item
int	max_char		#I Maximum size of item

pointer	str
bool	found
int	n, nmatch, cp, strlen(), ctowrd(), strncmp()

begin
	nmatch = strlen (template)
	n = max (nmatch, max_char)

	call malloc (str, n, TY_CHAR)

	cp = 1
	for (itemno=1;; itemno=itemno+1) {
	    if (ctowrd (list, cp, Memc[str], n) == 0) {
		itemno = 0
		break
	    }
	    if (strncmp (template, Memc[str], nmatch) == 0)
		break
	}
	found = (itemno != 0)
	if (!found)
	    item[1] = EOS
	else if (max_char > 0)
	    call strcpy (Memc[str], item, max_char)

	call mfree (str, TY_CHAR)
	return (found)
end


# SPT_GITEMS -- Get the item nos from the register, spectrum and image lists.
# The item numbers are zero if not found.  This routine isolates the
# format matching.

procedure spt_gitems (spt, reg, rgitem, spitem, imitem)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
int	rgitem			#O Register list item number
int	spitem			#O Spectrum list item number
int	imitem			#O Image list item number

bool	spt_getitemno()

begin
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%s ")
	    call pargstr (REG_IDSTR(reg))
	if (spt_getitemno (RGLIST(spt), SPT_STRING(spt), rgitem, "", 0))
	    ;

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%s %21t%3d ")
	    call pargstr (REG_IMAGE(reg))
	    call pargi (REG_AP(reg))
	if (spt_getitemno (SPLIST(spt), SPT_STRING(spt), spitem, "",0))
	    ;

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%s ")
	    call pargstr (REG_IMAGE(reg))
	if (spt_getitemno (IMLIST(spt), SPT_STRING(spt), imitem, "", 0))
	    ;
end
