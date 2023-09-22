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
GAINFIT=${21}
MONAME=${22}
BIN=${23}
NORMFIT=${24}
PLOT=${25}
LOG="calbpbackmodel.log"
LOG2="calbpbackmodel_entireErange.log"
IMG="pbackmodel_fit.ps"
PACKLOG="packagegen.log"

WEMAX=$(perl -e "print $WEMAX *1e-3"); WEMAX=$(printf "%.3f" $WEMAX)
WEMIN=$(perl -e "print $WEMIN *1e-3"); WEMIN=$(printf "%.3f" $WEMIN)

if [ "$CLOB" = "yes" ] || [ "$CLOB" = "no" -a ! -e "$LMODDAT" -a ! -e "$LMODOUTCPP" ]; then
echo "${MONAME} 0 0. 1e5 c_acispback add 0 1" >$LMODDAT
echo "// created at `date`" >$LMODOUTCPP
while read line; do
if [ $(echo "$line" |grep -c "TEMP1") -eq 1 ];then line="std::ifstream ifs(\"`pwd`/flux.dat\");"; fi
if [ $(echo "$line" |grep -c "TEMP2") -eq 1 ];then line="std::ifstream ifs2(\"`pwd`/emin.dat\");"; fi
echo $line >>$LMODOUTCPP
done <${SCRIPT_DIR}/acispback_model_template.cpp
rm *pkgFunctionMap.* lpack_*pkg.cxx Makefile pkgIndex.tcl ${LMODNAME}.o lpack_*pkg.o $LMODCPP 2>/dev/null
initpackage ${MONAME}_pkg $LMODDAT . >$PACKLOG 2>&1
hmake >>$PACKLOG 2>&1
else echo "clobber error while making $LMODDAT & $LMODOUTCPP."; exit 1; fi

if [ "$CLOB" = "yes" ] || [ "$CLOB" = "no" -a ! -e "$XCM" ]; then
echo -e "Calibrating the spectral model...\n"
if [ "$PLOT" -eq 1 ]; then echo "cpd /xs">$XCM
else echo "cpd /null">$XCM
fi
echo "setp e">>$XCM
echo "setp com cs 1.3">>$XCM
echo "statistic cstat" >>$XCM
echo "query yes" >>$XCM
echo "setp com la t OBSID: " $(dmkeypar ${EV2FITS} OBS_ID echo+) >>$XCM
echo "setp com lw 1 on 1..10000" >>$XCM
echo "setp com r x 0.25 11.8" >>$XCM
echo "setp com r y 1e-2 1e0" >>$XCM
echo "setp com log x off 1 2" >>$XCM
echo "setp com r y2 0. 2." >>$XCM
echo "setp com wind 1" >>$XCM
echo "setp com view 0.12 0.3 0.9 0.9" >>$XCM
echo "setp com wind 2" >>$XCM
echo "setp com view 0.12 0.1 0.9 0.3" >>$XCM
echo "setp com win 1" >>$XCM
echo "setp com la y Counts /s /keV" >>$XCM
echo "setp com win 2" >>$XCM
echo "setp com la y Data/Model" >>$XCM
echo "setp com la pos y 3.3" >>$XCM
if [ "${BIN}" -eq 0 ]; then
	echo "data 1:1 temp_spec.pi" >>$XCM
	echo "backgrnd none" >>$XCM
else
	echo "test -f temp_spec_grp.pi && rm temp_spec_grp.pi" >>$XCM
	echo "punlearn dmgroup" >>$XCM
	echo "dmgroup temp_spec.pi temp_spec_grp.pi grouptype=BIN xcolumn=pi grouptypeval="" binspec="621:785:165" ycolumn=counts clobber=$CLOB" >>$XCM
	echo "data 1:1 temp_spec_grp.pi" >>$XCM
	echo "backgrnd none" >>$XCM
fi
echo "resp 1 temp.rmf" >>$XCM
echo "ig **:**-$WEMIN, $WEMAX-**" >>$XCM
if [ "${GAINFIT}" -eq 1 ]; then
	echo "gain fit" >>$XCM
	echo "1 0.0001" >>$XCM
	echo "0 0.0001" >>$XCM
