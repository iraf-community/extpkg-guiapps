include "../lib/xphot.h"

# XP_EPSET -- Edit a named parameter set.

procedure xp_epset (xp, rootpset, pset)

pointer	xp			#I pointer to the xapphot structure
char	rootpset[ARB]		#I the root pset name
int	pset			#I the pset code

pointer	sp, psetname, pp
pointer	clopset()

begin
	# Allocate some working space.
	call smark (sp)
	call salloc (psetname, SZ_FNAME, TY_CHAR)

	# Create the root pset name
	call sprintf (Memc[psetname], SZ_FNAME, "xapphot$src/%s.par")
	    call pargstr (rootpset)

	# Create the dummy pset.
	call clcmdw ("unlearn dummypars")
	call fcopy (Memc[psetname], "uparm$xatdummys.par")

	# Copy the current memory state into the dummy pset
	switch (pset) {
	case PSET_IMPARS:
            call xp_pipset ("dummypars", xp)
	case PSET_DISPARS:
            call xp_pdpset ("dummypars", xp)
	case PSET_FINDPARS:
            call xp_pfpset ("dummypars", xp)
	case PSET_OMARKPARS:
            call xp_popset ("dummypars", xp)
	case PSET_CENPARS:
            call xp_pcpset ("dummypars", xp)
	case PSET_SKYPARS:
            call xp_pspset ("dummypars", xp)
	case PSET_PHOTPARS:
            call xp_pppset ("dummypars", xp)
	case PSET_EPLOTPARS:
            call xp_pepset ("dummypars", xp)
	case PSET_APLOTPARS:
            call xp_papset ("dummypars", xp)
	default:
	    ;
	}

	# Edit the new pset.
	pp = clopset ("dummypars")
	call clepset (pp)
	call clcpset (pp)
	#call clcmdw ("eparam dummypars")

	# Read the new pset parameters into memory.
	switch (pset) {
	case PSET_IMPARS:
            call xp_gipset ("dummypars", xp)
	case PSET_DISPARS:
	    call xp_gdpset ("dummypars", xp)
	case PSET_FINDPARS:
	    call xp_gfpset ("dummypars", xp)
	case PSET_OMARKPARS:
            call xp_gopset ("dummypars", xp)
	case PSET_CENPARS:
            call xp_gcpset ("dummypars", xp)
	case PSET_SKYPARS:
            call xp_gspset ("dummypars", xp)
	case PSET_PHOTPARS:
            call xp_gppset ("dummypars", xp)
	case PSET_EPLOTPARS:
            call xp_gepset ("dummypars", xp)
	case PSET_APLOTPARS:
            call xp_gapset ("dummypars", xp)
	default:
	    ;
	}

	# Delete the temporary pset.
	call clcmdw ("unlearn dummypars")

	call sfree (sp)
end
