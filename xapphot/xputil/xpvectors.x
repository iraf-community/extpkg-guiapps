include <math.h>

# XP_WLIMR -- Set the weights of all data points outside a given minimum and
# maximum value to zero. Compute the minimum and maximum values and the
# indices of the remaining data.

procedure xp_wlimr (pix, w, npts, datamin, datamax, dmin, dmax, imin, imax)

real    pix[ARB]                #I the input pixel array
real    w[ARB]                  #I the weight array
int     npts                    #I the number of points
real    datamin                 #I the minimum good data point
real    datamax                 #I the maximum good data point
real    dmin                    #O the output data minimum
real    dmax                    #O the output data maximum
int     imin                    #I the index of the data minimum
int     imax                    #I the index of the data maximum

int     i
real    value

begin
        dmin = datamax
        dmax = datamin
        imin = 1
        imax = 1

        do i = 1, npts {
            value = pix[i]
            if ((value < datamin) || (value > datamax)) {
                w[i] = 0.0
                next
            }
            if (value  < dmin) {
                dmin = value
                imin = i
            } else if (value  > dmax) {
                dmax = value
                imax = i
            }
        }
end


# XP_ALIMR -- Compute the maximum and minimum data values and indices of a
# 1D array.

procedure xp_alimr (data, npts, mindat, maxdat, imin, imax)

real	data[npts]	#I the input data array
int	npts		#I the number of points
real	mindat, maxdat	#O the minimum and maximum data values
int	imin, imax	#O the indices of the minimum and maximum data values

int	i

begin
	imin = 1
	imax = 1
	mindat = data[1]
	maxdat = data[1]

	do i = 2, npts {
	    if (data[i] > maxdat) {
		imax = i
		maxdat = data[i]
	    }
	    if (data[i] < mindat) {
		imin = i
		mindat = data[i]
	    }
	}
end


define	LOGPTR		20			# log2(maxpts) (1e6)

# XP_QSORT -- Vector Quicksort. In this version the index array is
# sorted.

procedure xp_qsort (data, a, b, npix)

real	data[ARB]		#I the data array
int	a[ARB]			#I the input index array
int	b[ARB]			#O the output index array
int	npix			#I the number of pixels

int	i, j, lv[LOGPTR], p, uv[LOGPTR], temp
real	pivot

begin
	# Initialize the indices for an inplace sort.
	do i = 1, npix
	    a[i] = i
	call amovi (a, b, npix)

	p = 1
	lv[1] = 1
	uv[1] = npix
	while (p > 0) {

	    # If only one elem in subset pop stack otherwise pivot line.
	    if (lv[p] >= uv[p])
		p = p - 1
	    else {
		i = lv[p] - 1
		j = uv[p]
		pivot = data[b[j]]

		while (i < j) {
		    for (i=i+1;  data[b[i]] < pivot;  i=i+1)
			;
		    for (j=j-1;  j > i;  j=j-1)
			if (data[b[j]] <= pivot)
			    break
		    if (i < j) {		# out of order pair
			temp = b[j]		# interchange elements
			b[j] = b[i]
			b[i] = temp
		    }
		}

		j = uv[p]			# move pivot to position i
		temp = b[j]			# interchange elements
		b[j] = b[i]
		b[i] = temp

		if (i-lv[p] < uv[p] - i) {	# stack so shorter done first
		    lv[p+1] = lv[p]
		    uv[p+1] = i - 1
		    lv[p] = i + 1
		} else {
		    lv[p+1] = i + 1
		    uv[p+1] = uv[p]
		    uv[p] = i - 1
		}

		p = p + 1			# push onto stack
	    }
	}
end


# XP_CLIP -- Clip the ends of a sorted pixel distribution by a certain
# percent.

int procedure xp_clip (skypix, index, npix, loclip, hiclip, loindex, hiindex)

real	skypix[ARB]		#I the input unsorted array of sky pixels
int	index[ARB]		#U the output sorted array of indices
int	npix			#I the number of sky pixels
real	loclip, hiclip		#I the clipping factors in percent
int	loindex, hiindex	#O the output clipping indices

