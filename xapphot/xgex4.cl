
# XGEX4 -- Run the xguiphot tutorial exercise 4. This tutorial covers the
# topic of measuring bright isolated standard stars through a large aperture.

procedure xgex4 (results)

file	results		{prompt="The results file"}

begin
	string	tresults

	# Test for the exisitence of the output file.
	tresults = results
	if (access (tresults)) {
	    printf ("The output file %s already exists", tresults)
	    bye
	};

	# Unlearn the xguiphot task and its associated psets.
	unlearn ("xguiphot")
	unlearn ("impars")
	unlearn ("dispars")
	unlearn ("findpars")
	unlearn ("omarkpars")
	unlearn ("cenpars")
	unlearn ("skypars")
	unlearn ("cplotpars")
	unlearn ("splotpars")

	# Run xguiphot
	xguiphot (images="xapphot$data/m92*.fits",
	          objects="xapphot$data/m92*.coo.*", results=tresults,
		  tutorial="xapphot$doc/xgex4.html")
end
