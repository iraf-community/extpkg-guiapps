include <finfo.h>
include "../lib/xphot.h"

# XP_DIRLIST -- Create the sub-directory listing. If no sub-directory is
# specified list the current directory.

int procedure xp_dirlist (dirtemplate)

char	dirtemplate[ARB]	#I the directory template string

int	dirlist, len_dstr, strfd
int	ostruct[LEN_FINFO]
pointer	sp, dirliststr, dir
int	fntopnb(), fntlenb(), stropen(), fntgfnb(), finfo(), strlen()
errchk	fntopnb()

begin
	iferr (dirlist = fntopnb(dirtemplate, YES))
	    dirlist = fntopnb("..,*", YES)
	if (dirtemplate[1] == EOS || fntlenb (dirlist) <= 0)
	    return (dirlist)

	len_dstr = fntlenb (dirlist) * SZ_FNAME + 1
	call smark (sp)
	call salloc (dirliststr, len_dstr, TY_CHAR)
	call salloc (dir, SZ_FNAME, TY_CHAR)

	Memc[dirliststr] = EOS
	strfd = stropen (Memc[dirliststr], len_dstr, NEW_FILE) 
	while (fntgfnb (dirlist, Memc[dir], SZ_FNAME) != EOF) {
	    if (finfo (Memc[dir], ostruct) == ERR)
		next
	    if (FI_TYPE(ostruct) != FI_DIRECTORY)
		next
	    call strcat ("/", Memc[dir], SZ_FNAME)
	    call fprintf (strfd, "%s,")
		call pargstr (Memc[dir])
	}
	call close (strfd)
	if (Memc[dirliststr] != EOS)
	    Memc[dirliststr+strlen(Memc[dirliststr])-1] = EOS
	call fntclsb (dirlist)

	dirlist = fntopnb(Memc[dirliststr], YES)

	call sfree (sp)

	return (dirlist)
end


# XP_IMLIST -- Create an image list.

int procedure xp_imlist (imtemplatestr)

char	imtemplatestr[ARB]	#I the image template string

int	i, imlist, len_imliststr, strfd
pointer	sp, imliststr, image
int	imtopen(), imtlen(), imtrgetim(), stropen(), imaccess(), strlen()
errchk	imtopen()

begin
	iferr (imlist = imtopen (imtemplatestr))
	    imlist = imtopen ("")
	if (imtemplatestr[1] == EOS || imtlen (imlist) <= 0)
	    return (imlist)

	len_imliststr = imtlen (imlist) * SZ_FNAME + 1
	call smark (sp)
	call salloc (imliststr, len_imliststr, TY_CHAR)
	call salloc (image, SZ_FNAME, TY_CHAR)

	Memc[imliststr] = EOS
	strfd = stropen (Memc[imliststr], len_imliststr, NEW_FILE) 
	do i = 1, imtlen (imlist) {
	    if (imtrgetim (imlist, i, Memc[image], SZ_FNAME) == EOF)
	        break
	    if (imaccess (Memc[image], READ_ONLY) == NO)
		next
	    call fprintf (strfd, "%s,")
		call pargstr (Memc[image])
	}
	call close (strfd)
	if (Memc[imliststr] != EOS)
	    Memc[imliststr+strlen(Memc[imliststr])-1] = EOS

	call imtclose (imlist)
	imlist = imtopen (Memc[imliststr])

	call sfree (sp)

	return (imlist)
end


# XP_MKOLIST -- Create a list of default input files using the input image
# list and an input file template string. Test for the existence of each
# file in the list.

int procedure xp_mkolist (imlist, otemplatestr, defaultstr, extstr)

int	imlist			#I the image list descriptor
char	otemplatestr[ARB]	#I the file template string
char	defaultstr[ARB]		#I the defaults id string
char	extstr[ARB]		#I the extension string

int	i, len_dir, olist, len_oliststr, strfd
pointer	sp, dirname, oliststr, image, fname
int	fnldir(), strncmp(), strlen(), fntopnb(), imtlen(), stropen()
int	imtrgetim(), fntrfnb(), fntlenb(), access()

