CREATE FUNCTION [dbo].[fn_ConvertSecsToFormattedTime](
            @Seconds            DECIMAL(9,4), 
            @Verbose            BIT = 1,
            @NoMilliseconds     BIT = 0)
    RETURNS VARCHAR(64)
AS
-- ********************************************************************
--  Author         Simon Facer
--  Created        09/05/2008
--
--  Purpose        Convert a numeric seconds value to a Formatted Time 
--                  (Hours / Mins / Secs)
-- ********************************************************************

BEGIN
DECLARE @Hours      INT
DECLARE @Mins       INT
DECLARE @Secs       INT
DECLARE @Remainder  INT
DECLARE @Return     VARCHAR(64)

    SELECT @Seconds = ABS(@Seconds)

    SELECT @Hours = @Seconds / 3600

    SELECT @Seconds = @Seconds - (@Hours * 3600)

    SELECT @Mins = @Seconds / 60

    SELECT @Seconds = @Seconds - (@Mins * 60)

    SELECT @Secs = CAST(@Seconds AS INT)

    SELECT @Remainder = (@Seconds - @Secs) * 10000

    IF @Verbose = 0
        BEGIN
            SELECT @Return = CASE
                                WHEN @Hours > 0 THEN CAST(@Hours AS VARCHAR(3)) + ':'
                                ELSE '0:'
                             END +
                             CASE
                                WHEN @Mins > 9 THEN CAST(@Mins AS VARCHAR(2)) + ':'
                                WHEN @Mins > 0 THEN '0' + CAST(@Mins AS VARCHAR(1)) + ':'
                                ELSE '00:'
                             END +
                             CASE
                                WHEN @Secs > 9 THEN CAST(@Secs AS VARCHAR(2))
                                WHEN @Secs > 0 THEN '0' + CAST(@Secs AS VARCHAR(1))
                                ELSE '00'
                             END +
                             CASE 
                                WHEN @NoMilliseconds = 0 THEN '.' + RIGHT(('0000' + CAST(@Remainder AS VARCHAR(4))), 4)
                                ELSE ''
                             END
        END
    ELSE
        BEGIN
            SELECT @Return = CASE
                                WHEN @Hours > 1 THEN CAST(@Hours AS VARCHAR(3)) + ' Hrs, '
                                WHEN @Hours > 0 THEN CAST(@Hours AS VARCHAR(3)) + ' Hr, '
                                ELSE ''
                             END +
                             CASE
                                WHEN @Mins > 1 THEN CAST(@Mins AS VARCHAR(2)) + ' Mins, '
                                WHEN @Mins > 0 THEN CAST(@Mins AS VARCHAR(2)) + ' Min, '
                                ELSE ''
                             END +
                             CASE
                                WHEN @Secs > 0 THEN CAST(@Secs AS VARCHAR(2))
                                ELSE '0'
                             END +
                             CASE
                                WHEN @NoMilliseconds = 0 THEN '.' + RIGHT(('0000' + CAST(@Remainder AS VARCHAR(4))), 4) 
                                ELSE ''
                             END +
                             ' Secs'
        END

    RETURN @Return

END

GO
CREATE FUNCTION [dbo].[fn_DatabaseDetails] ()
RETURNS @retDBDetails TABLE 
        (DBName                 VARCHAR(64),
         StateDesc              VARCHAR(60),
         Recovery_Model_Desc    VARCHAR(60),
         LastFullBackupDate     DATETIME
        )    
-- --------------------------------------------------------------------------------------------------
--  FUNCTION    :   [fn_DatabaseDetails]
--  Description :   Retrieve database details.
--
-- --------------------------------------------------------------------------------------------------

AS

BEGIN

    INSERT @retDBDetails
        SELECT  d.[name],
                CASE 
                    WHEN d.[source_database_id] IS NOT NULL THEN 'SNAPSHOT'
                    ELSE d.state_desc
                END AS State_Desc,
                d.recovery_model_desc,
                MAX(b.backup_finish_date) AS FullBackupCompleted
            FROM master.sys.databases d
                LEFT OUTER JOIN [msdb].[dbo].[backupset] b
                    ON d.[name] = b.database_name
                    AND b.[type] = 'D'
            WHERE d.[name] != 'tempdb'
            GROUP BY d.[name],
                     d.[source_database_id],
                     d.[state_desc],
                     d.[recovery_model_desc]


    UPDATE @retDBDetails
        SET LastFullBackupDate = NULL
        WHERE DBName IN (SELECT r.DBName
                             FROM @retDBDetails r
                                 INNER JOIN master.sys.Databases d
                                     ON  r.DBName = d.[name]
                                     AND r.LastFullBackupDate < d.create_date)
    RETURN
