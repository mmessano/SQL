select * from Database_Status
select * from SSIS_Errors

USE SQL_Overview
GO
CREATE TABLE [dbo].[SSIS_ServerList](
	[Server] [varchar](128) NOT NULL,
	[Usage] [char](10) NULL,
	[Skip_SQL_Overview] [bit] NULL,
	CONSTRAINT [PK_SSIS_ServerList] PRIMARY KEY NONCLUSTERED
		(
			[Server] ASC
		)		
)

-------------------------------------------------------------------------------------------------

USE SQL_Overview
GO
CREATE TABLE #Server ( [Server] [varchar](128) )
INSERT INTO #Server
EXEC xp_cmdshell 'sqlcmd /Lc'
INSERT INTO SSIS_ServerList ([Server])
SELECT [Server] FROM #Server WHERE [Server] IS NOT NULL
DROP TABLE #Server 

select * from SSIS_ServerList

-------------------------------------------------------------------------------------------------

USE [SQL_Overview]
GO
CREATE TABLE [dbo].[Database_Status](
[Server] [nvarchar](128) NOT NULL,
[InstanceName] [nvarchar](128) NULL,
[DatabaseName] [nvarchar](128) NOT NULL,
[DatabaseStatus] [nvarchar](128) NULL,
[Recovery] [nvarchar](128) NULL,
[User_Access] [nvarchar](128) NULL,
[Updatability] [nvarchar](128) NULL
) ON [PRIMARY] 

-------------------------------------------------------------------------------------------------

USE [SQL_Overview]
GO
CREATE TABLE [dbo].[SSIS_Errors](
[Server] [varchar](128) NOT NULL,
[TaskName] [varchar](128) NULL,
[ErrorCode] [int] NULL,
[ErrorDescription] [varchar](MAX) NULL
) ON [PRIMARY] 

-------------------------------------------------------------------------------------------------

USE [SQL_Overview]
GO
CREATE TABLE [dbo].[ErrorLog](
[Server] [nvarchar](128) NOT NULL,
[dtMessage] [datetime] NULL,
[SPID] [varchar](50) NULL,
[vchMessage] [nvarchar](4000) NULL,
[ID] [int] NULL
) ON [PRIMARY] 

-------------------------------------------------------------------------------------------------

 IF OBJECT_ID('tempdb.dbo.ErrorLog') IS NOT NULL
DROP TABLE tempdb.dbo.ErrorLog
GO
CREATE TABLE tempdb.dbo.ErrorLog(
[Server] [nvarchar](128) NOT NULL,
[dtMessage] [datetime] NULL,
[SPID] [varchar](50) NULL,
[vchMessage] [nvarchar](4000) NULL,
[ID] [int] NULL
) ON [PRIMARY]

-------------------------------------------------------------------------------------------------

-- view errors
SELECT [Server]
,[dtMessage]
,[SPID]
,[vchMessage]
,[ID]
FROM [SQL_Overview].[dbo].[ErrorLog]
WHERE ([vchMessage] LIKE '%error%'
OR [vchMessage] LIKE '%fail%'
OR [vchMessage] LIKE '%Warning%'
OR [vchMessage] LIKE '%The SQL Server cannot obtain a LOCK resource at this time%'
OR [vchMessage] LIKE '%Autogrow of file%in database%cancelled or timed out after%'
OR [vchMessage] LIKE '% is full%'
OR [vchMessage] LIKE '% blocking processes%'
)
AND [vchMessage] NOT LIKE '%\ERRORLOG%'
AND [vchMessage] NOT LIKE '%Attempting to cycle errorlog%'
AND [vchMessage] NOT LIKE '%Errorlog has been reinitialized.%'
AND [vchMessage] NOT LIKE '%found 0 errors and repaired 0 errors.%'
AND [vchMessage] NOT LIKE '%without errors%'
AND [vchMessage] NOT LIKE '%This is an informational message%'
AND [vchMessage] NOT LIKE '%WARNING:%Failed to reserve contiguous memory%'
AND [vchMessage] NOT LIKE '%The error log has been reinitialized%'
AND [vchMessage] NOT LIKE '%Setting database option ANSI_WARNINGS%'
AND [vchMessage] NOT LIKE '%Error: 15457, Severity: 0, State: 1%'
AND [vchMessage] <> 'Error: 18456, Severity: 14, State: 16.'

-------------------------------------------------------------------------------------------------
-- create rep schema
USE  [SQL_Overview]
GO
CREATE SCHEMA [rep] AUTHORIZATION [dbo]

-------------------------------------------------------------------------------------------------
-- databaseowners parts
IF OBJECT_ID(N'[tempdb].[dbo].DatabaseOwners', 'U') IS NOT NULL
      DROP TABLE [tempdb].[dbo].DatabaseOwners;

