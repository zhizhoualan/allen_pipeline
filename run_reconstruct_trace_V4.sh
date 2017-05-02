#!/bin/bash

export LD_PRELOAD=/usr/lib64/libstdc++.so.6
export DISPLAY=:$RANDOM

Xvfb $DISPLAY -auth /dev/null &
rtn=$?
if [ $rtn -ne 0 ]; then exit $rtn; fi

sleep 5

SOMA_PATH_FILE=$1
SOMA_CENTER_FILE=$2
STACK_FILE=$3
SWC_FILE_REFINED=$4
EXECUTABLE=$5

#echo Arguments:
#echo Soma path file: $SOMA_PATH_FILE
#echo Soma center file: $SOMA_CENTER_FILE
#echo Stack file: $STACK_FILE
#echo Executable: $EXECUTABLE

$EXECUTABLE -x mipZ -f mip_zslices -i ${STACK_FILE} -p 1:1:e -o ${STACK_FILE}_mip.raw
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x multiscaleEnhancement -f adaptive_auto_2D -i ${STACK_FILE}_mip.raw -o ${STACK_FILE}_mip.raw_enhanced.raw
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x multiscaleEnhancement -f soma_detection_2D -i ${STACK_FILE}_mip.raw -p ${SOMA_CENTER_FILE} ${STACK_FILE}_mip.raw_enhanced.raw
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x Region_Neuron2 -f trace_app2 -i ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw -p 1 10 0 0 0 20 500
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x mapping3D_swc -f mapping -i ${STACK_FILE} ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw_region_APP2.swc
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x neuron_connector  -f connect_neuron_SWC -i ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw_region_APP2.swc_3D.swc -o ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw_region_APP2.swc_3D.swc_connected.swc -p 60 20 1 1 1 0 false 1
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x resample_swc -f resample_swc -i ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw_region_APP2.swc_3D.swc_connected.swc -p 10
rtn=$?
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x IVSCC_process_swc -f process_v2 -i ${STACK_FILE}_mip.raw_enhanced.raw_soma.raw_region_APP2.swc_3D.swc_connected.swc_resampled.swc ${SOMA_PATH_FILE} ${SOMA_CENTER_FILE} ${STACK_FILE}_mip.raw -o ${SWC_FILE_REFINED}_v1.swc
rtn=$?

#######added by Zhi Zhou
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x IVSCC_process_swc -f process_remove_artifacts -i ${SWC_FILE_REFINED}_v1.swc ${STACK_FILE} -o ${SWC_FILE_REFINED}_v2.swc
rtn=$?

#######added by Zhi Zhou 05/02/2017  soma correction
if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

$EXECUTABLE -x IVSCC_process_swc -f process_soma_correction_v2 -i ${SWC_FILE_REFINED}_v2.swc ${SOMA_CENTER_FILE} -o ${SWC_FILE_REFINED}
rtn=$?

#######added by Zhi Zhou

if [ $rtn -ne 0 ]; then kill %1; exit $rtn; fi

# kill background Xvfb process that this job started.
kill %1
exit $rtn
