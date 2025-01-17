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
#  tbl_yakujyoに登録されている画像ファイル名
#  からイメージデータを薬剤画像テーブルへ
#  格納する
#-------------------------------------------#

ERRPROOF="${LOGDIR}/medphoto_store.txt"

export MCP_TEMPDIR="/tmp/medphototemp"
export MCP_MIDDLEWARE_NAME="panda"
MEDIMAGEDIR="${MCP_TEMPDIR}/medimage"

# 画像ファイル格納ディレクトリの作成
mkdir -p ${MCP_TEMPDIR}
mkdir -p ${MEDIMAGEDIR}

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH

MICSQL="select count(*) from tbl_med_image;"
# tbl_med_imageのレコード有無チェック
create_pgpass
MIC=`psql ${DBCONNOPTION} -At -c "${MICSQL}" ${DBNAME}`
RC=$?
if [ $RC -ne 0 ] ;then
  echo "ERROR: tbl_med_image を読めませんでした。"
  exit 1
fi
if [ ${MIC} -ne "0" ]; then
  echo "薬剤情報画像登録処理 ... 設定済のため処理は中止します。"
  exit 0
fi

${DBSTUB} -dir ${LDDIRECTORY} -bd orcabt ORCBNOMIMISV \
          -parameter "**,${ERRPROOF}"
if [ $? -ne 0 ] ; then 
  delete_pgpass
  echo "薬剤情報画像登録処理 ... テーブル格納処理でエラーが発生しました。"
  exit 1
else
  echo "薬剤情報画像登録処理 ... 終了しました。"
fi
delete_pgpass
exit 0
