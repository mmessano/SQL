IF EXISTS (SELECT 1 FROM sysobjects WHERE [name] = 'spDoBackups' AND type = 'P')
	DROP PROC spDoBackups
GO
--
-- spDoBackups
-- Based on prc_DoSLSBackup written by Jeffrey Aven, Imceda Software, Inc.
-- Changes made by Andy Brown, Multimedia Games, Inc. to accomodate additional parameters and native SQL backups.
-- 
-- Revision History:
-- 07/02 –	1.0	(Initial Version)
-- 11/02 -	1.1	Added Differential Backup Functionality
-- 22/03 -	1.2	Added Support for Exclusion of Databases
-- 24/09 -	1.3	Added Error Handling for Concurrent Backup Operations
-- 15/10 -	1.4	Fixed Imtermittent Issue with Excluded DBs 
--			Continues backing up after DBCC error returns error at the end of the procedure
-- 16/10 -	1.5	Added support for creating subdirectory for each database
-- 28/11 -	1.5.1	Added support for logging
-- 03/12 -	1.5.2	Added support for servername directory
-- 27/01/06 -	1.6	(Andy Brown)
--			Added support for backing up and verifying normal SQL backup code to disk.
--			Added support for throttling and affinity in SQL LiteSpeed.
--			Added logging to the Event Viewer
--			Added support for making sure SQL LiteSpeed is installed.
--			Changed procedure name to sp_DoBackups
-- 31/01/06 -	1.6.1	Changed 'F' (FULL) parameter to 'C' (Complete) to allow for addition of File and File Group backups.
-- 15/05/06 - 		Changed procedure name to spDoBackups so as to not cause additional overhead.


CREATE PROCEDURE spDoBackups
@BackupType char(1) = 'C' 			
--'C' for Complete/Full Database Backup (Default)
--'D' for Differential Backups
--'F' for Individual File Backups
--'G' for Individual File Group Backups
--'L' for Transaction Log Backups
,@DBName sysname = '*'
--'*' for Backup All Databases (Default)
--'<database_name>' to backup an individual database 
,@BackupDir varchar(1024) = NULL
--Directory/Path to store Backups (can use UNC paths as well).
,@DoVerify bit = 1
--1 = Perform Verification of Backups (Default)
--0 = Skip Verification
,@BackupProduct smallint = 2
--2 = Use SQL Native Backup to File (Default)
--1 = Use SQL LiteSpeed Command Line Interface
--0 = Use SQL LiteSpeed Extended Stored Procedure Interface 
,@Debug smallint = 0
--2 = Print verbose logging and generate SQL LiteSpeed log files
--1 = Print verbose logging
--0 = Minimal logging (Default)
,@EncryptionKey varchar(1024) = NULL
--Encryption Key used to secure Backup Devices (Optional).
,@SLSThreads smallint = NULL
--Number of Threads to use for SQL LiteSpeed Backup, dynamically determined if not supplied.
,@SLSThrottle smallint = 85
--Sets SQL LiteSpeed's CPU usage. Default is 85(%).  Value should be between 1 and 100.
,@SLSAffinity int = 0
--Sets SQL LiteSpeed's processor affinity. Default is 0.
--On a 4-processor box, processors are numbered 0, 1, 2, and 3. 
--So on an N-processor box, processors would be numbered 0, 1, 2, ..., N-1.
--0 = All processors
--1 = Processor 0
--2 = Processor 1
--3 = Processor 0 and 1
--4 = Processor 2
--5 = Processor 2 and 0
--6 = Processor 2 and 1
--7 = Processor 2, 1 and 0
--8 = Processor 3
--See SQL SiteSpeed documentation for more information on the @affinity variable.
,@SLSPriority smallint = NULL
--Base priority of SQL LiteSpeed Backup process, dynamically determined if not supplied.
--2 = High
--1 = Above Normal
--0 = Normal (Default)
,@RetainDays int = NULL
--Number of days to retain backup device files, if supplied backup files older than the number of days specified
--will be purged.
,@InitBackupDevice bit = 0
--1 = Reinitialize backup device without date time stamp 
--0 = Create a new device for each backup which has the date time stamp embedded in the file name (Default)
,@PerformDBCC bit = 1
--1 = Perform DBCC CHECKDB prior to backing up database (default) 
--0 = Do not Perform DBCC CHECKDB prior to backing up database
,@ExcludedDBs varchar(2048) = NULL
--Comma Delimited List of Databases in Double Quotes to be excluded From Backup Operation
--CAUTION: Ensure proper syntax (eg '"pubs","Northwind"')
,@CreateSubDir bit = 0
--Creates a subdirectory under the backup directory for each db being backed up
,@CreateSrvDir bit = 0
--Creates a directory under the backup directory for the current server, used for scenarios where multiple servers 
--are backing up to the same location, ensures no namespace conflicts
,@Files varchar(2048) = NULL
--Comma Delimited List of Database Files in Double Quotes to be included in Backup Operation
--CAUTION: Ensure proper syntax (eg '"pubs_Data","Northwind_Data"')
,@FileGrps varchar(2048) = NULL
--Comma Delimited List of Database File Groups in Double Quotes to be included in Backup Operation
--CAUTION: Ensure proper syntax (eg '"PRIMARY","Indexes"')

