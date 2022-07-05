with Raw_contract_sla as (
	select * from {{ source(var("schema_sources"), 'contract_sla') }}
),

/*Contains data related SLA and due dates.*/
Contract_sla_input as(
	select 
		Raw_contract_sla."name_display_value" as "Due_date", 
		{{pm_utils.to_integer('Raw_contract_sla."duration"')}} as "Duration" 
	from Raw_contract_sla
)

select * from Contract_sla_input
