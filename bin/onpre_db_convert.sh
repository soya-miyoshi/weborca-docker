#!/bin/bash

# DBエンコード変換を行うスクリプト

#export RUBYOPT=-EUTF-8

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

CHECKMODE=""
if [ "x$1" = "x-t" ] ; then
    CHECKMODE="-t"
fi

LOG='/tmp/convu8.log'
create_pgpass
if [ $DBENCODING = "UTF-8" ] || [ $DBENCODING = "UTF8" ] || [ $DBENCODING = "utf-8" ] || [ $DBENCODING = "utf8" ] ; then
    /usr/bin/env ruby "$BINDIR"/convu8.rb ${DBCONNOPTION} -u ${CHECKMODE} 2>&1 | tee $LOG
else
    /usr/bin/env ruby "$BINDIR"/convu8.rb ${DBCONNOPTION} -e ${CHECKMODE} 2>&1 | tee $LOG
fi
delete_pgpass

COUNT=`grep -i "error" $LOG | wc -c`
if [ $COUNT = 0 ]
then
  exit 0
else
  exit 1
fi
