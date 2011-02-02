DECLARE @TDPath varchar(256)
DECLARE @OutFile varchar(32)
DECLARE @SQL varchar(256)
DECLARE @SQLCMD varchar(256)
DECLARE @DEL varchar(32)
DECLARE @File_Exists int

DECLARE @SourceServer varchar(32)
DECLARE @SourceDatabase varchar(64)
DECLARE @SourceTable varchar(10)
DECLARE @DestinationServer varchar(32)
DECLARE @DestinationDatabase varchar(64)
DECLARE @DestinationTable varchar(10)

SET @TDPath = '"C:\Program Files\Microsoft SQL Server\90\COM\tablediff.exe"'
SET @OutFile = 'E:\Dexma\Temp\SyncStatus'

-- FROM
SET @SourceServer = 'OSQLUTIL12'
SET @SourceDatabase = 'Status'
SET @SourceTable = 't_server'
-- TO
SET @DestinationServer = 'STGSQLCBS510'
SET @DestinationDatabase = 'StatusStage'
SET @DestinationTable = 't_server'


-- Run TableDiff and generate a sql file with differences(if any)
SELECT @SQL = @TDPath + ' -sourceserver ' + @SourceServer + ' -sourcedatabase ' + @SourceDatabase + ' -sourcetable ' + @SourceTable + ' -destinationserver ' + @DestinationServer + ' -destinationdatabase ' + @DestinationDatabase + ' -destinationtable ' + @DestinationTable + ' -f ' + @OutFile + ''

EXEC master..xp_cmdshell @SQL

-- Test for file creation
SET NOCOUNT ON

SELECT @OutFile = @OutFile + '.sql'
EXEC Master.dbo.xp_fileexist @OutFile, @File_Exists OUT
IF @File_Exists = 1
BEGIN 
	PRINT 'File Found: ' + @OutFile
	
	SELECT @SQLCMD = 'sqlcmd -S ' + @DestinationServer + ' -d ' + @DestinationDatabase + ' -i ' + @OutFile
	SELECT @DEL = 'del ' + @OutFile
	
	EXEC master..xp_cmdshell @SQLCMD
	EXEC master..xp_cmdshell @DEL
END

ELSE 
BEGIN
	PRINT 'File not found, nothing to do.'
END

