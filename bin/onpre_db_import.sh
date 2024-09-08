#!/bin/bash

# DB変換を行う本体スクリプト

if [ $# -lt 1 ]
then
  echo "$ $0 dump"
  exit
fi

DUMP=$1

cd `dirname $0`

# 共通変数の読み込み
WORKDIR=/tmp/onpre_db_import
TEMPDIR=$WORKDIR/tmp
STATUS=init
RCFILE=$WORKDIR/rc

init() {
  sudo -u orca rm -rf $WORKDIR
  sudo -u orca mkdir -p $WORKDIR
  sudo -u orca mkdir -p $TEMPDIR
}

start_func() {
  echo $STATUS | sudo -u orca tee $WORKDIR/status
  LOG=$WORKDIR/$STATUS.log
  ERRLOG=$WORKDIR/$STATUS.err.log
  echo
  echo "---- $STATUS"
}

error_check() {
  if [ $? != 0 ]
  then
    echo "---- error"
    echo "status:$STATUS" | sudo -u orca tee -a $LOG
    echo "Error" | sudo -u orca tee $RCFILE
    exit 1
  fi
}

error_check_pipe() {
  if [ ${PIPESTATUS[0]} != 0 ]
  then
    echo "---- error pipe"
    echo "status:$STATUS" | sudo -u orca tee -a $LOG
    echo "Error" | sudo -u orca tee $RCFILE
    exit 1
  fi
}

finish() {
  echo "DBImported END" | sudo -u orca tee $RCFILE
  exit 0
}

check_env() {
  STATUS=CheckEnvironment
  start_func
  if [ -f /opt/jma/weborca/conf/db.conf ]; then
    false
    error_check
  fi
  ENC=$(grep -v -e '^\s*#' /opt/jma/weborca/conf/jma-receipt.conf | grep DBENCODING)
  if [ -n "$ENC" ]; then
    false
    error_check
  fi
}

drop_db() {
  STATUS=DropDB
  start_func
  sudo -u orca dropdb --if-exists orca
}

check_encoding() {
  STATUS=CheckEncoding
  start_func
  # ダンプの破損を確認するため一度リストアする
  #echo "DBエンコーディングの取得に失敗しました。ダンプデータが不正か、破損しています。" > $LOG
  sudo -u orca pg_restore -v -n public -s -f - $DUMP &>/dev/null
  error_check

  ENCODE=$(pg_restore -n public -s -f - $DUMP | grep "SET client_encoding" | awk -F "'" '{print $2}')
  echo $ENCODE | sudo -u orca tee $LOG
}

convert_encoding() {
  STATUS=EncodeConverting
  start_func
  sudo -u orca ./onpre_db_convert.sh -t 2>&1 | sudo -u orca tee $LOG
  error_check_pipe
  sudo -u orca ./onpre_db_convert.sh 2>&1 | sudo -u orca tee $LOG
  error_check_pipe
}

restore_db() {
  STATUS=RestoreDB
  start_func

  sudo /opt/jma/weborca/app/bin/jma-setup --noinstall 2>&1 | sudo -u orca tee $LOG
  error_check_pipe

  # plpgsql拡張関連でエラーになってしまうためステータスチェックをしない
  TEMPDUMP=$TEMPDIR/temp.dump
  sudo -u orca pg_restore -x -O -f $TEMPDUMP $DUMP
  if [ "$ENCODE" = "UTF8" ]; then
    sudo -u orca sed -i -f rep.sed $TEMPDUMP
  fi
  sudo -u orca psql orca < $TEMPDUMP 2>&1 | sudo -u orca tee -a $LOG
  # sudo -u orca psql orca -c "SELECT * FROM tbl_syskanri WHERE kanricd='1001'" 2>&1 | sudo -u orca tee -a $LOG
  error_check_pipe

  sudo -u postgres psql orca -c "COMMENT ON EXTENSION plpgsql IS NULL;" 2>&1 | sudo -u orca tee -a $LOG
  error_check_pipe
}

check_grouping() {
  STATUS=CheckGrouping
  start_func
  COUNT=$(sudo -u orca pg_restore -t tbl_sysbase -a -f - $DUMP | grep -a '^[0-9]' | wc -l)
  error_check
  if [ "$COUNT" = "0" ]
  then
    echo "tbl_sysbaseのレコード数が0です。ダンプファイルが不正か破損している可能性があります。" | sudo -u orca tee -a $LOG
    echo "Error" | sudo -u orca tee $RCFILE
    exit 1
  fi
  if [ $COUNT -gt 1 ]
  then
    echo "グループ診療設定のDBには対応していません。" | sudo -u orca tee -a $LOG
    echo "Error" | sudo -u orca tee $RCFILE
    exit 1
  fi
  echo "グループ診療設定ではありません。問題ありません。" | sudo -u orca tee -a $LOG
}

db_dump() {
  STATUS=DeleteAPSTable
  start_func
  # aps関連テーブルの削除
  sudo -u orca psql -c "DROP TABLE IF EXISTS aps_migrations,ap_server_ld_processes CASCADE;"
  sudo -u orca psql -c "truncate table monbatch_log;"
  sudo -u orca psql -c "truncate table monbatch_clog;"
  sudo -u orca psql -c "truncate table tbl_para;"
  sudo -u orca psql -c "truncate table tbl_spa_tmp;"
  sudo -u orca psql -c "truncate table tbl_api_para;"
  sudo -u orca psql -c "truncate table tbl_lock;"
  sudo -u orca psql -c "truncate table monbatch;"
  sudo -u orca psql -c "truncate table tbl_jobkanri;"
  sudo -u orca psql -c "truncate table monpushevent;"
  sudo -u orca pg_dump -E EUC_JIS_2004 2>&1 1>/dev/null | sudo -u orca tee $WORKDIR/out.euc.err
  error_check_pipe
}

check_exec() {
  echo
  echo "インポート処理を開始します。"
  echo "※　インポート処理によりデータベースが削除されますのでご注意ください"
  echo -n "よろしいですか？ (y/n) "
  read REPLY

  if [ "$?" -eq 1 ] ; then
    echo "キャンセルされました。"
    exit 1
  fi
  if [ "$REPLY" != "y" -a "$REPLY" != "Y" ] ; then
    echo "キャンセルされました。"
    exit 0
  fi
}

######
# main
######

check_exec
init
check_env

# グループ診療かどうかのチェック
# check_grouping

drop_db

# ダンプファイルの文字エンコーディングを調べる
check_encoding

case "$ENCODE" in
"UTF8" )
  # UTF-8であればリストアのみ行う
  restore_db
  ;;
"EUC_JP" )
  # EUC-JPの場合、リストア後DBエンコード変換を行う
  echo "DBENCODING=EUC_JP" | sudo tee /opt/jma/weborca/conf/db.conf
  restore_db
  sudo rm /opt/jma/weborca/conf/db.conf
  convert_encoding
  ;;
* )
  echo "Invalid DB Encode:$ENCODE" | sudo -u orca tee -a $LOG
  echo "Error" | sudo -u orca tee $RCFILE
  exit 1
  ;;
esac

# aps関連テーブルの削除
db_dump

finish
