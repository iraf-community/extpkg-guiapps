# The private defintions file for the XPHOT task surface plotting substructure.

define	LEN_PSURFACE	(20)

# the contour plotting substructure

define	XP_ASNX			Memi[$1]
define	XP_ASNY			Memi[$1+1]
define	XP_ALABEL		Memi[$1+2]
define	XP_AZ1			Memr[P2R($1+3)]
define	XP_AZ2			Memr[P2R($1+4)]
define	XP_ANGH			Memr[P2R($1+5)]
define	XP_ANGV			Memr[P2R($1+6)]

# the default contour plotting parameter values

define	DEF_ASNX		31
define	DEF_ASNY		31
define	DEF_ALABEL		NO
define	DEF_AZ1			INDEFR
define	DEF_AZ2			INDEFR
define	DEF_ANGH		-33.0
define	DEF_ANGV		 25.0
