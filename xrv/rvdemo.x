include <fio.h>

define	SG_NLINES	2500
define	SG_SCALE	10000.0


# RV_SPECGEN - Generate two artificial spectra for a demo run.

procedure rv_specgen (object, template)

char	object[SZ_FNAME]		#o object filename
char	template[SZ_FNAME]		#o object filename

begin
	# Generate the artificial line list.
	call sg_mkline_list ("lines", SG_NLINES, SG_SCALE)

	# Create the object spectrum and add noise.

	# Create the template spectrum and add noise.
	
end


# SG_MKLINE_LIST - Generate a list of wavelengths to be used in the art-
# ificial line list.  Wavelengths generated are in the range 1 to scale_
# factor.

procedure sg_mkline_list (fname, nlines, scale_factor)

char	fname[ARB]			#i file name of spectral lines
int	nlines				#i number of lines to generate
real	scale_factor			#i wavelength scale factor

pointer	sp, nums
int	fd
long	i, seed

int	open(), access()
real	urand()

begin
	# Open the requested file name.
	if (access(fname,0,0) == YES) {
	    call error (2, "Requested wavelength filename already exists.")
	} else {
	    iferr (fd = open (fname, NEW_FILE, TEXT_FILE))
	        call error (3, "Error opening wavelength list file.")
	}

	call smark (sp)
	call salloc (nums, nlines, TY_REAL)

	# Generate the random numbers.
	seed = 1
	for (i=0; i<nlines; i=i+1)
	    Memr[nums+i] = urand (seed) * scale_factor
	call asrtr (Memr[nums], Memr[nums], nlines) 	# sort them

	# Write them out.
	for (i=0; i<nlines; i=i+1) {
	    call fprintf (fd, "%9.7g\n")
	        call pargr (Memr[nums+i])
	}

	call close (fd)				# clean up
	call sfree (sp)
end


# SG_MKRNOISE -- Make gaussian read noise.

procedure sg_mkrnoise (data, ndata, rdnoise)

real    data[ndata]             # Output data
int     ndata                   # Number of data points
real    rdnoise                 # Read noise (in data units)

long    seed
int     i
real	gasdev()

begin
	seed = 1
        do i = 1, ndata
            data[i] = data[i] + rdnoise * gasdev (seed)
end


# GASDEV -- Return a normally distributed deviate with zero mean and unit
# variance.  The method computes two deviates simultaneously.
#
# Based on Numerical Recipes by Press, Flannery, Teukolsky, and Vetterling.
# Used by permission of the authors.
# Copyright(c) 1986 Numerical Recipes Software.

real procedure gasdev (seed)

long    seed            # Seed for random numbers

real    v1, v2, r, fac, urand()
int     iset
data    iset/0/

begin
        if (iset == 0) {
            repeat {
                v1 = 2 * urand (seed) - 1.
                v2 = 2 * urand (seed) - 1.
                r = v1 ** 2 + v2 ** 2
            } until ((r > 0) && (r < 1))
            fac = sqrt (-2. * log (r) / r)

            iset = 1
            return (v1 * fac)
        } else {
            iset = 0
            return (v2 * fac)
        }
end
