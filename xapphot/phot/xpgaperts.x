include <lexnum.h>
include <ctype.h>

# XP_GETAPERTS -- Read the aperture radii values from a string

int procedure xp_getaperts (str, aperts, max_naperts)

char	str[ARB]		#I the aperturestring
real	aperts[ARB]		#O the number of apertures
int	max_naperts		#I the maximum number of apertures

int	fd, naperts
int	access(), open(), xp_rdaperts(), xp_decaperts()
errchk	open(), close()

begin
	naperts = 0

	if (access (str, READ_ONLY, TEXT_FILE) == YES) {
	    fd = open (str, READ_ONLY, TEXT_FILE)
	    naperts = xp_rdaperts (fd, aperts, max_naperts)
	    call close (fd)
	} else
	    naperts = xp_decaperts (str, aperts, max_naperts)

	return (naperts)
end


# XP_RDAPERTS -- Read the apertures radii values listed one per line
# from a file.

int procedure xp_rdaperts (fd, aperts, max_naperts)

int	fd		#I the aperture list file descriptor
real	aperts[ARB]	#O the list of apertures
int	max_naperts	#I the maximum number of apertures

int	naperts
pointer	sp, line
int	getline(), xp_decaperts()

begin
	call smark (sp)
	call salloc (line, SZ_LINE, TY_CHAR)

	naperts = 0
	while (getline (fd, Memc[line]) != EOF && naperts < max_naperts) {
	    naperts = naperts + xp_decaperts (Memc[line], aperts[1+naperts],
	        max_naperts - naperts)
	}

	call sfree (sp)

	return (naperts)
end


# XP_DECAPERTS -- Procedure to decode the aperture string.

int procedure xp_decaperts (str, aperts, max_naperts)

char	str[ARB]		#I the aperture string
real	aperts[ARB]		#O the aperture array
int	max_naperts		#I the maximum number of apertures

char	outstr[SZ_LINE]
int	naperts, ip, op, ndecode, nap
real	apstart, apend, apstep
bool	fp_equalr()
int	gctor()

begin
	naperts = 0

	for (ip = 1; str[ip] != EOS && naperts < max_naperts;) {

	    apstart = 0.0
	    apend = 0.0
	    apstep = 0.0
	    ndecode = 0

	    # Skip past white space and commas.
	    while (IS_WHITE(str[ip]))
		ip = ip + 1
	    if (str[ip] == ',')
		ip = ip + 1

	    # Get the number.
	    op = 1
	    while (IS_DIGIT(str[ip]) || str[ip] == '.') {
		outstr[op] = str[ip]
		ip = ip + 1
		op = op + 1
	    }
	    outstr[op] = EOS

	    # Decode the starting aperture.
	    op = 1
	    if (gctor (outstr, op, apstart) > 0) {
	        apend = apstart
	        ndecode = 1
	    } else
		apstart = 0.0

	    # Skip past white space and commas.
	    while (IS_WHITE(str[ip]))
		ip = ip + 1
	    if (str[ip] == ',')
		ip = ip + 1

	    # Get the ending aperture
	    if (str[ip] == ':') {
		ip = ip + 1

		# Get the ending aperture.
		op = 1
		while (IS_DIGIT(str[ip]) || str[ip] == '.') {
		    outstr[op] = str[ip]
		    ip = ip + 1
		    op = op + 1
		}
		outstr[op] = EOS

	        # Decode the ending aperture.
	        op = 1
	        if (gctor (outstr, op, apend) > 0) {
	            ndecode = 2
	            apstep = apend - apstart
		}
	     }

	    # Skip past white space and commas.
	    while (IS_WHITE(str[ip]))
		ip = ip + 1
	    if (str[ip] == ',')
		ip = ip + 1

	    # Get the step size.
	    if (str[ip] == ':') {
		ip = ip + 1

		# Get the step size.
		op = 1
		while (IS_DIGIT(str[ip]) || str[ip] == '.') {
		    outstr[op] = str[ip]
		    ip = ip + 1
		    op = op + 1
		}
		outstr[op] = EOS

		# Decode the step size.
		op = 1
		if (gctor (outstr, op, apstep) > 0) {
		    if (fp_equalr (apstep, 0.0))
			apstep = apend - apstart
		    else
			ndecode = (apend - apstart) / apstep + 1
		    if (ndecode < 0) {
			ndecode = -ndecode
			apstep = - apstep
		    }
		}
	    }

	    # Negative apertures are not permitted.
	    #if (apstart <= 0.0 || apend <= 0.0)
		#break
	    if (apstart < 0.0 || apend < 0.0)
		break

	    # Fill in the apertures.
	    if (ndecode == 0) {
		;
	    } else if (ndecode == 1) {
		naperts = naperts + 1
		aperts[naperts] = apstart
	    } else if (ndecode == 2) {
		naperts = naperts + 1
		aperts[naperts] = apstart
		if (naperts >= max_naperts)
		    break
		naperts = naperts + 1
		aperts[naperts] = apend
	    } else {
		for (nap = 1; nap <= ndecode && naperts < max_naperts;
		    nap = nap + 1) {
		    naperts = naperts + 1
		    aperts[naperts] = apstart + (nap - 1) * apstep
		}
	    }
	}

	return (naperts)
end


# GCTOR -- Procedure to convert a character variable to a real number.
# This routine is just an interface routine to the IRAF procedure gctod.

int procedure gctor (str, ip, rval)

char	str[ARB]	#I the string to be converted
int	ip		#I the pointer to the string
real	rval		#O the real value

double	dval
int	nchars
int	gctod()

begin
	nchars = gctod (str, ip, dval)
	rval = dval
	return (nchars)
end
