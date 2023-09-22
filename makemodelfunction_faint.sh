WEMIN=$1
WEMAX=$2
RMFDELTAE=$3
GENWMAP=$4
GENSPEC=$5
GENRMF=$6
CLOB=$7
STOWEDFLAG=$8
FS_EBOUNDFLAG=$9
EV2FITS=${10}
FORVF=${11}
SCRIPT_DIR=${12}
TEMPMOD_DIR_STEM=${13}
OUTMODEL=${14}
XCM=${15}
LMODNAME=${16}
LMODCALC=${17}
LMODCPP=${18}
LMODOUTCPP=${19}
LMODDAT=${20}
SHAPEMOD=${23}
COMPLOG="compilation.log"
#AVERATE=${23}
#ALPHA=${24}

MAINFUNC="flux_temp = "

## generate proper model for each CCD
if [ "$CLOB" = "yes" ] || [ "$CLOB" = "no" -a ! -e "emin.dat" -a ! -e "emax.dat" ]; then
	rm temp_emin.dat temp_emax.dat 2>/dev/null
	dmlist "temp.rmf[cols ENERG_LO]" opt=data outfile=temp_emin_.dat
	cat temp_emin_.dat |grep -oE "[0-9]+\s+[0-9]+.[0-9]+" |grep -oE "\s[0-9]+.[0-9]+" >emin.dat
	dmlist "temp.rmf[cols ENERG_HI]" opt=data outfile=temp_emax_.dat
	cat temp_emax_.dat |grep -oE "[0-9]+\s+[0-9]+.[0-9]+" |grep -oE "\s[0-9]+.[0-9]+" >emax.dat
	while read line; do RMFDELTAE=$line; break; done <emin.dat
	while read line; do RMFDELTAE=`perl -e "print $line - $RMFDELTAE"`; break; done <emax.dat
else echo "clobber error while making emin.dat & emax.dat."; exit 1; fi

echo "Generating spectral model..."
for CCD in 0 1 2 3 5 6 7 ; do
echo -e "  Processing CCD${CCD}."
LINE_E=()
declare -a LINE_E=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
LINE_SIGMA=()
declare -a LINE_SIGMA=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
LINE_TOT=()
declare -a LINE_TOT=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
FSLINE=()
FS_ELOW=()
FS_EHIGH=()
GABS1_E=()
GABS1_S=()
GABS1_N=()
GABS2_E=()
GABS2_S=()
GABS2_N=()
LINE1_E=()
LINE1_S=()
LINE1_N=()
LINE2_E=()
LINE2_S=()
LINE2_N=()
PL_G=()
PL_N=()
CONST_EXP=()
EXP_F=()

PL_BI_G=()
PL_BI_N=()
PL_BI2_G=()
PL_BI2_N=()
G1_E=()
G1_S=()
G1_N=()
G2_E=()
G2_S=()
G2_N=()
G3_E=()
G3_S=()
G3_N=()
G4_E=()
G4_S=()
G4_N=()
G5_E=()
G5_S=()
G5_N=()
G6_E=()
G6_S=()
G6_N=()
G7_E=()
G7_S=()
G7_N=()
G8_E=()
G8_S=()
G8_N=()
G9_E=()
G9_S=()
G9_N=()
G10_E=()
G10_S=()
G10_N=()
G11_E=()
G11_S=()
G11_N=()
G12_E=()
G12_S=()
G12_N=()
G13_E=()
G13_S=()
G13_N=()
G14_E=()
G14_S=()
G14_N=()
G15_E=()
G15_S=()
G15_N=()
G16_E=()
G16_S=()
G16_N=()
G17_E=()
G17_S=()
G17_N=()
G18_E=()
G18_S=()
G18_N=()
G19_E=()
G19_S=()
G19_N=()
G20_E=()
G20_S=()
G20_N=()

BKN_G1=()
BKN_G2=()
BKN_B=()
BKN_N=()
BKN2_G1=()
BKN2_G2=()
BKN2_B=()
BKN2_N=()

