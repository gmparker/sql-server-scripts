/*============================================================================
  File:     Recompile Sprocs - Recompile Hammer.sql
 
  Summary:  Recompiles Stored Procedures based on last execution time
  compared to the average times a value
 
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

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#dba_RecompileSprocs') IS NOT NULL
    DROP TABLE #dba_RecompileSprocs

declare @i int = 999
declare @maxi int = -1
declare @stmt varchar(255)

declare @SchemaName varchar(100)
declare @SprocName varchar(100)
declare @mwt decimal(18,2)
declare @lwt decimal(18,2)
declare @awt decimal(18,2)
declare @ec decimal(18,2)

CREATE TABLE #dba_RecompileSprocs 
(
[pkey] int identity(1,1) not null,
[SchemaName] varchar(100),
[SprocName] varchar(100),
[mwt] decimal(18,2),
[lwt] decimal(18,2),
[awt] decimal(18,2),
[ec] decimal(18,2), 
[txTimeStamp] datetime
)

insert into #dba_RecompileSprocs ([SchemaName],[SprocName], [mwt], [lwt], [awt], [ec], [txTimeStamp])
SELECT TOP 100 SCHEMA_NAME(schema_id) as Sch, name, total_worker_time, last_worker_time, (total_worker_time / execution_count) as awt, execution_count, getdate()
FROM sys.procedures AS p WITH (NOLOCK)
	INNER JOIN sys.dm_exec_procedure_stats AS qs WITH (NOLOCK)
		ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
AND last_worker_time >= (total_worker_time / execution_count) * 1.25
AND execution_count >= 10
ORDER BY name

select @i = min(pkey), @maxi = max(pkey) from #dba_RecompileSprocs

if @i is null and @maxi is null
begin
	print 'No changes needed.'
end

while @i <= @maxi
begin

select @SchemaName = SchemaName,
@SprocName = SprocName,
@mwt = mwt,
@lwt = lwt,
@awt = awt,
@ec = ec
from #dba_RecompileSprocs 
where [pkey] = @i


SELECT @stmt = 'EXEC sp_recompile ' + '''' + @SchemaName + '.' + '' + @SprocName + ''''
EXEC (@stmt)

select @i = min(pkey) from #dba_RecompileSprocs where [pkey] > @i
	
select @SchemaName = null
select @SprocName = null
select @mwt = null
select @lwt = null
select @awt = null
select @ec = null

end

IF OBJECT_ID('tempdb..#dba_RecompileSprocs') IS NOT NULL
    DROP TABLE #dba_RecompileSprocs
GO

