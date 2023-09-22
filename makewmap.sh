REGIONFILE=$1
WEMIN=$2
WEMAX=$3
RMFDELTAE=$4
GENWMAP=$5
GENSPEC=$6
GENRMF=$7
CLOB=$8
STOWEDFLAG=$9
FS_EBOUNDFLAG=${10}
EV2FITS=${11}
FORVF=${12}
SCRIPT_DIR=${13}
TEMPMOD_DIR_STEM=${14}
OUTMODEL=${15}

FAKEEVT=${24}

for CCD in 0 1 2 3 5 6 7; do
    if [ "$GENWMAP" -eq 1 ]; then
        echo -e "Processing CCD${CCD}.\n  Creating weight map..."
        punlearn dmextract

        if [ "$FAKEEVT" -gt 0 ]; then
            dmextract wmap="[energy=${WEMIN}:${WEMAX}][bin chipx=1:1024:32,chipy=1:1024:32]" mode=h verbose=0 infile="temp_fake_events_ccd${CCD}.fits[sky=region(${REGIONFILE})][ccd_id=${CCD}][bin pi=1:1024:1]" outfile=temp_ccd${CCD}_energy${WEMIN}to${WEMAX}.fits clobber="$CLOB" >/dev/null
        else
            dmextract wmap="[energy=${WEMIN}:${WEMAX}][bin chipx=1:1024:32,chipy=1:1024:32]" mode=h verbose=0 infile="temp_evt_regfil.evt[ccd_id=${CCD}][bin pi=1:1024:1]" outfile=temp_ccd${CCD}_energy${WEMIN}to${WEMAX}.fits clobber="$CLOB" >/dev/null
        fi
        if [ $? -gt 0 ]; then exit 1; fi
        if [ "$CLOB" = "yes" ] || [ "$CLOB" = "no" -a ! -e "temp_weightmap_ccd${CCD}_energy${WEMIN}to${WEMAX}.dat" ]; then
            ${ACISPBACK_PYTHON} ${SCRIPT_DIR}/make_weightmap.py temp_ccd${CCD}_energy${WEMIN}to${WEMAX}.fits temp_weightmap_ccd${CCD}_energy${WEMIN}to${WEMAX}.dat
        else
            echo "clobber error while making temp_weightmap_ccd${CCD}_energy${WEMIN}to${WEMAX}.dat."
            exit 1
        fi
        echo -e "  Created."
    fi
done
