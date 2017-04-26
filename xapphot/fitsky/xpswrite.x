include "../lib/xphot.h"
include "../lib/fitsky.h"


# XP_SQPRINT -- Print a quick summary of the sky fitting results on the
# standard output.

procedure xp_sqprint (xp, imname, ier, logresults)

pointer	xp		#I the pointer to the main xapphot structure
char	imname[ARB]	#I the input image name
int	ier		#I the input error code
int	logresults	#I is results logging turned on ?

int	xp_stati()
real	xp_statr()

begin
	# Print out the results on the standard output.
	call printf ( "%s  %8.2f %8.2f  %8g %8g ") 
	    call pargstr (imname)
	    call pargr (xp_statr (xp, SXCUR))
	    call pargr (xp_statr (xp, SYCUR))
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (xp_statr (xp, SKY_STDEV))
	if (logresults == YES) {
	    if (IS_INDEFI(ier)) {
	        call printf ("%8g  %5d %5d  xxx log+\n")
	    	    call pargr (xp_statr (xp, SKY_SKEW))
	    	    call pargi (xp_stati (xp, NSKY))
	    	    call pargi (xp_stati (xp, NSKY_REJECT))
	    } else {
	        call printf ("%8g  %5d %5d  %3d log+\n")
	    	    call pargr (xp_statr (xp, SKY_SKEW))
	    	    call pargi (xp_stati (xp, NSKY))
	    	    call pargi (xp_stati (xp, NSKY_REJECT))
	    	    call pargi (ier)
	    }
	} else {
	    if (IS_INDEFI(ier)) {
	        call printf ("%8g  %5d %5d  xxx log-\n")
	    	    call pargr (xp_statr (xp, SKY_SKEW))
	    	    call pargi (xp_stati (xp, NSKY))
	    	    call pargi (xp_stati (xp, NSKY_REJECT))
	    } else {
	        call printf ("%8g  %5d %5d  %3d log-\n")
	    	    call pargr (xp_statr (xp, SKY_SKEW))
	    	    call pargi (xp_stati (xp, NSKY))
	    	    call pargi (xp_stati (xp, NSKY_REJECT))
	    	    call pargi (ier)
	    }
	}
end


# XP_SWRITE -- Write out the centering results.

procedure xp_swrite (xp, fd, id, objects, lid, ier)

pointer xp              #I the pointer to the main xapphot structure
int     fd              #I the output file descriptor
int     id              #I the object id number
char    objects[ARB]    #I the object list name
int     lid             #I the object list id number
int     ier             #I the input error code

real    x, y
real    xp_statr()

begin
        x = xp_statr (xp, SXCUR)
        y = xp_statr (xp, SYCUR)
        call xp_wid (xp, fd, x, y, id, objects, lid, '\\')
        call xp_wsres (xp, fd, ier, ' ')
end
