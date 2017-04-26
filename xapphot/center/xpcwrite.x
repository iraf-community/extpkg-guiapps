include "../lib/xphot.h"
include "../lib/center.h"


# XP_CQPRINT -- Print a quick summary of the centering algorithm results
# on the standard output.

procedure xp_cqprint (xp, image, ier, logresults)

pointer	xp		#I the main xapphot descriptor
char	image[ARB]	#I the input image name
int	ier		#I the input error code 
int	logresults	#I is the output being logged ?

real	xp_statr()

begin
	call printf ( "%s  %8.2f %8.2f  %8.2f %8.2f  ")
	    call pargstr (image)
	    call pargr ((xp_statr (xp, XCENTER) - xp_statr (xp, XSHIFT)))
	    call pargr ((xp_statr (xp, YCENTER) - xp_statr (xp, YSHIFT)))
	    call pargr (xp_statr (xp, XCENTER))
	    call pargr (xp_statr (xp, YCENTER))
	if (logresults == YES) {
	    if (IS_INDEFI(ier)) {
	        call printf ("%6.3f %6.3f  xxx log+\n")
	    	    call pargr (xp_statr (xp, XERR))
	    	    call pargr (xp_statr (xp, YERR))
	    } else {
	        call printf ("%6.3f %6.3f  %3d log+\n")
	    	    call pargr (xp_statr (xp, XERR))
	    	    call pargr (xp_statr (xp, YERR))
	    	    call pargi (ier)
	    }
	} else {
	    if (IS_INDEFI(ier)) {
	        call printf ("%6.3f %6.3f  xxx log-\n")
	    	    call pargr (xp_statr (xp, XERR))
	    	    call pargr (xp_statr (xp, YERR))
	    } else {
	        call printf ("%6.3f %6.3f  %3d log-\n")
	    	    call pargr (xp_statr (xp, XERR))
	    	    call pargr (xp_statr (xp, YERR))
	    	    call pargi (ier)
	    }
	}
end


# XP_CWRITE -- Write out the centering results.

procedure xp_cwrite (xp, fd, id, objects, lid, ier)

pointer	xp		#I the main xapphot descriptor
int	fd		#I the output file descriptor
int	id		#I the object id number
char	objects[ARB]	#I the object list name
int	lid		#I the object list id number
int	ier		#I the input error code 

real	x, y
real	xp_statr()

begin
	x = xp_statr (xp, XCENTER) - xp_statr (xp, XSHIFT)
	y = xp_statr (xp, YCENTER) - xp_statr (xp, YSHIFT)
	call xp_wid (xp, fd, x, y, id, objects, lid, '\\')
	call xp_wcres (xp, fd, ier, ' ')
end
