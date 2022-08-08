with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),

Assigned_to_duration_times as (
	select * from {{ ref('Assigned_to_duration_times') }}
),

Incident_metric_first_assignment as (
	select 
		row_number() over(
			partition by Incident_metric_input."Case_ID", Incident_metric_input."Mi_definition"
			order by Incident_metric_input."Event_end" asc)
		as "First_assignment_group_t_updated",
		Incident_metric_input."Event_end", 
		Incident_metric_input."Case_ID", 
		Incident_metric_input."Mi_definition",
		Incident_metric_input."Mi_value"
	from Incident_metric_input
),

Assignment_group_events as (
	select -- Adds lines where "mi_definition" are equal 'Assignment Group' 
		Incident_metric_first_assignment."Event_end", 
		Incident_metric_first_assignment."Case_ID", 
		Incident_metric_first_assignment."Mi_definition", 
		case
			when Incident_metric_first_assignment."First_assignment_group_t_updated" = 1
			then 'Assign First Assignment Group'
			else 'Change Assignment Group'
		end as "Activity",
		case -- Sets the "User" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assigned to Duration'. In case it is the first assignment, the user is set as 'System'. 
			when Incident_metric_first_assignment."First_assignment_group_t_updated" = 1
			then 'System'
			else Assigned_to_duration_times."Mi_value"
		end as "User",
		Incident_metric_first_assignment."Mi_value" as "Team",
		2 as "Activity_order",
		'Change Assignment Group' as "Activity_type"
	from Incident_metric_first_assignment
	-- Join to the table in which the previous and new values for Assigned to Duration was calculated based on the moment the activity occurred
	left join Assigned_to_duration_times 
		on Assigned_to_duration_times."Case_ID" = Incident_metric_first_assignment."Case_ID" 
		and Incident_metric_first_assignment."Event_end" between Assigned_to_duration_times."Next_start" 
		and Assigned_to_duration_times."Next_end"
	where Incident_metric_first_assignment."Mi_definition"  = 'Assignment Group'
)

select * from Assignment_group_events
