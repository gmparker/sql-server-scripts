


SELECT     
'Availability Group: '+	AGS.name +'                   
Replica Server: '+	AR.replica_server_name       +'
Availability Mode Desc: '+	AR.availability_mode_desc       +'
Role: '+	HARS.role_desc +'
DB Name: '+	DB_NAME(DRS.database_id)+'
DB State: '+	DRS.database_state_desc COLLATE database_default +'
Is Suspended: '+	cast(DRS.is_suspended AS varchar(20)) +'
Last Hardened Time: '+	isnull(cast(DRS.last_hardened_time AS varchar(100)),'Not applicable on Primary') +'
Last Redone Time: '+	isnull(cast(DRS.last_redone_time AS varchar(100)),'Not applicable on Primary')  +'
Log Send Queue (kb): '+	isnull(cast(DRS.log_send_queue_size AS varchar(100)),'Not applicable on Primary')  +'
Redo Queue (kb): '+	isnull(cast(DRS.redo_queue_size AS varchar(100)),'Not applicable on Primary') +'
Last Commit Time: '+	isnull(cast(DRS.last_commit_time AS varchar(100)),'Not applicable on Primary') as AGString,
COUNT(*) as COUNTER
FROM  sys.dm_hadr_database_replica_states DRS
LEFT JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id
LEFT JOIN sys.availability_groups AGS ON AR.group_id = AGS.group_id
LEFT JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id																											AND AR.replica_id = HARS.replica_id
WHERE AR.replica_server_name = @@servername
AND AVAILABILITY_MODE_DESC <> 'ASYNCHRONOUS_COMMIT'
GROUP BY
'Availability Group: '+	AGS.name +'                   
Replica Server: '+	AR.replica_server_name       +'
Availability Mode Desc: '+	AR.availability_mode_desc       +'
Role: '+	HARS.role_desc +'
DB Name: '+	DB_NAME(DRS.database_id)+'
DB State: '+	DRS.database_state_desc COLLATE database_default +'
Is Suspended: '+	cast(DRS.is_suspended AS varchar(20)) +'
Last Hardened Time: '+	isnull(cast(DRS.last_hardened_time AS varchar(100)),'Not applicable on Primary') +'
Last Redone Time: '+	isnull(cast(DRS.last_redone_time AS varchar(100)),'Not applicable on Primary')  +'
Log Send Queue (kb): '+	isnull(cast(DRS.log_send_queue_size AS varchar(100)),'Not applicable on Primary')  +'
Redo Queue (kb): '+	isnull(cast(DRS.redo_queue_size AS varchar(100)),'Not applicable on Primary') +'
Last Commit Time: '+	isnull(cast(DRS.last_commit_time AS varchar(100)),'Not applicable on Primary')