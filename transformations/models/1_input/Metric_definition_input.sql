with Raw_metric_definition as (
	select * from {{ source(var("schema_sources"), 'metric_definition') }}
),

/*Contains the description for Configuration Items in the the Configuration Management Database.*/
Metric_definition_input as(
	select 
		Raw_metric_definition."sys_id" as "Sys_id", 
		Raw_metric_definition."name" as "Name"
	from Raw_metric_definition
	where Raw_metric_definition."table" = 'incident'
)

select * from Metric_definition_input