WEIGHT_T=()
declare -a WEIGHT_T=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
WEIGHT=()
declare -a WEIGHT=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
DELTA_E=()
declare -a DELTA_E=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
if [ "$CCD" -eq 1 ];then CCD_TEMP=0; else CCD_TEMP="$CCD"; fi
CNTS=0
while read line; do
WEIGHT_T[$CNTS]=$line
CNTS=$(( CNTS+1 ))
done <${SCRIPT_DIR}/template_models_faint/weightmap/temp_weightmap_ccd${CCD}_energy9000to11500.dat
CNTS=0
SUMWEIGHT=0
while read line; do
WEIGHT[$CNTS]=$line
SUMWEIGHT=$((SUMWEIGHT+WEIGHT[$CNTS]))
CNTS=$(( CNTS+1 ))
done <temp_weightmap_ccd${CCD}_energy${WEMIN}to${WEMAX}.dat
if [ "${SUMWEIGHT}" -eq 0 ]; then echo "    Skipping..."; continue; fi

if [ "${FS_EBOUNDFLAG}" -eq 0 ]; then
CNTS=0
while read line; do
DELTA_E[$CNTS]=`perl -e "print ${line} /1000"`
CNTS=$(( CNTS+1 ))
done <temp_calcdeltaE_ccd${CCD}.dat
fi

punlearn dmextract
dmextract infile="${EV2FITS}[ccd_id=${CCD}][energy=$WEMIN:$WEMAX][bin pi=1:1024:1]" mode=h verbose=0 outfile=temp_spec_whole_ccd${CCD}_energy${WEMIN}to${WEMAX}.pi clobber=$CLOB >/dev/null
if [ $? -gt 0 ]; then exit 1;fi
TOTCTS=`dmkeypar temp_spec_whole_ccd${CCD}_energy${WEMIN}to${WEMAX}.pi TOTCTS echo+`
EXPOSURE=`dmkeypar temp_spec_whole_ccd${CCD}_energy${WEMIN}to${WEMAX}.pi EXPOSURE echo+`
RATE=`perl -e "print ${TOTCTS}/${EXPOSURE}"`
ALPHA=0.0
AVERATE=1.0
CCD1FAC=0.70
#if [ "$CCD" -eq 0 -o "$CCD" -eq 1 ];then AVERATE=0.27; ALPHA=0.10; fi
#if [ "$CCD" -eq 2 ];then AVERATE=0.30; ALPHA=0.10; fi
#if [ "$CCD" -eq 3 ];then AVERATE=0.27; ALPHA=0.10; fi
if [ "$CCD" -eq 5 ];then AVERATE=1.55; ALPHA=0.35; fi
#if [ "$CCD" -eq 6 ];then AVERATE=0.10; ALPHA=0.00; fi
if [ "$CCD" -eq 7 ];then AVERATE=0.83; ALPHA=0.25; fi
if [ "$CCD" -eq 5 -o "$CCD" -eq 7 ] && [ $TOTCTS -lt 50 -o $SHAPEMOD -eq 0 ];then
	RATE=$AVERATE
	echo "    Will not apply spectral-shape modification."
fi

