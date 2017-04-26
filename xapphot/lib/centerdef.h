# Private centering parameters definitions file

define	LEN_PCENTER		(40 + SZ_FNAME + 1)

# centering algorithm parameters

define	XP_CALGORITHM       Memi[$1]	# centering algorithm
define	XP_CRADIUS	    Memr[P2R($1+1)]# centering box half-width
define	XP_CTHRESHOLD	    Memr[P2R($1+2)]# threshold above data min or max
define	XP_CMINSNRATIO	    Memr[P2R($1+3)]# minimum s/n ratio 
define	XP_CMAXITER	    Memi[$1+4]	# maximum number of iterations
define	XP_CXYSHIFT	    Memr[P2R($1+5)]# maximum center shift

# centering algorithm data buffers

define	XP_CTRPIX	    Memi[$1+10]	# pointer to pixels
define	XP_CXCUR	    Memr[P2R($1+11)]	# x cursor position
define	XP_CYCUR	    Memr[P2R($1+12)]	# y cursor position
define	XP_CXC		    Memr[P2R($1+13)]	# x center of subraster
define	XP_CYC		    Memr[P2R($1+14)]	# y center of subraster
define	XP_CNX		    Memi[$1+15]	# x dimension of subraster
define	XP_CNY		    Memi[$1+16]	# y dimension of subraster
define	XP_XCTRPIX	    Memi[$1+17]	# pointer to x coords (not used)
define	XP_YCTRPIX	    Memi[$1+18]	# pointer to y coords (not used)
define	XP_NCTRPIX	    Memi[$1+19]	# number of pixels (not used)
define	XP_LENCTRBUF	    Memi[$1+20]	# centering buffer size (not used)

# centering algorithm output

define	XP_XCENTER	    Memr[P2R($1+22)]	# computed x center
define	XP_YCENTER	    Memr[P2R($1+23)]	# computed y center
define	XP_XSHIFT	    Memr[P2R($1+24)]	# total x shift
define	XP_YSHIFT	    Memr[P2R($1+25)]	# total y shift
define	XP_XERR		    Memr[P2R($1+26)]	# x error
define	XP_YERR		    Memr[P2R($1+27)]	# y error
define	XP_CDATALIMIT	    Memr[P2R($1+28)]	# min (max) of subraster

# centering algorithm display marking commands

define	XP_CTRMARK	    Memi[$1+29] # mark the computed centers
define	XP_CCHARMARK	    Memi[$1+30] # the centers marker character
define	XP_CCOLORMARK	    Memi[$1+31] # the centers marker color
define	XP_CSIZEMARK        Memr[P2R($1+32)] # the centers marker size

define	XP_CSTRING	    Memc[P2C($1+35)]# centering algorithm id

# default setup values for centering parameters

define	DEF_CALGORITHM		2
define	DEF_CSTRING		"centroid1d"
define	DEF_CRADIUS		3.5
define	DEF_CTHRESHOLD		INDEF
define	DEF_CMINSNRATIO		3.0
define	DEF_CMAXITER		10
define	DEF_CXYSHIFT		5.0
define	DEF_CTRMARK		NO
define	DEF_CCHARMARK		4
define	DEF_CCOLORMARK		1
define	DEF_CSIZEMARK		5.0
