
# XGEX1 -- Run the xguiphot tutorial exercise 1. This tutorial covers the
# topic of displaying and examining images.

procedure xgex1 ()

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
	    results="default", tutorial="xapphot$doc/xgex1.html")
end
