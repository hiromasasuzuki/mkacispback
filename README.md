mkacispback
=======================  
A software to generate spectral models for Chandra ACIS (I and S1-S3) particle-induced background.  
Version: 2023-09-23 
Author: Hiromasa Suzuki (The University of Tokyo)  
   hiromasa050701 (at) gmail.com  
Contributors: Taweewat Somboonpanyakul, Adam Mantz, Steven W. Allen (Stanford University)


### Requirements:
- c++11 compiler (ver. 4.2.1, 4.8.5 tested)
- python (ver. 3.0 or later required; 3.5.4, 3.6.8, 3.8.5, 3.10.8 tested) with "astropy" library
- CIAO (ver. 4.10, 4.11, 4.12, 4.14, 4.15 tested)
- HEAsoft (ver. 6.20, 6.26, 6.27, 6.29, 6.30 tested)


### How to use the software:
1. Set three environment variables as below:

       export ACISPBACK=</path/to/this directory>
       export ACISPBACK_PYTHON=</path/to/python**>   # python with astropy library (ex. "export ACISPBACK_PYTHON=/usr/local/bin/python3.7")
       export ACISPBACK_GXX=</path/to/g++**>   # g++ which supports c++11 (ex. "export ACISPBACK_GXX=/usr/local/bin/g++-9")

2. Copy the executable file "mkacispback" to /usr/local/bin (or somewhere in $PATH).
3. Initialize HEAsoft and CIAO before running this command. The environment variable $CALDB must point at the CIAO CALDB. With CONDA CIAO, initialize HEAsoft and then activate CIAO, and finally set HEADAS to the HEAsoft directory.
4. Run mkacispback by, e.g., 
 
       $ mkacispback "acisf00000_evt2.fits.gz[sky=region(source.reg)]" outdir=pback-source name=pb_src
       OBSID: 00000
       Data mode= faint

       Processing CCD0.
       Creating weight map...
         Created.
         
	   (skipped)
	   
	   Extracting spectrum...
	   Extracted.
	   Creating rmf...
	   WARNING: Did not find 'GRATTYPE' in supplied header, skipping it
	   WARNING: Did not find 'CCD_ID' in supplied header, skipping it
	   WARNING: Did not find 'GRATTYPE' in supplied header, skipping it
	   Created.
	   Generating spectral model...
	     Processing CCD0.
		 Processing CCD1.
           Skipping...
           
	   (skipped)
	   
	   normalization factor = 0.347810
       gain slope=  1.00290 +/- 6.46455E-03
	   gain offset=  7.50589E-02 +/- 0.175410
       C-Statistic/d.o.f.= 185.85/169

       Done.

       Total counts in the input region (9000-11500 eV): 980
       Effective exposure (s): 88981.47389096  (from spectral file)
	   Area (arcmin^2): 1.2544916861928  (from spectral file)
	   All done.

   Particle-induced background spectral model named "pb_src" for the sky region "source.reg" will be gerenated in the directory "pback-source".

5. To load the model in XSPEC, 

       XSPEC> lmod pb_src_pkg ./pback-source   # if you are at the parent directory of "pback-source" directory

6. See more instruction with "mkacispback --h"


### Notes:
- By default, mkacispback newly creates an RMF file corresponding to the input source region and this may take some time. To prevent this, provide a prepared RMF file by "rmffile=FILENAME".
- Output model name must not include numbers, upper case letters, and must not begin with the words already registered as an XSPEC model (e.g., "name=src" leads to an error because "src" is recognized as the "srcut" model).
- Depending on the observation date, mkacispback may predict lower background continua in ~ 2-6 keV especially for the S1 and S3 CCDs. In such cases, you may have to add an additional power-law model. Please refer to the figures below which compare mkacispback output models to ACIS-stowed observations for each CCD. To get date from OBSID, refer to the paper below.
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
- Note that using an analysis region covering multiple CCDs may result in larger discrepancies between the data and acispback model than expected. If so, apply mkacispback for individual CCDs and do a simultaneous fit.
- Full XSPEC model expressions for each CCD depending on CHIPY regions can be found in [template_models_faint](template_models_faint) and [template_models_vfaint](template_models_vfaint) directories. The 32 models corresponding to different CHIPY positions are stored. The files including "y01" and "y32" in their names, for example, correspond to CHIPY=1:32  and CHIPY=993:1024 ranges, respectively.


### Test platforms:
- MacOS 10.14, 10.15, 11.4, 12.2 (Intel-based), 12.0, 13.5 (Apple M1)
- CentOS 7


### Known issues:
- May not work with HEASoft 6.29 due to the "initpackage" error

### Reference:
- [Suzuki et al. 2021, A&A, 665, A116](https://doi.org/10.1051/0004-6361/202141458)

