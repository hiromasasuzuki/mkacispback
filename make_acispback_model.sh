#! /bin/sh

### default parameter values
WEMIN=9000   # Emin for weight map and spectral fit
WEMAX=11500   # Emin for weight map and spectral fit
RMFDELTAE=0.05   # delta E of rmf
GENWMAP=1   # generate weight map or use already existing one
GENSPEC=1   # generate data spectrum or use already existing one
GENRMF=1   # generate rmf or use already existing one
CLOB="no"   # overwrite files or not
FS_EBOUNDFLAG=1   # 0: calculate "framestore lines" from each data, 1: use default
STOWEDFLAG=0   # 0: usual observation, 1: ACIS "stowed" observation
GAINFIT=1   # 1: fit with free gain parameters, 0: with fixed gain (slope=1.0, offset=0.0)
OUTMODEL="out_acispback_model.mo"   # output model file name
MONAME="acispback"   # output XSPEC model name
DIRNAME="acispback"   # output directory name which contains output spectral model
RM_TEMP=0   # remove temporary files
BIN=0   # group 9.0-11.5 keV data into one bin
NORMFIT=1   # fit the high energy total normalization or not
FAKEEVT=0	# make use of the fake event files
PLOT=1	# call a XSPEC plot window
SHAPEMOD=1   # if apply modification of spectral shape based on absolute count rate

XCM="temp_makemodel.xcm"
LMODNAME="acispback_lmod"
LMODCALC="acispback_calc"
LMODCPP="${LMODCALC}.cpp"
LMODOUTCPP="${LMODNAME}.cpp"
LMODDAT="${LMODNAME}.dat"
SCRIPT_DIR="$ACISPBACK"
INDATAMODE="none"
###


### input values
EV2FITS=$1
EV2FITS_MAIN=$(echo "${EV2FITS}" | awk -F'[\[]' '{print $1}' 2>/dev/null)
REGIONFILE=$(echo "${EV2FITS}" |grep -oE "region\(.+\)" |awk -F '[(|)]' '{print $2}' 2>/dev/null)
if [ $(echo "$@" | grep -cE "(\-h|\-\-h|\-help)") -eq 1 ]; then
	cat ${SCRIPT_DIR}/help
	exit 0
fi
if [ $(echo "$@" | grep -c "genwmap=") -eq 1 ]; then GENWMAP=$(echo "$@" | grep -cE "genwmap=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "genspec=") -eq 1 ]; then GENSPEC=$(echo "$@" | grep -cE "genspec=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "specfile=") -eq 1 ]; then
	SPECFILE=$(echo "$@" | grep -oE "(specfile=.+)" | awk -F'[ ]' '{print $1}' | awk -F'[=]' '{print $2}')
	GENSPEC=0
