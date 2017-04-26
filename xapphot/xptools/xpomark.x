include <gset.h>
include <gim.h>
include "../lib/objects.h"

# XP_OMKSHAPE -- Mark the object apertures on the image display.

procedure xp_omkshape (gd, symbol, opsymbol, spsymbol, xshift, yshift, scale,
	plot_object, plot_sky, def_size)

pointer	gd		#I the pointer to the graphics stream
pointer	symbol		#I the pointer to object in object symbol table 
pointer	opsymbol	#I the pointer to the object polygon
pointer	spsymbol	#I the pointer to the sky polygon
real	xshift, yshift	#I the x and y shift of the object if any
real	scale		#I the image scale factor
int	plot_object	#I plot the object region ?
int	plot_sky	#I plot the sky region ?
real	def_size	#I the default marker object size

int	i, naperts, nover, nsver
pointer	sp, aperts, txver, tyver
real	x, y, xobject, yobject, rapert, ratio, theta
bool	streq()
int	xp_decaperts()
#bool	fp_equalr()

begin
	if (gd == NULL)
	    return
	if (symbol == NULL)
	    return

	call smark (sp)
	call salloc (aperts, MAX_NOBJ_APERTURES, TY_REAL)
	txver = NULL
	tyver = NULL

	x = XP_OXINIT(symbol) + xshift
	y = XP_OYINIT(symbol) + yshift
	ratio = XP_OAXRATIO(symbol)
	theta = XP_OPOSANG(symbol)
	if (streq (XP_OAPERTURES(symbol), "INDEF")) {
	    Memr[aperts] = 0.0
	    naperts = 1
	} else
	    naperts = xp_decaperts (XP_OAPERTURES(symbol), Memr[aperts],
	        MAX_NOBJ_APERTURES)

	if (plot_object == YES) {

	    switch (XP_OGEOMETRY(symbol)) {

	    case XP_OCIRCLE:
	        do i = naperts, naperts {
		    rapert = scale * Memr[aperts+i-1]
	            call gmark (gd, x, y, GM_CIRCLE, -2.0 * rapert,
		        -2.0 * rapert)
		    #call xp_emark (gd, x, y, rapert, 1.0, 0.0)
	        }

	    case XP_OELLIPSE:
		if (! IS_INDEFR(ratio) && ! IS_INDEFR(theta)) {
	            do i = naperts, naperts {
		        rapert = scale * Memr[aperts+i-1]
		        call xp_emark (gd, x, y, rapert, ratio, theta)
		    }
		}

	    case XP_ORECTANGLE:
		if (! IS_INDEFR(ratio) && ! IS_INDEFR(theta)) {
	            do i = naperts, naperts {
		        rapert = scale * Memr[aperts+i-1]
		        call xp_rmark (gd, x, y, rapert, ratio, theta)
	            }
		}

	    case XP_OPOLYGON:
	        do i = naperts, naperts {
		    rapert = scale * Memr[aperts+i-1]
		    nover = XP_ONVERTICES(opsymbol)
	            call malloc (txver, nover, TY_REAL)
	    	    call malloc (tyver, nover, TY_REAL)
		    if (rapert <= 0.0) {
			call aaddkr (XP_XVERTICES(opsymbol),
			    XP_OXSHIFT(symbol) + xshift, Memr[txver], nover)
			call aaddkr (XP_YVERTICES(opsymbol),
			    XP_OYSHIFT(symbol) + yshift, Memr[tyver], nover)
		        call xp_pmark (gd, Memr[txver], Memr[tyver], nover)
		    } else {
		        call xp_pyexpand (XP_XVERTICES(opsymbol),
			    XP_YVERTICES(opsymbol), Memr[txver], Memr[tyver],
			    nover,  rapert)
			call aaddkr (Memr[txver], XP_OXSHIFT(symbol) + xshift,
			    Memr[txver], nover)
			call aaddkr (Memr[tyver], XP_OYSHIFT(symbol) + yshift,
			    Memr[tyver], nover)
		        call xp_pmark (gd, Memr[txver], Memr[tyver], nover)
		    }
	        }

	    default:
	        call gmark (gd, x, y, GM_PLUS, def_size, def_size)
	    }
	}

	xobject = x
	if (! IS_INDEFR(XP_OSXINIT(symbol)))
	    x = XP_OSXINIT(symbol)
	yobject = y
	if (! IS_INDEFR(XP_OSYINIT(symbol)))
	    y = XP_OSYINIT(symbol)
	ratio = XP_OSAXRATIO(symbol)
	theta = XP_OSPOSANG(symbol)

	if (plot_sky == YES) {

	    switch (XP_OSGEOMETRY(symbol)) {

	    case XP_OCIRCLE:
	        if (! IS_INDEFR(XP_OSRIN(symbol))) {
	            rapert = scale * XP_OSRIN(symbol)
	            call gmark (gd, x, y, GM_CIRCLE, -2.0 * rapert,
		        -2.0 * rapert)
	        }
	        if (! IS_INDEFR(XP_OSROUT(symbol))) {
	            rapert = scale * XP_OSROUT(symbol)
	            call gmark (gd, x, y, GM_CIRCLE, -2.0 * rapert,
		        -2.0 * rapert)
	        }

	    case XP_OELLIPSE:
		if (! IS_INDEFR(ratio) && ! IS_INDEFR(theta)) {
	            if (! IS_INDEFR(XP_OSRIN(symbol))) {
		        rapert = scale * XP_OSRIN(symbol)
		        call xp_emark (gd, x, y, rapert, ratio, theta)
		    }
	            if (! IS_INDEFR(XP_OSROUT(symbol))) {
		        rapert = scale * XP_OSROUT(symbol)
		        call xp_emark (gd, x, y, rapert, ratio, theta)
		    }
		}

	    case XP_ORECTANGLE:
		if (! IS_INDEFR(ratio) && ! IS_INDEFR(theta)) {
	            if (! IS_INDEFR(XP_OSRIN(symbol))) {
		        rapert = scale * XP_OSRIN(symbol)
		        call xp_rmark (gd, x, y, rapert, ratio, theta)
	            }
	            if (! IS_INDEFR(XP_OSROUT(symbol))) {
		        rapert = scale * XP_OSROUT(symbol)
		        call xp_rmark (gd, x, y, rapert, ratio, theta)
	            }
		}

	    case XP_OPOLYGON:
		if (XP_ONVERTICES(spsymbol) > 0)
		    nsver = XP_ONVERTICES(spsymbol)
		else
		    nsver = XP_SNVERTICES(spsymbol)
	        if (txver == NULL)
		    call malloc (txver, nsver, TY_REAL)
	        else
	            call realloc (txver, nsver, TY_REAL)
	        if (tyver == NULL)
		    call malloc (tyver, nsver, TY_REAL)
	        else
	            call realloc (tyver, nsver, TY_REAL)
	        if (! IS_INDEFR(XP_OSRIN(symbol)) &&
	            ! IS_INDEFR(XP_OSROUT(symbol))) {
		    if ((XP_OSRIN(symbol) + XP_OSROUT(symbol)) <= 0.0) {
		        call aaddkr (XP_XVERTICES(spsymbol),
			    XP_OSXSHIFT(symbol) + xshift, Memr[txver], nsver)
		        call aaddkr (XP_YVERTICES(spsymbol),
			    XP_OSYSHIFT(symbol) + yshift, Memr[tyver], nsver)
			call xp_pmark (gd, Memr[txver], Memr[tyver], nsver)
		    } else {
		        call xp_pyexpand (XP_XVERTICES(spsymbol),
			    XP_YVERTICES(spsymbol), Memr[txver], Memr[tyver],
			    nsver, XP_OSRIN(symbol))
			call aaddkr (Memr[txver], XP_OSXSHIFT(symbol) +
			    xshift, Memr[txver], nsver)
			call aaddkr (Memr[tyver], XP_OSYSHIFT(symbol) +
			    yshift, Memr[tyver], nsver)
                        call xp_pmark (gd, Memr[txver], Memr[tyver], nsver)
		        call xp_pyexpand (XP_XVERTICES(spsymbol),
			    XP_YVERTICES(spsymbol), Memr[txver], Memr[tyver],
			    nsver, XP_OSRIN(symbol) + XP_OSROUT(symbol))
			call aaddkr (Memr[txver], XP_OSXSHIFT(symbol) +
			    xshift, Memr[txver], nsver)
			call aaddkr (Memr[tyver], XP_OSYSHIFT(symbol) +
			    yshift, Memr[tyver], nsver)
                        call xp_pmark (gd, Memr[txver], Memr[tyver], nsver)
		    }
	        }

	    default:
		if (x != xobject || y != yobject)
	            call gmark (gd, x, y, GM_CIRCLE, def_size, def_size)
	    }
	}

	if (txver != NULL)
	    call mfree (txver, TY_REAL)
	if (tyver != NULL)
	    call mfree (tyver, TY_REAL)
	call sfree (sp)
end


# XP_OPCOLOR -- Return the gio color corresponding the user set object
# marking color.

int procedure xp_opcolor (xp)

pointer xp                      #I the pointer to the main xapphot structure

int     xp_stati()

begin
        switch (xp_stati (xp, OPCOLORMARK)) {
        case XP_OMARK_RED:
            return (RED)
        case XP_OMARK_BLUE:
            return (BLUE)
        case XP_OMARK_GREEN:
            return (GREEN)
        case XP_OMARK_YELLOW:
            return (YELLOW)
        default:
            return (GREEN)
        }
end


# XP_OSCOLOR -- Return the gio color corresponding the user set object
# sky marking color.

int procedure xp_oscolor (xp)

pointer xp                      #I the pointer to the main xapphot structure

int     xp_stati()

begin
        switch (xp_stati (xp, OSCOLORMARK)) {
        case XP_OMARK_RED:
            return (RED)
        case XP_OMARK_BLUE:
            return (BLUE)
        case XP_OMARK_GREEN:
            return (GREEN)
        case XP_OMARK_YELLOW:
            return (YELLOW)
        default:
            return (BLUE)
        }
end
