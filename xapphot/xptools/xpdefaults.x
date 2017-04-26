include "../lib/objects.h"

# XP_DDEFAULTS -- Set the display parameters to their default values.

procedure xp_ddefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_dfree (xp)
	call xp_dinit (xp)
end


# XP_IDEFAULTS -- Set the image parameters to their default values.

procedure xp_idefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_ifree (xp)
	call xp_iinit (xp)
end


# XP_ODEFAULTS -- Set the objects parameters to their default values.

procedure xp_odefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

pointer	objlist, polylist
pointer	xp_statp()

begin
	objlist = xp_statp (xp, OBJLIST)
	polylist = xp_statp (xp, POLYGONLIST)
	call xp_setp (xp, OBJLIST, NULL)
	call xp_setp (xp, POLYGONLIST, NULL)
	call xp_ofree (xp)
	call xp_oinit (xp)
	call xp_setp (xp, OBJLIST, objlist)
	call xp_setp (xp, POLYGONLIST, polylist)
end


# XP_FDEFAULTS -- Set the object detection parameters to their default values.

procedure xp_fdefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_ffree (xp)
	call xp_finit (xp)
end


# XP_CDEFAULTS -- Set the centering parameters to their default values.

procedure xp_cdefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_cfree (xp)
	call xp_cinit (xp)
end


# XP_SDEFAULTS -- Set the sky fitting parameter to their default values.

procedure xp_sdefaults (xp)

pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_sfree (xp)
	call xp_sinit (xp)
end


# XP_PDEFAULTS -- Set the sky fitting parameter to their default values.

procedure xp_pdefaults (xp)

pointer	xp			# pointer to the main xapphot structure

begin
	call xp_pfree (xp)
	call xp_pinit (xp)
end


# XP_EDEFAULTS -- Set the contour plotting parameters to their default
# values.

procedure xp_edefaults (xp)

pointer	xp			# pointer to the main xapphot structure

begin
	call xp_efree (xp)
	call xp_einit (xp)
end


# XP_ADEFAULTS -- Set the surface plotting parameters to their default
# values.

procedure xp_adefaults (xp)

pointer	xp			# pointer to the main xapphot structure

begin
	call xp_afree (xp)
	call xp_ainit (xp)
end
