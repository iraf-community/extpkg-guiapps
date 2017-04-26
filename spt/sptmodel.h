# SPTMODEL.H -- Line fitting model data structures.

define	LEN_MODS	(20+$1)			# Length of main structure
define	MOD_PARS	Memi[$1+$2-1]		# Model parameters (12)
define	MOD_WIDTH	Memr[P2R($1+12)]	# Default fitting width
define	MOD_COLOR	Memi[$1+13]		# Model plotting color
define	MOD_NSUB	Memi[$1+14]		# Number of pixel subsamples
define	MOD_MCN		Memi[$1+15]		# Number of Monte-Carlo samples
define	MOD_MCP		Memr[P2R($1+16)]	# Done interval (percent)
define	MOD_MCSIG	Memr[P2R($1+17)]	# Error sigma sample (percent)
define	MOD_NLINES	Memi[$1+18]		# Number of lines
define	MOD_LINES	Memi[$1+$2+19]		# Model lines (0 = default)

define	LEN_MOD		20			# Length of line description
define	MOD_ID		Memi[$1]		# Group ID
define	MOD_TYPE	Memi[$1+1]		# Model type
define	MOD_SUB		Memi[$1+2]		# Model subtracted?
define	MOD_X1		Memd[P2D($1+4)]		# Fitting region
define	MOD_X2		Memd[P2D($1+6)]		# Fitting region
define	MOD_A		Memd[P2D($1+8)]		# Continuum at line center
define	MOD_B		Memd[P2D($1+10)]	# Continum slope at line center
define	MOD_X		Memd[P2D($1+12)]	# Line center
define	MOD_Y		Memd[P2D($1+14)]	# Line peak
define	MOD_G		Memd[P2D($1+16)]	# Line GFWHM
define	MOD_L		Memd[P2D($1+18)]	# Line LFWHM

define	LEN_MODITEM	66			# Length of model list item


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
