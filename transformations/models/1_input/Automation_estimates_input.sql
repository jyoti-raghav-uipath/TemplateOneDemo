with Raw_event_processing_estimates as (
    select * from {{ref('Automation_estimates')}}
),

Automation_estimates_input as (
    select 
        -- Primary Key
        {{pm_utils.to_varchar('Raw_event_processing_estimates."Activity"')}} as "Activity",
        {{pm_utils.to_double('Raw_event_processing_estimates."Event_cost"')}} as "Event_cost",
        {{pm_utils.to_integer('Raw_event_processing_estimates."Event_processing_time"')}} as "Event_processing_time"
    from Raw_event_processing_estimates
)

select * from Automation_estimates_input
