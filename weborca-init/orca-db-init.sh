#! /bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV


ECHO_RUN () {
  echo -e "\e[1;34m${1}\e[m"
}

ECHO_STDERR() {
  echo "$@" >&2
}

err () {
  MSG="ERROR: $1"
  NUM=$2
  echo -e $MSG
  ECHO_STDERR -e $MSG
  exit ${NUM}
}

create_pgpass
if [ "$DBHOST" = "localhost" ]; then
  DBCONNOPTION=
fi

echo -ne "DBKANRI\t\t"
DBKANRISQL="SELECT count(*) FROM pg_tables WHERE tablename = 'tbl_dbkanri';"
DBKANRICHECK=`su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -At ${DBNAME} -c \"${DBKANRISQL}\""`
RC=$?
if [ $RC -ne 0 ] ; then
    err "(${DBKANRISQL}) が処理出来ませんでした" 99
fi
if [ "$DBKANRICHECK" -gt 0 ]; then
  echo "OK (tbl_dbkanri)"
  exit 0
fi

DBKANRI=`su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -q --set \"ON_ERROR_STOP=1\" ${DBNAME} -f ${INITDIR}/orca_dbkanri_orig.dump" 2>&1`
RC=$?
if [ $RC -ne 0 ] ; then
    err "${INITDIR}/orca_dbkanri_orig.dump が処理出来ませんでした" 99
fi

echo "true" > /tmp/ORCA_CLEAN_INSTALL

ECHO_RUN "CREATE TABLE (tbl_dbkanri)"

exit 0
