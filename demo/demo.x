# DEMO -- Dummy task for testing gui files.

task	demo		= t_demo

# T_DEMO -- Execute a user interface in prototype widget server

procedure t_demo()

char	uifname[SZ_FNAME]
char	strval[SZ_LINE]
int	wcs, key, clgcur()
real	x, y
pointer	gp, gopenui()

begin
	call clgstr ("uifname", uifname, SZ_FNAME)

	gp = gopenui ("stdgraph", NEW_FILE, uifname, STDGRAPH)
	while (clgcur ("coords", x, y, wcs, key, strval, SZ_LINE) != EOF) {
	    switch (key) {
	    case 'q', 'Q':
	        call gclose (gp)
		break
	    }
	}
end
