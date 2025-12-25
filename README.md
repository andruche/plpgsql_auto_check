# plpgsql auto check

The event trigger plpgsql_auto_check automatically checks functions when created / modified.

### installation
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
psql -d mydb -c "CREATE EXTENSION plpgsql_check"
psql -d mydb -c "CREATE EXTENSION plpgsql_auto_check"
```
or execute sql manually:
```bash
psql -d mydb -c "CREATE EXTENSION plpgsql_check"
psql -d mydb -f extension/plpgsql_auto_check--1.0.sql
```

### dependencies
- plpgsql_check (extension)
### tests
```
cd tests/regress
run_test [PG_VERSION] [PLPGSQL_CHECK_VERSION]
```
