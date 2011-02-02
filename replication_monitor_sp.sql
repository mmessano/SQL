USE dbamaint
GO

IF OBJECT_ID('dbo.ReplicationMonitor') IS NULL
BEGIN
    CREATE TABLE dbo.ReplicationMonitor
    ( 
          MonitorID            INT IDENTITY(1,1)   Not Null
        , MonitorDate          SMALLDATETIME       Not Null
        , PublicationName      sysname             Not Null
        , PublicationDB        sysname             Not Null
        , Iteration            INT                 Null
        , TracerID             INT                 Null
        , DistributorLatency   INT                 Null
        , Subscriber           VARCHAR(1000)       Null
        , SubscriberDB         VARCHAR(1000)       Null
        , SubscriberLatency    INT                 Null
        , OverallLatency       INT                 Null 
    );
END;

/****** Object:  StoredProcedure [dbo].[dbm_ReplicationLatencyMonitor]    Script Date: 08/31/2009 17:14:42 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dbm_ReplicationLatencyMonitor]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dbm_ReplicationLatencyMonitor]
GO

USE [dbamaint]
GO

/****** Object:  StoredProcedure [dbo].[dbm_ReplicationLatencyMonitor]    Script Date: 08/31/2009 17:14:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [dbo].[dbm_ReplicationLatencyMonitor]
         /* Declare Parameters */
          @publicationToTest    sysname        = N'yourPublicationName'
        , @publicationDB        sysname        = N'yourPublicationDB'
        , @replicationDelay     VARCHAR(10)    = N'00:00:30'
        , @iterations           INT            = 5
        , @iterationDelay       VARCHAR(10)    = N'00:00:30'
        , @displayResults       BIT            = 0
        , @deleteTokens         BIT            = 1
        , @trimResults			BIT			   = 0
AS
/*********************************************************************************
    Name:       dbm_ReplicationLatencyMonitor
    Author:     Michelle F. Ufford
    Purpose:    Retrieves the amount of replication latency in seconds
    Notes:      Default settings will run 1 test every minute for 5 minutes.
                @publicationToTest = defaults to yourPublicationName publication
                @publicationDB = the database that is the source for the publication.
				    The tracer procs are found in the publishing DB.
                @replicationDelay = how long to wait for the token to replicate;
                    probably should not set to anything less than 10 (in seconds)
                @iterations = how many tokens you want to test
                @iterationDelay = how long to wait between sending test tokens
                    (in seconds)
                @displayResults = print results to screen when complete
                @deleteTokens = whether you want to retain tokens when done
 
    Called by:  DBA
 
    Date        Initials    Description
    ----------------------------------------------------------------------------
    2008-11-20   MFU        Initial Release
    2008-11-24	 ILK        Tweaked to allow for centralized execution 
                            Replaced temp table with permanent table.
    2008-11-25   MFU        More tweaking, added publication data to 
                            ReplicationMonitor, fixed NULL latency data,
                            moved ReplicationMonitor creation out of proc
*********************************************************************************
    Exec dbo.dbm_ReplicationLatencyMonitor
          @publicationToTest    = N'myTestPublication'
        , @publicationDB        = N'sandbox_publisher'
        , @replicationDelay     = N'00:00:05'
        , @iterations           = 1
        , @iterationDelay       = N'00:00:05'
        , @displayResults       = 1
        , @deleteTokens         = 1;
*********************************************************************************/
 
SET NOCOUNT ON;
SET XACT_Abort ON;
 
