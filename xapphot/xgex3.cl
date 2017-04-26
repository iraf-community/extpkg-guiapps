
# XGEX3 -- Run the xguiphot tutorial exercise 3. This tutorial covers the
# topic of doing quick-look photometry.

procedure xgex3 ()

begin
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
	          objects="xapphot$data/m92*.coo.*", results="default",
		  tutorial="xapphot$doc/xgex3.html")
end
