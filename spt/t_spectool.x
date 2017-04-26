include	<gio.h>
include	<smw.h>
include	"spectool.h"

 
# T_SPECTOOL -- Display and analyze spectra.

procedure t_spectool ()

int	errcode, wcs, key
real	wx, wy
pointer	spt, reg, gp
pointer	sp, cmd, err

int	clgcur(), errget()
pointer	spt_open()
errchk	spt_open, spt_key, spt_replot

begin
	call smark (sp)
	call salloc (cmd, SZ_LINE, TY_CHAR)
	call salloc (err, SZ_LINE, TY_CHAR)

	# Open.
	gp = spt_open (spt)

	# Enter interactive loop with error checking.
	call gmsg (gp, "setGui", "interactive")
	reg = NULL
	errcode = 0
	key = 0
	repeat {
	    # Clear error messages.
	    if (errcode != 0 && SPT_ERRCLEAR(spt) == YES) {
		call printf ("\n")
		errcode = 0
	    }

	    iferr (call spt_key (spt, reg, gp, wx, wy, wcs, key, Memc[cmd])) {
		errcode = errget (Memc[err], SZ_LINE)
		errcode = 1
	    }

	    if (key == 'q')
		break
	    else
		call spt_replot (spt)

	    if (errcode != 0 && SPT_ERRCLEAR(spt) == YES)
		call printf (Memc[err])
	    call gmsg (gp, "ready", "")
	} until (clgcur ("cursor", wx, wy, wcs, key, Memc[cmd], SZ_LINE) == EOF)

	# Close.
	call spt_close (spt)

	call sfree (sp)
end


# SPT_OPEN -- Open SPECTOOL.

pointer procedure spt_open (spt)

pointer	spt			#O SPECTOOL structure

int	i
pointer	sp, str, gp

int	clgeti(), btoi()
bool	clgetb()
pointer	gopenui()

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	call calloc (spt, SPT_LEN, TY_STRUCT)
	SPT_MAXREG(spt) = clgeti ("maxreg")

	SPT_RGLEN(spt) = 1000
	SPT_IMLEN(spt) = 1000
	SPT_SPLEN(spt) = 1000
	call calloc (SPT_RGLIST(spt), SPT_RGLEN(spt), TY_CHAR)
	call calloc (SPT_IMLIST(spt), SPT_IMLEN(spt), TY_CHAR)
	call calloc (SPT_SPLIST(spt), SPT_SPLEN(spt), TY_CHAR)

	call fpathname ("", SPT_STARTDIR(spt), SPT_SZLINE)

	SPT_SPEC(spt) = NULL
	SPT_SN(spt) = 0
	SPT_LCLIP(spt) = 0.
	SPT_HCLIP(spt) = 0.
	call strcpy ("line1", SPT_TYPE(spt), SPT_SZTYPE)
	call strcpy ("vebar", SPT_ETYPE(spt), SPT_SZTYPE)
	SPT_COLOR(spt) = 1.

	call clgstr ("graphics", Memc[str], SZ_LINE)
	call clgstr ("gui", SPT_STRING(spt), SPT_SZSTRING)
	if (SPT_STRING(spt) == EOS)
	    SPT_GUI(spt) = NO
	else
	    SPT_GUI(spt) = YES
	gp = gopenui (Memc[str], NEW_FILE, SPT_STRING(spt), STDGRAPH)
	call gflush (gp)
	do i = 1, 3 { 
	    call malloc (SPT_WCSPTR(spt,i), LEN_WCSARRAY, TY_STRUCT)
	    call amovi (Memi[GP_WCSPTR(gp,1)], Memi[SPT_WCSPTR(spt,i)],
		LEN_WCSARRAY)
	}
	SPT_WCS(spt) = 1
	SPT_GP(spt) = gp

	call spt_graph (spt, "open")

	SPT_PLOT(spt,SHX) = NO
	SPT_PLOT(spt,SHDATA) = YES
	SPT_PLOT(spt,SHRAW) = NO
	SPT_PLOT(spt,SHSKY) = NO
	SPT_PLOT(spt,SHSIG) = NO
	SPT_PLOT(spt,SHCONT) = NO
	SPT_CTYPE(spt) = SHDATA

	call spt_log (spt, NULL, "open", "")
	call spt_help (spt, "open")
	call spt_stat (spt, NULL, "open", INDEFR, INDEFR, INDEFR, INDEFR)

	call lab_colon (spt, NULL, INDEFD, INDEFD, "open")
	#call lab_colon (spt, NULL, INDEFD, INDEFD, "select")
	call lid_colon (spt, NULL, INDEFD, INDEFD, "open")
	call lid_colon (spt, NULL, INDEFD, INDEFD, "select")
	call ll_colon (spt, NULL, INDEFD, INDEFD, "open")
	call spt_ctr (spt, NULL, INDEFD, INDEFD, "open")
	call sigclip (spt, NULL, "open")
	call spt_arith (spt, NULL, "open")
	call spt_errors (spt, "open")
	call mod_colon (spt, NULL, INDEFD, INDEFD, "open")
	call spt_plotcolon (spt, NULL, "open")
	call spt_stack (spt, "open")

	call smw_daxis (NULL, NULL, 0, 0, 0)

	# Set general GUI state.
	SPT_FINDER(spt) = btoi (clgetb ("pan"))
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "finder %d")
	    call pargi (SPT_FINDER(spt))
	call gmsg (gp, "setGui", SPT_STRING(spt))
	call sprintf (SPT_STRING(spt), SPT_SZSTRING, "coords %b")
	    call pargi (btoi (clgetb ("wcs")))
	call gmsg (gp, "setGui", SPT_STRING(spt))

	call gmsg (gp, "query", "colors")

	call clgstr ("template", SPT_IMTMP(spt), SPT_SZLINE)
	call spt_imlist (spt, "", SPT_IMTMP(spt))
	call gmsg (gp, "setGui", "files *")

	call gmsg (gp, "spectra", "")
	call gmsg (gp, "registers", "")

	SPT_ERRCLEAR(spt) = NO
	call sfree (sp)

	return (gp)
