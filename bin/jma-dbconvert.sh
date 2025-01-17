#!/bin/bash

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

create_pgpass
if [ $DBENCODING = "UTF-8" ] || [ $DBENCODING = "UTF8" ] || [ $DBENCODING = "utf-8" ] || [ $DBENCODING = "utf8" ] ; then
    /usr/bin/ruby3.0 -W0 "$BINDIR"/convu8.rb ${DBCONNOPTION} -u ${CHECKMODE}
else
    /usr/bin/ruby3.0 -W0 "$BINDIR"/convu8.rb ${DBCONNOPTION} -e ${CHECKMODE}
fi
delete_pgpass
