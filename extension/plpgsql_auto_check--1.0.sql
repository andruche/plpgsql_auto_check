create or replace function plpgsql_auto_check() returns event_trigger as $$
declare
  verror text;
  vextra_warnings boolean;
  vother_warnings boolean;
  vexclude_sqlstates text[];
  vexclude_message_pattern text;
begin
  if current_setting('plpgsql_auto_check.enabled', true) in ('false', 'off') then
      return;
  end if;

  vextra_warnings := current_setting('plpgsql_auto_check.extra_warnings', true) in ('false', 'off') is not true;
  vother_warnings := current_setting('plpgsql_auto_check.other_warnings', true) in ('false', 'off') is not true;
  vexclude_sqlstates := string_to_array(nullif(current_setting('plpgsql_auto_check.exclude_sqlstates', true), ''), ',');
  vexclude_message_pattern := nullif(current_setting('plpgsql_auto_check.exclude_message_pattern', true), '');

  select string_agg(
           format(
              e'%s: %s (sqlstate=%s)\nFunction: %s (line=%s, statement=%s)%s%s%s%s%s',
              upper(f.level), f.message, f.sqlstate, p.oid::regproc, f.lineno, f.statement,
              coalesce(e'\nTrigger: ' || p.tgname || ' on ' || p.tgrelid::regclass, ''),
              coalesce(e'\nQuery: ' || formated.query, ''),
              coalesce(e'\nDetail: ' || f.detail, ''),
              coalesce(e'\nHint:' || f.hint, ''),
              coalesce(e'\nContext: ' || f.context, '')),
           e'\n\n')
    into verror
    from pg_event_trigger_ddl_commands() obj
   cross join lateral (select p.oid, p.prolang, t.tgrelid, t.tgname
                         from pg_proc p
                         left join pg_trigger t
                                on t.tgfoid = p.oid
                        where obj.object_type = 'function' and
                              p.oid = obj.objid and
                              (p.prorettype <> 'trigger'::regtype
                               or
                               t.tgrelid is not null)
                       union all
                       select p.oid, p.prolang, t.tgrelid, t.tgname
                         from pg_trigger t
                        inner join pg_proc p
                                on p.oid = t.tgfoid
                        where obj.object_type = 'trigger' and
                              t.oid = obj.objid) p
   inner join pg_language l
           on l.oid = p.prolang
   cross join plpgsql_check_function_tb(
                p.oid::regproc,
                coalesce(p.tgrelid, 0),
                extra_warnings := vextra_warnings,
                other_warnings := vother_warnings) f
   cross join lateral (select substr(query, 1, f.position + shift_to_rigth-1) || e'\n' ||
                              repeat('-', shift_to_left) || '^' ||
                              substr(query, f.position + shift_to_rigth)
                         from substr(query, f.position) as qafter
                        cross join coalesce(nullif(position(e'\n' in substr(f.query, f.position)), 0) - 1,
                                            length(substr(query, f.position))) as shift_to_rigth
                        cross join coalesce(nullif(position(e'\n' in reverse(substr(query, 1, f.position))), 0) -2,
                                            f.position + 6) as shift_to_left) as formated(query)
   where l.lanname = 'plpgsql' and
         (f.sqlstate <> all(vexclude_sqlstates) or vexclude_sqlstates is null) and
         (format('%s: %s', upper(f.level), f.message)  !~ vexclude_message_pattern or vexclude_message_pattern is null);

  if verror is not null then
    raise notice 'plpgsql_check: %', verror;
  end if;
end;
$$ language plpgsql;

create event trigger plpgsql_auto_check
  on ddl_command_end
  when tag in ('CREATE FUNCTION', 'CREATE TRIGGER')
  execute procedure plpgsql_auto_check();
