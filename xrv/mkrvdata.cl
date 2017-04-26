#{ MKRVDATA - Make test images for the RV package.

procedure mkrvdata ()

int	nspec = 10		{ prompt="Number of test spectra to create" }
int	ddir  = "./rvdata"	{ prompt="Data directory to create" }

begin
	int	i, nim
	real	vel
	string	fname

	# sanity check
	if (!defpac("artdata")) {
	    error (0, "ARTDATA is not loaded") ; beep ()
	}
	if (!defpac("utilities")) {
	    error (0, "UTILITIES is not loaded") ; beep ()
	}

	nim = nspec

	# Create the data directory
	mkdir (ddir)
	cd (ddir)

	# Generate the low and high dispersion line lists.
	print ("Generating line lists ...")
	if (access("lines.hd")) {
	    print ("Warning: Linelist `lines.ld' already exists.")
	} else {
	    urand (nlines=600, ncol=1, ndigit=7, scale=10000.0, seed=1) | \
	        translit (from=" ",to="",del=yes) | sort(num=yes, > "lines.ld")
	}
	flpr ()
	if (access("lines.hd")) {
	    print ("Warning: Linelist `lines.hd' already exists.")
	} else {
	    urand (nlines=2500, ncol=1, ndigit=7, scale=10000.0, seed=1) | \
	        translit (from=" ",to="",del=yes) | sort(num=yes, > "lines.hd")
	}

	# Set the MK1DSPEC parameters.
	mk1dspec.output = ""
	mk1dspec.ap = 1
	mk1dspec.title = ""
	#mk1dspec.format = "onedspec"
	mk1dspec.ncols = 1024
	mk1dspec.naps = 1
	mk1dspec.header = "artdata$stdheader.dat"
	mk1dspec.continuum = 1000.
	mk1dspec.slope = 0.
	mk1dspec.temperature = 0.
	mk1dspec.fnu = no
	mk1dspec.peak = -0.5
	mk1dspec.sigma = 0.3
	mk1dspec.seed = 1
	mk1dspec.comments = yes

	# Set the MKNOISE parameters.
	mknoise.title = ""
	mknoise.ncols = 1024
	mknoise.nlines = 1
	mknoise.header = "artdata$stdheader.dat"
	mknoise.background = 0.
	mknoise.gain = 1.
	mknoise.rdnoise = 2.
	mknoise.poisson = yes
	mknoise.seed = 1
	mknoise.cosrays = ""
	mknoise.ncosrays = 0
	mknoise.energy = 30000.
	mknoise.radius = 0.5
	mknoise.ar = 1.
	mknoise.pa = 0.
	mknoise.comments = yes

	# Generate a high-dispersion correlation pair 
	#     (vpix=10.845, wpc=0.1857)
	print ("Creating high-dispersion spectra ...")
	mk1dspec ("hobj",rv=750.,z=no,wstart=5040.,wend=5230.,lines="lines.hd")
	mknoise("hobj",output="hobj")
	mk1dspec ("htemp",rv=0.,z=no,wstart=5040.,wend=5230.,lines="lines.hd")
	mknoise("htemp",output="htemp")

	print ("Creating high-dispersion emission spectra ...")
	mk1dspec ("hem",rv=1250.,z=no,wstart=5040.,wend=5230.,lines="lines.hd")
	mk1dspec ("hem",rv=1250.,z=no,wstart=5040.,wend=5230.,lines="",
	    nlines=6, peak=0.9)
	mknoise("hem",output="hem")

	vel = 0.0
	mk1dspec.line="lines.hd"
	for (i=1; i<=nim; i=i+1) {
	    if (i < 10)
	        fname = "hobj00" // i
	    else if (i >= 10 && i < 100)
	        fname = "hobj0" // i
	    mk1dspec (fname,rv=vel,z=no,wstart=5040.,wend=5230.)
	    mknoise (fname,output=fname)
	    vel = vel + 10.0
	}

	# Generate a low-dispersion correlation pair. 
	#    (vpix=138.954, wpc=2.6686)
	print ("Creating low-dispersion spectra ...")
	mk1dspec.sigma = 4.3
	mk1dspec ("lobj",rv=750.,z=no,wstart=4500.,wend=7230.,lines="lines.ld")
	mknoise("lobj",output="lobj")
	mk1dspec ("ltemp",rv=0.,z=no,wstart=4500.,wend=7230.,lines="lines.ld")
	mknoise("ltemp",output="ltemp")

	vel = 0.0
	mk1dspec.line="lines.ld"
	for (i=1; i<=nim; i=i+1) {
	    if (i < 10)
	        fname = "hobj00" // i
	    else if (i >= 10 && i < 100)
	        fname = "hobj0" // i
	    mk1dspec (fname,rv=vel,z=no,wstart=4500.,wend=7230.)
	    mknoise (fname,output=fname)
	    vel = vel + 100.0
	}

	print ("Creating low-dispersion emission spectra ...")
	mk1dspec ("lem",rv=7500.,z=no,wstart=4500.,wend=7230.,lines="lines.ld")
	mk1dspec ("lem",rv=7500.,z=no,wstart=4500.,wend=7230.,lines="",
	    nlines=6, peak=0.9)
	mknoise("lem",output="lem")
end