## weighed sum of components in template models
for MOD_NO in `seq 32`; do
MOD_NO2=`printf "%02d" $MOD_NO`
LINE_NO=1
while read line; do
VAL=`echo "${line}" grep -oE "([0-9\-]+\.([0-9e\-]|[0-9e\+])+|[0-9e\+]+)\s+([0-9\-]+\.[0-9\-]+|-1|1)\s" | grep -oE "^([0-9\-]+\.([0-9e\-]|[0-9e\+])+|[0-9e\+]+)\s"|grep -oE "([0-9\-]+\.([0-9e\-]|[0-9e\+])+|[0-9e\+]+)"`
VAL=`echo $VAL |grep -oE "^([0-9\-]+\.([0-9e\-]|[0-9e\+])+|[0-9e\+]+)"`
if [ "${LINE_NO}" -eq 9 -o "${LINE_NO}" -eq 12 -o "${LINE_NO}" -eq 15 -o "${LINE_NO}" -eq 18 -o "${LINE_NO}" -eq 21 -o "${LINE_NO}" -eq 24 -o "${LINE_NO}" -eq 27 -o "${LINE_NO}" -eq 30 -o "${LINE_NO}" -eq 33 -o "${LINE_NO}" -eq 36 -o "${LINE_NO}" -eq 39 -o "${LINE_NO}" -eq 42 -o "${LINE_NO}" -eq 45 -o "${LINE_NO}" -eq 48 -o "${LINE_NO}" -eq 51 ]; then LINE_E[$(( (LINE_NO-9)/3 ))]=$VAL; fi
if [ "${LINE_NO}" -eq 10 -o "${LINE_NO}" -eq 13 -o "${LINE_NO}" -eq 16 -o "${LINE_NO}" -eq 19 -o "${LINE_NO}" -eq 22 -o "${LINE_NO}" -eq 25 -o "${LINE_NO}" -eq 28 -o "${LINE_NO}" -eq 31 -o "${LINE_NO}" -eq 34 -o "${LINE_NO}" -eq 37 -o "${LINE_NO}" -eq 40 -o "${LINE_NO}" -eq 43 -o "${LINE_NO}" -eq 46 -o "${LINE_NO}" -eq 49 -o "${LINE_NO}" -eq 52 ]; then LINE_SIGMA[$(( (LINE_NO-10)/3 ))]=$VAL; fi
if [ "${LINE_NO}" -eq 11 -o "${LINE_NO}" -eq 14 -o "${LINE_NO}" -eq 17 -o "${LINE_NO}" -eq 20 -o "${LINE_NO}" -eq 23 -o "${LINE_NO}" -eq 26 -o "${LINE_NO}" -eq 29 -o "${LINE_NO}" -eq 32 -o "${LINE_NO}" -eq 35 -o "${LINE_NO}" -eq 38 -o "${LINE_NO}" -eq 41 -o "${LINE_NO}" -eq 44 -o "${LINE_NO}" -eq 47 -o "${LINE_NO}" -eq 50 -o "${LINE_NO}" -eq 53 ]; then LINE_TOT[$(( (LINE_NO-11)/3 ))]=`perl -e "print ${LINE_TOT[$(( (LINE_NO-11)/3 ))]}+${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"`; fi
if [ "${LINE_NO}" -eq 55 -o "${LINE_NO}" -eq 59 -o "${LINE_NO}" -eq 63 -o "${LINE_NO}" -eq 67 ]; then FS_ELOW+=( ${VAL} ); fi
if [ "${LINE_NO}" -eq 56 -o "${LINE_NO}" -eq 60 -o "${LINE_NO}" -eq 64 -o "${LINE_NO}" -eq 68 ]; then FS_EHIGH+=( ${VAL} ); fi
if [ "${LINE_NO}" -eq 57 -o "${LINE_NO}" -eq 61 -o "${LINE_NO}" -eq 65 -o "${LINE_NO}" -eq 69 ]; then
if [ $((`perl -e "print ${VAL} > 1"`+0)) -eq 0 ]; then FSLINE+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); else FSLINE+=( "0" ); fi; fi

if [ "$CCD" -le 3 -o "$CCD" -eq 6 ]; then
if [ "${LINE_NO}" -eq 70 ]; then G1_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 71 ]; then G1_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 72 ]; then G1_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 73 ]; then G2_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 74 ]; then G2_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 75 ]; then G2_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 76 ]; then G3_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 77 ]; then G3_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 78 ]; then G3_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 79 ]; then G4_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 80 ]; then G4_S+=( ${VAL} ); fi
if [ "${LINE_NO}" -eq 81 ]; then G4_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 82 ]; then G5_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 83 ]; then G5_S+=( ${VAL} ); fi
if [ "${LINE_NO}" -eq 84 ]; then G5_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 85 ]; then G6_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 86 ]; then G6_S+=( ${VAL} ); fi
if [ "${LINE_NO}" -eq 87 ]; then G6_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 88 ]; then BKN_G1+=( $VAL ); fi
if [ "${LINE_NO}" -eq 89 ]; then BKN_B+=( $VAL ); fi
if [ "${LINE_NO}" -eq 90 ]; then BKN_G2+=( $VAL ); fi
if [ "${LINE_NO}" -eq 91 ]; then BKN_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 92 ]; then break; fi
fi

