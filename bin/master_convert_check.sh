#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

umask 022

COND_FILE=/var/lib/jma-receipt/master/master_convert_check

noconv() {
  echo "$(date +'%Y-%m-%d %T')" > ${COND_FILE}
  delete_pgpass
  exit 0
}

create_pgpass

for mtable in tbl_mstkanri_org tbl_adrs_org tbl_chk_org tbl_hknjainf_org tbl_srycdchg_org tbl_tensu_org; do
  SQL="select relname from pg_class where relname='${mtable}';"
  TABLE=`psql ${DBCONNOPTION} ${DBNAME} -Atc "${SQL}"`
  if [ "${TABLE}" = "${mtable}" ]; then
    noconv
  fi
done

delete_pgpass
rm -f ${COND_FILE}

exit 0
