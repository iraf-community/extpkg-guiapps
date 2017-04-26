include "../lib/xphot.h"

# XP_OSEQLIST -- Open the sequence list.

procedure xp_oseqlist (xp)

pointer xp		#I pointer to the main xapphot descriptor

pointer	lptr
pointer	xp_statp(), stopen()

begin
	if (xp_statp(xp, SEQNOLIST) != NULL)
	    call stclose (xp_statp(xp, SEQNOLIST))
	lptr = stopen ("seqnosymlist", 2 * DEF_LEN_SEQNOLIST,
	    DEF_LEN_SEQNOLIST, 10 * DEF_LEN_SEQNOLIST)
	call xp_setp (xp, SEQNOLIST, lptr)
end


# XP_CSEQLIST -- Close the sequence list.

procedure xp_cseqlist (xp)

pointer xp		#I pointer to the main xapphot descriptor

pointer	xp_statp()

begin
	if (xp_statp(xp, SEQNOLIST) != NULL)
	    call stclose (xp_statp(xp, SEQNOLIST))
	call xp_setp (xp, SEQNOLIST, NULL)
end
