# Public centering parameters definitions file

# centering algorithms

define	XP_NONE		1	# no centering
define	XP_CENTROID1D	2	# 1D centroiding
define	XP_GAUSS1D	3	# 1D Gaussian non-linear least-squares fits
define	XP_OFILT1D	4	# 1D optimal filtering

define	CALGS		"|none|centroid1d|gauss1d|ofilter1d|"

# centering marker characters

define	XP_CMARK_POINT		1 
define	XP_CMARK_BOX		2 
define	XP_CMARK_CROSS		3
define	XP_CMARK_PLUS		4
define	XP_CMARK_CIRCLE		5
define	XP_CMARK_DIAMOND	6

define CMARKERS		"|point|box||plus|circle|diamond|"

# centering marker colors

define  XP_CMARK_RED		1
define  XP_CMARK_BLUE		2
define  XP_CMARK_GREEN		3
define  XP_CMARK_YELLOW		4

define	CCOLORS		"|red|blue|green|yellow|"

# the centering error codes (# 301 - 400)

define	XP_OK			0	# no error
define	XP_CTR_NOIMAGE		301	# the input image is undefined
define	XP_CTR_NOPIXELS		302	# the centering aperture off image
define	XP_CTR_OFFIMAGE		303	# centering aperture partially off image
define	XP_CTR_TOOSMALL		304	# centering aperture is too small
define	XP_CTR_BADDATA		305	# bad data in centering aperture
define	XP_CTR_LOWSNRATIO	306	# low s/n ratio in centering aperture
define	XP_CTR_SINGULAR		307	# fit is singular
define	XP_CTR_NOCONVERGE	308	# fit did not converge
define	XP_CTR_BADSHIFT		309	# maximum shift parameter exceeded

# centering parameters (# 301 - 400)

define	CALGORITHM	301
define	CSTRING		302
define	CRADIUS		303
define	CTHRESHOLD	304
define	CMINSNRATIO	305
define	CMAXITER	306
define	CXYSHIFT	307
define	CXCUR		308
define	CYCUR		309
define	CTRPIX		310

define	XCENTER		311
define	YCENTER		312
define	XERR		313
define	YERR		314
define	XSHIFT		315
define	YSHIFT		316
define	CDATALIMIT	317

define	CTRMARK		318
define	CCHARMARK	319
define	CCOLORMARK	320
define	CSIZEMARK	321

# center string commands

define	CCMDS		"|calgorithm|cradius|cthreshold|cminsnratio|cmaxiter|\
cxyshift|ctrmark|ccharmark|ccolormark|csizemark|"
define	UCCMDS		"||scaleunit|sigma|||scaleunit|||||"
define	HCCMDS		"|algorithm|scaleunit|sigma|number|number|scaleunit|"

define	CCMD_CALGORITHM		1
define	CCMD_CRADIUS		2
define	CCMD_CTHRESHOLD		3
define	CCMD_CMINSNRATIO	4
define	CCMD_CMAXITER		5
define	CCMD_CXYSHIFT		6

define	CCMD_CTRMARK		7
define	CCMD_CCHARMARK		8
define	CCMD_CCOLORMARK		9
define	CCMD_CSIZEMARK		10

# Miscellaneous

define	MAX_NCENTERPARS		15
define	MAX_SZCENTERPAR		60