begin
	# Return if the list is empty.
	iferr(olist = fntopnb (otemplatestr, NO))
	    olist = fntopnb ("", NO)
	if (otemplatestr[1] == EOS || fntlenb (olist) <= 0)
	    return (olist)

	call smark (sp)
	call salloc (dirname, SZ_FNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	# Get the directory name.
	if (fntrfnb (olist, 1, Memc[fname], SZ_FNAME) == EOF)
	    Memc[fname] = EOS
	len_dir = fnldir (Memc[fname], Memc[dirname], SZ_FNAME)

	# Get the default input coordinate file names. There will be one
	# coordinate file per image. An extension of 0 indicates that the
	# file does not exist.
	if (strncmp (defaultstr, Memc[fname+len_dir],
	    strlen (defaultstr)) == 0 || len_dir == strlen (Memc[fname])) {

	    call fntclsb (olist)
	    len_oliststr = imtlen (imlist) * SZ_FNAME + 1
	    call salloc (oliststr, len_oliststr, TY_CHAR)
	    call salloc (image, SZ_FNAME, TY_CHAR)
	    Memc[oliststr] = EOS

	    strfd = stropen (Memc[oliststr], len_oliststr, NEW_FILE) 
	    do i = 1, imtlen (imlist) {
	        if (imtrgetim (imlist, i, Memc[image], SZ_FNAME) == EOF)
		    break
		call xp_inname (Memc[image], Memc[dirname], extstr,
		    Memc[dirname], SZ_FNAME)
		if (access (Memc[dirname], READ_ONLY, TEXT_FILE) == NO)
		    next
	            #Memc[dirname+strlen(Memc[dirname])-1] = '0'
		call fprintf (strfd, "%s,")
		    call pargstr (Memc[dirname])
	    }
	    call close (strfd)

	    if (Memc[oliststr] != EOS)
	        Memc[oliststr+strlen(Memc[oliststr])-1] = EOS
	    olist = fntopnb (Memc[oliststr], NO)

	# Get the default user coordinate file names.
	} else {

	    len_oliststr = fntlenb (olist) * SZ_FNAME + 1
	    call salloc (oliststr, len_oliststr, TY_CHAR)
	    Memc[oliststr] = EOS

	    strfd = stropen (Memc[oliststr], len_oliststr, NEW_FILE) 
	    do i = 1, fntlenb (olist) {
	        if (fntrfnb (olist, i, Memc[fname], SZ_FNAME) == EOF)
		    break
		if (access (Memc[fname], READ_ONLY, TEXT_FILE) == NO)
		    next
		call fprintf (strfd, "%s,")
		    call pargstr (Memc[fname])
	    }
	    call close (strfd)

	    if (Memc[oliststr] != EOS)
	        Memc[oliststr+strlen(Memc[oliststr])-1] = EOS
	    call fntclsb (olist)
	    olist = fntopnb (Memc[oliststr], NO)
	}

	call sfree (sp)

	return (olist)
end


# XP_MKRLIST -- Create a list output files list using the input image list
# and an input file template string.

int procedure xp_mkrlist (imlist, otemplatestr, defaultstr, extstr, append)

int	imlist			#I the image list descriptor
char	otemplatestr[ARB]	#I the file template string
char	defaultstr[ARB]		#I the defaults id string
char	extstr[ARB]		#I the extension string
int	append			#I test for existence of file ?

int	i, len_dir, olist, len_oliststr, strfd
pointer	sp, dirname, oliststr, image, fname
int	fnldir(), strncmp(), strlen(), fntopnb(), imtlen(), stropen()
int	imtrgetim(), fntrfnb(), fntlenb(), access() 
errchk	fntopnb()

begin
	# Return if the input file list is empty.
	iferr (olist = fntopnb (otemplatestr, NO))
	    olist = fntopnb ("", NO)
	if (otemplatestr[1] == EOS || fntlenb (olist) <= 0)
	    return (olist)

	# Return if the output file list is the wrong length.
	if (fntlenb (olist) > 1 && fntlenb (olist) != imtlen (imlist)) {
	    call fntclsb (olist)
	    olist = fntopnb ("", NO)
	    return (olist)
	}

	call smark (sp)
	call salloc (dirname, SZ_FNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)

	# Get the directory name.
	if (fntrfnb (olist, 1, Memc[fname], SZ_FNAME) == EOF)
	    Memc[fname] = EOS
	len_dir = fnldir (Memc[fname], Memc[dirname], SZ_FNAME)

	# Get the default output file names. There will be one output file per
	# input image.
	if (strncmp (defaultstr, Memc[fname+len_dir],
	    strlen (defaultstr)) == 0 || len_dir == strlen (Memc[fname])) {

	    call fntclsb (olist)
	    len_oliststr = imtlen (imlist) * SZ_FNAME + 1
	    call salloc (oliststr, len_oliststr, TY_CHAR)
	    call salloc (image, SZ_FNAME, TY_CHAR)
	    Memc[oliststr] = EOS

	    strfd = stropen (Memc[oliststr], len_oliststr, NEW_FILE) 
	    do i = 1, imtlen (imlist) {
	        if (imtrgetim (imlist, i, Memc[image], SZ_FNAME) == EOF)
		    break
		call xp_outname (Memc[image], Memc[dirname], extstr,
		    Memc[dirname], SZ_FNAME)
		call fprintf (strfd, "%s,")
		    call pargstr (Memc[dirname])
	    }
	    call close (strfd)

	    if (Memc[oliststr] != EOS)
	        Memc[oliststr+strlen(Memc[oliststr])-1] = EOS
	    olist = fntopnb (Memc[oliststr], NO)

	# Get the user output names.
	} else {

	    len_oliststr = fntlenb (olist) * SZ_FNAME + 1
	    call salloc (oliststr, len_oliststr, TY_CHAR)
	    Memc[oliststr] = EOS

	    strfd = stropen (Memc[oliststr], len_oliststr, NEW_FILE) 
	    do i = 1, fntlenb (olist) {
	        if (fntrfnb (olist, i, Memc[fname], SZ_FNAME) == EOF)
		    break
		if (append == NO) {
		    if (access (Memc[fname], 0, 0) == YES) {
	        	if (imtrgetim (imlist, i, Memc[image], SZ_FNAME) == EOF)
			    break
		        call xp_outname (Memc[image], Memc[dirname], extstr,
		            Memc[fname], SZ_FNAME)
		    }
		}
		call fprintf (strfd, "%s,")
		    call pargstr (Memc[fname])
	    }
	    call close (strfd)

	    if (Memc[oliststr] != EOS)
	        Memc[oliststr+strlen(Memc[oliststr])-1] = EOS
	    call fntclsb (olist)
	    olist = fntopnb (Memc[oliststr], NO)
	}

	call sfree (sp)

	return (olist)
end


# XP_PFLIST - Print the input and out image and file lists.

procedure xp_pflist (gd, xp, dirlist, imlist, objlist, reslist, greslist)

pointer gd              #I pointer to the graphics stream
pointer xp              #I pointer to the main xapphot structure
int	dirlist		#I the current directory list descriptor
int	imlist		#I the input image list descriptor
int	objlist		#I the input objects file list descriptor
int	reslist		#I the output results file list descriptor
int	greslist	#I the output objects file list descriptor

int     i, tmp, nchars, imno, olno, rlno, glno
pointer sp, tmpname, pathname, fname
int     xp_stati(), open(), imtlen(), imtrgetim(), fntlenb(), fntrfnb()

begin
        call smark (sp)
        call salloc (tmpname, SZ_FNAME, TY_CHAR)
        call salloc (pathname, SZ_PATHNAME, TY_CHAR)
        call salloc (fname, SZ_FNAME, TY_CHAR)

	imno = xp_stati (xp, IMNUMBER)
	olno = xp_stati (xp, OFNUMBER)
	rlno = xp_stati (xp, RFNUMBER)
	glno = xp_stati (xp, GFNUMBER)

        call mktemp ("tmp$fl", Memc[tmpname], SZ_FNAME)
        tmp = open (Memc[tmpname], NEW_FILE, TEXT_FILE)

	call xp_stats (xp, CURDIR, Memc[pathname], SZ_FNAME)
        call fprintf (tmp, "Current directory: %s\n")
	    call pargstr (Memc[pathname])
	do i = 1, fntlenb (dirlist) {
	    nchars = fntrfnb (dirlist, i, Memc[fname], SZ_FNAME)
	    call fprintf (tmp, "    %s\n")
		call pargstr (Memc[fname])
	}
	call fprintf (tmp, "\n")

	call xp_stats (xp, IMTEMPLATE, Memc[fname], SZ_FNAME)
        call fprintf (tmp, "Image file list: %s\n")
	    call pargstr (Memc[fname])
	do i = 1, imtlen (imlist) {
	    nchars = imtrgetim (imlist, i, Memc[fname], SZ_FNAME)
	    if (i == imno) {
		call fprintf (tmp, "    [%04d] %s *\n")
	    } else {
		call fprintf (tmp, "    [%04d] %s\n")
	    }
	    call pargi (i)
	    call pargstr (Memc[fname])
	}
	call fprintf (tmp, "\n")

	call xp_stats (xp, OFTEMPLATE, Memc[fname], SZ_FNAME)
        call fprintf (tmp, "Objects file list: %s\n")
	    call pargstr (Memc[fname])
	do i = 1, fntlenb (objlist) {
	    nchars = fntrfnb (objlist, i, Memc[fname], SZ_FNAME)
	    if (i == olno) {
		call fprintf (tmp, "    [%04d] %s *\n")
	    } else {
		call fprintf (tmp, "    [%04d] %s\n")
	    }
	    call pargi (i)
	    call pargstr (Memc[fname])
	}
	call fprintf (tmp, "\n")

	call xp_stats (xp, RFTEMPLATE, Memc[fname], SZ_FNAME)
        call fprintf (tmp, "Results file list: %s\n")
	    call pargstr (Memc[fname])
	do i = 1, fntlenb (reslist) {
	    nchars = fntrfnb (reslist, i, Memc[fname], SZ_FNAME)
	    if (i == rlno) {
		call fprintf (tmp, "    [%04d] %s *\n")
	    } else {
		call fprintf (tmp, "    [%04d] %s\n")
	    }
	    call pargi (i)
	    call pargstr (Memc[fname])
	}
	call fprintf (tmp, "\n")

	call xp_stats (xp, GFTEMPLATE, Memc[fname], SZ_FNAME)
        call fprintf (tmp, "Output objects file list: %s\n")
	    call pargstr (Memc[fname])
	do i = 1, fntlenb (greslist) {
	    nchars = fntrfnb (greslist, i, Memc[fname], SZ_FNAME)
	    if (i == glno) {
		call fprintf (tmp, "    [%04d] %s *\n")
	    } else {
		call fprintf (tmp, "    [%04d] %s\n")
	    }
	    call pargi (i)
	    call pargstr (Memc[fname])
	}
	call fprintf (tmp, "\n")

        call close (tmp)
        call gpagefile (gd, Memc[tmpname], "")
        call delete (Memc[tmpname])
        call sfree (sp)
end


# XP_INNAME -- Construct an xapphot input file name. If input is null or a
# directory, a name is constructed from the root of the image name and the
# extension. The disk is searched to avoid name collisions.

procedure xp_inname (image, input, ext, name, maxch)

char	image[ARB]		#I input image name
char	input[ARB]		#I input directory or name
char	ext[ARB]		#I input file extension
char	name[ARB]		#O output input file name
int	maxch			#I maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen()

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (input, name, maxch)
	if (strlen (input) == ndir) {
	    call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
	        Memc[str], SZ_FNAME, clindex, clsize)
	    nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
	    if (clindex >= 0) {
	        call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
		    call pargstr (Memc[root+nimdir])
		    call pargi (clindex)
		    call pargstr (ext)
	    } else {
	        call sprintf (name[ndir+1], maxch, "%s.%s.*")
		    call pargstr (Memc[root+nimdir])
		    call pargstr (ext)
	    }

	    call xp_iversion (name, name, maxch)
	} else
	    call strcpy (input, name, maxch)

	call sfree (sp)
