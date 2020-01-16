-- upgrade-5.0.3.0.0-5.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-5.0.3.0.0-5.0.3.0.1.sql','');



-- Add new vacation balance fields
--
create or replace function inline_0 () 
returns integer as $body$
DECLARE
	v_count			integer;
BEGIN
	-- Check if colum exists in the database
	select	count(*) into v_count from user_tab_columns where lower(table_name) = 'im_employees' and lower(column_name) = 'vacation_balance_year';
	IF v_count > 0  THEN return 1; END IF; 

	alter table im_employees add vacation_balance_year date default date_trunc('year', now());
	alter table im_employees add vacation_balance_backup_previous_year numeric(12,2) default 0.0;

	return 0;
END;$body$ language 'plpgsql';
SELECT inline_0 ();
DROP FUNCTION inline_0 ();

