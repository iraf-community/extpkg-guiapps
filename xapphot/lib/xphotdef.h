# Private definitions file for the XAPPHOT package

# The principal XAPPHOT data structure

define	LEN_XPHOT	(18 + 2 * SZ_PATHNAME + 8 * SZ_FNAME + 10)

define	XP_PIMPARS	Memi[$1]    # pointer to image data structure
define	XP_PIMDISPLAY	Memi[$1+1]  # pointer to image display structure
define	XP_PFIND	Memi[$1+2]  # pointer to the object detection structure
define	XP_POBJECTS	Memi[$1+3]  # pointer to the object marking structure
define	XP_PCENTER	Memi[$1+4]  # pointer to centering structure
define	XP_PSKY		Memi[$1+5]  # pointer to sky fitting structure
define	XP_PPHOT	Memi[$1+6]  # pointer to photometry structure
define	XP_PCONTOUR	Memi[$1+7]  # pointer to contour plotting structure
define	XP_PSURFACE	Memi[$1+8]  # pointer to surface plotting structure

define	XP_IMNUMBER	Memi[$1+9]  # the current image number
define	XP_OFNUMBER	Memi[$1+10] # the current list number
define	XP_RFNUMBER	Memi[$1+11] # the current output number
define	XP_GFNUMBER	Memi[$1+12] # the current output number

define	XP_SEQNOLIST	Memi[$1+14] # the sequence number symbol table
define	XP_PSTATUS	Memi[$1+15] # the pointer to the status array

define	XP_IMTEMPLATE	Memc[P2C($1+16)]              # image name template
define	XP_OFTEMPLATE	Memc[P2C($1+16+1*SZ_FNAME+1)] # object list template
define	XP_RFTEMPLATE	Memc[P2C($1+16+2*SZ_FNAME+2)] # results list template
define	XP_GFTEMPLATE	Memc[P2C($1+16+3*SZ_FNAME+3)] # geometry list template

define	XP_IMAGE	Memc[P2C($1+16+4*SZ_FNAME+4)] # input image
define	XP_OBJECTS	Memc[P2C($1+16+5*SZ_FNAME+5)] # input coordinate file
define	XP_RESULTS	Memc[P2C($1+16+6*SZ_FNAME+6)] # output results file
define	XP_GRESULTS	Memc[P2C($1+16+7*SZ_FNAME+7)] # output geometry file
define	XP_STARTDIR	Memc[P2C($1+16+8*SZ_FNAME+8)] # starting directory
define	XP_CURDIR	Memc[P2C($1+16+8*SZ_FNAME+SZ_PATHNAME+9)] # starting directory

# Some internal constants 

define	XP_NSTATUS	15
