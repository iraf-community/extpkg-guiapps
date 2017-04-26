include	<error.h>
include	<smw.h>
include	"spectool.h"

# Commands
define	CMDS	"|open|close|write|"
define	OPEN		1
define	CLOSE		2
define	WRITE		3	# Write spectrum

# Output formats
define	OUTTYPES "|same|onedspec|"
define	OUTSAME		1	# Same as input spectrum
define	OUTONED		2	# Onedspec format

# SPT_WRSPECT -- Write spectrum.

procedure spt_wrspect (spt, reg, cmd)

pointer	spt			#I SPECTOOL pointer
pointer	reg			#I Register pointer
char	cmd			#I Command

int	i, n, outtype, strdic(), nscan(), envputs()
bool	overwrite
pointer	sp, fname, str, sh
errchk	wrspecta

begin
	if (reg == NULL)
	    return
	sh = REG_SH(reg)
	if (sh == NULL)
	    return

	call smark (sp)
	call salloc (fname, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Scan the command string and get the first word.
	call sscan (cmd)
	call gargwrd (Memc[str], SZ_LINE)
	n = strdic (Memc[str], Memc[str], SZ_LINE, CMDS)

	switch (n) {
	case OPEN:
	    ;

	case CLOSE:
	    ;

	case WRITE: # write file onedspec overwrite
	    call gargwrd (Memc[fname], SZ_LINE)
	    call gargwrd (Memc[str], SZ_LINE)
	    call gargb (overwrite)
	    if (nscan() < 4)
		call error (1, "Error in write command")

	    outtype = strdic (Memc[str], Memc[str], SZ_LINE, OUTTYPES)
	    if (outtype == 0)
		call error (1, "Unkown output format")

	    # Workaround to avoid append to FITS files.
	    i = envputs ("fkinit", "")
	    iferr (call wrspecta (sh, Memc[fname], outtype, overwrite)) {
		call spt_rglist (spt, reg)
		call sfree (sp)
		call erract (EA_ERROR)
	    }

	    if (REG_MODIFIED(reg) != 'S') {
		REG_MODIFIED(reg) = 'S'
		call spt_rglist (spt, reg)
	    }

	    call printf ("Register %s written to %s ")
		call pargstr (REG_IDSTR(reg))
		call pargstr (Memc[fname])

	    call  spt_imlist (spt, SPT_DIR(spt), SPT_IMTMP(spt))
	}

	call sfree (sp)
end


include	<error.h>
include	<imhdr.h>
include	<imio.h>
include	<smw.h>
include	<units.h>


# WRSPECT -- Write spectrum to the same image or another image.
#
# If overwriting reopen the image READ_WRITE.  If this is not possible it is
# an error which may be trapped by the calling routine if desired.
# 
# If writing to another image determine if the image exists.  If not make a
# NEW_COPY of the image and copy all spectra and associated data.  NDSPEC
# format spectra, i.e. 2D or 3D images, are copied to a 1D spectrum.
# 
# If the image exists check the overwrite parameter.  If overwriting, open the
# image READ_WRITE and return an error if this is not possible.  If the
# output image has only one spectrum delete the image and create a NEW_COPY
# of the current spectrum image.  Otherwise we will be replacing only the
# current spectrum so copy all spectra from the current image.
# 
# When the input and output images are not the same open the output WCS and
# select the spectrum of the same aperture to replace.  It is an error if the
# output spectrum does not contain a spectrum of the same aperture.  It is
# also an error if the output spectrum is an NDSPEC image.

procedure wrspecta (sh1, output, outtype, overwrite)

pointer	sh1		# Spectrum pointer to be written
char	output[ARB]	# Output spectrum filename
int	outtype		# Output type
bool	overwrite	# Overwrite existing spectrum?

bool	one
int	i, j, np1, np2, dtype[2], nw[2], types[SH_NTYPES], ntypes
real	r[2]
double	w1[2], dw[2], z[2]
pointer	sp, tmp, err, coeff, im, in, out, mw1, mw2, sh2, outbuf, ptr, sy

int	nowhite(), imaccf(), imaccess()
bool	xt_imnameeq(), fp_equald()
pointer immap(), smw_openim(), imgl3r(), impl3r(), imps3r()
errchk	immap,  imgl3r, impl3r, imps3r, imdelf, shdr_open, wrspectb
errchk	smw_openim, smw_gwattrs, smw_swattrs, smw_saveim, imunmap

define	new_	10

begin
	call smark (sp)
	call salloc (tmp, SZ_LINE, TY_CHAR)
	call salloc (err, SZ_LINE, TY_CHAR)

	in = IM(sh1)
	out = NULL
	mw1 = MW(sh1)
	out = NULL
	mw2 = NULL
	sh2 = NULL
	ptr = NULL

	iferr {
	    # Select output type.
	    one = (outtype==OUTONED || IM_NDIM(in)==1 || IM_LEN(in,2)==1)

	    # Map spectrum types.
	    call wrtypes (sh1, types, ntypes)
	    if (SMW_FORMAT(mw1) == SMW_ND && outtype != OUTONED)
		ntypes = 1

	    # Open and initialize the output image.
	    Memc[tmp] = EOS
	    if (xt_imnameeq (IMNAME(sh1), output)) {
		if (!overwrite) {
		    call sprintf (Memc[err], SZ_LINE, "Image %s already exists")
			call pargstr (output)
		    call error (1, Memc[err])
		}

		if (one || (ntypes>1 &&
		    (IM_NDIM(in)<3 || IM_LEN(in,3)!=ntypes))) {
		    call mktemp ("tmp", Memc[tmp], SZ_LINE)
		    im = immap (Memc[tmp], NEW_COPY, in)
		    goto new_
		}

		call imunmap (in)
		iferr (im = immap (IMNAME(sh1), READ_WRITE, 0)) {
		    in = immap (IMNAME(sh1), READ_ONLY, 0)
		    call erract (EA_ERROR)
		}

		in = im
		IM(sh1) = in
		out = in
		mw2 = MW(sh1)
		sh2 = sh1

	    } else {
		if (nowhite (output, output, ARB) == 0)
		    call error (2, "No output file specified")
		iferr (im = immap (output, NEW_COPY, in)) {
		    if (!overwrite) {
			call sprintf (Memc[err], SZ_LINE,
			    "Image %s already exists")
			    call pargstr (output)
			call error (1, Memc[err])
		    }
		    im = immap (output, READ_WRITE, 0); out = im

		    if (one || (ntypes>1 &&
			(IM_NDIM(out)<3 || IM_LEN(out,3)!=ntypes))) {
			call imunmap (out)
			call imdelete (output)
			im = immap (output, NEW_COPY, in)
			goto new_
		    }

		    im = smw_openim (out); mw2 = im
		    switch (SMW_FORMAT(mw1)) {
		    case SMW_ND:
			if (SMW_FORMAT(mw2) != SMW_ND)
			    call error (3, "Incompatible spectral formats")
			if (IM_NDIM(in) != IM_NDIM(out))
			    call error (4, "Incompatible dimensions")
			do i = 1, IM_NDIM(in)
			    if (IM_LEN(in,i) != IM_LEN(out,i))
				call error (4, "Incompatible dimensions")
			coeff = NULL
			call smw_gwattrs (mw1, 1, 1, i, i,
			    dtype[1], w1[1], dw[1], nw[1], z, r, r, coeff)
			call smw_gwattrs (mw2, 1, 1, i, i,
			    dtype[2], w1[2], dw[2], nw[2], z, r, r, coeff)
			call mfree (coeff, TY_CHAR)
			if (dtype[1]!=dtype[2] || !fp_equald (w1[1],w1[2]) ||
			    !fp_equald (dw[1],dw[2]))
			    call error (5,
				"Incompatible dispersion coordinates")
			call shdr_open (out, mw2, APINDEX(sh1), LINDEX(sh1,2),
			    AP(sh1), SHHDR, ptr)
			sh2 = ptr
		    case SMW_ES, SMW_MS:
			if (SMW_FORMAT(mw2) == SMW_ND)
			    call error (3, "Incompatible spectral formats")
			call shdr_open (out, mw2, APINDEX(sh1), 1,
			    AP(sh1), SHHDR, ptr)
			sh2 = ptr
		    }

		} else {
new_		    out = im

		    if (IM_PIXTYPE(out) != TY_DOUBLE)
			IM_PIXTYPE(out) = TY_REAL
		    if (one) {
			if (ntypes == 1)
			    IM_NDIM(out) = 1
			else {
			    IM_NDIM(out) = 3
			    IM_LEN(out,2) = 1
			    IM_LEN(out,3) = ntypes
			}
			if (SMW_FORMAT(mw1) == SMW_ND) {
			    IM_LEN(out,1) = SMW_LLEN(mw1,1)
			    call imaddi (out, "dispaxis", 1)
			}
			im = smw_openim (out); mw2 = im
			call shdr_open (out, mw2, 1, 1, INDEFI, SHHDR, sh2)
			AP(sh2) = AP(sh1)
			SMW_FORMAT(mw2) = SMW_ES
		    } else {
			if (ntypes > 1) {
			    IM_NDIM(out) = 3
			    IM_LEN(out,3) = ntypes
			}
			im = smw_openim (out); mw2 = im
			call shdr_open (out, mw2, APINDEX(sh1), 1, AP(sh1),
			    SHHDR, sh2)

			if (IM_LEN(out,2) > 1) {
			    do j = 1, IM_LEN(in,3)
				do i = 1, IM_LEN(out,2)
				    call amovr (Memr[imgl3r(in,i,j)],
					Memr[impl3r(out,i,j)], IM_LEN(out,1))
			    do j = IM_LEN(in,3)+1, IM_LEN(out,3)
				do i = 1, IM_LEN(out,2)
				    call amovkr (-1., Memr[impl3r(out,i,j)],
					IM_LEN(out,1))
			}
		    }
		}
	    }

	    # Check, set, and update the WCS information.  Note that
	    # wrspectb may change the smw pointers.

	    call wrspectb (sh1, sh2, types)
	    mw1 = MW(sh1)
	    mw2 = MW(sh2)
	    call smw_saveim (mw2, out)

	    # Update spectrum calibration parameters.
	    if (EC(sh1) == ECYES)
		call imaddi (out, "EX-FLAG", EC(sh1))
	    else if (imaccf (out, "EX-FLAG") == YES)
		call imdelf (out, "EX-FLAG")
	    if (FC(sh1) == FCYES)
		call imaddi (out, "CA-FLAG", FC(sh1))
	    else if (imaccf (out, "CA-FLAG") == YES)
		call imdelf (out, "CA-FLAG")
	    if (RC(sh1) != EOS)
		call imastr (out, "DEREDDEN", RC(sh1))
	    else if (imaccf (out, "DEREDDEN") == YES)
		call imdelf (out, "DEREDDEN")

	    # Copy the spectra.
	    i =  max (1, LINDEX(sh2,1))
	    do j = 1, ntypes {
		if (types[j] == 0)
		    next
		sy = SPEC(sh1,types[j])
		if (sy == NULL)
		    next

		np1 = NP1(sh2)
		np2 = NP2(sh2)
		switch (SMW_FORMAT(mw2)) {
		case SMW_ND:
		    switch (SMW_LAXIS(mw2,1)) {
		    case 1:
			outbuf = imps3r (out, np1, np2, i, i, j, j)
		    case 2:
			outbuf = imps3r (out, i, i, np1, np2, j, j)
		    case 3:
			outbuf = imps3r (out, i, i, j, j, np1, np2)
		    }
		    call amovr (Memr[SY(sh1)], Memr[outbuf], SN(sh1))
		case SMW_ES, SMW_MS:
		    outbuf = impl3r (out, i, j)
		    call amovr (Memr[sy], Memr[outbuf+np1-1], SN(sh1))
		    if (np1 > 1)
			call amovkr (Memr[outbuf+np1-1], Memr[outbuf], np1-1)
		    if (np2 < IM_LEN(out,1))
			call amovkr (Memr[outbuf+np2-1], Memr[outbuf+np2],
			    IM_LEN(out,1)-np2)
		}
	    }

	    # Close output image if not the same as the input image.
	    if (out != in) {
		call shdr_close (sh2)
		call smw_close (mw2)
		call imunmap (out)
	    }

	    # Replace tmp image.
	    if (Memc[tmp] != EOS) {
		if (xt_imnameeq (IMNAME(sh1), output))
		    call imunmap (in)
		call imdelete (output)
		call imrename (Memc[tmp], output)
		if (xt_imnameeq (IMNAME(sh1), output))
		    in = immap (IMNAME(sh1), READ_ONLY, 0)
	    }

	} then {
	    if (out != in) {
		if (sh2 != NULL)
		    call shdr_close (sh2)
		if (mw2 != NULL)
		    call smw_close (mw2)
		if (out != NULL)
		    call imunmap (out)
	    }
	    if (Memc[tmp] != EOS && imaccess (Memc[tmp], 0) == YES)
		call imdelete (Memc[tmp])
	    call sfree (sp)
	    call erract (EA_ERROR)
	}

	call sfree (sp)
end


# WRSPECTB -- Set output WCS attributes.
# This requires checking compatibility of the WCS with other spectra
# in the image.
 
procedure wrspectb (sh1, sh2, types)

pointer	sh1			# Input
pointer	sh2			# Output
int	types[ARB]		# Spectrum types

int	i, j, beam, dtype, nw
double	w1, wb, dw, z, a, b, p1, p2, p3, shdr_lw()
real	aplow[2], aphigh[2]
pointer	in, out, smw1, smw2, mw, smw_sctran()
pointer	sp, key, str, ltm, ltv, coeff
bool	fp_equald(), strne()
errchk	mw_glterm, smw_gwattrs, smw_swattrs, smw_sctran

begin
	call smark (sp)
	call salloc (key, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)
	call salloc (ltm, 3*3, TY_DOUBLE)
	call salloc (ltv, 3, TY_DOUBLE)
	call malloc (coeff, SZ_LINE, TY_CHAR)

	in = IM(sh1)
	out = IM(sh2)
	smw1 = MW(sh1)
	smw2 = MW(sh2)
	mw = SMW_MW(smw2,0)

	# Check dispersion function compatibility.
	# Nonlinear functions can't be copied to a different physical
	# coordinate system though the linear dispersion can be
	# adjusted.

	i = SMW_PDIM(smw2)
	j = SMW_PAXIS(smw2,1)
	call mw_gltermd (mw, Memd[ltm], Memd[ltv], SMW_PDIM(smw2))
	a = Memd[ltv+(j-1)]
	b = Memd[ltm+(i+1)*(j-1)]
	if (DC(sh1) == DCFUNC) {
	    i = SMW_PDIM(smw1)
	    j = SMW_PAXIS(smw1,1)
	    call mw_gltermd (SMW_MW(smw1,0), Memd[ltm], Memd[ltv], i)
	    Memd[ltv] = Memd[ltv+(j-1)]
	    Memd[ltm] = Memd[ltm+(i+1)*(j-1)]
	   if (!fp_equald (a, Memd[ltv]) || !fp_equald (b ,Memd[ltm])) {
		call error (7,
		"Physical basis for nonlinear dispersion functions don't match")
	    }
	}

	call smw_gwattrs (smw1, LINDEX(sh1,1), LINDEX(sh1,2),
	    AP(sh1), beam, dtype, w1, dw, nw, z, aplow, aphigh, coeff)

	w1 = shdr_lw (sh1, 1D0)
	wb = shdr_lw (sh1, double(SN(sh1)))
	iferr {
	    call un_ctrand (UN(sh1), MWUN(sh1), w1, w1, 1)
	    call un_ctrand (UN(sh1), MWUN(sh1), wb, wb, 1)
	} then
	    ;

	p1 = (NP1(sh1) - a) / b
	p2 = (NP2(sh1) - a) / b
	p3 = (IM_LEN(out,1) - a) / b
	nw = nint (min (max (p1 ,p3), max (p1, p2))) + NP1(sh1) - 1
	if (p1 != p2)
	    dw = (wb - w1) / (p2 - p1) * (1 + z)
	w1 = w1 * (1 + z) - (p1 - 1) * dw

	# Note that this may change the smw pointer.
	call smw_swattrs (smw2, LINDEX(sh2,1), 1, AP(sh2), beam, dtype,
	    w1, dw, nw, z, aplow, aphigh, Memc[coeff])
	if (smw2 != MW(sh2)) {
	    switch (SMW_FORMAT(smw2)) {
	    case SMW_ND, SMW_ES:
	        i = 2 ** (SMW_PAXIS(smw2,1) - 1)
	    case SMW_MS:
		i = 3B
	    }
	    CTLW1(sh2) = smw_sctran (smw2, "logical", "world", i)
	    CTWL1(sh2) = smw_sctran (smw2, "world", "logical", i)
	    CTLW(sh2) = CTLW1(sh2)
	    CTWL(sh2) = CTWL1(sh2)
	    MW(sh2) = smw2
	    mw = SMW_MW(smw2,0)
	}

	# Copy title and spectrum type identifications.
	call smw_sapid (smw2, LINDEX(sh2,1), 1, TITLE(sh1))
	do i = 1, SH_NTYPES {
	    if (types[i] == 0)
		next
	    j = types[i]
	    if (SID(sh1,j) != NULL) {
		call sprintf (Memc[key], SZ_LINE, "BANDID%d")
		    call pargi (i)
		iferr (call imgstr (out, Memc[key], Memc[str], SZ_LINE))
		    call imastr (out, Memc[key], Memc[SID(sh1,j)])
		else {
		    if (strne (Memc[SID(sh1,j)], Memc[str]))
			call eprintf (
			    "Warning: Input and output types (BANDID) differ\n")
		}
	    }
	}

	# Copy label and units
	if (UN_LABEL(MWUN(sh1)) != EOS)
	    call mw_swattrs (mw, 1, "label", UN_LABEL(MWUN(sh1)))
	if (UN_UNITS(MWUN(sh1)) != EOS)
	    call mw_swattrs (mw, 1, "units", UN_UNITS(MWUN(sh1)))
	if (UN_USER(UN(sh1)) != EOF)
	    call mw_swattrs (mw, 1, "units_display", UN_USER(UN(sh1)))

	call mfree (coeff, TY_CHAR)
	call sfree (sp)
end


# WRTYPES -- Determine spectrum types.
# Currently this only works for multispec data.

procedure wrtypes (sh, types, ntypes)

pointer	sh			#I SHDR pointer
int	types[SH_NTYPES]	#O Spectrum types assigned to physical coords.
int	ntypes			#O Number of Spectrum types

int	i, j, ctowrd(), strdic()
pointer	sp, key, str, im, smw

begin
	im = IM(sh)
	smw = MW(sh)

	call smark (sp)
	call salloc (key, SZ_LINE, TY_CHAR)
	call salloc (str, SZ_LINE, TY_CHAR)

	# Get physical coordinate of each spectrum type in input.
	call aclri (types, SH_NTYPES)
	do i = 1, 6 {
	    call sprintf (Memc[key], SZ_LINE, "BANDID%d")
		call pargi (i)
	    ifnoerr (call imgstr (im, Memc[key], Memc[str], SZ_LINE)) {
		j = 1
		if (ctowrd (Memc[str], j, Memc[key], SZ_LINE) == 0)
		    next
		types[i] = strdic (Memc[key], Memc[key], SZ_LINE, STYPES)
	    }
	}

	# Assign the input spectra to physical coordinates if not already
	# assigned.
	do j = SHDATA, SHCONT {
	    if (SPEC(sh,j) == NULL)
		next
	    do i = 1, 6
		if (types[i] == j)
		    break
	    if (i > SHCONT) {
		do i = 1, 6 {
		    if (types[i] == 0) {
			types[i] = j
			break
		    }
		}
	    }
	}

	# Determine the number of types.
	ntypes = 0
	do i = 1, 6 {
	    if (types[i] != 0)
		ntypes = i
	}

	call sfree (sp)
end
