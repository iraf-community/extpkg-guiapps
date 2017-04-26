#{ GUIAPPS -- The GUI suite of packages.

cl < "guiapps$lib/zzsetenv.def"
package	guiapps, bin = guibin$

task	demo		= "demo$x_demo.e"
task	spt.pkg		= "spt$spt.cl"
task	xhelp		= "xhelp$x_xhelp.e"
task	xrv.pkg		= "xrv$xrv.cl"
task	xapphot.pkg	= "xapphot$xapphot.cl"

clbye()
