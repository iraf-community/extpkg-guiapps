include <gset.h>
include <gim.h>
include "../lib/impars.h"
include "../lib/objects.h"
include "../lib/center.h"

# XP_CMARK -- Mark the computed center and shift on the image display with a
# vector and a cross.

procedure xp_cmark (gd, xp, raster, wcs)

pointer	gd		#I the graphics descriptor
pointer	xp		#I the main xapphot descriptor
int	raster		#I the raster coordinate system
int	wcs		#I the current wcs

int	xp_stati()

begin
	if (gd == NULL)
	    return
	if (xp_stati (xp, CTRMARK) == NO)
	    return

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Do the plotting.
	call xp_ccmark (gd, xp)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_CCMARK -- Do the actual marking of the center position.

procedure xp_ccmark (gd, xp)

pointer	gd		#I the graphics descriptor
pointer	xp		#I the main xapphot descriptor

int	omarktype, ocolor, markchar
real	mksize
int	gstati(), xp_stati()
real	xp_statr()

begin
	if (IS_INDEFR(xp_statr(xp, XCENTER)) || IS_INDEFR(xp_statr(xp,YCENTER)))
	    return

	# Save the mark type.
	omarktype = gstati (gd, G_PMLTYPE)
	ocolor = gstati (gd, G_PLCOLOR)

	# Set the mark character.
	switch (xp_stati (xp, CCHARMARK)) {
	case XP_CMARK_POINT:
	    markchar = GM_POINT
	case XP_CMARK_BOX:
	    markchar = GM_BOX
	case XP_CMARK_CROSS:
	    markchar = GM_CROSS
	case XP_CMARK_PLUS:
	    markchar = GM_PLUS
	case XP_CMARK_CIRCLE:
	    markchar = GM_CIRCLE
	case XP_CMARK_DIAMOND:
	    markchar = GM_DIAMOND
	default:
	    markchar = GM_PLUS
	}

	# Set the color.
	switch (xp_stati (xp, CCOLORMARK)) {
	case XP_CMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_CMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_CMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_CMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)

	# Set the marker size.
	if (IS_INDEFR(xp_statr(xp, CSIZEMARK)))
	    mksize = - 2.0 * xp_statr (xp, ISCALE) * xp_statr (xp, CRADIUS)
	else
	    mksize = - 2.0 * xp_statr (xp, ISCALE) * xp_statr (xp, CSIZEMARK)

	call gmark (gd, xp_statr (xp, XCENTER), xp_statr (xp, YCENTER),
	    markchar, mksize, mksize)

	# Restore the mark type.
	call gseti (gd, G_PMLTYPE, omarktype)
	call gseti (gd, G_PLCOLOR, ocolor)
end



# XP_OCMARK -- Mark the centered object on the image display.

procedure xp_ocmark (gd, xp, symbol, raster, wcs)

pointer	gd		#I the graphics descriptor
pointer	xp		#I the main xapphot descriptor
int	symbol		#I the current object symbol
int	raster		#I the raster coordinate system
int	wcs		#I the current wcs

pointer	sp, str, opsymbol
int	xp_stati()
pointer	stfind(), xp_statp()

begin
	if (gd == NULL)
	    return

	if (xp_stati (xp, CTRMARK) == NO)
	    return

	if (symbol == NULL)
	    return

	if (XP_ONPOLYGON(symbol) > 0) {
	    call smark (sp)
	    call salloc (str, SZ_FNAME, TY_CHAR)
	    call sprintf (Memc[str], SZ_FNAME, "polygonlist%d")
                call pargi (XP_ONPOLYGON(symbol))
            opsymbol = stfind (xp_statp(xp, POLYGONLIST), Memc[str])
	    call sfree (sp)
	} else
	    opsymbol = NULL

	# The coordinate system of the raster to be marked.
	call gseti (gd, G_WCS, wcs)
	call gim_setraster (gd, raster)

	# Do the plotting.
	call xp_occmark (gd, xp, symbol, opsymbol)

	# Restore the default cursor mode coordinate system.
	call gim_setraster (gd, 0)
end


# XP_OCCMARK -- Do the actual marking of the center position.

procedure xp_occmark (gd, xp, symbol, psymbol)

pointer	gd		#I the graphics descriptor
pointer	xp		#I the main xapphot descriptor
int	symbol		#I the current object symbol
int	psymbol		#I the current object polygon symbol

int	omarktype, ocolor, markchar
real	mksize
int	gstati(), xp_stati()
real	xp_statr()

begin
	if (IS_INDEFR(xp_statr(xp, XCENTER)) || IS_INDEFR(xp_statr(xp,YCENTER)))
	    return

	# Save the mark type.
	omarktype = gstati (gd, G_PMLTYPE)
	ocolor = gstati (gd, G_PLCOLOR)

	# Set the mark character.
	switch (xp_stati (xp, CCHARMARK)) {
	case XP_CMARK_POINT:
	    markchar = GM_POINT
	case XP_CMARK_BOX:
	    markchar = GM_BOX
	case XP_CMARK_CROSS:
	    markchar = GM_CROSS
	case XP_CMARK_PLUS:
	    markchar = GM_PLUS
	case XP_CMARK_CIRCLE:
	    markchar = GM_CIRCLE
	case XP_CMARK_DIAMOND:
	    markchar = GM_DIAMOND
	default:
	    markchar = GM_PLUS
	}

	# Set the color.
	switch (xp_stati (xp, CCOLORMARK)) {
	case XP_CMARK_RED:
	    call gseti (gd, G_PLCOLOR, RED)
	case XP_CMARK_BLUE:
	    call gseti (gd, G_PLCOLOR, BLUE)
	case XP_CMARK_GREEN:
	    call gseti (gd, G_PLCOLOR, GREEN)
	case XP_CMARK_YELLOW:
	    call gseti (gd, G_PLCOLOR, YELLOW)
	default:
	    call gseti (gd, G_PLCOLOR, RED)
	}

	# Set the polymarker type.
	call gseti (gd, G_PMLTYPE, GL_SOLID)

	# Set the marker size.
	if (IS_INDEFR(xp_statr(xp, CSIZEMARK)))
	    mksize = - 2.0 * xp_statr (xp, ISCALE) * xp_statr (xp, CRADIUS)
	else
	    mksize = - 2.0 * xp_statr (xp, ISCALE) * xp_statr (xp, CSIZEMARK)

	call gmark (gd, xp_statr (xp, XCENTER), xp_statr (xp, YCENTER),
	    markchar, mksize, mksize)
	call xp_omkshape (gd, symbol, psymbol, NULL, xp_statr (xp, XSHIFT),
	    xp_statr (xp, YSHIFT), xp_statr (xp, ISCALE), YES, NO, mksize)

	# Restore the mark type.
	call gseti (gd, G_PMLTYPE, omarktype)
	call gseti (gd, G_PLCOLOR, ocolor)
end
