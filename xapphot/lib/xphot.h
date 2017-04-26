# Public definitions file for the XAPPHOT package

# define the XPHOT parameters common to all tasks (#1 - #100)

define	STARTDIR	1	# the starting directory
define	CURDIR		2	# the current directory
define	IMTEMPLATE	3	# the image template
define	OFTEMPLATE	4	# the coordinate list template
define	RFTEMPLATE	5	# the results list template
define	GFTEMPLATE	6	# the out geometry results list template

define	IMAGE		7	# the input image name
define	OBJECTS		8	# the input coordinate list
define	RESULTS		9	# the output results list
define	GRESULTS	10	# the output geometry results list

define	IMNUMBER	11	# the input image sequence number
define	OFNUMBER	12	# the input list sequence number
define	RFNUMBER	13	# the output list sequence number
define	GFNUMBER	14	# the output geometry list sequence number

define	PIMDISPLAY	15	# pointer to the image display structure
define	PIMPARS		16	# pointer to the image data structure
define	PFIND		17	# pointer to the object detection structure
define	POBJECTS	18	# pointer to the objects structure
define	PCENTER		19	# pointer to the centering structure
define	PSKY		20	# pointer to the sky fitting structure
define	PPHOT		21	# pointer to the photometry structure
define	PCONTOUR	22	# pointer to the contour plotting structure
define	PSURFACE	23	# pointer to the surface plotting structure

define	SEQNOLIST	24	# the sequence number symbol table
define	PSTATUS		25	# the pointer to the status array

# define the object sequence list structure

define	LEN_SEQNOLIST_STRUCT	2

define	XP_MAXSEQNO		Memi[$1]

define	DEF_LEN_SEQNOLIST	100

# define the structure of the XAPPHOT status return array

define	NEWIMAGE		Memi[$1+0]     # process a new image ?
define	NEWLIST			Memi[$1+1]     # process a new object file ?
define	NEWRESULTS		Memi[$1+2]     # start a new results file ?
define	REDISPLAY		Memi[$1+3]     # redisplay the image ?
define	OBJNO			Memi[$1+4]     # the current object number
define	NEWCBUF			Memi[$1+5]     # load new centering data ?
define	NEWCENTER		Memi[$1+6]     # compute a new center ?
define	NEWSBUF			Memi[$1+7]     # load new sky fitting data ?
define	NEWSKY			Memi[$1+8]     # compute a new sky value ?
define	NEWMBUF			Memi[$1+9]     # load new photometry data ?
define	NEWMAG			Memi[$1+10]    # compute a new magnitude ?
define	LOGRESULTS		Memi[$1+11]    # log the results ?
define	SEQNO			Memi[$1+12]    # the results sequence number

# define XAPPHOT image and file manipulation colon commands common to all tasks

define	FCMDS	"|startdir|chdir|setdir|images|imname|imnumber|objects|olname|\
olnumber|results|rlname|rlnumber|robjects|glname|glnumber|logresults|"

define	FCMD_STARTDIR	1
define	FCMD_CHDIR	2
define	FCMD_SETDIR	3
define	FCMD_IMTEMPLATE	4
define	FCMD_IMAGE	5
define	FCMD_IMNUMBER	6
define	FCMD_OFTEMPLATE	7
define	FCMD_OBJECTS	8
define	FCMD_OFNUMBER	9
define	FCMD_RFTEMPLATE	10
define	FCMD_RESULTS	11
define	FCMD_RFNUMBER	12
define	FCMD_GFTEMPLATE	13
define	FCMD_GRESULTS	14
define	FCMD_GFNUMBER	15
define	FCMD_LOGRESULTS	16

# define XAPPHOT pset manipulation colon command subsets.

define	AUCMDS	"|unlearn|lpar|epar||update|"
define	UUCMDS	"|unlearn|||save|update|"

define	UCMD_UNLEARN		1
define	UCMD_LPAR		2
define	UCMD_EPAR		3
define	UCMD_SAVE		4
define	UCMD_UPDATE		5

# XAPPHOT object geometry commands.

define	GEOCMDS	"|spgeometry|"

define	GCMD_SPGEOMETRY		1

# define the XAPPHOT pset subsets.

define	DPSETS	"|dispars|impars||||cplotpars|omarkpars|findpars|splotpars|"
define	CPSETS	"|dispars|impars|cenpars|||cplotpars|omarkpars|findpars|\
splotpars|"
define	SPSETS	"|dispars|impars||skypars||cplotpars|omarkpars|findpars|\
splotpars|"
define	APSETS	"|dispars|impars|cenpars|skypars|photpars|cplotpars|\
omarkpars|findpars|splotpars|"

define	PSET_DISPARS		1
define	PSET_IMPARS		2
define	PSET_CENPARS		3
define	PSET_SKYPARS		4
define	PSET_PHOTPARS		5
define	PSET_EPLOTPARS		6
define	PSET_OMARKPARS		7
define	PSET_FINDPARS		8
define	PSET_APLOTPARS		9
