USE dbamaint
GO

----------------------------------------------------------
-- This creates a table to log all activity and results --
----------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fragreport]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[fragreport]
GO

CREATE TABLE [dbo].[fragreport] (
	[fid] [int] IDENTITY (1, 1) NOT NULL ,
	[timestamp] [datetime] NULL ,
	[ObjectName] [sysname] NOT NULL ,
	[ObjectId] [int] NULL ,
	[IndexName] [sysname] NOT NULL ,
	[IndexId] [int] NULL ,
	[Level] [int] NULL ,
	[Pages] [int] NULL ,
	[Rows] [int] NULL ,
	[MinimumRecordSize] [int] NULL ,
	[MaximumRecordSize] [int] NULL ,
	[AverageRecordSize] [float] NULL ,
	[ForwardedRecords] [int] NULL ,
	[Extents] [int] NULL ,
	[ExtentSwitches] [int] NULL ,
	[AverageFreeBytes] [float] NULL ,
	[AveragePageDensity] [float] NULL ,
	[ScanDensity] [float] NULL ,
	[BestCount] [int] NULL ,
	[ActualCount] [int] NULL ,
	[LogicalFragmentation] [float] NULL ,
	[ExtentFragmentation] [float] NULL ,
	[DBName] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[PrePost] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[fragreport] WITH NOCHECK ADD 
	CONSTRAINT [PK_fragreport] PRIMARY KEY  CLUSTERED 
	(
		[fid]
	)  ON [PRIMARY] 
GO


-------------------------------------------------------
-- Run this from dbamaint and supply any database name --
-------------------------------------------------------

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_IndexDefragAndRebuild]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[sp_IndexDefragAndRebuild]
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE sp_IndexDefragAndRebuild
	@dbname varchar(100)
AS

SET NOCOUNT ON

CREATE TABLE #tables(
	rid int identity (1,1),
	tabid int,
	[name] varchar(100)
)

CREATE TABLE #indexes(
	rid int identity (1,1),
	indid int,
	[name] varchar(100)
)

CREATE TABLE #fragreport(
	fid int identity (1,1),
	[timestamp] datetime default getdate(),
	ObjectName sysname,
	ObjectId int,
	IndexName sysname,
	IndexId int,
	[Level] int,
	Pages int,
	[Rows] int,
	MinimumRecordSize int,
	MaximumRecordSize int,
	AverageRecordSize float,
	ForwardedRecords int,
	Extents int,
	ExtentSwitches int,
	AverageFreeBytes float,
	AveragePageDensity float,
	ScanDensity float,
	BestCount int,
	ActualCount int,
	LogicalFragmentation float,
	ExtentFragmentation float,
	DBName varchar(100) NULL,
	PrePost varchar(20) NULL
)

CREATE TABLE #reindex(
	rid int identity (1,1),
	ObjectName sysname,
	IndexName sysname
)

DECLARE @numtables int,
	@numindexes int,
	@numreindexes int,
	@tabcount int,
	@indcount int,
	@recount int,
	@currtable int,
	@tabname varchar(100),
	@currind int,
	@indname varchar(100)


SET @tabcount = 1

INSERT INTO #tables([tabid], [name])
EXEC ('SELECT [id], ltrim(rtrim(su.[name] + ''.'' + so.[name])) FROM ' + @dbname + '.dbo.sysobjects so INNER JOIN ' + @dbname + '.dbo.sysusers su ON su.uid = so.uid WHERE so.xtype = ''U'' AND so.[name] <> ''dtproperties''')

SELECT @numtables = count(*) FROM #tables

