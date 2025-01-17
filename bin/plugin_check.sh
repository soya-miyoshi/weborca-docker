#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

umask 022

COND_FILE=/var/lib/jma-receipt/plugin/plugin_condition_error

PLUGIN_SHELL=${ORCA_DIR}/bin/jma-plugin
JPPINFO=${SYSCONFDIR}/jppinfo.list

ERRCNT=`${PLUGIN_SHELL} -c ${JPPINFO} list4cobol | tr -d ' ' | grep -c "link:ERROR"`

if [ ${ERRCNT} -gt 0 ]; then
  echo "$(date +'%Y-%m-%d %T')" > ${COND_FILE}
else
  rm -f ${COND_FILE}
fi

exit 0
