with Incident_input as (
	select * from {{ ref('Incident_input') }}
),

Metric_definition_input as (
	select * from {{ ref('Metric_definition_input') }}
),

Metric_instance_input as (
	select * from {{ ref('Metric_instance_input') }}
),

Incident_metric_input as (
	select 
		Incident_input."Case_ID" as "Case_ID",
		Metric_definition_input."Name" as "Mi_definition",
		nullif(Metric_instance_input."Value", '') as "Mi_value",
		Metric_instance_input."Sys_created_on" as "Event_end"
	from Incident_input
	inner join Metric_instance_input
		on Metric_instance_input."Id" = Incident_input."Sys_id" 
	inner join Metric_definition_input
		on Metric_instance_input."Definition" = Metric_definition_input."Sys_id" 
	where Metric_definition_input."Name"
		in ('Open',
			'Incident State Duration',
			'Assignment Group',
			'Assigned to Duration',
			'Incident Pending Status Metrics',
			'Priority Change'
		)
)

select * from Incident_metric_input