END
GO


CREATE PROCEDURE [dbo].[pr_RebuildIndexes]
        (
            @DBGroup                    VARCHAR(16)   = NULL,
            @IncludeDBs                 VARCHAR(2048) = NULL,
            @ExcludeDBs                 VARCHAR(2048) = NULL,
            @RebuildFragLevel           INT           = 15,
            @ReorgFragLevel             INT           = 5,
            @RebuildOnline              BIT           = 0,
            @AllowOffline               BIT           = 0,
            @StopTime                   VARCHAR(10)   = NULL,
            @MaxProcessors              INT           = NULL,
            @LogIndexCommands           BIT           = 0,
            @LogCommandsOnly            BIT           = 0,
            @StopTimeoutHours           INT           = NULL )

AS
-- --------------------------------------------------------------------------------------------------
--  Procedure   :   [pr_RebuildIndexes]
--  Description :   To Rebuild or Reorg the indexes on a database or databases on a server
--  Parameters   DBGroup                The group of databases to process - System, User or All
--                                      OPTIONAL - defaults to NULL.
--               IncludeDBs             Databases to be included, Ignored if DBGroup set.
--                                      MUST be comma-separated.
--                                      OPTIONAL - defaults to NULL.
--                                      NOTE - Either DBGroup or IncludeDBs is REQUIRED.
--               ExcludeDBs             Databases to Exclude from DBGroup, ignored if IncludeDBs set.
--                                      MUST be comma-separated.
--                                      OPTIONAL - defaults to NULL.
--               RebuildFragLevel       Fragmentation Level that will trigger a Rebuild operation.
--                                      OPTIONAL - defaults to 15%.
--               ReorgFragLevel         Fragmentation Level that will trigger a Reorg operation.
--                                      OPTIONAL - defaults to 5%.
--               RebuildOnline          Switch to force use of ONLINE = ON if possible
--                                          Edition = Enterprise / Developer
--                                      OPTIONAL - defaults to 0 (No).
--               AllowOffline           Switch to determine if OffLine REBUILD commands can be run,
--                                      if not, and an Offline Rebuild would be executed, default
--                                      to running a Reorganize instead.
--                                      OPTIONAL - defaults to 0 (No).
--               StopTime               Time of day (24hour in hh:mm:ss format) to stop processing
--                                      Processing will stop as soon as the current operation is 
--                                      completed **AFTER** this time. An Index Rebuild / Reorganize
--                                      cannot be interrupted.
--                                      OPTIONAL - defaults to NULL (no stop time defined).
--               MaxProcessors          Equates to a MAXDOP clause on the REBUILD / REORGANIZE
--                                      statement, should be used with RebuildOnline=1, or if the  
--                                      Windows server is shared (other SQL instances / applications),
--                                      or if there are multiple databases on the server that will be
--                                      accessed while this routine is running.
--                                      OPTIONAL - defaults to NULL (no MAXDOP specified).
--               LogIndexCommands       Switch to determine if the Rebuild / Reorganize commands should 
--                                      be logged.
--                                      OPTIONAL - defaults to 0 (No).
--               LogCommandsOnly        Switch to determine if the Rebuild / Reorganize commands should
--                                      be run, setting this flag will default LogIndexCommands to YES.
--                                      If this flag is set, other detailed logging is prevented.
--                                      OPTIONAL - defaults to 0 (No).
--               StopTimeoutHours       Period from start time to stop processing, in hours,
--                                      If StopTime is passed, this parameter is ignored.
--                                      OPTIONAL - defaults to NULL (no stop timeout defined).
--                                      Processing will stop as soon as the current operation is 
--                                      completed **AFTER** this timeout. An Index Rebuild / Reorganize
--                                      cannot be interrupted.
--
-- --------------------------------------------------------------------------------------------------

BEGIN

