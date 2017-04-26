include	<error.h>
include	<smw.h>
include	<time.h>
include	"spectool.h"
include	"lids.h"
include	"rv.h"

# List of colon commands.
define	CMDS "|open|close|allocate|free|set|velocity|log|deredshift|"

define	OPEN	1	# Open/allocate/initialize
define	CLOSE	2	# Close/free
define	ALLOC	3	# Allocate and initialize RV structure
define	FREE	4	# Free register RV structure
define	SET	5	# Set velocity
define	VEL	6	# Compute velocity
define	LOG	7	# Write log
define	DERED	8	# Deredshift

# List of velocity types.
define	VTYPES	"|vobs|zobs|vhelio|zhelio|"
define	VOBS	1
define	ZOBS	2
define	VHELIO	3
define	ZHELIO	4

# SPT_RV -- Interpret RV colon commands.

procedure spt_rv (spt, reg, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	reg			#I Register pointer
char	cmd[ARB]		#I GIO command

int	i, strdic(), nscan()
double	z
pointer	rv, lids
pointer	un_open()
errchk	un_open, spt_velocity, spt_vhelio

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	i = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (i) {
	case OPEN:
	    call clgstr ("observatory", SPT_OBS(spt), SPT_SZLINE)

	case CLOSE:
	    call clpstr ("observatory", SPT_OBS(spt))

	case ALLOC: # allocate
	    if (reg == NULL)
		return
	    rv = REG_RV(reg)
	    lids = REG_LIDS(reg)
	    if (rv == NULL)
		call calloc (rv, SPT_RVLEN, TY_STRUCT)
	    RV_UN(rv) = un_open ("angstroms")
	    SPT_REDSHIFT(rv) = INDEFD
	    SPT_ZHELIO(rv) = INDEFD
	    SPT_RVOBS(rv) = EOS
	    call spt_rvlog (spt, reg, lids, rv)
	    REG_RV(reg) = rv

	case FREE: # free
	    if (reg == NULL)
		return
	    rv = REG_RV(reg)
	    if (rv != NULL)
		call un_close (RV_UN(rv))
	    call mfree (rv, TY_STRUCT)
	    REG_RV(reg) = rv

	case SET: # set [vobs|zobs|vhelio|zhelio] value
	    if (reg == NULL)
		return
	    rv = REG_RV(reg)
	    lids = REG_LIDS(reg)
	    call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	    call gargd (z)
	    if (nscan() < 3)
		SPT_REDSHIFT(rv) = INDEFD
	    else {
		i = strdic (SPT_STRING(spt),SPT_STRING(spt),SPT_SZSTRING,VTYPES)
		switch (i) {
		case VOBS:
		    SPT_REDSHIFT(rv) = z / VLIGHT
		case ZOBS:
		    SPT_REDSHIFT(rv) = z
		case VHELIO:
		    if (SPT_RVOBS(rv) == EOS)
			call spt_vhelio (spt, reg, rv)
		    if (IS_INDEFD(SPT_ZHELIO(rv)))
			SPT_REDSHIFT(rv) = z / VLIGHT
		    else
			SPT_REDSHIFT(rv) = z / VLIGHT - SPT_ZHELIO(rv)
		case ZHELIO:
		    if (IS_INDEFD(SPT_ZHELIO(rv)))
			SPT_REDSHIFT(rv) = z
		    else
			SPT_REDSHIFT(rv) = z - SPT_ZHELIO(rv)
		}
	    }
	    call spt_rvlog (spt, reg, lids, rv)
	    SPT_REDRAW(spt,1) = YES

	case VEL: # velocity
	    if (reg == NULL)
		return
	    rv = REG_RV(reg)
	    lids = REG_LIDS(reg)
	    call spt_velocity (spt, reg, lids, rv)
	    SPT_REDRAW(spt,1) = YES
	    if (SPT_RVOBS(rv) == EOS)
		iferr (call spt_vhelio (spt, reg, rv)) {
		    call spt_rvlog (spt, reg, lids, rv)
		    call erract (EA_ERROR)
		}

	    call spt_rvlog (spt, reg, lids, rv)

	case DERED: # deredshift
	    if (reg == NULL)
		return
	    rv = REG_RV(reg)
	    lids = REG_LIDS(reg)
	    if (!IS_INDEFD(SPT_REDSHIFT(rv))) {
		call sprintf (SPT_STRING(spt), SPT_SZSTRING, "deredshift %g")
		    call pargd (SPT_REDSHIFT(rv))
		call spt_coord (spt, reg, SPT_STRING(spt))
	    }

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: rv %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


# SPT_VELOCITY -- Compute velocity.

procedure spt_velocity (spt, reg, lids, rv)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register
pointer	lids			#I Features
pointer	rv			#I RV

int	i, n
double	w1, w2, z, sumz
pointer	un1, un2, lab

begin
	if (rv == NULL)
	    return

	if (lids == NULL)
	    call error (1, "No spectral lines defined")

	un1 = UN(REG_SH(reg))
	un2 = RV_UN(rv)

	sumz = 0.
	n = 0
	do i = 1, LID_NLINES(lids) {
	    lab = LID_LINES(lids,i)
	    if (lab == NULL)
		next
	    if (IS_INDEFD(LID_REF(lab)))
		next
	    call un_ctrand (un1, un2, LID_X(lab), w1, 1)
	    call un_ctrand (un1, un2, LID_REF(lab), w2, 1)
	    z = (w1 - w2) / w2
	    sumz = sumz + z
	    n = n + 1
	}

	SPT_RVN(rv) = n
	SPT_REDSHIFT(rv) = sumz / max (1, n)

	if (n == 0)
	    call error (1, "No spectral lines with reference coordinates")
end


# SPT_VHELIO -- Compute helocentric velocity and Julian day.

procedure spt_vhelio (spt, reg, rv)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register
pointer	rv			#I RV

bool	newobs, obshead
int	flags, year, month, day, fd
double	ra, dec, ep, ut, lt
double	epoch, vrot, vbary, vorb
double	latitude, longitude, altitude
pointer	sh, tmp, obs

int	stropen(), dtm_decode()
double	imgetd(), obsgetd()
errchk	imgetd, imgstr, obsimopen, stropen


begin
	if (spt == NULL || reg == NULL || rv == NULL)
	    return

	sh = REG_SH(reg)
	if (sh == NULL)
	    return

	iferr {
	    # Get the observatory data.
	    obs = NULL
	    call obsimopen (tmp, IM(sh), SPT_OBS(spt), NO, newobs, obshead)
	    obs = tmp

	    latitude = obsgetd (obs, "latitude")
	    longitude = obsgetd (obs, "longitude")
	    altitude = obsgetd (obs, "altitude")

	    # Get the image header data.
	    call imgstr (IM(sh), "date-obs", SPT_STRING(spt), SPT_SZSTRING)
	    if (dtm_decode (SPT_STRING(spt),year,month,day,ut,flags) == ERR)
		call error (1, "Error in date string")

	    if (IS_INDEFD(ut))
		ut = imgetd (IM(sh), "ut")
	    ra = imgetd (IM(sh), "ra")
	    dec = imgetd (IM(sh), "dec")
	    ep = imgetd (IM(sh), "epoch")

	    # Determine epoch of observation and precess coordinates.
	    call ast_date_to_epoch (year, month, day, ut, epoch)
	    call ast_precess (ra, dec, ep, ra, dec, epoch)

	    # Determine velocity components.
	    call ast_vorbit (ra, dec, epoch, vorb)
	    call ast_vbary (ra, dec, epoch, vbary)
	    call ast_vrotate (ra, dec, epoch, latitude, longitude,
		altitude, vrot)
	    call ast_hjd (ra, dec, epoch, lt, SPT_HJD(rv))

	    SPT_ZHELIO(rv) = (vrot + vbary + vorb) / VLIGHT

	    fd = stropen (SPT_RVOBS(rv), SPT_OBSLEN, NEW_FILE)
	    call obslog (obs, "SPECTOOL", "latitude longitude altitude", fd)
	    call close (fd)

	    if (obs != NULL)
		call obsclose (obs)
	} then {
	    SPT_ZHELIO(rv) = INDEFD
	    SPT_HJD(rv) = INDEFD
	    if (obs != NULL)
		call obsclose (obs)
	    call sprintf (SPT_RVOBS(rv), SPT_OBSLEN,
		"# Cannot compute heliocentric velocity\n")
	    call error (1, "Cannot compute heliocentric velocity")
	}
end


# SPT_RVLOG -- Velocity log

procedure spt_rvlog (spt, reg, lids, rv)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register
pointer	lids			#I Features
pointer	rv			#I RV

int	i, fd, nrms
double	w1, w2, w3, z, zrms, zerr, zhelio, werr, rms, v, verr, vhelio
pointer	sp, time, str, gp, sh, un1, un2, lab

int	stropen()
errchk	stropen

begin
	gp = SPT_GP(spt)
	if (rv == NULL) {
	    call gmsg (gp, "rvvel", "vobs \"\"")
	    call gmsg (gp, "rvvel", "zobs \"\"")
	    call gmsg (gp, "rvvel", "vhelio \"\"")
	    call gmsg (gp, "rvvel", "zhelio \"\"")
	    call gmsg (gp, "rvresults", "")
	    return
	}

	z = SPT_REDSHIFT(rv)
	zhelio = SPT_ZHELIO(rv)
	v = SPT_REDSHIFT(rv)
	if (!IS_INDEFD(v))
	    v = v * VLIGHT
	if (!IS_INDEFD(zhelio))
	    vhelio = SPT_ZHELIO(rv) * VLIGHT
	else
	    vhelio = 0.

	if (IS_INDEFD(z)) {
	    call gmsg (gp, "rvvel", "vobs \"\"")
	    call gmsg (gp, "rvvel", "zobs \"\"")
	    call gmsg (gp, "rvvel", "vhelio \"\"")
	    call gmsg (gp, "rvvel", "zhelio \"\"")
	    call gmsg (gp, "rvresults", "")
	    return
	}

	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "vobs %.5g")
	    call pargd (v)
	call gmsg (gp, "rvvel", SPT_STRING(spt))
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "zobs %.5g")
	    call pargd (z)
	call gmsg (gp, "rvvel", SPT_STRING(spt))
	if (IS_INDEFD(zhelio)) {
	    call gmsg (gp, "rvvel", "vhelio \"\"")
	    call gmsg (gp, "rvvel", "zhelio \"\"")
	} else {
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "vhelio %.5g")
		call pargd (v + vhelio)
	    call gmsg (gp, "rvvel", SPT_STRING(spt))
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "zhelio %.5g")
		call pargd (z + zhelio)
	    call gmsg (gp, "rvvel", SPT_STRING(spt))
	}

	if (SPT_RVN(rv) == 0 || reg == NULL || lids == NULL) {
	    call gmsg (gp, "rvresults", "")
	    return
	}

	call smark (sp)
	call salloc (time, SZ_TIME, TY_CHAR)
	call salloc (str, (10+SPT_RVN(rv)) * SZ_LINE, TY_CHAR)
	fd = stropen (Memc[str], (10 + SPT_RVN(rv)) * SZ_LINE, WRITE_ONLY)

	call fprintf (fd, "%s\n")
	    call pargstr (SPT_RVOBS(rv))

	sh = REG_SH(reg)
	un1 = UN(sh)
	un2 = RV_UN(rv)

	call fprintf (fd, "# Features identified in image %s%s: %s\n")
	    call pargstr (IMNAME(sh))
	    call pargstr (IMSEC(sh))
	    call pargstr (TITLE(sh))

	call fprintf (fd, "# %8s %8s %10s %10s %10s %10s %s\n")
	    call pargstr ("Observed")
	    call pargstr ("Rest")
	    call pargstr ("Reference")
	    call pargstr ("Residual")
	    call pargstr ("Velocity")
	    call pargstr ("Residual")
	    call pargstr ("Label")

	zrms = 0.
	rms = 0.
	nrms = 0
	do i = 1, LID_NLINES(lids) {
	    lab = LID_LINES(lids,i)
	    if (lab == NULL)
		next
	    if (IS_INDEFD(LID_REF(lab)))
		next

	    call un_ctrand (un1, un2, LID_X(lab), w1, 1)
	    call un_ctrand (un1, un2, LID_REF(lab), w2, 1)
	    call un_ctrand (un2, un1, w1/(1+z), w3, 1)
	    zerr = (w1 - w2) / w2
	    verr = (w1 - w2) / w2 * VLIGHT
	    werr = w3 - LID_REF(lab)
	    zrms = zrms + (zerr - z) ** 2
	    rms = rms + werr ** 2
	    nrms = nrms + 1

	    call fprintf (fd,
		"%10.8g %10.8g %10.8g %10.4g %10.8g %10.4g %s\n")
		call pargd (LID_X(lab))
		call pargd (w3)
		call pargd (LID_REF(lab))
		call pargd (werr)
		call pargd (verr + vhelio)
		call pargd (verr - v)
		call pargstr (LID_LABEL(lab))
	}

	if (nrms > 1) {
	    if (zrms > 0.)
		zrms = sqrt (zrms / nrms)
	    else
		zrms = 0.
	    call fprintf (fd, "# Coordinate RMS = %0.6g\n")
		call pargd (sqrt (rms / nrms))
	    call fprintf (fd, "# Velocity RMS = %8.5g\n")
		call pargd (zrms * VLIGHT)
	}
	SPT_RMSRED(rv) = zrms

	zerr = zrms
	if (nrms > 1)
	    zerr = zerr / sqrt (nrms - 1.)
	v = z * VLIGHT
	verr = zerr * VLIGHT

	call fprintf (fd, "\n")
	if (!IS_INDEFD(zhelio)) {
	    call fprintf (fd, "# %8s %10s %10s %8s %8s %8s %7d\n")
		call pargstr ("Zobs")
		call pargstr ("Zhelio")
		call pargstr ("Error")
		call pargstr ("Vobs")
		call pargstr ("Vhelio")
		call pargstr ("Error")
		call pargstr ("Lines")
	    call fprintf (fd, "# %8s %10s %10s %8s %8s %8s %7d\n")
		call pargstr ("")
		call pargstr ("")
		call pargstr ("")
		call pargstr ("km/s")
		call pargstr ("km/s")
		call pargstr ("km/s")
		call pargstr ("")
	    call fprintf (fd, "%10.5g %10.5g %10.5g %8.5g %8.5g %8.5g %7d\n")
		call pargd (z)
		call pargd (z+zhelio)
		call pargd (zerr)
		call pargd (v)
		call pargd (v+vhelio)
		call pargd (verr)
		call pargi (nrms)
	} else {
	    call fprintf (fd, "# %8s %10s %8s %8s %7d\n")
		call pargstr ("Zobs")
		call pargstr ("Error")
		call pargstr ("Vobs")
		call pargstr ("Error")
		call pargstr ("Lines")
	    call fprintf (fd, "# %8s %10s %8s %8s %7d\n")
		call pargstr ("")
		call pargstr ("")
		call pargstr ("km/s")
		call pargstr ("km/s")
		call pargstr ("")
	    call fprintf (fd, "%10.5g %10.5g %8.5g %8.5g %7d\n")
		call pargd (z)
		call pargd (zerr)
		call pargd (v)
		call pargd (verr)
		call pargi (nrms)
	}

