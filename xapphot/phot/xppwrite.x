include "../lib/xphot.h"
include "../lib/impars.h"
include "../lib/center.h"
include "../lib/fitsky.h"
include "../lib/phot.h"

# XP_PBANNER -- Format a banner string.

procedure xp_pbanner (xp, banner, maxch)

pointer	xp		#I the pointer to the main xapphot structure
char	banner[ARB]	#O the banner string
int	maxch		#I the maximum number of characters

begin
	call sprintf (banner, maxch,
	"%15.15s  %8s %8s %8s  %6s %5s %5s  %8s  %8s  %8s  %10s %7s %5s %10s")
	    call pargstr ("Image")

	    call pargstr ("Xc")
	    call pargstr ("Yc")
	    call pargstr ("Sky")

	    call pargstr ("Hw[N]")
	    call pargstr ("Ax[N]")
	    call pargstr ("Pa[N]")

	    call pargstr ("Flux[N]")
	    call pargstr ("Mag[N]")
	    call pargstr ("Merr[N]")
	    call pargstr ("Filter")
	    call pargstr ("Etime")
	    call pargstr ("X")
	    call pargstr ("Otime")
end


# XP_PRESULTS -- Format the photometry answers string.

procedure xp_presults (xp, results, maxch)

pointer	xp		#I the pointer to the main xapphot structure
char	results[ARB]	#O the results string
int	maxch		#I the maximum number of characters

int	nap
pointer	sp, str1, str2, str3
real	flux
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	call smark (sp)
	call salloc (str1, SZ_FNAME, TY_CHAR)
	call salloc (str2, SZ_FNAME, TY_CHAR)
	call salloc (str3, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[str1], SZ_FNAME)
	call xp_stats (xp, IFILTER, Memc[str2], SZ_FNAME)
	call xp_stats (xp, IOTIME, Memc[str3], SZ_FNAME)

	nap = xp_stati(xp,NAPERTS)
	call sprintf (results, maxch,
"%15.15s  %8.2f %8.2f %8g  %6.2f %5.2f %5.1f  %8g  %8.3f  %8.3f  %10.10s %7.1f %5.2f %10.10h")
	    call pargstr (Memc[str1])
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (Memr[xp_statp(xp,MHWIDTHS)+nap-1])
	    call pargr (Memr[xp_statp(xp,MAXRATIOS)+nap-1])
	    call pargr (Memr[xp_statp(xp,MPOSANGLES)+nap-1])
	    if (IS_INDEFR(xp_statr (xp, SKY_MODE))) {
		call pargr (INDEFR)
	    } else {
		if (IS_INDEFD(Memd[xp_statp(xp,FLUX)+nap-1]))
		    flux = INDEFR
		else
	            flux = Memd[xp_statp(xp,FLUX)+nap-1]
	        call pargr (flux)
	    }
	    call pargr (Memr[xp_statp(xp,MAGS)+nap-1])
	    call pargr (Memr[xp_statp(xp,MAGERRS)+nap-1])
	    call pargstr (Memc[str2])
	    call pargr (xp_statr(xp, IETIME))
	    call pargr (xp_statr(xp, IAIRMASS))
	    call pargstr (Memc[str3])

	call sfree (sp)
end


# XP_ORESULTS -- Format the object answers string.

procedure xp_oresults (xp, lseqno, seqno, banner, maxch)

pointer	xp		#I the pointer to the main xapphot structure
int	lseqno		#I the input objects file seqno
int	seqno		#I the output results file seqno
char	banner[ARB]	#O the results string
int	maxch		#I the maximum number of characters

int	i, strfd
pointer	sp, imname, olname, rlname
real	area, flux
int	stropen(), xp_stati()
pointer	xp_statp()
real	xp_statr()


