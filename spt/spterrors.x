include	"spectool.h"


# List of colon commands.
define	COLONCMDS "|open|close|errors|"

define	OPEN		1
define	CLOSE		2
define	ERRORS		3	# Set parameters


# SPT_ERRORS -- Errors.

procedure spt_errors (spt, cmd)

pointer	spt			#I SPECTOOLS pointer
char	cmd[ARB]		#I Command

int	ncmd, mcn, mcseed
real	mcsig
bool	bval

bool	clgetb()
int	clgeti(), strdic(), btoi(), nscan()
real	clgetr()
define	err_		10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt),
	    SPT_SZSTRING, COLONCMDS)

	switch (ncmd) {
	case OPEN:
	    SPT_ERRORS(spt) = btoi (clgetb ("errors"))
	    SPT_ERRMCN(spt) = clgeti ("mcsample")
	    SPT_ERRMCSIG(spt) = clgetr ("mcsigma")
	    SPT_ERRMCSEED(spt) = clgeti ("mcseed")
	    SPT_ERRMCP(spt) = 10

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%b %d %.1f %d")
		call pargi (SPT_ERRORS(spt))
		call pargi (SPT_ERRMCN(spt))
		call pargr (SPT_ERRMCSIG(spt))
		call pargi (SPT_ERRMCSEED(spt))
	    call gmsg (SPT_GP(spt), "errpars", SPT_STRING(spt))

	case CLOSE:
	    call clputb ("errors", (SPT_ERRORS(spt) == YES))
	    call clputi ("mcsample", SPT_ERRMCN(spt))
	    call clputr ("mcsigma", SPT_ERRMCSIG(spt))
	    call clputi ("mcseed", SPT_ERRMCSEED(spt))

	case ERRORS:
	    call gargb (bval)
	    call gargi (mcn)
	    call gargr (mcsig)
	    call gargi (mcseed)
	    if (nscan() != 5)
		goto err_

	    SPT_ERRORS(spt) = btoi (bval)
	    SPT_ERRMCN(spt) = mcn
	    SPT_ERRMCSIG(spt) = mcsig
	    SPT_ERRMCSEED(spt) = mcseed

	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%b %d %.1f %d")
		call pargi (SPT_ERRORS(spt))
		call pargi (SPT_ERRMCN(spt))
		call pargr (SPT_ERRMCSIG(spt))
		call pargi (SPT_ERRMCSEED(spt))
	    call gmsg (SPT_GP(spt), "errpars", SPT_STRING(spt))

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: errors %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end
