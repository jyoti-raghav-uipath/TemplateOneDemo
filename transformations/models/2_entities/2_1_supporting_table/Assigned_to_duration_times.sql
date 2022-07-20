with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),
-- Create a table filtering on Assigned to Duration changes ordered by the moment in which they occurred. This will be used as the "previous" value before the Assigned to Duration is changed.
Assigned_to_duration_previous as (
	select
		Incident_metric_input."Case_ID",
		Incident_metric_input."Event_end",
		Incident_metric_input."Mi_value",
		Incident_metric_input."Mi_definition",
		row_number() over(partition by Incident_metric_input."Case_ID" order by Incident_metric_input."Event_end" asc) as "rn"
	from Incident_metric_input
	where Incident_metric_input."Mi_definition" = 'Assigned to Duration'
),
-- Create a table filtering on Assigned to Duration changes ordered by the moment in which they occurred. This will be used as the value after the Assigned to Duration is changed.
Assigned_to_duration_next as (
	select
		Incident_metric_input."Case_ID",
		Incident_metric_input."Event_end",
		Incident_metric_input."Mi_value",
		Incident_metric_input."Mi_definition",
		row_number() over(partition by Incident_metric_input."Case_ID" order by Incident_metric_input."Event_end" asc) as "rn"
	from Incident_metric_input
	where Incident_metric_input."Mi_definition" = 'Assigned to Duration'
),
-- Join both tables, showing the previous and new values for the Assigned to Duration, and at what time they occurred.
Assigned_to_duration_times as (
	select
		Assigned_to_duration_previous."Case_ID",
		Assigned_to_duration_previous."Event_end" as "Next_start",
		case 
			when Assigned_to_duration_next."Event_end" is null
			then {{pm_utils.to_timestamp(var("max_datetime"))}}
			else dateadd(second, -1, Assigned_to_duration_next."Event_end") 
		end as "Next_end",
		Assigned_to_duration_previous."Mi_value"
	from Assigned_to_duration_previous
	left join Assigned_to_duration_next 
		on Assigned_to_duration_previous."Case_ID" = Assigned_to_duration_next."Case_ID" 
		and Assigned_to_duration_previous."rn" = (Assigned_to_duration_next."rn" - 1)
)

select * from Assigned_to_duration_times
