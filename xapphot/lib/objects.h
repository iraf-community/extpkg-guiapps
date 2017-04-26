# Public objects list parameter definitions file

define	LEN_OBJLIST_STRUCT	(20 + MAX_SZAPERTURES + 1)

define	XP_ODELETED	    Memi[$1]	     # has the object been deleted
define	XP_OXINIT	    Memr[P2R($1+1)]  # the object x position
define	XP_OYINIT	    Memr[P2R($1+2)]  # the object y position
define	XP_OGEOMETRY	    Memi[$1+3]	     # the object geometry
define	XP_OAXRATIO	    Memr[P2R($1+4)]  # the object axis ratio
define	XP_OPOSANG	    Memr[P2R($1+5)]  # the object position angle
define	XP_ONPOLYGON	    Memi[$1+6]       # the object polygon id number
define	XP_OXSHIFT	    Memr[P2R($1+7)]  # the object polygon x shift
define	XP_OYSHIFT	    Memr[P2R($1+8)]  # the object polygon y shift
define	XP_OSXINIT	    Memr[P2R($1+9)]  # the sky x position
define	XP_OSYINIT	    Memr[P2R($1+10)] # the sky y position
define	XP_OSRIN	    Memr[P2R($1+11)] # the inner sky radius
define	XP_OSROUT	    Memr[P2R($1+12)] # the outer sky radius
define	XP_OSGEOMETRY	    Memi[$1+13]      # the sky geometry
define	XP_OSAXRATIO	    Memr[P2R($1+14)] # the sky axis ratio
define	XP_OSPOSANG	    Memr[P2R($1+15)] # the sky position angle
define	XP_OSNPOLYGON	    Memi[$1+17]      # the sky polygon id number
define	XP_OSXSHIFT	    Memr[P2R($1+18)] # the object polygon x shift
define	XP_OSYSHIFT	    Memr[P2R($1+19)] # the object polygon y shift
define	XP_OAPERTURES	    Memc[P2C($1+20)] # the apertures list

define	LEN_POLYGONLIST_STRUCT (10 + 2 * MAX_NOBJ_VERTICES + 2)

define	XP_POLYWRITTEN	    Memi[$1]
define	XP_ONVERTICES	    Memi[$1+1]
define	XP_SNVERTICES	    Memi[$1+2]
define	XP_XVERTICES	    Memr[P2R($1+3)]
define	XP_YVERTICES	    Memr[P2R($1+3+MAX_NOBJ_VERTICES+1)]

define	DEF_LEN_OBJLIST		1000
define	DEF_LEN_POLYGONLIST	10
define	MAX_SZAPERTURES		40
#define	DEF_OBUFSIZE		1000

# list of object markers

define	XP_OMARK_POINT		1 
define	XP_OMARK_BOX		2 
define	XP_OMARK_CROSS		3
define	XP_OMARK_PLUS		4
define	XP_OMARK_CIRCLE		5
define	XP_OMARK_DIAMOND	6
define	XP_OMARK_SHAPE		7

define OMARKERS		"|point|box||plus|circle|diamond|shape|"

# object marker colors

define  XP_OMARK_RED		1
define  XP_OMARK_BLUE		2
define  XP_OMARK_GREEN		3
define  XP_OMARK_YELLOW		4

define	OCOLORS		"|red|blue|green|yellow|"

# object geometries

define	XP_OINDEF	        1
define	XP_OCIRCLE	        2
define	XP_OELLIPSE	        3
define	XP_ORECTANGLE	        4
define	XP_OPOLYGON	        5
define	XP_OOBJECT	        6

define OGEOMETRIES	"|INDEF|circle|ellipse|rectangle|polygon|"
define OSGEOMETRIES	"|INDEF|circle|ellipse|rectangle|polygon|object|"

# objects parameters (# 701 - 800)

define	OBJLIST		       701
define	POLYGONLIST	       702
define	OTOLERANCE	       703
define	OBJMARK		       704
define	OCHARMARK	       705
define	ONUMBER		       706
define	OPCOLORMARK	       707
define	OSCOLORMARK	       708
define	OSIZEMARK	       709

# objects string commands

define	OCMDS	"|objmark|ocharmark|onumber|opcolormark|oscolormark|\
osizemark|otolerance|ox|oy|ogeometry|oapertures|oaxratio|oposangle|overtices|\
osx|osy|osgeometry|osrin|osrout|osaxratio|osposangle|osvertices|oselect|\
odelete|oundelete|oadd|osave|"
define	UOCMDS	"|||||||scaleunit||||scaleunit||degrees|||||scaleunit|\
scaleunit||degrees||||||"

define	OCMD_OBJMARK		1
define	OCMD_OCHARMARK		2
define	OCMD_ONUMBER		3
define	OCMD_OPCOLORMARK	4
define	OCMD_OSCOLORMARK	5
define	OCMD_OSIZEMARK		6
define	OCMD_OTOLERANCE		7

define	OCMD_OX			8
define	OCMD_OY			9
define	OCMD_OGEOMETRY		10
define	OCMD_OAPERTURES		11
define	OCMD_OAXRATIO		12
define	OCMD_OPOSANG		13
define	OCMD_OVERTICES		14

define	OCMD_OSX		15
define	OCMD_OSY		16
define	OCMD_OSGEOMETRY		17
define	OCMD_OSRIN		18
define	OCMD_OSROUT		19
define	OCMD_OSAXRATIO		20
define	OCMD_OSPOSANG		21
define	OCMD_OSVERTICES		22

define	OCMD_OSELECT		23
define	OCMD_ODELETE		24
define	OCMD_OUNDELETE		25
define	OCMD_OADD		26
define	OCMD_OSAVE		27

# define the object list reading mode

define	RLIST_NEW		1
define	RLIST_APPENDONE		2
define	RLIST_TEMP		3
#define	RLIST_REPLACE		4

# miscellaneous

define	MAX_NOBJ_VERTICES	100
define	MAX_NOBJ_APERTURES	100

define	MAX_NOBJECTPARS		15
define	MAX_SZOBJECTPAR		60
