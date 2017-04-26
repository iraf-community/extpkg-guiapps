include "pstools.h"


# PS_RIGHTJUSTIFY -- Right justfify text on the given string and break.

procedure ps_rightjustify (ps, str)

pointer ps                                      #i PSTOOLS descriptor
char    str[ARB]                                #i text line

int     mtemp, ps_rjPos()

begin
	mtemp = PS_CLMARGIN(ps)
        PS_CLMARGIN(ps) = ps_rjpos (ps, str)
	call ps_output (ps, str, NO)
	PS_CLMARGIN(ps) = mtemp
end


# PS_RJPOS -- Get the X position of the right-justified string.

int procedure ps_rjpos (ps, str)

pointer	ps					#i PSTOOLS descriptor
char	str[ARB]				#i text to justify

int	ps_textwidth()

begin
	return (PS_CRMPOS(ps) - ps_textwidth (ps, str))
end


# PS_SET_JUSTIFY -- Set the justification flag.

procedure ps_setjustify (ps, justify)

pointer	ps					#i PSTOOLS descriptor
int	justify					#i justificaton flag

begin
	PS_JUSTIFY(ps) = justify
end
