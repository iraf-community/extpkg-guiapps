# Public photometry parameters definitions file

# define the aperture geometries

define  XP_ACIRCLE      1       # circle
define  XP_AELLIPSE     2       # ellipse
define  XP_ARECTANGLE   3       # rectangle
define  XP_APOLYGON     4       # polygon

define  AGEOMS          "|circle|ellipse|rectangle|polygon|"

# define the aperture phtoometry  marker colors

define  XP_AMARK_RED            1
define  XP_AMARK_BLUE           2
define  XP_AMARK_GREEN          3
define  XP_AMARK_YELLOW         4

define  PCOLORS         "|red|blue|green|yellow|"

# define the photometry  error codes (# 501 - 600)

define	XP_OK			0	# no error
define	XP_APERT_NOIMAGE	501	# no image
define	XP_APERT_NOAPERT	502	# no photometry aperture
define  XP_APERT_OUTOFBOUNDS	503	# one or more apertures out of bounds
define	XP_APERT_NOSKYMODE	504	# undefined sky value
define	XP_APERT_TOOFAINT	505	# star too faint
define	XP_APERT_BADDATA	506	# bad pixels in aperture

# the photometry parameters and results (# 501 - 600)

define	PGEOSTRING	501
define	PGEOMETRY	502
define	PAPSTRING	503
define	PAXRATIO	504
define	PPOSANGLE	505
define	PZMAG		506

define	POGEOSTRING	507
define	POGEOMETRY	508
define	POAPSTRING	509
define	PAPERTURES	510
define	NAPERTS		511
define	POAXRATIO	512
define	POPOSANGLE	513

define	PUXVER		514
define	PUYVER		515
define	PUNVER		516

define	PXCUR		517
define	PYCUR		518
define	APIX		519
define	NAPIX		520
define	XAPIX		521
define	YAPIX		522
define	AXC		523
define	AYC		524
define	ANX		525
define	ANY		526
define	ADATAMIN	527
define	ADATAMAX	528

define	AREAS		529
define	SUMS		530
define	FLUX		531
define	SUMXSQ		532
define	SUMYSQ		533
define	SUMXY		534
define	MAGS		535
define	MAGERRS		536
define	MPOSANGLES	537
define	MAXRATIOS	538
define	MHWIDTHS	539

define	NMAXAP		540
define	NMINAP		541

define	PHOTMARK	542
define	PCOLORMARK	543

# the photometry keywords

#define	KY_PGEOSTRING	"PGEOMETRY"
#define	KY_PAPERTURES	"PAPERTURES"
#define	KY_PAXRATIO	"PAXRATIO"
#define	KY_PPOSANGLE	"PPOSANGLE"
#define	KY_PZMAG	"PZMAG"
#define	KY_PHOTMARK	"photmark"
#define	KY_PCOLORMARK	"pcolormark"

# the photometry units

#define	UN_PGEOMETRY	"geometry"
#define	UN_PAPERTURES	"scaleunit"
#define	UN_PNUMBER	"number"
#define	UN_PPOSANGLE	"degrees"
#define	UN_PZMAG	"magnitude"

# photometry strings

define	PCMDS		"|pgeometry|papertures|paxratio|pposangle|pzmag|\
photmark|pcolormark|"
define  UPCMDS		"||scaleunit||degrees|magnitude|||"
define  HPCMDS		"|geometry|scaleunit|number|degrees|magnitude|"

define	PCMD_PGEOMETRY		1
define	PCMD_PAPERTURES		2
define	PCMD_PAXRATIO		3
define	PCMD_PPOSANGLE		4
define	PCMD_PZMAG		5
define	PCMD_PHOTMARK		6
define	PCMD_PCOLORMARK		7

# define the default plot types

define	OBJPLOT_OBJECT		1
define	OBJPLOT_OVERLAY		2
define	OBJPLOT_APERTURE	3
define	OBJPLOT_MOMENTS		4
define	OBJPLOT_CONTOUR		5
define	OBJPLOT_SURFACE		6
define	OBJPLOT_RADIUS		7
define	OBJPLOT_PA		8
define	OBJPLOT_COG		9
define	OBJPLOT_MHWIDTH		10
define	OBJPLOT_MAXRATIO	11
define	OBJPLOT_MPOSANGLE	12

define	OBJPLOT_DISPLAY_WCS	2
define	OBJPLOT_ANALYSIS_WCS	10
define	OBJPLOT_RADIUS_WCS	10
define	OBJPLOT_PA_WCS		11
define	OBJPLOT_COG_WCS		12
define	OBJPLOT_MHWIDTH_WCS	13
define	OBJPLOT_MAXRATIO_WCS	14
define	OBJPLOT_MPOSANGLE_WCS	15

# miscellaneous

define	MAX_NAPERTS		100
define	MAX_NAP_VERTICES	100
define	MAX_NPHOTPARS		10
define	MAX_SZPHOTPAR		60
