# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include <diropen.h>
include	<ctype.h>
include	<finfo.h>
include "rvpackage.h"


# Pattern matching definitions.
define  PATCHARS        "*?[" 		

# Browsing command dictionary.
define	DIR_CMDS "|dirlist|loadobj|loadtemp|template|home|up|root|rescan|select|"
define	DIRLIST		1		# get the directory listing
define	LOADOBJ		2		# load the requested file
define	LOADTEMP	3		# load the requested file
define	TEMPLATE	4		# filename matching template
define	HOME		5		# goto the user's home$
define	UP		6		# go up one directory
define	ROOT		7		# go to the root directory
define	RESCAN		8		# rescan current directory
define	SELECT		9		# file selection


# RV_DIRECTORY -- Process the directory browsing command.

procedure rv_directory (rv, command)

pointer	rv					#i task descriptor
char	command[ARB]				#i command option

pointer	sp, dir, file, pattern, path, fmt
pointer task, pkg, opt, type
int	ncmd
int	strdic(), strcmp(), envgets()

begin
	# Allocate working space and clear it.
	call smark (sp)
	call salloc (dir, SZ_PATHNAME, TY_CHAR) 	
	call salloc (path, SZ_PATHNAME, TY_CHAR) 	
	call salloc (file, SZ_FNAME, TY_CHAR)
	call salloc (pattern, SZ_FNAME, TY_CHAR)
	call salloc (fmt, SZ_FNAME, TY_CHAR)
	call salloc (task, SZ_FNAME, TY_CHAR)
	call salloc (pkg, SZ_FNAME, TY_CHAR)
	call salloc (opt, SZ_FNAME, TY_CHAR)
	call salloc (type, SZ_FNAME, TY_CHAR)

	call aclrc (Memc[dir], SZ_FNAME)
	call aclrc (Memc[path], SZ_PATHNAME)
	call aclrc (Memc[file], SZ_FNAME)
	call aclrc (Memc[fmt], SZ_FNAME)
	call aclrc (Memc[pattern], SZ_FNAME)
	call aclrc (Memc[task], SZ_FNAME)
	call aclrc (Memc[pkg], SZ_FNAME)
	call aclrc (Memc[opt], SZ_FNAME)
	call aclrc (Memc[type], SZ_FNAME)

	ncmd = strdic (command, command, SZ_LINE, DIR_CMDS)
	switch (ncmd) {
	    case DIRLIST:
		call gargwrd (Memc[dir], SZ_PATHNAME) 	# get the dirname
		if (strcmp ("../", Memc[dir]) == 0) {
		    call rv_updir (rv)
		} else {
		    call sprintf (Memc[path], SZ_PATHNAME, "%s%s")
		        call pargstr (CURDIR(rv))
		        call pargstr (Memc[dir])
		    call rv_set_curdir (rv, Memc[path])
		    call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))
	            #call rv_selection (rv, CURDIR(rv))
		}

	    case LOADOBJ:
	    case LOADTEMP:
		call gargwrd (Memc[file], SZ_FNAME) 	# get the filename
		call sprintf (Memc[path], SZ_PATHNAME, "%s%s")
		    call pargstr (CURDIR(rv))
		    call pargstr (Memc[file])
	        call rv_selection (rv, Memc[path])

	    case TEMPLATE:
		call gargwrd (Memc[pattern], SZ_FNAME) 	# set the template
		call rv_set_pattern (rv, Memc[pattern])
		call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))

	    case HOME:
		if (envgets ("home", Memc[dir], SZ_PATHNAME) != EOF) {
		    call rv_set_curdir (rv, Memc[dir])
		    call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))
	   	}

	    case SELECT:
		call gargwrd (Memc[path], SZ_PATHNAME) 	# get the item
	        call rv_selection (rv, Memc[path])

	    case UP:
		call rv_updir (rv)

	    case ROOT:
		call rv_set_curdir (rv, "/")
		call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))

	    case RESCAN:
		call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))
	}

	call sfree (sp)
end


# RV_DIRLIST -- Given the directory name and a file template return the
# directory contents.

procedure rv_dirlist (rv, directory, pattern)

pointer	rv					#i task descriptor
char	directory[ARB]				#i directory to read
char	pattern[ARB]				#i matching template

pointer	sp, path, fname, patbuf
pointer	dp, fp, lp, ip, op, ep, sym
bool	match_extension, match_list
int	dd, n, patlen
int	nfiles, ndirs, lastch

pointer	stopen(), stenter()
int	diropen(), rv_isdir(), strncmp(), stridxs()
int	patmake(), patmatch(), strlen(), getline()
int	imtopen(), imtgetim()
bool	streq()

