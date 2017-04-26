# Run SPECTOOL in tutorial mode.

procedure tutorial ()

string	spectrum = "sptdata$tutorial.ms"	{prompt="Tutorial data"}

begin
	spectool (spectrum, topic="tutorial")
end
