#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

# TMPDIR=`mktemp -d -p /var/tmp`
# trap "rm -r $TMPDIR" EXIT
TMPDIR=/var/tmp
MSTDIR=orca-$(date +%Y%m%d)
VERSIONFL=${DOCDIR}/version

DBLISTSQL="SELECT * FROM tbl_dbkanri WHERE kanricd='ORCADB00';"
DBVERSIONSQL="SELECT version FROM tbl_dbkanri WHERE kanricd='ORCADB00';"

UPDKANRIFILE=info/ORCADBS.DAT

UPDFILE=$TMPDIR/$MSTDIR/ORCADBS.OUT
LEN=100
INSTALLLOG="$LOGDIR"/orca-db-install-5.2.0.log
THISTIMELOG="$LOGDIR"/orca-db-install-thistime.log

PATH=$BINDIR:$PATCHSCRIPTSDIR/allways:$SCRIPTSDIR/allways:$PATCHLIBDIR:$ORCALIBDIR:$PATH

ECHO_STDERR() {
    echo "$@" >&2
}

ECHO_RUN () {
  echo -e "\e[1;34m${@}\e[m"
}
ECHO_N_RUN () {
  echo -ne "\e[1;34m${@}\e[m"
}

err () {
  MSG="ERROR: $1"
  NUM=$2
  ECHO_STDERR -e $MSG
  exit ${NUM}
}

orcawget () {
    DWNFL=`echo $1 | awk '{i=split($0,arr,"/"); print arr[i]} ' `
    if [ ${DWNFL:1:10} = "XXXXXXXXXX" ] ; then
        return 0;
    fi
#受信ファイル削除
    if [ -e $DWNFL ] ; then
        rm $DWNFL;
    fi
    RST=`orcadt_verify.rb --dir . --cacert ${CACERTFILE} ${DBUPGRADEPATH}/$1.p7m 2>&1`
    RC=$?
    ECHO_STDERR "$RST : $DWNFL"
#接続確認 && ファイルサイズチェック
    if [ $RC -eq 0 ] && [ -s $DWNFL ] ; then
        return 0;
    else
        return 1;
    fi
}

orcatar () {
    TARFL=`echo $1 | awk '{i=split($0,arr,"/"); print arr[i]} ' `
    TAR=`echo $TARFL | awk '{i=split($0,arr,"."); print arr[i-1] arr[i]} ' `
    LOCALFL=`echo $TARFL | awk '{i=split($0,arr,"."); print arr[1]".dat"} ' `
#解凍処理
    if [ $TAR = "targz" ] ; then
        tar zxf $TARFL
    else
        return 0;
    fi
#tar確認
    if [ $? -eq 0 ] ; then
        ECHO_STDERR "$TARFL tar end OK"
    else
        ECHO_STDERR "$TARFL tar end NG"
        return 1;
    fi
#ファイルサイズチェック
    if [ -s $LOCALFL ] ; then
        return 0;
    else
        return 1;
    fi
}

create_pgpass
if [ "$DBHOST" = "localhost" ]; then
  DBCONNOPTION=
fi

if [ ! -e "$INSTALLLOG" ]; then
    su - $ORCAUSER -c "touch $INSTALLLOG"
fi
rm -f $THISTIMELOG
su - $ORCAUSER -c "touch $THISTIMELOG"

#整合性チェック
VERLIST=`awk '/version/{gsub(/\t| |;/,""); print} ' $VERSIONFL`
VERDATA=`echo $VERLIST | awk '{i=split($0,arr,"("); print arr[i]} ' `
VERDATA1=`echo $VERDATA | awk '{gsub(/[-)]/,""); print } ' `
VERDATA2=`echo $VERDATA | awk '{gsub(/[)]/,""); print } ' `

DBVERSION=`su - $ORCAUSER -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -At -c \"${DBVERSIONSQL}\" $DBNAME"`
if [ $? -ne 0 ] ; then
    err "データベース管理情報が読み取れません。処理を中止します" 99
fi

DBVERSION1=`echo $DBVERSION | awk '{gsub(/[-)]/,""); print } ' `
if [ -z "$DBVERSION1" ] ; then
    err "データベースバージョン(tbl_dbkanri:$DBVERSION)が読み取れません。処理を中止します" 99
fi
if [ "$DBVERSION1" -gt "$VERDATA1" ] ; then
    ECHO_STDERR "Database: ${DBVERSION1}"
    ECHO_STDERR " Version: ${VERDATA1}"
    err "ダウングレードの処理となっています。処理を中止します" 99
fi

echo -ne "UPDATE CHECK:\t"
#DB管理情報更新
echo "update tbl_dbkanri set version='$VERDATA2' where kanricd='ORCADB00';" | su - $ORCAUSER -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -q $DBNAME" >&2

#オフラインメンテナンスであるかチェック
OFFLINEPATH=`echo $DBUPGRADEPATH | sed -ne 's#file://##p'`
if [ -z $OFFLINEPATH ]; then
    OFFLINE="online"
else
    OFFLINE="offline"
fi

if ! [ -d $TMPDIR/$MSTDIR ] ; then
    mkdir $TMPDIR/$MSTDIR
    chown "$ORCAUSER":"$ORCAGROUP" $TMPDIR/$MSTDIR
fi
cd $TMPDIR/$MSTDIR
rm -f *
if  [ $OFFLINE = "offline" ]; then
    if  [ ! -e $OFFLINEPATH/$UPDKANRIFILE ]; then
        err "DBレコード管理情報がありませんでした" 99
    fi
    cp $OFFLINEPATH/$UPDKANRIFILE ./
    echo "OK (${OFFLINE})"
    ECHO_STDERR "OFFLINE: DBレコード管理情報を複写しました"
