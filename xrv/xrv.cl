#{ XRV -- GUI Radial Velocity Analysis Package

package xrv

# GUI Executables
task 	fxcor 		= "xrv$x_xrv.e"
#task 	fxcor,
#	rvcorrect,
#	rvidlines,
#	rvreidlines	= "xrv$x_xrv.e"

#task 	rvcorrect	= "astutil$x_astutil.e"

# PSET Tasks
task	filtpars	= "xrv$filtpars.par"
task	continpars 	= "xrv$continpars.par"
task	keywpars	= "xrv$keywpars.par"

# Hidden tasks
task	rvdebug		= "xrv$rvdebug.par"
    hidetask ("rvdebug")

clbye()
