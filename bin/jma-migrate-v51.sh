#!/bin/bash
#
# jma-receipt ver5.1.0
# 
# バージョンアップによる移行処理
#
# 移行処理対象のテーブルのバックアップについて
#   /var/tmp/jma-migrate-v51 に保存

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
		err "マスターデータ移行処理は異常終了しました。" 99
	    else
    		err "Master Data migrate process was aborted." 99
	    fi
	fi
    done)
    result=$?
    if [ $result -ne 0 ]; then
	exit $result
    fi
    return 0
}

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

if [ $# -gt 2 ]; then
  err "オプションが不正です。"
fi

NOACCESS="false"
NOCONVERT="false"

if ! [ -z ${1} ]; then
  if [ "${1}" = "noaccesskey" ]; then
    NOACCESS="true"
  fi
  if [ "${1}" = "noconv" ]; then
    NOCONVERT="true"
  fi
fi
if ! [ -z ${2} ]; then
  if [ "${2}" = "noaccesskey" ]; then
    NOACCESS="true"
  fi
  if [ "${2}" = "noconv" ]; then
    NOCONVERT="true"
  fi
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
#if [ "$1" != "-y" -a "$1" != "-Y" ] ; then
    echo
    echo "マスタデータ移行処理を行います。"
    if [ "${NOCONVERT}" = "true" ]; then
      echo
      echo "マスタデータ移行は行わず、関係テーブルの削除のみ行います。"
    fi
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
#fi

LOG=${LOGDIR}/jma-migrate-v51.log
TDDIR=/var/tmp/jma-migrate-v51

export PATH=${PATCHSCRIPTSDIR}/tools:${SCRIPTSDIR}/tools:${PATCHSCRIPTSDIR}/allways:${SCRIPTSDIR}/allways:${PATH}
su - ${ORCAUSER} -c "echo \"処理を開始しました : $(date '+%Y-%m-%d %H:%M:%S')\" | tee -a ${LOG}"
create_pgpass
# tbl_mstkanri_orgテーブルの存在確認
# テーブルが存在しない場合は移行処理済みと判断する
TABLE=`su - ${ORCAUSER} -c "psql ${DBCONNOPTION} ${DBNAME} -Atc \"select relname from pg_class where relname='tbl_mstkanri_org';\""`
if ! [ "${TABLE}" = "tbl_mstkanri_org" ]; then
  # テーブルが存在しない場合は移行元のテーブルを削除する
  su - ${ORCAUSER} -c "psql ${DBCONNOPTION} ${DBNAME} -Atqc \"
    drop table if exists tbl_adrs_org;
    drop table if exists tbl_chk_org;
    drop table if exists tbl_hknjainf_org;
    drop table if exists tbl_srycdchg_org;
    drop table if exists tbl_tensu_org;\""
  su - ${ORCAUSER} -c "echo \"tbl_mstkanri_org テーブルはありません。\" | tee -a ${LOG}"
  su - ${ORCAUSER} -c "echo \"処理を終了します。\" | tee -a ${LOG}"
  delete_pgpass
  exit 0
fi

if [ "${NOACCESS}" = "false" ]; then
  SQLSTR="select a.hospnum from tbl_sysbase a left outer join tbl_access_key b on a.hospnum=b.hospnum left outer join tbl_syskanri c on a.hospnum=c.hospnum and c.kanricd='1001' and kbncd='*' where b.access_key_1 is null and substr(c.kanritbl,1,30) not like '%JPN50%';"
  TABLE=`su - ${ORCAUSER} -c "psql ${DBCONNOPTION} ${DBNAME} -Atc \"${SQLSTR}\""`

  if [ -z "${TABLE}" ]; then
    echo
  else
    echo "以下の医療機関識別番号はアクセスキーの設定がありません。"
    echo "${TABLE}"
    echo
    echo "処理を中止します。"
    delete_pgpass
    exit 0
  fi
fi

# 移行前の該当テーブルをバックアップ（１回のみ）
if ! [ -d ${TDDIR} ]; then
  su - ${ORCAUSER} -c "echo \"該当テーブルをバックアップします。[${TDDIR}]\" | tee -a ${LOG}"
  su - ${ORCAUSER} -c "mkdir -p ${TDDIR}"
  su - ${ORCAUSER} -c "pg_dump -Fp -t tbl_mstkanri_org ${DBNAME} > ${TDDIR}/tbl_mstkanri_org.dump"
  su - ${ORCAUSER} -c "pg_dump -Fc -t tbl_adrs_org ${DBNAME} > ${TDDIR}/tbl_adrs_org.dump"
  su - ${ORCAUSER} -c "pg_dump -Fc -t tbl_chk_org ${DBNAME} > ${TDDIR}/tbl_chk_org.dump"
  su - ${ORCAUSER} -c "pg_dump -Fc -t tbl_hknjainf_org ${DBNAME} > ${TDDIR}/tbl_hknjainf_org.dump"
  su - ${ORCAUSER} -c "pg_dump -Fc -t tbl_srycdchg_org ${DBNAME} > ${TDDIR}/tbl_srycdchg_org.dump"
  su - ${ORCAUSER} -c "pg_dump -Fc -t tbl_tensu_org ${DBNAME} > ${TDDIR}/tbl_tensu_org.dump"
fi

# montsuqi関係テーブルを作成
su - ${ORCAUSER} -c "/usr/lib/panda/bin/monsetup -dir ${LDDIRECTORY}"

if [ "${NOCONVERT}" = "false" ]; then
  # マスタ更新（データ移行対象マスタのみ）
  su - ${ORCAUSER} -c "echo \"マスタ更新処理を行います。\" | tee -a ${LOG}"
  EXSH=`type -P migrate-v51_master_upgrade_ctrl.sh`
  su - ${ORCAUSER} -c "bash ${EXSH}"
  if [ $? -ne 0 ]; then
    su - ${ORCAUSER} -c "echo -e \"\e[1;31mマスタ更新処理はエラーが発生しました。\e[m\" | tee -a ${LOG}"
    su - ${ORCAUSER} -c "echo -e \"\e[1;31mマスタ移行処理は強制終了します。\e[m\" | tee -a ${LOG}"
    exit 1
  fi
  # 対象マスタ移行処理
  su - ${ORCAUSER} -c "echo \"マスタ移行処理を行います。\" | tee -a ${LOG}"
  EXSH=`type -P migrate-v51_migrate_ctrl.sh`
  su - ${ORCAUSER} -c "bash ${EXSH}"
  if [ $? -ne 0 ]; then
    su - ${ORCAUSER} -c "echo -e \"\e[1;31mマスタ移行処理はエラーが発生しました。\e[m\" | tee -a ${LOG}"
    su - ${ORCAUSER} -c "echo -e \"\e[1;31mマスタ移行処理は強制終了します。\e[m\" | tee -a ${LOG}"
    exit 1
  fi
fi

# 移行処理完了のためテーブルは削除
# マスタ管理テーブルは一応別名でバックアップしておく
su - ${ORCAUSER} -c "pg_dump -Fp -t tbl_mstkanri_org ${DBNAME} > ${TDDIR}/tbl_mstkanri_org_after.dump"
su - ${ORCAUSER} -c "psql ${DBCONNOPTION} ${DBNAME} -Atqc \"
  drop table if exists tbl_mstkanri_org;
  drop table if exists tbl_adrs_org;
  drop table if exists tbl_chk_org;
  drop table if exists tbl_hknjainf_org;
  drop table if exists tbl_srycdchg_org;
  drop table if exists tbl_tensu_org;\""
delete_pgpass
su - ${ORCAUSER} -c "echo \"移行対象テーブルを削除しました。\" | tee -a ${LOG}"
su - ${ORCAUSER} -c "${BINDIR}/master_convert_check.sh"
su - ${ORCAUSER} -c "echo \"処理は終了しました : $(date '+%Y-%m-%d %H:%M:%S')\" | tee -a ${LOG}"

exit 0
