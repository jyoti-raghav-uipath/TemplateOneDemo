with Raw_cmdb_ci as (
	select * from {{ source(var("schema_sources"), 'cmdb_ci') }}
),

/*Contains the description for Configuration_items in the the Configuration Management Database.*/
Cmdb_ci_input as(
	select 
		Raw_cmdb_ci."name_display_value" as "Configuration_item", 
		Raw_cmdb_ci."sys_class_name_display_value" as "Class_name",
		row_number() over (partition by Raw_cmdb_ci."name_display_value" order by Raw_cmdb_ci."sys_updated_on" desc) as "Last_line"
	from Raw_cmdb_ci
)

select * from Cmdb_ci_input
where Cmdb_ci_input."Last_line" = 1
