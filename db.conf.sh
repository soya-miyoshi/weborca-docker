#############################################################################
# Override the default config set in /opt/jma/weborca/app/etc/jma-receipt.env 
#############################################################################
# allow export to en environment variable
set -a

export DBNAME=$ORCA_DBNAME
export DBUSER=$ORCA_DBUSER
export DBPASS=$ORCA_DBPASS
export DBHOST=$ORCA_DBHOST
export DBPORT=$ORCA_DBPORT
export PGPASSWORD=$PGPASSWORD
