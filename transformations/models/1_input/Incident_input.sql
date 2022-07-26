with Raw_incident as (
    select * from {{ source(var("schema_sources"), 'incident') }}
),

/*Contains data realated to each Incident Number.*/
Incident_input as (
    select
        Raw_incident."number" as "Case_ID",
        Raw_incident."assigned_to_display_value" as "Case_owner",
        Raw_incident."priority_display_value" as "Case_type",
        Raw_incident."caller_id_display_value" as "Customer",
        Raw_incident."assignment_group_display_value" as "Supplier",
        Raw_incident."cmdb_ci_display_value" as "Configuration_item",
        Raw_incident."close_code_display_value" as "Close_code",
        Raw_incident."state_display_value" as "Case_status",
        Raw_incident."contact_type_display_value" as "Contact_type",
        Raw_incident."category_display_value" as "Category",
        Raw_incident."upon_approval_display_value" as "Upon_approval",
        Raw_incident."upon_reject_display_value" as "Upon_reject",
        Raw_incident."urgency_display_value" as "Urgency",
        -- The folowing attribute will be used to get the last record for each incident number (Case_ID).
        row_number() over (partition by Raw_incident."number" order by Raw_incident."sys_updated_on" desc) as "Last_record",
        Raw_incident."sys_id" as "Sys_id"
    from  Raw_incident
)

select * from Incident_input
-- Only the last record for each incident number is taken from this table. This filter is necessary because some incident numbers may have multiple entries in this table.
where Incident_input."Last_record" = 1
