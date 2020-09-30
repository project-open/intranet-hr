-- upgrade-5.0.3.0.1-5.0.3.0.2.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-5.0.3.0.1-5.0.3.0.2.sql','');


-------------------------------------------------------------------
-- DynField Widgets
-------------------------------------------------------------------


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'employee_status',			-- widget_name
	'#intranet-hr.Employee_Status#',	-- pretty_name
	'#intranet-hr.Employee_Status#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Employee Pipeline State"}}}'			-- Parameters
);

select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'salutation',			-- widget_name
	'#intranet-hr.Salutation#',	-- pretty_name
	'#intranet-hr.Salutation#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'im_category_tree',	-- widget
	'integer',		-- sql_datatype
	'{{custom {category_type "Intranet Salutation"}}}'			-- Parameters
);


select im_dynfield_widget__new (
	null,			-- widget_id
	'im_dynfield_widget',	-- object_type
	now(),			-- creation_date
	null,			-- creation_user
	null,			-- creation_ip	
	null,			-- context_id
	'supervisors',			-- widget_name
	'#intranet-hr.Supervisor#',	-- pretty_name
	'#intranet-hr.Supervisor#',	-- pretty_plural
	10007,			-- storage_type_id
	'integer',		-- acs_datatype
	'generic_sql',	-- widget
	'integer',		-- sql_datatype
	'{{custom {sql "select 
                0 as user_id,
                ''No Supervisor (CEO)'' as user_name
        from dual
    UNION
        select 
                u.user_id,
                im_name_from_user_id(u.user_id) as user_name
        from 
                users u,
                group_distinct_member_map m
        where 
                m.member_id = u.user_id
                and m.group_id = (select group_id from groups where group_name = ''Employee'')"}}}'			-- Parameters
);





-------------------------------------------------------------------
-- Create DynFields
-------------------------------------------------------------------



-- im_dynfield_attribute_new (o_type, column, pretty_name, widget_name, data_type, required_p, pos, also_hard_coded_p)

SELECT im_dynfield_attribute_new ('person', 'first_names', '#acs-subsite.first_names#', 'textbox_medium', 'string', 't', 0, 't');
SELECT im_dynfield_attribute_new ('person', 'last_name', '#acs-subsite.last_name#', 'textbox_medium', 'string', 't', 1, 't');
SELECT im_dynfield_attribute_new ('party', 'email', '#acs-subsite.Email#', 'textbox_medium', 'string', 't', 2, 't');
SELECT im_dynfield_attribute_new ('party', 'url', '#acs-subsite.URL#', 'textbox_medium', 'string', 't', 3, 't');



-- Salutation
SELECT im_dynfield_attribute_new ('person', 'salutation_id', '#intranet-hr.Salutation#', 'salutation', 'integer', 'f', 4, 'f');

-- Companies
SELECT im_dynfield_attribute_new ('im_company', 'company_name', '#intranet-core.Company_Name#', 
	'textbox_medium', 'string', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_path', '#intranet-core.Company_Path#', 
	'textbox_medium', 'string', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_status_id', '#intranet-core.Company_Status#', 
	'category_company_status', 'integer', 't', 1, 't');

SELECT im_dynfield_attribute_new ('im_company', 'company_type_id', '#intranet-core.Company_Types#', 
	'category_company_type', 'integer', 't', 1, 't');



create or replace function inline_0 ()
returns integer as '
declare
	v_count		integer;
begin
	select	count(*) into v_count from user_tab_columns 
	where	lower(table_name) = ''persons'' and lower(column_name) = ''salutation_id'';
	IF 0 != v_count THEN return 0; END IF;

	alter table persons 
	add column salutation_id integer
	constraint persons_salutation_fk
	references im_categories;

	return 0;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


