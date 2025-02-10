


SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#temp') IS NOT NULL
BEGIN
	DROP TABLE #temp
END

SET QUOTED_IDENTIFIER ON

if (select
        ars.role_desc
    from sys.dm_hadr_availability_replica_states ars
    inner join sys.availability_groups ag
    on ars.group_id = ag.group_id
    where ag.name = 'Prod08_GPS'
    and ars.is_local = 1) = 'PRIMARY'
BEGIN

	USE Prod08_GPS


	declare @procname varchar(2000)
	declare @schemaname varchar(2000)
	declare @counter int = 0

	select @procname = 'Sel_GeoFencesByGroupIds'
	select @schemaname = 'GeoFenceSvc'

	-- Break down the query plan to parse out the operators
	;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
	CachedPlans
	(DatabaseName,SchemaName,ObjectName,ParentOperationID,OperationID, PhysicalOperator, LogicalOperator, IndexName, QueryText,QueryPlan, CacheObjectType, ObjectType)
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
	Coalesce(RelOp.op.value(N'TableScan[1]/Object[1]/@Index', N'varchar(50)') , 
	RelOp.op.value(N'OutputList[1]/ColumnReference[1]/@Index', N'varchar(50)') ,
	RelOp.op.value(N'IndexScan[1]/Object[1]/@Index', N'varchar(200)') ,
	'Unknown'
	)
	as IndexName,
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
	and OBJECT_SCHEMA_NAME (st.objectid, st.dbid) = @schemaname
	)

	-- Load the data into a temp table to confirm that a plan exists
	SELECT DatabaseName,SchemaName,ObjectName,ParentOperationID,OperationID, PhysicalOperator, LogicalOperator, IndexName, CacheObjectType, ObjectType, queryplan
	INTO #temp 
	FROM CachedPlans

	IF @@ROWCOUNT > 0 -- There are rows in the temp table indicating that a plan exists
		BEGIN
			SELECT @counter = count(*) --DatabaseName,SchemaName,ObjectName,ParentOperationID,OperationID, PhysicalOperator, LogicalOperator, IndexName, CacheObjectType, ObjectType, queryplan
			FROM #temp
			WHERE CacheObjectType = N'Compiled Plan'
			AND PhysicalOperator LIKE '%Merge%'
	
			IF @counter > 0 -- At least one merge join exists
			BEGIN
				EXEC sp_recompile 'GeoFenceSvc.Sel_GeoFencesByGroupIds'
				SELECT 'TRUE'
			END 

			ELSE
				SELECT 'FALSE' -- No merge join exists in the current plan
		END
	ELSE
		SELECT 'FALSE' -- No plan currently exists
END	