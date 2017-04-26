# The private image data parameters definitions file

# The Image Parameter Structure

define	LEN_PIMPARS	(15 + 10 * SZ_FNAME + 10)

define	XP_ISCALE	Memr[P2R($1)]	# image scale in pixels / unit 
define	XP_IHWHMPSF	Memr[P2R($1+1)]	# the hwhm of the psf (scale units)
define	XP_IEMISSION    Memi[$1+2]	# emission feature  (yes / no)
define	XP_ISKYSIGMA	Memr[P2R($1+3)]	# standard deviation of sky (counts)
define	XP_IMINDATA	Memr[P2R($1+4)]	# mininum good data value (counts)
define	XP_IMAXDATA	Memr[P2R($1+5)]	# maximum good data value (counts)
define	XP_IETIME	Memr[P2R($1+6)]	# effective exposure time (units)
define	XP_IAIRMASS	Memr[P2R($1+7)]	# effective air mass

define	XP_INOISEMODEL	Memi[$1+8]	# the noise model
define	XP_IGAIN	Memr[P2R($1+9)]	# the effective gain (e- / count)
define	XP_IREADNOISE	Memr[P2R($1+10)]	# the effective readnoise (e-)

define	XP_IKEXPTIME	Memc[P2C($1+12)]		# exposure keyword
define	XP_IKAIRMASS	Memc[P2C($1+12+1*SZ_FNAME+1)]	# airmass keyword
define	XP_IKFILTER	Memc[P2C($1+12+2*SZ_FNAME+2)]	# filter keyword
define	XP_IKOBSTIME	Memc[P2C($1+12+3*SZ_FNAME+3)]	# time of observation
define	XP_IFILTER	Memc[P2C($1+12+4*SZ_FNAME+4)]	# filter id
define	XP_IOTIME	Memc[P2C($1+12+5*SZ_FNAME+5)]	# time of observation

define	XP_INSTRING	Memc[P2C($1+12+6*SZ_FNAME+6)]   # noise model
define	XP_IKGAIN	Memc[P2C($1+12+7*SZ_FNAME+7)]	# gain keyword
define	XP_IKREADNOISE	Memc[P2C($1+12+8*SZ_FNAME+8)]   # readout noise keyword

#define	XP_IMAGE	Memc[P2C($1+12+9*SZ_FNAME+9)]   # input image name

# Internal Default Definitions

define	DEF_ISCALE		1.0000
define	DEF_IHWHMPSF		1.0
define	DEF_IEMISSION		YES
define	DEF_ISKYSIGMA		INDEFR
define	DEF_IMINDATA		INDEFR
define	DEF_IMAXDATA		INDEFR

define	DEF_IKEXPTIME		"EXPTIME"
define	DEF_IKAIRMASS		"AIRMASS"
define	DEF_IKFILTER		"FILTERS"
define	DEF_IKOBSTIME		"UT"
define	DEF_IETIME		1.0
define	DEF_IAIRMASS		INDEFR
define	DEF_IFILTER		"INDEF"
define	DEF_IOTIME		"INDEF"

define	DEF_INOISEMODEL		1		# (poisson)
define	DEF_IKREADNOISE		"RDNOISE"
define	DEF_IKGAIN		"GAIN"
define	DEF_IGAIN		1.0
define	DEF_IREADNOISE		0.0
define	DEF_INSTRING		"poisson"

#define	MAX_NIMPARS		20
#define	MAX_SZIMPAR		60