#	call fprintf (fd, "\n")
#	call fprintf (fd, "# %s %3d : Zobs     = %10.5g,    ")
#	    call pargstr (IMNAME(sh))
#	    call pargi (AP(sh))
#	    call pargd (z)
#	call fprintf (fd, "Mean err = %10.5g,    Lines = %3d\n")
#	    call pargd (zerr)
#	    call pargi (nrms)
#	call fprintf (fd, "# %s %3d : Vobs     = %8.5g km/s, ")
#	    call pargstr (IMNAME(sh))
#	    call pargi (AP(sh))
#	    call pargd (v)
#	call fprintf (fd, "Mean err = %8.5g km/s, Lines = %3d\n")
#	    call pargd (verr)
#	    call pargi (nrms)
#	if (!IS_INDEFD(zhelio)) {
#	    call fprintf (fd, "# %s %3d : Zhelio   = %10.5g,    ")
#		call pargstr (IMNAME(sh))
#		call pargi (AP(sh))
#		call pargd (z + zhelio)
#	    call fprintf (fd, "Mean err = %8.5g km/s, Lines = %3d\n")
#		call pargd (zerr)
#		call pargi (nrms)
#	    call fprintf (fd, "# %s %3d : Vhelio   = %8.5g km/s, ")
#		call pargstr (IMNAME(sh))
#		call pargi (AP(sh))
#		call pargd (v + vhelio)
#	    call fprintf (fd, "Mean err = %8.5g km/s, Lines = %3d\n")
#		call pargd (verr)
#		call pargi (nrms)
##	    call fprintf (fd, "%s %3d : HJD      = %g\n")
##		call pargstr (IMNAME(sh))
##		call pargi (AP(sh))
##		call pargd (hjd)
#	}
	call fprintf (fd, "\n")
	call close (fd)

	call gmsg (gp, "rvresults", Memc[str])
	call spt_log (spt, reg, "add", Memc[str])
	call sfree (sp)
end
