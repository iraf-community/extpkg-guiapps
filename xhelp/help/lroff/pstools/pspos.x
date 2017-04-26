include "pstools.h"


# PS_XPOS -- Set current X position on page.

procedure ps_xpos (ps, xpos)

pointer	ps					#i PSTOOLS descriptor
int	xpos					#i position

begin
	PS_XPOS(ps) = xpos
	call fprintf (PS_FD(ps), "%d H\n")
	    call pargi (PS_XPOS(ps))
end


# PS_YPOS -- Set current Y position on page.

procedure ps_ypos (ps, ypos)

pointer	ps					#i PSTOOLS descriptor
int	ypos					#i position

begin
	PS_YPOS(ps) = ypos
	call fprintf (PS_FD(ps), "%d V\n")
	    call pargi (PS_YPOS(ps))
end


# PS_INDENT -- Set current left margin defined as a number of fixed width
# characters from the permanent left margin.

procedure ps_indent (ps, nchars)

pointer	ps					#i PSTOOLS descriptor
int	nchars					#i position

begin
	PS_CLMARGIN(ps) = PS_PLMARGIN(ps) + max(0,nchars) * FIXED_WIDTH
	PS_LINE_WIDTH(ps) = (PS_PWIDTH(ps) * RESOLUTION) - 
                                PS_CLMARGIN(ps) - PS_PRMARGIN(ps) 
end


# PS_TESTPAGE -- Test whether we are within the given number of lines from
# the bottom of the page, if so break.

procedure ps_testpage (ps, nlines)

pointer	ps					#i PSTOOLS descriptor
int	nlines					#i position

int	nleft

begin
	nleft = nlines * LINE_HEIGHT * RESOLUTION
	if ((PS_YPOS(ps) - PS_PBMARGIN(ps)) < nleft)
	    call ps_pagebreak (ps)
end
