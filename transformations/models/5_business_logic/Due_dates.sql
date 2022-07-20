with Task_sla_input as (
	select * from {{ ref('Task_sla_input') }}
),

Events_base as (
	select * from {{ ref('Events_base') }}
),

-- Contains the duration (in seconds) for each sla type.
Contract_sla_input as ( 
	select * from {{ ref('Contract_sla_input') }}
),

/*Only "Activity" = 'Resolved' records are used to identify due dates.*/
Resolved_events as ( 
	select 
		max(Events_base."Event_end") over (partition by Events_base."Case_ID") as "Actual_date",
		Events_base."Event_id",
		Events_base."Case_ID"
	from Events_base
	where Events_base."Activity" = 'Change status to "Resolved"'
),

Sla_duration as (
	select
		Task_sla_input."Case_ID",
		Task_sla_input."Due_date",
		/*The function bellow is used to obtain the date and time when a SLA Category was assigned to the incident number (Case_ID).*/
		dateadd(second,-Contract_sla_input."Duration",Task_sla_input."Planned_end_time") as "Date_of_assign_sla",
		Task_sla_input."Planned_end_time" as "Expected_date"
	from Task_sla_input
	left join Contract_sla_input on Contract_sla_input."Due_date" = Task_sla_input."Due_date"
),

/*Identify the last due date type defined for each case id.*/
Last_sla as (
	select
		Sla_duration."Case_ID",
		/*The Last_due_date will organize and filter records, so the only record for each case id will be the last defined sla.*/
		max(Sla_duration."Date_of_assign_sla") as "Last_due_date"
	from Sla_duration
	group by Sla_duration."Case_ID"
),

/*Retrieves the due date types.*/
Sla_due_date as (
	select
		Sla_duration."Case_ID",
		Sla_duration."Due_date",
		Sla_duration."Expected_date"
	from Sla_duration
	left join Last_sla
		on Sla_duration."Case_ID" = Last_sla."Case_ID"
			/*This comparison is necessary so the only records selected are those from the Last_sla, obtaining only the record related to the last SLA category assigned to a Case_ID.*/
			and Last_sla."Last_due_date" = Sla_duration."Date_of_assign_sla"
	where Last_sla."Last_due_date" is not null
	group by Sla_duration."Case_ID", Sla_duration."Due_date", Sla_duration."Expected_date",Last_sla."Last_due_date"
),

/*Joins the SLA data to the Resolved_events data to retrieve the Actual_date and Event_ID*/
Due_dates as (
	select
		Sla_due_date."Due_date",
		Sla_due_date."Expected_date",
		Resolved_events."Actual_date",
		{{pm_utils.to_varchar('Resolved_events."Event_id"')}} as "Event_ID"
	from Resolved_events
	inner join Sla_due_date on Resolved_events."Case_ID" = Sla_due_date."Case_ID"
)

select * from Due_dates
