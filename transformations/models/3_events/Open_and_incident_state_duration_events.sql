with Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),
Assignment_group_times as (
	select * from {{ ref('Assignment_group_times') }}
),

Assigned_to_duration_times as (
	select * from {{ ref('Assigned_to_duration_times') }}
),

Open_and_incident_state_duration as (
	select 
		Incident_metric_input."Event_end", 
		Incident_metric_input."Case_ID", 
		Incident_metric_input."Mi_definition", 
		case-- Sets "Activity" as 'Open' for when "Mi_definition" is 'Open', but sets all other lines to retrieve the 'Activity' from the 'Mi_value' field.
			when Incident_metric_input."Mi_definition" = 'Open'
			then 'Open Incident'
			when Incident_metric_input."Mi_value" in ('Assigned', 'Work in Progress', 'Resolved', 'Pending')
			then concat('Change status to "', Incident_metric_input."Mi_value",'"')
			when Incident_metric_input."Mi_value" = 'Closed'
			then 'Close Incident'
		end as "Activity",
		case
			when Incident_metric_input."Mi_definition" = 'Open'
			then 'Open Incident'
			else Incident_metric_input."Mi_value" 
		end as "Activity_type"
	from Incident_metric_input
	where Incident_metric_input."Mi_definition" = 'Open'
		or Incident_metric_input."Mi_definition"  = 'Incident State Duration'
),

Open_and_incident_state_duration_events as (
	select
		Open_and_incident_state_duration."Event_end", 
		Open_and_incident_state_duration."Case_ID",
		Open_and_incident_state_duration."Mi_definition",
		Open_and_incident_state_duration."Activity",
		-- Sets the "User" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assigned to Duration'.
		Assigned_to_duration_times."Mi_value" as "User",
		-- Sets the "Team" based on the "Mi_value" from last previous line where "Mi_definition" is equal to 'Assignment Group'.
		Assignment_group_times."Mi_value" as "Team",
		case
			when Open_and_incident_state_duration."Activity" = 'Open Incident'
			then 1
			when Open_and_incident_state_duration."Activity" = 'Change status to "Assigned"'
			then 3
			when Open_and_incident_state_duration."Activity" = 'Change status to "Work in Progress"'
			then 6
			when Open_and_incident_state_duration."Activity" = 'Change status to "Resolved"'
			then 7
			when Open_and_incident_state_duration."Activity" = 'Close Incident'
			then 8
			-- The else means Open_and_incident_state_duration."Activity" = 'Pending', therefore Activity order is not applicable since pending can occur at anytime during the process.
			else null
		end as "Activity_order",
		Open_and_incident_state_duration."Activity_type"
	from Open_and_incident_state_duration
	-- Join to the table in which the previous and new values for Assigned to Duration was calculated based on the moment the activity occurred
	left join Assigned_to_duration_times 
		on Assigned_to_duration_times."Case_ID" = Open_and_incident_state_duration."Case_ID" 
		and Open_and_incident_state_duration."Event_end" between Assigned_to_duration_times."Next_start" 
		and Assigned_to_duration_times."Next_end"
	-- Join to the table in which the previous and new values for Assignment Group was calculated based on the moment the activity occurred
	left join Assignment_group_times 
		on Assignment_group_times."Case_ID" = Open_and_incident_state_duration."Case_ID" 
		and Open_and_incident_state_duration."Event_end" between Assignment_group_times."Next_start" 
		and Assignment_group_times."Next_end"
)

select * from Open_and_incident_state_duration_events