begin
	call smark (sp)
	call salloc (imname, SZ_FNAME, TY_CHAR)
	call salloc (olname, SZ_FNAME, TY_CHAR)
	call salloc (rlname, SZ_FNAME, TY_CHAR)
	call xp_stats (xp, IMAGE, Memc[imname], SZ_FNAME)
	call xp_stats (xp, OBJECTS, Memc[olname], SZ_FNAME)
	call xp_stats (xp, RESULTS, Memc[rlname], SZ_FNAME)

	strfd = stropen (banner, maxch, NEW_FILE)
	call fprintf (strfd,
	    "%10tIMAGE: %s  OBJECTS: %s[%5d]  RESULTS: %s[%5d]\n\n")
	    call pargstr (Memc[imname])
	    call pargstr (Memc[olname])
	    call pargi (lseqno)
	    call pargstr (Memc[rlname])
	    call pargi (seqno)
	call fprintf (strfd, "        Xc Yc: %7.2f %7.2f  ")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	call fprintf (strfd, "     Xsky Ysky: %7.2f %7.2f  ")
	    call pargr (xp_statr (xp, SXCUR))
	    call pargr (xp_statr (xp, SYCUR))
	call fprintf (strfd, "    Sky Sigma Nsky: %8.2f %7.2f %d\n")
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (xp_statr (xp, SKY_STDEV))
	    call pargi (xp_stati (xp, NSKY))
	do i = 1, xp_stati(xp,NAPERTS) {
	    call fprintf (strfd,
	 "Ap: %5.1f  Hw: %5.2f Ax: %5.2f Pa: %5.1f  Area: %8.2f Flux: %10.2f  ")
		call pargr (Memr[xp_statp(xp,PAPERTURES)+i-1])
	        call pargr (Memr[xp_statp(xp,MHWIDTHS)+i-1])
	        if (IS_INDEFR(Memr[xp_statp(xp,MAXRATIOS)+i-1]))
		    call pargr (INDEFR)
	        else
	            call pargr (Memr[xp_statp(xp,MAXRATIOS)+i-1])
	    call pargr (Memr[xp_statp(xp,MPOSANGLES)+i-1])
	    if (IS_INDEFR(xp_statr (xp, SKY_MODE))) {
		call pargr (INDEFR)
		call pargr (INDEFR)
	    } else {
		if (IS_INDEFD(Memd[xp_statp(xp,AREAS)+i-1]))
		    area = INDEFR
		else
	            area = Memd[xp_statp(xp,AREAS)+i-1]
		if (IS_INDEFD(Memd[xp_statp(xp,FLUX)+i-1]))
		    flux = INDEFR
		else
	            flux = Memd[xp_statp(xp,FLUX)+i-1]
	        call pargr (area)
	        call pargr (flux)
	    }
	    call fprintf (strfd, "Mag: %8.3f Merr: %7.3f\n")
	        call pargr (Memr[xp_statp(xp,MAGS)+i-1])
	        call pargr (Memr[xp_statp(xp,MAGERRS)+i-1])
	}

	call strclose(strfd)
	call sfree (sp)
end


# XP_PQPRINT -- Print a quick summary of the photometry results on the
# standard output.

procedure xp_pqprint (xp, imname, cier, sier, pier, logresults)

pointer	xp		#I the pointer to the main xapphot structure
char	imname[ARB]	#I the input image name
int	cier		#I the centering error
int	sier		#I the sky fitting error
int	pier		#I the photometry error
int	logresults	#I the results file logging status

int	apno
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	# Get aperture number.
	apno = xp_stati(xp, NAPERTS)

	# Print the center, sky, and moments analysis .
	call printf ("%s  %8.2f %8.2f %8g  %6.2f %4.2f %5.1f  ")
	    call pargstr (imname)
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (Memr[xp_statp(xp,MHWIDTHS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MAXRATIOS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MPOSANGLES)+apno-1])

	# Print out the magnitudes.
	call printf ("%8g %8.3f %6.3f  ")
	    call pargd (Memd[xp_statp(xp,FLUX)+apno-1])
	    call pargr (Memr[xp_statp(xp,MAGS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MAGERRS)+apno-1])
	if (logresults == YES) {
	    if (IS_INDEFI(pier)) {
	        call printf ("%xxx log+\n")
	    } else {
	        call printf ("%3d log+\n")
		    call pargi (pier)
	    }
	} else {
	    if (IS_INDEFI(pier)) {
	        call printf ("xxx log-\n")
	    } else {
	        call printf ("%3d log-\n")
	            call pargi (pier)
	    }
	}
