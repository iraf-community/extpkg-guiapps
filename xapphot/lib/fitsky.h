# The public sky fitting parameters definitions files

# define the sky aperture positioning modes

define	XP_SCONCENTRIC	1
define	XP_SOFFSET	2

define	SMODES		"|concentric|offset|"

# define the sky fitting algorithms

define	XP_ZERO		1       # use a zero-valued sky
define	XP_CONSTANT	2	# use a constant sky
define	XP_MEAN		3 	# compute the mean of the sky pixels
define	XP_MEDIAN	4	# take median of sky pixels
define	XP_MODE32	5	# compute the mode32 of the sky pixels
define	XP_HCENTROID	6	# compute histogram peak by centroiding
define	XP_HOFILTER	7	# compute histogram peak by optimal filtering
define	XP_HCROSSCOR	8 	# compute histogram peak by xcorrelation
define	XP_HGAUSS	9	# compute histogram peak by gaussian fitting
define	XP_HISTPLOT	10	# mark the sky on a histogram plot
define	XP_RADPLOT	11	# mark sky on radial profile plot
define	XP_SKYFILE	12	# get values from a file

define	SALGS		"|none|constant|mean|median|mode32|hcentroid|hofilter|\
hcrosscor|hgauss|histplot|radplot|file|"


# define the sky fitting geometries

define	XP_SCIRCLE	1	# circle
define	XP_SELLIPSE	2	# ellipse
define	XP_SRECTANGLE	3	# rectangle
define	XP_SPOLYGON	4	# polygon

define	SGEOMS		"|circle|ellipse|rectangle|polygon|"


# define sky marker colors

define  XP_SMARK_RED            1
define  XP_SMARK_BLUE           2
define  XP_SMARK_GREEN          3
define  XP_SMARK_YELLOW         4

define  SCOLORS         "|red|blue|green|yellow|"


# define the sky fitting errors (# 401 - 500)

define	XP_OK			0	# no error
define	XP_SKY_NOIMAGE		401	# the input image is undefined
define	XP_SKY_NOPIXELS		402	# the sky aperture is undefined
define	XP_SKY_OFFIMAGE		403	# sky annulus partially off image
define	XP_SKY_NOHISTOGRAM	404	# histogram has no width
define	XP_SKY_FLATHISTOGRAM	405	# histogram is flat or concave
define	XP_SKY_TOOSMALL		406	# too few sky pixels for fit
define	XP_SKY_SINGULAR		407	# sky fit is singular
define	XP_SKY_NOCONVERGE	408	# sky fit did not converge
define	XP_SKY_NOGRAPHICS	409	# no graphics pointer
define	XP_SKY_NOFILE		410	# no sky file descriptor
define	XP_SKY_ATEOF		411	# end of sky file
define	XP_SKY_BADSCAN		412	# incomplete scan of sky file
define	XP_SKY_BADPARS		413	# fitted parameters are non-physical

# sky fitting parameters (# 401 - 500)


define	SMODE		401
define	SGEOMETRY	402
define	SRANNULUS	403
define	SWANNULUS	404
define	SAXRATIO	405
define	SPOSANGLE	406

define	SOMODE		407
define	SOGEOMETRY	408
define	SORANNULUS	409
define	SOWANNULUS	410
define	SOAXRATIO	411
define	SOPOSANGLE	412

define	SUXVER		413
define	SUYVER		414
define	SUNVER		415

define	SALGORITHM	416
define	SCONSTANT	417
define	SHWIDTH		418
define	SHBINSIZE	419
define	SHSMOOTH	420
define	SLOCLIP		421
define	SHICLIP		422
define	SMAXITER	423
define	SNREJECT	424
define	SLOREJECT	425
define	SHIREJECT	426
define	SRGROW		427

define	SXCUR		428
define	SYCUR		429
define	SKYPIX		430
define	SCOORDS		431
define	SINDEX		432
define	SWEIGHTS	433
define	NSKYPIX		434
define	SILO		435
define	SXC		436
define	SYC		437
define	SNX		438
define	SNY		439

define	SKY_MEAN	440
define	SKY_MEDIAN	441
define	SKY_MODE	442
define	SKY_STDEV	443
define	SKY_SKEW	444
define	NSKY		445
define	NSKY_REJECT	446

define	SSTRING		447
define	SMSTRING	448
define	SOMSTRING	449
define	SGEOSTRING	450
define	SOGEOSTRING	451

define	SKYMARK		452
define	SCOLORMARK	453

# fitsky string definitions

define	SCMDS		"|smode|sgeometry|srannulus|swannulus|saxratio|\
sposangle|salgorithm|sconstant|sloclip|shiclip|shwidth|shbinsize|shsmooth|\
smaxiter|snreject|sloreject|shireject|srgrow|skymark|scolormark|"

define	USCMDS	"|||scaleunit|scaleunit||degrees||counts|percent|percent|\
sigma|sigma||||sigma|sigma|scaleunit|||"
define	HSCMDS	"|position|geometry|scaleunit|scaleunit|number|degrees|\
algorithm|counts|percent|percent|sigma|sigma|switch|number|number|sigma|\
sigma|scaleunit|"

define	SCMD_SMODE		1
define	SCMD_SGEOMETRY		2
define	SCMD_SRANNULUS		3
define	SCMD_SWANNULUS		4
define	SCMD_SAXRATIO		5
define	SCMD_SPOSANGLE		6
define	SCMD_SALGORITHM 	7
define	SCMD_SCONSTANT 		8
define	SCMD_SLOCLIP		9
define	SCMD_SHICLIP		10
define	SCMD_SHWIDTH		11
define	SCMD_SHBINSIZE		12
define	SCMD_SHSMOOTH		13
define	SCMD_SMAXITER		14
define	SCMD_SNREJECT		15
define	SCMD_SLOREJECT		16
define	SCMD_SHIREJECT		17
define	SCMD_SRGROW		18
define	SCMD_SKYMARK		19
define	SCMD_SCOLORMARK		20

# define the default plot types

define	SKYPLOT_OBJECT		1
define	SKYPLOT_OVERLAY		2
define	SKYPLOT_APERTURE	3
define	SKYPLOT_CONTOUR		4
define	SKYPLOT_SURFACE		5
define	SKYPLOT_RADIUS          6
define  SKYPLOT_PA              7
define  SKYPLOT_HISTOGRAM       8

# define the sky plots world coordinate systems

define	SKYPLOT_DISPLAY_WCS	3
define	SKYPLOT_ANALYSIS_WCS	7
define	SKYPLOT_RADIUS_WCS	7
define	SKYPLOT_PA_WCS		8
define	SKYPLOT_HISTOGRAM_WCS	9

# miscellaneous

define	MAX_NSKY_VERTICES	100
define	MAX_NSKYPARS		25
define	MAX_SZSKYPAR		60
