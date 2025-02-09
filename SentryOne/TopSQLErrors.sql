/*============================================================================
  File:     TopSQLErrors.sql
 
  Summary:  SentryOne Top SQL Errors by Count
 
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

/* Note: This can cause blocking so it includes wITH(NOLOCK) hints */

DECLARE @sproc VARCHAR(255), @duration int
SELECT @sproc = 'INSERT SPROC NAME HERE'
SELECT @duration = -60

SELECT esc.ObjectName as ServerName,
		patd.DatabaseName,
		patd.ObjectName as ObjectName,
		 COUNT(*) AS [Count]
FROM SQLSentry.[dbo].[PerformanceAnalysisTraceData] patd WITH(NOLOCK)
JOIN EventSourceConnection esc WITH(NOLOCK)
	ON patd.EventSourceConnectionID = esc.ID
WHERE  patd.ObjectName IS NOT NULL
AND patd.Error >= 2
AND patd.NormalizedStartTime > dateadd(minute, @duration , getutcdate()) -- The amount of time to look backwards
AND patd.ObjectName NOT IN (@sproc)  -- Comment out to return ALL stored procedures
GROUP BY esc.ObjectName, patd.ObjectName, patd.DatabaseName
HAVING COUNT(*) >= 5
ORDER BY esc.ObjectName, patd.DatabaseName, patd.ObjectName

