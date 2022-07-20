with Incidents as (
	select * from {{ ref('Incidents') }}
),

Cases_base as (
	select 
		Incidents."Case_ID",
		concat('Incident Number: ', replace(Incidents."Case_ID",'INC','')) as "Case",
		Incidents."Case_owner",
		Incidents."Case_type",
		Incidents."Case_status",
		Incidents."Customer",
		Incidents."Supplier",
		Incidents."Contact_type",
		Incidents."Configuration_item",
		Incidents."Close_code",
		Incidents."Category",
		Incidents."Urgency",
		Incidents."Upon_reject",
		Incidents."Upon_approval",
		Incidents."Class_name",
		{{pm_utils.to_double('null')}} as "Case_value"
	from Incidents
)

select * from Cases_base
