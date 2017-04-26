# The private skyfitting parameters definitions file 

define LEN_PSKY		(55 + 5 * SZ_FNAME + 5)

# sky fitting parameters

define	XP_SMODE	  Memi[$1]	# user position of the sky aperture
define	XP_SGEOMETRY	  Memi[$1+1]	# user shape of the sky aperture
define	XP_SRANNULUS	  Memr[P2R($1+2)] # user radius of sky annulus scale 
define	XP_SWANNULUS	  Memr[P2R($1+3)] # user width of annulus in scale units
define	XP_SAXRATIO	  Memr[P2R($1+4)] # user ratio of short/long annulus axes
define	XP_SPOSANGLE	  Memr[P2R($1+5)] # user ratio short/long annulus axes
define	XP_SALGORITHM	  Memi[$1+6]	# the sky fitting algorithm
define	XP_SCONSTANT	  Memr[P2R($1+7)] # user defined sky value
define	XP_SLOCLIP	  Memr[P2R($1+8)] # lower clipping percentile
define	XP_SHICLIP	  Memr[P2R($1+9)] # lower clipping percentile
define	XP_SHWIDTH	  Memr[P2R($1+10)] # K-sigma histogram rejection
define	XP_SHBINSIZE	  Memr[P2R($1+11)] # histogram binsize in sky sigma
define	XP_SHSMOOTH	  Memi[$1+12]	# Smooth histogram ?
define	XP_SMAXITER	  Memi[$1+13]	# maximum number of iterations
define	XP_SNREJECT	  Memi[$1+14]	# maximum number of rejection cycles
define	XP_SLOREJECT	  Memr[P2R($1+15)] # lower K-sigma rejection for pixels
define	XP_SHIREJECT	  Memr[P2R($1+16)] # higher K-sigma rejection for pixels
define	XP_SRGROW	  Memr[P2R($1+17)] # region growing radius in scale

# actual sky fitting geometry

define	XP_SOMODE	  Memi[$1+18]	# actual position of the sky aperture
define	XP_SOGEOMETRY	  Memi[$1+19]	# actual shape of the sky aperture
define	XP_SORANNULUS	  Memr[P2R($1+20)] # actual radius of sky annulus scale 
define	XP_SOWANNULUS	  Memr[P2R($1+21)] # actual with of annulus in scale units
define	XP_SOAXRATIO	  Memr[P2R($1+22)] # user ratio of short/long annulus axes
define	XP_SOPOSANGLE	  Memr[P2R($1+23)] # actual ratio short/long annulus axes

define	XP_SUXVER	  Memi[$1+24]   # pointer to user sky polygon x vertices
define	XP_SUYVER	  Memi[$1+25]   # pointer to user sky polygon y vertices
define	XP_SUNVER	  Memi[$1+26]   # number of user sky polygon vertices

# sky buffer definitions

define	XP_SKYPIX	Memi[$1+27]	# pointer to sky pixels
define	XP_SINDEX	Memi[$1+28]	# pointer to sky sorting array
define	XP_SCOORDS	Memi[$1+29]	# pointer to sky coordinates array
define	XP_SWEIGHTS	Memi[$1+30]	# pointer to sky weights
define	XP_NSKYPIX	Memi[$1+31]	# number of sky pixels
define	XP_SILO		Memi[$1+32]	# the low side clipping index
define	XP_NBADSKYPIX	Memi[$1+33]	# number of bad sky pixels
define	XP_LENSKYBUF	Memi[$1+34]	# length of sky buffers
define	XP_SXCUR	Memr[P2R($1+35)]	# x center of sky annulus
define	XP_SYCUR	Memr[P2R($1+36)]	# y center of sky annulus
define	XP_SXC		Memr[P2R($1+37)]	# x center of sky subraster
define	XP_SYC		Memr[P2R($1+38)]	# y center of sky subraster
define	XP_SNX		Memi[$1+39]	# x dimension of sky subraster
define	XP_SNY		Memi[$1+40]	# y dimension of sky subraster

# sky fitting output

define	XP_SKY_MEAN	Memr[P2R($1+41)]  # computed sky mean (optional)
define	XP_SKY_MEDIAN	Memr[P2R($1+42)]  # computed sky median (optional)
define	XP_SKY_MODE	Memr[P2R($1+43)]  # computed sky value
define	XP_SKY_STDEV	Memr[P2R($1+44)]  # computed sky standard deviation
define	XP_SKY_SKEW	Memr[P2R($1+45)]  # computed sky skew
define	XP_NSKY		Memi[$1+46]	  # number of sky pix
define	XP_NSKY_REJECT	Memi[$1+47]	  # number of rejected sky pix

# sky marking 

define	XP_SKYMARK	Memi[$1+48]	  # mark sky annulus on display
define	XP_SCOLORMARK	Memi[$1+49]	  # color of marked sky annulus

define	XP_SSTRING	Memc[P2C($1+50)]  	      # user salgorithm string
define	XP_SMSTRING	Memc[P2C($1+50+1*SZ_FNAME+1)] # user sky mode string
define	XP_SOMSTRING	Memc[P2C($1+50+2*SZ_FNAME+2)] # actual sky mode string
define	XP_SGEOSTRING	Memc[P2C($1+50+3*SZ_FNAME+3)] # user geometry string
define	XP_SOGEOSTRING	Memc[P2C($1+50+4*SZ_FNAME+4)] # actual geometry string

# default setup values for sky fitting

define	DEF_SMSTRING		"concentric"
define	DEF_SMODE		1		# (concentric)
define	DEF_SGEOSTRING		"circle"
define	DEF_SGEOMETRY		1		# (circle)
define	DEF_SRANNULUS		20.
define	DEF_SWANNULUS		5.0
define	DEF_SAXRATIO		1.0
define	DEF_SPOSANGLE		0.0
define	DEF_SSTRING		"hcentroid"
define	DEF_SALGORITHM		6		# (hcentroid)
define	DEF_SCONSTANT		0.0
define	DEF_SHWIDTH		3.0
define	DEF_SHBINSIZE		0.20
define	DEF_SHSMOOTH		YES
define	DEF_SMAXITER		10
define	DEF_SLOCLIP		0.0
define	DEF_SHICLIP		0.0
define	DEF_SNREJECT		50
define	DEF_SLOREJECT		3.0
define	DEF_SHIREJECT		3.0
define	DEF_SRGROW		0.0
define	DEF_SKYMARK		YES
define	DEF_SCOLORMARK		4		# (yellow)
