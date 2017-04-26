
# XGEX2 -- Run the xguiphot tutorial exercise 2. This tutorial covers the
# topic of creating, viewing, editing and saving objects lists.

procedure xgex2 ()

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
	xguiphot (images="xapphot$data/*.fits", objects="xapphot$data/*.coo.*",
	    results="default", tutorial="xapphot$doc/xgex2.html")
end