CREATE TABLE [tempdb].[dbo].DatabaseOwners
(
	[server_name] [varchar](64) NULL,
	[database_name] [sysname] NOT NULL,
	[sys_databases_sid] [varbinary](85) NOT NULL,
	[sys_databases_owner] [nvarchar](256) NULL,
	[sys_users_sid] [varbinary](85) NULL,
	[sys_users_owner] [nvarchar](256) NULL,
	[LastUpdate] [datetime] NOT NULL CONSTRAINT [DF_DatabaseOwners_LastUpdate]  DEFAULT (getdate())
);


DECLARE @Version VARCHAR(1000)
SELECT @Version = @@VERSION

SELECT @Version = LEFT(LTRIM(RTRIM( SUBSTRING( @Version, CHARINDEX( '-', @Version )+1,CHARINDEX( '(', @Version ) - CHARINDEX( '-', @Version ) - 1 ) )),1)

IF ( @Version = '8' )
	BEGIN
		INSERT INTO [tempdb].[dbo].DatabaseOwners
			(
				--server_name,
				database_name,
				sys_databases_sid,
				sys_databases_owner
			)
      SELECT
		name,
		sid,
		SUSER_SNAME(sid)
    FROM master.dbo.sysdatabases;

	EXEC sp_MSforeachdb '
	UPDATE [tempdb].[dbo].DatabaseOwners
		SET sys_users_sid = (
			SELECT sid
			FROM ?.dbo.sysusers
			WHERE name = ''dbo''),
		sys_users_owner = (
			SELECT SUSER_SNAME(sid)
			FROM ?.dbo.sysusers
		WHERE name = ''dbo'')
	WHERE database_name = ''?''
      ';
	END
ELSE IF ( @version = '9' )
	BEGIN
	INSERT INTO [tempdb].[dbo].DatabaseOwners
	(
		database_name,
		sys_databases_sid,
 		sys_databases_owner
	)
		SELECT
			name,
			owner_sid,
			SUSER_SNAME(owner_sid)
		FROM sys.databases;

Declare @dbname varchar(128)
Declare @cmd varchar(8000)

declare dbname cursor for 
	select database_name from [tempdb].[dbo].DatabaseOwners

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 

select @cmd =	' UPDATE [tempdb].[dbo].DatabaseOwners ' + char(13) +
				' SET sys_users_sid = ( ' + char(13) +
				' SELECT sid ' + char(13) +
				' FROM [' + @dbname + '].sys.database_principals ' + char(13) +
				' WHERE name = ''dbo''), ' + char(13) +
				' sys_users_owner = ( ' + char(13) +
				' SELECT SUSER_SNAME(sid) ' + char(13) +
				' FROM [' + @dbname + '].sys.database_principals ' + char(13) +
				' WHERE name = ''dbo'') ' + char(13) +
				' WHERE database_name = ''' + @dbname + '''' + char(13)

--print @dbname
--print(@cmd)
EXEC(@cmd)

fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname

END

UPDATE [tempdb].[dbo].DatabaseOwners set server_name = @@SERVERNAME

--SELECT * FROM [tempdb].[dbo].DatabaseOwners


-------------------------------------------------------------------------------------------------
-- MaintenancePlan backup dir parts
IF EXISTS (SELECT * 
           FROM    tempdb.dbo.sysobjects 
           WHERE   id = OBJECT_ID(N'[tempdb].[dbo].[MaintPlanBackupDir]')
                ) 
        DROP TABLE [tempdb].[dbo].[MaintPlanBackupDir]
GO 

CREATE TABLE [tempdb].[dbo].[MaintPlanBackupDir](
	[ServerName] [nvarchar](32) NULL,
	[PlanName] [nvarchar](256) NULL,
	[BackupDir] [nvarchar](256) NULL,
	[LastUpdate] [datetime] NULL
) ON [PRIMARY]

GO

INSERT INTO [tempdb].[dbo].[MaintPlanBackupDir] (ServerName, PlanName, BackupDir,LastUpdate)
select CONVERT(nvarchar(128),Serverproperty('Servername')) AS ServerName, sj.Name AS PlanName, SUBSTRING (sjs.[Command], CHARINDEX ('-BkUpDB', sjs.[Command]) + 8, CHARINDEX ('-',SUBSTRING (sjs.[Command], CHARINDEX ('-BkUpDB', sjs.[Command]) + 8, LEN (sjs.[Command])) ) - 2 ) AS BackupDir, GetDate() 
from	msdb.dbo.sysjobs sj JOIN
	msdb.dbo.sysjobsteps sjs ON sj.job_id = sjs.job_id
where sjs.Command LIKE '%BkUpDB%'




USE [tempdb]
GO
/****** Object:  Table [dbo].[DatabaseOwners]    Script Date: 06/20/2008 09:57:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DatabaseOwners](
	[server_name] [varchar](64) NULL,
	[database_name] [sysname] NOT NULL,
	[sys_databases_sid] [varbinary](85) NOT NULL,
	[sys_databases_owner] [nvarchar](256) NULL,
	[sys_users_sid] [varbinary](85) NULL,
	[sys_users_owner] [nvarchar](256) NULL,
	[LastUpdate] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF