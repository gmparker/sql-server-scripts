
/*============================================================================
  File:     WhoIsActive (production).sql
 
  Summary:  Based on the very old sp_who, a much more detailed troubleshooting
  script used by many across the entire SQL Server community.
 
------------------------------------------------------------------------------
  Written by George M. Parker
 
  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you include this copyright and give due
  credit, but you must obtain prior permission before blogging this code.
   
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE. ALWAYS TEST IN A NON-PRODUCTION ENVIRONMENT BEFORE
  RUNNING IN A PRODUCTION ENVIRONMENT!
============================================================================*/

/****************************************************************************
Requires sp_whoisactive by Adam Machanic to be installed on the SQL Server:

https://github.com/amachanic/sp_whoisactive

There are a ton of parameters available but I almost always start with
just two: sorted by CPU (DESC) and sorted by DURATION (start_time) ASC. 
When there's an issue in production, the first two things I want to 
know are what's chewing up the most CPU and what's been running for the 
longest amount of time. I then tend to run Paul Randal's WaitingTasks script
for additional details on what SQL Server is waiting for.
****************************************************************************/

EXEC sp_whoisactive @sort_order = '[CPU] DESC', @get_outer_command = 1

EXEC sp_whoisactive @sort_order = '[start_time] ASC', @get_outer_command = 1


/***************************************************************************
Sorted by tempdb usage and physical reads
****************************************************************************/
EXEC sp_whoisactive @sort_order = '[tempdb_allocations] DESC', @get_outer_command = 1

EXEC sp_whoisactive @sort_order = '[physical_reads] DESC', @get_outer_command = 1


/***************************************************************************
Additional details on sp_whoisactivy by Adam Machanic:

https://github.com/amachanic/sp_whoisactive
****************************************************************************/

EXEC sp_whoisactive @help = 1

EXEC sp_whoisactive 
    @filter = '', 
    @filter_type = 'session', 
    @not_filter = '', 
    @not_filter_type = 'session', 
    @show_own_spid = 0, 
    @show_system_spids = 0, 
    @show_sleeping_spids = 1, 
    @get_full_inner_text = 0, 
    @get_plans = 0, 
    @get_outer_command = 0, 
    @get_transaction_info = 0, 
    @get_task_info = 1, 
    @get_locks = 0, 
    @get_avg_time = 0, 
    @get_additional_info = 0, 
    @find_block_leaders = 0, 
    @delta_interval = 0, 
    @output_column_list = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]', 
    @sort_order = '[start_time] ASC', 
    @format_output = 1, 
    @destination_table = '', 
    @return_schema = 0, 
    @schema = NULL, 
    @help = 0


