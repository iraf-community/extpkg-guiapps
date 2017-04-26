include "pstools.h"
	

# PS_CENTER -- Center the string on the page and break.

procedure ps_center (ps, str)

pointer	ps					#i PSTOOLS descriptor
char	str[ARB]				#i text string

int	mtemp, ps_centerPos()

begin
	mtemp = PS_CLMARGIN(ps)
	PS_CLMARGIN(ps) = ps_centerpos (ps, str)
	call ps_output (ps, str, NO)
	PS_CLMARGIN(ps) = mtemp
end


# PS_CENTERPOS -- Get the X position of the centered string.

int procedure ps_centerpos (ps, str)

pointer	ps					#i PSTOOLS descriptor
char    str[ARB]                             	#i string to center

int	ps_textwidth()

begin
	return (((PS_PWIDTH(ps) * RESOLUTION)/2) - ps_textwidth (ps, str) / 2)
end
