
procedure t_l2p ()

int	fd
char	fname[SZ_FNAME]

pointer	ps
int	open()

begin
	call clgstr ("input",  fname, SZ_FNAME) # Get parameters.
	fd = open (fname, READ_ONLY, TEXT_FILE) # Open the file.

	# Process it.
	ps = NULL
	call lroff2ps (fd, STDOUT, ps, "", "")

	call close (fd)
end
