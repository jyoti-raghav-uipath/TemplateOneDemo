with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),

Assignment_group_times as (
	select * from {{ ref('Assignment_group_times') }}
),

Assigned_to_duration_times as (
	select * from {{ ref('Assigned_to_duration_times') }}
),

Priority_change as (
	select 
		Incident_metric_input."Event_end", 
		Incident_metric_input."Case_ID", 
		Incident_metric_input."Mi_definition", 
		concat('Change Priority to',right(Incident_metric_input."Mi_value", 2)) as "Activity"
	from Incident_metric_input
	where Incident_metric_input."Mi_definition" = 'Priority Change'
),

Priority_change_events as (
	select
		Priority_change."Event_end", 
		Priority_change."Case_ID",
		Priority_change."Mi_definition", 
		Priority_change."Activity" as "Activity", 
		-- Sets the "User" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assigned to Duration'.
		Assigned_to_duration_times."Mi_value" as "User",
		-- Sets the "Team" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assignment Group'.
		Assignment_group_times."Mi_value" as "Team",
		5 as "Activity_order",
		'Priority Change' as "Activity_type"
	from Priority_change
	-- Join to the table in which the previous and new values for Assigned to Duration was calculated based on the moment the activity occurred
	left join Assigned_to_duration_times 
		on Assigned_to_duration_times."Case_ID" = Priority_change."Case_ID" 
		and Priority_change."Event_end" between Assigned_to_duration_times."Next_start" 
		and Assigned_to_duration_times."Next_end"
	-- Join to the table in which the previous and new values for Assignment Group was calculated based on the moment the activity occurred
	left join Assignment_group_times 
		on Assignment_group_times."Case_ID" = Priority_change."Case_ID" 
		and Priority_change."Event_end" between Assignment_group_times."Next_start" 
		and Assignment_group_times."Next_end"
)

select * from Priority_change_events
