-- /packages/intranet-hr/sql/oracle/intranet-hr-create.sql
--
-- Project/Open HR Module, fraber@fraber.de, 030828
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- Copyright (C) 1999-2004 ArsDigita, Frank Bergmann and others
--
-- This program is free software. You can redistribute it 
-- and/or modify it under the terms of the GNU General 
-- Public License as published by the Free Software Foundation; 
-- either version 2 of the License, or (at your option) 
-- any later version. This program is distributed in the 
-- hope that it will be useful, but WITHOUT ANY WARRANTY; 
-- without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU General Public License for more details.


----------------------------------------------------
-- Employees
--
-- Employees is a subclass of Users
-- So according to the AC conventions, there is an
-- additional table *_info which contains the additional
-- fields.
--

prompt *** Creating im_employees
create table im_employees (
	employee_id		integer 
				constraint im_employees_pk
				primary key 
				constraint im_employees_id_fk
				references parties,
	department_id		integer 
				constraint im_employees_department_fk
				references im_cost_centers,
	job_title		varchar(200),
	job_description		varchar(4000),
				-- part_time = 50% availability
	availability		integer,
	supervisor_id		integer 
				constraint im_employees_supervisor_fk
				references parties,
	ss_number		varchar(20),
	salary			number(12,3),
	social_security		number(12,3),
	insurance		number(12,3),
	other_costs		number(12,3),
	currency		char(3)
				constraint im_employees_currency_fk
				references currency_codes,
	salary_period		varchar(12) default 'month' 
				constraint im_employees_salary_period_ck
				check (salary_period in ('hour','day','week','month','year')),
	salary_payments_per_year integer default 12,
				--- W2 information
	dependant_p		char(1) 
				constraint im_employees_dependant_p_con 
				check (dependant_p in ('t','f')),
	only_job_p		char(1) 
				constraint im_employees_only_job_p_con 
				check (only_job_p in ('t','f')),
	married_p		char(1) 
				constraint im_employees_married_p_con 
				check (married_p in ('t','f')),
	dependants		integer,
	head_of_household_p	char(1)
				constraint im_employees_head_of_house_con 
				check (head_of_household_p in ('t','f')),
	birthdate		date,
	skills			varchar(2000),
	first_experience	date,	
	years_experience	number(5,2),
	educational_history	varchar(4000),
	last_degree_completed	varchar(100),
				-- employee lifecycle management
	employee_status_id	integer
				constraint im_employees_rec_state_fk
				references im_categories,
	termination_reason	varchar(4000),
	voluntary_termination_p	char(1) default 'f'
				constraint im_employees_vol_term_ck
				check (voluntary_termination_p in ('t','f')),
				-- did s/he sign non disclosure agreement?
	signed_nda_p		char(1)
				constraint im_employees_conf_p_con 
				check(signed_nda_p in ('t','f')),
	referred_by 		integer
				constraint im_employees_referred_fk 
				references parties,
	experience_id		integer 
				constraint im_employees_experience_fk
				references im_categories,
	source_id		integer 
				constraint im_employees_source_fk
				references im_categories,
	original_job_id		integer 
				constraint im_employees_org_job_fk
				references im_categories,
	current_job_id		integer 
				constraint im_employees_current_job_fk
				references im_categories,
	qualification_id	integer 
				constraint im_employees_qualification_fk
				references im_categories		
);
create index im_employees_referred_idx on im_employees(referred_by);

alter table im_employees
add constraint im_employees_superv_ck
check (supervisor_id != employee_id);


-- Select all information for active employees
-- (member of Employees group).
--
create or replace view im_employees_active as
select
	u.*,
	e.*,
	pa.*,
	pe.*
from
	users u,
	parties pa,
	persons pe,
	im_employees e,
	groups g,
	group_distinct_member_map gdmm,
	-- for member_state=approved check:
        membership_rels mr,
        acs_magic_objects mo,
        group_member_map m
