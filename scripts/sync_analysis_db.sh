#!/usr/bin/env bash
set -e

# Provide environment as first argument (i.e: staging, production)
ENV=$1

# Need to run with the debug flag enabled because foreign key constraints fail
# if tables are copied in parallel
DATABASE_URL=$(cd terraform/${ENV}; terraform output database_url)

DATABASE_URL=${DATABASE_URL} bundle exec pgsync all --debug #--schema-first
