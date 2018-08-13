# Not meant to be a re-runnable script,as much as documentation
# on how we set up the RDS instance

#!/usr/bin/env bash
set -e

DATABASE="" # database URL
ROOT_USER="" # user with full create privileges
ROOT_PASSWORD="" # password

ROLE="readonly"
DATABASE_NAME="analysis"

# name of new user and password
USER=$1
PASSWORD=$2

PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "CREATE ROLE $ROLE;"
PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "GRANT CONNECT ON DATABASE $DATABASE_NAME TO $ROLE;"
PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO $ROLE;"
PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $ROLE;"

PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "CREATE EXTENSION pgcrypto;"

PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "CREATE USER $USER WITH PASSWORD '$PASSWORD';"
PGPASSWORD="$ROOT_PASSWORD" psql -U ${ROOT_USER} -h "$DATABASE" -c "GRANT $ROLE TO $USER;"
