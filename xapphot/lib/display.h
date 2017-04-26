# The public definitions file for the XPHOT task image display substructure

# the supported greylevel transformations

define	XP_DZNONE	1
define	XP_DZLINEAR	2
define	XP_DZLOG	3
define	XP_DZLUT	4

define	DZTRANS_OPTIONS "|none|linear|log|user|"

# the supported greylevel limits computation  algorithms

define	XP_DZMEDIAN	1
define	XP_DZIMAGE	2
define	XP_DZUSER	3

define	DZLIMITS_OPTIONS	"|median|image|user|"

# the display substructure parameter definitions (# 601 - 700)

define	DERASE		601
define	DFILL		602
define	DXORIGIN	603
define	DYORIGIN	604
define	DXMAG		605
define	DYMAG		606
define	DXVIEWPORT	607
define	DYVIEWPORT	608
define	DZTRANS		609
define	DZLIMITS	610
define	DZCONTRAST	611
define	DZNSAMPLE	612
define	DZ1		613
define	DZ2		614
define	DLUT		615
define	DREPEAT		616
define	DLUTFILE	617
define	DIMZ1		618
define	DIMZ2		619


# the display subtructure parameter editing commands

define DCMDS "|derase|dfill|dxorigin|dyorigin|dxviewport|dyviewport|dxmag|\
dymag|dztransform|dzlimits|dzcontrast|dznsample|dz1|dz2|dlutfile|drepeat|"

define UDCMDS	"|||pixels|pixels|||||||||counts|counts|||"

define	DCMD_DERASE		1
define	DCMD_DFILL		2
define	DCMD_DXORIGIN		3
define	DCMD_DYORIGIN		4 
define	DCMD_DXVIEWPORT		5
define	DCMD_DYVIEWPORT		6
define	DCMD_DXMAG		7
define	DCMD_DYMAG		8
define	DCMD_DZTRANSFORM	9
define	DCMD_DZLIMITS		10
define	DCMD_DZCONTRAST		11
define	DCMD_DZNSAMPLE		12
define	DCMD_DZ1		13
define	DCMD_DZ2		14
define	DCMD_DLUTFILE		15
define	DCMD_DREPEAT		16

# the raster and world coordinate system for the image display

define	IMAGE_DISPLAY_WCS	1

# miscellaneous

define	MAX_NDISPLAYPARS	15
define	MAX_SZDISPLAYPAR	60
