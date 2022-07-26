with Incident_metric_input as (
    select * from {{ ref('Incident_metric_input') }}
),
-- Create a table filtering on Assignment Group changes ordered by the moment in which they occurred. This will be used as the "previous" value before the Assignment Group is changed.
Assignment_group_previous as (
    select
        Incident_metric_input."Case_ID",
        Incident_metric_input."Event_end",
        Incident_metric_input."Mi_value",
        row_number() over(partition by Incident_metric_input."Case_ID" order by Incident_metric_input."Event_end" asc) as "rn"
    from Incident_metric_input
    where Incident_metric_input."Mi_definition" = 'Assignment Group'
),
-- Create a table filtering on Assignment Group changes ordered by the moment in which they occurred. This will be used as the value after the Assignment Group is changed.
Assignment_group_next as (
    select
        Incident_metric_input."Case_ID",
        Incident_metric_input."Event_end",
        Incident_metric_input."Mi_value",
        row_number() over(partition by Incident_metric_input."Case_ID" order by Incident_metric_input."Event_end" asc) as "rn"
    from Incident_metric_input
    where Incident_metric_input."Mi_definition" = 'Assignment Group'
),
-- Join both tables, showing the previous and new values for the Assignment group, and at what time they occurred.
Assignment_group_times as (
    select
        Assignment_group_previous."Case_ID",
        Assignment_group_previous."Event_end" as "Next_start",
        case 
            when Assignment_group_next."Event_end" is null
            then {{pm_utils.to_timestamp(var("max_datetime"))}}
            else dateadd(second, -1, Assignment_group_next."Event_end") 
        end as "Next_end",
        Assignment_group_previous."Mi_value"
    from Assignment_group_previous
    left join Assignment_group_next 
        on Assignment_group_previous."Case_ID" = Assignment_group_next."Case_ID" 
        and Assignment_group_previous."rn" = (Assignment_group_next."rn" - 1)
)
select * from Assignment_group_times
