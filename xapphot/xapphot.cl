#{ XAPPHOT -- The X based digital photometry package.

type "xapphot$banner.dat"

package xapphot

set glbcolor = "pt=3,fr=9,gr=5,al=3,ax=5,tk=5,tl=6"

task	xfind,
	xcenter,
	xfitsky,
	xphot,
	xguiphot	= "xapphot$x_xapphot.e"

task	xgphot		="xapphot$xgphot.cl"
task	$xgex1		="xapphot$xgex1.cl"
task	$xgex2		="xapphot$xgex2.cl"
task	$xgex3		="xapphot$xgex3.cl"
task	xgex4		="xapphot$xgex4.cl"
task	$xgex5		="xapphot$xgex5.cl"

task	impars		= "xapphot$impars.par"
task	dispars		= "xapphot$dispars.par"
task	findpars	= "xapphot$findpars.par"
task	omarkpars	= "xapphot$omarkpars.par"
task	cenpars		= "xapphot$cenpars.par"
task	skypars		= "xapphot$skypars.par"
task	photpars	= "xapphot$photpars.par"
task	cplotpars	= "xapphot$cplotpars.par"
task	splotpars	= "xapphot$splotpars.par"
task	dummypars	= "xapphot$dummypars.par"

hidetask dummypars
hidetask xfind, xcenter, xfitsky, xphot

clbye()
