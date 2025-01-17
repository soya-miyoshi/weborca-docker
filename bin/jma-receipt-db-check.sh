#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

VERSIONFL=${DOCDIR}/version
DBVERSIONSQL="SELECT version FROM tbl_dbkanri WHERE kanricd='ORCADB00';"

if [ "${LANG}" = "ja_JP.UTF-8" ] || [ "${LANG}" = "ja_JP.utf8" ]; then
    JMSG=1
else
    JMSG=0
fi
if [ `id -u` -ne 0 ] ; then
    if [ ${JMSG} -eq 1 ] ; then
        echo "ERROR: root権限で実行してください。"
    else
        echo "ERROR: mest be root permission."
    fi
    exit 1
fi

EXITMODE=file
if [ -z $1 ] ; then
    EXITMODE=code
fi

VERLIST=`awk '/version/{gsub(/\t| |;/,""); print} ' $VERSIONFL`
VERDATA=`echo $VERLIST | awk '{i=split($0,arr,"("); print arr[i]} ' `
VERDATA1=`echo $VERDATA | awk '{gsub(/[-)]/,""); print } ' `

echo -ne "DBVERSION:\t"
create_pgpass
if [ "$DBHOST" = "localhost" ]; then
  DBCONNOPTION=
fi
DBVERSION=`psql ${DBCONNOPTION} -At -c "${DBVERSIONSQL}" $DBNAME`
RC=$?
if [ $RC -ne 0 ] || [ -z "$DBVERSION" ] ; then
  echo "ERROR: Failed to read DBVERSION at $(basename "$0")"
  exit 99
fi
DBVERSION1=`echo $DBVERSION | awk '{gsub(/[-)]/,""); print } ' `

if [ `echo $DBVERSION1 $VERDATA1 | awk '{print($1==$2) ? "true" : "false"} '` = "true" ];	then
  echo "OK ($DBVERSION1)"
  if [ -e "$SYSCONFDIR"/database-schema-different ] ; then
    rm -f "$SYSCONFDIR"/database-schema-different
  fi
else
  echo "package  version=" $VERDATA1
  echo "database version=" $DBVERSION1
  echo
  if [ ${JMSG} -eq 1 ] ; then
      echo "パッケージとデータベースのバージョンが不整合を起こしています。"
  else
      echo "No Good!"
  fi
  if [ "${EXITMODE}" = "file" ] ; then
      if ! [ -e "$SYSCONFDIR"/database-schema-different ] ; then
	  touch "$SYSCONFDIR"/database-schema-different
      fi
  else
      exit 99
  fi
fi

exit 0
