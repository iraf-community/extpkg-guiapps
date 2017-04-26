include <math.h>

# RV_PHASE - Compute the phase of a complex function

procedure rv_phase (n, shift, x, phase)

int     n
double  shift
complex x[ARB]
real    phase[ARB]

double  angle, npi
int     i, ncycle

begin
        do i = 1, n {
            angle = TWOPI * double (i-1) * shift / double (n)
            if ((aimag (x[i]) == 0.) || (real (x[i]) == 0.))
                phase[i] = 0.
            else
                phase[i] = atan2 (aimag(x[i]), real(x[i]))

            npi = (phase[i] - angle) / PI
            if (npi > 0)
                ncycle = (npi + 1) / 2
            else
                ncycle = (npi - 1) / 2

            phase[i] = phase[i] - (TWOPI * double (ncycle))
            if (i < n/2) 
		phase[i+n/2] = phase[i] - angle

        }
end
