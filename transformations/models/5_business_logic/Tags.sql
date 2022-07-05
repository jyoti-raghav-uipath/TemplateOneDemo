with Events_base as (
	select * from {{ ref('Events_base') }}
),

Assigned_count as (
	select
		Events_base."Case_ID",
		count(Events_base."Activity") as "Count_activity"
	from Events_base
	where Events_base."Activity" = 'Change status to "Assigned"'
	group by Events_base."Case_ID"
),

Resolved_activity as (
	select
		Events_base."Case_ID",
		Events_base."Event_end"
	from Events_base
	where Events_base."Activity" = 'Change status to "Resolved"'
),

Pending_assigned_activity as (
	select
		Events_base."Case_ID",
		Events_base."Event_end"
	from Events_base
	where Events_base."Activity" = 'Change status to "Pending"'
		or Events_base."Activity" = 'Change status to "Assigned"'
),

Reopen_cases as (
	select
		Pending_assigned_activity."Case_ID"
	from Resolved_activity
	left join Pending_assigned_activity
		on Pending_assigned_activity."Case_ID" = Resolved_activity."Case_ID"
	where Pending_assigned_activity."Case_ID" is not null
		and Pending_assigned_activity."Event_end" > Resolved_activity."Event_end"
	group by Pending_assigned_activity."Case_ID"
),

Tags as (
	-- Reopen - Tagged when a 'Pending' or 'Assigned' happen after a 'Resolved' activity.
	select
		Reopen_cases."Case_ID",
		'Reopen' as "Tag"
	from Reopen_cases
	union all
	-- Created without Assignment Group - Tagged when a 'Open' activity has no team (Assignment Group).
	select
		Events_base."Case_ID",
		'Created without Assignment Group' as "Tag"
	from Events_base
	where Events_base."Activity" = 'Open Incident'
		and Events_base."Team" is null
	group by Events_base."Case_ID"
	union all
	-- Multiple assignments - Cases where the Activity 'Assigned' appear more than once.
	select 
		Assigned_count."Case_ID",
		'Multiple assignments' as "Tag"
	from Assigned_count
	where Assigned_count."Count_activity" > 1
	union all
	-- Assignment Group change - Cases where the Activity 'Assignment Group change' appear.
	select 
		Events_base."Case_ID",
		'Assignment Group Change' as "Tag"
	from Events_base
	where Events_base."Activity" = 'Change Assignment Group'
	group by Events_base."Case_ID"
	union all
	-- Priority Changes - Cases where the Activity 'Priority Change to (Level number)' appear.
	select 
		Events_base."Case_ID",
		'Priority Changes' as "Tag"
	from Events_base
	where Events_base."Activity" like 'Change Priority to %'
	group by Events_base."Case_ID"
)

select * from Tags
