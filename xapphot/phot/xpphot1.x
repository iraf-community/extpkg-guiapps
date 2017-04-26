include "../lib/fitsky.h"
include "../lib/phot.h"

# XP_CFIT1 -- Fit the center for a single object.

int procedure xp_cfit1 (xp, im, wx, wy, newcbuf, newcenter, cier)

pointer	xp		#I the  pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the initial x and y coordinates
int	newcbuf		#I new centering data ?
int	newcenter	#I compute a new center ?
int	cier		#I the previous centering error code

int	xp_fitcenter(), xp_refitcenter()

begin
	# Do something about polygons at some point.
	if (newcbuf == YES) {
            cier = xp_fitcenter (xp, im, wx, wy)
        } else if (newcenter == YES)
            cier = xp_refitcenter (xp, cier)

	return (cier)
end


# XP_SFIT1 -- Fit the sky for a single object.

int procedure xp_sfit1 (xp, im, wx, wy, xver, yver, nver, sd, gd, newsbuf,
	newsky)

pointer	xp		#I the pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the initial x and y coordinates
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of polygon vertices
int	sd		#I the sky values file descriptor
pointer	gd		#I the graphics stream descriptor
int	newsbuf		#I new sky fitting data ?
int	newsky		#I compute a new sky value ?

int	sier
bool	fp_equalr()
int	xp_fitsky(), xp_refitsky()
real	xp_statr()

begin
	if (newsbuf == YES || ! fp_equalr (wx, xp_statr (xp, SXCUR)) ||
	    ! fp_equalr (wy, xp_statr (xp, SYCUR)))
            sier = xp_fitsky (xp, im, wx, wy, xver, yver, nver, sd, gd)
         else if (newsky == YES)
            sier = xp_refitsky (xp, gd)

	return (sier)
end


# XP_MAG1 -- Compute the magnitude for a single object.

int procedure xp_mag1 (xp, im, wx, wy, xver, yver, nver, sky, sigma, nsky,
	newmbuf, newmag)

pointer	xp		#I the pointer to the main xapphot structure
pointer	im		#I the pointer to the input image
real	wx, wy		#I the initial x and y coordinates
real	xver[ARB]	#I the x coordinates of the polygon vertices
real	yver[ARB]	#I the y coordinates of the polygon vertices
int	nver		#I the number of polygon vertices
real	sky		#I the input sky value
real	sigma		#I the input standard deviation of the sky  pixels
int	nsky		#I the number of sky pixels
int	newmbuf		#I new magnitude data ?
int	newmag		#I compute a new magnitude ?

int	pier
bool	fp_equalr()
int	xp_mag(), xp_remag()
real	xp_statr()

begin
	if (newmbuf == YES || ! fp_equalr (wx, xp_statr (xp, PXCUR)) ||
	    ! fp_equalr (wy, xp_statr (xp, PYCUR)))
            pier = xp_mag (xp, im, wx, wy, xver, yver, nver, sky,
		sigma, nsky)
         else
            pier = xp_remag (xp, sky, sigma, nsky)

	return (pier)
end
