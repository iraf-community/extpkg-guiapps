# Private objects list parameters definitions file

define	LEN_POBJECTS		(10)

define	XP_OBJLIST	    Memi[$1]	# the symbol table containing the list
define	XP_POLYGONLIST	    Memi[$1+1]	# the symbol table containing polygons
define	XP_OTOLERANCE	    Memr[P2R($1+2)]  # the position matching tolerance
define	XP_OBJMARK	    Memi[$1+3]  # mark the objects ?
define	XP_ONUMBER	    Memi[$1+4]  # number the marked objects ?
define	XP_OCHARMARK	    Memi[$1+5]  # the objects marker
define	XP_OPCOLORMARK	    Memi[$1+6]  # the marker color
define	XP_OSCOLORMARK	    Memi[$1+7]  # the marker color
define	XP_OSIZEMARK        Memr[P2R($1+8)]  # the marker size

# default setup values for object marking parameters

define	DEF_OTOLERANCE		5.0
define	DEF_OBJMARK		YES
define	DEF_ONUMBER		NO
define	DEF_OCHARMARK		4		# (plus)
define	DEF_OPCOLORMARK		3		# (green)
define	DEF_OSCOLORMARK		2		# (blue)
define	DEF_OSIZEMARK		5.0
