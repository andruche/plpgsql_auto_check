#!/bin/bash

export PGDATABASE=test_db
PG_VERSION=15
PLPGSQL_CHECK_VERSION=2.8.5
CONTAINER_NAME=plpgsql_auto_test

export DOCKER_CLI_HINTS=false

echo "- remove previous container:"
docker rm -f $CONTAINER_NAME

set -e

if [ $# -eq 1 ]; then
    PG_VERSION=$1
elif [ $# -eq 2 ]; then
    PG_VERSION=$1
    PLPGSQL_CHECK_VERSION=$2
fi

image_name=$CONTAINER_NAME:${PG_VERSION}-${PLPGSQL_CHECK_VERSION}
echo "- build docker image:"
docker build -q -t $image_name \
       --build-arg PG_VERSION=$PG_VERSION \
       --build-arg PLPGSQL_CHECK_VERSION=$PLPGSQL_CHECK_VERSION \
       --build-context extension=../../extension .

echo "- start container:"
docker run --name $CONTAINER_NAME -e POSTGRES_PASSWORD=123456 -d $image_name
sleep 2
docker exec -u postgres $CONTAINER_NAME createdb $PGDATABASE

psql() {
  docker exec -u postgres $CONTAINER_NAME psql -q -d $PGDATABASE "$@"
}

run_test() {
  # args: --name <test name> --command <sql> --expected <sql running output pattern>
  if line=$(psql -c "$4" 2>&1 | grep "NOTICE:  plpgsql_check: $6"); then
    echo "$2: $line: ok"
  else
    echo "$2: failed"
  fi
}

psql -c "create extension plpgsql_check;"
psql -c "create extension plpgsql_auto_check;"

echo "- run tests:"

psql -c "create table table1 (id integer, val1 integer);"

run_test --name "1. miss table column name" --command "
create function miss_table_column_name() returns integer as '
begin
  return (select t.val2
            from table1 as t);
end;
' language plpgsql;
" --expected "ERROR: column t.val2 does not exist"

run_test --name "2. unused variable" --command "
create function unused_variable() returns void as '
declare
  my_var1 integer;
begin
end;
' language plpgsql;
" --expected "WARNING: unused variable \"my_var1\""

run_test --name "3. unused argument" --command "
create function unused_argument(arg1 integer) returns void as '
begin
end;
' language plpgsql;
" --expected "WARNING EXTRA: unused parameter \"arg1\""

psql -c "
create function update_table1_trigger() returns trigger as '
begin
  perform new.val2;
  return null;
end;
' language plpgsql;"

run_test --name "4. check trigger function when create trigger " --command "
create trigger update_table1 after update on table1
  for each row execute function update_table1_trigger();
" --expected "ERROR: record \"new\" has no field \"val2\""

run_test --name "5. check trigger function when change trigger function " --command "
create or replace function update_table1_trigger() returns trigger as '
begin
  perform new.val3;
  return null;
end;
' language plpgsql;
" --expected "ERROR: record \"new\" has no field \"val3\""
