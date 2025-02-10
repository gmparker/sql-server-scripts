
/*============================================================================
  File:     Transaction Log Free Space with Disk.sql
 
  Summary:  Checks the amount of free space available in the transaction log
  taking account if autogrow is enabled / disabled and the amount of 
  available disk space on the drive.
 
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

/*
Transaction Log Freespace Alert
Checks for amount of log freespace
as well as the amount of available disk space

If auto grow is DISABLED, exludes the available 
disk space check
*/

declare @logfreespace int = 25 -- amount of log free space available
declare @diskfreepct int = 50  -- amount of disk free space available

IF OBJECT_ID(N'tempdb..#tran_log_space_usage') IS NOT NULL
BEGIN
	DROP TABLE #tran_log_space_usage
END

create table #tran_log_space_usage ( 
        database_name sysname
,       log_size_mb float
,       log_space_used float
,       status int
); 

insert into #tran_log_space_usage 
exec('DBCC SQLPERF ( LOGSPACE ) WITH NO_INFOMSGS')

SELECT DISTINCT 
'Server Name: ' + @@servername + '
Database Name: ' + db_name(mf.database_id)  + '
LogSizeMB: ' + cast(CONVERT(decimal(18,2), tt.log_size_mb) as varchar(25))  + '
LogSpaceUsed: ' + cast(CONVERT(decimal(18,2), tt.log_space_used) as varchar(25)) + '%
LogFreeSpace: ' + cast(convert(decimal(18,2),(100-log_space_used)) as varchar(25)) + '%
DriveFreeSpaceInMB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.available_bytes/1048576.0)) + '
DriveTotalSpaceInMB: ' +  CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.total_bytes/1048576.0)) + '
DiskFreePct: ' + cast(CONVERT(decimal(18,2), ((CONVERT(decimal(18,2),dovs.available_bytes/1048576.00) / CONVERT(decimal(18,2),dovs.total_bytes/1048576.00))  * 100.00)) as varchar(25)) + '%
     ' as String,
cast(convert(decimal(18,2),(100-log_space_used)) as varchar(25)) as LogFreeSpace
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
INNER JOIN #tran_log_space_usage tt
	ON db_name(mf.database_id) = tt.database_name
WHERE dovs.FILE_ID = 2 -- Transaction Log File
AND cast(convert(float,(100-log_space_used)) as decimal(10,2)) <= @logfreespace -- Log Free Space 
AND CONVERT(FLOAT,dovs.available_bytes/1048576.00) / CONVERT(FLOAT,dovs.total_bytes/1048576.00)  * 100.00 <= @diskfreepct -- Disk Space Free %
AND mf.growth > 0 -- Auto Grow is ENABLED

UNION ALL

SELECT DISTINCT 
'Server Name: ' + @@servername + '
Database Name: ' + db_name(mf.database_id)  + '
LogSizeMB: ' + cast(CONVERT(decimal(18,2), tt.log_size_mb) as varchar(25))  + '
LogSpaceUsed: ' + cast(CONVERT(decimal(18,2), tt.log_space_used) as varchar(25)) + '%
LogFreeSpace: ' + cast(convert(decimal(18,2),(100-log_space_used)) as varchar(25)) + '%
DriveFreeSpaceInMB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.available_bytes/1048576.0)) + '
DriveTotalSpaceInMB: ' +  CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.total_bytes/1048576.0)) + '
DiskFreePct: ' + cast(CONVERT(decimal(18,2), ((CONVERT(decimal(18,2),dovs.available_bytes/1048576.00) / CONVERT(decimal(18,2),dovs.total_bytes/1048576.00))  * 100.00)) as varchar(25)) + '%
     ' as String,
cast(convert(decimal(18,2),(100-log_space_used)) as varchar(25)) as LogFreeSpace
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
INNER JOIN #tran_log_space_usage tt
	ON db_name(mf.database_id) = tt.database_name
WHERE dovs.FILE_ID = 2 -- Transaction Log File
AND cast(convert(float,(100-log_space_used)) as decimal(10,2)) <= @logfreespace -- Log Free Space 
AND mf.growth = 0 -- Auto Grow is DISABLED
