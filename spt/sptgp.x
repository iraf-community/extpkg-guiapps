include	<gio.h>
include	"spectool.h"

# SPT_GP -- Set selected WCS in GIO pointer.
# THIS IS A TEMPORARY INTERFACE VIOLATION FOR MULTIPLE GTERM WIDGETS.

pointer procedure spt_gp (spt, wcs)

pointer	spt		#I Spectool pointer
int	wcs		#I Desired WCS

int	i
pointer	gp

begin
	gp = SPT_GP(spt)
	i = SPT_WCS(spt)

	if (wcs == i)
	    return (gp)

	if (wcs < 1 || wcs > 2)
	    call error (1, "Invalid WCS")

	call gflush (gp)
	call amovi (Memi[GP_WCSPTR(gp,1)], Memi[SPT_WCSPTR(spt,i)],
	    LEN_WCSARRAY)

	i = wcs
	call amovi (Memi[SPT_WCSPTR(spt,i)], Memi[GP_WCSPTR(gp,1)],
	    LEN_WCSARRAY)
	GP_WCSSTATE(gp) = MODIFIED
	call gpl_cache (gp)
	SPT_WCS(spt) = wcs

	return (gp)
end
