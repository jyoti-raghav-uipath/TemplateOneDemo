with Events_base as (
	select * from {{ ref('Events_base') }}
),

Automation_estimates as (
	select * from {{ ref('Automation_estimates_input') }}
),

Event_log_base as (
	select
		Events_base."Event_end",
		{{pm_utils.to_varchar('Events_base."Event_id"')}} as "Event_ID",
		Events_base."Case_ID",
		Events_base."Activity",
		Events_base."User",
		Events_base."Team",
		Events_base."Activity_type",
		case
			when Events_base."User" = 'System'
			then 1
			else 0
		end as "Automated",
		Events_base."Activity_order",
		Automation_estimates."Event_cost",
		Automation_estimates."Event_processing_time",
		{{pm_utils.to_timestamp('null')}} as "Event_start",
		{{pm_utils.to_varchar('null')}} as "Event_detail"
	from Events_base
	left join Automation_estimates
		on Automation_estimates."Activity" = Events_base."Activity"
)

select * from Event_log_base
