with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),

Assignment_group_times as (
select * from {{ ref('Assignment_group_times') }}
),

Assignment_duration as (
select
	Incident_metric_input."Case_ID",
	Incident_metric_input."Event_end",
	Incident_metric_input."Mi_value",
	Incident_metric_input."Mi_definition"
from Incident_metric_input
where Incident_metric_input."Mi_definition" = 'Assigned to Duration'
),

Assigned_to_duration_events AS (
	select
		Assignment_duration."Event_end",
		Assignment_duration."Case_ID",
		Assignment_duration."Mi_definition",
		-- Splits the 'Assign User' activity to identify changes to the assigned user. Sometimes there could be a field "Mi_definition" = 'Assined to duration' record with a NULL "Mi_value". This would mean that no users were assigned in an 'Assign User' activity, so the 'To Be Assigned' activity is created for those situations.
		case 
			when Assignment_duration."Mi_value" is null
			then 'To be Assigned'
			else 'Assign User'
		end as "Activity",
		-- Sets the "User" based on the "Mi_value" from last previous record where "Mi_definition" is equal to 'Assigned to Duration'. 
		Assignment_duration."Mi_value" as "User",
		-- Sets the "Team" based on the "Mi_value" from last previous record where "Mi_definition" is equal to 'Assignment Group'. 
		Assignment_group_times."Mi_value" as "Team",
		4 as "Activity_order",
		'User Assignation' as "Activity_type"
	from Assignment_duration
	-- Join to the table in which the previous and new values for Assignment Group was calculated based on the moment the activity occurred
	left join Assignment_group_times 
		on Assignment_group_times."Case_ID" = Assignment_duration."Case_ID" 
		and Assignment_duration."Event_end" between Assignment_group_times."Next_start" 
		and Assignment_group_times."Next_end"
)

select * from Assigned_to_duration_events
