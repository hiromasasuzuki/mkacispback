mkacispback
=======================  
A software to generate spectral models for Chandra ACIS particle-induced background.  
Version: 2021-07-15  
Author: Hiromasa Suzuki (The University of Tokyo)  
hiromasa050701 (at) gmail.com  


### Requirements:
- c++11 compiler (ver. 4.2.1, 4.8.5 tested)
- python (ver. 3.0 or later reguired, 3.5.4, 3.6.8, 3.8.5 tested) with "astropy" library
- CIAO (ver. 4.10, 4.11, 4.12 tested)
- HEAsoft (ver. 6.20, 6.26, 6.27 tested)


### How to use the software:
1. Set three environment variables as below:

       export ACISPBACK=</path/to/this directory>
       export ACISPBACK_PYTHON=</path/to/python**>   # python with astropy library (ex. "export ACISPBACK_PYTHON=/usr/local/bin/python3.7")
       export ACISPBACK_GXX=</path/to/g++**>   # g++ which supports c++11 (ex. "export ACISPBACK_GXX=/usr/local/bin/g++-9")

2. Copy the executable file "mkacispback" to /usr/local/bin (or somewhere in the $PATH).
3. Initialize HEAsoft and CIAO before running this command. The environment variable $CALDB must point at the CIAO CALDB.
4. Run "mkacispback --h" to see the usage.


### Notes:
- By default, mkacispback newly creates an rmf file corresponding to the input source region and this takes some time. To prevent this, provide a prepared rmf file by "genrmf=no" and "rmffile=FILENAME".
- Output model name must not include numbers, upper case letters, and must not begin with the words already registerd as an XSPEC model (e.g., "name=src" leads to an error because "src" is recognized as the "srcut" model).
- Depending on the observation date, mkacispback may predict lower background coninua in ~ 2-6 keV especially for the S1 and S3 CCDs. In such cases, you may have to add a power-law model. Please refer to figures which compare mkacispback output models to ACIS-stowed observations for each CCD. To get date from OBSID, refer to the paper below.
	- VFAINT mode 
![I0, vfaint mode](figures/vfaint_ccd0_tiled-crop.pdf)
![I2, vfaint mode](figures/vfaint_ccd2_tiled-crop.pdf)
![I3, vfaint mode](figures/vfaint_ccd3_tiled-crop.pdf)
![S1, vfaint mode](figures/vfaint_ccd5_tiled-crop.pdf)
![S2, vfaint mode](figures/vfaint_ccd6_tiled-crop.pdf)
![S3, vfaint mode](figures/vfaint_ccd7_tiled-crop.pdf)
	- FAINT mode 
![I0, faint mode](figures/faint_ccd0_tiled-crop.pdf)
![I2, faint mode](figures/faint_ccd2_tiled-crop.pdf)
![I3, faint mode](figures/faint_ccd3_tiled-crop.pdf)
![S1, faint mode](figures/faint_ccd5_tiled-crop.pdf)
![S2, faint mode](figures/faint_ccd6_tiled-crop.pdf)
![S3, faint mode](figures/faint_ccd7_tiled-crop.pdf)
- Note that using an analysis region covering multiple CCDs may result in a large discrepancy between the data and acispback model. If so, apply mkacispback for individual CCDs and do a simultaneous fit.
- Full XSPEC model expressions for each CCD depending on CHIPY regions can be found in [template_models_faint](template_models_faint) and [template_models_vfaint](template_models_vfaint) directories. The 32 models corresponding to different CHIPY positions are stored. The files including "y01" and "y32" in their names, for example, correspond to CHIPY=1:32  and CHIPY=993:1024 ranges, respectively.


### Test platforms:
- MacOS 10.14, 10.15
- CentOS 7


### Reference:
- Suzuki et al. 2021, A&A, in prep. ([arXiv link](https://arxiv.org/abs/2108.11234))