if [ "$CCD" -eq 5 ]; then
if [ "${LINE_NO}" -eq 70 ]; then PL_BI_G+=( $VAL ); fi
if [ "${LINE_NO}" -eq 71 ]; then PL_BI_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 72 ]; then GABS1_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 73 ]; then GABS1_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 74 ]; then GABS1_N+=( $VAL ); fi
if [ "${LINE_NO}" -eq 75 ]; then PL_BI2_G+=( $VAL ); fi
if [ "${LINE_NO}" -eq 76 ]; then PL_BI2_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 77 ]; then G5_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 78 ]; then G5_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 79 ]; then G5_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 80 ]; then G6_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 81 ]; then G6_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 82 ]; then G6_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 83 ]; then G7_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 84 ]; then G7_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 85 ]; then G7_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 86 ]; then G8_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 87 ]; then G8_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 88 ]; then G8_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 89 ]; then G9_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 90 ]; then G9_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 91 ]; then G9_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 92 ]; then G10_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 93 ]; then G10_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 94 ]; then G10_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 95 ]; then G11_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 96 ]; then G11_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 97 ]; then G11_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 98 ]; then G12_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 99 ]; then G12_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 100 ]; then G12_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 101 ]; then G13_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 102 ]; then G13_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 103 ]; then G13_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 104 ]; then G14_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 105 ]; then G14_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 106 ]; then G14_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 107 ]; then G15_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 108 ]; then G15_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 109 ]; then G15_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 110 ]; then G16_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 111 ]; then G16_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 112 ]; then G16_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 113 ]; then G17_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 114 ]; then G17_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 115 ]; then G17_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 116 ]; then G18_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 117 ]; then G18_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 118 ]; then G18_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 119 ]; then G19_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 120 ]; then G19_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 121 ]; then G19_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 122 ]; then G20_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 123 ]; then G20_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 124 ]; then G20_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 125 ]; then break; fi
fi

if [ "$CCD" -eq 7 ]; then
if [ "${LINE_NO}" -eq 70 ]; then G1_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 71 ]; then G1_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 72 ]; then G1_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 73 ]; then G2_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 74 ]; then G2_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 75 ]; then G2_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 76 ]; then G3_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 77 ]; then G3_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 78 ]; then G3_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 79 ]; then G4_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 80 ]; then G4_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 81 ]; then G4_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 82 ]; then G5_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 83 ]; then G5_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 84 ]; then G5_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 85 ]; then G6_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 86 ]; then G6_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 87 ]; then G6_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 88 ]; then BKN_G1+=( $VAL ); fi
if [ "${LINE_NO}" -eq 89 ]; then BKN_B+=( $VAL ); fi
if [ "${LINE_NO}" -eq 90 ]; then BKN_G2+=( $VAL ); fi
if [ "${LINE_NO}" -eq 91 ]; then BKN_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 92 ]; then BKN2_G1+=( $VAL ); fi
if [ "${LINE_NO}" -eq 93 ]; then BKN2_B+=( $VAL ); fi
if [ "${LINE_NO}" -eq 94 ]; then BKN2_G2+=( $VAL ); fi
if [ "${LINE_NO}" -eq 95 ]; then BKN2_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 96 ]; then G7_E+=( $VAL ); fi
if [ "${LINE_NO}" -eq 97 ]; then G7_S+=( $VAL ); fi
if [ "${LINE_NO}" -eq 98 ]; then G7_N+=( `perl -e "print ${VAL}*${WEIGHT[$(( MOD_NO-1 ))]}/${WEIGHT_T[$(( MOD_NO-1 ))]}"` ); fi
if [ "${LINE_NO}" -eq 99 ]; then break; fi
fi
LINE_NO=$(( LINE_NO+1 ))
done <${TEMPMOD_DIR_STEM}/template-ccd${CCD_TEMP}/ccd${CCD_TEMP}-merged-gaincor-32reg-gain-each-y${MOD_NO2}.mo
done