end


# XP_OUTNAME -- Construct an xapphot output file name.
# If output is null or a directory, a name is constructed from the root
# of the image name and the extension. The disk is searched to avoid
# name collisions.

procedure xp_outname (image, output, ext, name, maxch)

char	image[ARB]		#I input image name
char	output[ARB]		#I input output directory or name
char	ext[ARB]		#I input extension
char	name[ARB]		#O output file name
int	maxch			#I maximum size of name

int	ndir, nimdir, clindex, clsize
pointer	sp, root, str
int	fnldir(), strlen(),

begin
	call smark (sp)
	call salloc (root, SZ_FNAME, TY_CHAR)
	call salloc (str, SZ_FNAME, TY_CHAR)

	ndir = fnldir (output, name, maxch)
	if (strlen (output) == ndir) {
	    call imparse (image, Memc[root], SZ_FNAME, Memc[str], SZ_FNAME,
	        Memc[str], SZ_FNAME, clindex, clsize)
	    nimdir = fnldir (Memc[root], Memc[str], SZ_FNAME)
	    if (clindex >= 0) {
	        call sprintf (name[ndir+1], maxch, "%s%d.%s.*")
		    call pargstr (Memc[root+nimdir])
		    call pargi (clindex)
		    call pargstr (ext)
	    } else {
	        call sprintf (name[ndir+1], maxch, "%s.%s.*")
		    call pargstr (Memc[root+nimdir])
		    call pargstr (ext)
	    }
	    call xp_oversion (name, name, maxch)
	} else
	    call strcpy (output, name, maxch)

	call sfree (sp)