SET NOCOUNT ON

    -- ******************************************************************************************
    -- Declare the Local Variables
    DECLARE @DBName                 VARCHAR(64)
    DECLARE @SQLCmd                 VARCHAR(2048)
    DECLARE @IndexID                INT
    DECLARE @TableID                INT
    DECLARE @IndexName              SYSNAME
    DECLARE @ObjectName             SYSNAME
    DECLARE @SchemaName             SYSNAME
    DECLARE @IndexType              VARCHAR(32)
    DECLARE @PartitionNum           VARCHAR(16)
    DECLARE @PartitionCount         BIGINT
    DECLARE @CurrentDensity         DECIMAL(38, 10)
    DECLARE @CurrentFrag            DECIMAL(38, 10)

    DECLARE @SQLEdition             VARCHAR(64)
    DECLARE @ProcStartTime          DATETIME
    DECLARE @DBStartTime            DATETIME
    DECLARE @ProcessStartTime       DATETIME
    DECLARE @ProcessingLimitTime    DATETIME
    DECLARE @StopTimeWork           VARCHAR(32)
    DECLARE @LobData                BIT
    DECLARE @ForceReorg             BIT

    -- These variables are used in SP_EXECUTE SQL calls.
    DECLARE @SPEX_BitFlag           BIT
    DECLARE @SPEX_Int               INT
    DECLARE @SPEX_ParmStr           NVARCHAR(256)
    DECLARE @SPEX_SQLCmd            NVARCHAR(1024)
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Validate the passed parameters
    -- (1) Required parameters
    IF ( @DBGroup IS NULL
    AND (@IncludeDBs IS NULL OR LTRIM(RTRIM(@IncludeDBs)) = '')
           )
        BEGIN
            SELECT  '** ERROR ** Parameter DBGroup or IncludeDBs must be passed in'
            RAISERROR ('Parameter DBGroup or IncludeDBs must be passed in', 16, 1)
            RETURN
        END

    -- (2) Valid DBGroup
    IF @DBGroup IS NOT NULL
        BEGIN
            IF @DBGroup != 'System' AND
               @DBGroup != 'User' AND
               @DBGroup != 'All'
                BEGIN
                    PRINT '** ERROR ** Parameter DBGroup must be System, User or All'
                    RAISERROR ('Parameter DBGroup must be either System, User or All', 16, 1)
                    RETURN
                END
        END

    -- (3) Rebuild fragmentation level must be entered
    IF @RebuildFragLevel IS NULL
        BEGIN
            PRINT '** ERROR ** Parameter RebuildFragLevel must be entered'
            RAISERROR ('Parameter RebuildFragLevel must be entered', 16, 1)
            RETURN
        END

    -- (4) Reorg fragmentation level must be entered
    IF @ReorgFragLevel IS NULL
        BEGIN
            PRINT '** ERROR ** Parameter ReorgFragLevel must be entered'
            RAISERROR ('Parameter ReorgFragLevel must be entered', 16, 1)
            RETURN
        END

    -- (5) Rebuild fragmentation level must be >= Reorg fragmentation level 
    IF @RebuildFragLevel < @ReorgFragLevel
        BEGIN
            PRINT '** ERROR ** Parameter RebuildFragLevel must be >= ReorgFragLevel'
            RAISERROR ('Parameter RebuildFragLevel must be >= ReorgFragLevel', 16, 1)
            RETURN
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If StopTime wasnt passed, and StopTimeoutHours was passed, 
    --  (1) Validate that the StopTimeoutHours value is <= 12,
    --  (2) Generate the StopTime value.
    IF (@StopTime IS NOT NULL AND 
        LTRIM(RTRIM(@StopTime)) != '')
    AND (@StopTimeoutHours IS NOT NULL)
        BEGIN
            PRINT '** StopTime parameter passed in, StopTimeoutHours is being ignored'
        END

    IF (@StopTime IS NULL OR 
        LTRIM(RTRIM(@StopTime)) = '')
    AND (@StopTimeoutHours IS NOT NULL)
        BEGIN
            IF @StopTimeoutHours > 12 OR
               @StopTimeoutHours < 1
                BEGIN
                    PRINT '** Passed value for StopTimeoutHours (' + CAST(@StopTimeoutHours AS VARCHAR(6)) + ') is not valid.'
                    PRINT '   Value must be between 1 and 12.'
                    PRINT '   Aborting Processing.'
                    RAISERROR ('Parameter StopTimeoutHours is invalid', 16, 1)        
                    RETURN    
                END
            ELSE
                BEGIN
                    SELECT @StopTime = CONVERT(VARCHAR(5), DATEADD(HOUR, @StopTimeoutHours, GETDATE()), 114)
                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Calculate the stop time, if passed in
    IF @StopTime IS NOT NULL AND
       LTRIM(RTRIM(@StopTime)) != ''
        BEGIN
            SELECT @StopTimeWork = CONVERT(VARCHAR(10), GETDATE(), 101) + ' ' + @StopTime
            IF ISDATE(@StopTimeWork) = 1
                BEGIN
                    SELECT @ProcessingLimitTime = CAST(@StopTimeWork AS DATETIME)
                    IF @ProcessingLimitTime < GETDATE()
                        BEGIN
                            SELECT @ProcessingLimitTime = DATEADD(DAY, 1, @ProcessingLimitTime)                            
                        END
                    PRINT '** Stop Processing Time set to: ' + 
                           CONVERT(VARCHAR(10), @ProcessingLimitTime, 101) + ' ' + CONVERT(VARCHAR(10), @ProcessingLimitTime, 108) 
                END
            ELSE
                BEGIN
                    PRINT '** Passed value for StopTime (' + @StopTime + ') is not valid.'
                    PRINT '   Please enter time in HH:MM (24-hour, no AM/PM, or 12-hour with AM/PM) format,'
                    PRINT '   e.g. 6:00 or 6:00am, 23:15 or 11:15pm.'
                    PRINT '   Aborting Processing.'
                    RAISERROR ('Parameter StopTime is invalid', 16, 1)        
                    RETURN    
                END
        END
    SELECT @StopTimeWork = NULL
    -- ******************************************************************************************
 
    -- ******************************************************************************************
    -- If RebuildOnline is specified, and this is NOT Enterprise or Developer edition,
    -- reset the switch to 0.
    SELECT @SQLEdition = CAST(SERVERPROPERTY ('Edition') AS VARCHAR(64))
    IF @RebuildOnline = 1 AND
       CHARINDEX('Developer', @SQLEdition) = 0 AND
       CHARINDEX('Enterprise', @SQLEdition) = 0
        BEGIN
            PRINT REPLICATE('*', 120)
            PRINT '** Resetting @RebuildOnline switch to 0 (No). '
            PRINT '   This switch is only valid for Enterprise and Developer editions of SQL Server'
            PRINT '   Current version is: ' + CAST(SERVERPROPERTY ('Edition') AS VARCHAR(64))
            PRINT REPLICATE('*', 120)
            SELECT @RebuildOnline = 0
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If LogOnly is set, make sure we are actually logging something ...
    IF @LogCommandsOnly = 1
        BEGIN
            SELECT @LogIndexCommands = 1
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Set the MaxProcessors value.
    -- Parallel processing of Indexes is ONLY allowed in Enterprise and Developer editions.
    IF CHARINDEX('Developer', @SQLEdition) = 0 AND
       CHARINDEX('Enterprise', @SQLEdition) = 0 AND 
       @MaxProcessors IS NOT NULL
        BEGIN
            PRINT REPLICATE('*', 120)
            PRINT '** Resetting @MaxProcessors switch to NULL (not set). '
            PRINT '   This switch is only valid for Enterprise and Developer editions of SQL Server'
            PRINT '   Current version is: ' + CAST(SERVERPROPERTY ('Edition') AS VARCHAR(64))
            PRINT REPLICATE('*', 120)
            SELECT @MaxProcessors = NULL
        END
    IF @MaxProcessors IS NOT NULL AND
       @MaxProcessors < 0
        BEGIN
            PRINT REPLICATE('*', 120)
            PRINT '** Resetting @MaxProcessors switch to NULL (not set). '
            PRINT '   The entered value (' + CAST(@MaxProcessors AS VARCHAR(5)) + ') is not valid.'
            PRINT REPLICATE('*', 120)
            SELECT @MaxProcessors = NULL
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Print the Log file Headers
    PRINT '-- Starting Index Defrag at ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)
    IF @LogCommandsOnly = 1
        BEGIN
            PRINT '>>>>> ' + REPLICATE('+', 114)
            PRINT '>>>>> Flag LogCommandsOnly = 1 (YES).'
            PRINT '>>>>> Indexes will NOT be processed.'
            PRINT '>>>>> This execution will only Log the commands that would have been executed.'
            PRINT '>>>>> ' + REPLICATE('+', 114)
        END
    PRINT '-- ' + REPLICATE ('=', 117)
    SELECT @ProcStartTime = GETDATE()
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Create the # temp table to identify the databases to be processed
    CREATE TABLE #Databases(
        DBName                      VARCHAR(64),
        StateDesc                   VARCHAR(60),
        Recovery_Model_Desc         VARCHAR(60),
        LastFullBackupDate          DATETIME )
    -- ******************************************************************************************

    -- ******************************************************************************************
    CREATE TABLE #Indexes(
        IndexID		                INT             NOT NULL,
        IndexName		            VARCHAR(255)    NULL,
        TableName		            VARCHAR(255)    NULL,
        TableID		                INT             NOT NULL,
        SchemaName		            VARCHAR(255)    NULL,
        IndexType		            VARCHAR(18)     NOT NULL,
        PartitionNumber	            VARCHAR(18)     NOT NULL,
        PartitionCount		        INT             NULL,
        CurrentDensity		        FLOAT           NOT NULL,
        CurrentFragmentation	    FLOAT           NOT NULL)
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- Process any IncludeDBs data to add '[' and ']' values.
    SELECT @IncludeDBs = '[' + REPLACE(@IncludeDBs, ',', '],[') + ']'
    WHILE CHARINDEX('[ ', @IncludeDBs) > 0 
        BEGIN
            SELECT @IncludeDBs = REPLACE(@IncludeDBs, '[ ', '[')
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Process any ExcludeDBs data to add '[' and ']' values.
    SELECT @ExcludeDBs = '[' + REPLACE(@ExcludeDBs, ',', '],[') + ']'
    WHILE CHARINDEX('[ ', @ExcludeDBs) > 0 
        BEGIN
            SELECT @ExcludeDBs = REPLACE(@ExcludeDBs, '[ ', '[')
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Populate the #Databases table with all the databases on the server
    -- NOTE - [fn_DatabaseDetails] is specific to the SQL Version.
    INSERT #Databases
        SELECT *
            FROM [dbo].[fn_DatabaseDetails] ()
    -- ******************************************************************************************
    
    -- ******************************************************************************************
    -- If a Group was specified, filter the database names
    IF @DBGroup IS NOT NULL
        BEGIN
            IF @DBGroup = 'System'
                BEGIN
                    DELETE #Databases
                        WHERE DBName NOT IN ('master', 'model', 'msdb')
                END

            ELSE  
                BEGIN
                    IF @DBGroup = 'User'
                        BEGIN
                            DELETE #Databases
                                WHERE DBName IN ('master', 'model', 'msdb')
                        END
                END

            IF @ExcludeDBs IS NOT NULL AND
               LTRIM(RTRIM(@ExcludeDBs)) != ''
                BEGIN
                    DELETE #Databases
                        WHERE CHARINDEX(('[' + DBName + ']'), @ExcludeDBs) > 0
                END
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If a list of databases to include was specified and a DBGroup wasn't, process the 
    -- include list.
    IF @DBGroup IS NULL AND
       (LTRIM(RTRIM(@IncludeDBs)) != '')
        BEGIN
            DELETE #Databases
                WHERE CHARINDEX(('[' + DBName + ']'), @IncludeDBs) = 0
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If the Cursor is already open, close it.
    IF CURSOR_STATUS('LOCAL', 'csrDatabases') >= 0
        BEGIN
            CLOSE csrDatabases
            DEALLOCATE csrDatabases
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Define the Cursor to loop through the databases and back them up.
    DECLARE csrDatabases CURSOR LOCAL FOR
        SELECT DBName
            FROM #Databases
            ORDER BY DBName
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Open the Cursor, and retrieve the first value
    OPEN csrDatabases
    FETCH NEXT FROM csrDatabases
        INTO @DBName
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Loop through the databases
    WHILE @@FETCH_STATUS = 0
        BEGIN
    -- ==========================================================================================

            -- ******************************************************************************************
            -- Log the database processing start time
            PRINT '>> ' + REPLICATE ('-', 117)
            PRINT '>> ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)  + 
                  ' - Started Processing DB: [' + @DBName + ']'
            SELECT @DBStartTime = GETDATE()
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Check the database is available
            IF DATABASEPROPERTYEX(@DBName, 'Status') != N'ONLINE' OR
               DATABASEPROPERTYEX(@DBName, 'Updateability') != N'READ_WRITE' OR
               DATABASEPROPERTYEX(@DBName, 'UserAccess') != N'MULTI_USER'
                BEGIN
                    PRINT '   -- Unable to process database ' + @DBName + ', status is ' +
                        CAST(DATABASEPROPERTYEX(@DBName, 'Status') AS VARCHAR(16)) + ' / ' + 
                        CAST(DATABASEPROPERTYEX(@DBName, 'Updateability') AS VARCHAR(16)) + ' / ' + 
                        CAST(DATABASEPROPERTYEX(@DBName, 'UserAccess') AS VARCHAR(16))
                    PRINT '   -- Status must be ONLINE / READ_WRITE / MULTI_USER'
                    GOTO ProcessNextDatabase
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Clear the Index table to remove any data from a previous loop
            DELETE #Indexes
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Load the Index table with the metadata for the current database
            --  Only tables > 512 pages are processed (4MB)
            --  Only tables indexes with > ReorgFragLevel fragmentation are processed
            INSERT INTO #Indexes(
                    IndexID, 
                    TableID, 
                    IndexType, 
                    PartitionNumber, 
                    CurrentDensity, 
                    CurrentFragmentation)
                SELECT  ips.index_id,
                        ips.OBJECT_ID, 
                        ips.index_type_desc AS IndexType,
                        CAST(ips.partition_number AS VARCHAR(10)),
                        ips.avg_page_space_used_in_percent,
                        ips.avg_fragmentation_in_percent
                    FROM sys.dm_db_index_physical_stats(DB_ID(@DBName), NULL, NULL, NULL, 'SAMPLED') AS ips
                    WHERE ips.avg_fragmentation_in_percent > @ReorgFragLevel 
                     AND  ips.page_count> 512
                     AND  ips.index_id > 0
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Populate the index names, schema names, table names and partition counts.
            SELECT @SQLCmd =    'UPDATE #Indexes ' + 
                                    'SET TableName = t.name, ' + 
                                    '    SchemaName = s.name, ' + 
                                    '    IndexName = i.Name, ' + 
                                    '    PartitionCount = (SELECT COUNT(*) ' + 
                                    '                          FROM [' + @DBName + '].sys.partitions p ' + 
                                    '                          WHERE  p.object_id = w.TableID ' + 
                                    '                           AND  p.index_id = w.Indexid) ' + 
                                    ' FROM [' + @DBName + '].sys.tables t ' + 
                                    '     INNER JOIN ['	+ @DBName + '].sys.schemas s ' + 
                                    '         ON t.schema_id = s.schema_id ' + 
                                    '     INNER JOIN #Indexes w ' + 
                                    '         ON t.object_id = w.tableid ' + 
                                    '     INNER JOIN ['	+ @DBName + '].sys.indexes i ' + 
                                    '         ON  w.tableid = i.object_id ' + 
                                    '         AND w.indexid = i.index_id'
            EXEC (@SQLCmd)
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Add delimiters to Schema, Table and Index names
            UPDATE #Indexes 
                SET TableName = '[' + TableName + ']',
                    SchemaName = '[' + SchemaName + ']',
                    IndexName = '[' + IndexName + ']'
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If the Cursor is already open, close it.
            IF CURSOR_STATUS('LOCAL', 'csrIndexes') >= 0
                BEGIN
                    CLOSE csrIndexes
                    DEALLOCATE csrIndexes
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Define the Cursor to loop through the indexes to be processed
            DECLARE csrIndexes CURSOR LOCAL FOR
                SELECT  i.IndexID,
                        i.TableID,
                        CASE 
                            WHEN i.IndexType = 'Clustered Index' THEN 'ALL' 
                            ELSE i.IndexName 
                        END AS IndexName,
                        i.TableName,
                        i.SchemaName,
                        i.IndexType,
                        i.PartitionNumber,
                        i.PartitionCount,
                        i.CurrentDensity,
                        i.CurrentFragmentation
                    FROM #Indexes i
                    WHERE NOT EXISTS(SELECT 1 
	                                     FROM #Indexes i2
                                         WHERE i2.TableName = i.TableName 
                                          AND  i2.IndexType = 'CLUSTERED INDEX' 
                                          AND  i.IndexType = 'NONCLUSTERED INDEX')
                    ORDER BY i.TableName, 
                             i.IndexID
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Open the Cursor, and retrieve the first value
            OPEN csrIndexes
            FETCH NEXT FROM csrIndexes
                INTO    @IndexID, 
                        @TableID, 
                        @IndexName, 
                        @ObjectName, 
                        @SchemaName, 
                        @IndexType, 
                        @PartitionNum, 
                        @PartitionCount, 
                        @CurrentDensity, 
                        @CurrentFrag
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Loop through the Indexes
            WHILE @@FETCH_STATUS = 0
                BEGIN
            -- ==========================================================================================

                    -- ******************************************************************************************
                    -- Log the start of the Index Processing
                    IF @LogCommandsOnly = 0
                        BEGIN
                            PRINT ' >>>> ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)  + 
                                  ' - Started Processing Index: ' + @SchemaName + '.' + @ObjectName + '.' + @IndexName + ''
                        END
                    SELECT @ProcessStartTime = GETDATE()

                    SELECT @SQLCmd = ''
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- If the index is disabled, ignore it
                    SET @SPEX_ParmStr = N'@pSPEX_BitFlag BIT OUTPUT'
                    SET @SPEX_SQLCmd = N'SELECT @pSPEX_BitFlag = is_disabled ' +
                                       N'    FROM [' + @DBName + '].sys.indexes ' +
                                       N'    WHERE object_id = ' + CAST(@TableID AS VARCHAR(50)) +
                                       N'     AND  index_id = ' + CAST(@IndexID AS VARCHAR(50))
                    EXECUTE sp_executesql @SPEX_SQLCmd, @SPEX_ParmStr, @pSPEX_BitFlag = @SPEX_BitFlag OUTPUT
                    IF @SPEX_BitFlag = 1
                        BEGIN
                            IF @LogCommandsOnly = 0
                                BEGIN
                                    PRINT ' ----' + REPLICATE (' ', 23) + 'Index is OFFLINE, it is being skipped' 
                                END
                            GOTO ProcessNextIndex
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- If the table contains LOB Data, REBUILD WITH (ONLINE = ON) is not allowed.
                    SELECT @LobData = 0
                    IF @RebuildOnline = 1 AND
                       @CurrentFrag >= @RebuildFragLevel
                        BEGIN
                            SET @SPEX_ParmStr = N'@pSPEX_Int INT OUTPUT'
                            SET @SPEX_SQLCmd = N'SELECT @pSPEX_Int = COUNT(alloc_unit_type_desc) ' +
                                               N'    FROM sys.dm_db_index_physical_stats (DB_ID(''' + @DBName + '''), NULL, NULL , NULL, ''LIMITED'') ' +
                                               N'    WHERE object_id = ' + CAST(@TableID AS VARCHAR(50)) +
                                               N'     AND alloc_unit_type_desc = ''LOB_DATA'''
                            EXECUTE sp_executesql @SPEX_SQLCmd, @SPEX_ParmStr, @pSPEX_Int = @SPEX_Int OUTPUT
                            IF @SPEX_Int > 0 
                                BEGIN
                                    PRINT ' ----' + REPLICATE (' ', 23) + 'Table contains LOB data, Online Rebuild is not permitted, falling back to Offline'
                                    SELECT @LobData = 1
                                END
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Build the SQL String for a REBUILD operation
                    SELECT @SQLCmd = NULL
                    IF @CurrentFrag >= @RebuildFragLevel
                        BEGIN
                            IF @LogCommandsOnly = 0
                                BEGIN
                                    PRINT ' ----' + REPLICATE (' ', 23) + 'Fragmentation: ' + CAST(CAST(@CurrentFrag AS DECIMAL(9,4)) AS VARCHAR(16)) + '% / REBUILD'
                                END
                            SELECT @SQLCmd = 'USE [' + @DBName + '];' + 
                                             'ALTER INDEX ' + @IndexName + ' ON ' + @SchemaName + '.' + @ObjectName + ' ' +
                                             'REBUILD' +
                                             CASE 
                                                 WHEN (@RebuildOnline = 0 OR @LobData = 1) AND
                                                      @MaxProcessors IS NOT NULL
                                                     THEN ' WITH (MAXDOP = ' + CAST(@MaxProcessors AS VARCHAR(2)) + ');'
                                                 WHEN @RebuildOnline = 1 AND
                                                      @MaxProcessors IS NOT NULL
                                                     THEN ' WITH (ONLINE = ON, MAXDOP = ' + CAST(@MaxProcessors AS VARCHAR(2)) + ');'
                                                 WHEN @RebuildOnline = 1 AND
                                                      @MaxProcessors IS NULL
                                                     THEN ' WITH (ONLINE = ON);'
                                                 ELSE ';'
                                             END
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- If a Rebuild Command has been constructed, and OffLine rebuilds are not allowed, and
                    -- this isnt an Online rebuild, default to a reorganize...
                    SELECT @ForceReorg = 0
                    IF @SQLCmd IS NOT NULL AND
                       @AllowOffline = 0 AND 
                       CHARINDEX('ONLINE', @SQLCmd) = 0
                        BEGIN
                            SELECT @ForceReorg = 1
                            IF @LogCommandsOnly = 0
                                BEGIN
                                    PRINT ' ----' + REPLICATE (' ', 23) + 'OFFLINE Rebuilds are not allowed, falling back to a REORGANIZE'
                                END
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Build the SQL String for a REORGANIZE operation
                    IF (@CurrentFrag < @RebuildFragLevel AND
                        @CurrentFrag >= @ReOrgFragLevel)
                    OR (@ForceReorg = 1 AND
                        @CurrentFrag >= @ReOrgFragLevel)
                        BEGIN
                            IF @LogCommandsOnly = 0
                                BEGIN
                                    PRINT ' ----' + REPLICATE (' ', 23) + 'Fragmentation: ' + CAST(CAST(@CurrentFrag AS DECIMAL(9,4)) AS VARCHAR(16)) + '% / REORGANIZE'
                                END
                            SELECT @SQLCmd = 'USE ' + @DBName + ';' + 
                                             'ALTER INDEX ' + @IndexName + ' ON ' + @SchemaName + '.' + @ObjectName + ' ' +
                                             'REORGANIZE;'
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Log data ...
                    IF @LogCommandsOnly = 1
                        BEGIN
                            PRINT '  Index: ' + @ObjectName + '.[' + @IndexName + '], ' +
                                  'Fragmentation Level: ' + CAST(CAST(@CurrentFrag AS DECIMAL(9,4)) AS VARCHAR(16))
                        END
                    IF @LogIndexCommands = 1
                        BEGIN
                            PRINT '  ' + @SQLCmd
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Execute the REBUILD or REORGANIZE command
                    IF @LogCommandsOnly = 0
                        BEGIN
                            BEGIN TRY
                                EXEC (@SQLCmd)
                            END TRY
                            BEGIN CATCH
                                PRINT REPLICATE('*', 100)
                                PRINT '** ERROR executing command:'
                                PRINT '** <' + @SQLCmd + '>'
                                PRINT '** Error: Number   <' + CAST(ERROR_NUMBER() AS VARCHAR(16))
                                PRINT '** Error: Message  <' + CAST(ERROR_MESSAGE() AS VARCHAR(MAX))
                                PRINT REPLICATE('*', 100)
                            END CATCH
                        END
                    -- ******************************************************************************************


                    -- ******************************************************************************************
                    -- Log the end of the Index Processing
