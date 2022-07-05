with Raw_task_sla as(
	select * from {{ source(var("schema_sources"), 'task_sla') }}
),

/*Contains data realated to SLA types and Due dates.*/
Task_sla_input as (
	select 
		Raw_task_sla."task_display_value" as "Case_ID",
		Raw_task_sla."sla_display_value" as "Due_date",
		{{ pm_utils.to_timestamp('Raw_task_sla."planned_end_time"') }} as  "Planned_end_time"
	from Raw_task_sla
	where Raw_task_sla."stage" = 'completed'
)

select * from Task_sla_input
