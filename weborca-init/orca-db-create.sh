#! /bin/bash

JMARECEIPT_ENV="/opt/jma/weborca/app/etc/jma-receipt.env"
if [ ! -f ${JMARECEIPT_ENV} ]; then
    echo "${JMARECEIPT_ENV} does not found."
    exit 1
fi
. $JMARECEIPT_ENV

USEROPTION="--createdb --no-superuser --no-createrole "

USERCHECKSQL="SELECT usename FROM pg_user WHERE usename = '${DBUSER}';"
DBCHECKSQL="SELECT datname FROM pg_database WHERE datname = '${DBNAME}';"
SETPASSWORD="ALTER USER ${DBUSER} password '${DBPASS}';"
ENCODINGCHECK="SELECT pg_encoding_to_char(encoding) FROM pg_database WHERE datname = '${DBNAME}';"

ECHO_RUN () {
  echo -e "\e[1;34m${1}\e[m"
}

ECHO_STDERR() {
    echo "$@" >&2
}

err () {
  MSG="ERROR: $1"
  NUM=$2
  ECHO_STDERR -e $MSG
  exit ${NUM}
}

run_user_orca () {
  su - $ORCAUSER -c "$@"
  if [ $? -ne 0 ]; then
    err "$@" 99
  fi
  return 0
}

run_user_postgres () {
    su - postgres -c "$@"
    if [ $? -ne 0 ]; then
	err "$@" 99
    fi
    return 0
}

#!/bin/bash

# Function to execute a query as the PostgreSQL user 'postgres'
psql_user_postgres() {
    local query="$1"
    su - postgres -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} template1 -t -c \"$query\"" 2>&1
}

# Function to execute a query as the ORCA user
psql_user_orca() {
    local query="$1"
    su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} template1 -t -c \"$query\"" 2>&1
}

# Function to check if PostgreSQL is reachable
host_check() {
    local host="$1"
    echo "pgpassword:$PGPASSWORD"

    echo "Testing connection as 'postgres' user..."
    if output=$(psql_user_postgres "SELECT now();") >/dev/null 2>&1; then
        echo "Connection successful as 'postgres'."
    else
        echo "Connection failed as 'postgres': $output"
        return 1
    fi

    echo "Testing connection as 'orca_user'..."
    if output=$(psql_user_orca "SELECT now();") >/dev/null 2>&1; then
        echo "Connection successful as 'orca_user'."
    else
        echo "Connection failed as 'orca_user': $output"
        return 1
    fi

    echo "Testing connection with user '${ORCAUSER}' on database '${DBNAME}'..."
    if output=$(su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} ${DBNAME} -t -c \"SELECT now();\"") >/dev/null 2>&1; then
        echo "Connection successful with user '${ORCAUSER}' on database '${DBNAME}'."
    else
        echo "Connection failed with user '${ORCAUSER}' on database '${DBNAME}': $output"
        return 1
    fi
}

# Function to check the database host
dbhost_check() {
    local checkhost="$DBHOST"
    if [ -z "$checkhost" ]; then
        checkhost="localhost"
    fi

    echo -ne "DBHOST:\t\t"
    
    if host_check "$checkhost"; then
        echo "OK (PostgreSQL: $checkhost)"
    else
        echo "ERROR: Unable to connect to PostgreSQL at $checkhost"
        exit 99
    fi
}

create_dbuser() {
  # USER
  echo -ne "DBUSER:\t\t"
  if [ x"$DBHOST" = "x" ] || [ "$DBHOST" = "localhost" ]; then
    # localhost("")
    USEREXIST=`psql_user_postgres ${USERCHECKSQL}`
    RC=$?
    if [ $RC -ne 0 ] ; then
	err "SQL error" 99
    fi
    if [ -n "${USEREXIST}" ]; then
	echo "OK (${DBUSER})"
	return
    fi
    run_user_postgres "createuser ${DBCONNOPTION} ${USEROPTION} ${DBUSER}" >&2
    ECHO_RUN "CREATEUSER (${DBUSER})"
    # PASSWORD
    if [ x"$DBPASS" != "x" ]; then
	echo -ne "DBPASS:\t\t"
	psql_user_orca "${SETPASSWORD}" >&2
	RC=$?
	ECHO_RUN "SET (${DBUSER})"
    fi
  else
    # remote host
    if [ x"$PGPASS" = "x" ]; then
	err "not set PGPASS" 99
    fi
    USEREXIST=`psql_user_orca ${USERCHECKSQL}`
    RC=$?
    if [ $RC -ne 0 ] ; then
	err "SQL error" 99
    fi
    if [ -n ${USEREXIST} ]; then
	echo "OK"
	return
    fi
    ECHO_RUN "CREATEUSER (${DBUSER})"
    run_user_orca "createuser ${DBCONNOPTION} -U postgres ${USEROPTION} ${DBUSER}" >&2
    echo "done"
    # PASSWORD
    if [ x"$DBPASS" != "x" ]; then
	echo -ne "DBPASS:\t\t"
	run_user_orca "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} -U postgres -c \"${SETPASSWORD}\""
	ECHO_RUN "SET (${DBUSER})"
    fi
  fi
  return $RC
}

create_db(){
  echo -ne "DATABASE:\t"
  # DB
  DBEXIST=`su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} template1 -t -c \"${DBCHECKSQL}\""`
  RC=$?
  if [ ! -z $DBEXIST ] ; then
    DBEXIST=`su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} ${DBNAME} -t -c \"${DBCHECKSQL}\""`
    RC=$?
  fi
  if [ $RC -ne 0 ] ; then
    err "database check error (${DBCHECKSQL})" 99
  fi
  if [ ! -z $DBEXIST ] ; then
      echo "OK (${DBNAME})"
      return 0
  fi
  su - ${ORCAUSER} -c "createdb ${DBCONNOPTION} -lC -Ttemplate0 -E${DBENCODING} \"${DBNAME}\""
  if [ $? -ne 0 ] ; then
      err "createdb error (${DBNAME})" 99
  fi
  ECHO_RUN "CREATEDB (${DBNAME})"
}

dbencoding() {
  echo -ne "DBENCODING:\t"
  ORCAENCODING=`su - ${ORCAUSER} -c "PGPASSWORD=$PGPASSWORD psql ${DBCONNOPTION} ${DBNAME} -t -c \"${ENCODINGCHECK}\""`
  if [ $? -ne 0 ] ; then
      err "encoding error (${DBNAME})" 99
  fi
  if [ $DBENCODING = "UTF-8" ] || [ $DBENCODING = "UTF8" ] || [ $DBENCODING = "utf-8" ] || [ $DBENCODING = "utf8" ] ; then
      if [ $ORCAENCODING != "UTF8" ]; then
	  err "encoding error Database(${ORCAENCODING}) != DBENCODING(${DBENCODING})" 98
      fi
  else
      if [ $ORCAENCODING != "EUC_JP" ]; then
	  err "encoding error Database(${ORCAENCODING}) != DBENCODING(${DBENCODING})" 98
      fi
  fi
  echo "OK (${DBENCODING})"
}

if [ -z "$DBENCODING" ]
then
    DBENCODING="EUC-JP"
fi

create_pgpass
if [ "$DBHOST" = "localhost" ]; then
  DBCONNOPTION=
fi

dbhost_check
create_dbuser
create_db
dbencoding

exit 0
