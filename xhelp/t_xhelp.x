# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<syserr.h>
include	<fset.h>
include	<error.h>
include <ctype.h>
include	"help/help.h"
include	"help/helpdir.h"
include	"xhelp.h"


# XHELP callback commands.
define  XC_COMMANDS "|help|load|print|quit|search|files|directory|type|package|"
define  CMD_HELP        1
define  CMD_LOAD        2
define  CMD_PRINT       3
define  CMD_QUIT        4
define  CMD_SEARCH      5
define  CMD_FILES       6
define  CMD_DIRECTORY   7
define  CMD_TYPE   	8
define  CMD_PACKAGE     9

define	SZ_ARG		SZ_FNAME


# T_XHELP -- The main task procedure.  XHELP is a GUI client program for
# browsing the IRAF help system.  As much as possible it uses the existing
# help database code but provides a friendlier interface, allowing users to
# browse packages for help pages in the same way they would browse packages
# in the CL.  It provides an HTML converter for LROFF sources for better
# presentation in the GUI, as well as Postscript generation for better
# looking hardcopy.  XHelp acts as a server for the help system, merely
# returning any output that the GUI has requested.  Navigation is done in
# the GUI code, this program maintains just the state of the last page
# returned and knows nothing about how it got there.  See the xhelp.hlp for
# detailed documentation.

procedure t_xhelp ()

pointer	xh, sp, cmd, arg, opt, pkg, pat
pointer	str, gui, dev, name
real    x, y
int     wcs, key, exact_match, search, template

pointer	xh_open(), gopenui()
bool    streq(), clgetb()
int     btoi(), clgcur(), clgeti(), strdic()

begin
	# Allocate working memory.
	call smark (sp)
	call salloc (str, SZ_ARG, TY_CHAR)
	call salloc (cmd, SZ_ARG, TY_CHAR)
	call salloc (opt, SZ_ARG, TY_CHAR)
	call salloc (gui, SZ_ARG, TY_CHAR)
	call salloc (dev, SZ_ARG, TY_CHAR)
	call salloc (pkg, SZ_ARG, TY_CHAR)
	call salloc (pat, SZ_ARG, TY_CHAR)
	call salloc (arg, SZ_ARG, TY_CHAR)
	call salloc (name, SZ_ARG, TY_CHAR)

	# Clear working arrays.
	call aclrc (Memc[str], SZ_ARG)
	call aclrc (Memc[cmd], SZ_ARG)
	call aclrc (Memc[opt], SZ_ARG)
	call aclrc (Memc[gui], SZ_ARG)
	call aclrc (Memc[dev], SZ_ARG)
	call aclrc (Memc[pkg], SZ_ARG)
	call aclrc (Memc[pat], SZ_ARG)
	call aclrc (Memc[arg], SZ_ARG)
	call aclrc (Memc[name], SZ_ARG)

	# Open struct for the task and allocate pointers.
	xh = xh_open ()

        # Load the task parameters.
        if (clgeti ("$nargs") > 0)
            call clgstr ("topic", TOPIC(xh), SZ_FNAME)
        call clgstr ("option",  OPTION(xh),  SZ_FNAME)
        call clgstr ("printer", PRINTER(xh), SZ_FNAME)
        call clgstr ("quickref", QUICKREF(xh), SZ_FNAME)
	XH_SHOWTYPE(xh) = btoi (clgetb("showtype"))
	search = btoi (clgetb("search"))
	template = btoi (clgetb("file_template"))

        # Fetch the name of the help database.
	call xh_ghelpdb (xh)

        # Open the GUI.
        call clgstr ("uifname", Memc[gui], SZ_ARG)
        XH_GP(xh) = gopenui ("stdgraph", NEW_FILE, Memc[gui], STDGRAPH)
	call gflush (XH_GP(xh))

	# Initialize the task and send topic list to the GUI.
	call xh_init (xh, template, search)

	# Enter the command loop.
        while (clgcur ("coords", x, y, wcs, key, Memc[str], SZ_ARG) != EOF) {

	    # Skip any non-colon commands.
	    if (key != ':') 			
		next

	    # Get the colon command string.
	    call sscan (Memc[str])
	        call gargwrd (Memc[cmd], SZ_ARG)

	    switch (strdic (Memc[cmd], Memc[cmd], SZ_ARG, XC_COMMANDS)) {
	    case CMD_HELP:
	        call gargwrd (Memc[name], SZ_ARG)

	        # Get help on the requested topic, updates package list 
	        # if necesary.
	        if (streq(Memc[name],"Home")) {
	    	    call xh_init (xh, NO, YES) 			
	        } else {
	            call gargwrd (Memc[pkg], SZ_ARG)		# curpack
		    call gargwrd (Memc[opt], SZ_ARG)		# option
		    call xh_cmd_help (xh, Memc[name], Memc[pkg], Memc[opt])
		}

	    case CMD_FILES:
	        call gargwrd (Memc[name], SZ_ARG)		# task name
		call gargwrd (Memc[pkg], SZ_ARG)		# parent package
		call xh_files (xh, Memc[name], Memc[pkg])

	    case CMD_LOAD:
		# Load a requested page from the history.
	        call gargwrd (Memc[name], SZ_ARG)		# task name
        	call gargwrd (Memc[pkg], SZ_ARG)		# curpack
        	call gargwrd (Memc[opt], SZ_ARG)		# help option
		call xh_cmd_load (xh, Memc[name], Memc[pkg], Memc[opt])

	    case CMD_PRINT:
		# Print the current results.
	        call gargwrd (Memc[name], SZ_ARG)		# task name
        	call gargwrd (Memc[pkg], SZ_ARG)		# curpack
		call gargwrd (Memc[dev], SZ_ARG)		# printer name
		call xh_print_help (xh, Memc[name], Memc[pkg], Memc[dev])

	    case CMD_QUIT:
		# Quit the task.
		break

	    case CMD_SEARCH:
		# Get the results of the keyword search.
		call gargi (exact_match)
	        call gargstr (Memc[pat], SZ_ARG)
		call xh_search (xh, exact_match, Memc[pat])

	    case CMD_DIRECTORY:
		# Process the directory browsing command.
	        call gargwrd (Memc[opt], SZ_ARG)
		call xh_directory (xh, Memc[opt])

	    case CMD_TYPE:
		# Get the showtype value from the GUI
		call gargi (XH_SHOWTYPE(xh))

	    case CMD_PACKAGE:
		# For the given item return the package in which it
		# was found.  [DEBUG ROUTINE.]
	        call gargwrd (Memc[name], SZ_ARG)
		call xh_pkgpath (xh, Memc[name], CURPACK(xh), Memc[pkg])
		call printf ("%s => %s\n")
		    call pargstr (Memc[name])
		    call pargstr (Memc[pkg])
		call flush(STDOUT)
	    }
	}

	# Clean up.
	call gclose (XH_GP(xh))
	call xh_close (xh)
	call sfree (sp)
