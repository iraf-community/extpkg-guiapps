# RV -- Radial velocity data structure

define	VLIGHT	2.997925e5	# Speed of light, km/s
define	SPT_OBSLEN	399

define	SPT_RVLEN	210
define	RV_UN		Memi[$1]		# RV units
define	SPT_RVN		Memi[$1+1]		# Number of lines used
define	SPT_REDSHIFT	Memd[P2D($1+2)]		# Redshift
define	SPT_RMSRED	Memd[P2D($1+4)]		# RMS of redshift
define	SPT_ZHELIO	Memd[P2D($1+6)]		# Helocentric Z
define	SPT_HJD		Memd[P2D($1+8)]		# Helocentric Julian date
define	SPT_RVOBS	Memc[P2C($1+10)]	# Observatory log string

define	REG_REDSHIFT	SPT_REDSHIFT(REG_RV($1))