ProcessNextIndex:
                    IF @LogCommandsOnly = 0
                        BEGIN
                            PRINT ' ---- ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)  + 
                                  ' - Completed Processing Index: ' + @SchemaName + '.' + @ObjectName + '.' + @IndexName + ''
                            PRINT ' ----' + REPLICATE (' ', 23) + 'Time Taken: ' + dbo.fn_ConvertSecsToFormattedTime ((CAST(DATEDIFF(ms, @ProcessStartTime, GETDATE()) AS DECIMAL(16,6)) / 1000), 1, 0)
                        END
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- Retrieve the next value from the Index Cursor
                    FETCH NEXT FROM csrIndexes
                        INTO    @IndexID, 
                                @TableID, 
                                @IndexName, 
                                @ObjectName, 
                                @SchemaName, 
                                @IndexType, 
                                @PartitionNum, 
                                @PartitionCount, 
                                @CurrentDensity, 
                                @CurrentFrag
                    -- ******************************************************************************************

                    -- ******************************************************************************************
                    -- If a Stop Time was entered, and we have passed it, Stop Processing.
                    IF @ProcessingLimitTime IS NOT NULL AND
                       @ProcessingLimitTime < GETDATE()
                        BEGIN
                            SELECT @StopTimeWork = 'Expired'
                            BREAK
                        END
                    -- ******************************************************************************************

            -- ==========================================================================================
                END
            -- End of the Index Loop
            -- ******************************************************************************************

