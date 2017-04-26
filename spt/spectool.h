# SPECTOOL - Spectrum Examination and Analysis Tool

define	SPT_SZLINE	99			# Size of string lines
define	SPT_SZSTRING	999			# Size of SPT_STRING
define	SPT_SZTYPE	9			# Size of colors and mark types
define	SPT_REGALLOC	26			# Initial and block alloc size

# Global structure
define	SPT_LEN		1816			# Length of SPT structure
define	SPT_FNT		Memi[$1]		# Image template pointer
define	SPT_IMIMT	Memi[$1+1]		# Image template pointer
define	SPT_IMLIST	Memi[$1+2]		# Pointer to image list
define	SPT_IMLEN	Memi[$1+3]		# Length of image list
define	SPT_SPLIST	Memi[$1+4]		# Pointer to spectrum list
define	SPT_SPLEN	Memi[$1+5]		# Length of spectrum list
define	SPT_RGLIST	Memi[$1+6]		# Pointer to register list
define	SPT_RGLEN	Memi[$1+7]		# Length of register list
define	SPT_NREG	Memi[$1+8]		# Number of registers
define	SPT_REGS	Memi[$1+9]		# Pointer to registers
define	SPT_CREG	Memi[$1+10]		# Current register
define	SPT_CTYPE	Memi[$1+11]		# Current spectrum type
define	SPT_STYPE	Memi[$1+12]		# Spectum type to operate on
define	SPT_WCSPTR	Memi[$1+$2+12]		# WCS pointers (3)
define	SPT_WCS		Memi[$1+16]		# Current WCS
define	SPT_GUI		Memi[$1+17]		# GUI?
define	SPT_GP		Memi[$1+18]		# GIO pointer
define	SPT_GT		Memi[$1+19]		# GTOOLS pointer
define	SPT_PLOT	Memi[$1+$2+19]		# Spectrum types to plot (6)
define	SPT_FINDER	Memi[$1+26]		# Finder graph?
define	SPT_ERRCLEAR	Memi[$1+27]		# Clear errors?
define	SPT_SPEC	Memi[$1+28]		# Pointer to spectrum buffer
define	SPT_SN		Memi[$1+29]		# Length of spectrum buffer
define	SPT_LCLIP	Memr[P2R($1+30)]	# Low clipping factor
define	SPT_HCLIP	Memr[P2R($1+31)]	# High clipping factor
define	SPT_SCALE	Memi[$1+32]		# Scale type
define	SPT_OFFSET	Memi[$1+33]		# Offset type
define	SPT_PMODE	Memi[$1+34]		# Plot mode
define	SPT_PMODE1	Memi[$1+35]		# Previous plot mode
define	SPT_STACKTYPE	Memi[$1+36]		# Stacking type
define	SPT_STACKSTEP	Memr[P2R($1+37)]	# Stacking step
define	SPT_STACKPLOT	Memi[$1+38]		# Stacking plot type
define	SPT_STACKCOL	Memi[$1+39]		# Stacking color
define	SPT_LOGFD	Memi[$1+40]		# Backup log file descriptor
#define	SPT_MODEL	Memi[$1+41]		# Line fitting models
define	SPT_REDRAW	Memi[$1+$2+41]		# Redraw flags (2)
define	SPT_NSUM	Memi[$1+$2+43]		# Nsum (2)
define	SPT_COLOR	Memi[$1+46]		# Default color
define	SPT_ZERO	Memi[$1+47]		# Force zero in window?
define	SPT_ERRORS	Memi[$1+48]		# Compute errors?
define	SPT_ERRMCN	Memi[$1+49]		# Number of Monte-Carlo samples
define	SPT_ERRMCSIG	Memr[P2R($1+50)]	# Random number seed
define	SPT_ERRMCSEED	Memi[$1+51]		# Error sigma sample (percent)
define	SPT_ERRMCP	Memr[P2R($1+52)]	# Done interval (percent)
define	SPT_MAXREG	Memi[$1+53]		# Maximum number of registers
define	SPT_TYPE	Memc[P2C($1+60)]	# Default plot type (9)
define	SPT_ETYPE	Memc[P2C($1+65)]	# Default error plot type (9)
define	SPT_COLORS	Memc[P2C($1+$2*10+70)]	# Colors (10*9)
define	SPT_STARTDIR	Memc[P2C($1+170)]	# Starting directory
define	SPT_DIR		Memc[P2C($1+220)]	# Directory
define	SPT_FTMP	Memc[P2C($1+270)]	# File template
define	SPT_IMTMP	Memc[P2C($1+320)]	# Image template
define	SPT_APTMP	Memc[P2C($1+370)]	# Aperture range template
define	SPT_BMTMP	Memc[P2C($1+420)]	# Beam range template
define	SPT_BDTMP	Memc[P2C($1+470)]	# Band range template
define	SPT_UNKNOWN	Memc[P2C($1+520)]	# Unknown units
define	SPT_UNITS	Memc[P2C($1+570)]	# Display units
define	SPT_FUNITS	Memc[P2C($1+620)]	# Flux units
define	SPT_TITLE	Memc[P2C($1+670)]	# Title
define	SPT_XLABEL	Memc[P2C($1+720)]	# X label
define	SPT_YLABEL	Memc[P2C($1+770)]	# Y label
define	SPT_XUNITS	Memc[P2C($1+820)]	# X label units
define	SPT_YUNITS	Memc[P2C($1+870)]	# Y label units
define	SPT_OBS		Memc[P2C($1+920)]	# Observatory
define	SPT_STRING	Memc[P2C($1+970)]	# Working string

