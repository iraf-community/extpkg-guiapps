# LIDS - Line identifications

define	LID_SZLINE	99			# Size of strings
define	LID_SZPROF	11			# Size of profile string

# Collection of lines
define	LID_NLINES	Memi[$1]		# Number of lines
define	LID_LID		Memi[$1+1]		# Current line
define	LID_LINES	Memi[$1+1+$2]		# Array of line pointers

# Individual lines
define	LID_LEN		178
define	LID_ITEM	Memi[$1]		# Item number
define	LID_DRAW	Memi[$1+2]		# Draw line id?
define	LID_X		Memd[P2D($1+4)]		# X coordinate (measured)
define	LID_REF		Memd[P2D($1+6)]		# Ref coordinate value
define	LID_LOW		Memd[P2D($1+8)]		# Lower limit
define	LID_UP		Memd[P2D($1+10)]		# Upper limit
define	LID_LABEL	Memc[P2C($1+12)]	# Label (99)
define	LID_LLINDEX	Memi[$1+62]		# Line list index
define	LID_LABY	Memd[P2D($1+64)]	# Y label coordinate (NDC)
define	LID_LABTICK	Memi[$1+66]		# Draw tick?
define	LID_LABARROW	Memi[$1+67]		# Draw arrow?
define	LID_LABBAND	Memi[$1+68]		# Draw bandpass?
define	LID_LABX	Memi[$1+69]		# Label with measured?
define	LID_LABREF	Memi[$1+70]		# Label with reference?
define	LID_LABID	Memi[$1+71]		# Label with ID?
define	LID_LABCOL	Memi[$1+72]		# Label color
define	LID_LABFMT	Memc[P2C($1+73)]	# Label format (99)
define	MOD_FIT		Memi[$1+123]		# Fit flag
define	MOD_SUB		Memi[$1+124]		# Model subtracted?
define	MOD_DRAW	Memi[$1+125]		# Draw model?
define	MOD_PDRAW	Memi[$1+126]		# Draw profile?
define	MOD_SDRAW	Memi[$1+127]		# Draw sum?
define	MOD_CDRAW	Memi[$1+128]		# Draw continuum?
define	MOD_PCOL	Memi[$1+129]		# Profile color
define	MOD_SCOL	Memi[$1+130]		# Sum color
define	MOD_CCOL	Memi[$1+131]		# Continuum color
define	MOD_PROF	Memc[P2C($1+132)]	# Profile type string (11)
define	MOD_TYPE	Memi[$1+138]		# Profile type code
define	MOD_X1		Memd[P2D($1+140)]	# Fitting region
define	MOD_X2		Memd[P2D($1+142)]	# Fitting region
define	MOD_A		Memd[P2D($1+144)]	# Continuum at line center
define	MOD_B		Memd[P2D($1+146)]	# Continum slope at line center
define	MOD_X		Memd[P2D($1+148)]	# Profile center
define	MOD_Y		Memd[P2D($1+150)]	# Profile peak
define	MOD_G		Memd[P2D($1+152)]	# Profile GFWHM
define	MOD_L		Memd[P2D($1+154)]	# Profile LFWHM
define	MOD_F		Memd[P2D($1+156)]	# Profile Flux
define	MOD_E		Memd[P2D($1+158)]	# Profile Eq. Width
define	EQW_B		Memd[P2D($1+158)+$2]	# Equivalent width bandpass (2)
define	EQW_X		Memd[P2D($1+162)+$2]	# Equivalent width center (2)
define	EQW_F		Memd[P2D($1+166)+$2]	# Equivalent width flux (2)
define	EQW_C		Memd[P2D($1+170)+$2]	# Equivalent width continuum (2)
define	EQW_E		Memd[P2D($1+174)+$2]	# Equivalent width (2)

# SPTMODEL.H -- Line fitting model data structures.

#define	LEN_MODS	(20+$1)			# Length of main structure
#define	MOD_PARS	Memi[$1+$2-1]		# Model parameters (12)
#define	MOD_WIDTH	Memr[$1+12]		# Default fitting width
#define	MOD_COLOR	Memi[$1+13]		# Model plotting color
#define	MOD_NSUB	Memi[$1+14]		# Number of pixel subsamples
#define	MOD_MCN		Memi[$1+15]		# Number of Monte-Carlo samples
#define	MOD_MCP		Memr[$1+16]		# Done interval (percent)
#define	MOD_MCSIG	Memr[$1+17]		# Error sigma sample (percent)
#define	MOD_NLINES	Memi[$1+18]		# Number of lines
#define	MOD_LINES	Memi[$1+$2+19]		# Model lines (0 = default)

#define	LEN_MOD		20			# Length of line description
#define	MOD_ID		Memi[$1]		# Group ID
#define	MOD_TYPE	Memi[$1+1]		# Model type
#define	MOD_SUB		Memi[$1+2]		# Model subtracted?
#define	MOD_X1		Memd[P2D($1+4)]		# Fitting region
#define	MOD_X2		Memd[P2D($1+6)]		# Fitting region
#define	MOD_A		Memd[P2D($1+8)]		# Continuum at line center
#define	MOD_B		Memd[P2D($1+10)]	# Continum slope at line center
#define	MOD_X		Memd[P2D($1+12)]	# Line center
#define	MOD_Y		Memd[P2D($1+14)]	# Line peak
#define	MOD_G		Memd[P2D($1+16)]	# Line GFWHM
#define	MOD_L		Memd[P2D($1+18)]	# Line LFWHM

define	LEN_MODITEM	66			# Length of model list item


# Label y types
define	LID_YTSNDC	0	# NDC offset from spectrum
define	LID_YTSABS	1	# Coordinate offset from spectrum
define	LID_YTGNDC	2	# NDC offset from bottom of graph
define	LID_YTABS	3	# Absolute coordinate

# Profile types.
define  PTYPES		"|gaussian|lorentzian|voigt|"
define  GAUSS           1       # Gaussian profile
define  LORENTZ         2       # Lorentzian profile
define  VOIGT           3       # Voigt profile

# Elements of fit array.
define  BKG             1       # Background
define  POS             2       # Position
define  INT             3       # Intensity
define  GAU             4       # Gaussian FWHM
define  LOR             5       # Lorentzian FWHM

# Type of constraints.
define  FIXED           1       # Fixed parameter
define  SINGLE          2       # Fit a single value for all lines
define  INDEP           3       # Fit independent values for all lines
