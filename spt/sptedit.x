include	<smw.h>
include	"spectool.h"

define	ZAP	1	# Radius of zap


procedure spt_edit (spt, reg, stype, gp, wx, wy, wcs, key, cmd)

pointer	spt		#I SPECTOOLS pointer
pointer	reg		#I Register pointer
int	stype		#I Spectrum type
pointer	gp		#I GIO pointer
real	wx, wy		#U Coordinate
int	wcs		#U WCS
int	key		#U Key
char	cmd[SZ_LINE]	#U Colon command

int	i, i1, i2, imin, imax, keylast, clgcur()
real	wxlast, wylast, y1, y2
double	z1, z2, shdr_wl(), shdr_lw()
pointer	sh, sy

define	z_	10

begin
	gp = SPT_GP(spt)
	sh = REG_SH(reg)
	sy = SPEC(sh,stype)

	call spt_shcopy (sh, REG_SHBAK(reg), YES)

	wxlast = wx
	wylast = wy
	keylast = key
	call printf ("More %c:\n")
	    call pargi (key)
	if (key == 'z')
	    goto z_
	while (clgcur ("cursor", wx, wy, wcs, key, cmd, SZ_LINE) != EOF) {
z_	     if (key != keylast)
		break

	    z1 = max (0.5D0, min (double (SN(sh)+.499),
		shdr_wl(sh, double(wxlast))))
	    z2 = max (0.5D0, min (double (SN(sh)+.499),
		shdr_wl(sh, double(wx))))
	    i1 = nint (z1)
	    i2 = nint (z2)
	    wxlast = shdr_lw (sh, z1)
	    wx = shdr_lw (sh, z2)

	    switch (key) {
	    case 'x':
		y1 = Memr[sy+i1-1]
		y2 = Memr[sy+i2-1]
	    case 'c', 'y':
		y1 = wylast
		y2 = wy
	    case 'z':
		i1 = max (1, min(i1,i2) - ZAP)
		i2 = min (i1 + 2 * ZAP, SN(sh))

		i = i1
		y1 = abs (wylast - Memr[sy+i1-1])
		for (i1 = i1 + 1; i1 <= i2; i1=i1+1) {
		    y2 = abs (wylast - Memr[sy+i1-1])
		    if (y2 > y1) {
			y1 = y2
			i = i1
		    }
		}

		i1 = max (1, i - 1)
		i2 = min (SN(sh), i + 1)
		y1 = Memr[sy+i1-1]
		y2 = Memr[sy+i2-1]
	    }

	    if (i1 == i2)
		y2 = 1
	    else
		y2 = (y2 - y1) / (i2 - i1)
	    imin = min (i1, i2)
	    imax = max (i1, i2)
	    call spt_plotreg1 (spt, reg, imin-1, imax+1, stype, YES)
	    do i = imin, imax
		Memr[sy+i-1] = y1 + y2 * (i - i1)
	    call spt_plotreg1 (spt, reg, imin-1, imax+1, stype, NO)

	    call spt_scale (spt, reg)

	    if (REG_MODIFIED(reg) != 'M') {
		REG_MODIFIED(reg) = 'M'
		call spt_rglist (spt, reg)
	    }

	    wxlast = wx
	    wylast = wy
	    keylast = key
	}
	call printf ("\n")
end
