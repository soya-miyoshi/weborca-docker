#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

if [ `id -u` -eq 0 ] ; then
    # root
    su - $ORCAUSER -c "${DBSYNC} -dir ${LDDEFDIR}/directory $*"
else
    $DBSYNC -dir ${LDDEFDIR}/directory $*
fi
