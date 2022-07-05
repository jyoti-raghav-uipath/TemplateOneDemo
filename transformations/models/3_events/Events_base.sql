with Assigned_to_duration_events as (
	select * from {{ ref('Assigned_to_duration_events') }}
),
Assignment_group_events as (
	select * from {{ ref('Assignment_group_events') }}
),
Incident_pending_status_metrics_events as (
	select * from {{ ref('Incident_pending_status_metrics_events') }}
),
Open_and_incident_state_duration_events as (
	select * from {{ ref('Open_and_incident_state_duration_events') }}
),
Priority_change_events as (
	select * from {{ ref('Priority_change_events') }}
),
Events_union as (
	select
		Assigned_to_duration_events."Event_end",
		Assigned_to_duration_events."Case_ID",
		Assigned_to_duration_events."Mi_definition",
		Assigned_to_duration_events."Activity",
		Assigned_to_duration_events."User",
		Assigned_to_duration_events."Team",
		Assigned_to_duration_events."Activity_order",
		Assigned_to_duration_events."Activity_type"	
	from Assigned_to_duration_events
	union all
	select 
		Assignment_group_events."Event_end",
		Assignment_group_events."Case_ID",
		Assignment_group_events."Mi_definition",
		Assignment_group_events."Activity",
		Assignment_group_events."User",
		Assignment_group_events."Team",
		Assignment_group_events."Activity_order",
		Assignment_group_events."Activity_type"
	from Assignment_group_events
	union all
	select 
		Incident_pending_status_metrics_events."Event_end",
		Incident_pending_status_metrics_events."Case_ID",
		Incident_pending_status_metrics_events."Mi_definition",
		Incident_pending_status_metrics_events."Activity",
		Incident_pending_status_metrics_events."User",
		Incident_pending_status_metrics_events."Team",
		Incident_pending_status_metrics_events."Activity_order",
		Incident_pending_status_metrics_events."Activity_type"
	from Incident_pending_status_metrics_events
	union all
	select 
		Open_and_incident_state_duration_events."Event_end",
		Open_and_incident_state_duration_events."Case_ID",
		Open_and_incident_state_duration_events."Mi_definition",
		Open_and_incident_state_duration_events."Activity",
		Open_and_incident_state_duration_events."User",
		Open_and_incident_state_duration_events."Team",
		Open_and_incident_state_duration_events."Activity_order",
		Open_and_incident_state_duration_events."Activity_type"
	from Open_and_incident_state_duration_events
	union all
	select
		Priority_change_events."Event_end",
		Priority_change_events."Case_ID",
		Priority_change_events."Mi_definition",
		Priority_change_events."Activity",
		Priority_change_events."User",
		Priority_change_events."Team",
		Priority_change_events."Activity_order",
		Priority_change_events."Activity_type"
	from Priority_change_events
),
Events_base as (
	select
		Events_union."Event_end",
		Events_union."Case_ID",
		Events_union."Activity",
		case -- Sets the "user" field as 'System' for "activity" = 'Close Incident' or, in case the "user" field has no data, sets it as 'Unassigned username'.
			when Events_union."Activity" = 'Close Incident'
			--Automatic user.
			then 'System'
			when Events_union."User" is null 
				or Events_union."User" = ''
			then 'Unassigned username'
			else Events_union."User"
		end as "User",
		Events_union."Team",
		Events_union."Activity_type",
		Events_union."Activity_order"
	from Events_union
	where Events_union."Activity" is not null
)
select *,
   	row_number() over (order by Events_base."Event_end") as "Event_id"
from Events_base
