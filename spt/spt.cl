#{ SPT -- SPECTOOL Package

package spt

task	spectool	= spt$x_spectool.e
task	tutorial	= spt$tutorial.cl

task	spterrors	= spt$spterrors.par
task	sptgraph	= spt$sptgraph.par
task	spticfit	= spt$spticfit.par
task	sptlabels	= spt$sptlabels.par
task	sptlines	= spt$sptlines.par
task	sptmodel	= spt$sptmodel.par
task	sptsigclip	= spt$sptsigclip.par
task	sptstack	= spt$sptstack.par
task	sptstat		= spt$sptstat.par

task	sptqueries	= spt$sptqueries.par

hidetask sptqueries

clbye()
