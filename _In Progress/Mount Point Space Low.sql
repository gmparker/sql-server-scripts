



/*
Percent of disk space free alert F:\
Alerts if the percent of disk space available drops below 20%
Due to limitation on Solarwinds, we have created one for each mount point on the DWH
*/
declare @spacefree int
select @spacefree = 20

select distinct
'Server Name: ' + @@servername 
	+ ' Database Name: ' + db_name(mf.database_id) + CHAR(13) + CHAR(10) 
	+ ' MountPoint: ' + volume_mount_point + CHAR(13) + CHAR(10) 
	--+ ' Available Space MB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.available_bytes/1048576.0)) + CHAR(13) + CHAR(10) 
	--+ ' TotalSpace MB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.total_bytes/1048576.0))+ CHAR(13) + CHAR(10) 
	+ ' DiskFreePct: ' + cast(CONVERT(decimal(18,2), ((CONVERT(decimal(18,2),dovs.available_bytes/1048576.00) / CONVERT(decimal(18,2),dovs.total_bytes/1048576.00))  * 100.00)) as varchar(25)) + '% ' + CHAR(13) + CHAR(10) 
    + ' Volume Mount Point: ' + volume_mount_point + CHAR(13) + CHAR(10) 
    + ' Space Available GB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.available_bytes/1048576.00 / 1024)) + CHAR(13) + CHAR(10) 
    + ' Total Space GB: ' + CONVERT(varchar(25),CONVERT(decimal(18,2), dovs.total_bytes/1048576.00 / 1024)) + CHAR(13) + CHAR(10) ,
 + cast(CONVERT(decimal(18,2) , ((CONVERT(decimal(18,2),dovs.available_bytes/1048576.00) / CONVERT(decimal(18,2),dovs.total_bytes/1048576.00)) * 100.00)) as varchar(25)) as 'Pct free'
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
WHERE CONVERT(FLOAT,dovs.available_bytes/1048576.00) / CONVERT(FLOAT,dovs.total_bytes/1048576.00)  * 100.00 <= @spacefree -- Disk Space Free %
AND volume_mount_point = (select volume_mount_point from sys.dm_os_volume_stats(11, 20))
