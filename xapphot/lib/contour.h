# The public defintions file for the XPHOT task contour plotting substructure.

# define the hi/lo marking options

define	XP_ENONE		1
define	XP_EHILO		2
define	XP_EPIXEL		3

define	EHILOMARK_OPTIONS	"|none|hilo|pixel|"

# the contour substructure parameter definitions (# 801 - 900)

define	ENX			801
define	ENY			802
define	EZ1			803
define	EZ2			804
define	EZ0			805
define	ENCONTOURS		806
define	EDZ			807
define	EHILOMARK		808
define	EDASHPAT		809
define	ELABEL			810
define	EBOX			811
define	ETICKLABEL		812
define	EXMAJOR			813
define	EXMINOR			814
define	EYMAJOR			815
define	EYMINOR			816
define	EROUND			817
define	EFILL			818

# the display subtructure parameter editing commands

define ECMDS "|enx|eny|ez1|ez2|ez0|encontours|edz|ehilomark|\
edashpat|elabel|ebox|eticklabel|exmajor|exminor|eymajor|eyminor|eround|efill|"

define	UECMDS	"|||counts|counts|counts||||||||||||||"

define	ECMD_ENX		1
define	ECMD_ENY		2
define	ECMD_EZ1		3
define	ECMD_EZ2		4 
define	ECMD_EZ0		5
define	ECMD_ENCONTOURS		6
define	ECMD_EDZ		7
define	ECMD_EHILOMARK		8
define	ECMD_EDASHPAT		9
define	ECMD_ELABEL		10
define	ECMD_EBOX		11
define	ECMD_ETICKLABEL		12
define	ECMD_EXMAJOR		13
define	ECMD_EXMINOR		14
define	ECMD_EYMAJOR		15
define	ECMD_EYMINOR		16
define	ECMD_EROUND		17
define	ECMD_EFILL		18

# Miscellaneous

define	MAX_NCONTOURPARS		15
define	MAX_SZCONTOURPAR		60
