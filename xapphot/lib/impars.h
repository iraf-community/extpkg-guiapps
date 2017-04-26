# The public image data parameters definitions file

# Image parameters (# 101 - 200)

define	ISCALE		101	# image scale
define	IHWHMPSF	102	# half-width half-maximum of the PSF
define	IEMISSION	103	# emission or absorption feature ?
define	ISKYSIGMA	104     # standard deviation of background
define	IMINDATA	105	# minimum good data value
define	IMAXDATA	106	# maximum good data value

define	IKEXPTIME	107	# exposure time keyword
define	IKAIRMASS	108	# airmass keyword
define	IKFILTER	109	# filter keyword
define	IKOBSTIME	110	# time of observation keyword
define	IETIME		111	# exposure time
define	IAIRMASS	112	# airmass value
define	IFILTER		113	# filter id
define	IOTIME		114	# time stamp

define	INOISEMODEL	115	# the adopted noise model
define	ISKYSIGMA	116	# the standard deviation of the background
define	IKREADNOISE	117	# the CCD readout keyword
define	IKGAIN		118	# the CCD gain keyword
define	IREADNOISE	119	# the readout noise
define	IGAIN		120	# the gain
define	INSTRING	121	# the noise model string

# Image Parameter Commands

define	ICMDS	"|iscale|ihwhmpsf|iemission|iskysigma|imindata|imaxdata|\
inoisemodel|ikreadnoise|ikgain|ireadnoise|igain|ikexptime|ikfilter|\
ikairmass|ikobstime|ietime|ifilter|iairmass|iotime|"

define UICMDS	"||scaleunit||counts|counts|counts||||e-|e-/count|\
||||timeunit|||timeunit|"
define HICMDS	"|unit/pixel|scaleunit|switch|counts|counts|counts|\
model|keyword|keyword|e-|e-/count|keyword|keyword|keyword|keyword|\
timeunit|name|number|timeunit|"

define	ICMD_ISCALE		1
define	ICMD_IHWHMPSF		2
define	ICMD_IEMISSION		3
define	ICMD_ISKYSIGMA		4
define	ICMD_IMINDATA		5
define	ICMD_IMAXDATA		6

define	ICMD_INOISEMODEL	7
define	ICMD_IKREADNOISE	8
define	ICMD_IKGAIN		9
define	ICMD_IREADNOISE		10
define	ICMD_IGAIN		11

define	ICMD_IKEXPTIME	       	12
define	ICMD_IKFILTER		13
define	ICMD_IKAIRMASS		14
define	ICMD_IKOBSTIME		15
define	ICMD_IETIME		16
define	ICMD_IFILTER		17
define	ICMD_IAIRMASS		18
define	ICMD_IOTIME		19

# the noise functions

define	XP_INPOISSON	1

define	NFUNCS	"|poisson|"

# miscellaneous

define	MAX_NIMPARS		20
define	MAX_SZIMPAR		60
