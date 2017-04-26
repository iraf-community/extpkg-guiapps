
# XGEX5 -- Run the xguiphot tutorial exercise 5. This tutorial covers the
# topic of doing crowded-field aperture photometry.

procedure xgex5 ()

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
	xguiphot (images="xapphot$data/globular.fits", objects="",
	    results="default", tutorial="xapphot$doc/xgex5.html")
end
