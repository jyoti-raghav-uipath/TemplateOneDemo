with Incident_input as (
	select * from {{ ref('Incident_input') }}
),

Cmdb_ci_input as (
	select * from {{ ref('Cmdb_ci_input') }}
),

Incident_metric_input as (
	select * from {{ ref('Incident_metric_input') }}
),

--This subset is used to guarantee that all Case IDs added to the Case_base will have at least one record on Incident_metric
Ticketid_list as (
	select 
		Incident_metric_input."Case_ID"
	from Incident_metric_input
	group by Incident_metric_input."Case_ID"
),

Incidents as(
	select  
		Incident_input."Case_ID",
		Incident_input."Case_owner",
		Incident_input."Case_type",
		Incident_input."Customer",
		Incident_input."Supplier",
		Incident_input."Configuration_item",
		Incident_input."Close_code",
		Incident_input."Case_status",
		Incident_input."Contact_type",
		Incident_input."Category",
		Incident_input."Upon_approval",
		Incident_input."Upon_reject",
		Incident_input."Urgency",
		Cmdb_ci_input."Class_name"
	from Incident_input
	-- Join the Configuration Management table to retrive master data.
	left outer join Cmdb_ci_input
		on Incident_input."Configuration_item" = Cmdb_ci_input."Configuration_item"
	-- This join and the where are filtering the Case IDs without any activities that are being created based on Metric_definition_input."Name"
	left join Ticketid_list 
		on Incident_input."Case_ID" = Ticketid_list."Case_ID"
	where Ticketid_list."Case_ID" is not null
)

select * from Incidents
