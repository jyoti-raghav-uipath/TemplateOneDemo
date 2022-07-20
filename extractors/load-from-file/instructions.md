# Instructions

See for instructions about the `load-from-file` extraction method the [UiPath documentation](https://docs.uipath.com/process-mining/v0/docs/extractors). 

## Configuration
Input files for this connector can be found in the `data.zip` in the sample_data folder. These are tab delimited .csv files. To load them using the `load-from-file` extraction method, make sure to extract the .zip and configure the source connection in CData Sync to point to the location of the files.

###  Load from File Data Import

In order to load CSV files into the data model, CData Sync will be used. 

**Source Connection**

|Step|Action                                                                                                                                                |
|:---|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
|1   |Define a New Connection of type CSV
|2   |Select *Property List*, *Auth Scheme* = *None* and enter the file path in the *URI* field.
|3   |Go to the Advanced tab, and define the additional settings.
|4   |Set FMT to TabDelimited to load in .csv files that are tab delimited.
|5   |Set Push Empty Values As Null to True.
|6   |Set Type Detection Scheme to None to make sure all data types are considered as string.
|7   |If you are planning to use DataBridgeAgent, make sure to append the Include Files with ,TSV.

**Destination Connection**

|Step|Action                                                                                                                                                |
|:---|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
|1   |Define a New Connection of type SQL Server or Snowflake.                                                                                              |
|2   |Setup connection details as required.   |

**Job Configuration**

|Step|Action                                                                                                                                                |
|:---|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
|1   |Create a new job using the Source and Destination connections. Name the job CSV_to_*Destination_Connection* where *Destination_Connection* is the type of database you will use.|
|2   |Click on Create to save the new Job|
|3   |Click on the job to enter configuration specifics|
|4   |Click on the *Advanced* tab |
|5   |Under *Destination Schema*, setup the target data schema in the SQL Server or Snowflake database |
|6   |Mark the *Drop Table* checkbox as *Active* |
|7   |Save all changes |

##### Set up Environment Variables

CData allows the use of environment variables in order to drive specific extraction logic in each query. 

|Variable             |Description                                         |Comment  |
|:-------             |:----------                                         |:------  |
|start_extraction_date|Defines first date for which data will be extracted.|Mandatory|
|end_extraction_date  |Last date for which data will be extracted.         |         |

Because the ServiceNow Incident Management connector uses the Incident Number as the main case ID, consideration should be made when choosing an extraction date, as it will be used across all objects.

In order to setup the environment variables:

|Step|Action                                                                                                                                                |
|:---|:-----------------------------------------------------------------------------------------------------------------------------------------------------|
|1   |Access the job created in the previous step.                                                                                                          |
|2   |Click on the *Events* tab.                                                                                                                            |
|3   |Add the following lines to the *Pre-Job Event* script by replacing `<!-- Code goes here-->` with the following code:                                  |

```
<!-- Modify variables here. Variable start_extraction_date must be populated. In case a specific end date is needed, replace now() with the required date in yyyy-MM-dd format  -->
<api:set attr="out.env:start_extraction_date"  value="1900-01-01" />
<api:set attr="out.env:end_extraction_date"  value="[null | now() | todate('yyyy-MM-dd')]" />
<api:push item="out" />
```

**Important**: Do not modify the `api:info` details that are shown by default and start_extraction_date and end_extraction_date should be optimized according to the content of the data for all .csv files.

In order to modify the environment variables, modify the values within the *Events* tab. By default, `end_extraction_date` will default to today's date. `start_extraction_date` must always be populated.

##### Table Replication

Once the job is correctly setup, click on *Add Custom Query* under the *Tables* tab and paste the following queries (*each query needs to maintain the semicolon at the end*):
```
	REPLICATE [metric_instance] SELECT [sys_id], [id], [sys_created_on], [value], [definition] FROM [metric_instance] WHERE ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
	REPLICATE [cmdb_ci] SELECT [name_display_value], [sys_class_name_display_value],[sys_updated_on] FROM [cmdb_ci] WHERE ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
	REPLICATE [contract_sla] SELECT [name_display_value], [duration] FROM [contract_sla] WHERE ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
	REPLICATE [task_sla] SELECT [sla_display_value], [task_display_value], [planned_end_time], [stage] FROM [task_sla] WHERE [stage] = 'completed' AND ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
	REPLICATE [metric_definition] SELECT [sys_id], [name], [table] FROM [metric_definition] WHERE [table] = 'incident' AND ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
	REPLICATE [incident] SELECT [sys_id], [sys_updated_on], [assigned_to_display_value], [assignment_group_display_value], [caller_id_display_value], [category_display_value], [close_code_display_value], [cmdb_ci_display_value], [contact_type_display_value], [priority_display_value], [number], [state_display_value], [upon_approval_display_value], [upon_reject_display_value], [urgency_display_value] FROM [incident] WHERE ([sys_created_on] >= '{env:start_extraction_date}') AND ([sys_created_on] <= '{env:end_extraction_date}');
```

Make sure you **save all changes**.