begin
	call smark (sp)
	call salloc (path, SZ_PATHNAME, TY_CHAR)
	call salloc (fname, SZ_FNAME, TY_CHAR)
	call salloc (patbuf, SZ_LINE, TY_CHAR)

	call aclrc (Memc[path], SZ_PATHNAME)
	call aclrc (Memc[fname], SZ_FNAME)
	call aclrc (Memc[patbuf], SZ_LINE)

	# If this isn't a directory just return silently.
	if (rv_isdir (directory, Memc[path], SZ_PATHNAME) == 0) {
	    call sfree (sp)
	    return
	}
	
	# Open the requested directory
	dd = diropen (directory, SKIP_HIDDEN_FILES)

	# Set up the pattern matching code.  We recognize selecting all files
	# with a particular extension as a special case, since this case is
	# very common and can be done much more efficiently if we don't use
	# the general pattern matching code.  If we have no pattern set the
	# length to zero to indicate that everything will match.

	match_list = (stridxs (",", pattern) != 0)
	if (pattern[1] == EOS) {
	    patlen = 0
	} else {
	    match_extension = (strncmp (pattern, "*.", 2) == 0 &&
		stridxs (PATCHARS, pattern[3]) <= 0)
	    if (match_extension || match_list)
		patlen = strlen (pattern)
	    else {
		# Convert file matching pattern into general pattern string.
		Memc[fname] = '^'
		op = fname + 1
		lastch = 0
		for (ip=1;  pattern[ip] != EOS;  ip=ip+1) {
		    if (pattern[ip] == '*' && lastch != '?' && lastch != ']') {
			Memc[op] = '?'
			op = op + 1
		    }
		    lastch = pattern[ip]
		    Memc[op] = lastch
		    op = op + 1
		}
		Memc[op] = '$'
		op = op + 1
		Memc[op] = EOS
			
		# Compile the pattern.
		patlen = patmake (pattern, Memc[patbuf], SZ_LINE)
	    }
	}

	# Initialize counters.
	ndirs  = 0
	nfiles = 0
	dp = NULL
	fp = NULL

	# Accumulate the contents into the directory and files lists.  We
	# match files against the given template, all directories are
	# matched regardless.  If we're matching a list of patterns get
	# those first then scan for directories.

	if (match_list) {
	    if (streq (directory, "/"))
		call fchdir ("//")
	    else
	        call fchdir (directory)
	    lp = imtopen (pattern)
	    while (imtgetim (lp, Memc[fname], SZ_FNAME) != EOF) {
		nfiles = nfiles + 1

		# If this is the first file initialize the symtab.
		if (nfiles == 1)
		    fp = stopen ("filelist", LEN_INDEX, LEN_STAB, SZ_SBUF)

		# Enter the directory name into the symbol table.
		sym = stenter (fp, Memc[fname], strlen(Memc[fname])+1)
	    }
	    call imtclose (lp)
	}

		
	# We're not reading hidden files so make a special entry for the
	# parent directory so we can navigate up.
	dp = stopen ("dirlist", LEN_INDEX, LEN_STAB, SZ_SBUF)
	sym = stenter (dp, "../", 4)

	for (n=0; n != EOF; ) {
	    n = getline (dd, Memc[fname])
	    if (n < 1)
		break
	    n = n - 1
	    Memc[fname+n] = EOS			# stomp the newline

	    # See if this is a directory.
	    call sprintf (Memc[path], SZ_PATHNAME, "%s%s")
		call pargstr (CURDIR(rv))
		call pargstr (Memc[fname])
	    if (rv_isdir (Memc[path], Memc[path], SZ_PATHNAME) > 0) {
		ndirs = ndirs + 1

		# If this is the first directory initialize the symtab.
		#if (ndirs == 1)
		#    dp = stopen ("dirlist", LEN_INDEX, LEN_STAB, SZ_SBUF)

		# Enter the directory name into the symbol table.
		call strcat ("/", Memc[fname], SZ_FNAME)
		sym = stenter (dp, Memc[fname], strlen(Memc[fname])+1)

	    } else if (!match_list) {
		# Check if the file matches the given pattern.  If we're
	 	# matching a list of patterns that was done above so we skip
		# simple files here.

		if (patlen > 0) {
		    if (match_extension) {
			if (n < patlen)
			    next
			ep = fname + n - 1
			for (ip=patlen; ip > 2; ip=ip-1) {
			    if (Memc[ep] != pattern[ip])
				break
			    ep = ep - 1
			}
			if (pattern[ip] != '.' || Memc[ep] != '.')
			    next
		    } else if (patmatch (Memc[fname], Memc[patbuf]) <= 0)
			next
		}

		# We have a match.
		nfiles = nfiles + 1

		# If this is the first file initialize the symtab.
		if (nfiles == 1)
		    fp = stopen ("filelist", LEN_INDEX, LEN_STAB, SZ_SBUF)

		# Enter the directory name into the symbol table.
		sym = stenter (fp, Memc[fname], strlen(Memc[fname])+1)
	    }
	}

	# Send the results to the GUI.
	call rv_putlist (rv, dp, "directory", "dirlist")
	call rv_putlist (rv, fp, "directory", "filelist")

	# Clean up.
	if (dp != NULL)
	    call stclose (dp)
	if (fp != NULL)
	    call stclose (fp)
	call close (dd)
	call sfree (sp)
