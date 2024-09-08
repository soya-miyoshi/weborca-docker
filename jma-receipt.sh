prefix=/opt/jma/weborca/app
exec_prefix=${prefix}

SYSCONFDIR=${prefix}/etc

ORCA_DIR=${exec_prefix}

DIRECTORYFILE=directory

COPYDIR=${ORCA_DIR}/cobol/copy
ORCADATADIR=${ORCA_DIR}/data
DOCDIR=${ORCA_DIR}/doc
FORMDIR=${ORCA_DIR}/form
INITDIR=${ORCA_DIR}/init
LDDEFDIR=${ORCA_DIR}/lddef
LDDIRECTORY=${LDDEFDIR}/${DIRECTORYFILE}
RECORDDIR=${ORCA_DIR}/record
SCREENDIR=${ORCA_DIR}/screen
SCRIPTSDIR=${ORCA_DIR}/scripts
BINDIR=${ORCA_DIR}/bin
ORCALIBDIR=${exec_prefix}

PATCHDIR=${prefix}/patch-lib
PATCHLIBDIR=${prefix}/patch-lib

PATCHCOPYDIR=${PATCHDIR}/cobol/copy
PATCHDATADIR=${PATCHDIR}/data
PATCHFORMDIR=${PATCHDIR}/form
PATCHINITDIR=${PATCHDIR}/init
PATCHLDDEFDIR=${PATCHDIR}/lddef
PATCHRECORDDIR=${PATCHDIR}/record
PATCHSCREENDIR=${PATCHDIR}/screen
PATCHSCRIPTSDIR=${PATCHDIR}/scripts

SITEDIR=/opt/jma/weborca/site-lib
SITESRCDIR=/usr/local/site-jma-receipt
SITELIBDIR=${ORCALIBDIR}

SITECOPYDIR=${SITEDIR}/cobol/copy
SITEDATADIR=${SITEDIR}/data
SITEFORMDIR=${SITEDIR}/form
SITEINITDIR=${SITEDIR}/init
SITELDDEFDIR=${SITEDIR}/lddef
SITERECORDDIR=${SITEDIR}/record
SITESCREENDIR=${SITEDIR}/screen
SITESCRIPTSDIR=${SITEDIR}/scripts

NUMERICHOST=true

export PATH=$PATH:${SCRIPTSDIR}/daily:${SCRIPTSDIR}/monthly:${SCRIPTSDIR}/allways:${SCRIPTSDIR}/claim:/opt/jma/weborca/mw/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/jma/weborca/cobol/libcob

DBSTUB="/opt/jma/weborca/mw/bin/dbstub"

#if [ -f /etc/default/jma-receipt ]
#then
#       . /etc/default/jma-receipt
#fi

DBSYNC=dbsync
MONUPLOAD=monupload
MONBLOB=monblob
MONBATCH=monbatch
MONINFO=moninfo
MONSQL=monsql

CPP="gcc -E"

COBOL="/opt/jma/weborca/cobol/bin/cobc"
COBOLFLAGS="-m -dynamic -fixed -fimplicit-init -std=cobol85 -Wall -L/opt/jma/weborca/cobol/libcob "

DBUPGRADEPATH=https://ftp.orca.med.or.jp/pub/orca_data
PGUPGRADEPATH=https://dl.orca.med.or.jp/bugfix/ubuntu/amd64/unknown
MSTUPDATEPATH=https://ftp.orca.med.or.jp/pub/orca_data
DBLICENSEPATH=https://dl.orca.med.or.jp/orca_data

MSTSRVPATH=https://dl.orca.med.or.jp/orca_data/master
ORCAIDPATH=https://orcaid.orca.med.or.jp/api
ACCESSKEYPATH=${ORCAIDPATH}/keys

PGUP_PROOF="${PATCHLIBDIR}/patch-program.prf"

CACERTFILE=/etc/ssl/certs/orca-project-ca.crt
DASDIR="/opt/jma/weborca/var/das"
MASTERDIR="/opt/jma/weborca/var/master"
LOGDIR=/opt/jma/weborca/log
#REDIRECTLOG="/var/lib/jma-receipt/dbredirector/orca.log"
WGETOPTION=

#PANDALIB="/usr/lib/panda"

#############################################################################
# create .pgpass
#############################################################################
create_pgpass (){
  if [ -z "$DBPASS" ] ; then
    return 0
  fi
  if [ ! -z "$ORCAPGPASSFILE" ] ; then
    return 1
  fi

  trap delete_pgpass EXIT

  PGPASSPATH=`eval echo ~${ORCAUSER}`
  ORCAPGPASSFILE=$(mktemp  ${PGPASSPATH}/.pgpass_jma-receipt.XXXXXXX)
  echo "${DBHOST}:${DBPORT}:*:${DBUSER}:${DBPASS}" > $ORCAPGPASSFILE
  echo "${DBHOST}:${DBPORT}:*:${PGUSER}:${PGPASS}" >> $ORCAPGPASSFILE
  if [ $(whoami) != $ORCAUSER ] ; then
    chown $ORCAUSER:$ORCAGROUP $ORCAPGPASSFILE
  fi
  export PGPASSFILE=$ORCAPGPASSFILE
}
#############################################################################
# delete .pgpass
#############################################################################
delete_pgpass(){
  if [ -z "$DBPASS" ] ; then
    return 0
  fi
  if [ -z "$ORCAPGPASSFILE" ] ; then
    return 1
  fi
  rm $ORCAPGPASSFILE
  unset ORCAPGPASSFILE
}
#############################################################################
ORCAUSER=orca
ORCAGROUP=orca

#############################################################################
# Database Program file
#############################################################################
PGVERSION=14
PGCLUSTER=main
PGPATH=/var/lib/postgresql/14
PGDATA=${PGPATH}/${PGCLUSTER}
PGDATA_BACKUP_DIR=/var/tmp

#############################################################################
# Database Default
#############################################################################
DBNAME="orca"
DBUSER="orca"
DBPASS="orca"
DBHOST=$ORCA_DBHOST
DBPORT="5432"
DBENCODING="UTF-8"
PGUSER="postgres"
PGPASS="postgres"

DBCONNOPTION=""
#############################################################################

umask 066

export HTTP_PORT=8000
export HTTP_HOST=http://localhost

if [ -f /opt/jma/weborca/conf/db.conf ]; then
   . /opt/jma/weborca/conf/db.conf
fi
. /opt/jma/weborca/conf/jma-receipt.conf

#############################################################################
if [ ! x"$DBHOST" = "x" ] ; then
  DBCONNOPTION="-w -h ${DBHOST} -p ${DBPORT} -U ${DBUSER} "
fi
#############################################################################
export FORCE_CLEAR_SPA=1
#############################################################################