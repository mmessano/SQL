select * from sysmaintplan_logdetail
where line1 LIKE 'Back Up Database Task (PSQLSVC20)'
where datepart(day,end_time) = datepart(day,GetDate()-1)

SELECT * FROM sysmaintplan_log

select * FROM [msdb].[dbo].[backupset]
SELECT * FROM sysmaintplan_subplans
-------------------------------------------------------------------------
SELECT [backup_set_id]
      ,[media_set_id]
      ,[name]
      ,[description]
      ,[database_creation_date]
      ,[backup_finish_date]
      ,[type]
      ,[backup_size]
      ,[database_name]
      ,[server_name]
      ,[machine_name]
  FROM [msdb].[dbo].[backupset]
where datepart(day,backup_finish_date) = datepart(day,GetDate()-1)
AND type = 'D'
AND NAME = 'CacheManagement_backup_2009_06_24_230001_3709062'
--------------------------------------------------------------------------
SELECT [backup_set_id]
      ,[backup_set_uuid]
      ,[media_set_id]
      ,[first_family_number]
      ,[name]
      ,[description]
      ,[user_name]
      ,[first_lsn]
      ,[last_lsn]
      ,[checkpoint_lsn]
      ,[database_backup_lsn]
      ,[database_creation_date]
      ,[backup_start_date]
      ,[backup_finish_date]
      ,[type]
      ,[backup_size]
      ,[database_name]
      ,[server_name]
      ,[machine_name]
  FROM [msdb].[dbo].[backupset] bs INNER JOIN
  sysmaintplan_logdetail ld ON ld.task_detail_id = 
where line1 LIKE 'Back Up Database Task (PSQLSVC20)'
datepart(day,backup_finish_date) = datepart(day,GetDate()-1)
AND NAME = 'CacheManagement_backup_2009_06_24_230001_3709062'

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
--Most Recent Database Backup for Each Database
------------------------------------------------------------------------------------------- 
SELECT 
   CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server,
   msdb.dbo.backupset.database_name,
   msdb.dbo.backupmediafamily.physical_device_name, 
   MAX(msdb.dbo.backupset.backup_finish_date) AS last_db_backup_date
FROM   msdb.dbo.backupmediafamily 
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 
WHERE  msdb..backupset.type = 'D'
GROUP BY
   msdb.dbo.backupset.database_name, msdb.dbo.backupmediafamily.physical_device_name
ORDER BY 
   msdb.dbo.backupset.database_name
   -------------------------------------------------------------------------------------------
--Most Recent Database Backup for Each Database - Detailed
-------------------------------------------------------------------------------------------
SELECT 
   A.[Server], 
   A.last_db_backup_date, 
   B.backup_start_date, 
   B.expiration_date,
   B.backup_size, 
   B.logical_device_name, 
   B.physical_device_name,  
   B.backupset_name,
   B.description
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
   A.database_name