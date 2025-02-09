
/*============================================================================
  File:     SOS Scheduler Yields.sql
 
  Summary:  Tasks wiating for SOS Scheduler Yields
 
  SQL Server Versions: 2005 onward
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com
 
  (c) 2019, SQLskills.com. All rights reserved.
 
  For more scripts and sample code, check out 
    http://www.SQLskills.com
 
  You may alter this code for your own *non-commercial* purposes. You may
  republish altered code as long as you include this copyright and give due
  credit, but you must obtain prior permission before blogging this code.
   
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

SELECT
--*******************************************************************************************************
-- Added by George M Parker to Paul Randal's Original Script
-- https://www.sqlskills.com/blogs/paul/identifying-queries-with-sos_scheduler_yield-waits/
    object_name(est.objectid, er.database_id) as Obj,
    SUBSTRING(est.text, (er.statement_start_offset/2)+1,   
        ((CASE er.statement_end_offset  
          WHEN -1 THEN DATALENGTH(est.text)  
         ELSE er.statement_end_offset  
         END - er.statement_start_offset)/2) + 1) AS statement_text,
--*******************************************************************************************************
    [er].[session_id],
    [es].[program_name],
    [est].text,
    [er].[database_id],
    [eqp].[query_plan],
    [er].[cpu_time]
FROM sys.dm_exec_requests [er]
INNER JOIN sys.dm_exec_sessions [es] ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE
    [es].[is_user_process] = 1
    AND [er].[last_Wait_type] = N'SOS_SCHEDULER_YIELD'
ORDER BY
    [er].[session_id];
GO