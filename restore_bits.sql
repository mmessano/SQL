if exists (select * from tempdb..sysobjects where name like '##backuphistory%') 
--truncate table #backuphistory 
--drop table #backuphistory
delete from ##backuphistory where LastUpdate < GetDate() - 7
ELSE
CREATE TABLE [dbo].[##backuphistory](
	[database_name] [sysname] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sequence_id] [int] NOT NULL DEFAULT '0',
	[server_name] [sysname] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT (convert(sysname,serverproperty('ServerName'))),
	[activity] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[end_time] [datetime] NOT NULL DEFAULT (getdate()),
	[message] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LastUpdate] [datetime] NOT NULL DEFAULT (getdate()),
	[Restored] bit DEFAULT 0
) ON [PRIMARY]
 

-- this will not populate when the table is empty or there is no record for the particular database
insert into ##backuphistory (database_name,sequence_id,server_name,activity,end_time,message)
select database_name,sequence_id,server_name,activity,end_time,REPLACE(SUBSTRING(message,22,LEN(message)),']','') 
	from msdb.dbo.sysdbmaintplan_history
	where  activity LIKE 'Backup%'
	-- and database_name NOT IN ('master','model','msdb')
	and database_name = 'GEMonitoring'
	and end_time >= GetDate() - 1
	-- the following is the problem
	and sequence_id > (select max(ISNULL(sequence_id,0)) from ##backuphistory where database_name = 'GEMonitoring')
order by 1,2,3

select * from ##backuphistory

--select max(ISNULL(sequence_id,0)) from psqlge10.msdb.dbo.sysdbmaintplan_history
--------------------------------------------------------------------------------
--select * from psqlge10.msdb.dbo.backupfile
--select * from psqlge10.msdb.dbo.backupset
--------------------------------------------------------------------------------
-- Backup history
/*Declare @database  SYSNAME

Set @database = 'GEMonitoring'

SELECT   b.database_name,
         b.backup_start_date,
         b.backup_finish_date,
         b.user_name,
         f.logical_name,
         f.physical_name,
         f.file_type
FROM     psqlge10.msdb.dbo.backupfile f,
         psqlge10.msdb.dbo.backupset b
WHERE    f.backup_set_id = b.backup_set_id
           AND b.backup_start_date  >= GetDate() - 1
           AND b.database_name = COALESCE(@database,database_name)
ORDER BY b.database_name, b.backup_start_date
*/
--------------------------------------------------------------------------------
--select * from xsql1.msdb.dbo.restorehistory where restore_date >= GetDate() - 1
--select * from xsql1.msdb.dbo.restorefile
--------------------------------------------------------------------------------
-- Restore history
/*
Declare @database  SYSNAME
Set @database = 'GEMonitoring'

SELECT  h.destination_database_name,
          h.restore_date,
           h.user_name,
           h.restore_type,
           f.destination_phys_name
FROM     xsql1.msdb.dbo.restorehistory h,
         xsql1.msdb.dbo.restorefile f
WHERE    h.restore_history_id = f.restore_history_id
           AND h.restore_date >= GetDate() - 1
           AND h.destination_database_name = COALESCE (@database,destination_database_name)
ORDER BY h.destination_database_name, h.restore_date
*/
--------------------------------------------------------------------------------
