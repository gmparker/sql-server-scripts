/*============================================================================
  File:     query plan cache.sql
 
  Summary:  Returns detailed information about the plan for a specifc SPROC
  as well as the statistics used by that SPROC
 
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


-- USE AdventureWorks
-- GO

IF OBJECT_ID('tempdb..#temp') IS NOT NULL    
    DROP TABLE #temp 

declare @procname sysname
select @procname = 'Sel_AllEmployees'

-- When did the stored procedure last compile
select object_name(object_id, database_id), * 
from sys.dm_exec_procedure_stats
where object_name(object_id, database_id) = @procname
--where object_name(object_id, database_id) in
--(
--'INSERT STORED SPROC NAME 1 HERE',
--'INSERT STORED SPROC NAME 2 HERE'
--)
order by 1


-- When did the statements in the stored procedure last compile
select top 500  
	SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS statement_text,

object_name(st.objectid, st.dbid) as Obj,
creation_time as CT,
    GETDATE() AS 'Collection Date',
    qs.execution_count AS 'Execution Count',
    SUBSTRING(st.text,qs.statement_start_offset/2 +1, 
                 (CASE WHEN qs.statement_end_offset = -1 
                       THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 
                       ELSE qs.statement_end_offset END -
                            qs.statement_start_offset
                 )/2
             ) AS 'Query Text', 
     DB_NAME(st.dbid) AS 'DB Name',
     qs.total_worker_time AS 'Total CPU Time',
     qs.total_worker_time/qs.execution_count AS 'Avg CPU Time (ms)',     
     qs.total_physical_reads AS 'Total Physical Reads',
     qs.total_physical_reads/qs.execution_count AS 'Avg Physical Reads',
     qs.total_logical_reads AS 'Total Logical Reads',
     qs.total_logical_reads/qs.execution_count AS 'Avg Logical Reads',
     qs.total_logical_writes AS 'Total Logical Writes',
     qs.total_logical_writes/qs.execution_count AS 'Avg Logical Writes',
     qs.total_elapsed_time AS 'Total Duration',
     qs.total_elapsed_time/qs.execution_count AS 'Avg Duration (ms)',
     qp.query_plan AS 'Plan', *
from sys.dm_exec_query_stats qs 
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
where st.objectid is not null and st.dbid <> 32767
and object_name(st.objectid, st.dbid) = @procname
--and object_name(st.objectid, st.dbid) IN
--(
--'Sel_EventRecorderFilesOnDeviceWithoutRequest_byER',
--'Del_EventRecorderFilesOnDeviceByTriggerTypeId'
--)
order by creation_time desc



-- Break down the query plan to look for SCANS
;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
CachedPlans
(DatabaseName,SchemaName,ObjectName,ParentOperationID,OperationID, PhysicalOperator, LogicalOperator, QueryText,QueryPlan, CacheObjectType, ObjectType)
AS
(
SELECT
Coalesce(RelOp.op.value(N'TableScan[1]/Object[1]/@Database', N'varchar(50)') , 
RelOp.op.value(N'OutputList[1]/ColumnReference[1]/@Database', N'varchar(50)') ,
RelOp.op.value(N'IndexScan[1]/Object[1]/@Database', N'varchar(50)') ,
'Unknown'
)
as DatabaseName,
Coalesce(
RelOp.op.value(N'TableScan[1]/Object[1]/@Schema', N'varchar(50)') ,
RelOp.op.value(N'OutputList[1]/ColumnReference[1]/@Schema', N'varchar(50)') ,
RelOp.op.value(N'IndexScan[1]/Object[1]/@Schema', N'varchar(50)') ,
'Unknown'
)
as SchemaName,
Coalesce(
RelOp.op.value(N'TableScan[1]/Object[1]/@Table', N'varchar(50)') ,
RelOp.op.value(N'OutputList[1]/ColumnReference[1]/@Table', N'varchar(50)') ,
RelOp.op.value(N'IndexScan[1]/Object[1]/@Table', N'varchar(50)') ,
'Unknown'
)
as ObjectName,
RelOp.op.value(N'../../@NodeId', N'int') AS ParentOperationID,
RelOp.op.value(N'@NodeId', N'int') AS OperationID,
RelOp.op.value(N'@PhysicalOp', N'varchar(50)') as PhysicalOperator,
RelOp.op.value(N'@LogicalOp', N'varchar(50)') as LogicalOperator,

st.text as QueryText,
qp.query_plan as QueryPlan,
cp.cacheobjtype as CacheObjectType,
cp.objtype as ObjectType
FROM
sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY qp.query_plan.nodes(N'//RelOp') RelOp (op)
WHERE object_name(st.objectid, st.dbid) = @procname
)
SELECT
DatabaseName,SchemaName,ObjectName,ParentOperationID,OperationID, PhysicalOperator
, LogicalOperator, QueryText,CacheObjectType, ObjectType, queryplan
INTO #temp
FROM
CachedPlans
WHERE
CacheObjectType = N'Compiled Plan'
--and
--(PhysicalOperator = 'Clustered Index Scan' or PhysicalOperator = 'Table Scan' or PhysicalOperator = 'Index Scan')
----AND DatabaseName <> '[tempdb]'
--GO

SELECT * from #temp
WHERE (physicaloperator like '%scan%' or logicaloperator like '%scan%')
and DatabaseName <> '[tempdb]'
ORDER BY ObjectNAme

-- Switch to the correct database to pull the relevant statistics data for the objects in the query plan
SELECT
'UPDATE STATISTICS ' + [sch].[name] + '.'  + [so].[name] + ' ' + [ss].[name] + ' WITH FULLSCAN;' as FQN,
'DROP STATISTICS ' + [sch].[name] + '.'  + [so].[name] + '.' + [ss].[name] + ';' AS DD,
[sch].[name],
[so].object_id,
[so].[name] [TableName],
[ss].[name] [StatisticName],
[ss].[stats_id] [StatisticID],
[sp].[rows],
[sp].[last_updated] [LastUpdated],
[sp].[rows] [RowsInTableWhenUpdated],
[sp].[rows_sampled] [RowsSampled],
[sp].[modification_counter] [NumberOfModifications],
[sp].[modification_counter] * 1.00 / sp.rows * 100 [percent_mod],
[ss].no_recompute,
[so].create_date--, *
FROM [sys].[stats] [ss]
INNER JOIN [sys].[objects] [so] 
	ON [ss].[object_id] = [so].[object_id]
INNER JOIN sys.schemas sch
	ON so.schema_id = sch.schema_id
CROSS APPLY [sys].[dm_db_stats_properties] ([so].[object_id], [ss].stats_id) [sp]
WHERE is_ms_shipped = 0 
AND [sp].[rows] > 0 and (so.name in (select distinct REPLACE(REPLACE(ObjectName, '[', ''), ']', '') from #temp))
--AND so.name IN ('trips', 'IdleViolations', 'GeoFenceActivations')
--AND [sp].[last_updated] < '2018-05-08 00:00:00.000'
--AND [sp].[rows] >= 50000
--AND [ss].[auto_created] = 0
--AND [sp].[modification_counter] * 1.00 / sp.rows * 100 > .5
--AND [so].[name] = 'Events'
--ORDER BY [sp].[modification_counter] * 1.00 / sp.rows * 100 DESC
ORDER BY [so].[name], LastUpdated desc
GO




 
	  