end


# RV_PUTLIST -- Given the symtab for the directory contents construct a
# list suitable for a message to the GUI.  The 'arg' parameter is passed
# to indicate which type of list this is.

procedure rv_putlist (rv, stp, param, arg)

pointer	rv					#i task descriptor
pointer	stp					#i symtab ptr for list
char	param[ARB]				#i GUI param to notify
char	arg[ARB]				#i GUI param arg

pointer	sp, list, msg, sym, name, ip
int	nchars

pointer	sthead(), stnext(), stname()
int	stsize(), gstrcpy(), strcmp(), strlen()

begin
	# Return if there is no symtab information.
	if (stp == NULL) {
	    call smark (sp)
	    call salloc (msg, SZ_FNAME , TY_CHAR)
	    call sprintf (Memc[msg], SZ_FNAME, "%s { }")
	        call pargstr (arg)

	    call gmsg (RV_GP(rv), param, Memc[msg]) 	# send it to the GUI
	    call sfree (sp)
	    return
	}

	# Allocate space for the list.
	nchars =  stsize (stp) + 1

	call smark (sp)
	call salloc (list, nchars , TY_CHAR)
	call aclrc (Memc[list], nchars)
	ip = list

	# Build the list from the symtab.
        for (sym = sthead (stp); sym != NULL; sym = stnext (stp,sym)) {
	    name = stname(stp,sym)
	    if (strcmp (Memc[name], "./") != 0) {
	        ip = ip + gstrcpy (Memc[name], Memc[ip], SZ_FNAME)
	        ip = ip + gstrcpy (" ", Memc[ip], SZ_FNAME)
	    }
	}

	# Sort the list.
	call rv_sort_list (Memc[list])

	# Allocate space for the message buffer.  The "+ 6" is space for
	# the brackets around the list in the message created below.
	nchars = nchars + strlen (arg) + 6
	call salloc (msg, nchars, TY_CHAR)
	call aclrc (Memc[msg], nchars)
	ip = msg

	# Begin the message by adding the arg and make a Tcl list of the
	# contents.
	call sprintf (Memc[msg], nchars, "%s { %s }")
	    call pargstr (arg)
	    call pargstr (Memc[list])

	# Finally, send it to the GUI.
	call gmsg (RV_GP(rv), param, Memc[msg])

	call sfree (sp)
end


# RV_UPDIR -- Go up to the parent directory and return contents.

procedure rv_updir (rv)

pointer	rv					#i task descriptor

pointer	sp, ip, dir, parent
int	nchars, strlen()

begin
	call smark (sp)
	call salloc (dir, SZ_PATHNAME, TY_CHAR)
	call salloc (parent, SZ_PATHNAME, TY_CHAR)

	# Expand the current directory to a host path.
	call fdirname (CURDIR(rv), Memc[dir], SZ_PATHNAME)

	# Work backwards to the parent '/', be sure to skip the trailing
	# backslash already in the dirname.
	ip = dir + strlen (Memc[dir]) - 2
	while (Memc[ip] != '/' && ip > dir) 
	    ip = ip - 1

	nchars = ip - dir
	if (nchars > 0)
	    call strcpy (Memc[dir], Memc[parent], nchars)
	else
	    call strcpy ("/", Memc[parent], nchars)

	# Set the parent dir and load it's contents.
	call rv_set_curdir (rv, Memc[parent])
	call rv_dirlist (rv, CURDIR(rv), PATTERN(rv))
	#call rv_selection (rv, CURDIR(rv))

	call sfree (sp)
end


# RV_SET_CURDIR -- Set the filename matching template pattern.

procedure rv_set_curdir (rv, dir)

pointer	rv					#i task descriptor
char	dir[ARB]				#i current directory

pointer	sp, dirbuf
int	strlen()

