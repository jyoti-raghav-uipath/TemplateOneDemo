with Raw_metric_instance as (
	select * from {{ source(var("schema_sources"), 'metric_instance') }}
),

/*Contains the description for Configuration Items in the the Configuration Management Database.*/
Metric_instance_input as(
	select 
		Raw_metric_instance."sys_id" as "Sys_id",
		Raw_metric_instance."definition" as "Definition",
		Raw_metric_instance."id" as "Id",
		{{ pm_utils.to_timestamp('Raw_metric_instance."sys_created_on"')}}  as "Sys_created_on",
		Raw_metric_instance."value" as "Value"
	from Raw_metric_instance
)

select * from Metric_instance_input