define	SPT_LABEL	Memi[$1+1501]		# Label registers?
define	SPT_LABTYPE	Memi[$1+1502]		# Default label WCS type
define	SPT_LABCOL	Memi[$1+1503]		# Default label color
define	SPT_LABFMT	Memc[P2C($1+1504)]	# Default label format

define	SPT_LIDSALL	Memi[$1+1600]		# All lines flag
define	SPT_LINES	Memi[$1+1601]		# Label registers?
define	SPT_LINELIST	Memc[P2C($1+1602)]	# Line list (99)
define	SPT_LL		Memi[$1+1652]		# Line list data
define	SPT_LLSEP	Memd[P2D($1+1654)]	# Pix sep for ll match
define	SPT_SEP		Memd[P2D($1+1656)]	# Pix sep for lines
define	SPT_DLOW	Memd[P2D($1+1658)]	# Default lower limit
define	SPT_DUP		Memd[P2D($1+1660)]	# Default upper limit
define	SPT_DPROF	Memc[P2C($1+1662)]	# Default profile (11)
define	SPT_DLABY	Memd[P2D($1+1668)]	# Default label position
define	SPT_DLABTICK	Memi[$1+1676]		# Default draw tick?
define	SPT_DLABARROW	Memi[$1+1677]		# Default draw arrow?
define	SPT_DLABBAND	Memi[$1+1678]		# Default draw bandpass?
define	SPT_DLABX	Memi[$1+1679]		# Default label with measured?
define	SPT_DLABREF	Memi[$1+1680]		# Default label with reference?
define	SPT_DLABID	Memi[$1+1681]		# Default label with ID?
define	SPT_DLABFMT	Memc[P2C($1+1682)]	# Default label format (99)
define	SPT_DLABCOL	Memi[$1+1732]		# Default label color

define	SPT_MODPLOT	Memi[$1+1733]		# Plot models?
define	SPT_MODPDRAW	Memi[$1+1734]		# Plot profiles?
define	SPT_MODPCOL	Memi[$1+1735]		# Profile plotting color
define	SPT_MODSDRAW	Memi[$1+1736]		# Plot sum?
define	SPT_MODSCOL	Memi[$1+1737]		# Sum plotting color
define	SPT_MODCDRAW	Memi[$1+1738]		# Plot continuum
define	SPT_MODCCOL	Memi[$1+1739]		# Continuum plotting color
define	SPT_MODPARS	Memi[$1+$2+1739]	# Model parameters (12)
define	SPT_MODNSUB	Memi[$1+1752]		# Number of pixel subsamples