where
	u.user_id = pa.party_id
	and u.user_id = pe.person_id
	and u.user_id = e.employee_id(+)
	and g.group_name = 'Employees'
	and gdmm.group_id = g.group_id
	and gdmm.member_id = u.user_id
	-- for member_state=approved check:
	and m.member_id = u.user_id
        and mo.name = 'registered_users'
        and m.group_id = mo.object_id
        and m.rel_id = mr.rel_id
        and m.rel_type = 'membership_rel'
        and m.container_id = m.group_id
	and mr.member_state = 'approved'
;



-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_users without these indices

create index im_employees_idx1 on im_employees(employee_id, supervisor_id);
create index im_employees_idx2 on im_employees(supervisor_id, employee_id);



-- Employee Pipeline State
insert into im_categories (category_id, category, category_type) values 
(450, 'Potential', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(451, 'Received Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(452, 'Failed Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(453, 'Approved Test', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(454, 'Active', 'Intranet Employee Pipeline State');
insert into im_categories (category_id, category, category_type) values 
(455, 'Past', 'Intranet Employee Pipeline State');


------------------------------------------------------
-- HR Views
--
create or replace view im_prior_experiences as
select category_id as experience_id, category as experience
from im_categories
where category_type = 'Intranet Prior Experience';

create or replace view im_hiring_sources as
select category_id as source_id, category as source
from im_categories
where category_type = 'Intranet Hiring Source';

create or replace view im_job_titles as
select category_id as job_title_id, category as job_title
from im_categories
where category_type = 'Intranet Job Title';

create or replace view im_qualification_processes as
select category_id as qualification_id, category as qualification
from im_categories
where category_type = 'Intranet Qualification Process';

create or replace view im_employee_pipeline_states as
select category_id as state_id, category as state
from im_categories
where category_type = 'Intranet Employee Pipeline State';



prompt *** Creating im_supervises_p
create or replace function im_supervises_p(
	v_supervisor_id IN integer, 
	v_user_id IN integer)
return varchar
is
	v_exists_p char;
BEGIN
	select decode(count(1),0,'f','t') into v_exists_p
	from im_employees
	where employee_id = v_user_id
	and level > 1
	start with employee_id = v_supervisor_id
	connect by supervisor_id = PRIOR employee_id;
	return v_exists_p;
END im_supervises_p;
/
show errors


-- at given stages in the employee cycle, certain checkpoints
-- must be competed. For example, the employee should receive
-- an offer letter and it should be put in the employee folder

prompt *** Creating im_employee_checkpoints
create sequence im_employee_checkpoint_id_seq;
create table im_employee_checkpoints (
	checkpoint_id		integer
				constraint im_emp_checkp_pk
				primary key,
	stage			varchar(100) not null,
	checkpoint		varchar(500) not null
);

create table im_emp_checkpoint_checkoffs (
	checkpoint_id		integer 
				constraint im_emp_checkpoff_checkp_fk
				references im_employee_checkpoints,
	checkee			integer not null 
				constraint im_emp_checkpoff_checkee_fk
				references parties,
	checker			integer not null 
				constraint im_emp_checkpoff_checker_fk
				references parties,
	check_date		date,
	check_note		varchar(1000),
		constraint im_emp_checkpoff_pk
		primary key (checkee, checkpoint_id)
);




prompt *** Creating im_views
insert into im_views (view_id, view_name, visible_for) values (55, 'employees_list', 'view_users');
insert into im_views (view_id, view_name, visible_for) values (56, 'employees_view', 'view_users');




prompt *** Creating im_view_columns for employees_list
delete from im_view_columns where column_id >= 5500 and column_id < 5599;

insert into im_view_columns (column_id, view_id, group_id, column_name, 
column_render_tcl, extra_select, extra_from, extra_where, sort_order, visible_for
) values (5500,55,NULL,'Name',
	'"<a href=/intranet/users/view?user_id=$user_id>$name</a>"',
	'e.supervisor_id, im_name_from_user_id(e.supervisor_id) as supervisor_name',
	'im_employees e',
	'u.user_id = e.employee_id(+)',
	0,
	''
);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5501,55,'Email','"<a href=mailto:$email>$email</a>"',3);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5502,55,'Supervisor',
'"<a href=/intranet/users/view?user_id=$supervisor_id>$supervisor_name</a>"',3);

-- insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
-- sort_order)values (5502,55,'Status','$status','','',4,'');

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5504,55,'Work Phone','$work_phone',6);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5505,55,'Cell Phone','$cell_phone',7);

insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5506,55,'Home Phone','$home_phone',8);
--
commit;




prompt *** Creating im_view_columns for employees_view
delete from im_view_columns where column_id >= 5600 and column_id < 5699;
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5600,56,'Department',
'"<a href=${department_url}$department_id>$department_name</a>"',0);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5602,56,'Job Title','$job_title',02);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5604,56,'Job Description','$job_description',04);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5606,56,'Availability %','$availability',06);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5608,56,'Supervisor',
'"<a href=${user_url}$supervisor_id>$supervisor_name</a>"',08);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5610,56,'Social Security #','$ss_number',10);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5612,56,'Salary','$salary',12);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5614,56,'Social Security','$social_security',14);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5616,56,'Insurance','$insurance',16);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5618,56,'Other Costs','$other_costs',18);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5620,56,'Salary Period','$salary_period',20);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5622,56,'Salaries per Year','$salary_payments_per_year',22);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5624,56,'Birthdate','$birthdate',24);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5626,56,'Start Date','$start_date',26);
insert into im_view_columns (column_id, view_id, column_name, column_render_tcl,
sort_order) values (5628,56,'Termination Date','$end_date',28);
commit;




prompt *** Creating User Freelance Component plugin
-- Show the freelance information in users view page
--
declare
    v_plugin            integer;
begin
    v_plugin := im_component_plugin.new (
        plugin_name =>  'User Employee Component',
        package_name => 'intranet-hr',
        page_url =>     '/intranet/users/view',
        location =>     'left',
        sort_order =>   60,
        component_tcl =>
        'im_employee_info_component \
                $user_id \
                $return_url \
                [im_opt_val employee_view_name]'
    );
end;
/



prompt *** Creating OrgChart menu entry
-- Add OrgChart to Users menu
declare
	v_user_orgchart_menu	integer;
	v_user_menu		integer;

        -- Groups
        v_employees     	integer;
        v_accounting    	integer;
        v_senman                integer;
        v_customers     	integer;
        v_freelancers   	integer;
        v_proman                integer;
        v_admins                integer;
begin
    select group_id into v_admins from groups where group_name = 'P/O Admins';
    select group_id into v_senman from groups where group_name = 'Senior Managers';
    select group_id into v_proman from groups where group_name = 'Project Managers';
    select group_id into v_accounting from groups where group_name = 'Accounting';
    select group_id into v_employees from groups where group_name = 'Employees';
    select group_id into v_customers from groups where group_name = 'Customers';
    select group_id into v_freelancers from groups where group_name = 'Freelancers';

    select menu_id
    into v_user_menu
    from im_menus
    where label='users';

    v_user_orgchart_menu := im_menu.new (
	package_name =>	'intranet-hr',
	name =>		'Org Chart',
	label =>	'users_org_chart',
	url =>		'/intranet-hr/org-chart?customer_id=0',
	sort_order =>	5,
	parent_menu_id => v_user_menu
    );

    acs_permission.grant_permission(v_user_orgchart_menu, v_admins, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_senman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_proman, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_accounting, 'read');
    acs_permission.grant_permission(v_user_orgchart_menu, v_employees, 'read');

end;
/
show errors;


------------------------------------------------------
-- HR Permissions
--

prompt *** Creating HR Profiles
begin
   im_create_profile ('HR Managers','profile');
end;
/
show errors;

prompt *** Creating Privileges
begin
    acs_privilege.create_privilege('view_hr','View HR','View HR');
end;
/

prompt Initializing HR Permissions
BEGIN
    im_priv_create('view_hr',	'HR Managers');
    im_priv_create('view_hr',	'P/O Admins');
    im_priv_create('view_hr',	'Senior Managers');
END;
/

commit;
