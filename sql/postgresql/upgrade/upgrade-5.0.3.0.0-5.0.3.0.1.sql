-- upgrade-5.0.3.0.0-5.0.3.0.1.sql

SELECT acs_log__debug('/packages/intranet-hr/sql/postgresql/upgrade/upgrade-5.0.3.0.0-5.0.3.0.1.sql','');


update im_component_plugins
set component_tcl = 'im_employee_info_component $user_id_from_search $return_url [im_opt_val -limit_to nohtml employee_view_name]'
where plugin_name = 'User Employee Component';
