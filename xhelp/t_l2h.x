include	<syserr.h>
include	<ctype.h>


procedure t_l2h ()

int	fdi, fdo
pointer	sp, iname, oname

int	open()
errchk	open

begin
	call smark (sp)
	call salloc (iname, SZ_FNAME, TY_CHAR) 
	call salloc (oname, SZ_FNAME, TY_CHAR) 

	# Get parameters.
	call clgstr ("input",  Memc[iname], SZ_FNAME)
	call clgstr ("output", Memc[oname], SZ_FNAME)

	# Open the file.
	fdi = open (Memc[iname], READ_ONLY, TEXT_FILE)
	fdo = open (Memc[oname], NEW_FILE, TEXT_FILE)

	# Process it.
	call lroff2html (fdi, fdo, Memc[iname], "", "", "", "")

	call close (fdi)
	call close (fdo)
	call sfree (sp)
end