end


## APTMPIMAGE -- Generate a temporary image name either by calling a system
## routine or by appending the image name to a user specified prefix.
#
#int procedure aptmpimage (image, prefix, tmp, name, maxch)
#
#char	image[ARB]		# image name
#char	prefix[ARB]		# user supplied prefix
#char	tmp[ARB]		# user supplied temporary root
#char	name[ARB]		# output name
#int	maxch			# max number of chars
#
#int	npref, ndir
#int	fnldir(), apimroot(), strlen()
#
#begin
#	npref = strlen (prefix)
#	ndir = fnldir (prefix, name, maxch)
#	if (npref == ndir) {
#	    call mktemp (tmp, name[ndir+1], maxch)
#	    return (NO)
#	} else {
#	    call strcpy (prefix, name, npref)
#	    if (apimroot (image, name[npref+1], maxch) <= 0)
#		;
#	    return (YES)
#	}
#end


# XP_IMROOT -- Fetch the root image name minus the directory specification
# and the section notation. The length of the root name is returned.
#
#int procedure xp_imroot (image, root, maxch)
#
#char	image[ARB]		# the input image name
#char	root[ARB]		# the output root image name
#int	maxch			# the maximum size of the output name
#
#int	nchars
#pointer	sp, str
#int	fnldir(), strlen()
#
#begin
#	call smark (sp)
#	call salloc (str, SZ_FNAME, TY_CHAR)
#	call imgimage (image, root, maxch)
#	nchars = fnldir (root, Memc[str], maxch)
#	call strcpy (root[nchars+1], root, maxch)
#	call sfree (sp)
#
#	return (strlen (root))
#end


