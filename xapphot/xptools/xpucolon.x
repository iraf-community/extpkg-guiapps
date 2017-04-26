include "../lib/xphot.h"

# XP_UCOLON -- Execute the parameter set editing commands.

int procedure xp_ucolon (gd, xp, cmdstr, cmdlist, psetlist, pset)

pointer	gd			#I pointer to the graphics stream
pointer	xp			#I pointer to the main xapphot structure
char	cmdstr[ARB]		#I the input command string
char	cmdlist[ARB]		#I the input command list
char	psetlist[ARB]		#I the input pset string
int	pset			#O the pset to be edited

bool	bval
int	ncmd, update
pointer	sp, cmd, str
int	strdic(), nscan()

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

	# Initialize the pset id.
	pset = 0

	# Process the command.
	ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, cmdlist)
	switch (ncmd) {

	case UCMD_UNLEARN:
	    update = NO
	    call gargwrd (Memc[cmd], SZ_LINE)
	    ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, psetlist)
	    switch (ncmd) {
	    case PSET_IMPARS:
		call xp_idefaults (xp)
		pset = PSET_IMPARS
		update = YES
	    case PSET_DISPARS:
		call xp_ddefaults (xp)
		pset = PSET_DISPARS
		update = YES
	    case PSET_FINDPARS:
		call xp_fdefaults (xp)
		pset = PSET_FINDPARS
		update = YES
	    case PSET_OMARKPARS:
		call xp_odefaults (xp)
		pset = PSET_OMARKPARS
		update = YES
	    case PSET_CENPARS:
		call xp_cdefaults (xp)
		pset = PSET_CENPARS
		update = YES
	    case PSET_SKYPARS:
		call xp_sdefaults (xp)
		pset = PSET_SKYPARS
		update = YES
	    case PSET_PHOTPARS:
		call xp_pdefaults (xp)
		pset = PSET_PHOTPARS
		update = YES
	    case PSET_EPLOTPARS:
		call xp_edefaults (xp)
		pset = PSET_EPLOTPARS
		update = YES
	    case PSET_APLOTPARS:
		call xp_adefaults (xp)
		pset = PSET_APLOTPARS
		update = YES
	    default:
		pset = 0
		update = NO
	    }

	case UCMD_LPAR:
	    update = NO
	    call gargwrd (Memc[cmd], SZ_LINE)
	    ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, psetlist)
	    if (ncmd > 0)
		call gdeactivate (gd, 0)
	    switch (ncmd) {
	    case PSET_IMPARS:
		call xp_lipars (xp)
		pset = PSET_IMPARS
	    case PSET_DISPARS:
		call xp_ldpars (xp)
		pset = PSET_DISPARS
	    case PSET_FINDPARS:
		call xp_lfpars(xp)
		pset = PSET_FINDPARS
	    case PSET_OMARKPARS:
		call xp_lopars(xp)
		pset = PSET_OMARKPARS
	    case PSET_CENPARS:
		call xp_lcpars (xp)
		pset = PSET_CENPARS
	    case PSET_SKYPARS:
		call xp_lspars (xp)
		pset = PSET_SKYPARS
	    case PSET_PHOTPARS:
		call xp_lppars (xp)
		pset = PSET_PHOTPARS
	    case PSET_EPLOTPARS:
		call xp_lepars (xp)
		pset = PSET_EPLOTPARS
	    case PSET_APLOTPARS:
		call xp_lapars (xp)
		pset = PSET_APLOTPARS
	    default:
		pset = 0
	    }
	    if (ncmd > 0)
		call greactivate (gd, 0)

	case UCMD_EPAR:
	    update = NO
	    call gargwrd (Memc[cmd], SZ_LINE)
	    ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, psetlist)
	    if (ncmd > 0)
		call gdeactivate (gd, 0)
	    switch (ncmd) {
	    case PSET_IMPARS:
		call xp_epset (xp, "impars", PSET_IMPARS)
		update = YES
		pset = PSET_IMPARS
	    case PSET_DISPARS:
		call xp_epset (xp, "dispars", PSET_DISPARS)
		update = YES
		pset = PSET_DISPARS
	    case PSET_FINDPARS:
		call xp_epset (xp, "findpars", PSET_FINDPARS)
		update = YES
		pset = PSET_FINDPARS
	    case PSET_OMARKPARS:
		call xp_epset (xp, "omarkpars", PSET_OMARKPARS)
		update = YES
		pset = PSET_OMARKPARS
	    case PSET_CENPARS:
		call xp_epset (xp, "cenpars", PSET_CENPARS)
		update = YES
		pset = PSET_CENPARS
	    case PSET_SKYPARS:
		call xp_epset (xp, "skypars", PSET_SKYPARS)
		update = YES
		pset = PSET_SKYPARS
	    case PSET_PHOTPARS:
		call xp_epset (xp, "photpars", PSET_PHOTPARS)
		update = YES
		pset = PSET_PHOTPARS
	    case PSET_EPLOTPARS:
		call xp_epset (xp, "cplotpars", PSET_EPLOTPARS)
		update = YES
		pset = PSET_EPLOTPARS
	    case PSET_APLOTPARS:
		call xp_epset (xp, "splotpars", PSET_APLOTPARS)
		update = YES
		pset = PSET_APLOTPARS
	    default:
		pset = 0
	    }
	    if (ncmd > 0)
		call greactivate (gd, 0)

	case UCMD_SAVE:
	    call gargwrd (Memc[cmd], SZ_LINE)
	    call gargb (bval)
	    if (nscan () == 3) {
	        if (bval)
		    update = YES
	        else
		    update = NO
	    } else
		update = YES
	    ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, APSETS)
	    switch (ncmd) {
	    case PSET_IMPARS:
	        pset = PSET_IMPARS
	    case PSET_DISPARS:
	        pset = PSET_DISPARS
	    case PSET_FINDPARS:
		pset = PSET_FINDPARS
	    case PSET_OMARKPARS:
		pset = PSET_OMARKPARS
	    case PSET_CENPARS:
		pset = PSET_CENPARS
	    case PSET_SKYPARS:
		pset = PSET_SKYPARS
	    case PSET_PHOTPARS:
		pset = PSET_PHOTPARS
	    case PSET_EPLOTPARS:
		pset = PSET_EPLOTPARS
	    case PSET_APLOTPARS:
		pset = PSET_APLOTPARS
	    default:
	        pset = 0
		update = NO
	    }

	case UCMD_UPDATE:
	    update = NO
	    call gargwrd (Memc[cmd], SZ_LINE)
	    ncmd = strdic (Memc[cmd], Memc[cmd], SZ_LINE, psetlist)
	    switch (ncmd) {
	    case PSET_IMPARS:
		call xp_pipset ("impars", xp)
		pset = PSET_IMPARS
	    case PSET_DISPARS:
		call xp_pdpset ("dispars", xp)
		pset = PSET_DISPARS
	    case PSET_FINDPARS:
		call xp_pfpset ("findpars", xp)
		pset = PSET_FINDPARS
	    case PSET_OMARKPARS:
		call xp_popset ("omarkpars", xp)
		pset = PSET_OMARKPARS
	    case PSET_CENPARS:
		call xp_pcpset ("cenpars", xp)
		pset = PSET_CENPARS
	    case PSET_SKYPARS:
		call xp_pspset ("skypars", xp)
		pset = PSET_SKYPARS
	    case PSET_PHOTPARS:
		call xp_pppset ("photpars", xp)
		pset = PSET_PHOTPARS
	    case PSET_EPLOTPARS:
		call xp_pepset ("cplotpars", xp)
		pset = PSET_EPLOTPARS
	    case PSET_APLOTPARS:
		call xp_papset ("splotpars", xp)
		pset = PSET_APLOTPARS
	    default:
		pset = 0
	    }

	default:
	    pset = 0
	    update = NO
	}

	call sfree (sp)

	return (update)
end