fi
if [ $(echo "$@" | grep -c "genrmf=") -eq 1 ]; then GENRMF=$(echo "$@" | grep -cE "genrmf=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "rmffile=") -eq 1 ]; then
	RMFFILE=$(echo "$@" | grep -oE "(rmffile=.+)" | awk -F'[ ]' '{print $1}' | awk -F'[=]' '{print $2}')
	GENRMF=0
fi
if [ $(echo "$@" | grep -c "emin=") -eq 1 ]; then
	WEMIN=$(echo "$@" | grep -oE "emin=[0-9]+" | grep -oE "[0-9]+")
	SHAPEMOD=0
fi
if [ $(echo "$@" | grep -c "emax=") -eq 1 ]; then
	WEMAX=$(echo "$@" | grep -oE "emax=[0-9]+" | grep -oE "[0-9]+")
	SHAPEMOD=0
fi
if [ $(echo "$@" | grep -c "egrid=") -eq 1 ]; then RMFDELTAE=$(echo "$@" | grep -oE "egrid=[0-9]+.[0-9]+" | grep -oE "[0-9]+.[0-9]+"); fi
if [ $(echo "$@" | grep -c "clobber=") -eq 1 ]; then CLOB=$(echo "$@" | grep -oE "clobber=(yes|\"yes\"|\'yes\'|no|\"no\"|\'no\')" | grep -oE "(yes|no)"); fi
if [ $(echo "$@" | grep -c "gainfit=") -eq 1 ]; then GAINFIT=$(echo "$@" | grep -cE "gainfit=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "outdir=") -eq 1 ]; then DIRNAME=$(echo "$@" | grep -oE "(outdir=.+)" | awk -F'[ ]' '{print $1}' | awk -F'[=]' '{print $2}'); fi
if [ $(echo "$@" | grep -c "name=") -eq 1 ]; then MONAME=$(echo "$@" | grep -oE "(name=.+)" | awk -F'[ ]' '{print $1}' | awk -F'[=]' '{print $2}'); fi
if [ $(echo "$@" | grep -c "datamode=") -eq 1 ]; then INDATAMODE=$(echo "$@" | grep -oE "(datamode=.+)" | awk -F'[ ]' '{print $1}' | awk -F'[=]' '{print $2}'); fi
if [ $(echo "$@" | grep -c "clean=") -eq 1 ]; then RM_TEMP=$(echo "$@" | grep -cE "clean=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "normfit=") -eq 1 ]; then NORMFIT=$(echo "$@" | grep -cE "normfit=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "fakeevt=") -eq 1 ]; then FAKEEVT=$(echo "$@" | grep -cE "fakeevt=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "bin=") -eq 1 ]; then BIN=$(echo "$@" | grep -cE "bin=(yes|\"yes\"|\'yes\')"); fi
if [ $(echo "$@" | grep -c "plot=") -eq 1 ]; then PLOT=$(echo "$@" | grep -cE "plot=(yes|\"yes\"|\'yes\')"); fi

FORVF=$(dmhistory ${EV2FITS} acis_process_events 2>/dev/null|grep -oE "check_vf_pha=[\"noyes]+" |grep -oE "(no|yes)")
FORVF=$(echo $FORVF |grep -oE "(no|yes)$")
if [ "$FORVF" = "no" ]; then FORVF=faint; fi
if [ "$FORVF" = "yes" ]; then FORVF=vfaint; fi
if [ "$INDATAMODE" = "faint" -o "$INDATAMODE" = "vfaint" ];then FORVF=$INDATAMODE; fi
TEMPMOD_DIR="${SCRIPT_DIR}/template_models_${FORVF}"
###

if [ ! "`echo "${EV2FITS_MAIN}" |grep -oE . |head -n 1`" = "/" -a ! "`echo "${EV2FITS_MAIN}" |grep -oE . |head -n 1`" = "~" ];then
	EV2FITS_MAIN="../${EV2FITS_MAIN}"; fi
if [ ! "$RMFFILE" = "" ] && [ ! "$(echo "${RMFFILE}" | grep -oE . | head -n 1)" = "/" -a ! "$(echo "${RMFFILE}" | grep -oE . | head -n 1)" = "~" ]; then
	RMFFILE="../${RMFFILE}"; fi
if [ ! "$SPECFILE" = "" ] && [ ! "$(echo "${SPECFILE}" | grep -oE . | head -n 1)" = "/" -a ! "$(echo "${SPECFILE}" | grep -oE . | head -n 1)" = "~" ]; then
	SPECFILE="../${SPECFILE}"; fi
if [ ! "$REGIONFILE" = "" ] && [ ! "$(echo "${REGIONFILE}" | grep -oE . | head -n 1)" = "/" -a ! "$(echo "${REGIONFILE}" | grep -oE . | head -n 1)" = "~" ]; then
	REGIONFILE="../${REGIONFILE}"; fi
ARGS="${WEMIN} ${WEMAX} ${RMFDELTAE} ${GENWMAP} ${GENSPEC} ${GENRMF} ${CLOB} ${STOWEDFLAG} ${FS_EBOUNDFLAG} ${EV2FITS_MAIN} ${FORVF} ${SCRIPT_DIR} ${TEMPMOD_DIR} ${OUTMODEL} ${XCM} ${LMODNAME} ${LMODCALC} ${LMODCPP} ${LMODOUTCPP} ${LMODDAT} ${GAINFIT} ${MONAME}"

### print some setup parameters
OBSID=$(dmkeypar "${EV2FITS}" OBS_ID echo+)
if [ $(echo "$OBSID" |grep -cE "([0-9]+|Merged)") -eq 0 -o $(echo "$FORVF" |grep -cE "(faint|vfaint)") -eq 0 ]; then
	echo -e "\nInput parameter/file error !! Exiting... \n"
	cat ${SCRIPT_DIR}/help
	exit 1
fi
if [ $(echo "${MONAME}" |grep -cE [0-9]) -gt 0 ];then
	echo -e "\nError in model name !! It contains a number !! Exiting... \n"
	exit 1
fi

echo "OBSID: $OBSID"
echo -e "Data mode= ${FORVF} \n"
###


### make a working directory
if [ ! -e "${DIRNAME}" ]; then mkdir "${DIRNAME}"; fi

### create region-selected event file
if [ $((GEMSPEC+GENWMAP+GENRMF)) -gt 0 ]; then
	punlearn dmcopy
	dmcopy "${EV2FITS}" ${DIRNAME}/temp_evt_regfil.evt option=all clobber="$CLOB" >/dev/null
	if [ $? -gt 0 ]; then
		echo "Exiting due to an error while making a filtered event file..."; exit 1;fi
fi

cd "$DIRNAME"

### make 32x32-binned weight map corresponding to input region
punlearn dmextract
dmextract infile="temp_evt_regfil.evt[energy=$WEMIN:$WEMAX][bin pi=1:1024:1]" mode=h verbose=0 outfile=temp_totcnts.pi clobber=$CLOB >/dev/null
TOTCNTS=$(dmkeypar temp_totcnts.pi TOTCTS echo+)
if [ $TOTCNTS -lt 50 ]; then
	echo "Total count number in the input region is small. Will create fake event files to generate spectral model."
	FAKEEVT=1
	SHAPEMOD=0
fi
if [ "$FAKEEVT" -eq 1 ]; then
	echo "Creating fake event files..."
	${ACISPBACK_PYTHON} ${SCRIPT_DIR}/create_fake_events.py --input_file ${EV2FITS_MAIN} --output_dir ./
	echo "Created."
	if [ $? -gt 0 ]; then
		echo "Exiting due to an error while creating fake events..."
		exit 1
	fi
fi
bash ${SCRIPT_DIR}/makewmap.sh $REGIONFILE $ARGS $FAKEEVT
if [ $? -gt 0 ]; then
	echo "Exiting due to an error while extracting a count (weight) map..."
	exit 1
fi
rm temp_fake_events_ccd?.fits 2>/dev/null

### extract spectrum and rmf from input region
if [ "$GENRMF" -eq 0 -a $(echo "$@" |grep -c "rmffile=") -eq 1 ]; then cp $RMFFILE temp.rmf; fi
if [ "$GENSPEC" -eq 0 -a $(echo "$@" |grep -c "specfile=") -eq 1 ]; then
	cp $SPECFILE temp_spec_original.pi
	test -f temp_spec.pi && rm temp_spec.pi
	punlearn dmgroup
	dmgroup temp_spec_original.pi temp_spec.pi grouptype=NONE xcolumn=pi grouptypeval=0 binspec="" ycolumn=counts
fi
if [ $TOTCNTS -gt 0 ] && [ "$GENRMF" -gt 0 -o "$GENSPEC" -gt 0 ]; then
	bash ${SCRIPT_DIR}/makespecandrmf.sh $ARGS
	if [ $? -gt 0 ]; then
		echo "Exiting due to an error while extracting spectrum and RMF..."
		exit 1
	fi
elif [ $TOTCNTS -eq 0 ] && [ "$RMFFILE" = "" -o "$SPECFILE" = "" ]; then
	echo -e "\nCannot create RMF/spectrum because the total count number is 0 !!"
	echo "Please provide RMF file with \"rmffile=<name>\" and spectrum file with \"specfile=<name>\"."
	exit 1
fi
if [ $TOTCNTS -eq 0 ] && [ "$SPECFILE" = "" ]; then NORMFIT=0; fi

### take weighed-sum over template models
if [ "$FORVF" = "faint" ]; then
	bash ${SCRIPT_DIR}/makemodelfunction_faint.sh $ARGS $SHAPEMOD
	if [ $? -gt 0 ]; then
		echo "Exiting due to an error while constructing a spectral model..."
		exit 1
	fi
fi
if [ "$FORVF" = "vfaint" ]; then
	bash ${SCRIPT_DIR}/makemodelfunction_vfaint.sh $ARGS $SHAPEMOD
	if [ $? -gt 0 ]; then
		echo "Exiting due to an error while constructing a spectral model..."
		exit 1
	fi
fi

### calibrate the output spectral model
bash ${SCRIPT_DIR}/calibratemodel_gainfit.sh $ARGS $BIN $NORMFIT $PLOT
if [ $? -gt 0 ]; then
	echo "Exiting due to an error while calibrating the spectral model..."
	exit 1
fi

## print some basic statistics
echo "Total counts in the input region ($WEMIN-$WEMAX eV): $TOTCNTS"
if [ $TOTCNTS -gt 0 -o ! "$SPECFILE" = "" ]; then
	BACKSCAL=$(dmkeypar temp_spec.pi backscal echo+)
	EXPOSURE=$(dmkeypar temp_spec.pi exposure echo+)
	AREA=$(perl -e "print $BACKSCAL *(8192*0.492/60.)**2")
	echo "Effective exposure (s): $EXPOSURE  (from spectral file)"
	echo "Area (arcmin^2): $AREA  (from spectral file)"
fi

### remove temporary files
if [ "$RM_TEMP" -eq 1 ]; then
	echo -e "\nRemoving temporary files...\n"
	rm temp*
fi

echo -e "All done.\n"
cd ../
