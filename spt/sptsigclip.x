include	<smw.h>
include	<mach.h>
include	"spectool.h"

# Commands
define	CMDS	"|open|close|sigclip|"
define	OPEN		1
define	CLOSE		2
define	SIGCLIP		3	# Sigma clip


# SIGCLIP -- Sigma clip around continuum.

procedure sigclip (spt, reg, cmd)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
char	cmd			#I Command

int	i, j, n, nclip, ncmd
real	sigmaclip, lowclip, highclip, radiusclip
real	sigma, low, high, radius, r, lval, hval
pointer	sh, y, c, e
int	strdic(), nscan()
real	clgetr()

begin
	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (SPT_STRING(spt), SPT_SZSTRING)
	ncmd = strdic (SPT_STRING(spt), SPT_STRING(spt), SPT_SZSTRING, CMDS)

	switch (ncmd) {
	case OPEN:
	    sigmaclip = clgetr ("sigclip")
	    lowclip = clgetr ("lowclip")
	    highclip = clgetr ("highclip")
	    radiusclip = clgetr ("radiusclip")
	    call sprintf (SPT_STRING(spt), SPT_SZSTRING, "%g %g %g %g")
		call pargr (sigmaclip)
		call pargr (lowclip)
		call pargr (highclip)
		call pargr (radiusclip)
	    call gmsg (SPT_GP(spt), "sigclip", SPT_STRING(spt))

	case CLOSE:
	    call clputr ("sigclip", sigmaclip)
	    call clputr ("lowclip", lowclip)
	    call clputr ("highclip", highclip)
	    call clputr ("radiusclip", radiusclip)
	    
	case SIGCLIP: # sigclip sigma low high radius
	    # Set parameters
	    call gargr (sigma)
	    call gargr (low)
	    call gargr (high)
	    call gargr (radius)

	    n = nscan()
	    if (n < 2)
		sigma = sigmaclip
	    if (n < 3)
		low = lowclip
	    if (n < 4)
		high = highclip
	    if (n < 5)
		radius = radiusclip

	    sigmaclip = sigma
	    lowclip = low
	    highclip = high
	    radiusclip = radius

	    if (IS_INDEFR(sigma) || sigma < 0.)
		sigma = INDEFR
	    if (IS_INDEFR(low) || low < 0.)
		low = INDEFR
	    if (IS_INDEFR(high) || high < 0.)
		high = INDEFR
	    if (IS_INDEFR(radius) || radius < 0.)
		radius = 0.

	    # Set data
	    if (reg == NULL)
		return
	    sh = REG_SH(reg)
	    y = SPEC(sh,SPT_CTYPE(spt))
	    c = SC(sh)
	    e = SE(sh)
	    n = SN(sh)
	    if (y == NULL || c == NULL)
		return

	    # Compute sigma if needed.
	    if (IS_INDEFR(sigma) && e == NULL) {
		sigma = 0.
		do i = 0, n-1 {
		    r = Memr[y+i] - Memr[c+i]
		    sigma = sigma + r * r
		}
		sigma = sqrt (sigma / max (1,n-1))
	    }

	    # Flag clipped pixels with INDEFR.
	    nclip = 0
	    if (IS_INDEFR(sigma)) {
		do i = 0, n-1 {
		    r = Memr[y+i] - Memr[c+i]
		    if (IS_INDEFR(low))
			lval = -MAX_REAL
		    else
			lval = -low * Memr[e+i]
		    if (IS_INDEFR(high))
			hval = MAX_REAL
		    else
			hval = high * Memr[e+i]
		    if (r < lval || r > hval) {
			if (nclip == 0)
			    call spt_shcopy (sh, REG_SHBAK(reg), YES)
			Memr[y+i] = INDEFR 
			nclip = nclip + 1
		    }
		}
	    } else {
		if (IS_INDEFR(low))
		    lval = -MAX_REAL
		else
		    lval = -low * sigma
		if (IS_INDEFR(high))
		    hval = MAX_REAL
		else
		    hval = high * sigma
		do i = 0, n-1 {
		    r = Memr[y+i] - Memr[c+i]
		    if (r < lval || r > hval) {
			if (nclip == 0)
			    call spt_shcopy (sh, REG_SHBAK(reg), YES)
			Memr[y+i] = INDEFR 
			nclip = nclip + 1
		    }
		}
	    }

	    if (nclip == 0)
		return

	    # Replace neighbor pixels with continuum.
	    if (radius >= 1.) {
		do i = 0, n-1 {
		    if (IS_INDEFR(Memr[y+i])) {
			do j = max(0,i-1), max(0,nint(i-radius)), -1
			    Memr[y+j] = Memr[c+j]
			do j = min(n-1,i+1), min(n-1,nint(i+radius))
			    Memr[y+j] = Memr[c+j]
		    }
		}
	    }

	    # Replace clipped pixels with continuum.
	    do i = 0, n-1 {
		if (IS_INDEFR(Memr[y+i]))
		    Memr[y+i] = Memr[c+i]
	    }

	    SPT_REDRAW(spt,1) = YES
	    SPT_REDRAW(spt,2) = YES
	}
end
