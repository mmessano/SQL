----------------------------------------------------------------------------------------------------
-- OBJECT NAME		: dbm_BackupTranLogs
--
-- AUTHOR		: Tara Duggan
-- INPUTS		: @Path - location of the backups
-- OUTPUTS		: None
-- DEPENDENCIES	: None
--
-- DESCRIPTION          : This stored procedure performs a transaction log backup on the non-log
--        shipped user databases that do not have SIMPLE set as the recovery model.
--
-- EXAMPLES (optional)  : EXEC dbm_BackupTranLogs @Path = 'F:\MSSQL\Backup\'
--
-- MODIFICATION HISTORY :
----------------------------------------------------------------------------------------------------
--
----------------------------------------------------------------------------------------------------
CREATE        PROC dbm_BackupTranLogs
(@Path VARCHAR(100))
AS

SET NOCOUNT ON

DECLARE @Now CHAR(14)		-- current date in the form of yyyymmddhhmmss
DECLARE @DBName SYSNAME		-- stores the database name that is currently being processed
DECLARE @cmd SYSNAME		-- stores the dynamically created DOS command
DECLARE @Result INT			-- stores the result of the dir DOS command
DECLARE @RowCnt INT			-- stores @@ROWCOUNT
DECLARE @disk VARCHAR(200)	-- stores the path and file name of the TRN file

CREATE TABLE #WhichDatabase
(
 dbName SYSNAME NOT NULL
)

-- Get the list of the databases to be backed up
INSERT INTO #WhichDatabase (dbName)
SELECT [name]
	FROM master.dbo.sysdatabases
WHERE  [name] NOT IN ('master', 'model', 'msdb', 'tempdb')
	--AND [name] NOT IN (SELECT database_name FROM msdb.dbo.log_shipping_databases)
	AND DATABASEPROPERTYEX([name], 'Recovery') <> 'SIMPLE'
ORDER BY name

-- Get the database to be backed up
SELECT TOP 1 @DBName = dbName
	FROM #WhichDatabase

SET @RowCnt = @@ROWCOUNT

-- Iterate throught the temp table until no more databases need to be backed up
WHILE @RowCnt <> 0
BEGIN

 -- Get the current date using style 120, remove all dashes, spaces, and colons
 SELECT @Now = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(50), GETDATE(), 120), '-', ''), ' ', ''), ':', '')

 -- Build the .BAK path and file name
 SELECT @disk = @Path + @DBName + '\' + @DBName + '_' + @Now + '.TRN'

 -- Build the dir command that will check to see if the directory exists
 SELECT @cmd = 'dir ' + @Path + @DBName

 -- Run the dir command, put output of xp_cmdshell into @result
 EXEC @result = master.dbo.xp_cmdshell @cmd

 -- If the directory does not exist, we must create it
 IF @result <> 0
 BEGIN

  -- Build the mkdir command
  SELECT @cmd = 'mkdir ' + @Path + @DBName

  -- Create the directory
  EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT

 END
 -- The directory exists, so let's delete files older than two days
 ELSE
 BEGIN

  -- Stores the name of the file to be deleted
  DECLARE @WhichFile VARCHAR(1000)

  CREATE TABLE #DeleteOldFiles
  (
   DirInfo VARCHAR(7000)
  )

  -- Build the command that will list out all of the files in a directory
  SELECT @cmd = 'dir ' + @Path + @DBName + ' /OD'

  -- Run the dir command and put the results into a temp table
  INSERT INTO #DeleteOldFiles
  EXEC master.dbo.xp_cmdshell @cmd

  -- Delete all rows from the temp table except the ones that correspond to the files to be deleted
  DELETE
	FROM #DeleteOldFiles
	WHERE ISDATE(SUBSTRING(DirInfo, 1, 10)) = 0 OR DirInfo LIKE '%
%' OR SUBSTRING(DirInfo, 1, 10) >= GETDATE() - 2

  -- Get the file name portion of the row that corresponds to the file to be deleted
  SELECT TOP 1 @WhichFile = SUBSTRING(DirInfo, LEN(DirInfo) -  PATINDEX('% %', REVERSE(DirInfo)) + 2, LEN(DirInfo))
	FROM #DeleteOldFiles

  SET @RowCnt = @@ROWCOUNT

  -- Interate through the temp table until there are no more files to delete
  WHILE @RowCnt <> 0
  BEGIN

   -- Build the del command
   SELECT @cmd = 'del ' + @Path + + @DBName + '\' + @WhichFile + ' /Q /F'

   -- Delete the file
   EXEC master.dbo.xp_cmdshell @cmd, NO_OUTPUT

   -- To move to the next file, the current file name needs to be deleted from the temp table
   DELETE
	FROM #DeleteOldFiles
	WHERE SUBSTRING(DirInfo, LEN(DirInfo) -  PATINDEX('% %', REVERSE(DirInfo)) + 2, LEN(DirInfo))  = @WhichFile

   -- Get the file name portion of the row that corresponds to the file to be deleted
   SELECT TOP 1 @WhichFile = SUBSTRING(DirInfo, LEN(DirInfo) -  PATINDEX('% %', REVERSE(DirInfo)) + 2, LEN(DirInfo))
	FROM #DeleteOldFiles

   SET @RowCnt = @@ROWCOUNT

  END

  DROP TABLE #DeleteOldFiles

 END

 -- Backup the transaction log
 BACKUP LOG @DBName
	TO DISK = @disk
	WITH INIT

 -- To move onto the next database, the current database name needs to be deleted from the temp table
 DELETE
	FROM #WhichDatabase
	WHERE dbName = @DBName

 -- Get the database to be backed up
 SELECT TOP 1 @DBName = dbName
	FROM #WhichDatabase

 SET @RowCnt = @@ROWCOUNT

 -- Let the system rest for 5 seconds before starting on the next backup
 WAITFOR DELAY '00:00:05'

END

DROP TABLE #WhichDatabase

SET NOCOUNT OFF

RETURN 0

GO