-- 5.1.0.0.4-5.1.0.0.5.sql
SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-5.1.0.0.4-5.1.0.0.5.sql','');


-- Fix previous queues
create or replace function inline_0 ()
returns integer as $body$
declare
	v_count			integer;
BEGIN
	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_employees' and lower(column_name) = 'vacation_balance_year';
	IF (v_count = 0) THEN
		-- From when is the vacation_balance? Should be 1st of Jan of year
		alter table im_employees add vacation_balance_year date default date_trunc('year', now());
	END IF;

	select	count(*) into v_count from user_tab_columns
	where	lower(table_name) = 'im_employees' and lower(column_name) = 'vacation_balance_backup_previous_year';
	IF (v_count = 0) THEN
		-- Just a backup of the previous balance
		alter table im_employees add vacation_balance_backup_previous_year numeric(12,2) default 0.0;
	END IF;

	return 0;
end;$body$ language 'plpgsql';
select inline_0();
drop function inline_0();