PI=3.14159265358979
for i in `seq 15`; do
ECEN=${LINE_E[$(( i-1 ))]}
SIG=${LINE_SIGMA[$(( i-1 ))]}
NORM=${LINE_TOT[$(( i-1 ))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
done
for i in `seq 32`; do
CHMIN=$(( (i-1)*32 ))
CHMAX=$(( (i)*32 ))
SIG=${LINE_SIGMA[0]}
if [ $((`perl -e "print ${SIG}<=0"`+0)) -eq 1 ]; then SIG=0.0001; fi
if [ "${FS_EBOUNDFLAG}" -eq 0 ]; then EMIN=`perl -e "print ${DELTA_E[0]}*${CHMIN} + ${DELTA_E[1]} + 1.48656"`; EMAX=`perl -e "print ${DELTA_E[0]}*${CHMAX} + ${DELTA_E[1]} + 1.48656"`; fi
if [ "${FS_EBOUNDFLAG}" -eq 1 ]; then EMIN=${FS_ELOW[$(( 4*(i-1)+0 ))]}; EMAX=${FS_EHIGH[$(( 4*(i-1)+0 ))]}; fi
ESUM=`perl -e "print $EMIN + $EMAX"`
if [ $((`perl -e "print $EMIN > $EMAX"`+0)) -eq 1 ]; then EMIN=$EMAX; EMAX=`perl -e "print $ESUM - $EMIN"`; fi
ESUB=`perl -e "print $EMAX - $EMIN"`
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="${FSLINE[$(( 4*(i-1)+0 ))]}*(int(${EMIN}<=egridL))*(int(egridL<${EMAX}))+"; else MAINFUNC+="${FSLINE[$(( 4*(i-1)+0 ))]}*(fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMAX},2.)) + 1000.*exp(-pow(egridL-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.)))+fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMAX},2.)) + 1000.*exp(-pow(egridH-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.))))/2.+"; fi

SIG=${LINE_SIGMA[5]}
if [ $((`perl -e "print ${SIG}<=0"`+0)) -eq 1 ]; then SIG=0.0001; fi
if [ "${FS_EBOUNDFLAG}" -eq 0 ]; then EMIN=`perl -e "print ${DELTA_E[4]}*${CHMIN} + ${DELTA_E[5]} + 2.20500"`; EMAX=`perl -e "print ${DELTA_E[4]}*${CHMAX} + ${DELTA_E[5]} + 2.20500"`; fi
if [ "${FS_EBOUNDFLAG}" -eq 1 ]; then EMIN=${FS_ELOW[$(( 4*(i-1)+1 ))]}; EMAX=${FS_EHIGH[$(( 4*(i-1)+1 ))]}; fi
ESUM=`perl -e "print $EMIN + $EMAX"`
if [ $((`perl -e "print $EMIN > $EMAX"`+0)) -eq 1 ]; then EMIN=$EMAX; EMAX=`perl -e "print $ESUM - $EMIN"`; fi
ESUB=`perl -e "print $EMAX - $EMIN"`
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="${FSLINE[$(( 4*(i-1)+1 ))]}*(int(${EMIN}<=egridL))*(int(egridL<${EMAX}))+"; else MAINFUNC+="${FSLINE[$(( 4*(i-1)+1 ))]}*(fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMAX},2.)) + 1000.*exp(-pow(egridL-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.)))+fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMAX},2.)) + 1000.*exp(-pow(egridH-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.))))/2.+"; fi

SIG=${LINE_SIGMA[7]}
if [ $((`perl -e "print ${SIG}<=0"`+0)) -eq 1 ]; then SIG=0.0001; fi
if [ "${FS_EBOUNDFLAG}" -eq 0 ]; then EMIN=`perl -e "print ${DELTA_E[8]}*${CHMIN} + ${DELTA_E[9]} + 7.46090"`; EMAX=`perl -e "print ${DELTA_E[8]}*${CHMAX} + ${DELTA_E[9]} + 7.46090"`; fi
if [ "${FS_EBOUNDFLAG}" -eq 1 ]; then EMIN=${FS_ELOW[$(( 4*(i-1)+2 ))]}; EMAX=${FS_EHIGH[$(( 4*(i-1)+2 ))]}; fi
ESUM=`perl -e "print $EMIN + $EMAX"`
if [ $((`perl -e "print $EMIN > $EMAX"`+0)) -eq 1 ]; then EMIN=$EMAX; EMAX=`perl -e "print $ESUM - $EMIN"`; fi
ESUB=`perl -e "print $EMAX - $EMIN"`
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="${FSLINE[$(( 4*(i-1)+2 ))]}*(int(${EMIN}<=egridL))*(int(egridL<${EMAX}))+"; else MAINFUNC+="${FSLINE[$(( 4*(i-1)+2 ))]}*(fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMAX},2.)) + 1000.*exp(-pow(egridL-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.)))+fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMAX},2.)) + 1000.*exp(-pow(egridH-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.))))/2.+"; fi

SIG=${LINE_SIGMA[12]}
if [ $((`perl -e "print ${SIG}<=0"`+0)) -eq 1 ]; then SIG=0.0001; fi
if [ "${FS_EBOUNDFLAG}" -eq 0 ]; then EMIN=`perl -e "print ${DELTA_E[12]}*${CHMIN} + ${DELTA_E[13]} + 9.62800"`; EMAX=`perl -e "print ${DELTA_E[12]}*${CHMAX} + ${DELTA_E[13]} + 9.62800"`; fi
if [ "${FS_EBOUNDFLAG}" -eq 1 ]; then EMIN=${FS_ELOW[$(( 4*(i-1)+3 ))]}; EMAX=${FS_EHIGH[$(( 4*(i-1)+3 ))]}; fi
ESUM=`perl -e "print $EMIN + $EMAX"`
if [ $((`perl -e "print $EMIN > $EMAX"`+0)) -eq 1 ]; then EMIN=$EMAX; EMAX=`perl -e "print $ESUM - $EMIN"`; fi
ESUB=`perl -e "print $EMAX - $EMIN"`
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="${FSLINE[$(( 4*(i-1)+3 ))]}*(int(${EMIN}<=egridL))*(int(egridL<${EMAX}))+"; else MAINFUNC+="${FSLINE[$(( 4*(i-1)+3 ))]}*(fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridL-${EMAX},2.)) + 1000.*exp(-pow(egridL-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.)))+fmin (1.0, exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMIN},2.)) + exp(-1./(2.*pow(${SIG},2.))*pow(egridH-${EMAX},2.)) + 1000.*exp(-pow(egridH-$ESUM/2.,2.)*log(1000.)/pow($ESUB/2.,2.))))/2.+"; fi

if [ "$CCD" -le 3 -o "$CCD" -eq 6 ]; then
ECEN=${G1_E[$((i-1))]}
SIG=${G1_S[$((i-1))]}
NORM=${G1_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
if [ "$CCD" -eq 1 ]; then MAINFUNC+="*${CCD1FAC}"; fi
MAINFUNC+="+"
ECEN=${G2_E[$((i-1))]}
SIG=${G2_S[$((i-1))]}
NORM=${G2_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G3_E[$((i-1))]}
SIG=${G3_S[$((i-1))]}
NORM=${G3_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G4_E[$((i-1))]}
SIG=${G4_S[$((i-1))]}
NORM=${G4_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
if [ "$CCD" -eq 1 ]; then MAINFUNC+="*${CCD1FAC}"; fi
MAINFUNC+="+"
ECEN=${G5_E[$((i-1))]}
SIG=${G5_S[$((i-1))]}
NORM=${G5_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
if [ "$CCD" -eq 1 ]; then MAINFUNC+="*${CCD1FAC}"; fi
MAINFUNC+="+"
ECEN=${G6_E[$((i-1))]}
SIG=${G6_S[$((i-1))]}
NORM=${G6_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
BKN1=${BKN_G1[$((i-1))]}
BKN2=${BKN_G2[$((i-1))]}
BKNB=${BKN_B[$((i-1))]}
BKNN=${BKN_N[$((i-1))]}
BKNB2=$BKNB
MAINFUNC+="(${BKNN}*((int(egridL<=${BKNB}))*pow(egridL,(-1)*${BKN1})+(int(egridL>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridL,(-1)*${BKN2}))+"
MAINFUNC+="${BKNN}*((int(egridH<=${BKNB}))*pow(egridH,(-1)*${BKN1})+(int(egridH>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridH,(-1)*${BKN2})))/2."
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
fi

if [ "$CCD" -eq 5 ]; then
ECEN=${G5_E[$((i-1))]}
SIG=${G5_S[$((i-1))]}
NORM=${G5_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G6_E[$((i-1))]}
SIG=${G6_S[$((i-1))]}
NORM=${G6_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G7_E[$((i-1))]}
SIG=${G7_S[$((i-1))]}
NORM=${G7_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G8_E[$((i-1))]}
SIG=${G8_S[$((i-1))]}
NORM=${G8_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G9_E[$((i-1))]}
SIG=${G9_S[$((i-1))]}
NORM=${G9_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G10_E[$((i-1))]}
SIG=${G10_S[$((i-1))]}
NORM=${G10_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G11_E[$((i-1))]}
SIG=${G11_S[$((i-1))]}
NORM=${G11_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G12_E[$((i-1))]}
SIG=${G12_S[$((i-1))]}
NORM=${G12_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G13_E[$((i-1))]}
SIG=${G13_S[$((i-1))]}
NORM=${G13_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G14_E[$((i-1))]}
SIG=${G14_S[$((i-1))]}
NORM=${G14_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G15_E[$((i-1))]}
SIG=${G15_S[$((i-1))]}
NORM=${G15_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G16_E[$((i-1))]}
SIG=${G16_S[$((i-1))]}
NORM=${G16_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G17_E[$((i-1))]}
SIG=${G17_S[$((i-1))]}
NORM=${G17_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G18_E[$((i-1))]}
SIG=${G18_S[$((i-1))]}
NORM=${G18_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G19_E[$((i-1))]}
SIG=${G19_S[$((i-1))]}
NORM=${G19_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G20_E[$((i-1))]}
SIG=${G20_S[$((i-1))]}
NORM=${G20_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
P_G=${PL_BI_G[$((i-1))]}
P_N=${PL_BI_N[$((i-1))]}
MAINFUNC+="(${P_N}*pow(egridL,-1*${P_G})+${P_N}*pow(egridH,-1*${P_G}))/2."
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
GA1_E=${GABS1_E[$((i-1))]}
GA1_S=${GABS1_S[$((i-1))]}
GA1_N=${GABS1_N[$((i-1))]}
P_G=${PL_BI2_G[$((i-1))]}
P_N=${PL_BI2_N[$((i-1))]}
MAINFUNC+="(exp((-${GA1_N}/(sqrt(2.*${PI})*${GA1_S}))*exp(-0.5*pow((egridL-${GA1_E})/${GA1_S},2.)))*${P_N}*pow(egridL,-1*${P_G})+"
MAINFUNC+="exp((-${GA1_N}/(sqrt(2.*${PI})*${GA1_S}))*exp(-0.5*pow((egridH-${GA1_E})/${GA1_S},2.)))*${P_N}*pow(egridH,-1*${P_G}))/2."
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
fi

if [ "$CCD" -eq 7 ]; then
ECEN=${G1_E[$((i-1))]}
SIG=${G1_S[$((i-1))]}
NORM=${G1_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G2_E[$((i-1))]}
SIG=${G2_S[$((i-1))]}
NORM=${G2_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G3_E[$((i-1))]}
SIG=${G3_S[$((i-1))]}
NORM=${G3_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2."; fi
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})+"
ECEN=${G4_E[$((i-1))]}
SIG=${G4_S[$((i-1))]}
NORM=${G4_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G5_E[$((i-1))]}
SIG=${G5_S[$((i-1))]}
NORM=${G5_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G6_E[$((i-1))]}
SIG=${G6_S[$((i-1))]}
NORM=${G6_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
ECEN=${G7_E[$((i-1))]}
SIG=${G7_S[$((i-1))]}
NORM=${G7_N[$((i-1))]}
if [ $((`perl -e "print ${SIG}<${RMFDELTAE}*0.1"`+0)) -eq 1 ]; then MAINFUNC+="1./ewidth*${NORM}*(int(egridL<=${ECEN}))*(int(${ECEN}<egridH))+"; else MAINFUNC+="${NORM}/(${SIG}*sqrt(2.*${PI}))*(exp(-pow(egridL-${ECEN},2.)/(2.*pow(${SIG},2.)))+exp(-pow(egridH-${ECEN},2.)/(2.*pow(${SIG},2.))))/2.+"; fi
BKN1=${BKN_G1[$((i-1))]}
BKN2=${BKN_G2[$((i-1))]}
BKNB=${BKN_B[$((i-1))]}
BKNN=${BKN_N[$((i-1))]}
BKNB2=$BKNB
MAINFUNC+="(${BKNN}*((int(egridL<=${BKNB}))*pow(egridL,-1*${BKN1})+(int(egridL>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridL,-1*${BKN2}))+"
MAINFUNC+="${BKNN}*((int(egridH<=${BKNB}))*pow(egridH,-1*${BKN1})+(int(egridH>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridH,-1*${BKN2})))/2.+"
BKN1=${BKN2_G1[$((i-1))]}
BKN2=${BKN2_G2[$((i-1))]}
BKNB=${BKN2_B[$((i-1))]}
BKNN=${BKN2_N[$((i-1))]}
BKNB2=$BKNB
MAINFUNC+="(${BKNN}*((int(egridL<=${BKNB}))*pow(egridL,-1*${BKN1})+(int(egridL>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridL,-1*${BKN2}))+"
MAINFUNC+="${BKNN}*((int(egridH<=${BKNB}))*pow(egridH,-1*${BKN1})+(int(egridH>${BKNB}))*pow(${BKNB2},${BKN2}+(-1)*${BKN1})*pow(egridH,-1*${BKN2})))/2."
MAINFUNC+="*pow(${RATE}/${AVERATE},${ALPHA})"
fi

MAINFUNC+="+ "
done
done
MAINFUNC+="0;"


if [ "$CLOB" = "yes" ] || [ "$CLOB" = "no" -a ! -e "$LMODCPP" ]; then
	echo "// created at `date`" >$LMODCPP
	while read line; do
		echo "$line" >>$LMODCPP
	done <${SCRIPT_DIR}/acispback_model_template_calc.cpp
	echo "$MAINFUNC">>$LMODCPP
	echo "ofs<< ewidth*flux_temp << std::endl;">>$LMODCPP
	echo "}">>$LMODCPP
	echo "}">>$LMODCPP
	echo "ofs.close();">>$LMODCPP
	echo "}">>$LMODCPP
	${ACISPBACK_GXX} -std=c++11 $LMODCPP -o ${LMODCALC} >$COMPLOG
	./${LMODCALC}
else echo "clobber error while making $LMODCPP."; exit 1; fi

echo -e "Generated."
