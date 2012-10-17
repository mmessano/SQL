---------------------------------------------------------------------------------
--Database Backups for all databases For Previous Week
---------------------------------------------------------------------------------
SELECT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   msdb.dbo.backupset.database_name, 
   msdb.dbo.backupset.backup_start_date, 
   msdb.dbo.backupset.backup_finish_date,
   msdb.dbo.backupset.expiration_date,
   CASE msdb..backupset.type 
       WHEN 'D' THEN 'Database' 
       WHEN 'L' THEN 'Log' 
   END AS backup_type, 
   msdb.dbo.backupset.backup_size, 
   msdb.dbo.backupmediafamily.logical_device_name, 
   msdb.dbo.backupmediafamily.physical_device_name,  
   msdb.dbo.backupset.name AS backupset_name,
   msdb.dbo.backupset.description
FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7) 
ORDER BY 
   msdb.dbo.backupset.database_name,
   msdb.dbo.backupset.backup_finish_date
-------------------------------------------------------------------------------------------
--Most Recent Database Backup for Each Database - Detailed
-------------------------------------------------------------------------------------------    
SELECT
	A.[Server]
	, A.database_name
	, B.backup_start_date
	, B.backup_finish_date
	, CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, B.backup_start_date, B.backup_finish_date), 0), 114) AS BackupTime
	, B.backup_size
	--, B.expiration_date
	--, B.logical_device_name
	--, B.physical_device_name
	--, B.backupset_name
FROM
   (
   SELECT  
       CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
       msdb.dbo.backupset.database_name, 
       MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date
   FROM    msdb.dbo.backupmediafamily 
       INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
   WHERE   msdb..backupset.type = 'D'
   GROUP BY
       msdb.dbo.backupset.database_name 
   ) AS A
   
   LEFT JOIN 

   (
   SELECT  
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   msdb.dbo.backupset.database_name, 
   msdb.dbo.backupset.backup_start_date, 
   msdb.dbo.backupset.backup_finish_date,
   msdb.dbo.backupset.expiration_date,
   msdb.dbo.backupset.backup_size, 
   msdb.dbo.backupmediafamily.logical_device_name, 
   msdb.dbo.backupmediafamily.physical_device_name,  
   msdb.dbo.backupset.name AS backupset_name,
   msdb.dbo.backupset.description
FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  msdb..backupset.type = 'D'
   ) AS B
   ON A.[server] = B.[server] AND A.[database_name] = B.[database_name] AND A.[last_db_backup_date] = B.[backup_finish_date]
ORDER BY 
   backup_finish_date
-------------------------------------------------------------------------------------------
--Databases with data backup over 24 hours old
SELECT
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   msdb.dbo.backupset.database_name,
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date,
   DATEDIFF(hh, MAX(msdb.dbo.backupset.backup_finish_date), GETDATE()) AS [Backup Age (Hours)]
FROM    msdb.dbo.backupset
WHERE     msdb.dbo.backupset.type = 'D' 
GROUP BY msdb.dbo.backupset.database_name
HAVING      (MAX(msdb.dbo.backupset.backup_finish_date) < DATEADD(hh, - 24, GETDATE())) 

UNION 

--Databases without any backup history
SELECT     
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, 
   master.dbo.sysdatabases.NAME AS database_name, 
   NULL AS [Last Data Backup Date], 
   9999 AS [Backup Age (Hours)] 
FROM
   master.dbo.sysdatabases LEFT JOIN msdb.dbo.backupset
       ON master.dbo.sysdatabases.name  = msdb.dbo.backupset.database_name
WHERE msdb.dbo.backupset.database_name IS NULL AND master.dbo.sysdatabases.name <> 'tempdb'
ORDER BY 
   msdb.dbo.backupset.database_name