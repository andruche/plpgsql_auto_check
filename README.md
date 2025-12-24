# plpgsql auto check

The event trigger plpgsql_auto_check automatically checks functions when created / modified.

### installation

```
psql -d mydb -f enable_plpgsql_auto_check.sql
```

### dependencies
- plpgsql_check extension

### tests
```
cd tests/regress
run_test [PG_VERSION] [PLPGSQL_CHECK_VERSION]
```
