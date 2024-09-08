#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

if [ $1 -ne 1 ]; then
    echo
    echo "オプションが正しくありません"
    echo
    exit 1
fi

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
cd $exec_prefix
$DBSTUB -dir "$LDDEFDIR"/directory -bd ORCBONSHIPUSH  -parameter $1