AS
SET NOCOUNT ON
--Local Variables
DECLARE @DBStatus int
	,@DBMode varchar(50)
	,@StatusMsgPrefix char(18)
	,@StatusMsg varchar(1024)
	,@FileExt varchar(4)
	,@PhyName varchar(1024)
	,@BackupType2 varchar(4)
	,@Cmd nvarchar(1024)
	,@RC int
	,@dbid int
	,@BackupStartTime varchar(12)
	,@BackupAllDBs bit
	,@Operation varchar(6)
	,@CmdStr varchar(255)
	,@BUFile varchar(255)
	,@BUFileDate char(12)
	,@BUFileDate2 smalldatetime
	,@BaseBUFileDatalength int
	,@sqlstr varchar(1048)
	,@is_db_excluded bit
	,@orig_backup_dir varchar(512)

SELECT @StatusMsgPrefix =  'spDoBackups : ' 
SELECT @BackupAllDBs = 0
SELECT @orig_backup_dir = @BackupDir

--Check Access Level
IF IS_SRVROLEMEMBER ( 'sysadmin') = 0
	BEGIN
	SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Insufficient system access for ' + SUSER_SNAME() 
				+ ' to perform backup'
	RAISERROR(@StatusMsg,17,1) WITH LOG
	RETURN 1 	
	END

--Validate @BackupType Argument
SELECT @BackupType = UPPER(@BackupType)
IF @BackupType IN ('C', 'D', 'F', 'G', 'L')
	BEGIN
	IF @BackupType = 'C'
		SELECT @BackupType2 = 'Comp'
	IF @BackupType = 'D'
		SELECT @BackupType2 = 'Diff'
	IF @BackupType = 'F'
		SELECT @BackupType2 = 'File'
	IF @BackupType = 'G'
		SELECT @BackupType2 = 'FGrp'
	IF @BackupType = 'L'
		SELECT @BackupType2 = 'TLog'
	IF @BackupType IN ('F', 'G')
		BEGIN
		SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Backups of type:' + @BackupType + ' are currently not supported.  Contact the DBA group for more information'
		RAISERROR(@StatusMsg,16,1) WITH LOG
		RETURN 1
		END
	END
ELSE
	BEGIN
	SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Valid values for the @BackupType parameter are C, D, F, G, or L' 
	RAISERROR(@StatusMsg,16,1) WITH LOG
	RETURN 1 	
	END

-- Verify @BackupProduct exists (SQL LiteSpeed)
IF @BackupProduct < 2
	BEGIN
	IF NOT EXISTS (SELECT 1 FROM master..sysobjects WHERE [name] = 'xp_backup_database' AND type = 'X')
		BEGIN
		SELECT @StatusMsg = @StatusMsgPrefix + ' Error - SQL LiteSpeed is not installed.  Please set @BackupProduct to ''2'' or install SQL LiteSpeed before running this script again.' 
		RAISERROR(@StatusMsg,17,1) WITH LOG
		RETURN 1 	
		END
	END