begin
	# Sort the pixels.
	call xp_qsort (skypix, index, index, npix)

	# Determine the clipping factors.
	loindex = nint (0.01 * loclip * npix) + 1
	hiindex = npix - nint (0.01 * hiclip * npix)

	# Return the number of pixels remaining.
	if ((hiindex - loindex + 1) <= 0)
	    return (npix)
	else
	    return (loindex - 1 + npix - hiindex)
end


# XP_IALIMR -- Compute the maximum and minimum data values of an indexed
# sorted array.

procedure xp_ialimr (data, index, npts, mindat, maxdat)

real	data[npts]		#I the input data array
int	index[npts]		#I the input index array
int	npts			#I the number of points
real	mindat, maxdat		#O the output min and max data value

int	i

begin
	mindat = data[index[1]]
	maxdat = data[index[1]]
	do i = 2, npts {
	    if (data[index[i]] > maxdat)
		maxdat = data[index[i]]
	    if (data[index[i]] < mindat)
		mindat = data[index[i]]
	}
end


# XP_INDEX -- Define an index array.

procedure xp_index (index, npix)

int	index[ARB]		#O the output index array
int	npix			#I the number of pixels

int	i

begin
	do i = 1, npix
	    index[i] = i
end


# XP_SBOXR -- Boxcar smooth for a vector that has not been boundary
# extended.

procedure xp_sboxr (in, out, npix, nsmooth)

real	in[npix]		#I the input array 
real	out[npix]		#I the output array
int	npix			#I the number of pixels
int	nsmooth			#I the half width of smoothing box

int	i, j, ib, ie, ns
real	sum

begin
	ns = 2 * nsmooth + 1
	do i = 1, npix {
	    ib = max (i - nsmooth, 1)
	    ie = min (i + nsmooth, npix)
	    sum = 0.0
	    do j = ib, ie
	        sum = sum + in[j]
	    out[i] = sum / ns
	}
end


# XP_HIGMR -- Accumulate the histogram of the input vector.  The output vector
# hgm (the histogram) should be cleared prior to the first call. The procedure
# returns the number of data values it could not include in the histogram.

int procedure xp_higmr (data, wgt, index, npix, hgm, nbins, z1, z2)

real 	data[ARB]		#I the data vector
real	wgt[ARB]		#I the weights vector
int	index[ARB]		#I the index vector
int	npix			#I the number of pixels
real	hgm[ARB]		#O the output histogram
int	nbins			#I the number of bins in histogram
real	z1, z2			#I the greyscale values of first and last bins

real	dz
int	bin, i, nreject

begin
	if (nbins < 2)
	    return (0)

	nreject = 0
	dz = real (nbins - 1) / real (z2 - z1)
	do i = 1, npix {
	    if (data[index[i]] < z1 || data[index[i]] > z2) {
		nreject = nreject + 1
		wgt[index[i]] = 0.0
		next
	    }
	    bin = int ((data[index[i]] - z1) * dz) + 1
	    hgm[bin] = hgm[bin] + 1.0
	}

	return (nreject)
end


# XP_HGMR -- Accumulate the histogram of the input vector.  The output vector
# hgm (the histogram) should be cleared prior to the first call. The procedure
# returns the number of data values it could not include in the histogram.

int procedure xp_hgmr (data, wgt, npix, hgm, nbins, z1, z2)

real 	data[ARB]	    #I the data vector
real	wgt[ARB]	    #I the weights vector
int	npix		    #I the number of pixels
real	hgm[ARB]	    #O the output histogram
int	nbins		    #I the number of bins in the histogram
real	z1, z2		    #I the greyscale values of the first and last bins

real	dz
int	bin, i, nreject

begin
	if (nbins < 2)
	    return (0)

	nreject = 0
	dz = real (nbins - 1) / real (z2 - z1)
	do i = 1, npix {
	    if (data[i] < z1 || data[i] > z2) {
		nreject = nreject + 1
		wgt[i] = 0.0
		next
	    }
	    bin = int ((data[i] - z1) * dz) + 1
	    hgm[bin] = hgm[bin] + 1.0
	}

	return (nreject)
end


# XP_MAPR -- Vector linear transformation.  Map the range of pixel values
# a1, a2 from a into the range b1, b2 into b.  It is assumed that a1 < a2
# and b1 < b2.

real procedure xp_mapr (a, a1, a2, b1, b2)

