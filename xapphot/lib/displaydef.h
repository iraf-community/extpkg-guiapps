# The private definitions file for the XPHOT task image display substructure

# the image display substructure

define	LEN_PIMDISPLAY	(30 + SZ_FNAME + 1)

define	XP_DERASE	Memi[$1]	 # erase image display window
define	XP_DFILL	Memi[$1+1]	 # fill image display window
define	XP_DXORIGIN	Memr[P2R($1+2)]	 # the display window h center
define	XP_DYORIGIN	Memr[P2R($1+3)]	 # the display window v center
define	XP_DXVIEWPORT	Memr[P2R($1+4)]	 # the display window h size
define	XP_DYVIEWPORT	Memr[P2R($1+5)]	 # the display window v size
define	XP_DXMAG	Memr[P2R($1+6)]	 # the display window h magnification
define	XP_DYMAG	Memr[P2R($1+7)]	 # the display window v magnification
define	XP_DZTRANS	Memi[$1+8]	 # the grey level transformation
define	XP_DZLIMITS	Memi[$1+9]	 # the zlimits algorithm
define	XP_DZNSAMPLE	Memi[$1+10]	 # the number of sample lines
define	XP_DZCONTRAST	Memr[P2R($1+11)] # the contrast for zmedian algorithm
define	XP_DZ1		Memr[P2R($1+12)] # the min value for zuser algorithm
define	XP_DZ2		Memr[P2R($1+13)] # the max value for zuser algorithm
define	XP_DIMZ1	Memr[P2R($1+14)] # the min value for zuser algorithm
define	XP_DIMZ2	Memr[P2R($1+15)] # the max value for zuser algorithm
define	XP_DLUT		Memi[$1+16]	 # pointer to the lut
define	XP_DREPEAT	Memi[$1+17]	 # use previous display parameters
define	XP_DLUTFILE	Memc[P2C($1+25)] # the lookup table file

# miscellaneous internal algorithm definitions

define	DEF_DERASE	YES		 
define	DEF_DFILL	YES		 
define	DEF_DXVIEWPORT	1.0
define	DEF_DYVIEWPORT	1.0
define	DEF_DXMAG	1.0
define	DEF_DYMAG	1.0
define	DEF_DZTRANS	2		 # (linear)
define	DEF_DZLIMITS	1		 # (median)
define	DEF_DZCONTRAST	0.25
define	DEF_DSAMPLESIZE	600
define	DEF_DZNSAMPLE	5
define	DEF_DZ1		INDEFR
define	DEF_DZ2		INDEFR
define	DEF_DIMZ1	INDEFR
define	DEF_DIMZ2	INDEFR
define	DEF_DREPEAT	NO

define	DEF_UMAXPTS	4096		 # the maximum number of lut points
define	DEF_UZ1		0		 # the default lut min value
define	DEF_UZ2		4095		 # the default lut max value
define	DEF_UMAXLOG	3		 # the max log (z) value

define	DEF_CNCOLORS  200		 # the default number of colors
define	DEF_CZ1	     (LAST_COLOR + 1) 	 # the default min color value
define	DEF_CZ2	     (LAST_COLOR + DEF_CNCOLORS) # the default max color value
define	DEF_CMAXINTENSITY	255