end


# XH_OPEN -- Open and allocate the XHELP task structure.

pointer procedure xh_open ()

pointer	xh					# task descriptor
errchk	calloc

begin
        iferr (call calloc (xh, SZ_XHELPSTRUCT, TY_STRUCT))
            call error (0, "Error opening task structure.")

	iferr {
            call calloc (XH_LPTR(xh), SZ_HELPLIST, TY_CHAR)
            call calloc (XH_TOPIC(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_OPTION(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_PRINTER(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_CURTASK(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_CURPACK(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_QUICKREF(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_HOMEPAGE(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_CURDIR(xh), SZ_PATHNAME, TY_CHAR)
            call calloc (XH_PATTERN(xh), SZ_FNAME, TY_CHAR)
            call calloc (XH_HELPDB(xh), SZ_HELPDB, TY_CHAR)
	} then
	    call error (0, "Error allocating structure pointers.")

	return (xh)
end


# XH_CLOSE -- Close the XHELP task structure.

procedure xh_close (xh)

pointer	xh					# task descriptor

begin
        call mfree (XH_TOPIC(xh), TY_CHAR)
        call mfree (XH_OPTION(xh), TY_CHAR)
        call mfree (XH_PRINTER(xh), TY_CHAR)
        call mfree (XH_CURTASK(xh), TY_CHAR)
        call mfree (XH_CURPACK(xh), TY_CHAR)
        call mfree (XH_QUICKREF(xh), TY_CHAR)
        call mfree (XH_HOMEPAGE(xh), TY_CHAR)
        call mfree (XH_CURDIR(xh), TY_CHAR)
        call mfree (XH_PATTERN(xh), TY_CHAR)
        call mfree (XH_HELPDB(xh), TY_CHAR)
        call mfree (XH_LPTR(xh),  TY_CHAR)

        call mfree (xh, TY_STRUCT)
end


# XH_CMD_HELP -- Process a help command.

procedure xh_cmd_help (xh, topic, curpack, option)

pointer	xh					# task descriptor
char	topic[ARB]				# requested topic
char	curpack[ARB]				# current package
char	option[ARB]				# option (help|source|sysdoc)

int	len

bool    streq()
int	strncmp()
int	xh_pkgname(), xh_pkglist()

begin
	if (streq (option, "help")) {
	    # No package name given, find one and load it.
	    if (streq (curpack, "{}")) {
		curpack[1] = EOS
		len = 0
	    	if (xh_pkgname (xh, topic, curpack) == OK)
		    len = xh_pkglist (xh, curpack, HELPDB(xh), LIST(xh))

		if (len != 0 && 
		    strncmp(curpack, "root", 4) != 0 &&
		    strncmp(curpack, "clpack", 6) != 0) {
		        call gmsg (XH_GP(xh), "pkglist", LIST(xh))
		        call strcpy (curpack, CURPACK(xh), SZ_FNAME)
    		        call gmsg (XH_GP(xh), "curpack", curpack)
			call gmsg (XH_GP(xh), "history", "package")
		}
	    }

		
	    if (xh_pkglist (xh, topic, HELPDB(xh), LIST(xh)) != 0) {
		# Got a package listing....
		call gmsg (XH_GP(xh), "pkglist", LIST(xh))
		call strcpy (topic, CURPACK(xh), SZ_FNAME)
    		call gmsg (XH_GP(xh), "curpack", topic)
	    }
	}

	if (streq (topic, CURPACK(xh))) {
	    call gmsg (XH_GP(xh), "type", "package")
	    call gmsg (XH_GP(xh), "curtask", topic)
	    if (streq (option, "help"))
		call xh_help (xh, "", CURPACK(xh), option)
	    else
		call xh_help (xh, topic, curpack, option)
	    call strcpy (CURPACK(xh), CURTASK(xh), SZ_FNAME)

	} else {
	    call gmsg (XH_GP(xh), "type", "task")
	    call gmsg (XH_GP(xh), "curtask", topic)
	    call xh_help (xh, topic, CURPACK(xh), option)
	    call strcpy (topic, CURTASK(xh), SZ_FNAME)
	}
	call gmsg (XH_GP(xh), "history", "append")
end


# XH_CMD_LOAD -- Simply load the requested items.  This is only called
# from a history selection in the GUI so we know the thing exists.  This
# allows us to load a help page without doing anything else that changes
# the state of the GUI.

procedure xh_cmd_load (xh, topic, curpack, option)

pointer	xh					# task descriptor
char	topic[ARB]				# requested topic
char	curpack[ARB]				# current package
char	option[ARB]				# option (help|source|sysdoc)

int	xh_pkglist()

begin
        if (xh_pkglist (xh, topic, HELPDB(xh), LIST(xh)) != 0)
            call gmsg (XH_GP(xh), "pkglist", LIST(xh))
        call xh_help (xh, topic, curpack, option)
end


# XH_GHELPDB -- Fetch the name of the help database, i.e., "helpdb",
# "helpdir",  or the name of a file.   If the helpdb string is a list check
# for the existance of each file in the list to ensure the final list
# contains only valid help databases.

procedure xh_ghelpdb (xh)

pointer	xh					# task descriptor

pointer	sp, hdb, hdbstr, name
int	list
int	fntopnb(), fntgfnb()
int	access(), envgets()
bool	streq()

begin
	call smark (sp)
	call salloc (name, SZ_FNAME, TY_CHAR)
	call salloc (hdb, SZ_HELPDB, TY_CHAR)
	call salloc (hdbstr, SZ_HELPDB, TY_CHAR)

	# Clear the working memory.
	call aclrc (Memc[name], SZ_FNAME)
	call aclrc (Memc[hdb], SZ_HELPDB)
	call aclrc (Memc[hdbstr], SZ_HELPDB)

	# Get the parameter value.
        call clgstr ("helpdb", Memc[hdbstr], SZ_HELPDB)
        if (streq (Memc[hdbstr], "helpdb"))
            if (envgets ("helpdb", Memc[hdbstr], SZ_HELPDB) <= 0)
                call syserrs (SYS_ENVNF, "helpdb")

	# Open the list.
	list = fntopnb (Memc[hdbstr], YES)

	# Copy each of the existing files in the list to the output database
	# string to be used by the task.
	while (fntgfnb(list, Memc[name], SZ_FNAME) != EOF) {
	    if (access (Memc[name], 0, 0) == YES) {
		if (Memc[hdb] != EOS)
		    call strcat (",", Memc[hdb], SZ_HELPDB)
		call strcat (Memc[name], Memc[hdb], SZ_HELPDB)
	    }
	}
	call strcpy (Memc[hdb], HELPDB(xh), SZ_HELPDB)

	# Clean up.
	call fntclsb (list)
	call sfree (sp)
end
