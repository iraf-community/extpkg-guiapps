# LABELS - Labels

define	LAB_SZLINE	99			# Size of strings

# Collection of labels
define	LAB_NLABELS	Memi[$1]		# Number of labels
define	LAB_LABELS	Memi[$1+$2]		# Array of label pointers

# Individual labels
define	LAB_LEN		108
define	LAB_ITEM	Memi[$1]		# Item
define	LAB_DRAW	Memi[$1+1]		# Draw label?
define	LAB_X		Memd[P2D($1+2)]		# X coordinate
define	LAB_Y		Memd[P2D($1+4)]		# Y coordinate
define	LAB_LABEL	Memc[P2C($1+6)]		# Label
define	LAB_TYPE	Memi[$1+56]		# WCS type
define	LAB_COL		Memi[$1+57]		# Label color
define	LAB_FMT		Memc[P2C($1+58)]	# Label format
