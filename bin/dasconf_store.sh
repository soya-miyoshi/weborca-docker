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

#-------------------------------------------#
#  定点調査の申請情報をファイルから
#  テーブルへ格納する
#-------------------------------------------#

DASCONFDIR=${SYSCONFDIR}/das-upload.d

if ! [ -d ${DASCONFDIR} ]; then
  echo "定点調査申請情報設定処理 ... ${DASCONFDIR} が存在しません。"
  exit 0
fi

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH

create_pgpass
for fn in `ls ${DASCONFDIR}/das-upload*.conf`; do
  f=`basename ${fn}`
  hospnum=${f:10:2}
  # 該当医療機関のtbl_das_confのレコード有無チェック
  DASCSQL="select count(*) from tbl_das_conf where hospnum=${hospnum};"
  DASC=`psql ${DBCONNOPTION} -At -c "${DASCSQL}" ${DBNAME}`
  RC=$?
  if [ $RC -ne 0 ] ;then
    echo "ERROR: tbl_das_conf (${hospnum}) を読めませんでした。"
    delete_pgpass
    exit 1
  fi
  if [ ${DASC} -ne "0" ]; then
    echo "定点調査申請情報設定処理 ... 医療機関識別番号[${hospnum}]は設定済のためスキップします。"
  else
    # das-uploadxx.conf -> tbl_das_conf
    ${DBSTUB} -dir ${LDDIRECTORY} -bd orcabt ORCBDASCONF \
              -parameter "T,${hospnum},,,${DASCONFDIR}/${f},,"
    if [ $? -eq 0 ]; then
      echo "定点調査申請情報設定処理 ... 医療機関識別番号[${hospnum}]を取り込みました。"
    fi
  fi
done
delete_pgpass

echo "定点調査申請情報設定処理 ... 終了しました。"
exit 0
