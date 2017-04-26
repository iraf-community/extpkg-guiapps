# XP_REMAP -- Remap the specified raster.

procedure xp_remap (gd, mapping, refresh)

pointer	gd			#I the pointer to the graphics stream
int	mapping			#I the the mapping to be reset
int	refresh			#I refresh the screen

int	rop, src, st, sx, sy, sw, sh, dst, dt, dx, dy, dw, dh
int	gim_getmapping()

begin
	#call gflush (gd)
	#call gcancel (gd)

	# this is a null operation
	#if (gim_getmapping (gd, mapping, rop, src, st, sx, sy, sw, sh, dst, dt,
	    #dx, dy, dw, dh) == NO)
	    #;
	#call gim_refreshpix (gd, mapping, dt, dx, dy, dw, dh)
	    #call printf ("mapping inactive\n")
	#else
	    #call printf ("mapping active\n")
	#call gim_setmapping (gd, mapping, rop, src, st, sx, sy, sw, sh,
	    #dst, dt, dx, dy, dw, dh)

	# Note that this call does refresh the screen, erasing any graphics
	# that are present (do not actually want this).
	#call gim_refreshmapping (gd, mapping)

	#call gim_refreshmapping (gd, 1)
end