else
    #センタからのDB構造体ダウンロード
    if orcawget $UPDKANRIFILE ; then
	echo "OK (${OFFLINE})"
        ECHO_STDERR "ONLINE: センタからのDBレコード管理情報のダウンロードが終了しました"
    else
        err "センタからのDBレコード管理情報のダウンロードに失敗しました" 99
    fi
fi

echo -ne "DBLIST:\t\t"
DBLIST=`su - $ORCAUSER -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -At -c \"${DBLISTSQL}\" $DBNAME"`
if [ $? -ne 0 ] || [ -z "$DBLIST" ] ; then
    echo "DBLIST: での失敗"
    err "データベース管理情報が読み取れませ。処理を中止します" 99
fi
echo "OK (`echo $DBLIST|cut -d'|' -f2`)"

#ダウンロードファイル生成
echo -ne "LIST DOWNLOAD:\t"
RST=`ORCXSMST1 $MSTDIR$DBLIST 2>&1`
RC=$?
ECHO_STDERR "$RST"
if [ $RC -ne 0 ] ; then
    err "ダウンロードファイル生成に失敗しました" 99
fi
#更新用ダウンロードファイル受信
#ファイルサイズチェック
if [ -s $UPDFILE ] ; then
    UPDNUM=`cat $UPDFILE|wc -l`
    ECHO_RUN "FILE ($UPDNUM)"
    ECHO_STDERR "更新用ダウンロードファイルの作成が終了しました"
else
    echo "OK (nothing)"
    ECHO_STDERR "更新用ファイルはありません"
    rm -r $TMPDIR/$MSTDIR
    exit 0
fi

UPDLIST=`awk '{gsub(/\t| |;/,""); print} ' $UPDFILE`
echo -ne "DOWNLOAD:\t"
for UPD in $UPDLIST
do
    if  [ $OFFLINE = "offline" ]; then
        DWNFL=`echo ${UPD:35:$LEN} | awk '{i=split($0,arr,"/"); print arr[i]} ' `
        if [ ${DWNFL:1:10} = "XXXXXXXXXX" ] ; then
            ECHO_STDERR ${UPD:35:$LEN} "オリジナルダンプスキップしました"
        else
            if  [ -e $OFFLINEPATH/${UPD:35:$LEN} ]; then
                cp $OFFLINEPATH/${UPD:35:$LEN} ./
                ECHO_STDERR ${UPD:35:$LEN} "複写が終了しました"
            else
		echo "$OFFLINEPATH/"
                err "${UPD:35:$LEN} 複写に失敗しました" 99
            fi
        fi
    else
        if orcawget ${UPD:35:$LEN} ; then
            ECHO_STDERR ${UPD:35:$LEN} "ダウンロードが終了しました"
        else
            err "${UPD:35:$LEN} ダウンロードに失敗しました" 99
        fi
    fi
    ECHO_N_RUN "."
done
ECHO_RUN "OK"

echo -ne "EXTRACT:\t"
for UPD in $UPDLIST
do
    ECHO_STDERR $UPD
    if orcatar $UPD ; then
        ECHO_STDERR "$UPD 解凍処理が終了しました"
    else
        err "$UPD 解凍処理に失敗しました" 99
    fi
    ECHO_N_RUN "."
done
ECHO_RUN "OK"

#DB構造変更処理
DBOPTION="${DBCONNOPTION} ${DBNAME}"

echo -ne "UPDATE:\t\t"
for UPD in $UPDLIST
do
    UPD1=`echo $UPD | awk '{gsub(/.tar.gz/,".dat"); print} ' `
    UPD2=`echo $UPD1 | awk '{i=split($0,arr,"/"); print arr[i]} ' `
    if [ -s $TMPDIR/$MSTDIR/$UPD2 ]; then
        if [ "${UPD2:0:7}" = "ORCADBC" ]; then
	    echo $UPD2 >>${THISTIMELOG}
            su - $ORCAUSER -c "bash $TMPDIR/$MSTDIR/$UPD2 \"${DBOPTION}\" ${INSTALLLOG} ${THISTIMELOG}" >&2
        else
            su - $ORCAUSER -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -e $DBNAME < \"$TMPDIR/$MSTDIR/$UPD2\" " >&2
        fi
	echo "$TMPDIR/$MSTDIR/$UPD2 done." >&2
    fi
    LOGLIST=`awk '/ERROR:/{gsub(/\t| |;/,""); print} ' $THISTIMELOG`
    for LOG in $LOGLIST
    do
        if [ "${LOG:0:6}" = "ERROR:" ] ; then
            err "$UDP2 更新処理に失敗しました" 99
        fi
    done
    #DB管理情報更新
    echo "UPDATE tbl_dbkanri set dbsversion1='${UPD:0:21}',dbsversion2='${UPD:0:21}',upymd=to_char(now(),'yyyymmdd'),uphms=to_char(now(),'hh24miss') WHERE kanricd='ORCADB00';" | su - $ORCAUSER -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -e $DBNAME >&2"
    ECHO_N_RUN "."
done
ECHO_RUN "OK"

if [ -e /tmp/ORCA_CLEAN_INSTALL ]; then
  if [ "`cat /tmp/ORCA_CLEAN_INSTALL`" = "true" ]; then
    su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} ${DBNAME} -Atqc \"
      drop table if exists tbl_mstkanri_org;
      drop table if exists tbl_adrs_org;
      drop table if exists tbl_chk_org;
      drop table if exists tbl_hknjainf_org;
      drop table if exists tbl_srycdchg_org;
      drop table if exists tbl_tensu_org;\""
  fi
fi

rm -r $TMPDIR/$MSTDIR
ECHO_STDERR "全ての処理が完了しました"

exit 0
