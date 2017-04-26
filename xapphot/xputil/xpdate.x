include <time.h>

# XP_DATE -- Fetch the date and time strings required for the xapphot output
# files.

procedure xp_date (date, time, maxch)

char	date[ARB]	#O the date string
char	time[ARB]	#O the time string
int	maxch		#I the maximum number of character in the string

int	tm[LEN_TMSTRUCT]
long	ctime
long	clktime()
#long	lsttogmt()

begin
	ctime = clktime (long(0))
	#ctime = lsttogmt (ctime)
	call brktime (ctime, tm)
	call sprintf (date, maxch, "%04d-%02d-%02d")
	    call pargi (TM_YEAR(tm))
	    call pargi (TM_MONTH(tm))
	    call pargi (TM_MDAY(tm))
	call sprintf (time, maxch, "%02d:%02d:%02d")
	    call pargi (TM_HOUR(tm))
	    call pargi (TM_MIN(tm))
	    call pargi (TM_SEC(tm))
end
