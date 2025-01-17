#!/bin/sh

SETTING=/opt/jma/weborca/app/etc/jma-receipt.env

umask 077

err () {
  MSG=$1
  NUM=$2
  echo "Error ${NUM}: ${MSG}" >&2
  exit ${NUM}
}

[ $(whoami) = "root" ] || err "rootユーザで実行してください。$(whoami)で実行されています" 100

[ -f ${SETTING} ] || err "${SETTING} 日レセの設定ファイルが有りません" 103
. ${SETTING}

[ -d ${PGDATA_BACKUP_DIR}  ] || err "${PGDATA_BACKUP_DIR}と言うディレクトリが有りません" 101
[ -d ${PGDATA}  ] || err "${PGDATA}と言うディレクトリが有りません" 102

BACKUP_FILENAME=${PGVERSION}-${PGCLUSTER}-$( date +"%Y%m%d%H%M%S").tar.gz

invoke-rc.d postgresql-${PGVERSION} stop >/dev/null 2>&1 || err "PostgreSQLの停止に失敗しました" 201

sleep 1

pgrep -f "postgres" && err "PostgreSQLが起動しています" 202

tar czf ${PGDATA_BACKUP_DIR}/${BACKUP_FILENAME} -C ${PGPATH} ${PGCLUSTER} || err "${BACKUP_FILENAME}にバックアップ失敗" 301

invoke-rc.d postgresql-${PGVERSION} start >/dev/null 2>&1 || err "PostgreSQLの起動に失敗しました" 203

echo ${PGDATA_BACKUP_DIR}/${BACKUP_FILENAME}にバックアップ作成完了

exit 0
