# XP_POBJLIST -- Page the current object list.

procedure xp_pobjlist (gd, xp)

pointer	gd		#I pointer to the graphics stream
pointer	xp		#I pointer to the main xapphot structure

int	tmp, nwritten
pointer	sp, tmpname
int	open(), xp_wobjects()

begin
	call smark (sp)
	call salloc (tmpname, SZ_FNAME, TY_CHAR)
	call mktemp ("tmp$ol", Memc[tmpname], SZ_FNAME)
	tmp = open (Memc[tmpname], NEW_FILE, TEXT_FILE)
	call fprintf (tmp, "Current objects list\n\n")
	nwritten = xp_wobjects (tmp, xp, NO, YES)
	call fprintf (tmp, "\n")
	call close (tmp)
	call gpagefile (gd, Memc[tmpname], "")
	call delete (Memc[tmpname])
	call sfree (sp)
end