fi
echo "lmod ${MONAME}_pkg ./" >>$XCM
echo "mo ${MONAME}" >>$XCM
echo "1 0.001" >>$XCM
echo "pl ld ra" >>$XCM
echo "setp com r y1" >>$XCM
echo "pl ld ra" >>$XCM
echo "fit" >>$XCM
echo "log ${LOG}" >>$XCM
echo "sho data" >>$XCM
echo "sho param" >>$XCM
echo "sho fit" >>$XCM
echo "log none" >>$XCM
echo "no **:0.25-11.5" >>$XCM
echo "ig **:**-0.25, 11.5-**" >>$XCM
echo "setp rebin 5 50" >>$XCM
echo "setp com r y1" >>$XCM
echo "pl ld ra" >>$XCM
echo "setp com ti of" >>$XCM
echo "cpd ${IMG}/cps" >>$XCM
echo "pl ld ra" >>$XCM
if [ "$PLOT" -eq 1 ]; then echo "cpd /xs">>$XCM
else echo "cpd /null">>$XCM
fi
echo "pl ld ra" >>$XCM
echo "save mo ${OUTMODEL}" >>$XCM

echo "log ${LOG2}" >>$XCM
echo "sho data" >>$XCM
echo "sho param" >>$XCM
echo "sho fit" >>$XCM
echo "log none" >>$XCM

if [ "$NORMFIT" -eq 1 ];then
rm ${OUTMODEL} 2>/dev/null
xspec >/dev/null <<EOF
@$XCM
EOF
NORMALIZATION=`cat ${LOG} |grep  "#   1    1" |grep -oE "[0-9][.][0-9E.+-]+" |grep -m1 -oE "[0-9][.][0-9E.+-]+"`
else
	echo "Will not perform spectral fitting because normfit=0."
	NORMALIZATION=1
fi
else echo "clobber error while making xcm for calibration."; fi

echo "normalization factor = $NORMALIZATION"
rm acispback_lmod_temp.cpp 2>/dev/null
while read line; do
if [ `echo "$line" |grep -c "flux\[i\]=flux_temp2"` -eq 1 ];then line="flux[i]=flux_temp2 *$NORMALIZATION;"; fi
echo $line >>acispback_lmod_temp.cpp
done <$LMODOUTCPP
cp acispback_lmod_temp.cpp $LMODOUTCPP; rm acispback_lmod_temp.cpp
rm *pkgFunctionMap.* lpack_*pkg.cxx Makefile pkgIndex.tcl ${LMODNAME}.o lpack_*pkg.o $LMODCPP 2>/dev/null
initpackage ${MONAME}_pkg $LMODDAT . >>$PACKLOG 2>&1
hmake >>$PACKLOG 2>&1

if [ "$NORMFIT" -eq 1 -a "${GAINFIT}" -eq 1 ]; then
	echo "gain slope= " $(cat ${LOG} |grep -E "(gain)\s+(slope)+\s+" |grep -oE "[0-9\-]+.([0-9E\-]+|[0-9E\+]+)\s+(\+/\-)\s+[0-9\-]+.([0-9E\-]+|[0-9E\+]+)")
	echo "gain offset= " $(cat ${LOG} |grep -E "(gain)\s+(offset)+\s+" |grep -oE "[0-9\-]+.([0-9E\-]+|[0-9E\+]+)\s+(\+/\-)\s+[0-9\-]+.([0-9E\-]+|[0-9E\+]+)")
fi
if [ "$NORMFIT" -eq 1 ]; then
	CSTAT=$(cat ${LOG} |grep -E "(C-Statistic)\s+" |grep -oE "([0-9]+[\.][0-9E\+]+)")
	DOF=$(cat ${LOG} |grep -oE -m 1 "([0-9]+\s(degrees of freedom))" |grep -oE "[0-9]+")
	echo -e "C-Statistic/d.o.f.= ${CSTAT}/${DOF} \n"
	if [ $((`perl -e "print ${CSTAT}/${DOF} > 2.0"`+0)) -eq 1 ];then
		echo -e "Warning !! Spectral model may be inappropriate with C-Statistic/d.o.f. > 2.0 !! \n"
	fi
fi

echo -e "Done. \n"
