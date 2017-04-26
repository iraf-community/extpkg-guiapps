include <imhdr.h>
include <time.h>
include <ctype.h>

define	SZ_DIMSTR 	(1 + 6 * IM_MAXDIM)


# XP_PIMHEADER -- Page the header list.

procedure xp_pimheader (gd, im)

pointer	gd		#I the pointer to the graphics stream
pointer	im		#I the pointer to the input image

int	tmp
pointer	sp, tmpname
int	open()

begin
	call smark (sp)
	call salloc (tmpname, SZ_FNAME, TY_CHAR)
	call mktemp ("tmp$hdr", Memc[tmpname], SZ_FNAME)
	tmp = open (Memc[tmpname], NEW_FILE, TEXT_FILE)
	call xp_imheader (im, tmp, NO)
	call close (tmp)
	call gpagefile (gd, Memc[tmpname], "")
	call delete (Memc[tmpname])

	call sfree (sp)
end


# XP_IMHEADER -- Format the image header and store it in a string.

procedure xp_imheader (im, fd, listfmt) 

pointer	im		#I the pointer to the input image
int	fd		#I the output file descriptor
int	listfmt		#I list format ?

int	ip
pointer	sp, ctime, mtime, ldim, pdim, title
int	gstrcpy(), access(), strncmp()

begin
        # Allocate automatic buffers.
        call smark (sp)
        call salloc (ctime, SZ_TIME, TY_CHAR)
        call salloc (mtime, SZ_TIME, TY_CHAR)
        call salloc (ldim, SZ_DIMSTR, TY_CHAR)
        call salloc (pdim, SZ_DIMSTR, TY_CHAR)
        call salloc (title, SZ_LINE, TY_CHAR)

	# Format subscript strings, date strings, mininum and maximum
        # pixel values.
        call xp_fmt_dimensions (im, Memc[ldim], SZ_DIMSTR, IM_LEN(im,1))
        call xp_fmt_dimensions (im, Memc[pdim], SZ_DIMSTR, IM_PHYSLEN(im,1))
        call cnvtime (IM_CTIME(im), Memc[ctime], SZ_TIME)
        call cnvtime (IM_MTIME(im), Memc[mtime], SZ_TIME)

        # Strip any trailing whitespace from the title string.
        ip = title + gstrcpy (IM_TITLE(im), Memc[title], SZ_LINE) - 1
        while (ip >= title && IS_WHITE(Memc[ip]) || Memc[ip] == '\n')
            ip = ip - 1
        Memc[ip+1] = EOS

	# Begin printing image header.
	if (listfmt == NO)
            call fprintf (fd, "%s%s[%s]: %s\n")
	else
            call fprintf (fd, "{%s%s[%s]: %s}\n")
                call pargstr (IM_HDRFILE(im))
                call pargstr (Memc[ldim])
                call xp_pargtype (IM_PIXTYPE(im))
                call pargstr (Memc[title])

	if (listfmt == NO)
	    call fprintf (fd,
	        "%4w%s bad pixels, %s histogram, min=%s, max=%s%s\n")
	else
	    call fprintf (fd,
	        "{%4w%s bad pixels, %s histogram, min=%s, max=%s%s}\n")
        if (IM_NBPIX(im) == 0)
            call pargstr ("No")
        else
            call pargl (IM_NBPIX(im))

        #if (HGM_TIME(IM_HGM(im)) == 0)
            call pargstr ("no")
        #else if (HGM_TIME(IM_HGM(im)) < IM_MTIME(im))
            #call pargstr ("old")
        #else
            #call pargstr ("valid")

        if (IM_LIMTIME(im) == 0) {
            call pargstr ("unknown")
            call pargstr ("unknown")
            call pargstr ("")
        } else {
            call pargr (IM_MIN(im))
            call pargr (IM_MAX(im))
            if (IM_LIMTIME(im) < IM_MTIME(im))
                call pargstr (" (old)")
            else
                call pargstr ("")
        }

	if (listfmt == NO)
	    call fprintf (fd,
            "%4w%s storage mode, physdim %s, length of user area %d s.u.\n")
	else
	    call fprintf (fd,
            "{%4w%s storage mode, physdim %s, length of user area %d s.u.}\n")
            call pargstr ("Line")
            call pargstr (Memc[pdim])
            call pargi (IM_HDRLEN(im) - LEN_IMHDR)

	if (listfmt == NO)
            call fprintf (fd, "%4wCreated %s, Last modified %s\n")
	else
            call fprintf (fd, "{%4wCreated %s, Last modified %s}\n")
            call pargstr (Memc[ctime])
            call pargstr (Memc[mtime])

	if (listfmt == NO)
            call fprintf (fd, "%4wPixel file '%s' %s\n")
	else
            call fprintf (fd, "{%4wPixel file '%s' %s}\n")
            call pargstr (IM_PIXFILE(im))
        if (access (IM_PIXFILE(im), 0, 0) == YES)
            call pargstr ("[ok]")
	else if (strncmp (IM_PIXFILE(im), "HDR$", 4) == 0)
            call pargstr ("[ok]")
        else
            call pargstr ("[NO PIXEL FILE]")

       # Print the user area.
	call xp_imuser (im, fd, listfmt)

	call sfree (sp)
