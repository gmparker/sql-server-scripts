/*============================================================================
  File:     Statement Execution Counts.sql
 
  Summary:  Returns counts by statement detailing what is currently being executed.
  Can be used to determine potential query plan issues causing statements
  to run longer than normal.
 
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


SELECT
	db_name(est.dbid) as db, object_name(est.objectid, est.dbid) as obj,
	SUBSTRING(est.text, (er.statement_start_offset/2)+1,   
        ((CASE er.statement_end_offset  
          WHEN -1 THEN DATALENGTH(est.text)  
         ELSE er.statement_end_offset  
         END - er.statement_start_offset)/2) + 1) AS statement_text,
wait_type, REPLACE(wait_resource,':', ','),
	COUNT(*) as Cnt
FROM sys.dm_exec_sessions es
INNER JOIN sys.dm_exec_requests [er] ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE
    [es].[is_user_process] = 1
	AND object_name(est.objectid, est.dbid) is not null
	--AND wait_Type = 'PAGEIOLATCH_SH'
	AND SUBSTRING(est.text, (er.statement_start_offset/2)+1,   
        ((CASE er.statement_end_offset  
          WHEN -1 THEN DATALENGTH(est.text)  
         ELSE er.statement_end_offset  
         END - er.statement_start_offset)/2) + 1) --LIKE '%%'
GROUP BY 
db_name(est.dbid),object_name(est.objectid, est.dbid),
SUBSTRING(est.text, (er.statement_start_offset/2)+1,   
        ((CASE er.statement_end_offset  
          WHEN -1 THEN DATALENGTH(est.text)  
         ELSE er.statement_end_offset  
         END - er.statement_start_offset)/2) + 1),
wait_type, wait_resource
ORDER BY Cnt DESC
GO