WHILE @tabcount <= @numtables
BEGIN
	SET @indcount = 1

	SELECT @currtable = tabid,
	       @tabname = ltrim(rtrim([name]))
	FROM #tables
	WHERE rid = @tabcount 
	
	INSERT INTO #fragreport([ObjectName], [ObjectId], [IndexName], [IndexId], [Level], [Pages], [Rows], [MinimumRecordSize], [MaximumRecordSize], [AverageRecordSize], [ForwardedRecords], [Extents], [ExtentSwitches], [AverageFreeBytes], [AveragePageDensity], [ScanDensity], [BestCount], [ActualCount], [LogicalFragmentation], [ExtentFragmentation])
	EXEC('USE ' + @dbname + ' DBCC SHOWCONTIG ([' + @tabname + ']) WITH ALL_INDEXES, TABLERESULTS')

	DELETE FROM #fragreport
	WHERE IndexID IN (0,255)

	UPDATE #fragreport
	SET PrePost = 'PRE'
	WHERE PrePost is NULL

	INSERT #indexes([indid], [name])
	EXEC ('SELECT indid, [name] FROM ' + @dbname + '.dbo.sysindexes WHERE [id] = ' + @currtable + ' AND [name] not like ''_WA%'' AND indid NOT IN (0, 255)')

	SELECT @numindexes = count(*) FROM #indexes

	WHILE @indcount <= @numindexes
	BEGIN
		SELECT @currind = indid,
		       @indname = ltrim(rtrim([name]))
		FROM #indexes
		WHERE rid = @indcount
		EXEC ('DBCC INDEXDEFRAG (''' + @dbname + ''',''' + @tabname + ''',''' + @indname + ''')')
		SET @indcount = @indcount + 1
 	END

	INSERT INTO #fragreport([ObjectName], [ObjectId], [IndexName], [IndexId], [Level], [Pages], [Rows], [MinimumRecordSize], [MaximumRecordSize], [AverageRecordSize], [ForwardedRecords], [Extents], [ExtentSwitches], [AverageFreeBytes], [AveragePageDensity], [ScanDensity], [BestCount], [ActualCount], [LogicalFragmentation], [ExtentFragmentation])
	EXEC('USE ' + @dbname + ' DBCC SHOWCONTIG ([' + @tabname + ']) WITH ALL_INDEXES, TABLERESULTS')

	DELETE FROM #fragreport
	WHERE IndexID IN (0,255)

	UPDATE #fragreport
	SET PrePost = 'POST'
	WHERE PrePost is NULL

	SET @tabcount = @tabcount + 1
	TRUNCATE TABLE #indexes
END

INSERT INTO #reindex([ObjectName],[IndexName])
SELECT #tables.[name], #fragreport.[IndexName]
FROM #fragreport
INNER JOIN #tables on #tables.tabid = #fragreport.objectid
WHERE #fragreport.IndexId NOT IN (0, 255)
AND (#fragreport.ScanDensity < 90 OR #fragreport.LogicalFragmentation > 10)
AND #fragreport.PrePost = 'POST'

SELECT @numreindexes = count(*) FROM #reindex

SET @recount = 1

WHILE @recount <= @numreindexes
BEGIN
	SELECT @tabname = ObjectName,
	       @indname = IndexName
	FROM #reindex
	WHERE rid = @recount
	
	EXEC('DBCC DBREINDEX([' + @dbname + '.' + @tabname + '],[' + @indname + '])')

	INSERT INTO #fragreport([ObjectName], [ObjectId], [IndexName], [IndexId], [Level], [Pages], [Rows], [MinimumRecordSize], [MaximumRecordSize], [AverageRecordSize], [ForwardedRecords], [Extents], [ExtentSwitches], [AverageFreeBytes], [AveragePageDensity], [ScanDensity], [BestCount], [ActualCount], [LogicalFragmentation], [ExtentFragmentation])
	EXEC('USE ' + @dbname + ' DBCC SHOWCONTIG ([' + @tabname + '],[' + @indname + ']) WITH TABLERESULTS')

	SET @recount = @recount + 1
END

UPDATE #fragreport
SET PrePost = 'REINDEXED'
WHERE PrePost is NULL

UPDATE #fragreport
SET DBName = @dbname

INSERT INTO [dbamaint].[dbo].[fragreport]([timestamp], [ObjectName], [ObjectId], [IndexName], [IndexId], [Level], [Pages], [Rows], [MinimumRecordSize], [MaximumRecordSize], [AverageRecordSize], [ForwardedRecords], [Extents], [ExtentSwitches], [AverageFreeBytes], [AveragePageDensity], [ScanDensity], [BestCount], [ActualCount], [LogicalFragmentation], [ExtentFragmentation], [DBName], [PrePost])
SELECT [timestamp], [ObjectName], [ObjectId], [IndexName], [IndexId], [Level], [Pages], [Rows], [MinimumRecordSize], [MaximumRecordSize], [AverageRecordSize], [ForwardedRecords], [Extents], [ExtentSwitches], [AverageFreeBytes], [AveragePageDensity], [ScanDensity], [BestCount], [ActualCount], [LogicalFragmentation], [ExtentFragmentation], [DBName], [PrePost] FROM #fragreport

DROP TABLE #tables
DROP TABLE #indexes
DROP TABLE #fragreport
DROP TABLE #reindex


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO