#!/usr/bin/env bash

# Provide db url as environment variable

# Need to run with the debug flag enabled because foreign key constraints fail
# if tables are copied in parallel

DATABASE_URL=${DATABASE_URL} bundle exec pgsync all --debug