# XP_OVERSION -- Compute the next available version number of a given file
# name template and output the new file name.

procedure xp_oversion (template, filename, maxch)

char	template[ARB]			#I the input name template
char	filename[ARB]			#O the output name
int	maxch				#I the  maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	fntgfnb() strldx(), ctoi(), fntopnb()
errchk	fntopnb()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	iferr (list = fntopnb (template, NO))
	    list = fntopnb ("", NO)

	# Loop over the names in the list searchng for the highest version.
	newversion = 0
	while (fntgfnb (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion + 1)

	call fntclsb (list)
	call sfree (sp)
end


# XP_IVERSION -- Compute the highest available version number of a given file
# name template and output the file name.

procedure xp_iversion (template, filename, maxch)

char	template[ARB]			#I the input name template
char	filename[ARB]			#O the output name
int	maxch				#I the maximum number of characters

char	period
int	newversion, version, len
pointer	sp, list, name
int	fntgfnb() strldx(), ctoi(), fntopnb()
errchk	fntopnb()

begin
	# Allocate temporary space
	call smark (sp)
	call salloc (name, maxch, TY_CHAR)
	period = '.'
	iferr(list = fntopnb (template, NO))
	    list = fntopnb ("", NO)

	# Loop over the names in the list searchng for the highest version.
	newversion = 1
	while (fntgfnb (list, Memc[name], maxch) != EOF) {
	    len = strldx (period, Memc[name])
	    len = len + 1
	    if (ctoi (Memc[name], len, version) <= 0)
		next
	    newversion = max (newversion, version)
	}

	# Make new output file name.
	len = strldx (period, template)
	call strcpy (template, filename, len)
	call sprintf (filename[len+1], maxch, "%d")
	    call pargi (newversion)

	call fntclsb (list)
	call sfree (sp)
end
