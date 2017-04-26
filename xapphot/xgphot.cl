
# XGPHOT -- A CL wrapper around the XGUIPHOT task which permits the
# user to run it a regular IRAF task without the GUI.

procedure xgphot (images, objects, results)

file	images		{"*", prompt="List of images to be analyzed"}
file	objects		{"default", prompt="List of input objects files"}
file	results		{"default", prompt="List of output results files"}
file	robjects        {"", prompt="List of optional output objects files"}
bool    logresults      {no, prompt="Log results in interactive mode ?"}
pset	impars          {"", prompt="The image data parameters"}
pset	dispars         {"", prompt="The image display parameters"}
pset	findpars        {"", prompt="The object list detection parameters"}
pset	omarkpars       {"", prompt="The object list marking parameters"}
pset	cenpars         {"", prompt="The centering algorithm parameters"}
pset	skypars         {"", prompt="The sky fitting algorithm parameters"}
pset	photpars        {"", prompt="The photometry algorithm parameters"}
pset	cplotpars       {"", prompt="The object contour plotting parameters"}
pset	splotpars       {"", prompt="The object surface plotting parameters"}
bool    update          {no, prompt="Update parameters at task termination ?"}
bool    verbose         {yes, prompt="Print messages in non-interactive mode ?"}
bool    interactive     {yes, prompt="Run the task interactively ?"}
string	graphics	{"stdgraph", prompt="The default graphics device"}
string	gcommands	{"", prompt="The default graphics cursor"}

begin
	xguiphot (images=images, objects=objects, results=results,
	    robjects=robjects, logresults=logresults, impars=impars,
	    dispars=dispars, findpars=findpars, omarkpars=omarkpars,
	    cenpars=cenpars, skypars=skypars, photpars=photpars,
	    cplotpars=cplotpars, splotpars=splotpars, update=update,
	    verbose=verbose, interactive=interactive, graphics=graphics,
	    gcommands=gcommands, guifile="", helpfile="", tutorial="")
end