real	a		#I the value to be mapped
real	a1, a2		#I the numbers specifying the input data range
real	b1, b2		#I the numbers specifying the output data range

real	minout, maxout, aoff, boff
real	scalar

begin
	scalar = (real (b2) - real (b1)) / (real (a2) - real (a1))
	minout = min (b1, b2)
	maxout = max (b1, b2)
	aoff = a1
	boff = b1
	return (max (minout, min (maxout, real ((a - aoff) * scalar) + boff)))
end


# XP_AMAXEL -- Find the maximum value and its index of a 1D array.

procedure xp_amaxel (a, npts, maxdat, imax)

real	a[ARB]		#I the data array
int	npts		#I the number of points
real	maxdat		#O the maximum value
int	imax		#O the index of max value


int	i

begin
	maxdat = a[1]
	imax = 1
	do i = 2, npts {
	    if (a[i] > maxdat) {
		maxdat = a[i]
		imax = i
	    }
	}
end


# XP_SXYTOR -- Change the single integer coord of the sky pixels to a radial
# distance value. The integer coordinate is equal to coord = (i - xc + 1) +
# blklen * (j - yc).

procedure xp_sxytor (coords, index, r, nskypix, xc, yc, xblklen, yblklen)

int	coords[ARB]		#I the sky pixel coordinates array
int	index[ARB]		#I the sky pixel coordinates index array
real	r[ARB]			#O the output radial coordinates
int	nskypix			#I the number of sky pixels
real	xc, yc			#I the center of symmetry of the sky pixels
int	xblklen,yblklen		#I dimensions of the sky subraster

int	i, x, y

begin
	do i = 1, nskypix {
	    x = real (mod (coords[index[i]], xblklen))
	    if (x == 0)
		x = xblklen
	    y = (coords[index[i]] - x) / xblklen + 1 
	    r[i] = sqrt ((x - xc) ** 2 + (y - yc) ** 2)
	}
end


# XP_SXYTOE -- Change the single integer coord of the sky pixels to a radial
# distance value. The integer coordinate is equal to coord = (i - xc + 1) +
# blklen * (j - yc).

procedure xp_sxytoe (coords, index, pa, nskypix, xc, yc, xblklen, yblklen)

int	coords[ARB]		#I the sky pixel coordinates array
int	index[ARB]		#I the sky pixel coordinates index array
real	pa[ARB]			#O the the output radial coordinates
int	nskypix			#I number of sky pixels
real	xc, yc			#I the center of symmetry of the sky pixels
int	xblklen,yblklen		#I the dimensions of the sky subraster

int	i, x, y

begin
	do i = 1, nskypix {
	    x = real (mod (coords[index[i]], xblklen))
	    if (x == 0)
		x = xblklen
	    y = (coords[index[i]] - x) / xblklen + 1 
	    pa[i] = RADTODEG(atan2 (real (y - yc), real(x - xc)))
	    if (pa[i] < 0.0)
		pa[i] = 360.0 + pa[i]
	}
end


# XP_ASUMR - Compute the sum of an index sorted array

real procedure xp_asumr (data, index, npts)

real    data[npts]      #I the data array
int     index[npts]     #I the index array
int     npts            #I the  number of points

double  sum
int     i

begin
        sum = 0.0d0
        do i = 1, npts
            sum = sum + data[index[i]]
        return (real (sum))
end


# XP_RECIPROCAL -- Compute the reciprocal of the absolute value of a vector.

procedure xp_reciprocal (a, b, npts, value)

real    a[ARB]          #I the input vector
real    b[ARB]          #O the output vector
int     npts            #I the number of data points
real    value           #I the value to be assigned to b[i] if a[i] = 0

int     i

begin
        do i = 1, npts {
            if (a[i] > 0.0)
                b[i] = 1.0 / a[i]
            else if (a[i] < 0.0)
                b[i] = - 1.0 / a[i]
            else
                b[i] = value
        }
end


# XP_WSSQR -- Compute the weighted sum of the squares of a vector.

real procedure xp_wssqr (a, wgt, npts)

real    a[ARB]          #I the data array
real    wgt[ARB]        #I the array of weights
int     npts            #I the number of points

int     i
real    sum

begin
        sum = 0.0
        do i = 1, npts
            sum = sum + wgt[i] * a[i] * a[i]
        return (sum)
end
