include <imhdr.h>
include "../lib/impars.h"

# XP_KEYSET -- Update the image keyword information after a new image is
# opened.

procedure xp_keyset (im, xp)

pointer	im			#I the pointer to the input image
pointer	xp			#I the pointer to the main xapphot structure

begin
	call xp_etime (im, xp)
	call xp_gain (im, xp)
	call xp_rdnoise (im, xp)
	call xp_filter (im, xp)
	call xp_airmass (im, xp)
	call xp_otime (im, xp)
end


# XP_ETIME -  Set the image exposure time.

procedure xp_etime (im, xp)

pointer	im		#I the pointer to the input image
pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, key
real	etime
real	imgetr(), xp_statr()

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKEXPTIME, Memc[key], SZ_FNAME)
	if (Memc[key] == EOS)
	    etime = xp_statr (xp, IETIME)
	else {
	    iferr { 
		if (im == NULL)
	    	    etime = INDEFR
		else
	            etime = imgetr (im, Memc[key])
	    } then {
		#etime = xp_statr (xp, IETIME)
		etime = INDEFR
		call printf ("Warning: image %s  keyword: %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}
	if (IS_INDEFR(etime) || etime <= 0.0)
	    call xp_setr (xp, IETIME, 1.0)
	else
	    call xp_setr (xp, IETIME, etime)

	call sfree (sp)
end


# XP_GAIN -- Set the image gain parameter for the noise model computation.

procedure xp_gain (im, xp)

pointer	im		#I the pointer to the input image
pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, key
real	gain
real	imgetr(), xp_statr()

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKGAIN, Memc[key], SZ_FNAME)
	if (Memc[key] == EOS)
	    gain = xp_statr (xp, IGAIN)
	else {
	    iferr {
		if (im == NULL)
	    	    gain = INDEFR
		else
	            gain = imgetr (im, Memc[key])
	    } then {
		#gain = xp_statr (xp, IGAIN)
	    	gain = INDEFR
		call printf ("Warning: image %s  keyword %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}
	if (IS_INDEFR(gain) || gain <= 0.0)
	    call xp_setr (xp, IGAIN, 1.0)
	else
	    call xp_setr (xp, IGAIN, gain)

	call sfree (sp)
end


# XP_RDNOISE --  Set the image readnoise parameter.

procedure xp_rdnoise (im, xp)

pointer	im		#I the pointer to the input image
pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, key
real	rdnoise
real	imgetr(), xp_statr()

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKREADNOISE, Memc[key], SZ_FNAME)
	if (Memc[key] == EOS)
	    rdnoise = xp_statr (xp, IREADNOISE)
	else {
	    iferr {
		if (im == NULL)
	            rdnoise = INDEFR
		else
	            rdnoise = imgetr (im, Memc[key])
	    } then {
		#rdnoise = xp_statr (xp, IREADNOISE)
	        rdnoise = INDEFR
		call printf ("Warning: image %s  keyword %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}
	if (IS_INDEFR(rdnoise) || rdnoise <= 0.0)
	    call xp_setr (xp, IREADNOISE, 0.0)
	else
	    call xp_setr (xp, IREADNOISE, rdnoise)

	call sfree (sp)
end


# XP_FILTER --  Set the image filter id.

procedure xp_filter (im, xp)

pointer	im		#I the pointer to the input image
pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, key, filt

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)
	call salloc (filt, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKFILTER, Memc[key], SZ_FNAME)
	Memc[filt] = EOS
	if (Memc[key] == EOS)
	    call xp_stats (xp, IFILTER, Memc[filt], SZ_FNAME)
	else {
	    iferr { 
		if (im == NULL)
		    call strcpy ("INDEF", Memc[filt], SZ_FNAME)
		else
	            call imgstr (im, Memc[key], Memc[filt], SZ_FNAME)
	    } then {
	        #call xp_stats (xp, IFILTER, Memc[filt], SZ_FNAME)
		call strcpy ("INDEF", Memc[filt], SZ_FNAME)
		call printf ("Warning: image %s  keyword: %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}

	if (Memc[filt] == EOS) {
	    call xp_sets (xp, IFILTER, "INDEF")
	} else {
	    call xp_rmwhite (Memc[filt], Memc[filt], SZ_FNAME)
	    call xp_sets (xp, IFILTER, Memc[filt])
	}

	call sfree (sp)
end


# XP_AIRMASS --  Set the image airmass.

procedure xp_airmass (im, xp)

pointer	im		#I the pointer to input image
pointer	xp		#I the pointer to the main xapphot structure

pointer	sp, key
real	xair
real	imgetr(), xp_statr()

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKAIRMASS, Memc[key], SZ_FNAME)
	if (Memc[key] == EOS)
	    xair = xp_statr (xp, IAIRMASS)
	else {
	    iferr { 
		if (im == NULL)
	            xair = INDEFR
		else
	            xair = imgetr (im, Memc[key])
	    } then {
		#xair = xp_statr (xp, IAIRMASS)
	        xair = INDEFR
		call printf ("Warning: image %s  keyword: %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}
	if (IS_INDEFR(xair) || xair <= 0.0)
	    call xp_setr (xp, IAIRMASS, INDEFR)
	else
	    call xp_setr (xp, IAIRMASS, xair)

	call sfree (sp)
end


# XP_OTIME --  Set the time or epoch of the observation from the image
# header.

procedure xp_otime (im, xp)

pointer	im		#I the pointer to the input image
pointer	xp		#I the pointer to the main xapphot structure

char	timechar
int	index
pointer	sp, key, otime
bool	streq()
int	strldx()

begin
	call smark (sp)
	call salloc (key, SZ_FNAME, TY_CHAR)
	call salloc (otime, SZ_FNAME, TY_CHAR)

	call xp_stats (xp, IKOBSTIME, Memc[key], SZ_FNAME)
	Memc[otime] = EOS
	if (Memc[key] == EOS)
	    call xp_stats (xp, IOTIME, Memc[otime], SZ_FNAME)
	else {
	    iferr { 
		if (im == NULL)
		    call strcpy ("INDEF", Memc[otime], SZ_FNAME)
		else
	            call imgstr (im, Memc[key], Memc[otime], SZ_FNAME)
	    } then {
	        #call xp_stats (xp, IOTIME, Memc[otime], SZ_FNAME)
		call strcpy ("INDEF", Memc[otime], SZ_FNAME)
		call printf ("Warning: image %s  keyword: %s not found\n")
		    call pargstr (IM_HDRFILE(im))
		    call pargstr (Memc[key])
	    }
	}
	if (Memc[otime] == EOS) {
	    call xp_sets (xp, IOTIME, "INDEF")
        } else if (streq ("DATE-OBS", Memc[key]) || streq ("date-obs",
            Memc[key])) {
            timechar = 'T'
            index = strldx (timechar, Memc[otime])
            if (index > 0)
                call xp_sets (xp, IOTIME, Memc[otime+index])
            else
                call xp_sets (xp, IOTIME, "INDEF")
	} else {
	    call xp_sets (xp, IOTIME, Memc[otime])
	}

	call sfree (sp)
end