end


# XP_FMT_DIMENSIONS -- Format the image dimensions in the form of a subscript,
# i.e., "[nx,ny,nz,...]".

procedure xp_fmt_dimensions (im, outstr, maxch, len_axes)

pointer im			#I the pointer to the input image
char    outstr[ARB]		#O the output string
int     maxch			#I the maximum size of the output string
long	len_axes[ARB]		#I the input array of axes lengths

int	i, fd
int	stropen()

begin
        fd = stropen (outstr, maxch, NEW_FILE)

        call fprintf (fd, "[%d")
            call pargl (len_axes[1])

        do i = 2, IM_NDIM(im) {
            call fprintf (fd, ",%d")
                call pargl (len_axes[i])
        }

        call fprintf (fd, "]")
        call close (fd)
end


# XP_IMUSER -- Print the user area of the image, if nonzero length
# and it contains only ascii values.

procedure xp_imuser (im, out, listfmt)

pointer im                      #I the image descriptor
int     out                     #I the output file
int	listfmt			#I list format ?

pointer sp, lbuf, ip
int     in,  min_lenuserarea
int     stropen(), getline()

begin
        call smark (sp)
        call salloc (lbuf, SZ_LINE, TY_CHAR)

        # Open user area in header.
        min_lenuserarea = (IM_HDRLEN(im) - LEN_IMHDR) * SZ_STRUCT
        in = stropen (Memc[IM_USERAREA(im)], min_lenuserarea, READ_ONLY)

        # Copy header records to the output, stripping any trailing
        # whitespace and clipping at the right margin.

        while (getline (in, Memc[lbuf]) != EOF) {
            for (ip=lbuf;  Memc[ip] != EOS && Memc[ip] != '\n';  ip=ip+1)
                ;
            while (Memc[ip-1] == ' ')
                ip = ip - 1
	    Memc[ip] = EOS
            #Memc[ip] = '\n'
            #Memc[ip+1] = EOS

	    if (listfmt == NO)
                call putline (out, "    ")
	    else
                call putline (out, "{    ")
            call putline (out, Memc[lbuf])
	    if (listfmt == NO)
                call putline (out, "\n")
	    else
                call putline (out, "}\n")
        }

        call close (in)
        call sfree (sp)
end


# XP_PARGTYPE -- Convert an integer type code into a string, and output the
# string with PARGSTR to FMTIO.

procedure xp_pargtype (dtype)

int     dtype			#I the input data type

begin
        switch (dtype) {
        case TY_UBYTE:
            call pargstr ("ubyte")
        case TY_BOOL:
            call pargstr ("bool")
        case TY_CHAR:
            call pargstr ("char")
        case TY_SHORT:
            call pargstr ("short")
        case TY_USHORT:
            call pargstr ("ushort")
        case TY_INT:
            call pargstr ("int")
        case TY_LONG:
            call pargstr ("long")
        case TY_REAL:
            call pargstr ("real")
        case TY_DOUBLE:
            call pargstr ("double")
        case TY_COMPLEX:
            call pargstr ("complex")
        case TY_POINTER:
            call pargstr ("pointer")
        case TY_STRUCT:
            call pargstr ("struct")
        default:
            call pargstr ("unknown datatype")
        }
end
