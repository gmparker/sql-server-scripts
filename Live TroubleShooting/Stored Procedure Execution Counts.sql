/*============================================================================
  File:     Stored Procedure Execution Counts.sql
 
  Summary:  Returns counts by stored procedure detailing what is currently being
  executed. Can be used to determine potential query plan issues causing stored 
  procedures to run longer than normal.
 
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
	db_name(est.dbid) as db,
	OBJECT_SCHEMA_NAME(est.objectid, est.dbid) as sch,
	object_name(est.objectid, est.dbid) as obj,
	USER_NAME(USER_ID) as UserName,
	COUNT(*) as Cnt
FROM sys.dm_exec_sessions es
INNER JOIN sys.dm_exec_requests [er] ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE
    [es].[is_user_process] = 1
	AND object_name(est.objectid, est.dbid) is not null
GROUP BY 
db_name(est.dbid),
OBJECT_SCHEMA_NAME(est.objectid, est.dbid), 
object_name(est.objectid, est.dbid),
USER_NAME(USER_ID)
ORDER BY
    Cnt DESC
GO
