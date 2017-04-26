include	<error.h>
include	<smw.h>
include	"spectool.h"

define	CMDS	"|open|close|average|median|gauss|"
define	OPEN	1
define	CLOSE	2
define	AVG	3	# Box average
define	MEDIAN	4	# Box median
define	GAUSS	5	# Gaussian convolution


# SPT_SMOOTH -- Smooth spectrum.
# Syntax: type size
#   type is one of the smoothing types and size is a size parameter in pixels.

procedure spt_smooth (spt, inreg, instype, outreg, outstype, cmd)

pointer	spt			#I SPECTOOLS pointer
pointer	inreg			#I Input register pointer
int	instype			#I Input spectrum type
pointer	outreg			#I Output register pointer
int	outstype		#I Output spectrum type
char	cmd[ARB]		#I Command

int	ncmd, sn
real	size
pointer	sy1, sy2

int	strdic(), nscan()
real	clgetr()
errchk	spt_smooth1

define	err_	10

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (ncmd) {
	case OPEN: # open
	    ;

	case CLOSE: # close
	    ;

	case AVG, MEDIAN, GAUSS: # [average|median|gauss] size
	    call gargr (size)
	    if (nscan() == 1) {
		switch (ncmd) {
		case AVG:
		    size = clgetr ("sptqueries.mvavg")
		case MEDIAN:
		    size = clgetr ("sptqueries.mvmed")
		case GAUSS:
		    size = clgetr ("sptqueries.gconvolve")
		}
	    }

	    if (REG_SHSAVE(outreg) == NULL)
		call spt_shcopy (REG_SH(outreg), REG_SHSAVE(outreg), YES)
	    else
		call spt_shcopy (REG_SH(outreg), REG_SHBAK(outreg), YES)

	    sy1 = SPEC(REG_SH(inreg),instype)
	    sy2 = SPEC(REG_SH(outreg),outstype)
	    if (sy2 == NULL) {
		call malloc (SPEC(REG_SH(outreg),outstype), SN(REG_SH(outreg)),
		    TY_REAL)
		sy2 = SPEC(REG_SH(outreg),outstype)
	    }
	    sn = min (SN(REG_SH(inreg)), SN(REG_SH(outreg))) 
	    if (sy2 == sy1) {
		call malloc (sy2, sn, TY_REAL)
		call spt_smooth1 (ncmd, size, Memr[sy1], Memr[sy2], sn)
		call amovr (Memr[sy2], Memr[sy1], sn)
		call mfree (sy2, TY_REAL)
	    } else
		call spt_smooth1 (ncmd, size, Memr[sy1], Memr[sy2], sn)

	    call spt_scale (spt, outreg)
	    SPT_REDRAW(spt,1) = YES

	default: # error or unknown command
err_	    call sprintf (SPT_STRING(spt), SPT_SZSTRING,
		"Error in colon command: %s")
		call pargstr (cmd)
	    call error (1, SPT_STRING(spt))
	}
end


# SPT_SMOOTH1 -- Smooth spectrum.
# The box size must be greater than 1 and is limited to spectrum length.
# At the edges it uses as many pixels as fall in the box at each output
# pixel.  For even box sizes there is one more point to greater pixels
# than to lower.  The input and output spectrum vectors must not be
# the same.

procedure spt_smooth1 (type, size, y1, y2, n)

int	type		#I Smoothing type
real	size		#I Smoothing size
real	y1[n]		#I Input spectrum
real	y2[n]		#I Ouput spectrum
int	n		#I Number of points in spectrum

int	i, j, k, box, box1
real	sum, center, sigma, amedr(), spt_conv()
pointer	filter

begin
	switch (type) {
	case AVG:
	    box = min (n, nint (size))
	    if (box <= 1)
		return
	    box1 = box / 2

	    i = 1
	    j = 1
	    k = 1
	    sum = 0
	    for (; i<=box1; i=i+1)
		sum = sum + y1[i]
	    for (; i<=box; i=i+1) {
		sum = sum + y1[i]
		y2[j] = sum / i
		j = j + 1
	    }
	    for (; i<=n; i=i+1) {
		sum = sum + y1[i]
		sum = sum - y1[k]
		y2[j] = sum / box
		j = j + 1
		k = k + 1
	    }
	    for (i=box-1; i>=box1; i=i-1) {
		sum = sum - y1[k]
		y2[j] = sum / i
		j = j + 1
		k = k + 1
	    }
	case MEDIAN:
	    box = min (n, nint (size))
	    if (box <= 1)
		return
	    box1 = box / 2

	    i = 1
	    j = 1
	    for (k=box1+1; k<=box; k=k+1) {
		y2[j] = amedr (y1, k)
		j = j + 1
	    }
	    for (; k<=n; k=k+1) {
		y2[j] = amedr (y1[i], box)
		i = i + 1
		j = j + 1
	    }
	    for (k=box-1; k>=box1; k=k-1) {
		y2[j] = amedr (y1[i], k)
		i = i + 1
		j = j + 1
	    }
	case GAUSS:
	    box = min (n, nint (3*size))
	    if (box <= 1)
		return
	    box1 = box / 2
	    center = box / 2.
	    sigma = size / (2 * sqrt (log (2.)))

	    call malloc (filter, box, TY_REAL)

	    sum = 0.
	    do i = 0, box-1 {
		Memr[filter+i] = exp (-((i-center)/sigma)**2)
		sum = sum + Memr[filter+i]
	    }
	    do i = 0, box-1
		Memr[filter+i] = Memr[filter+i] / sum

	    do i = 1, n
		y2[i] = spt_conv (Memr[filter], box, y1, n, i-box1)

	    call mfree (filter, TY_REAL)
	}
end


real procedure spt_conv (filter, nfilter, data, ndata, start)

real	filter[nfilter]		#I Normalized convolution filter
int	nfilter			#I Number of points in filter
real	data[ndata]		#I Data to be convolved
int	ndata			#I Number of data points
int	start			#I Starting pixel in data

int	i, j
real	sum, norm

begin
	j = start - 1
	if (j < 0 || j > ndata-nfilter) {
	    norm = 0.
	    sum = 0.
	    do i = max (1, 1-j), min (nfilter, ndata-j) {
		norm = norm + filter[i]
		sum = sum + data[i+j] * filter[i]
	    }
	    if (norm > 0.)
		sum = sum / norm
	} else {
	    sum = 0.
	    do i = 1, nfilter
		sum = sum + data[i+j] * filter[i]
	}
	return (sum)
end
