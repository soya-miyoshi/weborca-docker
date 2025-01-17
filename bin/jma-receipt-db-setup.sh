#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

ECHO_STDERR() {
    echo "$@" >&2
}

err () {
  MSG="\e[1;31mERROR:\e[m $1"
  NUM=$2
  ECHO_STDERR -e $MSG
  exit ${NUM}
}

run() {
    /bin/bash "$@" 2> >(while read line; do
	if [[ "$line" =~ "ERROR:" ]]; then
	    echo -e "${line/ERROR:/\\e[1;31mERROR:\\e[m}"
	    echo "($@)"
	    if [ ${JMSG} -eq 1 ] ; then
		err "データベース構造変更処理は異常終了しました。" 99
	    else
    		err "Database structure change process was aborted." 99
	    fi
	fi
    done)
    result=$?
    if [ $result -ne 0 ]; then
	exit $result
    fi
    return 0
}

CHANGE=$1
NOINST=$2

if [ "${LANG}" = "ja_JP.UTF-8" ] || [ "${LANG}" = "ja_JP.utf8" ]; then
    JMSG=1
else
    JMSG=0
fi

FLAG=`id -u`

if [ ${FLAG} -ne 0 ] ; then
    if [ ${JMSG} -eq 1 ] ; then
	err "root権限で実行してください。"
    else
    	err "must be root permission."
    fi
    exit 1
fi

# Check for echo -n vs echo \c
if echo '\c' | grep -s c >/dev/null
then
    ECHO_N="echo -n"
    ECHO_C=""
else
    ECHO_N="echo"
    ECHO_C='\c'
fi

#
if [ "$1" != "-y" -a "$1" != "-Y" ] ; then
    echo
    echo "version 5.2.0 データベース構造変更処理を行います。"
    if [ ${JMSG} -eq 1 ] ; then
	$ECHO_N "よろしいですか？ (y/n) "$ECHO_C
    else
	$ECHO_N "Are you sure? (y/n) "$ECHO_C
    fi
    read REPLY

    if [ "$?" -eq 1 ] ; then
	if [ ${JMSG} -eq 1 ] ; then
	    echo "NOTICE: ユーザにより処理をキャンセルされました。"
	else
    	    echo "NOTICE: user canceled."
	fi
	exit 1
    fi
    if [ "$REPLY" != "y" -a "$REPLY" != "Y" ] ; then
	if [ ${JMSG} -eq 1 ] ; then
	    echo "NOTICE: ユーザにより処理をキャンセルされました。"
	else
    	    echo "NOTICE: user canceled."
	fi
	exit 0
    fi
fi
#
# メイン処理
#

run "$INITDIR"/orca-db-create.sh
if [ x"$NOINST" = x"--noinstall" ] ; then
    if [ ${JMSG} -eq 1 ] ; then
	echo "OK! データベースをリストア後再度 jma-setupを実行してください"
    else
	echo "OK! Please execute jma-setup again after restoring the database."
    fi
    exit 0
fi

echo "false" > /tmp/ORCA_CLEAN_INSTALL
run "$INITDIR"/orca-db-init.sh
run "$INITDIR"/orca-db-install.sh
run "$BINDIR"/jma-receipt-db-check.sh
if [ -e "$SYSCONFDIR"/database-non-upgrade ] ; then
    rm -f "$SYSCONFDIR"/database-non-upgrade
fi
rm -f /tmp/ORCA_CLEAN_INSTALL
#
# 処理終了
#
if [ ${JMSG} -eq 1 ] ; then
    echo "データベース構造変更処理は終了しました"
else
    echo "Done. Completed."
fi
echo
exit 0