BEGIN
 
    /* Declare Variables */
    DECLARE @currentIteration   INT
          , @tokenID            BIGINT
          , @currentDateTime    SMALLDATETIME
          , @sqlStatement       NVARCHAR(200)
          , @parmDefinition		NVARCHAR(500);
 
    DECLARE @tokenResults TABLE
    ( 
          Iteration             INT             Null
        , TracerID              INT             Null
        , DistributorLatency    INT             Null
        , Subscriber            VARCHAR(1000)   Null
        , SubscriberDB          VARCHAR(1000)   Null
        , SubscriberLatency     INT             Null
        , OverallLatency        INT             Null 
    );
 
    /* Initialize our variables */
    SELECT @currentIteration = 0
         , @currentDateTime  = GETDATE();
 
    WHILE @currentIteration < @iterations
    BEGIN
 
		/* Prepare the stored procedure execution string */
		SET @sqlStatement = N'Execute ' + @publicationDB + N'.sys.sp_postTracerToken ' + 
							N'@publication = @VARpublicationToTest , ' +
							N'@tracer_token_id = @VARtokenID OutPut;'
 
		/* Define the parameters used by the sp_ExecuteSQL later */
		SET @parmDefinition = N'@VARpublicationToTest sysname, ' +
			N'@VARtokenID bigint OutPut';
 
        /* Insert a new tracer token in the publication database */
        EXECUTE SP_EXECUTESQL 
              @sqlStatement
            , @parmDefinition
            , @VARpublicationToTest = @publicationToTest
            , @VARtokenID = @TokenID OUTPUT;
 
        /* Give a few seconds to allow the record to reach the subscriber */
        WAITFOR Delay @replicationDelay;
 
        /* Prepare our statement to retrieve tracer token data */
        SELECT @sqlStatement = 'Execute ' + @publicationDB + '.sys.sp_helpTracerTokenHistory ' +
                    N'@publication = @VARpublicationToTest , ' +
                    N'@tracer_id = @VARtokenID'
            , @parmDefinition = N'@VARpublicationToTest sysname, ' +
                    N'@VARtokenID bigint';
 
        /* Store our results for retrieval later */
        INSERT INTO @tokenResults
        (
            DistributorLatency
          , Subscriber
          , SubscriberDB
          , SubscriberLatency
          , OverallLatency
        )
        EXECUTE SP_EXECUTESQL 
              @sqlStatement
            , @parmDefinition
            , @VARpublicationToTest = @publicationToTest
            , @VARtokenID = @TokenID;
 
        /* Assign the iteration and token id to the results for easier investigation */
        UPDATE @tokenResults
        SET iteration = @currentIteration + 1
          , TracerID = @tokenID
        WHERE iteration IS Null;
 
        /* Wait for the specified time period before creating another token */
        WAITFOR Delay @iterationDelay;
 
        /* Avoid endless looping... :) */
        SET @currentIteration = @currentIteration + 1;
 
    END;
 
    /* Display our results */
    IF @displayResults = 1
    BEGIN
        SELECT 
              iteration
            , TracerID
            , IsNull(DistributorLatency, 0) AS 'DistributorLatency'
            , Subscriber
            , SubscriberDB
            , IsNull(SubscriberLatency, 0) AS 'SubscriberLatency'
            , IsNull(OverallLatency, 
                IsNull(DistributorLatency, 0) + IsNull(SubscriberLatency, 0))
                AS 'OverallLatency'
        FROM @tokenResults;
    END;
 
    /* Store our results */
    INSERT INTO dbo.ReplicationMonitor
    (
          MonitorDate
        , PublicationName
        , PublicationDB
        , Iteration
        , TracerID
        , DistributorLatency
        , Subscriber
        , SubscriberDB
        , SubscriberLatency
        , OverallLatency
    )
    SELECT 
          @currentDateTime
        , @publicationToTest
        , @publicationDB
        , Iteration
        , TracerID
        , IsNull(DistributorLatency, 0)
        , Subscriber
        , SubscriberDB
        , IsNull(SubscriberLatency, 0)
        , IsNull(OverallLatency, 
          IsNull(DistributorLatency, 0) + IsNull(SubscriberLatency, 0))
    FROM @tokenResults;
 
    /* Delete the tracer tokens if requested */
    IF @deleteTokens = 1
    BEGIN
 
        SELECT @sqlStatement = 'Execute ' + @publicationDB + '.sys.sp_deleteTracerTokenHistory ' +
                    N'@publication = @VARpublicationToTest , ' +
                    N'@cutoff_date = @VARcurrentDateTime'
            , @parmDefinition = N'@VARpublicationToTest sysname, ' +
                    N'@VARcurrentDateTime datetime';
 
        EXECUTE SP_EXECUTESQL 
              @sqlStatement
            , @parmDefinition
            , @VARpublicationToTest = @publicationToTest
            , @VARcurrentDateTime = @currentDateTime;
 
    END;
    
    IF @trimResults = 1
    BEGIN
    
		DELETE FROM ReplicationMonitor 
			WHERE publicationName = @PublicationToTest
			AND publicationDB = @PublicationDB
			AND MonitorDate < GETDATE() - 7
    
    END;
 
    SET NOCOUNT OFF;
    RETURN 0;
END

GO