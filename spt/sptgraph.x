include	<gset.h>
include	<pkg/gtools.h>
include	"spectool.h"

# List of colon commands.
define	CMDS "|open|close|"
define	OPEN	1
define	CLOSE	2

define  XAXES	"|none|bottom|top|both|"
define  YAXES	"|none|left|right|both|"

# SPT_GRAPH -- GRAPH module.

procedure spt_graph (spt, cmd)

pointer	spt			#I SPECTOOLS pointer
char	cmd[ARB]		#I Command

int	i, ival
real	rval
pointer	sp, str, gp, gt

bool	clgetb()
int	clgeti(), clgwrd(), strdic(), btoi(), gstati(), gt_geti()
real	clgetr(), gstatr(), gt_getr()
pointer	gt_init()
errchk	gt_init, gt_ireset

begin
	call smark (sp)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	i = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (i) {
	case OPEN: # open
	    gp = SPT_GP(spt)
	    gt = gt_init ()

	    call clgstr ("ptype", SPT_TYPE(spt), SPT_SZLINE)
	    call clgstr ("etype", SPT_ETYPE(spt), SPT_SZLINE)
	    SPT_COLOR(spt) = clgwrd ("pcolor", Memc[str],
		SZ_LINE, COLORS) - 1
	    call gt_setr (gt, GTXSIZE, clgetr ("xmarksize"))
	    call gt_setr (gt, GTYSIZE, clgetr ("ymarksize"))

	    call clgstr ("title", SPT_TITLE(spt), SPT_SZLINE)
	    call clgstr ("xlabel", SPT_XLABEL(spt), SPT_SZLINE)
	    call clgstr ("ylabel", SPT_YLABEL(spt), SPT_SZLINE)
	    call strcpy ("default", SPT_XUNITS(spt), SPT_SZLINE)
	    call strcpy ("default", SPT_YUNITS(spt), SPT_SZLINE)
	    call clgstr ("dunits", SPT_UNITS(spt), SPT_SZLINE)
	    call clgstr ("funits", SPT_FUNITS(spt), SPT_SZLINE)
	    call clgstr ("unknown", SPT_UNKNOWN(spt), SPT_SZLINE)

	    call gt_seti (gt, GTSYSID, btoi (clgetb ("sysid")))
	    call clgstr ("subtitle", Memc[str], SZ_LINE)
	    call gt_sets (gt, GTSUBTITLE, Memc[str])
	    ival = clgwrd ("titlecolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_TITLECOLOR, ival)
	    ival = clgwrd ("xaxlabcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_XAXISLABELCOLOR, ival)
	    ival = clgwrd ("yaxlabcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_YAXISLABELCOLOR, ival)

	    call gt_setr (gt, GTVXMIN, clgetr ("xviewmin"))
	    call gt_setr (gt, GTVXMAX, clgetr ("xviewmax"))
	    call gt_setr (gt, GTVXMAX, 0.95)
	    call gt_setr (gt, GTVYMIN, clgetr ("yviewmin"))
	    call gt_setr (gt, GTVYMAX, clgetr ("yviewmax"))
	    ival = clgwrd ("xdrawaxis", Memc[str], SZ_LINE, XAXES) - 1
	    call gseti (gp, G_XDRAWAXES, ival)
	    ival = clgwrd ("ydrawaxis", Memc[str], SZ_LINE, YAXES) - 1
	    call gseti (gp, G_YDRAWAXES, ival)
	    rval = clgetr ("xaxwidth")
	    call gsetr (gp, G_XAXISWIDTH, rval)
	    rval = clgetr ("yaxwidth")
	    call gsetr (gp, G_YAXISWIDTH, rval)
	    rval = clgetr ("xaxwidth")
	    call gsetr (gp, G_XMAJORWIDTH, rval)
	    rval = clgetr ("yaxwidth")
	    call gsetr (gp, G_YMAJORWIDTH, rval)
	    rval = clgetr ("xaxwidth")
	    call gsetr (gp, G_XMINORWIDTH, rval)
	    rval = clgetr ("yaxwidth")
	    call gsetr (gp, G_YMINORWIDTH, rval)
	    call clgstr ("xaxtype", Memc[str], SZ_LINE)
	    call gt_sets (gt, GTXTRAN, Memc[str])
	    call clgstr ("yaxtype", Memc[str], SZ_LINE)
	    call gt_sets (gt, GTYTRAN, Memc[str])
	    ival = clgwrd ("xaxcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_XAXISCOLOR, ival)
	    ival = clgwrd ("yaxcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_YAXISCOLOR, ival)
	    ival = clgwrd ("xaxcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_XTICKCOLOR, ival)
	    ival = clgwrd ("yaxcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_YTICKCOLOR, ival)
	    call gseti (gp, G_XDRAWGRID, btoi (clgetb ("xdrawgrid")))
	    call gseti (gp, G_YDRAWGRID, btoi (clgetb ("ydrawgrid")))
	    ival = clgwrd ("xgridcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_XGRIDCOLOR, ival)
	    ival = clgwrd ("ygridcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_YGRIDCOLOR, ival)
	    ival = clgwrd ("framecolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_FRAMECOLOR, ival)

	    call gseti (gp, G_XDRAWTICKS, btoi (clgetb ("xdrawticks")))
	    call gseti (gp, G_XDRAWTICKS, btoi (clgetb ("ydrawticks")))
	    call gseti (gp, G_XNMAJOR, clgeti ("xnmajor"))
	    call gseti (gp, G_YNMAJOR, clgeti ("ynmajor"))
	    call gseti (gp, G_XNMINOR, clgeti ("xnminor"))
	    call gseti (gp, G_YNMINOR, clgeti ("ynminor"))
	    call gseti (gp, G_XLABELTICKS, btoi (clgetb ("xlabticks")))
	    call gseti (gp, G_XLABELTICKS, btoi (clgetb ("ylabticks")))
	    call clgstr ("xtickformat", Memc[str], SZ_LINE)
	    call gt_sets (gt, GTXFORMAT, Memc[str])
	    call clgstr ("ytickformat", Memc[str], SZ_LINE)
	    call gt_sets (gt, GTYFORMAT, Memc[str])
	    ival = clgwrd ("xticklabcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_XTICKLABELCOLOR, ival)
	    ival =clgwrd ("yticklabcolor", Memc[str], SZ_LINE, COLORS) - 1
	    call gseti (gp, G_YTICKLABELCOLOR, ival)

	    call gt_setr (gt, GTXMIN, clgetr ("xmin"))
	    call gt_setr (gt, GTXMAX, clgetr ("xmax"))
	    call gt_setr (gt, GTYMIN, clgetr ("ymin"))
	    call gt_setr (gt, GTYMAX, clgetr ("ymax"))

	    call gt_setr (gt, GTYBUF, 0.15)
	    call gt_sets (gt, GTTYPE, "line1")

	    call gt_ireset (gp, gt)

	    call gmsg (gp, "setGui", "xflip 0")
	    call gmsg (gp, "setGui", "yflip 0")

	    SPT_GT(spt) = gt

	case CLOSE: # close
	    gp = SPT_GP(spt)
	    gt = SPT_GT(spt)
	    call gt_reset (gp, gt)

	    call gt_sets (gt, GTTYPE, SPT_TYPE(spt))
	    call gt_gets (gt, GTTYPE, Memc[str], SZ_LINE)
	    call clpstr ("ptype", Memc[str])
	    call clpstr ("etype", SPT_ETYPE(spt))
	    call spt_dic (COLORS, SPT_COLOR(spt)+1,
		Memc[str], SZ_LINE)
	    call clpstr ("pcolor", Memc[str])
	    call clputr ("xmarksize", gt_getr (gt, GTXSIZE))
	    call clputr ("ymarksize", gt_getr (gt, GTYSIZE))

	    call clpstr ("title", SPT_TITLE(spt))
	    call clpstr ("xlabel", SPT_XLABEL(spt))
	    call clpstr ("ylabel", SPT_YLABEL(spt))
	    call clpstr ("dunits", SPT_UNITS(spt))
	    call clpstr ("funits", SPT_FUNITS(spt))

	    call clputb ("sysid", gt_geti(gt,GTSYSID)==YES)
	    Memc[str] = EOS
	    call gt_gets (gt, GTSUBTITLE, Memc[str], SZ_LINE)
	    call clpstr ("subtitle", Memc[str])
	    ival = gstati (gp, G_TITLECOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("titlecolor", Memc[str])
	    ival = gstati (gp, G_XAXISLABELCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("xaxlabcolor", Memc[str])
	    ival = gstati (gp, G_YAXISLABELCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("yaxlabcolor", Memc[str])

	    call clputr ("xviewmin", gt_getr(gt,GTVXMIN))
	    call clputr ("xviewmax", gt_getr(gt,GTVXMAX))
	    call clputr ("yviewmin", gt_getr(gt,GTVYMIN))
	    call clputr ("yviewmax", gt_getr(gt,GTVYMAX))
	    ival = gstati (gp, G_XDRAWAXES) + 1
	    call spt_dic (XAXES, ival, Memc[str], SZ_LINE)
	    call clpstr ("xdrawaxis", Memc[str])
	    ival = gstati (gp, G_YDRAWAXES) + 1
	    call spt_dic (YAXES, ival, Memc[str], SZ_LINE)
	    call clpstr ("ydrawaxis", Memc[str])
	    call clputr ("xaxwidth", gstatr (gp, G_XAXISWIDTH))
	    call clputr ("yaxwidth", gstatr (gp, G_YAXISWIDTH))
	    call clputr ("xaxwidth", gstatr (gp, G_XMAJORWIDTH))
	    call clputr ("yaxwidth", gstatr (gp, G_YMAJORWIDTH))
	    call clputr ("xaxwidth", gstatr (gp, G_XMINORWIDTH))
	    call clputr ("yaxwidth", gstatr (gp, G_YMINORWIDTH))

	    Memc[str] = EOS
	    call gt_gets (gt, GTXTRAN, Memc[str], SZ_LINE)
	    call clpstr ("xaxtype", Memc[str])
	    Memc[str] = EOS
	    call gt_gets (gt, GTYTRAN, Memc[str], SZ_LINE)
	    call clpstr ("yaxtype", Memc[str])
	    ival = gstati (gp, G_XAXISCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("xaxcolor", Memc[str])
	    ival = gstati (gp, G_YAXISCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("yaxcolor", Memc[str])
	    ival = gstati (gp, G_XTICKCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("xaxcolor", Memc[str])
	    ival = gstati (gp, G_YTICKCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("yaxcolor", Memc[str])
	    call clputb ("xdrawgrid", gstati(gp,G_XDRAWGRID)==YES)
	    call clputb ("ydrawgrid", gstati(gp,G_YDRAWGRID)==YES)
	    ival = gstati (gp, G_XGRIDCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("xgridcolor", Memc[str])
	    ival = gstati (gp, G_YGRIDCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("ygridcolor", Memc[str])
	    ival = gstati (gp, G_FRAMECOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("framecolor", Memc[str])

	    call clputb ("xdrawticks", gstati(gp,G_XDRAWTICKS)==YES)
	    call clputb ("ydrawticks", gstati(gp,G_YDRAWTICKS)==YES)
	    call clputi ("xnmajor", gstati(gp,G_XNMAJOR))
	    call clputi ("ynmajor", gstati(gp,G_YNMAJOR))
	    call clputi ("xnminor", gstati(gp,G_XNMINOR))
	    call clputi ("ynminor", gstati(gp,G_YNMINOR))
	    call clputb ("xlabticks", gstati(gp,G_XLABELTICKS)==YES)
	    call clputb ("ylabticks", gstati(gp,G_YLABELTICKS)==YES)
	    Memc[str] = EOS
	    call gt_gets (gt, GTXFORMAT, Memc[str], SZ_LINE)
	    call clpstr ("xtickformat", Memc[str])
	    Memc[str] = EOS
	    call gt_gets (gt, GTYFORMAT, Memc[str], SZ_LINE)
	    call clpstr ("ytickformat", Memc[str])
	    ival = gstati (gp, G_XTICKLABELCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("xticklabcolor", Memc[str])
	    ival = gstati (gp, G_YTICKLABELCOLOR) + 1
	    call spt_dic (COLORS, ival, Memc[str], SZ_LINE)
	    call clpstr ("yticklabcolor", Memc[str])

	    call gt_free (SPT_GT(spt))

	default: # error or unknown command
	    call sprintf (Memc[str], SZ_LINE,
		"Error in help command: gtools %s")
		call pargstr (cmd)
	    call error (1, Memc[str])
	}

	call sfree (sp)
end


# SPT_DIC -- Extract string from a dictionary given an index.

procedure spt_dic (dic, index, str, max_char)

char	dic[ARB]	# Dictionary string
int	index		# Index to select
char	str[max_char]	# Output string
int	max_char	# Size of output string

int	i, ip
char	ch

begin
	str[1] = EOS

	i = 0
	for (ip=1; dic[ip]!=EOS; ip=ip+1) {
	    if (dic[ip] == '|')
		i = i + 1
	    if (i == index)
		break
	}
	if (dic[ip] == EOS)
	    return

	i = 1
	for (ip=ip+1; dic[ip]!=EOS; ip=ip+1) {
	    ch = dic[ip]
	    if (ch == '|' || ch == '\n')
		break
	    str[i] = ch
	    i = i + 1
	}
	str[i] = EOS
end
