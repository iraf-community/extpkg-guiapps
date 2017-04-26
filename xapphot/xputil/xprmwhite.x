include <ctype.h>

# XP_RMWHITE -- Remove whitespace from a string.

procedure xp_rmwhite (instr, outstr, maxch)

char	instr[ARB]		#I the input string
char	outstr[ARB]		#O the output string, may be the same as instr
int	maxch			#I maximum number of characters in outstr

int	ip, op

begin
	op = 1
	for (ip = 1; (instr[ip] != EOS) && (op <= maxch); ip = ip + 1) {
	    if (IS_WHITE(instr[ip]))
		next
	    outstr[op] = instr[ip]
	    op = op + 1
	}
	outstr[op] = EOS
end
