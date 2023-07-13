#! /usr/bin/env python

import sys
from astropy.io import fits

fits = fits.open(sys.argv[1])
data = fits[0].data
sum32 = 0
for i in range(0, len(data)):
	for j in range(0, len(data)):
		sum32 += data[i][j]
	print(sum32)
	sum32 = 0