--Validate @DBName Argument
IF @DBName <> '*'
	BEGIN
	IF NOT EXISTS (SELECT [name] FROM master.dbo.sysdatabases WHERE [name] = @DBName)
		BEGIN
		SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Invalid database selected for @DBName (' + @DBName 
					+ ') parameter' 
		RAISERROR(@StatusMsg,17,1) WITH LOG
		RETURN 1 	
		END 	
	IF @Debug > 0
		BEGIN
		SELECT @StatusMsg = @StatusMsgPrefix + @DBName + ' Selected for ' + @BackupType2 + ' Backup' 
		PRINT @StatusMsg
		END
	GOTO DoBackup
	END
ELSE
	BEGIN
	SELECT @BackupAllDBs = 1
	IF @Debug > 0
		BEGIN
		SELECT @StatusMsg = @StatusMsgPrefix + ' All Databases Selected for ' + @BackupType2 + ' Backup' 
		PRINT @StatusMsg
		END
	END

DECLARE DBs CURSOR FOR
SELECT name, dbid, status
FROM master..sysdatabases
WHERE [name] <> 'tempdb'
FOR READ ONLY

OPEN DBs
FETCH NEXT FROM DBs INTO @DBName, @dbid, @DBStatus
WHILE @@FETCH_STATUS = 0
	BEGIN
	--Is Databases Explicitly Excluded
	IF @ExcludedDBs IS NOT NULL
		BEGIN
		SELECT @ExcludedDBs = REPLACE(@ExcludedDBs,'"','''')
		IF EXISTS (SELECT 1 FROM tempdb..sysobjects WHERE [name] = 'tmp_is_db_excluded')
			DROP TABLE tempdb..tmp_is_db_excluded
		
		CREATE TABLE tempdb..tmp_is_db_excluded
			(
			is_db_excluded bit 
			)
		-- J. O'Brien need to reset bit field to 0 as if tmp_is_db_excluded is empty
		SELECT @is_db_excluded = 0
		SELECT @sqlstr = 'IF ''' + @DBName + ''' IN (' + @ExcludedDBs  + ') INSERT tempdb..tmp_is_db_excluded SELECT 1'
		EXEC (@sqlstr)
		SELECT @is_db_excluded = is_db_excluded FROM tempdb..tmp_is_db_excluded
		IF @is_db_excluded = 1
			BEGIN
			IF @Debug > 0
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + ' Skippping ' + @DBName + ' as this database has been explicitly excluded' 
				PRINT @StatusMsg
				END
			GOTO NextDB
			END
		END
DoBackup:	
	SELECT @Operation = 'Backup'
	SELECT @BackupStartTime = CONVERT(varchar(12),GETDATE(),12) + REPLACE(CONVERT(varchar(12),GETDATE(),8),':','')
	IF @BackupType = 'L'
		BEGIN
		--Check for System Database
		IF @dbid <= 4
			BEGIN
			IF @Debug > 0
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + 'System Database (' + @DBName 
							+ ') skipped for transaction log backup' 
				PRINT @StatusMsg
				END
			IF @BackupAllDBs = 1
				GOTO NextDB
			ELSE
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Unable to backup the log for ' + @DBName 
							+ ' - System Database' 
				RAISERROR(@StatusMsg,17,1) WITH LOG
				RETURN 1
				END
			END 	
			--Check for Simple Recovery Model		
			IF @DBStatus & 8 <> 0
				BEGIN
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Database (' + @DBName 
							+ ') skipped for transaction log backup - Simple Recovery Model' 
					PRINT @StatusMsg
					END
				IF @BackupAllDBs = 1
					GOTO NextDB
				ELSE
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Unable to backup the log for ' 
								+ @DBName + ' - Simple Recovery Model' 
					RAISERROR(@StatusMsg,17,1) WITH LOG
					RETURN 1
					END 
				END	
			END

 		--Check Database Accessibility
		SELECT @DBMode = 'OK'
		IF DATABASEPROPERTY(@DBName, 'IsDetached') > 0 
				SELECT @DBMode = 'Detached'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsInLoad') > 0 
				SELECT @DBMode = 'Loading'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsNotRecovered') > 0 
				SELECT @DBMode = 'Not Recovered'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsInRecovery') > 0 
				SELECT @DBMode = 'Recovering'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsSuspect') > 0 
				SELECT @DBMode = 'Suspect'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsOffline') > 0  	
				SELECT @DBMode = 'Offline'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsEmergencyMode') > 0 
				SELECT @DBMode = 'Emergency Mode'
			ELSE IF DATABASEPROPERTY(@DBName, 'IsShutDown') > 0 
				SELECT @DBMode = 'Shut Down (problems during startup)'
		IF @DBMode <> 'OK'
			BEGIN			
			IF @Debug > 0
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + 'Unable to backup ' + @DBName 
							+ ' - Database is in '  + @DBMode + ' state'
				PRINT @StatusMsg
				END
			IF @BackupAllDBs = 1
				GOTO NextDB
			ELSE
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Unable to backup ' + @DBName 
							+ ' - Database is in '  + @DBMode + ' state'
				RAISERROR(@StatusMsg,17,1) WITH LOG
				RETURN 1
				END
			END			
		--Check if Backup Directory Exists
		IF @CreateSrvDir = 1 and @CreateSubDir = 1
			SELECT @BackupDir = @orig_backup_dir + '\' + @@SERVERNAME + '\' + @DBName
		IF @CreateSrvDir = 1 and @CreateSubDir = 0
			SELECT @BackupDir = @orig_backup_dir + '\' + @@SERVERNAME
		IF @CreateSrvDir = 0 and @CreateSubDir = 1
			SELECT @BackupDir = @orig_backup_dir + '\' + @DBName
		
		SELECT @Cmd = 'dir "' + @BackupDir + '"' 
		EXEC @RC = master..xp_cmdshell @Cmd, NO_OUTPUT
		IF @RC <> 0
			--Create Backup Directory
			BEGIN
			SELECT @Cmd = 'md "' + @BackupDir + '"'
			EXEC @RC = master.dbo.xp_cmdshell @Cmd, NO_OUTPUT
			IF @RC <> 0
				BEGIN		 
				SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Unable to create backup directory (' 
							+ @BackupDir + ')'
				RAISERROR(@StatusMsg,17,1) WITH LOG
				RETURN 1
				END
			END

		--Build the Backup File Name
		SELECT @PhyName = @BackupDir + '\' + REPLACE(@@SERVERNAME,'\','_')  + '.' + REPLACE(@DBName,'.','_') 
				+ '.'	+ @BackupType2 
		IF @BackupProduct = 2
			SELECT @FileExt = '.BAK'
		ELSE
			SELECT @FileExt = '.SLS'
		IF @InitBackupDevice = 0
			--New Device For Each Backup
			SELECT @PhyName = @PhyName + @BackupStartTime + @FileExt 
		ELSE
			--Re-Initialize Each Backup Device
			SELECT @PhyName = @PhyName + @FileExt 
		--Set Tuning Defaults
		IF (@SLSThreads IS NULL) OR (@SLSAffinity > 0)
			BEGIN
			DECLARE @ProcessorCount int
			CREATE TABLE #MSVer
			(
			[Index] int
			,[Name] varchar (255)
			,Internal_Value int NULL
			,Charater_Value varchar(255)
			)
			INSERT #MSVer EXEC master..xp_msver
			SELECT @ProcessorCount = Internal_Value FROM #MSVer WHERE [Name] = 'ProcessorCount'
			SELECT @SLSThreads = @ProcessorCount
			DECLARE @i int
			DECLARE @binstr varchar(2048)
			SELECT @binstr = ''
			SELECT @i = @ProcessorCount
			WHILE @i > 0
				BEGIN
				SELECT @binstr = @binstr + '1'
				SELECT @i = @i - 1
				END
			IF cast(@SLSAffinity as binary) > cast(@binstr as binary)
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + ' Error - Invalid processor afffinity specified.  Please set @SLSAffinity to 0 or consult SQL LiteSpeed''s documentation.'
				RAISERROR(@StatusMsg,17,1) WITH LOG
				RETURN 1 	
				DROP TABLE #MSVer
				END
			END
		IF @SLSPriority IS NULL
			SELECT @SLSPriority = 0	
		--Do DBCC CHECKDB
		IF @PerformDBCC = 1
			BEGIN
			IF @Debug > 0
				BEGIN
				SELECT @StatusMsg = @StatusMsgPrefix + 'Executing DBCC CHECKDB on Database ' + @DBName 
							+ char(10)
				PRINT @StatusMsg
				DBCC CHECKDB (@DBName)
				END
			ELSE
				DBCC CHECKDB (@DBName) WITH NO_INFOMSGS
			SET @RC = @@ERROR
			IF @RC <> 0
				BEGIN
				SELECT @Operation = 'DBCC CHECKDB'
				GOTO FailedBackup
				END	
			END
		
		--Do Backup
		IF @BackupType = 'C'
			--Perform Complete Database Backup
			BEGIN
			IF @BackupProduct = 2
				BEGIN
				SELECT @Cmd = 'BACKUP DATABASE [' + @DBName + '] TO DISK = '''+ @PhyName + '''' 
				IF (@EncryptionKey IS NOT NULL) or (@InitBackupDevice IS NOT NULL)
					SELECT @Cmd = @Cmd + ' WITH'
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' PASSWORD = '''+ @EncryptionKey + ''''
				IF (@EncryptionKey IS NOT NULL) AND (@InitBackupDevice IS NOT NULL)
					SELECT @Cmd = @Cmd + ', '
				IF @InitBackupDevice IS NOT NULL
					SELECT @Cmd = @Cmd + ' INIT'
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' 
								+ @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				
				EXEC @RC = sp_executesql @Cmd

				END
			ELSE IF @BackupProduct = 1
				BEGIN
				SELECT @Cmd = char(34) + 'C:\Program Files\DBAssociates\SQLLiteSpeed\SQLLiteSpeed.EXE' + char(34) 
						+ ' -S' + @@SERVERNAME
						+ ' -BDatabase'
						+ ' -D' + @DBName
						+ ' -F' + @PhyName
						+ ' -t' + CONVERT(varchar(2),@SLSThreads)
						+ ' -h' + CONVERT(varchar(2),@SLSThrottle)
						+ ' -A' + CONVERT(varchar(2),@SLSAffinity)
						+ ' -p' + CONVERT(varchar(2),@SLSPriority)
						+ ' -I'
						+ ' -T'  
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' -K' + @EncryptionKey
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' + @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					EXEC @RC = master..xp_cmdshell @Cmd
					END
				ELSE
					EXEC @RC = master..xp_cmdshell @Cmd, NO_OUTPUT
				END
			ELSE
				BEGIN
				SELECT @Cmd = 'EXEC master..xp_backup_database' + char(10)
						+ char(9) + '@database = ' + char(39) + @DBName + char(39) + char(10)
						+ char(9) + ', @filename = ' + char(39) + @PhyName + char(39) + char(10)
						+ char(9) + ', @threads = ' + CONVERT(varchar(2),@SLSThreads) + char(10)
						+ char(9) + ', @throttle = ' + CONVERT(varchar(2),@SLSThrottle) + char(10)
						+ char(9) + ', @affinity = ' + CONVERT(varchar(2),@SLSAffinity) + char(10)
						+ char(9) + ', @priority = ' + CONVERT(varchar(2),@SLSPriority) + char(10)
						+ char(9) + ', @init = 1' + char(10)
						+ char(9) + ', @logging = ' + CONVERT(char(1),@Debug) + char(10)
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + char(9) + ', @encryptionkey = ' + char(39) 
							+ @EncryptionKey + char(39) + char(10)
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' 
								+ @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				IF @EncryptionKey IS NOT NULL
					EXEC @RC = master..xp_backup_database
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@encryptionkey = @EncryptionKey
							,@logging = @Debug
				ELSE
					EXEC @RC = master..xp_backup_database
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@logging = @Debug
				END
			IF @RC <> 0
				GOTO FailedBackup
			END

		IF @BackupType = 'D'
			--Perform Differential Database Backup
			BEGIN
			IF @DBName = 'master'
				GOTO NextDB
			IF @BackupProduct = 2
				BEGIN
				SELECT @Cmd = 'BACKUP DATABASE [' + @DBName + '] TO DISK = '''+ @PhyName + ''' WITH DIFFERENTIAL'
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ', PASSWORD = ''' + @EncryptionKey + ''''
				IF @InitBackupDevice IS NOT NULL
					SELECT @Cmd = @Cmd + ', INIT'
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' 
								+ @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
					EXEC @RC = sp_executesql @Cmd
				END
			ELSE IF @BackupProduct = 1
				BEGIN
				SELECT @Cmd = char(34) + 'C:\Program Files\DBAssociates\SQLLiteSpeed\SQLLiteSpeed.EXE' + char(34) 
						+ ' -S' + @@SERVERNAME
						+ ' -BDatabase'
						+ ' -D' + @DBName
						+ ' -F' + @PhyName
						+ ' -t' + CONVERT(varchar(2),@SLSThreads)
						+ ' -h' + CONVERT(varchar(2),@SLSThrottle)
						+ ' -A' + CONVERT(varchar(2),@SLSAffinity)
						+ ' -p' + CONVERT(varchar(2),@SLSPriority)
						+ ' -I'
						+ ' -T'  		
						+ ' -WDIFFERENTIAL'
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' -K' + @EncryptionKey
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' + @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					EXEC @RC = master..xp_cmdshell @Cmd
					END
				ELSE
					EXEC @RC = master..xp_cmdshell @Cmd, NO_OUTPUT
				END
			ELSE
				BEGIN
				SELECT @Cmd = 'EXEC master..xp_backup_database' + char(10)
						+ char(9) + '@database = ' + char(39) + @DBName + char(39) + char(10)
						+ char(9) + ', @filename = ' + char(39) + @PhyName + char(39) + char(10)
						+ char(9) + ', @threads = ' + CONVERT(varchar(2),@SLSThreads) + char(10)
						+ char(9) + ', @throttle = ' + CONVERT(varchar(2),@SLSThrottle) + char(10)
						+ char(9) + ', @affinity = ' + CONVERT(varchar(2),@SLSAffinity) + char(10)
						+ char(9) + ', @priority = ' + CONVERT(varchar(2),@SLSPriority) + char(10)
						+ char(9) + ', @init = 1' + char(10)
						+ char(9) + ', @with = ' + char(39) + 'DIFFERENTIAL' + char(39) + char(10)
						+ char(9) + ', @logging = ' + CONVERT(char(1),@Debug) + char(10)
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + char(9) + ', @encryptionkey = ' + char(39) 
							+ @EncryptionKey + char(39) + char(10)
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' + @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				IF @EncryptionKey IS NOT NULL
					EXEC @RC = master..xp_backup_database
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@encryptionkey = @EncryptionKey
							,@with = 'DIFFERENTIAL'
							,@logging = @Debug
				ELSE
					EXEC @RC = master..xp_backup_database
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@with = 'DIFFERENTIAL'
							,@logging = @Debug
				END
			IF @RC <> 0
				BEGIN
				IF @RC = 11704
					BEGIN
					GOTO NextDB
					END
				ELSE
					BEGIN
					GOTO FailedBackup
					END
				END
			END
			
		IF @BackupType = 'L'
			--Perform Transaction Log Backup
			BEGIN
			IF @BackupProduct = 2
				BEGIN
				SELECT @Cmd = 'BACKUP LOG [' + @DBName + '] TO DISK = '''+ @PhyName + ''''
				IF (@EncryptionKey IS NOT NULL) or (@InitBackupDevice IS NOT NULL)
					SELECT @Cmd = @Cmd + ' WITH'
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' PASSWORD = '''+ @EncryptionKey + ''''
				IF (@EncryptionKey IS NOT NULL) AND (@InitBackupDevice IS NOT NULL)
					SELECT @Cmd = @Cmd + ', '
				IF @InitBackupDevice IS NOT NULL
					SELECT @Cmd = @Cmd + ' INIT'
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' 
								+ @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
					EXEC @RC = sp_executesql @Cmd
				END
			ELSE IF @BackupProduct = 1
				BEGIN
				SELECT @Cmd = char(34) + 'C:\Program Files\DBAssociates\SQLLiteSpeed\SQLLiteSpeed.EXE' + char(34) 
						+ ' -S' + @@SERVERNAME
						+ ' -BLog'
						+ ' -D' + @DBName
						+ ' -F' + @PhyName
						+ ' -t' + CONVERT(varchar(2),@SLSThreads)
						+ ' -h' + CONVERT(varchar(2),@SLSThrottle)
						+ ' -A' + CONVERT(varchar(2),@SLSAffinity)
						+ ' -p' + CONVERT(varchar(2),@SLSPriority)
						+ ' -I'
						+ ' -T'  		
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' -K' + @EncryptionKey
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' + @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					EXEC @RC = master..xp_cmdshell @Cmd
					END
				ELSE
					EXEC @RC = master..xp_cmdshell @Cmd, NO_OUTPUT
				END
			ELSE
				BEGIN
				SELECT @Cmd = 'EXEC master..xp_backup_log' + char(10)
						+ char(9) + '@database = ' + char(39) + @DBName + char(39) + char(10)
						+ char(9) + ', @filename = ' + char(39) + @PhyName + char(39) + char(10)
						+ char(9) + ', @threads = ' + CONVERT(varchar(2),@SLSThreads) + char(10)
						+ char(9) + ', @throttle = ' + CONVERT(varchar(2),@SLSThrottle) + char(10)
						+ char(9) + ', @affinity = ' + CONVERT(varchar(2),@SLSAffinity) + char(10)
						+ char(9) + ', @priority = ' + CONVERT(varchar(2),@SLSPriority) + char(10)
						+ char(9) + ', @init = 1' + char(10)
						+ char(9) + ', @logging = ' + CONVERT(char(1),@Debug) + char(10)
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + char(9) + ', @encryptionkey = ' + char(39) 
							+ @EncryptionKey + char(39) + char(10)
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Backup of Database ' + @DBName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				IF @EncryptionKey IS NOT NULL
					EXEC @RC = master..xp_backup_log
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@encryptionkey = @EncryptionKey
							,@logging = @Debug
				ELSE
					EXEC @RC = master..xp_backup_log
							@database = @DBName
							,@filename = @PhyName 
							,@threads = @SLSThreads
							,@throttle = @SLSThrottle
							,@affinity = @SLSAffinity
							,@priority = @SLSPriority
							,@init = 1
							,@logging = @Debug
				END
			IF @RC <> 0
				BEGIN
				IF @RC = 11704
					BEGIN
					GOTO NextDB
					END
				ELSE
					BEGIN
					GOTO FailedBackup
					END
				END
			END
		--Verify Backup Device
		IF @DoVerify = 1
			BEGIN
			IF @BackupProduct = 2
				BEGIN
				SELECT @Cmd = 'RESTORE VERIFYONLY FROM DISK = ''' + @PhyName + ''''
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' WITH PASSWORD = ''' + @EncryptionKey + ''''
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Verifyonly of Backup Device ' 
								+ @PhyName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				EXEC @RC = sp_executesql @Cmd
				END
			ELSE IF @BackupProduct = 1
				BEGIN
				SELECT @Cmd = char(34) + 'C:\Program Files\DBAssociates\SQLLiteSpeed\SQLLiteSpeed.EXE' + char(34) 
						+ ' -S' + @@SERVERNAME
						+ ' -RVerifyonly'
						+ ' -F' + @PhyName
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + ' -K' + @EncryptionKey
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Verifyonly of Backup Device ' 
								+ @PhyName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					EXEC @RC = master..xp_cmdshell @Cmd	
					END
				ELSE
					EXEC @RC = master..xp_cmdshell @Cmd, NO_OUTPUT						
				END
			ELSE
				BEGIN
				SELECT @Cmd = 'EXEC master..xp_restore_verifyonly' + char(10)
						+ char(9) + ' @filename = ' + char(39) + @PhyName + char(39) + char(10)
				IF @EncryptionKey IS NOT NULL
					SELECT @Cmd = @Cmd + char(9) + ', @encryptionkey = ' + char(39) 
							+ @EncryptionKey + char(39) + char(10)
				IF @Debug > 0
					BEGIN
					SELECT @StatusMsg = @StatusMsgPrefix + 'Executing Verifyonly of Backup Device ' 
								+ @PhyName
					PRINT @StatusMsg
					SELECT @StatusMsg = @StatusMsgPrefix + 'Command to be Executed : ' + char(10) 
								+ char(9) + @Cmd + char(10)
					PRINT @StatusMsg
					END
				IF @EncryptionKey IS NOT NULL
					EXEC @RC = master..xp_restore_verifyonly
							@filename = @PhyName 
							,@encryptionkey = @EncryptionKey
							,@logging = @Debug
				ELSE
					EXEC @RC = master..xp_restore_verifyonly
							@filename = @PhyName 
							,@logging = @Debug
				END
			IF @RC <> 0
				BEGIN
				SELECT @Operation = 'Verify'
				GOTO FailedBackup
				END	
			END

		--Delete Old Backup Files and Remove Backup History
		IF @RetainDays IS NOT NULL AND @InitBackupDevice = 0 AND @BackupType = 'F'
			BEGIN
			--Building up Table of Files to Delete
			CREATE TABLE #DirOut
			(
			[Output] varchar(255)
			)
			SELECT @CmdStr = 'dir "' + @BackupDir + '\' + REPLACE(@@SERVERNAME,'\','_')  + '.' 
						+ REPLACE(@DBName,'.','_') +  '.*' + @FileExt + '" /B'
			SELECT @BaseBUFileDatalength = LEN(REPLACE(@@SERVERNAME,'\','_')  + '.' 
						+ REPLACE(@DBName,'.','_') +  '.') + 4
			INSERT #DirOut EXEC master..xp_cmdshell @CmdStr
			--Scroll Through Table
			DECLARE BUFiles CURSOR FOR
			SELECT [Output] FROM #DirOut WHERE [Output] IS NOT NULL
			FOR READ ONLY
			OPEN BUFiles
			FETCH NEXT FROM BUFiles INTO @BUFile
			WHILE @@FETCH_STATUS = 0
				BEGIN
				--Reconstruct DateTime From Filename
				SELECT @BUFileDate = LEFT(REPLACE(SUBSTRING(@BUFile,@BaseBUFileDatalength + 1,LEN(@BUFile)),'.SLS',''),6)
				SELECT @BUFileDate2 = CONVERT(smalldatetime,@BUFileDate,12)
				--Compare Date
				IF @BUFile <> (REPLACE(@@SERVERNAME,'\','_')  + '.' + REPLACE(@DBName,'.','_') + '.*'
						+ @FileExt)
					BEGIN
					IF DATEDIFF(d,@BUFileDate2,getdate()) > @RetainDays
						BEGIN
						SELECT @CmdStr = 'del "' + @BackupDir + '\' + @BUFile + '"'
						IF @Debug > 0
							BEGIN
							SELECT @StatusMsg = @StatusMsgPrefix + 'Deleting File : ' 
										+ @BUFile
							PRINT @StatusMsg										
							SELECT @StatusMsg = @StatusMsgPrefix 
										+ 'Command to be Executed : ' + @CmdStr
							PRINT @StatusMsg							
							EXEC @RC = master..xp_cmdshell @CmdStr 
							END
						ELSE
							EXEC @RC = master..xp_cmdshell @CmdStr, NO_OUTPUT
						END
					END
					FETCH NEXT FROM BUFiles INTO @BUFile
				END
				CLOSE BUFiles
				DEALLOCATE BUFiles
				DROP TABLE #DirOut
			
			BEGIN TRAN
				DELETE FROM msdb..restorefile
				FROM msdb..restorefile rf
				INNER JOIN msdb..restorehistory rh 
				ON rf.restore_history_id = rh.restore_history_id
				INNER JOIN msdb..backupset bs 
				ON rh.backup_set_id = bs.backup_set_id
				WHERE bs.backup_finish_date < (GETDATE() - @RetainDays)
				AND bs.database_name = @DBName
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..restorefilegroup
				FROM msdb..restorefilegroup rfg
				INNER JOIN msdb..restorehistory rh 
				ON rfg.restore_history_id = rh.restore_history_id
				INNER JOIN msdb..backupset bs 
				ON rh.backup_set_id = bs.backup_set_id
				WHERE bs.backup_finish_date < (GETDATE() - @RetainDays)
				AND bs.database_name = @DBName
				SET @StatusMsg = @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..restorehistory
				FROM msdb..restorehistory rh
				INNER JOIN msdb..backupset bs 
				ON rh.backup_set_id = bs.backup_set_id
				WHERE bs.backup_finish_date < (GETDATE() - @RetainDays)
				AND bs.database_name = @DBName
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				SELECT media_set_id, backup_finish_date
				INTO #Temp 
				FROM msdb..backupset
				WHERE backup_finish_date < (GETDATE() - @RetainDays)
				AND database_name = @DBName
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..backupfile
				FROM msdb..backupfile bf
				INNER JOIN msdb..backupset bs 
				ON bf.backup_set_id = bs.backup_set_id
				INNER JOIN #Temp t
				ON bs.media_set_id = t.media_set_id
				WHERE bs.backup_finish_date < (GETDATE() - @RetainDays)
				AND bs.database_name = @DBName
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..backupset
				FROM msdb..backupset bs
				INNER JOIN #Temp t
				ON bs.media_set_id = t.media_set_id
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..backupmediafamily
				FROM msdb..backupmediafamily bmf
				INNER JOIN msdb..backupmediaset bms 
				ON bmf.media_set_id = bms.media_set_id
				INNER JOIN #Temp t 
				ON bms.media_set_id = t.media_set_id
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
				DELETE FROM msdb..backupmediaset
				FROM msdb..backupmediaset bms
				INNER JOIN #Temp t 
				ON bms.media_set_id = t.media_set_id
				SET @StatusMsg= @@ERROR
				IF @StatusMsg<> 0
					GOTO Error_Exit
			COMMIT TRAN
			
			SET @RC = 0
			
			GOTO DeleteBackupHistory_Exit
			
			Error_Exit:
			
			ROLLBACK TRAN
			
			SET @RC = -1
			
			DeleteBackupHistory_Exit:
			
			DROP TABLE #Temp
			

			END

		IF @BackupAllDBs = 0
			GOTO NoCursor
		ELSE
			GOTO NextDB
		
FailedBackup:
		SELECT @StatusMsg = @StatusMsgPrefix + ' Error - ' + @Operation + ' Operation Failed for ' 
					+ @BackupType + ' Backup of ' + @DBName
print @RC
print @Cmd
		RAISERROR(@StatusMsg,17,1) WITH LOG
		IF @BackupAllDBs = 0
			GOTO NoCursor
		ELSE
			GOTO NextDB
NextDB:
		FETCH NEXT FROM DBs INTO @DBName, @dbid, @DBStatus
	END

CLOSE DBs
DEALLOCATE DBs

NoCursor:
RETURN









