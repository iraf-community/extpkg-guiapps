include "../lib/xphot.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

# XP_GCOLON -- Execute the geometry definition commands

int procedure xp_gcolon (gd, xp, cmdstr)

pointer	gd			#I pointer to the graphics stream
pointer	xp			#I pointer to the main xapphot structure
char	cmdstr[ARB]		#I the input command string

int	ncmd, update
pointer	sp, cmd, str, pstatus
int	strdic(), xp_ggeom()
pointer	xp_statp()

begin
	# Get the command.
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	call sscan (cmdstr)
	call gargwrd (Memc[cmd], SZ_LINE)
	if (Memc[cmd] == EOS) {
	    call sfree (sp)
	    return (NO)
	}
	pstatus = xp_statp(xp, PSTATUS)

	# Process the command.
	ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, GEOCMDS)
	switch (ncmd) {

	case GCMD_SPGEOMETRY:
	    call gargstr (Memc[cmd], SZ_LINE)
	    update = xp_ggeom (xp, Memc[cmd])
	    if (update == YES) {
		NEWSBUF(pstatus) = YES
		NEWSKY(pstatus) = YES
		NEWMBUF(pstatus) = YES
		NEWMAG(pstatus) = YES
	    }

	default:
	    update = NO
	}

	call sfree (sp)

	return (update)
end


# XP_GGEOM -- Procedure to decode the geometry of the photometry and
# sky apertures. Cannot yet deal with polygons

int procedure xp_ggeom (xp, cmdstr)

pointer	xp			#I the main xapphot descriptor
char	cmdstr[ARB]		#I the input command string

char	dummychar
int	i, stat, update, nover, nsver, nver
pointer	sp, ageom, apertures, sgeom, oxver, oyver, sxver, syver
real	aratio, atheta, srannulus, swannulus, sratio, stheta
bool	streq()
int	nscan(), strdic()
pointer	xp_statp()
real	xp_statr()

begin
	# Allocate temporary space.
	call smark (sp)
	call salloc (ageom, SZ_FNAME, TY_CHAR)
	call salloc (sgeom, SZ_FNAME, TY_CHAR)
	call salloc (apertures, SZ_LINE, TY_CHAR)

	# Print the current object and sky geometry.
	if (cmdstr[1] == EOS) {

	    call xp_stats (xp, PAPSTRING, Memc[apertures], SZ_FNAME)
	    call xp_stats (xp, PGEOSTRING, Memc[ageom], SZ_FNAME)
	    call xp_stats (xp, SGEOSTRING, Memc[sgeom], SZ_FNAME)
	    call printf ("%s %s %0.2f %0.1f %s %0.2f %0.2f %0.2f %0.1f\n")
		call pargstr (Memc[ageom])
		call pargstr (Memc[apertures])
		call pargr (xp_statr (xp, PAXRATIO))
		call pargr (xp_statr (xp, PPOSANGLE))
		call pargstr (Memc[sgeom])
		call pargr (xp_statr (xp, SRANNULUS))
		call pargr (xp_statr (xp, SWANNULUS))
		call pargr (xp_statr (xp, SAXRATIO))
		call pargr (xp_statr (xp, SPOSANGLE))
	    update = NO

	} else {

	    # Scan the geometry string.
	    call sscan (cmdstr)

	    # Decode the object geoemtry.
	    call gargwrd (Memc[ageom], SZ_FNAME)
	    call gargwrd (Memc[apertures], SZ_LINE)
	    if (streq (Memc[ageom], "polygon") ) {
		aratio = 1.0
		atheta = 0.0
		call gargi (nover)
		nver = 0
		oxver = xp_statp(xp,PUXVER)
		oyver = xp_statp(xp,PUYVER)
		do i = 1, nover {
		    if (i > MAX_NAP_VERTICES)
			break
		    nver = nver + 1
		    call gargc (dummychar)
		    call gargr (Memr[oxver+nver-1])
		    call gargr (Memr[oyver+nver-1])
		    call gargc (dummychar)
		}
		Memr[oxver+nver] = Memr[oxver]
		Memr[oyver+nver] = Memr[oyver]
	    } else {
	        call gargr (aratio)
	        call gargr (atheta)
		nover = 0
	    }
	    call xp_seti (xp, PUNVER, nover)

	    # Decode the  sky geometry.
	    call gargwrd (Memc[sgeom], SZ_FNAME)
	    call gargr (srannulus)
	    call gargr (swannulus)
	    if (streq (Memc[ageom], "polygon") ) {
		sratio = 1.0
		stheta = 0.0
		call gargi (nsver)
		nver = 0
		sxver = xp_statp(xp,SUXVER)
		syver = xp_statp(xp,SUYVER)
		do i = 1, nsver {
		    if (i > MAX_NAP_VERTICES)
			break
		    nver = nver + 1
		    call gargc (dummychar)
		    call gargr (Memr[sxver+nver-1])
		    call gargr (Memr[syver+nver-1])
		    call gargc (dummychar)
		}
		Memr[sxver+nver] = Memr[sxver]
		Memr[syver+nver] = Memr[syver]
	    } else {
	        call gargr (sratio)
	        call gargr (stheta)
		nsver = 0
	    }
	    call xp_seti (xp, SUNVER, nsver)

	    # Set the new values.
	    if (nscan() >= 9) {
 		stat = strdic (Memc[ageom], Memc[ageom], SZ_FNAME, AGEOMS)
                if (stat > 0) {
                    call xp_seti (xp, PGEOMETRY, stat)
                    call xp_sets (xp, PGEOSTRING, Memc[ageom])
                }
		call xp_sets (xp, PAPSTRING, Memc[apertures])
		call xp_setr (xp, PAXRATIO, aratio)
		call xp_setr (xp, PPOSANGLE, atheta)
 		stat = strdic (Memc[sgeom], Memc[sgeom], SZ_FNAME, SGEOMS)
                if (stat > 0) {
                    call xp_seti (xp, SGEOMETRY, stat)
                    call xp_sets (xp, SGEOSTRING, Memc[sgeom])
                }
		call xp_setr (xp, SRANNULUS, srannulus)
		call xp_setr (xp, SWANNULUS, swannulus)
		call xp_setr (xp, SAXRATIO, sratio)
		call xp_setr (xp, SPOSANGLE, stheta)
		update = YES
	    }

	}

	call sfree (sp)

	return (update)
end