ProcessNextDatabase:
            -- ******************************************************************************************
            -- Log the end of the DB Processing
            IF @LogCommandsOnly = 0
                BEGIN
                    PRINT ' -- ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)  + 
                          ' - Completed Processing DB: [' + @DBName + ']'
                    PRINT ' --' + REPLICATE (' ', 23) + 'Time Taken: ' + dbo.fn_ConvertSecsToFormattedTime ((CAST(DATEDIFF(ms, @DBStartTime, GETDATE()) AS DECIMAL(16,6)) / 1000), 1, 0) + CHAR(10) + CHAR(13)
                    PRINT '>> ' + REPLICATE ('-', 117)
                END
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- Retrieve the next value from the Database Cursor
            FETCH NEXT FROM csrDatabases
                INTO @DBName
            -- ******************************************************************************************

            -- ******************************************************************************************
            -- If a Stop Time was entered, and we have passed it, Stop Processing.
            IF @ProcessingLimitTime IS NOT NULL AND
               @ProcessingLimitTime < GETDATE()
                BEGIN
                    SELECT @StopTimeWork = 'Expired'
                    BREAK
                END
            -- ******************************************************************************************

    -- ==========================================================================================
        END
    -- End of the Database Loop
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Close and Deallocate the Cursor
    CLOSE csrDatabases
    DEALLOCATE csrDatabases
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- If Processing was stopped due to an Expired Stop Time, log a message
    IF @StopTimeWork IS NOT NULL
        BEGIN
            PRINT '** Stop Processing Time has expired. (' +
                  CONVERT(VARCHAR(10), @ProcessingLimitTime, 101) + ' ' + CONVERT(VARCHAR(10), @ProcessingLimitTime, 108)  + ')'
            PRINT '   The remaining processing is being aborted'
        END
    -- ******************************************************************************************

    -- ******************************************************************************************
    -- Print the Log file Trailers
    PRINT '-- ' + REPLICATE ('=', 117)
    PRINT '-- Completed Index Defrag at ' + CONVERT (VARCHAR(20), GETDATE(), 101) + ' '  + CONVERT (VARCHAR(20), GETDATE(), 108)
    PRINT '-- Total Time Taken: ' + dbo.fn_ConvertSecsToFormattedTime ((CAST(DATEDIFF(ms, @ProcStartTime, GETDATE()) AS DECIMAL(16,6)) / 1000), 1, 0)
    -- ******************************************************************************************

END

