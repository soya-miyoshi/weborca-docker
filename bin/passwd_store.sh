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
#  ユーザ認証をアプリケーション側で行うため
#  glauthで使用していたパスワードファイルから
#  ユーザ名とパスワードを抜き出しテーブルへ
#  格納する
#-------------------------------------------#

PASSWDFILE=${SYSCONFDIR}/passwd
COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH
PWDCSQL="select count(*) from tbl_passwd;"

# tbl_passwdのレコード有無チェック
create_pgpass
PWDC=`psql ${DBCONNOPTION} -At -c "${PWDCSQL}" ${DBNAME}`
RC=$?
if [ $RC -ne 0 ] ;then
  echo "ERROR: tbl_passwd を読めませんでした。"
  exit 1
fi
if [ ${PWDC} -ne "0" ]; then
  echo "パスワード設定処理 ... 設定済のため処理は中止します。"
  exit 0
fi

input_password() {
  PWD1=''
  PWD2=''
 
  trap "echo \"キャンセルされました。\"; stty echo; exit 1" 2
  while :
  do
    stty -echo
    echo
    echo "ormasterのパスワードを設定します(8文字以上16文字以内)"
    echo -n "パスワード: "
    read PWD1
    echo
    echo -n "パスワード確認: "
    read PWD2
    echo
    if [ ${#PWD1} -lt 8 -o ${#PWD2} -lt 8 ]; then
      echo "8文字以上で入力してください。"
      continue
    fi
    if [ ${#PWD1} -gt 16 -o ${#PWD2} -gt 16 ]; then
      echo "16文字以内で入力してください。"
      continue
    fi
    if [ ${PWD1} = ${PWD2} ]; then
      break
    else
      echo "パスワード不一致です。"
    fi
  done
  stty echo
 
  return
}

TEMP1=$(mktemp)
# passwdファイルが存在しない場合はormasterのパスワードを設定
if ! [ -e ${PASSWDFILE} ]; then
  input_password
  NPASS=`md5pass ${PWD1}`
  echo "ormaster:${NPASS}:" > ${TEMP1}
else
  cp -p ${PASSWDFILE} ${TEMP1}
fi

# passwdファイルからSQL文を作成
TEMP2=$(mktemp)
export TEMP1
export TEMP2
trap "rm -f ${TEMP1}; rm -f ${TEMP2}" EXIT

/usr/bin/ruby3.0 <<RUBY_END
  fi = open(ENV['TEMP1'])
  fo = open(ENV['TEMP2'], 'w')

  while l = fi.gets
    pwary = l.chomp.split(":")
    fo.puts "INSERT INTO tbl_passwd (userid, password) VALUES ('#{pwary[0]}', '#{pwary[1]}');"
  end

  fo.close
  fi.close
RUBY_END

${DBSTUB} -dir ${LDDIRECTORY} -bd orcabt ORCBSQL1 \
          -parameter "00,${TEMP2}"
if [ $? -ne 0 ] ; then 
  echo "パスワード設定処理 ... テーブル格納処理でエラーが発生しました。"
  exit 1
else
  echo "パスワード設定処理 ... 終了しました。"
  exit 0
fi
