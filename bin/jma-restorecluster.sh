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

[ -f ${SETTING} ] || err "${SETTING} 日レセの設定ファイルが有りません" 105
. ${SETTING}


while getopts i: opt; do
  case $opt in 
    "i" ) BACKUP_FILENAME=${OPTARG};;
    *   ) err "引数が間違っています" 10 ;;
  esac
done

[ -d ${PGDATA}  ] || err "${PGDATA}と言うディレクトリが有りません" 102
[ ! -d ${PGDATA}.bak  ] || err "${PGDATA}.bakがすでに存在しています" 104
[ -f "${BACKUP_FILENAME}" ] || err "引数が設定されていません" 103

BACKUP_PGCLUSTERNAME=$(echo ${BACKUP_FILENAME} | xargs basename | awk -F'-' '{print $2}')
BACKUP_PGVERSION=$(echo ${BACKUP_FILENAME} | xargs basename | awk -F'-' '{print $1}')

[ "x${PGCLUSTER}" = "x${BACKUP_PGCLUSTERNAME}" ] || err "バックアップファイルのクラスタの名前が一致していません" 106
[ "x${PGVERSION}" = "x${BACKUP_PGVERSION}" ] || err "バックアップファイルのクラスタのバージョンが一致していません" 106

invoke-rc.d postgresql-${PGVERSION} stop >/dev/null 2>&1 || err "PostgreSQLの停止に失敗しました" 201

sleep 1

pgrep -f "postgres" >/dev/null 2>&1 && err "PostgreSQLが起動しています" 202

mv ${PGDATA} ${PGDATA}.bak || err "${PGDATA}.bakへの移動に失敗" 302
tar xzf ${BACKUP_FILENAME} -C ${PGPATH} || err "${PGPATH}にリストア失敗" 301

invoke-rc.d postgresql-${PGVERSION} start >/dev/null 2>&1 || err "PostgreSQLの起動に失敗しました" 203

sleep 1

pgrep -f "postgres" >/dev/null 2>&1 || err "復元後のPostgreSQLの起動に失敗した可能性があります。ログなどを確認して下さい。クラスタのバックアップは${PGDATA}.bakです。" 204

echo ${PGPATH}に復元完了しました。古いクラスタは${PGDATA}.bakとして保存しています。

exit 0