end


# SPT_CLOSE -- Close SPECTOOL.

procedure spt_close (spt)

pointer	spt			#I SPECTOOL structure
int	i

begin
	# Free registers.
	while (SPT_NREG(spt) > 0)
	    call reg_free (spt, REG(spt,1))

	# Close modules.
	call spt_ctr (spt, NULL, INDEFD, INDEFD, "close")
	call spt_deredden (spt, NULL, "close")
	call spt_eqwidth (spt, NULL, INDEFR, INDEFR, "close")
	call spt_help (spt, "close")
	call spt_plotcolon (spt, NULL, "close")
	call lab_colon (spt, NULL, INDEFD, INDEFD, "close")
	call lid_colon (spt, NULL, INDEFD, INDEFD, "close")
	call ll_colon (spt, NULL, INDEFD, INDEFD, "close")
	call spt_log (spt, NULL, "close", "")
	call spt_arith (spt, NULL, "close")
	call spt_errors (spt, "close")
	call mod_colon (spt, NULL, INDEFD, INDEFD, "close")
	call spt_rv (spt, NULL, "close")
	call spt_smooth (spt, NULL, 0, NULL, 0, "close")
	call spt_stack (spt, "close")
	call spt_stat (spt, NULL, "close", INDEFR, INDEFR, INDEFR, INDEFR)
	call sigclip (spt, NULL, "close")
	call spt_wrspect (spt, NULL, "close")
	call spt_graph (spt, "close")
	#call clpstr ("template", SPT_IMTMP(spt), SPT_SZLINE)

	# Close GUI.
	call gmsg (SPT_GP(spt), "output", "quit")
	call gclose (SPT_GP(spt))

	# Free memory.
	if (SPT_FNT(spt) != NULL)
	    call fntclsb (SPT_FNT(spt))
	call imtclose (SPT_IMIMT(spt))
	call mfree (SPT_RGLIST(spt), TY_CHAR)
	call mfree (SPT_IMLIST(spt), TY_CHAR)
	call mfree (SPT_SPLIST(spt), TY_CHAR)
	call mfree (SPT_SPEC(spt), TY_REAL)
	do i = 1, 3
	    call mfree (SPT_WCSPTR(spt,i), TY_STRUCT)

	# Restore starting directory.
	call fchdir (SPT_STARTDIR(spt))

	call mfree (spt, TY_STRUCT)
end
