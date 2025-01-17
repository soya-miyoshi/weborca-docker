#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

FLAG=`id -u`

if [ "${LANG}" != "ja_JP.UTF-8" ] && [ "${LANG}" != "ja_JP.utf8" ] ; then
  echo "ERROR: change charactor-code ja_JP.UTF-8 (or ja_JP.utf8)"
  exit 1
fi

if [ ${FLAG} -ne 0 ] ; then
  echo "ERROR: root権限で実行してください。"
  exit 1
fi

if [ $# -eq 0 ] ; then
  echo "ERROR: オプションを指定してください。"
  exit 1
fi

COB_LIBRARY_PATH="$PATCHLIBDIR":"$ORCALIBDIR":"$PANDALIB"
export COB_LIBRARY_PATH

CMDNAME=`basename $0`

usage() {
echo "usage: sudo sh ${CMDNAME} [-mlh]"
echo ""
echo "       -m : レコード更新"
echo "       -l : レコード一覧"
echo "       -h : ヘルプ表示"
echo ""
echo "      [-g グループ番号]"
echo "      [-n 医療機関識別番号]"
echo "      [-k 期限]"
echo "      [-H 本院分院番号]"
echo "      [-b 本院分院区分]"
echo "      [-N 医療機関名]"
echo ""
}

GRPNUM=
HOSPNUM=
KIGEN=
HBGRP=
HBKBN=
HOSPNAME=
RECORD=

PARAM=

while getopts 'mlhg:H:n:k:b:N:r' OPTION
do
  case "${OPTION}" in
   m | l )
      if [ -z ${PARAM} ]; then
        case "${OPTION}" in
	 m )
	    PARAM=mod
	 ;;
	 l )
	    PARAM=lst
	 ;;
	esac
      else
        usage
	exit 0
      fi
      ;;
   g )
      GRPNUM=${OPTARG}
      ;;
   H )
      HBGRP=${OPTARG}
      ;;
   n )
      HOSPNUM=${OPTARG}
      ;;
   k )
      KIGEN=${OPTARG}
      ;;
   b )
      HBKBN=${OPTARG}
      ;;
   N )
      HOSPNAME=${OPTARG}
      ;;
   r )
      RECORD=${OPTARG}
      ;;
   h | ? )
      usage
      exit 0
      ;;
  esac
done

if [ -z ${RECORD} ]; then
  PARAM="${PARAM},${GRPNUM},${HOSPNUM},${KIGEN},${HBGRP},${HBKBN},${HOSPNAME}"
else
  PARAM="${PARAM},${RECORD}"
fi

#su $ORCAUSER -c "$DBSTUB -dir $LDDIRECTORY -bd orcabt ORCBSETSYSBASE -parameter $PARAM | nkf -w"
su $ORCAUSER -c "$DBSTUB -dir $LDDIRECTORY -bd orcabt ORCBSETSYSBASE -parameter $PARAM"
echo
cat /tmp/sysbase-result | nkf -w

exit 0
