# Private object detection parameters definitions file

define	LEN_PFIND		(10)

define	XP_FTHRESHOLD	    Memr[P2R($1)]    # detection threshold in counts
define	XP_FRADIUS	    Memr[P2R($1+1)]  # the fitting radius in HWHM units
define	XP_FSEPMIN	    Memr[P2R($1+2)]  # the minimum separation in HWHM units 
define	XP_FROUNDLO	    Memr[P2R($1+3)]  # the minimum roundness value
define	XP_FROUNDHI	    Memr[P2R($1+4)]  # the maximum roundness value
define	XP_FSHARPLO	    Memr[P2R($1+5)]  # the minimum sharpness value
define	XP_FSHARPHI	    Memr[P2R($1+6)]  # the maximum sharpness value

# default setup values for object marking parameters

define	DEF_FTHRESHOLD		320.0
define	DEF_FRADIUS		2.5
define	DEF_FSEPMIN		5.0
define	DEF_FROUNDLO		0.0
define	DEF_FROUNDHI		0.2
define	DEF_FSHARPLO		0.5
define	DEF_FSHARPHI		2.0
