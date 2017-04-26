# The UI parameters definitions file

define	SZ_UIPARAM	15

define	LEN_UI_STRUCT 	(16 + 55 * (SZ_UIPARAM + 1) / 2)

define	UI_SHOWHELP		Memi[$1]      # Display the help panel ?
define	UI_SHOWFILES		Memi[$1+1]    # Display the files panel ?
define	UI_SHOWHEADER		Memi[$1+2]    # Display the header panel ?
define	UI_SHOWOBJLIST		Memi[$1+3]    # Display the objects list panel ?
define	UI_SHOWMPLOTS		Memi[$1+4]    # Display the model fit panel ?
define	UI_SHOWPTABLE		Memi[$1+5]    # Display the table panel ?
define	UI_SHOWPLOTS		Memi[$1+6]    # Display the plots panel ?
define	UI_OBJDISPLAY		Memi[$1+7]    # The default object region plot
define	UI_SKYDISPLAY		Memi[$1+8]    # The default sky region plot
define	UI_OBJPLOTS		Memi[$1+9]    # The default object analysis plot
define	UI_SKYPLOTS		Memi[$1+10]   # The default sky analysis plot

define	UI_STARTDIRSTR		Memc[P2C($1+16)]   # The image template 
define	UI_CURDIRSTR		Memc[P2C($1+24)]   # The image template 
define	UI_DIRLISTSTR		Memc[P2C($1+32)]   # The image list 

define	UI_IMTEMPLATESTR	Memc[P2C($1+40)]   # The image template 
define	UI_IMLISTSTR		Memc[P2C($1+48)]   # The image list 
define	UI_IMNO			Memc[P2C($1+56)]   # The image number

define	UI_OFTEMPLATESTR	Memc[P2C($1+64)]   # The objects template
define	UI_OLLISTSTR		Memc[P2C($1+72)]   # The objects file list
define	UI_OFNO			Memc[P2C($1+80)]   # The objects file number

define	UI_RFTEMPLATESTR	Memc[P2C($1+88)]   # The results template
define	UI_RFFILE		Memc[P2C($1+96)]   # The results file
define	UI_RFNO			Memc[P2C($1+104)]   # The results file number

define	UI_GFTEMPLATESTR	Memc[P2C($1+112)]   # The robjects template
define	UI_GFFILE		Memc[P2C($1+120)]   # The robjects file name
define	UI_GFNO			Memc[P2C($1+128)]  # The robjects file number

define	UI_IMPARS		Memc[P2C($1+136)]  # The impars parameters
define	UI_DISPARS		Memc[P2C($1+144)]  # The dispars parameters
define	UI_FINDPARS		Memc[P2C($1+152)]  # The findpars parameters
define	UI_OMARKPARS		Memc[P2C($1+160)]  # The omarkpars parameters
define	UI_CENPARS		Memc[P2C($1+168)]  # The cenpars parameters
define	UI_SKYPARS		Memc[P2C($1+176)]  # The skypars parameters
define	UI_PHOTPARS		Memc[P2C($1+184)]  # The photpars parameters
define	UI_EPLOTPARS		Memc[P2C($1+192)]  # The contouring parameters
define	UI_APLOTPARS		Memc[P2C($1+200)]  # The mesh plot parameters

define	UI_FILES		Memc[P2C($1+208)]  # Display the files panel ?
define	UI_HEADER		Memc[P2C($1+216)]  # Display the header panel ?
define	UI_HDRLIST		Memc[P2C($1+224)]  # The current image header

define	UI_OBJECTS		Memc[P2C($1+232)]  # Display the list panel ?
define	UI_OBJLIST		Memc[P2C($1+240)]  # The current object list
define	UI_OBJNO		Memc[P2C($1+248)]  # The current object number
define	UI_OBJMARKER		Memc[P2C($1+256)]  # the current object geometry

define	UI_PPOLYGON		Memc[P2C($1+264)]  # The object polygon
define	UI_S1POLYGON		Memc[P2C($1+272)]  # The inner sky polygon
define	UI_S2POLYGON		Memc[P2C($1+280)]  # The outer sky polygon

define	UI_PLOTS		Memc[P2C($1+288)]
define	UI_MPLOTS		Memc[P2C($1+296)]
define	UI_GTERM		Memc[P2C($1+304)]
define	UI_CURSOR		Memc[P2C($1+312)]

define	UI_LOGRESULTS		Memc[P2C($1+320)]  # Record the results ?
define	UI_RESULTS              Memc[P2C($1+328)]  # Display photometry table ?
define	UI_PBANNER		Memc[P2C($1+336)]  # The photometry table banner
define	UI_PTABLE		Memc[P2C($1+344)]  # The last table measurment
define	UI_POBJECT		Memc[P2C($1+352)]  # The last object measurement

define	UI_HELP			Memc[P2C($1+360)]  # Display the help panel ?
define	UI_HELPLIST		Memc[P2C($1+368)]  # The help string

define	UI_TUTOR		Memc[P2C($1+376)]  # Display the tutor panel ?
define	UI_TUTORLIST		Memc[P2C($1+384)]  # The tutorial string

define	UI_MREDRAW		Memc[P2C($1+392)]  # Redraw active markers ?
define	UI_REDISPLAY		Memc[P2C($1+400)]  # Need to redisplay image ?


# The plot types.

define	UI_VIMAGEPLOT		"imageplot"
define	UI_VMODELPLOT		"modelplot"
define	UI_VOBJECTPLOT		"objectplot"
define	UI_VSKYPLOT		"skyplot"
define	UI_VOBJREGIONPLOT	"objregionplot"
define	UI_VSKYREGIONPLOT	"skyregionplot"
