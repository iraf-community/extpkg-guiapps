# The private photometry parameters definitions file

define	LEN_PPHOT		(45 + 4 * SZ_LINE + 4)

# the user photometry aperture geometry

define	XP_PGEOMETRY	Memi[$1]	# user geometry of photometry axes	
define	XP_PAXRATIO	Memr[P2R($1+1)]	# user ratio of short to long axes
define	XP_PPOSANGLE	Memr[P2R($1+2)]	# user position ange of axes
define	XP_PZMAG	Memr[P2R($1+3)]	# the magnitude zero point

# the actual photometry aperture geometry

define	XP_POGEOMETRY	Memi[$1+4]	# actual geometry of photometry axes	
define	XP_PAPERTURES	Memi[$1+5]	# the pointer to the aperture array
define	XP_NAPERTS	Memi[$1+6]	# the number of apertures
define	XP_POAXRATIO	Memr[P2R($1+7)]	# actual ratio of short to long axes
define	XP_POPOSANGLE	Memr[P2R($1+8)]	# actual position ange of axes

define	XP_PUXVER	Memi[$1+9]      # pointer to user polygon x vertices
define	XP_PUYVER	Memi[$1+10]     # pointer to user polygon y vertices
define	XP_PUNVER	Memi[$1+11]     # number of vertices

# the photometry data

define	XP_PXCUR	Memr[P2R($1+12)] # x aperture center
define	XP_PYCUR	Memr[P2R($1+13)] # y aperture center
define	XP_APIX		Memi[$1+14]	 # pointer to pixels (not used)
define	XP_XAPIX	Memi[$1+15]	 # pointer to x coords array (not used)
define	XP_YAPIX	Memi[$1+16]	 # pointer to y coords array (not used)
define	XP_NAPIX	Memi[$1+17]	 # number of pixels (not used)
define	XP_LENABUF	Memi[$1+18]	 # size of pixels buffer (not used)
define	XP_AXC		Memr[P2R($1+19)] # x center of subraster
define	XP_AYC		Memr[P2R($1+20)] # y center of subraster
define	XP_ANX		Memi[$1+21]	 # x dimension of subraster
define	XP_ANY		Memi[$1+22]	 # y dimension of subraster
define	XP_ADATAMIN	Memr[P2R($1+23)] # minimum data value in buffer
define	XP_ADATAMAX	Memr[P2R($1+24)] # maximum data value in buffer

# photometry output

define	XP_NMAXAP	Memi[$1+25]	# maximum number of apertures
define	XP_NMINAP	Memi[$1+26]	# minimum number of apertures
define	XP_AREAS	Memi[$1+27]	# pointer to areas array
define	XP_SUMS		Memi[$1+28]	# pointer to aperture sums array
define	XP_FLUX		Memi[$1+29]	# pointer to aperture flux array
define	XP_SUMXSQ	Memi[$1+30]	# pointer to aperture flux * xsq array
define	XP_SUMYSQ	Memi[$1+31]	# pointer to aperture flux * ysq array
define	XP_SUMXY	Memi[$1+32]	# pointer to aperture flux * x * y array
define	XP_MAGS		Memi[$1+33]	# pointer to magnitude array
define	XP_MAGERRS	Memi[$1+34]	# pointer to magnitude errors array
define	XP_MAXRATIOS	Memi[$1+35]	# pointer to magnitude errors array
define	XP_MPOSANGLES	Memi[$1+36]	# pointer to magnitude errors array
define	XP_MHWIDTHS	Memi[$1+37]	# pointer to magnitude errors array

# photometry aperture marking

define	XP_PHOTMARK	Memi[$1+38]	# mark the photometry apertures
define	XP_PCOLORMARK	Memi[$1+39]	# the aperture marking colors

# photometry strings

define	XP_PGEOSTRING	Memc[P2C($1+40)]             # user geometry string
define	XP_POGEOSTRING	Memc[P2C($1+40+SZ_LINE+1)]   # actual geometry string
define	XP_PAPSTRING	Memc[P2C($1+40+2*SZ_LINE+2)] # user apertures string
define	XP_POAPSTRING	Memc[P2C($1+40+3*SZ_LINE+3)] # actual apertures string

# some default defintions

define	DEF_PGEOMETRY		1		# (circle)
define	DEF_PGEOSTRING		"circle"	# (circle)
define	DEF_PAPERTURES		15.0
define	DEF_PAPSTRING		"15.0"
define	DEF_POAPSTRING		"15.0"
define	DEF_PAXRATIO		1.0
define	DEF_PPOSANGLE		0.0
define	DEF_PZMAG		25.0
define	DEF_ADATAMIN		-MAX_REAL
define	DEF_ADATAMAX		MAX_REAL
define	DEF_PHOTMARK		YES
define	DEF_PCOLORMARK		1		# (red)
