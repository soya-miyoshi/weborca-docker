#!/bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

DBGROUPINC=${SYSCONFDIR}/dbgroup.inc
SUBNAME="log"

HOSTPORT=""
if [ "x${DBHOST}" != "x" ] ; then
    if [ "x${DBPORT}" != "x" ] ; then
	HOSTPORT="${DBHOST}:${DBPORT}"
    else
	HOSTPORT="${DBHOST}"
    fi
fi
if [ "x${SSLMODE}" != "x" ] ; then
    STRSSLMODE="sslmode \"${SSLMODE}\";"
fi
: > $DBGROUPINC
chown $ORCAUSER:$ORCAGROUP $DBGROUPINC
chmod 0600 $DBGROUPINC

cat << _EOF_ >> $DBGROUPINC
db_group {
 type "PostgreSQL";
 port "${HOSTPORT}"; $STRSSLMODE
 name "${DBNAME}";
 user "${DBUSER}";
 password "${DBPASS}";
 redirect "${SUBNAME}";
};

_EOF_

function slave_dbgroup () {
    SNAME=$1
    SDBNAME=$2
    SDBHOST=$3
    SDBPORT=$4
    SDBUSER=$5
    SDBPASS=$6
    SSSLMODE=$7
    SREDIRECTLOG=$8
    SREDIRECT=$9
    SREDIRECTPORT=${10}

    SUBHOSTPORT=""
    if [ "x${SDBHOST}" != "x" ] ; then
	if [ "x${SDBPORT}" != "x" ] ; then
	    SUBHOSTPORT="${SDBHOST}:${SDBPORT}"
	else
	    SUBHOSTPORT="${SDBHOST}"
	fi
    fi
    STRSUBSSLMODE=""
    if [ "x${SUBSSLMODE}" != "x" ] ; then
	STRSUBSSLMODE="sslmode \"${SUBSSLMODE}\";"
    fi
    STRREDIRECTLOG=""
    if [ "x${SREDIRECTLOG}" != "x" ] ; then
	STRREDIRECTLOG="file \"${SREDIRECTLOG}\";"
    fi
    STRREDIRECT=""
    if [ "x${SREDIRECT}" != "x" ] ; then
	STRREDIRECT="redirect \"${SREDIRECT}\";"
    fi
    cat << _EOF_ >> $DBGROUPINC
db_group "${SNAME}" {
 priority 100;
 type "PostgreSQL";
 port "${SUBHOSTPORT}"; $STRSUBSSLMODE
 name "${SDBNAME}";
 user "${SDBUSER}";
 password "${SDBPASS}";
 ${STRREDIRECTLOG}
 ${STRREDIRECT}
 redirect_port "localhost:${SREDIRECTPORT}";
};

_EOF_
}

if [ -z ${SUBDBNAME} ] ; then
    exit
fi
REDIRECTPORT="8010";
slave_dbgroup "$SUBNAME" "$SUBDBNAME" "$SUBDBHOST" "$SUBDBPORT" "$SUBDBUSER" "$SUBDBPASS" "$SUBSSLMODE" "$REDIRECTLOG" "$SUB2NAME" "$REDIRECTPORT"

if [ -z ${SUB2DBNAME} ] ; then
    exit
fi
SUB2REDIRECTPORT=`expr $REDIRECTPORT + 1`
slave_dbgroup "$SUB2NAME" "$SUB2DBNAME" "$SUB2DBHOST" "$SUB2DBPORT" "$SUB2DBUSER" "$SUB2DBPASS" "$SUB2SSLMODE" "" "" "$SUB2REDIRECTPORT"
