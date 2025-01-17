#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

if [ `whoami` != "${ORCAUSER}" ]; then
  echo "${ORCAUSER}ユーザーで実行してください。"
  exit 1
fi

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
$DBSTUB -dir $LDDIRECTORY -bd orcabt ORCBJOB -parameter "JBS0000001PRGMNT,01"

PATH=$SITESCRIPTSDIR/allways:$PATCHSCRIPTSDIR/allways:$SCRIPTSDIR/allways:$PATH
program_upgrade_online.sh "update" "01"

exit $?
