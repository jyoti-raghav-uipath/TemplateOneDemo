with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),

Assignment_group_times as (
	select * from {{ ref('Assignment_group_times') }}
),

Assigned_to_duration_times as (
	select * from {{ ref('Assigned_to_duration_times') }}
),

Incident_metric_pending_status as (
	select 
		Incident_metric_input."Event_end", 
		Incident_metric_input."Case_ID", 
		Incident_metric_input."Mi_definition", 
		-- Splits the 'Pending' status for more details.
		concat('Add Pending reason "', Incident_metric_input."Mi_value",'"') as "Activity"
	from Incident_metric_input
	where Incident_metric_input."Mi_definition"  = 'Incident Pending Status Metrics' 
),

Incident_pending_status_metrics_events as (
	select
		Incident_metric_pending_status."Event_end", 
		Incident_metric_pending_status."Case_ID",
		Incident_metric_pending_status."Mi_definition",
		Incident_metric_pending_status."Activity",
		-- Sets the "User" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assigned to Duration'.
		Assigned_to_duration_times."Mi_value" as "User", 
		-- Sets the "Team" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assignment Group'.
		Assignment_group_times."Mi_value" as "Team", 
		--Since pending can occur at anytime during the process, the activity order is not applicable.
		null as "Activity_order",
		'Pending' as "Activity_type"
	from Incident_metric_pending_status
	-- Join to the table in which the previous and new values for Assigned to Duration was calculated based on the moment the activity occurred
	left join Assigned_to_duration_times 
		on Assigned_to_duration_times."Case_ID" = Incident_metric_pending_status."Case_ID" 
		and Incident_metric_pending_status."Event_end" between Assigned_to_duration_times."Next_start" 
		and Assigned_to_duration_times."Next_end"
	-- Join to the table in which the previous and new values for Assignment Group was calculated based on the moment the activity occurred
	left join Assignment_group_times 
		on Assignment_group_times."Case_ID" = Incident_metric_pending_status."Case_ID" 
		and Incident_metric_pending_status."Event_end" between Assignment_group_times."Next_start" 
		and Assignment_group_times."Next_end"
)

select * from Incident_pending_status_metrics_events

