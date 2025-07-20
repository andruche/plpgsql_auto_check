create extension if not exists plpgsql_check schema pg_catalog;

create or replace function pg_catalog.plpgsql_auto_check() returns event_trigger as $$
declare
  verror text;
begin
  select string_agg(
           format(e'%s (sqlstate=%s, line=%s, statement=%s): %s%s%s%s%s',
                  upper(f.level), f.sqlstate, f.lineno, f.statement, f.message,
                  coalesce(e'\nQuery: ' || formated.query, ''),
                  coalesce(e'\nDetail: ' || f.detail, ''),
                  coalesce(e'\nHint:' || f.hint, ''),
                  coalesce(e'\nContext: ' || f.context, '')),
           e'\n\n')
    into verror
    from pg_event_trigger_ddl_commands() obj
   inner join pg_proc p
           on p.oid = obj.objid
   inner join pg_language l
           on l.oid = p.prolang
   cross join plpgsql_check_function_tb(obj.objid::regproc) f
   cross join lateral (select substr(query, 1, f.position + shift_to_rigth-1) || e'\n' ||
                              repeat('-', shift_to_left) ||'^'||
                              substr(query, f.position + shift_to_rigth)
                         from substr(query, f.position) as qafter
                        cross join coalesce(nullif(position(e'\n' in substr(f.query, f.position)), 0) - 1,
                                            length(substr(query, f.position))) as shift_to_rigth
                        cross join coalesce(nullif(position(e'\n' in reverse(substr(query, 1, f.position))), 0) -2,
                                            f.position + 6) as shift_to_left
                        ) as formated(query)
   where l.lanname = 'plpgsql' and
         p.prorettype <> 'trigger'::regtype and
         not (sqlstate = '42804' and --datatype_mismatch
              level = 'warning');

  if verror is not null then
    raise notice 'plpgsql_check: %', verror;
  end if;
end;
$$ language plpgsql;

create event trigger plpgsql_auto_check
  on ddl_command_end
  when tag in ('CREATE FUNCTION')
  execute procedure pg_catalog.plpgsql_auto_check();
