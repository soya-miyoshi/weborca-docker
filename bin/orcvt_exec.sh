#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

if [ $# -ne 2 ]; then
    echo
    echo "オプションが正しくありません"
    echo
    exit 1
fi

if [ ! -e "$2" ]; then
    echo
    echo "$2 ファイルが存在しません"
    echo
    exit 1
fi

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
cd $exec_prefix
$DBSTUB -dir "$LDDEFDIR"/directory -bd orcabt $1 -parameter $2
