# Public object detection parameter definitions file

# find parameters (# 201 - 300)

define	FTHRESHOLD	       201
define	FRADIUS		       202
define	FSEPMIN		       203
define	FROUNDLO	       204
define	FROUNDHI	       205
define	FSHARPLO	       206
define	FSHARPHI	       207

# find string commands

define	LCMDS	"|fthreshold|fradius|fsepmin|froundlo|froundhi|fsharplo|\
fsharphi|"
define	ULCMDS		"|counts|hwhm|hwhm|||||"
define	HLCMDS		"|counts|hwhm|hwhm|number|number|number|number|"

define	LCMD_FTHRESHOLD		1
define	LCMD_FRADIUS		2
define	LCMD_FSEPMIN		3
define	LCMD_FROUNDLO		4
define	LCMD_FROUNDHI		5
define	LCMD_FSHARPLO		6
define	LCMD_FSHARPHI		7

define	MAX_NFINDPARS	10
define	MAX_SZFINDPAR	60
define	DEF_NYBLOCK	256


# define the gaussian sums structure

define  LEN_GAUSS               10

define  GAUSS_SUMG              1
define  GAUSS_SUMGSQ            2
define  GAUSS_PIXELS            3
define  GAUSS_DENOM             4
define  GAUSS_SGOP              5

# miscellaneous constants

define  HWHM_TO_SIGMA           0.8493218
define  RMIN                    2.001