begin
	call smark (sp)
	call salloc (dirbuf, SZ_PATHNAME, TY_CHAR)

	call strcpy (dir, CURDIR(rv), SZ_PATHNAME)
	if (dir[strlen(dir)] != '/')
	    call strcat ("/", CURDIR(rv), SZ_PATHNAME)

	call sprintf (Memc[dirbuf], SZ_PATHNAME, "curdir %s")
	    call pargstr (CURDIR(rv))

	call gmsg (RV_GP(rv), "directory", Memc[dirbuf])

	call sfree (sp)
end


# RV_SET_PATTERN -- Set the filename matching template pattern.

procedure rv_set_pattern (rv, pattern)

pointer	rv					#i task descriptor
char	pattern[ARB]				#i template pattern

pointer	sp, patbuf

begin
	call smark (sp)
	call salloc (patbuf, SZ_FNAME, TY_CHAR)

	call sprintf (Memc[patbuf], SZ_FNAME, "template %s")
	    call pargstr (pattern)

	call strcpy (pattern, PATTERN(rv), SZ_FNAME)
	call gmsg (RV_GP(rv), "directory", Memc[patbuf])

	call sfree (sp)
end


# RV_SELECTION -- Set the selected filename.

procedure rv_selection (rv, selection)

pointer	rv					#i task descriptor
char	selection[ARB]				#i selection

pointer	sp, buf

begin
	call smark (sp)
	call salloc (buf, SZ_FNAME, TY_CHAR)

	call sprintf (Memc[buf], SZ_FNAME, "selection %s")
	    call pargstr (selection)

	call gmsg (RV_GP(rv), "directory", Memc[buf])
	call sfree (sp)
end


# RV_ISDIR -- Test whether the named file is a directory.  Check first to
# see if it is a subdirectory of the current directory. If VFN is a directory,
# return the OS pathname of the directory in pathname, and the number of
# chars in the pathname as the function value.  Otherwise return 0.

int procedure rv_isdir (vfn, pathname, maxch)

char	vfn[ARB]		# name to be tested
char	pathname[ARB]		# receives path of directory
int	maxch			# max chars out

bool	isdir
pointer	sp, fname, op
int	ip, fd, nchars, ch
long	file_info[LEN_FINFO]
int	finfo(), diropen(), gstrcpy(), strlen()

begin
	call smark (sp)
	call salloc (fname, SZ_PATHNAME, TY_CHAR)

	# Copy the VFN string, minus any whitespace on either end.
	op = fname
	for (ip=1;  vfn[ip] != EOS;  ip=ip+1) {
	    ch = vfn[ip]
	    if (!IS_WHITE (ch)) {
		Memc[op] = ch
		op = op + 1
	    }
	}
	Memc[op] = EOS

	isdir = false
	if (finfo (Memc[fname], file_info) != ERR) {
	    isdir = (FI_TYPE(file_info) == FI_DIRECTORY)

	    if (isdir) {
		call fdirname (Memc[fname], pathname, maxch)
		nchars = strlen (pathname)
	    }

	} else {
	    # If we get here, the VFN is the name of a new file.
	    ifnoerr (fd = diropen (Memc[fname], 0)) {
		call close (fd)
		isdir = true
	    }
	    nchars = gstrcpy (Memc[fname], pathname, maxch)
	}

	call sfree (sp)
	if (isdir)
	    return (nchars)
	else {
	    pathname[1] = EOS
	    return (0)
	}
end


# RV_SORT_LIST -- Take a list of words (as with a package list) and sort them.

procedure rv_sort_list (list)

char	list[ARB]					#u list to be sorted

pointer	sp, index, buf, ip
int	i, j, count, len

int	strlen()

define  MAXPTR          20000
define  SZ_LINBUF       300000


begin
	len = strlen (list)

	call smark (sp)
	call salloc (index, SZ_LINBUF, TY_INT)
	call salloc (buf, len+2, TY_CHAR)

	# Build up the index array.
	count = 1
	Memi[index] = 1
	for (i=2; i<len; i=i+1) {
	    if (list[i] == ' ') {
		list[i] = EOS
		Memi[index+count] = i + 1
		count = count + 1
	    }
	}

	# Sort the list.
	call strsrt (Memi[index], list, count)

	# Restore the list.
	ip = buf
	do i = 1, count {
	    for (j=0; list[Memi[index+i-1]+j] != EOS; j=j+1) {
	        Memc[ip] = list[Memi[index+i-1]+j]
	        ip = ip + 1
	    }
	    Memc[ip] = ' '
	    ip = ip + 1
	}
	Memc[ip-1] = EOS
	call strcpy (Memc[buf], list, strlen(Memc[buf]))
	call sfree (sp)
end
