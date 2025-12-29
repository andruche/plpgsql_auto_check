# plpgsql auto check

Online linter for plpgsql language which automatically checks functions when created / modified.

## quick example
```
tmp_db=# create table table1 (id integer, val1 integer);
CREATE TABLE

tmp_db=# create or replace function miss_table_column_name() returns integer as '
begin
  return (select t.val2
            from table1 as t);
end;
' language plpgsql;
CREATE FUNCTION

tmp_db=# create extension plpgsql_check;
CREATE EXTENSION

tmp_db=# create extension plpgsql_auto_check;
CREATE EXTENSION

tmp_db=# create or replace function miss_table_column_name() returns integer as '
begin
  return (select t.val2
            from table1 as t);
end;
' language plpgsql;
WARNING:  plpgsql_check (error): column t.val2 does not exist (sqlstate=42703)
Function: miss_table_column_name (line=3, statement=RETURN)
Query: (select t.val2
---------------^
            from table1 as t)
Hint:Perhaps you meant to reference the column "t.val1".
CREATE FUNCTION
```

## installation
1. [plpgsql_check](https://github.com/okbob/plpgsql_check) (dependencies):
```
VERSION=2.8.5
cd /opt/
wget https://github.com/okbob/plpgsql_check/archive/refs/tags/v${VERSION}.zip
unzip v${VERSION}.zip
cd /opt/plpgsql_check-${VERSION}/
make -j4 USE_PGXS=1 install

psql -d mydb -c "CREATE EXTENSION plpgsql_check;"
```
full installation instructions [here](https://github.com/okbob/plpgsql_check?tab=readme-ov-file#compilation)

2. plpgsql_auto_check:

create extension (recommended):
```bash
cd extension && make USE_PGXS=1 install  # or cp extension/* $(pg_config --sharedir)/extension/ 
psql -d mydb -c "CREATE EXTENSION plpgsql_auto_check"
```
or execute sql manually:
```bash
psql -d mydb -f extension/plpgsql_auto_check--1.0.sql
```

## dependencies
- plpgsql_check (extension)

## configuration parameters

### plpgsql_auto_check.enabled
```
set plpgsql_auto_check.enabled = {on|off}
```
Globally enables or disables the extension. When set to `off`, the event trigger is still present but no checks will be executed.

### plpgsql_auto_check.other_warnings
```
set plpgsql_auto_check.other_warnings = {on|off}
```
Controls whether `other warning` messages produced by `plpgsql_check` are reported. When disabled, these warnings will be ignored.

### plpgsql_auto_check.extra_warnings
```
set plpgsql_auto_check.extra_warnings = {on|off}
```
Controls whether `extra warning` messages produced by `plpgsql_check` are reported. When disabled, these warnings will be ignored.

### plpgsql_auto_check.exclude_sqlstates
```
set plpgsql_auto_check.exclude_sqlstates = '42804,42703'
```
Specifies a comma-separated list of SQLSTATE error codes to be ignored. Messages with matching SQLSTATE values will be excluded from reporting.

### plpgsql_auto_check.exclude_message_pattern
```
set plpgsql_auto_check.exclude_message_pattern = 'warning.* type is different type than|division by zero'
```
Message patterns (regex) used to suppress specific `plpgsql_check` messages. Messages matching of the pattern will be ignored.

### plpgsql_auto_check.on_error
```
set plpgsql_auto_check.on_error = {warning|error}
```
Defines how detected errors will be reported: as `WARNING`, or `ERROR`. When set to `error`, the DDL command that triggered the check will be aborted.

## tests
```
cd tests/regress
run_test [PG_VERSION] [PLPGSQL_CHECK_VERSION]
```