define  SPT_CTR_CTYPE   Memc[P2C($1+1801)]	# Centering type (11)
define  SPT_CTR_PTYPE   Memc[P2C($1+1807)]	# Profile type (11)
define  SPT_CTR_WIDTH   Memr[P2R($1+1813)]	# Profile width
define  SPT_CTR_RADIUS  Memr[P2R($1+1814)]	# Centering radius
define  SPT_CTR_THRESH  Memr[P2R($1+1815)]	# Centering threshold

# Register structure
define	REG_LEN		203			# Length of register structure
define	REG_NUM		Memi[$1]		# Register number
define	REG_ID		Memi[$1+1]		# Register ID
define	REG_IDSTR	Memc[P2C($1+2)]		# Register ID str (SPT_SZTYPE)
define	REG_IMAGE	Memc[P2C($1+7)]		# Image name
define	REG_TITLE	Memc[P2C($1+57)]	# Spectrum title
define	REG_AP		Memi[$1+107]		# Aperture
define	REG_BAND	Memi[$1+108]		# Image band
define	REG_DAXIS	Memi[$1+109]		# Dispersion axis
define	REG_NSUM	Memi[$1+110]		# Summing factor
define	REG_FORMAT	Memi[$1+111]		# Spectrum format
define	REG_TYPE	Memc[P2C($1+$2*10+102)]	# Plot types (6)
define	REG_COLOR	Memi[$1+$2+172]		# Color numbers (6)
define	REG_SCALE	Memr[P2R($1+180)]	# Intensity scale
define	REG_OFFSET	Memr[P2R($1+181)]	# Intensity offset
define	REG_SSCALE	Memr[P2R($1+182)]	# Stack scale
define	REG_STEP	Memr[P2R($1+183)]	# Stack step
define	REG_SH		Memi[$1+184]		# Spectrum
define	REG_SHSAVE	Memi[$1+185]		# Save spectrum
define	REG_SHBAK	Memi[$1+187]		# Backup spectrum
define	REG_MODIFIED	Memi[$1+189]		# Spectrum modified?
define	REG_PLOT	Memi[$1+190]		# Plot spectrum?
define	REG_LABEL	Memi[$1+191]		# Plot labels?
define	REG_LINES	Memi[$1+192]		# Plot lines?
define	REG_MODPLOT	Memi[$1+193]		# Plot models?
define	REG_ITEMNO	Memi[$1+194]		# Item number in list
define	REG_FLAG	Memi[$1+195]		# Register flag
define	REG_X1		Memr[P2R($1+196)]	# Spectrum limits
define	REG_X2		Memr[P2R($1+197)]
define	REG_Y1		Memr[P2R($1+198)]
define	REG_Y2		Memr[P2R($1+199)]
define	REG_LABS	Memi[$1+200]		# Labels
define	REG_LIDS	Memi[$1+201]		# Lines
define	REG_RV		Memi[$1+202]		# RV

define	REG		Memi[SPT_REGS($1)+$2-1]
define	RGLIST		Memc[SPT_RGLIST($1)]
define	IMLIST		Memc[SPT_IMLIST($1)]
define	SPLIST		Memc[SPT_SPLIST($1)]
define	APLIST		Memc[SPT_APLIST($1)]
define	SPECT		Memr[SPT_SPEC($1)]

# Scaling options
define	SCALEOPS	"|none|mean|"
define	SCALE_NONE	1
define	SCALE_MEAN	2

# Stacking options
define	STACKTYPES	"|absolute|first range|individual ranges|"
define	STACK_ABS	1
define	STACK_RANGE	2
define	STACK_RANGES	3

# Save types
define	XSAVE		1	# Dispersion change
define	YSAVE		2	# Pixel value change
define	XYSAVE		3	# Both dispersion and pixel value change

# Plot modes
define	NOPLOT		0	# No plot
define	PLOT1		1	# Plot spectrum
define	OPLOT		2	# Overplot spectrum
define	STACK		3	# Stack spectrum

define	COLORS	"|background|foreground|red|green|blue|cyan|yellow|magenta|purple|gray|"
