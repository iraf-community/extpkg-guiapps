include "pstools.h"


# PS_OPEN -- Initialize the PSTOOLS structure.

pointer procedure ps_open (fd, default_footer)

int	fd					#i output file descriptor
int	default_footer				#i option flags

pointer	ps
int	scale
char	page[SZ_FNAME]

int	envgets(), strcmp()

define	PSPAGE_ENV	"pspage"

begin
	# Allocate the structure.
	iferr {
	    call calloc (ps, LEN_PSSTRUCT, TY_STRUCT)

	    call calloc (PS_HLE(ps), SZ_WORD, TY_CHAR)
	    call calloc (PS_HCE(ps), SZ_WORD, TY_CHAR)
	    call calloc (PS_HRE(ps), SZ_WORD, TY_CHAR)
	    call calloc (PS_FLE(ps), SZ_WORD, TY_CHAR)
	    call calloc (PS_FCE(ps), SZ_WORD, TY_CHAR)
	    call calloc (PS_FRE(ps), SZ_WORD, TY_CHAR)
	
	    call calloc (PS_WBPTR(ps), SZ_LINE, TY_CHAR)
	} then
	    call error (0, "Error allocating PSTOOLS pointer.")

	# Set the output file descriptor
	PS_FD(ps) = fd


	# Initialize default values of the struct.
	
	if (envgets (PSPAGE_ENV, page, SZ_FNAME) != 0) {
	    call strlwr (page)
	    if (strcmp (page, "letter") != 0)
	        call ps_page_size (ps, PAGE_LETTER)
	    else if (strcmp (page, "legal") != 0)
	        call ps_page_size (ps, PAGE_LEGAL)
	    else if (strcmp (page, "a4") != 0)
	        call ps_page_size (ps, PAGE_A4)
	    else if (strcmp (page, "b5") != 0)
	        call ps_page_size (ps, PAGE_B5)
	} else
	    call ps_page_size (ps, PAGE_LETTER)

	PS_FONTSZ(ps)	= FONT_SIZE		# default font size
	PS_JUSTIFY(ps)	= YES			# justify text?

	# Set the margin values.
	scale = PPI * RESOLUTION
	PS_PLMARGIN(ps)	= LMARGIN * scale	# perm. L margin     (points)
	PS_PRMARGIN(ps)	= RMARGIN * scale	# perm. R margin     (points)
	PS_PTMARGIN(ps)	= TMARGIN * scale	# perm. T margin     (points)
	PS_PBMARGIN(ps)	= BMARGIN * scale	# perm. B margin     (points)

	PS_CLMARGIN(ps)	= PS_PLMARGIN(ps)	# current L margin   (points)
	PS_CRMARGIN(ps)	= PS_PRMARGIN(ps)	# current R margin   (points)

	# Set the right margin in pixel coords.
	PS_CRMPOS(ps)   = (PS_PWIDTH(ps) * RESOLUTION) - PS_CRMARGIN(ps)
	PS_PRMPOS(ps)   = PS_CRMPOS(ps)
	PS_CURPOS(ps)   = PS_PLMARGIN(ps)

	PS_LMARGIN(ps)	= LMARGIN		# page left margin   (inches)
	PS_RMARGIN(ps)	= RMARGIN		# page right margin  (inches)
	PS_TMARGIN(ps)	= TMARGIN		# page top margin    (inches)
	PS_BMARGIN(ps)	= BMARGIN		# page bottom margin (inches)

	PS_XPOS(ps)	= PS_PLMARGIN(ps)
	PS_YPOS(ps)	= (RESOLUTION * PS_PHEIGHT(ps)) - PS_PTMARGIN(ps)

	PS_CFONT(ps)	= F_ROMAN		# font initializations
	PS_PFONT(ps)	= F_ROMAN
	PS_SFONT(ps)	= NULL
	PS_CFONT_CH(ps)	= 'R'
	PS_SFONT_CH(ps)	= EOS

	# Compute the width of the line.
	PS_LINE_WIDTH(ps) = (PS_PWIDTH(ps) * RESOLUTION) - 
	  			PS_PLMARGIN(ps) - PS_PRMARGIN(ps) 

	# Set the footer flags.
	PS_PNUM(ps) = 1
	PS_NUMBER(ps) = YES
	if (default_footer == YES) {
	    call strcpy ("NOAO/IRAF", FLEDGE(ps), SZ_WORD)
	    call clgstr ("cl.version", FCENTER(ps), SZ_WORD)
	} 

	if (PS_DEBUG)
	    call ps_opndbg (ps)

	return (ps)
end


procedure ps_opndbg (ps)
pointer	ps
begin
    call eprintf ("page: w=%d h=%d orient=%d page=%d font=%d\n")
        call pargi(PS_PWIDTH(ps)) 	; call pargi(PS_PHEIGHT(ps))
        call pargi(PS_PAGE(ps))		; call pargi(PS_FONTSZ(ps))
    call eprintf ("margins: pl=%d pr=%d pt=%d pb=%d cl=%d cr=%d\n")
        call pargi(PS_PLMARGIN(ps)) ; call pargi(PS_PRMARGIN(ps))
        call pargi(PS_PTMARGIN(ps)) ; call pargi(PS_PBMARGIN(ps))
        call pargi(PS_CLMARGIN(ps)) ; call pargi(PS_CRMARGIN(ps))
    call eprintf ("page margins: l=%d r=%d t=%d b=%d\n")
        call pargr(PS_LMARGIN(ps)) ; call pargr(PS_RMARGIN(ps))
        call pargr(PS_TMARGIN(ps)) ; call pargr(PS_BMARGIN(ps))
    call eprintf ("line_width: %d\n") ; call pargi(PS_LINE_WIDTH(ps))
end
