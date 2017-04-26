# The private defintions file for the XPHOT task contour plotting substructure.

define	LEN_PCONTOUR	(20)

# the contour plotting substructure

define	XP_ENX			Memi[$1]
define	XP_ENY			Memi[$1+1]
define	XP_EZ1			Memr[P2R($1+2)]
define	XP_EZ2			Memr[P2R($1+3)]
define	XP_EZ0			Memr[P2R($1+4)]
define	XP_ENCONTOURS		Memi[$1+5]
define	XP_EDZ			Memr[P2R($1+6)]
define	XP_EHILOMARK		Memi[$1+7]
define	XP_EDASHPAT		Memi[$1+8]
define	XP_ELABEL		Memi[$1+9]
define	XP_EBOX			Memi[$1+10]
define	XP_ETICKLABEL		Memi[$1+11]
define	XP_EXMAJOR		Memi[$1+12]
define	XP_EXMINOR		Memi[$1+13]
define	XP_EYMAJOR		Memi[$1+14]
define	XP_EYMINOR		Memi[$1+15]
define	XP_EROUND		Memi[$1+16]
define	XP_EFILL		Memi[$1+17]

# the default contour plotting parameter values

define	DEF_ENX			31
define	DEF_ENY			31
define	DEF_EZ1			INDEFR
define	DEF_EZ2			INDEFR
define	DEF_EZ0			INDEFR
define	DEF_EDZ			INDEFR
define	DEF_ENCONTOURS		5
define	DEF_EHILOMARK		1		# (none)
define	DEF_EDASHPAT		528
define	DEF_ELABEL		NO
define	DEF_EBOX		NO
define	DEF_ETICKLABEL		NO
define	DEF_EXMAJOR		5
define	DEF_EXMINOR		0
define	DEF_EYMAJOR		5
define	DEF_EYMINOR		0
define	DEF_EROUND		NO
define	DEF_EFILL		NO