end


# XP_UPQPRINT -- Print a quick summary of the photometry results in the image
# display window.

procedure xp_upqprint (xp, cier, sier, pier, logresults)

pointer	xp		#I the pointer to the main xapphot structure
int	cier		#I the centering error
int	sier		#I the sky fitting error
int	pier		#I the photometry error
int	logresults	#I the results file logging status

int	apno
real	flux
int	xp_stati()
pointer	xp_statp()
real	xp_statr()

begin
	apno = xp_stati(xp, NAPERTS)

	# Print the center and sky value.
	call printf ("%0.2f %0.2f %g  %0.2f %0.2f %0.1f  ")
	    call pargr (xp_statr (xp, PXCUR))
	    call pargr (xp_statr (xp, PYCUR))
	    call pargr (xp_statr (xp, SKY_MODE))
	    call pargr (Memr[xp_statp(xp,MHWIDTHS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MAXRATIOS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MPOSANGLES)+apno-1])

	# Print out the magnitudes.
	if (IS_INDEFD(Memd[xp_statp(xp,FLUX)+apno-1]))
	    flux = INDEFR
	else
	    flux = Memd[xp_statp(xp,FLUX)+apno-1]
	call printf ("%g %0.3f %0.3f  ")
	    call pargr (flux)
	    call pargr (Memr[xp_statp(xp,MAGS)+apno-1])
	    call pargr (Memr[xp_statp(xp,MAGERRS)+apno-1])
	if (logresults == YES) {
	    if (IS_INDEFI(pier)) {
	        call printf ("xxx log+\n")
	    } else {
	        call printf ("%3d log+\n")
		    call pargi (pier)
	    }
	} else {
	    if (IS_INDEFI(pier)) {
	        call printf ("xxx log-\n")
	    } else {
	        call printf ("%3d log-\n")
	            call pargi (pier)
	    }
	}
end


# XP_PWRITE -- Procedure to write the results of the XGUIPHOT task to the output
# file.

procedure xp_pwrite (xp, fd, seqno, objects, loseqno, cier, sier, pier)

pointer xp      	#I the pointer to the xapphot structure
int     fd      	#I the output text file descriptor
int     seqno   	#I the output file sequence number
char	objects[ARB]	#I the input objects file name
int     loseqno 	#I the input objects file sequence number 
int     cier    	#I the centering error code
int     sier    	#I the sky fitting error code
int     pier    	#I the photometric error code

int     i, naperts
real    x, y
int     xp_stati()
real    xp_statr()

begin
        if (fd == NULL)
            return

        # Write out the object id parameters.
        x = xp_statr (xp, XCENTER) - xp_statr (xp, XSHIFT)
        y = xp_statr (xp, YCENTER) - xp_statr (xp, YSHIFT)
        call xp_wid (xp, fd, x, y, seqno, objects, loseqno, '\\')

        # Write out the centering results.
        call xp_wcres (xp, fd, cier, '\\')

        naperts = xp_stati (xp, NAPERTS)

	# Write out the moments analysis results.
        if (naperts == 0)
            call xp_wmres (xp, fd, 0, pier, " \\")
        else {
            do i = 1, naperts {
                if (naperts == 1)
                    call xp_wmres (xp, fd, i, pier, " \\")
                #else if (i == naperts)
                    #call xp_wmres (xp, fd, i, pier, "* ")
                else
                    call xp_wmres (xp, fd, i, pier, "*\\")
            }
        }

        # Write out the sky fitting results.
        call xp_wsres (xp, fd, sier, '\\')


        # Write out the photometry results.
        if (naperts == 0)
            call xp_wpres (xp, fd, 0, pier, "  ")
        else {
            do i = 1, naperts {
                if (naperts == 1)
                    call xp_wpres (xp, fd, i, pier, "  ")
		else if (i == naperts)
                    call xp_wpres (xp, fd, i, pier, "* ")
                else
                    call xp_wpres (xp, fd, i, pier, "*\\")
            }
        }

end
